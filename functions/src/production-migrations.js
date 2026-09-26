import { FieldPath, FieldValue } from 'firebase-admin/firestore';

export const productionProjectId = 'meetmap-addis';
export const migrationBatchSize = 100;
export const maximumMigrationBatchSize = 400;
export const maximumSearchPrefixes = 200;

const minimumPrefixLength = 2;
const maximumPrefixLength = 50;
const ratingEpsilon = 1e-9;

export function normalizeSearchValue(value) {
  return value.trim().toLowerCase().replace(/\s+/g, ' ');
}

export function buildSearchPrefixes(values) {
  const prefixes = new Set();
  for (const value of values) {
    const normalized = normalizeSearchValue(value);
    if (!normalized) continue;
    const words = normalized.split(' ');
    for (let wordIndex = 0; wordIndex < words.length; wordIndex += 1) {
      const phrase = words.slice(wordIndex).join(' ');
      const upperBound = Math.min(phrase.length, maximumPrefixLength);
      for (let length = minimumPrefixLength; length <= upperBound; length += 1) {
        prefixes.add(phrase.slice(0, length));
        if (prefixes.size >= maximumSearchPrefixes) return [...prefixes];
      }
    }
  }
  return [...prefixes];
}

export function validateMigrationOptions({ projectId, write, confirmProduction, batchSize }) {
  if (!projectId?.trim()) throw new Error('An explicit --project value is required');
  if (!Number.isInteger(batchSize) || batchSize < 1 || batchSize > maximumMigrationBatchSize) {
    throw new Error(`Batch size must be between 1 and ${maximumMigrationBatchSize}`);
  }
  if (write && projectId === productionProjectId && !confirmProduction) {
    throw new Error('Production writes require both --write and --confirm-production');
  }
}

function baseCounts() {
  return {
    scanned: 0,
    eligible: 0,
    alreadyPopulated: 0,
    malformed: 0,
    proposedUpdates: 0,
    changed: 0,
    skipped: 0,
    errors: 0,
  };
}

async function pagedDocuments({
  db,
  collectionPath,
  batchSize,
  startAfterId,
  maxBatches = Number.POSITIVE_INFINITY,
  processPage,
  onCheckpoint = async () => {},
}) {
  let cursor = startAfterId ?? null;
  let batches = 0;
  while (batches < maxBatches) {
    let query = db.collection(collectionPath)
      .orderBy(FieldPath.documentId())
      .limit(batchSize);
    if (cursor) query = query.startAfter(cursor);
    const snapshot = await query.get();
    if (snapshot.empty) return { completed: true, lastProcessedId: cursor };

    await processPage(snapshot.docs);
    cursor = snapshot.docs.at(-1).id;
    batches += 1;
    await onCheckpoint({ collectionPath, lastProcessedId: cursor });
    if (snapshot.size < batchSize) return { completed: true, lastProcessedId: cursor };
  }
  return { completed: false, lastProcessedId: cursor };
}

function searchSource(data) {
  if (
    typeof data.name !== 'string' ||
    typeof data.category !== 'string' ||
    typeof data.location !== 'string' ||
    (data.tags != null && (!Array.isArray(data.tags) || data.tags.some((tag) => typeof tag !== 'string')))
  ) {
    throw new Error('invalid-search-source');
  }
  return [data.name, data.category, data.location, ...(data.tags ?? [])];
}

export async function runSearchPrefixBackfill({
  db,
  projectId,
  write = false,
  confirmProduction = false,
  batchSize = migrationBatchSize,
  startAfterId,
  maxBatches,
  record = async () => {},
  onCheckpoint = async () => {},
}) {
  validateMigrationOptions({ projectId, write, confirmProduction, batchSize });
  const counts = baseCounts();
  const page = await pagedDocuments({
    db,
    collectionPath: 'places',
    batchSize,
    startAfterId,
    maxBatches,
    onCheckpoint: async (checkpoint) => onCheckpoint({ ...checkpoint, counts }),
    processPage: async (documents) => {
      const updates = [];
      for (const document of documents) {
        counts.scanned += 1;
        const data = document.data();
        if (Object.hasOwn(data, 'searchPrefixes')) {
          counts.alreadyPopulated += 1;
          counts.skipped += 1;
          continue;
        }
        try {
          const prefixes = buildSearchPrefixes(searchSource(data));
          if (prefixes.length === 0 || prefixes.length > maximumSearchPrefixes) {
            throw new Error('invalid-prefix-result');
          }
          counts.eligible += 1;
          counts.proposedUpdates += 1;
          updates.push({ document, prefixes });
        } catch (error) {
          counts.malformed += 1;
          counts.errors += 1;
          await record({
            path: document.ref.path,
            status: 'error',
            errorCategory: error.message,
          });
        }
      }

      if (!write) {
        for (const update of updates) {
          await record({
            path: update.document.ref.path,
            status: 'proposed',
            fieldsChanged: ['searchPrefixes'],
            oldValue: { searchPrefixes: 'missing' },
            newValue: { searchPrefixes: update.prefixes },
          });
        }
        return;
      }

      for (const update of updates) {
        await record({
          path: update.document.ref.path,
          status: 'pending',
          fieldsChanged: ['searchPrefixes'],
          oldValue: { searchPrefixes: 'missing' },
          newValue: { searchPrefixes: update.prefixes },
        });
      }
      if (updates.length > 0) {
        const batch = db.batch();
        for (const update of updates) {
          batch.update(update.document.ref, { searchPrefixes: update.prefixes });
        }
        await batch.commit();
        counts.changed += updates.length;
        for (const update of updates) {
          await record({ path: update.document.ref.path, status: 'changed' });
        }
      }
    },
  });
  return { migration: 'search-prefixes-v1', ...page, counts };
}

