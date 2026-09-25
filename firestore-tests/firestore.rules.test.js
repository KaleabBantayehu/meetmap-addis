import { after, before, beforeEach, describe, test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  deleteDoc,
  doc,
  getDoc,
  setDoc,
  Timestamp,
  updateDoc,
} from 'firebase/firestore';

const projectId = 'demo-meetmap-addis';
const rulesPath = fileURLToPath(
  new URL('../firestore.rules', import.meta.url),
);

let testEnv;

function dbFor(uid) {
  return testEnv.authenticatedContext(uid).firestore();
}

function publicDb() {
  return testEnv.unauthenticatedContext().firestore();
}

async function seed(path, data) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), path), data);
  });
}

const placeData = (createdBy = 'alice') => ({
  name: 'Test Place',
  createdBy,
  rating: 0,
  reviewCount: 0,
});

const newPlaceData = (createdBy = 'alice') => ({
  name: 'Test Place',
  createdBy,
});

const reviewData = (userId = 'alice', placeId = 'place-1') => ({
  userId,
  placeId,
  rating: 5,
  reviewText: 'A useful review',
  likedUserIds: [],
  createdAt: Timestamp.fromDate(new Date('2026-09-25T00:00:00Z')),
});

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: {
      host: process.env.FIRESTORE_EMULATOR_HOST?.split(':')[0] ?? '127.0.0.1',
      port: Number(process.env.FIRESTORE_EMULATOR_HOST?.split(':')[1] ?? 8181),
      rules: await readFile(rulesPath, 'utf8'),
    },
  });
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

after(async () => {
  await testEnv.cleanup();
});

describe('users', () => {
  test('users create, update, and intentionally delete only their own profile', async () => {
    const alice = dbFor('alice');
    const ownRef = doc(alice, 'users/alice');

    await assertSucceeds(setDoc(ownRef, { name: 'Alice' }));
    await assertSucceeds(updateDoc(ownRef, { name: 'Alice Updated' }));
    await assertSucceeds(deleteDoc(ownRef));
  });

  test('a user cannot create or update another user profile', async () => {
    const alice = dbFor('alice');
    await assertFails(setDoc(doc(alice, 'users/bob'), { name: 'Fake Bob' }));
    await seed('users/bob', { name: 'Bob' });
    await assertFails(updateDoc(doc(alice, 'users/bob'), { name: 'Changed' }));
  });
});

describe('saved places', () => {
  test('a user can read and write their own saved places only', async () => {
    const alice = dbFor('alice');
    const own = doc(alice, 'users/alice/saved_places/place-1');

    await assertSucceeds(setDoc(own, { placeId: 'place-1' }));
    await assertSucceeds(getDoc(own));
    await assertFails(
      setDoc(doc(alice, 'users/bob/saved_places/place-1'), {
        placeId: 'place-1',
      }),
    );
    await seed('users/bob/saved_places/place-2', { placeId: 'place-2' });
    await assertFails(getDoc(doc(alice, 'users/bob/saved_places/place-2')));
  });
});

describe('following and followers', () => {
  test('the app follow transaction paths and payloads are allowed', async () => {
    const alice = dbFor('alice');
    const followingRef = doc(alice, 'users/alice/following/bob');
    const followerRef = doc(alice, 'users/bob/followers/alice');
    await assertSucceeds(setDoc(followingRef, { userId: 'bob' }));
    await assertSucceeds(setDoc(followerRef, { userId: 'alice' }));
    await assertSucceeds(getDoc(followingRef));
    await assertSucceeds(getDoc(followerRef));
    await assertSucceeds(deleteDoc(followingRef));
    await assertSucceeds(deleteDoc(followerRef));
  });

  test('self-follow, mismatched payloads, and another user following state are denied', async () => {
    const alice = dbFor('alice');
    await assertFails(
      setDoc(doc(alice, 'users/alice/following/alice'), { userId: 'alice' }),
    );
    await assertFails(
      setDoc(doc(alice, 'users/alice/following/bob'), { userId: 'charlie' }),
    );
    await assertFails(
      setDoc(doc(alice, 'users/bob/following/charlie'), { userId: 'charlie' }),
    );
    await assertFails(
      setDoc(doc(alice, 'users/bob/followers/charlie'), { userId: 'charlie' }),
    );
  });
});

