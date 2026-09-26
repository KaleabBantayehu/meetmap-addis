import { after, before, beforeEach, describe, test } from 'node:test';
import assert from 'node:assert/strict';
import { deleteApp, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

import {
  deleteAccountFromRequest,
  deleteMeetMapAccount,
} from '../src/account-lifecycle.js';

const projectId = 'demo-meetmap-addis-account-lifecycle';
let app;
let db;
let deletedAuthUsers;
let auth;
let authFailuresRemaining;

before(() => {
  process.env.FIRESTORE_EMULATOR_HOST ??= '127.0.0.1:8181';
  app = initializeApp({ projectId }, 'account-lifecycle-tests');
  db = getFirestore(app);
});

beforeEach(async () => {
  await Promise.all([
    db.recursiveDelete(db.collection('users')),
    db.recursiveDelete(db.collection('places')),
    db.recursiveDelete(db.collection('events')),
    db.recursiveDelete(db.collection('hangouts')),
  ]);
  deletedAuthUsers = new Set();
  authFailuresRemaining = 0;
  auth = {
    async deleteUser(uid) {
      if (authFailuresRemaining > 0) {
        authFailuresRemaining--;
        throw new Error('Injected authentication deletion failure');
      }
      if (deletedAuthUsers.has(uid)) {
        const error = new Error('User not found');
        error.code = 'auth/user-not-found';
        throw error;
      }
      deletedAuthUsers.add(uid);
    },
  };
});

after(async () => {
  await deleteApp(app);
});

async function seedAccount(uid = 'alice') {
  await Promise.all([
    db.doc(`users/${uid}`).set({ name: 'Alice' }),
    db.doc(`users/${uid}/private/account`).set({ email: 'alice@example.com' }),
    db.doc(`users/${uid}/saved_places/place-1`).set({ savedAt: new Date() }),
    db.doc('users/bob/saved_places/place-1').set({ savedAt: new Date() }),
    db.doc('users/alice/following/bob').set({ userId: 'bob' }),
    db.doc('users/bob/followers/alice').set({ userId: 'alice' }),
    db.doc('users/carol/following/alice').set({ userId: 'alice' }),
    db.doc('users/alice/followers/carol').set({ userId: 'carol' }),
    db.doc('users/bob/following/carol').set({ userId: 'carol' }),
    db.doc('users/carol/followers/bob').set({ userId: 'bob' }),
    db.doc('places/place-1').set({
      createdBy: uid,
      rating: 5,
      ratingSum: 5,
      reviewCount: 1,
    }),
    db.doc('places/place-1/reviews/review-1').set({
      userId: uid,
      placeId: 'place-1',
      rating: 5,
      reviewText: 'Worth preserving',
      createdAt: new Date(),
    }),
    db.doc('places/place-1/reviews/review-2').set({
      userId: 'bob',
      placeId: 'place-1',
      rating: 4,
      reviewText: 'Bob review',
      createdAt: new Date(),
    }),
    db.doc('events/event-1').set({ createdBy: uid }),
    db.doc('hangouts/hangout-1').set({ createdBy: uid }),
  ]);
}

describe('trusted account lifecycle', () => {
  test('anonymizes public contributions and removes private relationships', async () => {
    await seedAccount();

    const result = await deleteMeetMapAccount({ db, auth, uid: 'alice' });

    assert.equal(result.reviewCount, 1);
    assert.equal(deletedAuthUsers.has('alice'), true);
    assert.equal((await db.doc('users/alice').get()).exists, false);
    assert.equal((await db.doc('users/bob/followers/alice').get()).exists, false);
    assert.equal((await db.doc('users/carol/following/alice').get()).exists, false);
    assert.equal((await db.doc('users/bob/following/carol').get()).exists, true);
    assert.equal((await db.doc('users/carol/followers/bob').get()).exists, true);
    assert.equal((await db.doc('users/bob/saved_places/place-1').get()).exists, true);
    assert.equal((await db.doc('places/place-1').get()).exists, true);

    const review = (await db.doc('places/place-1/reviews/review-1').get()).data();
    assert.equal(review.userId, null);
    assert.equal(review.rating, 5);
    assert.equal(review.reviewText, 'Worth preserving');
    const bobReview = (
      await db.doc('places/place-1/reviews/review-2').get()
    ).data();
    assert.equal(bobReview.userId, 'bob');

    const place = (await db.doc('places/place-1').get()).data();
    assert.equal(place.createdBy, null);
    assert.equal(place.lifecycleStatus, 'systemManaged');
    assert.equal(place.ratingSum, 5);
    assert.equal(place.reviewCount, 1);
    assert.equal(place.rating, 5);

    const event = (await db.doc('events/event-1').get()).data();
    assert.equal(event.createdBy, null);
    assert.equal(event.lifecycleStatus, 'archived');
    const hangout = (await db.doc('hangouts/hangout-1').get()).data();
    assert.equal(hangout.createdBy, null);
    assert.equal(hangout.lifecycleStatus, 'inactive');
  });

  test('is safe to retry after cleanup has completed', async () => {
    await seedAccount();
    await deleteMeetMapAccount({ db, auth, uid: 'alice' });
    const retry = await deleteMeetMapAccount({ db, auth, uid: 'alice' });

    assert.equal(retry.reviewCount, 0);
    assert.equal((await db.doc('users/alice').get()).exists, false);
    assert.equal(
      (await db.doc('places/place-1/reviews/review-1').get()).data().rating,
      5,
    );
  });

  test('requires an authenticated user identifier', async () => {
    await assert.rejects(
      deleteMeetMapAccount({ db, auth, uid: '' }),
      /Authenticated user ID is required/,
    );
  });

  test('uses request auth UID and ignores a different payload UID', async () => {
    await seedAccount('alice');
    await db.doc('users/bob').set({ name: 'Bob' });
    await db.doc('events/bob-event').set({ createdBy: 'bob' });

    await deleteAccountFromRequest({
      db,
      auth,
      request: { auth: { uid: 'alice' }, data: { uid: 'bob' } },
    });

    assert.equal((await db.doc('users/alice').get()).exists, false);
    assert.equal((await db.doc('users/bob').get()).exists, true);
    assert.equal((await db.doc('events/bob-event').get()).data().createdBy, 'bob');
    assert.equal(deletedAuthUsers.has('alice'), true);
    assert.equal(deletedAuthUsers.has('bob'), false);
  });

  test('converges after Firestore cleanup succeeds but Auth deletion fails', async () => {
    await seedAccount();
    authFailuresRemaining = 1;

    await assert.rejects(
      deleteMeetMapAccount({ db, auth, uid: 'alice' }),
      /Injected authentication deletion failure/,
    );
    assert.equal((await db.doc('users/alice').get()).exists, false);
    assert.equal(
      (await db.doc('places/place-1/reviews/review-1').get()).data().userId,
      null,
    );

    await deleteMeetMapAccount({ db, auth, uid: 'alice' });
    assert.equal(deletedAuthUsers.has('alice'), true);
    assert.equal(
      (await db.doc('places/place-1/reviews/review-2').get()).data().userId,
      'bob',
    );
  });
});
