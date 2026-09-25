import { after, before, beforeEach, describe, test } from 'node:test';
import assert from 'node:assert/strict';
import { deleteApp, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

import {
  applyReviewAggregateEvent,
  reconcilePlaceReviewAggregate,
} from '../src/review-aggregates.js';

const projectId = 'demo-meetmap-addis-functions';
let app;
let db;

async function placeAggregate(placeId = 'place-1') {
  const snapshot = await db.doc(`places/${placeId}`).get();
  const data = snapshot.data();
  return {
    ratingSum: data.ratingSum,
    reviewCount: data.reviewCount,
    rating: data.rating,
    aggregateUpdatedAt: data.aggregateUpdatedAt,
  };
}

async function apply({
  eventId,
  reviewId,
  beforeData = null,
  afterData = null,
}) {
  return applyReviewAggregateEvent({
    db,
    eventId,
    placeId: 'place-1',
    reviewId,
    beforeData,
    afterData,
  });
}

before(() => {
  process.env.FIRESTORE_EMULATOR_HOST ??= '127.0.0.1:8181';
  app = initializeApp({ projectId }, 'review-aggregate-tests');
  db = getFirestore(app);
});

beforeEach(async () => {
  await db.recursiveDelete(db.collection('places'));
  await db.doc('places/place-1').set({
    name: 'Test Place',
    ratingSum: 0,
    reviewCount: 0,
    rating: 0,
  });
});

after(async () => {
  await deleteApp(app);
});

describe('trusted review aggregate transaction', () => {
  test('create, second create, update, delete, and last delete', async () => {
    await apply({
      eventId: 'event-create-5',
      reviewId: 'review-5',
      afterData: { rating: 5 },
    });
    assert.deepEqual(
      await placeAggregate(),
      {
        ratingSum: 5,
        reviewCount: 1,
        rating: 5,
        aggregateUpdatedAt: (await placeAggregate()).aggregateUpdatedAt,
      },
    );

    await apply({
      eventId: 'event-create-3',
      reviewId: 'review-3',
      afterData: { rating: 3 },
    });
    let aggregate = await placeAggregate();
    assert.equal(aggregate.ratingSum, 8);
    assert.equal(aggregate.reviewCount, 2);
    assert.equal(aggregate.rating, 4);

    await apply({
      eventId: 'event-update-5-to-1',
      reviewId: 'review-5',
      beforeData: { rating: 5 },
      afterData: { rating: 1 },
    });
    aggregate = await placeAggregate();
    assert.equal(aggregate.ratingSum, 4);
    assert.equal(aggregate.reviewCount, 2);
    assert.equal(aggregate.rating, 2);

    await apply({
      eventId: 'event-delete-1',
      reviewId: 'review-5',
      beforeData: { rating: 1 },
    });
    aggregate = await placeAggregate();
    assert.equal(aggregate.ratingSum, 3);
    assert.equal(aggregate.reviewCount, 1);
    assert.equal(aggregate.rating, 3);

    await apply({
      eventId: 'event-delete-3',
      reviewId: 'review-3',
      beforeData: { rating: 3 },
    });
    aggregate = await placeAggregate();
    assert.equal(aggregate.ratingSum, 0);
    assert.equal(aggregate.reviewCount, 0);
    assert.equal(aggregate.rating, 0);
    assert.ok(aggregate.aggregateUpdatedAt);
  });

  test('duplicate event processing does not double-count', async () => {
    const event = {
      eventId: 'duplicate-event',
      reviewId: 'review-1',
      afterData: { rating: 5 },
    };
    const first = await apply(event);
    const duplicate = await apply(event);

    assert.equal(first.duplicate, false);
    assert.equal(duplicate.duplicate, true);
    assert.equal((await placeAggregate()).ratingSum, 5);
    assert.equal((await placeAggregate()).reviewCount, 1);
  });

  test('concurrent creates are transactionally accumulated', async () => {
    await Promise.all([
      apply({
        eventId: 'concurrent-1',
        reviewId: 'review-1',
        afterData: { rating: 5 },
      }),
      apply({
        eventId: 'concurrent-2',
        reviewId: 'review-2',
        afterData: { rating: 3 },
      }),
    ]);

    const aggregate = await placeAggregate();
    assert.equal(aggregate.ratingSum, 8);
    assert.equal(aggregate.reviewCount, 2);
    assert.equal(aggregate.rating, 4);
  });

  test('invalid review ratings are rejected', async () => {
    await assert.rejects(
      apply({
        eventId: 'invalid-rating',
        reviewId: 'review-invalid',
        afterData: { rating: 6 },
      }),
      /invalid rating/,
    );
    assert.equal((await placeAggregate()).reviewCount, 0);
  });

  test('invalid current aggregate fails instead of being clamped', async () => {
    await db.doc('places/place-1').set({
      ratingSum: 0,
      reviewCount: -1,
      rating: 0,
    });
    await assert.rejects(
      apply({
        eventId: 'invalid-place-state',
        reviewId: 'review-1',
        afterData: { rating: 5 },
      }),
      /requires reconciliation/,
    );
  });

  test('single-place reconciliation uses authoritative reviews', async () => {
    await db.doc('places/place-1').update({
      ratingSum: 99,
      reviewCount: 99,
      rating: 1,
    });
    await db.doc('places/place-1/reviews/review-1').set({ rating: 5 });
    await db.doc('places/place-1/reviews/review-2').set({ rating: 3 });

    const result = await reconcilePlaceReviewAggregate(db, 'place-1');
    assert.deepEqual(
      {
        ratingSum: result.ratingSum,
        reviewCount: result.reviewCount,
        rating: result.rating,
      },
      { ratingSum: 8, reviewCount: 2, rating: 4 },
    );
  });
});
