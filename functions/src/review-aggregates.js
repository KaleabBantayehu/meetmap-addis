import { createHash } from 'node:crypto';
import { FieldValue } from 'firebase-admin/firestore';

const MIN_RATING = 1;
const MAX_RATING = 5;
const EPSILON = 1e-9;

export function validRatingFromReview(review, label) {
  if (review == null) return null;

  const rating = review.rating;
  if (
    typeof rating !== 'number' ||
    !Number.isFinite(rating) ||
    rating < MIN_RATING ||
    rating > MAX_RATING
  ) {
    throw new Error(`${label} review has an invalid rating`);
  }
  return rating;
}

export function calculateReviewDelta(beforeData, afterData) {
  const beforeRating = validRatingFromReview(beforeData, 'Previous');
  const afterRating = validRatingFromReview(afterData, 'Current');

  if (beforeRating == null && afterRating == null) {
    throw new Error('Review event contains neither a previous nor current document');
  }

  return {
    ratingSumDelta: (afterRating ?? 0) - (beforeRating ?? 0),
    reviewCountDelta:
      (afterRating == null ? 0 : 1) - (beforeRating == null ? 0 : 1),
    eventType:
      beforeRating == null
        ? 'create'
        : afterRating == null
          ? 'delete'
          : 'update',
  };
}

function eventDocumentId(eventId) {
  return createHash('sha256').update(eventId).digest('hex');
}

function readCurrentAggregate(placeData) {
  const reviewCount = placeData.reviewCount ?? 0;
  const rating = placeData.rating ?? 0;
  const hasRatingSum = typeof placeData.ratingSum === 'number';

  if (!Number.isInteger(reviewCount) || reviewCount < 0) {
    throw new Error('Place has an invalid reviewCount and requires reconciliation');
  }
  if (typeof rating !== 'number' || !Number.isFinite(rating)) {
    throw new Error('Place has an invalid rating and requires reconciliation');
  }

  if (!hasRatingSum) {
    if (reviewCount === 0 && rating === 0) {
      return { ratingSum: 0, reviewCount: 0 };
    }
    throw new Error('Place is missing ratingSum and requires reconciliation');
  }

  const ratingSum = placeData.ratingSum;
  if (!Number.isFinite(ratingSum) || ratingSum < 0) {
    throw new Error('Place has an invalid ratingSum and requires reconciliation');
  }

  return { ratingSum, reviewCount };
}

export async function applyReviewAggregateEvent({
  db,
  eventId,
  placeId,
  reviewId,
  beforeData,
  afterData,
}) {
  if (!eventId || !placeId || !reviewId) {
    throw new Error('Aggregate event identifiers are required');
  }

  const delta = calculateReviewDelta(beforeData, afterData);
  const placeRef = db.doc(`places/${placeId}`);
  const eventRef = placeRef
    .collection('aggregateEvents')
    .doc(eventDocumentId(eventId));

  return db.runTransaction(async (transaction) => {
    const [eventSnapshot, placeSnapshot] = await Promise.all([
      transaction.get(eventRef),
      transaction.get(placeRef),
    ]);

    if (eventSnapshot.exists) {
      return { duplicate: true };
    }
    if (!placeSnapshot.exists) {
      throw new Error(`Parent place ${placeId} does not exist`);
    }

    const current = readCurrentAggregate(placeSnapshot.data() ?? {});
    let nextRatingSum = current.ratingSum + delta.ratingSumDelta;
    const nextReviewCount = current.reviewCount + delta.reviewCountDelta;

    if (Math.abs(nextRatingSum) <= EPSILON) nextRatingSum = 0;
    if (nextReviewCount < 0 || nextRatingSum < 0) {
      throw new Error('Review aggregate delta would create a negative state');
    }
    if (nextReviewCount === 0 && nextRatingSum !== 0) {
      throw new Error('Zero reviewCount cannot have a non-zero ratingSum');
    }

    const nextRating = nextReviewCount === 0
      ? 0
      : nextRatingSum / nextReviewCount;
    if (
      nextReviewCount > 0 &&
      (nextRating < MIN_RATING || nextRating > MAX_RATING)
    ) {
      throw new Error('Review aggregate delta would create an invalid rating');
    }

    transaction.update(placeRef, {
      ratingSum: nextRatingSum,
      reviewCount: nextReviewCount,
      rating: nextRating,
      aggregateUpdatedAt: FieldValue.serverTimestamp(),
    });
    transaction.create(eventRef, {
      eventId,
      placeId,
      reviewId,
      eventType: delta.eventType,
      processedAt: FieldValue.serverTimestamp(),
    });

    return {
      duplicate: false,
      ratingSum: nextRatingSum,
      reviewCount: nextReviewCount,
      rating: nextRating,
    };
  });
}

export async function reconcilePlaceReviewAggregate(db, placeId) {
  if (!placeId) throw new Error('A place ID is required');

  const placeRef = db.doc(`places/${placeId}`);
  const result = await db.runTransaction(async (transaction) => {
    const [placeSnapshot, reviewsSnapshot] = await Promise.all([
      transaction.get(placeRef),
      transaction.get(placeRef.collection('reviews')),
    ]);
    if (!placeSnapshot.exists) {
      throw new Error(`Parent place ${placeId} does not exist`);
    }

    let ratingSum = 0;
    for (const reviewDocument of reviewsSnapshot.docs) {
      ratingSum += validRatingFromReview(
        reviewDocument.data(),
        `Review ${reviewDocument.id}`,
      );
    }

    const reviewCount = reviewsSnapshot.size;
    const rating = reviewCount === 0 ? 0 : ratingSum / reviewCount;
    transaction.update(placeRef, {
      ratingSum,
      reviewCount,
      rating,
      aggregateUpdatedAt: FieldValue.serverTimestamp(),
    });

    return { placeId, ratingSum, reviewCount, rating };
  });

  return result;
}
