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
  writeBatch,
} from 'firebase/firestore';

const projectId = 'demo-meetmap-addis';
const rulesPath = fileURLToPath(
  new URL('../firestore.rules', import.meta.url),
);

let testEnv;

function dbFor(uid) {
  return testEnv.authenticatedContext(uid, {
    email: `${uid}@example.com`,
  }).firestore();
}

function publicDb() {
  return testEnv.unauthenticatedContext().firestore();
}

async function seed(path, data) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), path), data);
  });
}

const timestamp = () => Timestamp.fromDate(new Date('2026-09-25T00:00:00Z'));

const userData = (userId = 'alice') => ({
  id: userId,
  uid: userId,
  name: 'Alice',
  username: 'alice',
  profileImageUrl: '',
  photoUrl: '',
  title: null,
  bio: 'Profile biography',
  tags: [],
  recentImageUrls: [],
  createdAt: timestamp(),
});

const privateAccountData = (userId = 'alice') => ({
  email: `${userId}@example.com`,
  phoneNumber: '+251900000000',
  notificationsEnabled: true,
  createdAt: timestamp(),
});

const placeData = (createdBy = 'alice', placeId = 'place-1') => ({
  id: placeId,
  name: 'Test Place',
  imageUrl: 'https://example.com/place.jpg',
  category: 'Cafe',
  location: 'Addis Ababa',
  priceRange: '$$',
  isOpen: true,
  latitude: 9.03,
  longitude: 38.74,
  tags: [],
  description: 'A sufficiently detailed place description.',
  priceLevel: 2,
  imageUrls: ['https://example.com/place.jpg'],
  amenities: [],
  createdAt: timestamp(),
  updatedAt: timestamp(),
  createdBy,
  rating: 0,
  ratingSum: 0,
  reviewCount: 0,
});

const newPlaceData = (createdBy = 'alice', placeId = 'place-1') => {
  const data = placeData(createdBy, placeId);
  delete data.rating;
  delete data.ratingSum;
  delete data.reviewCount;
  return data;
};

const reviewData = (
  userId = 'alice',
  placeId = 'place-1',
  reviewId = 'review-1',
) => ({
  id: reviewId,
  userId,
  placeId,
  rating: 5,
  reviewText: 'A useful review',
  createdAt: timestamp(),
});

const eventData = (createdBy = 'alice') => ({
  id: 'item-1',
  title: 'Community Event',
  category: 'Community',
  location: 'Addis Ababa',
  date: 'September 30',
  time: '6:00 PM',
  host: 'Alice',
  imageUrl: 'https://example.com/event.jpg',
  description: 'Event description',
  createdBy,
  latitude: 9.03,
  longitude: 38.74,
  createdAt: timestamp(),
  updatedAt: timestamp(),
});

