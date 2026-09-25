import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';

import { applyReviewAggregateEvent } from './src/review-aggregates.js';

initializeApp();

export const maintainPlaceReviewAggregate = onDocumentWritten(
  {
    document: 'places/{placeId}/reviews/{reviewId}',
    retry: true,
  },
  async (event) => {
    const placeId = event.params.placeId;
    const reviewId = event.params.reviewId;

    try {
      await applyReviewAggregateEvent({
        db: getFirestore(),
        eventId: event.id,
        placeId,
        reviewId,
        beforeData: event.data?.before.exists
          ? event.data.before.data()
          : null,
        afterData: event.data?.after.exists
          ? event.data.after.data()
          : null,
      });
    } catch (error) {
      logger.error('Review aggregate update failed', {
        eventId: event.id,
        placeId,
        reviewId,
        error: error instanceof Error ? error.message : String(error),
      });
      throw error;
    }
  },
);
