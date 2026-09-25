import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

import { reconcilePlaceReviewAggregate } from '../src/review-aggregates.js';

function argumentValue(name) {
  const index = process.argv.indexOf(name);
  return index >= 0 ? process.argv[index + 1] : null;
}

const placeId = argumentValue('--place');
const projectId = argumentValue('--project');
const confirmed = process.argv.includes('--confirm');

if (!placeId || !projectId || !confirmed) {
  console.error(
    'Usage: npm run reconcile:place -- --place <placeId> '
      + '--project <projectId> --confirm',
  );
  process.exitCode = 1;
} else {
  initializeApp({ credential: applicationDefault(), projectId });
  const result = await reconcilePlaceReviewAggregate(getFirestore(), placeId);
  console.log(JSON.stringify(result));
}