const hangoutData = (createdBy = 'alice') => ({
  id: 'item-1',
  title: 'Coffee Hangout',
  category: 'Social',
  location: 'Addis Ababa',
  time: 'Saturday 4:00 PM',
  imageUrl: 'https://example.com/hangout.jpg',
  description: 'Hangout description',
  createdBy,
  latitude: 9.03,
  longitude: 38.74,
  createdAt: timestamp(),
  updatedAt: timestamp(),
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
  test('users create and update their own profile but cannot bypass trusted deletion', async () => {
    const alice = dbFor('alice');
    const ownRef = doc(alice, 'users/alice');

    await assertSucceeds(setDoc(ownRef, userData()));
    await assertSucceeds(
      updateDoc(ownRef, { name: 'Alice Updated', updatedAt: timestamp() }),
    );
    await assertFails(deleteDoc(ownRef));
  });

  test('a user cannot create or update another user profile', async () => {
    const alice = dbFor('alice');
    await assertFails(setDoc(doc(alice, 'users/bob'), userData('bob')));
    await seed('users/bob', userData('bob'));
    await assertFails(
      updateDoc(doc(alice, 'users/bob'), {
        name: 'Changed',
        updatedAt: timestamp(),
      }),
    );
  });

  test('private account identity email must match authentication', async () => {
    await assertFails(
      setDoc(doc(dbFor('alice'), 'users/alice/private/account'), {
        ...privateAccountData(),
        email: 'forged@example.com',
      }),
    );
  });

  test('profile owners cannot assign identity, trust, or relationship fields', async () => {
    await seed('users/alice', userData());
    const ownRef = doc(dbFor('alice'), 'users/alice');

    await assertFails(updateDoc(ownRef, { id: 'bob', updatedAt: timestamp() }));
    await assertFails(updateDoc(ownRef, { uid: 'bob', updatedAt: timestamp() }));
    await assertFails(
      updateDoc(ownRef, {
        email: 'attacker@example.com',
        updatedAt: timestamp(),
      }),
    );
    await assertFails(
      updateDoc(ownRef, { isVerified: true, updatedAt: timestamp() }),
    );
    await assertFails(updateDoc(ownRef, { roles: ['admin'], updatedAt: timestamp() }));
    await assertFails(
      updateDoc(ownRef, { followerIds: ['bob'], updatedAt: timestamp() }),
    );
    await assertFails(
      updateDoc(ownRef, { followingIds: ['bob'], updatedAt: timestamp() }),
    );
    await assertFails(updateDoc(ownRef, { createdAt: timestamp() }));
  });

  test('user profiles require authentication to read', async () => {
    await seed('users/alice', userData());
    await assertFails(getDoc(doc(publicDb(), 'users/alice')));
  });

  test('authenticated users can read another public profile', async () => {
    await seed('users/bob', userData('bob'));
    const snapshot = await assertSucceeds(
      getDoc(doc(dbFor('alice'), 'users/bob')),
    );
    assert.equal(snapshot.data()?.email, undefined);
    assert.equal(snapshot.data()?.phoneNumber, undefined);
  });

  test('private account fields cannot be injected into public profiles', async () => {
    await assertFails(
      setDoc(doc(dbFor('alice'), 'users/alice'), {
        ...userData(),
        email: 'alice@example.com',
      }),
    );
    await assertFails(
      setDoc(doc(dbFor('alice'), 'users/alice'), {
        ...userData(),
        phoneNumber: '+251911111111',
      }),
    );
  });
});

describe('private accounts', () => {
  test('owners can create, read, and update allowed private fields', async () => {
    const accountRef = doc(dbFor('alice'), 'users/alice/private/account');
    await assertSucceeds(setDoc(accountRef, privateAccountData()));
    await assertSucceeds(getDoc(accountRef));
    await assertSucceeds(
      updateDoc(accountRef, {
        phoneNumber: '+251911111111',
        notificationsEnabled: false,
        updatedAt: timestamp(),
      }),
    );
    await assertFails(deleteDoc(accountRef));
  });

  test('private identity and trusted fields cannot be changed or injected', async () => {
    await seed('users/alice/private/account', privateAccountData());
    const accountRef = doc(dbFor('alice'), 'users/alice/private/account');
    await assertFails(
      updateDoc(accountRef, {
        email: 'changed@example.com',
        updatedAt: timestamp(),
      }),
    );
    await assertFails(
      updateDoc(accountRef, { roles: ['admin'], updatedAt: timestamp() }),
    );
  });

  test('other users and unauthenticated clients cannot access private accounts', async () => {
    await seed('users/alice/private/account', privateAccountData());
    const bobRef = doc(dbFor('bob'), 'users/alice/private/account');
    const publicRef = doc(publicDb(), 'users/alice/private/account');
    await assertFails(getDoc(bobRef));
    await assertFails(
      updateDoc(bobRef, { phoneNumber: '+251922222222', updatedAt: timestamp() }),
    );
    await assertFails(getDoc(publicRef));
  });
});

