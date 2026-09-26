import { FieldValue } from 'firebase-admin/firestore';

async function updateDocuments(db, query, data) {
  const snapshot = await query.get();
  if (snapshot.empty) return 0;
  const writer = db.bulkWriter();
  for (const document of snapshot.docs) writer.update(document.ref, data);
  await writer.close();
  return snapshot.size;
}

async function deleteRelationshipDocuments(db, uid) {
  const [following, followers] = await Promise.all([
    db.collectionGroup('following').where('userId', '==', uid).get(),
    db.collectionGroup('followers').where('userId', '==', uid).get(),
  ]);
  const paths = new Set([
    ...following.docs.flatMap((document) => {
      const ownerUid = document.ref.parent.parent.id;
      return [
        document.ref.path,
        `users/${uid}/followers/${ownerUid}`,
      ];
    }),
    ...followers.docs.flatMap((document) => {
      const targetUid = document.ref.parent.parent.id;
      return [
        document.ref.path,
        `users/${uid}/following/${targetUid}`,
      ];
    }),
  ]);
  if (paths.size === 0) return 0;
  const writer = db.bulkWriter();
  for (const path of paths) writer.delete(db.doc(path));
  await writer.close();
  return paths.size;
}

export async function deleteMeetMapAccount({ db, auth, uid }) {
  if (!uid) throw new Error('Authenticated user ID is required');
  const changedAt = FieldValue.serverTimestamp();

  const [reviewCount, placeCount, eventCount, hangoutCount] =
    await Promise.all([
      updateDocuments(
        db,
        db.collectionGroup('reviews').where('userId', '==', uid),
        {
          userId: null,
          authorStatus: 'deleted',
          anonymizedAt: changedAt,
        },
      ),
      updateDocuments(db, db.collection('places').where('createdBy', '==', uid), {
        createdBy: null,
        lifecycleStatus: 'systemManaged',
        lifecycleUpdatedAt: changedAt,
      }),
      updateDocuments(db, db.collection('events').where('createdBy', '==', uid), {
        createdBy: null,
        lifecycleStatus: 'archived',
        lifecycleUpdatedAt: changedAt,
      }),
      updateDocuments(db, db.collection('hangouts').where('createdBy', '==', uid), {
        createdBy: null,
        lifecycleStatus: 'inactive',
        lifecycleUpdatedAt: changedAt,
      }),
    ]);

  const relationshipCount = await deleteRelationshipDocuments(db, uid);
  await db.recursiveDelete(db.doc(`users/${uid}`));

  try {
    await auth.deleteUser(uid);
  } catch (error) {
    if (error?.code !== 'auth/user-not-found') throw error;
  }

  return {
    uid,
    reviewCount,
    placeCount,
    eventCount,
    hangoutCount,
    relationshipCount,
  };
}

export async function deleteAccountFromRequest({ db, auth, request }) {
  const uid = request.auth?.uid;
  if (!uid) {
    const error = new Error('Authentication is required');
    error.code = 'unauthenticated';
    throw error;
  }
  return deleteMeetMapAccount({ db, auth, uid });
}
