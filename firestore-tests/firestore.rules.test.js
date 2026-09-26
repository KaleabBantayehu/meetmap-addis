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
  collection,
  deleteDoc,
  doc,
  documentId,
  getDoc,
  getDocs,
  limit,
  orderBy,
  query,
  setDoc,
  startAfter,
  Timestamp,
  updateDoc,
  where,
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
  searchPrefixes: ['te', 'tes', 'test', 'ca', 'caf', 'cafe'],
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
    const legacyPlace = newPlaceData('alice', 'legacy-search');
    delete legacyPlace.searchPrefixes;
    await assertSucceeds(
      setDoc(doc(alice, 'places/legacy-search'), legacyPlace),
    );
    await assertFails(
      setDoc(doc(alice, 'places/oversized-search'), {
        ...newPlaceData('alice', 'oversized-search'),
        searchPrefixes: Array.from({ length: 201 }, (_, index) => `p${index}`),
      }),
    );
  });

  test('public place prefix search supports stable document ordering', async () => {
    await seed('places/search-a', placeData('alice', 'search-a'));
    await seed('places/search-b', placeData('alice', 'search-b'));
    const searchQuery = query(
      collection(publicDb(), 'places'),
      where('searchPrefixes', 'array-contains', 'cafe'),
      orderBy(documentId()),
      limit(1),
    );
    const snapshot = await assertSucceeds(getDocs(searchQuery));
    assert.equal(snapshot.docs.length, 1);
    assert.equal(snapshot.docs[0].id, 'search-a');
  });

  test('public geographic candidates support bounded stable pagination', async () => {
    await seed('places/geo-a', {
      ...placeData('alice', 'geo-a'),
      latitude: 9.01,
      longitude: 38.71,
    });
    await seed('places/geo-b', {
      ...placeData('alice', 'geo-b'),
      latitude: 9.02,
      longitude: 38.72,
    });
    const base = collection(publicDb(), 'places');
    const firstQuery = query(
      base,
      where('latitude', '>=', 9),
      where('latitude', '<=', 9.1),
      where('longitude', '>=', 38.7),
      where('longitude', '<=', 38.8),
      orderBy('latitude'),
      orderBy('longitude'),
      orderBy(documentId()),
      limit(1),
    );
    const first = await assertSucceeds(getDocs(firstQuery));
    assert.equal(first.docs.length, 1);
    assert.equal(first.docs[0].id, 'geo-a');

    const secondQuery = query(
      base,
      where('latitude', '>=', 9),
      where('latitude', '<=', 9.1),
      where('longitude', '>=', 38.7),
      where('longitude', '<=', 38.8),
      orderBy('latitude'),
      orderBy('longitude'),
      orderBy(documentId()),
      startAfter(9.01, 38.71, 'geo-a'),
      limit(1),
    );
    const second = await assertSucceeds(getDocs(secondQuery));
    assert.equal(second.docs.length, 1);
    assert.equal(second.docs[0].id, 'geo-b');
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

for (const collectionName of ['events', 'hangouts']) {
  describe(collectionName, () => {
    test('creator can create, update, and delete their own document', async () => {
      const aliceRef = doc(dbFor('alice'), `${collectionName}/item-1`);
      const data = collectionName === 'events' ? eventData() : hangoutData();
      await assertSucceeds(setDoc(aliceRef, data));
      await assertSucceeds(
        updateDoc(aliceRef, { title: 'Updated Item', updatedAt: timestamp() }),
      );
      await assertSucceeds(deleteDoc(aliceRef));
    });

    test('clients may create active or legacy content but not inactive content', async () => {
      const alice = dbFor('alice');
      const dataFor = collectionName === 'events' ? eventData : hangoutData;
      await assertSucceeds(
        setDoc(doc(alice, `${collectionName}/active-item`), {
          ...dataFor(),
          id: 'active-item',
          lifecycleStatus: 'active',
        }),
      );
      await assertFails(
        setDoc(doc(alice, `${collectionName}/inactive-item`), {
          ...dataFor(),
          id: 'inactive-item',
          lifecycleStatus: collectionName === 'events' ? 'archived' : 'inactive',
        }),
      );
    });

    test('ownership claims, transfers, and writes by another user are denied', async () => {
      const alice = dbFor('alice');
      const dataFor = collectionName === 'events' ? eventData : hangoutData;
      await assertFails(
        setDoc(doc(alice, `${collectionName}/wrong-owner`), {
          ...dataFor('bob'),
          id: 'wrong-owner',
        }),
      );
      await seed(`${collectionName}/item-1`, dataFor());
      await assertFails(
        updateDoc(doc(alice, `${collectionName}/item-1`), { createdBy: 'bob' }),
      );
      await assertFails(
        updateDoc(doc(alice, `${collectionName}/item-1`), {
          attendeeCount: 99,
          updatedAt: timestamp(),
        }),
      );
      await assertFails(
        updateDoc(doc(alice, `${collectionName}/item-1`), {
          [collectionName === 'events' ? 'isFeatured' : 'isLive']: true,
          updatedAt: timestamp(),
        }),
      );
      const bobRef = doc(dbFor('bob'), `${collectionName}/item-1`);
      await assertFails(
        updateDoc(bobRef, { title: 'Hijacked', updatedAt: timestamp() }),
      );
      await assertFails(deleteDoc(bobRef));
    });
  });
}

describe('lifecycle-aware discovery', () => {
  for (const collectionName of ['events', 'hangouts']) {
    test(`${collectionName} active query excludes retained and unbackfilled legacy documents`, async () => {
      const dataFor = collectionName === 'events' ? eventData : hangoutData;
      await seed(`${collectionName}/active-a`, {
        ...dataFor(),
        id: 'active-a',
        lifecycleStatus: 'active',
      });
      await seed(`${collectionName}/active-b`, {
        ...dataFor(),
        id: 'active-b',
        lifecycleStatus: 'active',
      });
      await seed(`${collectionName}/retained`, {
        ...dataFor(),
        id: 'retained',
        createdBy: null,
        lifecycleStatus: collectionName === 'events' ? 'archived' : 'inactive',
      });
      await seed(`${collectionName}/legacy`, {
        ...dataFor(),
        id: 'legacy',
      });

      const first = await assertSucceeds(
        getDocs(
          query(
            collection(publicDb(), collectionName),
            where('lifecycleStatus', '==', 'active'),
            orderBy(documentId()),
            limit(1),
          ),
        ),
      );
      assert.deepEqual(first.docs.map((item) => item.id), ['active-a']);
      const second = await assertSucceeds(
        getDocs(
          query(
            collection(publicDb(), collectionName),
            where('lifecycleStatus', '==', 'active'),
            orderBy(documentId()),
            startAfter('active-a'),
            limit(1),
          ),
        ),
      );
      assert.deepEqual(second.docs.map((item) => item.id), ['active-b']);
    });
  }

  test('featured event query returns only active featured events', async () => {
    await seed('events/active-featured', {
      ...eventData(),
      id: 'active-featured',
      lifecycleStatus: 'active',
      isFeatured: true,
    });
    await seed('events/active-standard', {
      ...eventData(),
      id: 'active-standard',
      lifecycleStatus: 'active',
      isFeatured: false,
    });
    await seed('events/archived-featured', {
      ...eventData(),
      id: 'archived-featured',
      createdBy: null,
      lifecycleStatus: 'archived',
      isFeatured: true,
    });

    const snapshot = await assertSucceeds(
      getDocs(
        query(
          collection(publicDb(), 'events'),
          where('lifecycleStatus', '==', 'active'),
          where('isFeatured', '==', true),
          limit(10),
        ),
      ),
    );
    assert.deepEqual(snapshot.docs.map((item) => item.id), [
      'active-featured',
    ]);
  });
});

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

describe('trusted account lifecycle fields', () => {
  test('ordinary clients cannot inject or change lifecycle ownership fields', async () => {
    const alice = dbFor('alice');
    const place = newPlaceData('alice', 'lifecycle-place');
    place.lifecycleStatus = 'systemManaged';
    await assertFails(setDoc(doc(alice, 'places/lifecycle-place'), place));

    await seed('places/lifecycle-place', placeData('alice', 'lifecycle-place'));
    await assertFails(
      updateDoc(doc(alice, 'places/lifecycle-place'), {
        lifecycleStatus: 'systemManaged',
      }),
    );

    await seed(
      'places/lifecycle-place/reviews/review-1',
      reviewData('alice', 'lifecycle-place', 'review-1'),
    );
    await assertFails(
      updateDoc(
        doc(alice, 'places/lifecycle-place/reviews/review-1'),
        { userId: 'deleted-user', authorStatus: 'deleted' },
      ),
    );
  });

  test('account document deletion remains unavailable to clients', async () => {
    await seed('users/alice', userData('alice'));
    await seed('users/alice/private/account', privateAccountData('alice'));
    const alice = dbFor('alice');
    await assertFails(deleteDoc(doc(alice, 'users/alice')));
    await assertFails(deleteDoc(doc(alice, 'users/alice/private/account')));
    await assertFails(deleteDoc(doc(publicDb(), 'users/alice')));
  });

  test('retained lifecycle documents cannot be claimed, edited, or deleted', async () => {
    const systemPlace = placeData('alice', 'system-place');
    systemPlace.createdBy = null;
    systemPlace.lifecycleStatus = 'systemManaged';
    const archivedEvent = eventData('alice');
    archivedEvent.createdBy = null;
    archivedEvent.lifecycleStatus = 'archived';
    const inactiveHangout = hangoutData('alice');
    inactiveHangout.createdBy = null;
    inactiveHangout.lifecycleStatus = 'inactive';
    await seed('places/system-place', systemPlace);
    await seed('events/archived-event', archivedEvent);
    await seed('hangouts/inactive-hangout', inactiveHangout);

    const alice = dbFor('alice');
    for (const path of [
      'places/system-place',
      'events/archived-event',
      'hangouts/inactive-hangout',
    ]) {
      await assertFails(updateDoc(doc(alice, path), { createdBy: 'alice' }));
      await assertFails(updateDoc(doc(alice, path), { lifecycleStatus: 'active' }));
      await assertFails(deleteDoc(doc(alice, path)));
    }
  });

  test('anonymized reviews are unowned and immutable to all clients', async () => {
    const review = reviewData('alice', 'place-1', 'anonymous-review');
    review.userId = null;
    review.authorStatus = 'deleted';
    review.anonymizedAt = timestamp();
    await seed('places/place-1/reviews/anonymous-review', review);

    for (const uid of ['alice', 'bob', 'deleted-user']) {
      const reference = doc(
        dbFor(uid),
        'places/place-1/reviews/anonymous-review',
      );
      await assertFails(updateDoc(reference, { reviewText: 'Changed' }));
      await assertFails(deleteDoc(reference));
    }
  });
});