describe('places', () => {
  test('signed-in owners can create valid places and public reads work', async () => {
    const alice = dbFor('alice');
    const ref = doc(alice, 'places/place-1');
    await assertSucceeds(setDoc(ref, newPlaceData()));
    await assertSucceeds(getDoc(doc(publicDb(), 'places/place-1')));
  });

  test('place creation enforces ownership and backend-owned aggregates', async () => {
    const alice = dbFor('alice');
    await assertFails(
      setDoc(doc(alice, 'places/wrong-owner'), newPlaceData('bob')),
    );
    await assertFails(
      setDoc(doc(alice, 'places/nonzero-rating'), {
        ...newPlaceData(),
        rating: 4.5,
      }),
    );
    await assertFails(
      setDoc(doc(alice, 'places/client-zero-aggregates'), {
        ...newPlaceData(),
        rating: 0,
        reviewCount: 0,
      }),
    );
    await assertFails(
      setDoc(doc(alice, 'places/client-rating-sum'), {
        ...newPlaceData(),
        ratingSum: 0,
      }),
    );
  });

  test('only creator can update/delete and protected fields are immutable', async () => {
    await seed('places/place-1', placeData());
    const aliceRef = doc(dbFor('alice'), 'places/place-1');
    const bobRef = doc(dbFor('bob'), 'places/place-1');

    await assertSucceeds(updateDoc(aliceRef, { name: 'Updated Place' }));
    await assertFails(updateDoc(aliceRef, { createdBy: 'bob' }));
    await assertFails(updateDoc(aliceRef, { rating: 5 }));
    await assertFails(updateDoc(aliceRef, { ratingSum: 5 }));
    await assertFails(updateDoc(aliceRef, { reviewCount: 10 }));
    await assertFails(
      updateDoc(aliceRef, {
        aggregateUpdatedAt: Timestamp.fromDate(new Date()),
      }),
    );
    await assertFails(updateDoc(bobRef, { name: 'Hijacked' }));
    await assertFails(deleteDoc(bobRef));
    await assertSucceeds(deleteDoc(aliceRef));
  });
});

describe('reviews', () => {
  test('review creation requires matching authenticated owner and parent place', async () => {
    const alice = dbFor('alice');
    await assertSucceeds(
      setDoc(doc(alice, 'places/place-1/reviews/review-1'), reviewData()),
    );
    await assertFails(
      setDoc(
        doc(alice, 'places/place-1/reviews/wrong-user'),
        reviewData('bob'),
      ),
    );
    await assertFails(
      setDoc(
        doc(alice, 'places/place-1/reviews/wrong-place'),
        reviewData('alice', 'place-2'),
      ),
    );
    await assertFails(
      setDoc(doc(alice, 'places/place-1/reviews/invalid-rating'), {
        ...reviewData(),
        rating: 6,
      }),
    );
    await assertFails(
      setDoc(doc(alice, 'places/place-1/reviews/invalid-timestamp'), {
        ...reviewData(),
        createdAt: '2026-09-25T00:00:00Z',
      }),
    );
  });

  test('review owner can edit/delete without changing owner or place linkage', async () => {
    await seed('places/place-1/reviews/review-1', reviewData());
    const aliceRef = doc(
      dbFor('alice'),
      'places/place-1/reviews/review-1',
    );

    await assertSucceeds(updateDoc(aliceRef, { reviewText: 'Edited' }));
    await assertFails(updateDoc(aliceRef, { userId: 'bob' }));
    await assertFails(updateDoc(aliceRef, { placeId: 'place-2' }));
    await assertFails(
      updateDoc(aliceRef, {
        createdAt: Timestamp.fromDate(new Date('2026-09-26T00:00:00Z')),
      }),
    );
    await assertSucceeds(deleteDoc(aliceRef));
  });

  test('another user cannot edit, delete, or like the review document', async () => {
    await seed('places/place-1/reviews/review-1', reviewData());
    const bobRef = doc(dbFor('bob'), 'places/place-1/reviews/review-1');

    await assertFails(updateDoc(bobRef, { reviewText: 'Hijacked' }));
    await assertFails(updateDoc(bobRef, { likedUserIds: ['bob'] }));
    await assertFails(deleteDoc(bobRef));
  });
});

for (const collection of ['events', 'hangouts']) {
  describe(collection, () => {
    test('creator can create, update, and delete their own document', async () => {
      const aliceRef = doc(dbFor('alice'), `${collection}/item-1`);
      await assertSucceeds(setDoc(aliceRef, { createdBy: 'alice', name: 'Item' }));
      await assertSucceeds(updateDoc(aliceRef, { name: 'Updated' }));
      await assertSucceeds(deleteDoc(aliceRef));
    });

    test('ownership claims, transfers, and writes by another user are denied', async () => {
      const alice = dbFor('alice');
      await assertFails(
        setDoc(doc(alice, `${collection}/wrong-owner`), {
          createdBy: 'bob',
          name: 'Item',
        }),
      );
      await seed(`${collection}/item-1`, { createdBy: 'alice', name: 'Item' });
      await assertFails(
        updateDoc(doc(alice, `${collection}/item-1`), { createdBy: 'bob' }),
      );
      const bobRef = doc(dbFor('bob'), `${collection}/item-1`);
      await assertFails(updateDoc(bobRef, { name: 'Hijacked' }));
      await assertFails(deleteDoc(bobRef));
    });
  });
}

describe('public reference collections', () => {
  test('venues and activities are publicly readable but not client-writable', async () => {
    await seed('venues/venue-1', { name: 'Venue' });
    await seed('activities/activity-1', { name: 'Activity' });
    const unauthenticated = publicDb();

    await assertSucceeds(getDoc(doc(unauthenticated, 'venues/venue-1')));
    await assertSucceeds(getDoc(doc(unauthenticated, 'activities/activity-1')));
    await assertFails(
      setDoc(doc(dbFor('alice'), 'venues/venue-2'), { name: 'Venue 2' }),
    );
    await assertFails(
      setDoc(doc(dbFor('alice'), 'activities/activity-2'), {
        name: 'Activity 2',
      }),
    );
  });
});

test('no unmatched document path is writable by an authenticated user', async () => {
  await assertFails(
    setDoc(doc(dbFor('alice'), 'unexpected/document'), { owner: 'alice' }),
  );
  assert.ok(true);
});