async function runLifecycleCollection({
  db,
  projectId,
  collectionPath,
  write,
  confirmProduction,
  batchSize,
  startAfterId,
  maxBatches,
  record,
  onCheckpoint,
}) {
  validateMigrationOptions({ projectId, write, confirmProduction, batchSize });
  const counts = baseCounts();
  const page = await pagedDocuments({
    db,
    collectionPath,
    batchSize,
    startAfterId,
    maxBatches,
    onCheckpoint: async (checkpoint) => onCheckpoint({ ...checkpoint, counts }),
    processPage: async (documents) => {
      const updates = [];
      for (const document of documents) {
        counts.scanned += 1;
        if (Object.hasOwn(document.data(), 'lifecycleStatus')) {
          counts.alreadyPopulated += 1;
          counts.skipped += 1;
        } else {
          counts.eligible += 1;
          counts.proposedUpdates += 1;
          updates.push(document);
        }
      }
      const details = (document, status) => ({
        path: document.ref.path,
        status,
        fieldsChanged: ['lifecycleStatus'],
        oldValue: { lifecycleStatus: 'missing' },
        newValue: { lifecycleStatus: 'active' },
      });
      if (!write) {
        for (const document of updates) await record(details(document, 'proposed'));
        return;
      }
      for (const document of updates) await record(details(document, 'pending'));
      if (updates.length > 0) {
        const batch = db.batch();
        for (const document of updates) batch.update(document.ref, { lifecycleStatus: 'active' });
        await batch.commit();
        counts.changed += updates.length;
        for (const document of updates) {
          await record({ path: document.ref.path, status: 'changed' });
        }
      }
    },
  });
  return { collectionPath, ...page, counts };
}

export async function runLifecycleBackfill({
  db,
  projectId,
  write = false,
  confirmProduction = false,
  batchSize = migrationBatchSize,
  checkpoints = {},
  maxBatches,
  record = async () => {},
  onCheckpoint = async () => {},
}) {
  const results = {};
  for (const collectionPath of ['events', 'hangouts']) {
    results[collectionPath] = await runLifecycleCollection({
      db,
      projectId,
      collectionPath,
      write,
      confirmProduction,
      batchSize,
      startAfterId: checkpoints[collectionPath],
      maxBatches,
      record,
      onCheckpoint,
    });
  }
  return { migration: 'lifecycle-status-v1', collections: results };
}

function validReviewRating(data) {
  const rating = data.rating;
  if (typeof rating !== 'number' || !Number.isFinite(rating) || rating < 1 || rating > 5) {
    throw new Error('invalid-review-rating');
  }
  return rating;
}

function differs(actual, expected) {
  return typeof actual !== 'number' || !Number.isFinite(actual) ||
    Math.abs(actual - expected) > ratingEpsilon;
}

export async function runReviewAggregateReconciliation({
  db,
  projectId,
  write = false,
  confirmProduction = false,
  batchSize = migrationBatchSize,
  startAfterId,
  maxBatches,
  record = async () => {},
  onCheckpoint = async () => {},
}) {
  validateMigrationOptions({ projectId, write, confirmProduction, batchSize });
  const counts = baseCounts();
  const page = await pagedDocuments({
    db,
    collectionPath: 'places',
    batchSize,
    startAfterId,
    maxBatches,
    onCheckpoint: async (checkpoint) => onCheckpoint({ ...checkpoint, counts }),
    processPage: async (places) => {
      const updates = [];
      for (const place of places) {
        counts.scanned += 1;
        try {
          const reviews = await place.ref.collection('reviews').get();
          let ratingSum = 0;
          for (const review of reviews.docs) ratingSum += validReviewRating(review.data());
          const reviewCount = reviews.size;
          const rating = reviewCount === 0 ? 0 : ratingSum / reviewCount;
          const current = place.data();
          const changedFields = {};
          if (differs(current.ratingSum, ratingSum)) changedFields.ratingSum = ratingSum;
          if (current.reviewCount !== reviewCount) changedFields.reviewCount = reviewCount;
          if (differs(current.rating, rating)) changedFields.rating = rating;
          if (Object.keys(changedFields).length === 0) {
            counts.alreadyPopulated += 1;
            counts.skipped += 1;
            continue;
          }
          counts.eligible += 1;
          counts.proposedUpdates += 1;
          updates.push({ place, current, changedFields });
        } catch (error) {
          counts.malformed += 1;
          counts.errors += 1;
          await record({
            path: place.ref.path,
            status: 'error',
            errorCategory: error.message,
          });
        }
      }

      const details = (update, status) => ({
        path: update.place.ref.path,
        status,
        fieldsChanged: [...Object.keys(update.changedFields), 'aggregateUpdatedAt'],
        oldValue: Object.fromEntries(
          Object.keys(update.changedFields).map((field) => [
            field,
            Object.hasOwn(update.current, field) ? update.current[field] : 'missing',
          ]),
        ),
        newValue: { ...update.changedFields, aggregateUpdatedAt: 'serverTimestamp' },
      });
      if (!write) {
        for (const update of updates) await record(details(update, 'proposed'));
        return;
      }
      for (const update of updates) await record(details(update, 'pending'));
      if (updates.length > 0) {
        const batch = db.batch();
        for (const update of updates) {
          batch.update(update.place.ref, {
            ...update.changedFields,
            aggregateUpdatedAt: FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
        counts.changed += updates.length;
        for (const update of updates) {
          await record({ path: update.place.ref.path, status: 'changed' });
        }
      }
    },
  });
  return { migration: 'review-aggregates-v1', ...page, counts };
}
