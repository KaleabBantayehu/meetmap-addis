import { describe, test } from 'node:test';
import assert from 'node:assert/strict';
import { buildDemoUserDocuments } from '../src/demo-user-reseed.js';

describe('demo user reseed contract', () => {
  test('separates public profile and private account fields', () => {
    const timestamp = { serverTimestamp: true };
    const { publicProfile, privateAccount } = buildDemoUserDocuments({
      authUser: {
        uid: 'alice',
        email: 'auth@example.com',
        phoneNumber: '+251911111111',
        displayName: 'Auth Alice',
        photoURL: 'https://example.com/auth.jpg',
      },
      existingPublic: {
        name: 'Alice',
        username: 'alice',
        email: 'legacy@example.com',
        phoneNumber: '+251900000000',
        notificationsEnabled: false,
        followingIds: ['bob'],
        followerIds: ['bob'],
        savedPlaceIds: ['place-1'],
        reviewIds: ['review-1'],
        joinedHangoutIds: ['hangout-1'],
        isVerified: true,
      },
      timestamp,
    });

    assert.equal(publicProfile.id, 'alice');
    assert.equal(publicProfile.name, 'Alice');
    assert.equal(publicProfile.isVerified, true);
    for (const privateField of [
      'email',
      'phoneNumber',
      'notificationsEnabled',
      'followingIds',
      'followerIds',
      'savedPlaceIds',
      'reviewIds',
      'joinedHangoutIds',
    ]) {
      assert.equal(privateField in publicProfile, false);
    }
    assert.equal(privateAccount.email, 'auth@example.com');
    assert.equal(privateAccount.phoneNumber, '+251911111111');
    assert.equal(privateAccount.notificationsEnabled, false);
  });

  test('is deterministic for the same inputs and preserves existing timestamps', () => {
    const timestamp = 'updated';
    const input = {
      authUser: { uid: 'bob', email: 'bob@example.com' },
      existingPublic: { createdAt: 'public-created' },
      existingPrivate: { createdAt: 'private-created' },
      timestamp,
    };

    const first = buildDemoUserDocuments(input);
    const second = buildDemoUserDocuments(input);
    assert.deepEqual(first, second);
    assert.equal(first.publicProfile.createdAt, 'public-created');
    assert.equal(first.privateAccount.createdAt, 'private-created');
  });
});
