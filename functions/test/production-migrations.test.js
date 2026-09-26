import { after, before, beforeEach, describe, test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { deleteApp, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

import {
  buildSearchPrefixes,
  maximumSearchPrefixes,
  runLifecycleBackfill,
  runReviewAggregateReconciliation,
  runSearchPrefixBackfill,
} from '../src/production-migrations.js';
import {
  checkpointSchemaVersion,
  runMigrationCli,
  validateCheckpoint,
} from '../scripts/migrations/migration-cli.js';

const projectId = 'demo-meetmap-addis-migrations';
let app;
let db;

async function data(path) {
  return (await db.doc(path).get()).data();
}

before(() => {
  process.env.FIRESTORE_EMULATOR_HOST ??= '127.0.0.1:8181';
  app = initializeApp({ projectId }, 'production-migration-tests');
  db = getFirestore(app);
});

beforeEach(async () => {
  await Promise.all([
    db.recursiveDelete(db.collection('places')),
    db.recursiveDelete(db.collection('events')),
    db.recursiveDelete(db.collection('hangouts')),
  ]);
});

after(async () => deleteApp(app));

describe('migration safety contract', () => {
  test('production writes require explicit production confirmation', async () => {
    await assert.rejects(
      runSearchPrefixBackfill({
        db,
        projectId: 'meetmap-addis',
        write: true,
      }),
      /--write and --confirm-production/,
    );
  });

  test('valid checkpoint identity is accepted', () => {
    assert.doesNotThrow(() => validateCheckpoint({
      version: checkpointSchemaVersion,
      migration: 'search-prefixes-v1',
      projectId,
      mode: 'write',
      lastProcessedId: 'place-1',
    }, {
      migrationName: 'search-prefixes-v1',
      projectId,
      mode: 'write',
    }));
  });

  test('checkpoint identity rejects migration, version, project, and mode mismatches', () => {
    const valid = {
      version: checkpointSchemaVersion,
      migration: 'search-prefixes-v1',
      projectId,
      mode: 'dry-run',
    };
    const expected = {
      migrationName: 'search-prefixes-v1',
      projectId,
      mode: 'dry-run',
    };
    assert.throws(
      () => validateCheckpoint({ ...valid, migration: 'other-v1' }, expected),
      /belongs to migration/,
    );
    assert.throws(
      () => validateCheckpoint({ ...valid, version: 99 }, expected),
      /incompatible schema/,
    );
    assert.throws(
      () => validateCheckpoint({ ...valid, projectId: 'other-project' }, expected),
      /belongs to project/,
    );
    assert.throws(
      () => validateCheckpoint({ ...valid, mode: 'write' }, expected),
      /cannot be used for dry-run/,
    );
    assert.throws(
      () => validateCheckpoint(valid, { ...expected, mode: 'write' }),
      /cannot be used for write/,
    );
  });

  test('invalid checkpoint is rejected before migration processing', async () => {
    const directory = await mkdtemp(join(tmpdir(), 'meetmap-migration-'));
    const checkpointPath = join(directory, 'checkpoint.json');
    await writeFile(checkpointPath, JSON.stringify({
      version: checkpointSchemaVersion,
      migration: 'other-v1',
      projectId,
      mode: 'dry-run',
    }));
    const originalArguments = process.argv;
    let processed = false;
    process.argv = ['node', 'test', `--project=${projectId}`, `--checkpoint=${checkpointPath}`];
    try {
      await assert.rejects(
        runMigrationCli({
          migrationName: 'search-prefixes-v1',
          execute: async () => { processed = true; },
        }),
        /belongs to migration/,
      );
      assert.equal(processed, false);
      assert.equal((await db.collection('places').get()).empty, true);
    } finally {
      process.argv = originalArguments;
      await rm(directory, { recursive: true, force: true });
    }
  });

  test('prefix normalization matches case, whitespace, word, and limit semantics', () => {
    const prefixes = buildSearchPrefixes([
      '  Tomoca   Coffee  ',
      'CAFE',
      'Bole Road',
      'Study Spot',
    ]);
    assert.ok(prefixes.includes('to'));
    assert.ok(prefixes.includes('tomoca coffee'));
    assert.ok(prefixes.includes('coffee'));
    assert.ok(prefixes.includes('cafe'));
    assert.ok(prefixes.includes('bole road'));
    assert.ok(prefixes.includes('study'));

    const bounded = buildSearchPrefixes(
      Array.from({ length: 300 }, (_, index) => `unique${index} longvalue`),
    );
    assert.equal(bounded.length, maximumSearchPrefixes);
  });
});

describe('search prefix backfill', () => {
  test('dry run proposes missing prefixes without writing and reports malformed data', async () => {
    await db.doc('places/missing').set({
      name: 'Tomoca Coffee',
      category: 'Cafe',
      location: 'Bole Road',
      tags: ['Study Spot'],
      preserved: true,
    });
    await db.doc('places/existing').set({
      name: 'Existing',
      category: 'Cafe',
      location: 'Bole',
      tags: [],
      searchPrefixes: ['keep-me'],
    });
    await db.doc('places/malformed').set({
      name: 42,
      category: 'Cafe',
      location: 'Bole',
    });
    const records = [];

    const result = await runSearchPrefixBackfill({
      db,
      projectId,
      record: async (record) => records.push(record),
    });

    assert.equal(result.counts.scanned, 3);
    assert.equal(result.counts.proposedUpdates, 1);
    assert.equal(result.counts.alreadyPopulated, 1);
    assert.equal(result.counts.malformed, 1);
    assert.equal((await data('places/missing')).searchPrefixes, undefined);
    assert.deepEqual((await data('places/existing')).searchPrefixes, ['keep-me']);
    assert.deepEqual(records.map((record) => record.status).sort(), ['error', 'proposed']);
  });

  test('write changes only the missing field and retry performs no write', async () => {
    await db.doc('places/place-1').set({
      name: '  Addis   Cafe ',
      category: 'Coffee Shop',
      location: 'Bole',
      tags: ['Work Friendly'],
      preserved: 'yes',
    });
    const first = await runSearchPrefixBackfill({ db, projectId, write: true });
    const written = await data('places/place-1');
    assert.equal(first.counts.changed, 1);
    assert.equal(written.preserved, 'yes');
    assert.ok(written.searchPrefixes.includes('addis cafe'));
    assert.ok(written.searchPrefixes.includes('coffee shop'));
    assert.ok(written.searchPrefixes.includes('work friendly'));

    const retry = await runSearchPrefixBackfill({ db, projectId, write: true });
    assert.equal(retry.counts.changed, 0);
    assert.equal(retry.counts.alreadyPopulated, 1);
  });
});

describe('lifecycle backfill', () => {
  test('dry run and write preserve every explicit lifecycle value', async () => {
    await db.doc('events/legacy').set({ title: 'Legacy event', preserved: 1 });
    await db.doc('events/active').set({ lifecycleStatus: 'active' });
    await db.doc('events/archived').set({ lifecycleStatus: 'archived' });
    await db.doc('events/unknown').set({ lifecycleStatus: 'moderated' });
    await db.doc('hangouts/legacy').set({ title: 'Legacy hangout', preserved: 2 });
    await db.doc('hangouts/inactive').set({ lifecycleStatus: 'inactive' });

    const dryRun = await runLifecycleBackfill({ db, projectId });
    assert.equal(dryRun.collections.events.counts.proposedUpdates, 1);
    assert.equal(dryRun.collections.hangouts.counts.proposedUpdates, 1);
    assert.equal((await data('events/legacy')).lifecycleStatus, undefined);

    const written = await runLifecycleBackfill({ db, projectId, write: true });
    assert.equal(written.collections.events.counts.changed, 1);
    assert.equal(written.collections.hangouts.counts.changed, 1);
    assert.equal((await data('events/legacy')).lifecycleStatus, 'active');
    assert.equal((await data('events/legacy')).preserved, 1);
    assert.equal((await data('hangouts/legacy')).lifecycleStatus, 'active');
    assert.equal((await data('events/archived')).lifecycleStatus, 'archived');
    assert.equal((await data('events/unknown')).lifecycleStatus, 'moderated');
    assert.equal((await data('hangouts/inactive')).lifecycleStatus, 'inactive');

    const retry = await runLifecycleBackfill({ db, projectId, write: true });
    assert.equal(retry.collections.events.counts.changed, 0);
    assert.equal(retry.collections.hangouts.counts.changed, 0);
  });

  test('checkpoint resume continues after the last processed document', async () => {
    await db.doc('events/a').set({ title: 'A' });
    await db.doc('events/b').set({ title: 'B' });
    await db.doc('hangouts/a').set({ title: 'A' });
    await db.doc('hangouts/b').set({ title: 'B' });
    const checkpoints = {};
    const first = await runLifecycleBackfill({
      db,
      projectId,
      write: true,
      batchSize: 1,
      maxBatches: 1,
      onCheckpoint: async ({ collectionPath, lastProcessedId }) => {
        checkpoints[collectionPath] = lastProcessedId;
      },
    });
    assert.equal(first.collections.events.completed, false);
    assert.equal(first.collections.hangouts.completed, false);

    await runLifecycleBackfill({
      db,
      projectId,
      write: true,
      batchSize: 1,
      checkpoints,
    });
    assert.equal((await data('events/b')).lifecycleStatus, 'active');
    assert.equal((await data('hangouts/b')).lifecycleStatus, 'active');
  });

  test('independent lifecycle cursors are preserved and resume both collections', async () => {
    for (const id of ['a', 'b', 'c']) {
      await db.doc(`events/${id}`).set({ title: id });
      await db.doc(`hangouts/${id}`).set({ title: id });
    }
    const collections = {};
    const snapshots = [];
    await runLifecycleBackfill({
      db,
      projectId,
      write: true,
      batchSize: 1,
      maxBatches: 1,
      checkpoints: collections,
      onCheckpoint: async ({ collectionPath, lastProcessedId }) => {
        collections[collectionPath] = lastProcessedId;
        snapshots.push({ ...collections });
      },
    });
    assert.deepEqual(snapshots.at(-1), { events: 'a', hangouts: 'a' });

    await runLifecycleBackfill({
      db,
      projectId,
      write: true,
      batchSize: 1,
      checkpoints: collections,
    });
    for (const id of ['a', 'b', 'c']) {
      assert.equal((await data(`events/${id}`)).lifecycleStatus, 'active');
      assert.equal((await data(`hangouts/${id}`)).lifecycleStatus, 'active');
    }
    const retry = await runLifecycleBackfill({ db, projectId, write: true });
    assert.equal(retry.collections.events.counts.changed, 0);
    assert.equal(retry.collections.hangouts.counts.changed, 0);
  });
});

describe('review aggregate reconciliation', () => {
  test('dry run calculates authoritative aggregates without writing', async () => {
    await db.doc('places/place-1').set({
      name: 'Place',
      ratingSum: 1,
      reviewCount: 1,
      rating: 1,
      preserved: true,
    });
    await db.doc('places/place-1/reviews/one').set({ userId: 'alice', rating: 5 });
    await db.doc('places/place-1/reviews/two').set({ userId: 'alice', rating: 4 });
    await db.doc('places/place-1/reviews/anonymous').set({ userId: null, rating: 5 });

    const result = await runReviewAggregateReconciliation({ db, projectId });
    assert.equal(result.counts.proposedUpdates, 1);
    assert.equal((await data('places/place-1')).ratingSum, 1);
  });

  test('write converges aggregates, preserves fields, and is retry-safe', async () => {
    await db.doc('places/a-wrong').set({
      name: 'Wrong',
      ratingSum: 0,
      reviewCount: 0,
      rating: 0,
      preserved: 'yes',
    });
    await db.doc('places/a-wrong/reviews/one').set({ userId: 'alice', rating: 5 });
    await db.doc('places/a-wrong/reviews/two').set({ userId: null, rating: 3 });
    await db.doc('places/b-correct').set({
      name: 'Correct',
      ratingSum: 4,
      reviewCount: 1,
      rating: 4,
    });
    await db.doc('places/b-correct/reviews/one').set({ rating: 4 });
    await db.doc('places/c-empty').set({
      name: 'Empty',
      ratingSum: 9,
      reviewCount: 2,
      rating: 4.5,
    });

    const result = await runReviewAggregateReconciliation({
      db,
      projectId,
      write: true,
    });
    assert.equal(result.counts.changed, 2);
    const wrong = await data('places/a-wrong');
    assert.equal(wrong.ratingSum, 8);
    assert.equal(wrong.reviewCount, 2);
    assert.equal(wrong.rating, 4);
    assert.equal(wrong.preserved, 'yes');
    assert.ok(wrong.aggregateUpdatedAt);
    const empty = await data('places/c-empty');
    assert.equal(empty.ratingSum, 0);
    assert.equal(empty.reviewCount, 0);
    assert.equal(empty.rating, 0);

    const retry = await runReviewAggregateReconciliation({ db, projectId, write: true });
    assert.equal(retry.counts.changed, 0);
  });

  test('malformed reviews are reported while other places continue', async () => {
    await db.doc('places/bad').set({ name: 'Bad' });
    await db.doc('places/bad/reviews/review').set({ rating: 9 });
    await db.doc('places/good').set({ name: 'Good' });
    await db.doc('places/good/reviews/review').set({ rating: 5 });
    const records = [];
    const result = await runReviewAggregateReconciliation({
      db,
      projectId,
      write: true,
      record: async (record) => records.push(record),
    });
    assert.equal(result.counts.errors, 1);
    assert.equal(result.counts.changed, 1);
    assert.equal((await data('places/good')).rating, 5);
    assert.equal((await data('places/bad')).rating, undefined);
    assert.equal(records.find((record) => record.path === 'places/bad').status, 'error');
  });

  test('bounded checkpoint resumes without rescanning completed places', async () => {
    await db.doc('places/a').set({ name: 'A' });
    await db.doc('places/a/reviews/review').set({ rating: 5 });
    await db.doc('places/b').set({ name: 'B' });
    await db.doc('places/b/reviews/review').set({ rating: 3 });
    let checkpoint;
    const first = await runReviewAggregateReconciliation({
      db,
      projectId,
      write: true,
      batchSize: 1,
      maxBatches: 1,
      onCheckpoint: async ({ lastProcessedId }) => { checkpoint = lastProcessedId; },
    });
    assert.equal(first.completed, false);
    assert.equal(checkpoint, 'a');

    const resumed = await runReviewAggregateReconciliation({
      db,
      projectId,
      write: true,
      batchSize: 1,
      startAfterId: checkpoint,
    });
    assert.equal(resumed.counts.scanned, 1);
    assert.equal((await data('places/b')).rating, 3);
  });
});