describe('saved places', () => {
  test('a user can read and write their own saved places only', async () => {
    const alice = dbFor('alice');
    const own = doc(alice, 'users/alice/saved_places/place-1');

    await assertSucceeds(setDoc(own, { savedAt: timestamp() }));
    await assertSucceeds(getDoc(own));
    await assertFails(
      setDoc(doc(alice, 'users/bob/saved_places/place-1'), {
        savedAt: timestamp(),
      }),
    );
    await seed('users/bob/saved_places/place-2', { placeId: 'place-2' });
    await assertFails(getDoc(doc(alice, 'users/bob/saved_places/place-2')));
    await assertFails(setDoc(doc(alice, 'users/alice/saved_places/bad'), {
      savedAt: timestamp(),
      userId: 'bob',
    }));
  });
});

describe('following and followers', () => {
  test('the app follow transaction paths and payloads are allowed', async () => {
    const alice = dbFor('alice');
    const followingRef = doc(alice, 'users/alice/following/bob');
    const followerRef = doc(alice, 'users/bob/followers/alice');
    const followBatch = writeBatch(alice);
    followBatch.set(followingRef, { userId: 'bob', createdAt: timestamp() });
    followBatch.set(followerRef, { userId: 'alice', createdAt: timestamp() });
    await assertSucceeds(followBatch.commit());
    await assertSucceeds(getDoc(followingRef));
    await assertSucceeds(getDoc(followerRef));
    const unfollowBatch = writeBatch(alice);
    unfollowBatch.delete(followingRef);
    unfollowBatch.delete(followerRef);
    await assertSucceeds(unfollowBatch.commit());
  });

  test('self-follow, mismatched payloads, and another user following state are denied', async () => {
    const alice = dbFor('alice');
    await assertFails(
      setDoc(doc(alice, 'users/alice/following/alice'), {
        userId: 'alice',
        createdAt: timestamp(),
      }),
    );
    await assertFails(
      setDoc(doc(alice, 'users/alice/following/bob'), {
        userId: 'charlie',
        createdAt: timestamp(),
      }),
    );
    await assertFails(
      setDoc(doc(alice, 'users/bob/following/charlie'), {
        userId: 'charlie',
        createdAt: timestamp(),
      }),
    );
    await assertFails(
      setDoc(doc(alice, 'users/bob/followers/charlie'), {
        userId: 'charlie',
        createdAt: timestamp(),
      }),
    );
    await assertFails(
      setDoc(doc(alice, 'users/alice/following/bob'), {
        userId: 'bob',
        createdAt: timestamp(),
        role: 'admin',
      }),
    );
    await assertFails(
      setDoc(doc(alice, 'users/alice/following/bob'), {
        userId: 'bob',
        createdAt: timestamp(),
      }),
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
      setDoc(doc(alice, 'places/wrong-owner'), newPlaceData('bob', 'wrong-owner')),
    );
    await assertFails(
      setDoc(doc(alice, 'places/nonzero-rating'), {
        ...newPlaceData('alice', 'nonzero-rating'),
        rating: 4.5,
      }),
    );
    await assertFails(
      setDoc(doc(alice, 'places/client-zero-aggregates'), {
        ...newPlaceData('alice', 'client-zero-aggregates'),
        rating: 0,
        reviewCount: 0,
      }),
    );
    await assertFails(
      setDoc(doc(alice, 'places/client-rating-sum'), {
        ...newPlaceData('alice', 'client-rating-sum'),
        ratingSum: 0,
      }),
    );
  });

  test('only creator can update/delete and protected fields are immutable', async () => {
    await seed('places/place-1', placeData());
    const aliceRef = doc(dbFor('alice'), 'places/place-1');
    const bobRef = doc(dbFor('bob'), 'places/place-1');

    await assertSucceeds(
      updateDoc(aliceRef, { name: 'Updated Place', updatedAt: timestamp() }),
    );
    await assertFails(updateDoc(aliceRef, { createdBy: 'bob' }));
    await assertFails(updateDoc(aliceRef, { rating: 5 }));
    await assertFails(updateDoc(aliceRef, { ratingSum: 5 }));
    await assertFails(updateDoc(aliceRef, { reviewCount: 10 }));
    await assertFails(
      updateDoc(aliceRef, {
        aggregateUpdatedAt: Timestamp.fromDate(new Date()),
      }),
    );
    await assertFails(
      updateDoc(bobRef, { name: 'Hijacked', updatedAt: timestamp() }),
    );
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
        reviewData('bob', 'place-1', 'wrong-user'),
      ),
    );
    await assertFails(
      setDoc(
        doc(alice, 'places/place-1/reviews/wrong-place'),
        reviewData('alice', 'place-2', 'wrong-place'),
      ),
    );
    await assertFails(
      setDoc(doc(alice, 'places/place-1/reviews/invalid-rating'), {
        ...reviewData('alice', 'place-1', 'invalid-rating'),
        rating: 6,
      }),
    );
    await assertFails(
      setDoc(doc(alice, 'places/place-1/reviews/invalid-timestamp'), {
        ...reviewData('alice', 'place-1', 'invalid-timestamp'),
        createdAt: '2026-09-25T00:00:00Z',
      }),
    );
    await assertFails(
      setDoc(doc(alice, 'places/place-1/reviews/malformed'), {
        ...reviewData('alice', 'place-1', 'malformed'),
        reviewText: 42,
      }),
    );
    await assertFails(
      setDoc(doc(alice, 'places/place-1/reviews/client-trusted-fields'), {
        ...reviewData('alice', 'place-1', 'client-trusted-fields'),
        likedUserIds: ['alice'],
        reportCount: 1,
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
    await assertFails(updateDoc(aliceRef, { id: 'another-review' }));
    await assertFails(updateDoc(aliceRef, { likedUserIds: ['alice'] }));
    await assertFails(updateDoc(aliceRef, { reportCount: 1 }));
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
      const data = collection === 'events' ? eventData() : hangoutData();
      await assertSucceeds(setDoc(aliceRef, data));
      await assertSucceeds(
        updateDoc(aliceRef, { title: 'Updated Item', updatedAt: timestamp() }),
      );
      await assertSucceeds(deleteDoc(aliceRef));
    });

    test('ownership claims, transfers, and writes by another user are denied', async () => {
      const alice = dbFor('alice');
      const dataFor = collection === 'events' ? eventData : hangoutData;
      await assertFails(
        setDoc(doc(alice, `${collection}/wrong-owner`), {
          ...dataFor('bob'),
          id: 'wrong-owner',
        }),
      );
      await seed(`${collection}/item-1`, dataFor());
      await assertFails(
        updateDoc(doc(alice, `${collection}/item-1`), { createdBy: 'bob' }),
      );
      await assertFails(
        updateDoc(doc(alice, `${collection}/item-1`), {
          attendeeCount: 99,
          updatedAt: timestamp(),
        }),
      );
      await assertFails(
        updateDoc(doc(alice, `${collection}/item-1`), {
          [collection === 'events' ? 'isFeatured' : 'isLive']: true,
          updatedAt: timestamp(),
        }),
      );
      const bobRef = doc(dbFor('bob'), `${collection}/item-1`);
      await assertFails(
        updateDoc(bobRef, { title: 'Hijacked', updatedAt: timestamp() }),
      );
      await assertFails(deleteDoc(bobRef));
    });
  });
}

describe('unauthenticated writes', () => {
  test('publicly readable product data remains protected from anonymous writes', async () => {
    const unauthenticated = publicDb();
    await assertFails(
      setDoc(doc(unauthenticated, 'places/place-1'), newPlaceData()),
    );
    await assertFails(
      setDoc(
        doc(unauthenticated, 'places/place-1/reviews/review-1'),
        reviewData(),
      ),
    );
    await assertFails(
      setDoc(doc(unauthenticated, 'events/item-1'), eventData()),
    );
    await assertFails(
      setDoc(doc(unauthenticated, 'hangouts/item-1'), hangoutData()),
    );
  });
});

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
