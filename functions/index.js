import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { getAuth } from 'firebase-admin/auth';

import { applyReviewAggregateEvent } from './src/review-aggregates.js';
import { deleteAccountFromRequest } from './src/account-lifecycle.js';

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

export const deleteAccount = onCall(
  { enforceAppCheck: true },
  async (request) => {
    try {
      await deleteAccountFromRequest({
        db: getFirestore(),
        auth: getAuth(),
        request,
      });
      return { deleted: true };
    } catch (error) {
      if (error?.code === 'unauthenticated') {
        throw new HttpsError(
          'unauthenticated',
          'You must be signed in to delete your account.',
        );
      }
      logger.error('Account deletion failed', {
        uid: request.auth?.uid,
        error: error instanceof Error ? error.message : String(error),
      });
      throw new HttpsError(
        'internal',
        'Account deletion could not be completed. Please try again.',
      );
    }
  },
);
