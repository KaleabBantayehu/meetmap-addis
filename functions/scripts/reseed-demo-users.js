import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { buildDemoUserDocuments } from '../src/demo-user-reseed.js';

function option(name) {
  const prefix = `--${name}=`;
  const argument = process.argv.slice(2).find((value) => value.startsWith(prefix));
  return argument?.slice(prefix.length).trim();
}

function hasFlag(name) {
  return process.argv.slice(2).includes(`--${name}`);
}

async function selectedUsers(auth) {
  const uidOption = option('uids');
  if (uidOption) {
    const uids = [...new Set(uidOption.split(',').map((uid) => uid.trim()))]
      .filter(Boolean);
    if (uids.length === 0) throw new Error('At least one UID is required');
    const result = await auth.getUsers(uids.map((uid) => ({ uid })));
    if (result.notFound.length > 0) {
      throw new Error('One or more requested Firebase Auth users do not exist');
    }
    return result.users;
  }

  if (!hasFlag('all-auth-users')) {
    throw new Error('Provide --uids=<uid,...> or --all-auth-users');
  }

  const users = [];
  let pageToken;
  do {
    const page = await auth.listUsers(1000, pageToken);
    users.push(...page.users);
    pageToken = page.pageToken;
  } while (pageToken);
  return users;
}

const projectId = option('project');
if (!projectId) {
  throw new Error('Provide the target Firebase project with --project=<id>');
}

const shouldWrite = hasFlag('confirm');
initializeApp({ credential: applicationDefault(), projectId });
const auth = getAuth();
const db = getFirestore();
const users = await selectedUsers(auth);

for (const authUser of users) {
  const publicRef = db.doc(`users/${authUser.uid}`);
  const privateRef = publicRef.collection('private').doc('account');
  const [publicSnapshot, privateSnapshot] = await Promise.all([
    publicRef.get(),
    privateRef.get(),
  ]);
  const timestamp = FieldValue.serverTimestamp();
  const documents = buildDemoUserDocuments({
    authUser,
    existingPublic: publicSnapshot.data() ?? {},
    existingPrivate: privateSnapshot.data() ?? {},
    timestamp,
  });

  if (shouldWrite) {
    const batch = db.batch();
    batch.set(publicRef, documents.publicProfile);
    batch.set(privateRef, documents.privateAccount);
    await batch.commit();
  }

  console.log(JSON.stringify({
    uid: authUser.uid,
    mode: shouldWrite ? 'written' : 'dry-run',
    publicPath: publicRef.path,
    privatePath: privateRef.path,
  }));
}

console.log(JSON.stringify({
  projectId,
  usersProcessed: users.length,
  mode: shouldWrite ? 'written' : 'dry-run',
}));
