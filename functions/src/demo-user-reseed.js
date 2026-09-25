const PUBLIC_STRING_FIELDS = [
  'username',
  'title',
  'bio',
];

function firstDefined(...values) {
  return values.find((value) => value !== undefined && value !== null);
}

export function buildDemoUserDocuments({
  authUser,
  existingPublic = {},
  existingPrivate = {},
  timestamp,
}) {
  if (!authUser?.uid) throw new Error('Firebase Auth UID is required');
  if (timestamp == null) throw new Error('A timestamp value is required');

  const uid = authUser.uid;
  const profileImageUrl = firstDefined(
    existingPublic.profileImageUrl,
    existingPublic.photoUrl,
    authUser.photoURL,
  ) ?? '';
  const publicProfile = {
    id: uid,
    uid,
    name: firstDefined(
      existingPublic.name,
      authUser.displayName,
      'MeetMap User',
    ),
    tags: Array.isArray(existingPublic.tags) ? existingPublic.tags : [],
    recentImageUrls: Array.isArray(existingPublic.recentImageUrls)
      ? existingPublic.recentImageUrls
      : [],
    profileImageUrl,
    photoUrl: profileImageUrl,
    isVerified: existingPublic.isVerified === true,
    createdAt: firstDefined(existingPublic.createdAt, timestamp),
    updatedAt: timestamp,
  };

  for (const field of PUBLIC_STRING_FIELDS) {
    publicProfile[field] = firstDefined(
      existingPublic[field],
    ) ?? null;
  }

  const privateAccount = {
    email: firstDefined(authUser.email, existingPrivate.email) ?? null,
    phoneNumber: firstDefined(
      authUser.phoneNumber,
      existingPrivate.phoneNumber,
      existingPublic.phoneNumber,
    ) ?? null,
    notificationsEnabled: firstDefined(
      existingPrivate.notificationsEnabled,
      existingPublic.notificationsEnabled,
      true,
    ),
    createdAt: firstDefined(existingPrivate.createdAt, timestamp),
    updatedAt: timestamp,
  };

  return { publicProfile, privateAccount };
}
