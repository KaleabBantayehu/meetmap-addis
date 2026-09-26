# Phase 4 Production Readiness And Activation Plan

- Status: Preparation only
- Date: 2026-09-26
- Production project: `meetmap-addis`
- Safety boundary: no deployment, production write, migration, or credential creation is authorized by this document

## Release Gates

The permanent Android application ID is the first gate. The app and current Firebase Android configuration both use `com.example.meetmap_addis`. Engineering must either approve that value as permanent or select the permanent ID before Play Store registration, release signing finalization, Firebase Android app replacement, Google OAuth fingerprint registration, or production App Check activation. Changing it later creates a different Android application identity.

Cloud Functions are the second gate. `maintainPlaceReviewAggregate` and `deleteAccount` are required production contracts and cannot be deployed without Blaze billing. The current client must not be released with account deletion exposed while its callable is unavailable.

## Production Readiness Matrix

| Component | Current state | Required action | Risk | Blocker? | Owner/action |
| --- | --- | --- | --- | --- | --- |
| Android identity | Source and Firebase config agree on `com.example.meetmap_addis` | Approve it permanently or choose the final ID, then regenerate Firebase config | A later rename breaks Play/Firebase identity continuity | Yes | Product/engineering decision |
| Release signing | Gradle requires local `key.properties`; debug fallback is disabled | Store the release keystore securely, record recovery ownership, and verify signed AAB | Lost key or wrong certificate blocks updates and Google sign-in | Yes | Release owner |
| Firebase Authentication | Email/password and Google client code exist | Confirm providers, support email, authorized domains, and release SHA-1/SHA-256 | Release Google sign-in may fail | Yes | Firebase Console owner |
| Firestore rules | Versioned and emulator-tested | Review deployed diff, deploy, then smoke-test least privilege | Wrong deployment can reject valid writes or expose data | Yes | Backend owner |
| Firestore indexes | Geographic composite is versioned | Deploy and wait for `READY`; verify no console-only dependency | Geo query fails with missing-index error | Yes | Backend owner |
| Review aggregate Function | Implemented and tested | Enable Blaze, deploy, reconcile existing places, monitor failures | Cards show stale aggregates; failed deltas require reconciliation | Yes | Backend owner |
| Account deletion callable | Auth UID-derived and App Check-enforced | Enable Blaze, deploy, and test with a disposable account | Existing UI cannot complete deletion without the callable | Yes | Backend/release owner |
| App Check | Debug provider in debug; Play Integrity in release; callable enforcement enabled | Register Play app/signing certificate, configure Play Integrity, then validate tokens before enforcement expansion | Misconfiguration blocks callable requests | Yes | Firebase/Play Console owner |
| Place search | New writes produce bounded `searchPrefixes` | Backfill missing fields before enabling production search | Legacy places are absent from search | Yes for complete search | Data owner |
| Event/hangout lifecycle | New writes allow explicit `active`; reads require it | Backfill only missing lifecycle fields before releasing filtered client | Legacy content disappears from discovery | Yes | Data owner |
| Aggregate idempotency markers | Durable and intentionally unbounded | Monitor count/storage; do not add TTL without a replay bound | Gradual storage growth | No | Operations |
| Local/session caches | UID-scoped where private; race tests pass | Real-device account-switch and cold-start testing | Cross-account leakage if platform behavior differs | Yes | QA |
| Cloudinary | Unsigned preset client flow | Restrict preset, formats, size, transformations, and abuse exposure; test real uploads | Upload abuse or failed media workflows | Yes | Cloudinary owner |
| Gebeta | Client key is bundled through `.env` | Apply provider restrictions/quotas and run release-device map/directions tests | Client keys are extractable and may be abused | Yes | Gebeta account owner |
| Crash reporting | No Crashlytics dependency/configuration found | Add before broad beta, or establish a documented manual feedback/log collection process for controlled testing | Production crashes may be invisible | No for controlled testing | Release owner |
| Advanced search/geo/social scaling | Deliberately bounded implementation | Measure usage before further work | Premature complexity | No | DEFER |

## Migration Plan

No general production backfill tool currently exists. `reseed-demo-users.js` is scoped to demo users and `reconcile-place.js` handles one explicitly confirmed place; neither should be repurposed silently.

Any new migration utility must use Application Default Credentials, require an explicit project ID, default to dry-run, require a separate confirmation flag for writes, process bounded batches, resume from a document-ID checkpoint, and emit counts without logging private document contents. Run it first against the emulator and then a non-production project.

### Place Search Prefixes

1. Export/backup Firestore and record the pre-migration place count.
2. Dry-run every place using the same normalization contract as `place_search_index.dart`.
3. Select only documents where `searchPrefixes` is missing. Do not overwrite an existing field during the initial backfill.
4. Report scanned, eligible, unchanged, malformed, and proposed-update counts.
5. Review a sample containing mixed case, repeated whitespace, multi-word names, categories, locations, and tags.
6. During an approved window, write bounded batches with checkpointing.
7. Verify eligible documents have at most 200 normalized prefixes and execute representative production searches.

Rollback uses the migration manifest of changed document IDs to remove only fields added by this migration, or restores the Firestore export. Removing the fields while the search client is active makes those places undiscoverable, so client rollback must accompany data rollback.

### Event And Hangout Lifecycle

1. Export/backup Firestore and count documents by existing lifecycle value, including missing fields.
2. Dry-run events and hangouts separately.
3. Update only documents where `lifecycleStatus` is absent: events become `active`; hangouts become `active`.
4. Never overwrite `archived`, `inactive`, or another explicit state.
5. Record every changed path in a migration manifest and verify active-query counts before release.
6. Confirm archived events and inactive hangouts remain excluded.

Rollback can remove `lifecycleStatus` only from manifest-listed documents or restore the export. Because the new client excludes missing fields, rollback also requires restoring the previous client/query behavior.

### Review Aggregates

Existing places must be reconciled from authoritative review subcollections before cards rely on `rating`, `ratingSum`, and `reviewCount`. Use a controlled review-write maintenance window: deploy the trigger, prevent new review mutations, wait for in-flight events, reconcile every place with checkpointing, verify sampled review totals, then reopen writes. This avoids a delayed delta racing a full recomputation. The existing one-place script remains an operator repair tool, not a bulk migration.

## Phase 4.1 Migration Tooling

Phase 4.1 adds three bounded Firebase Admin commands under `functions/scripts/migrations`. They require an explicit project ID and default to dry-run mode:

```text
cd functions
node scripts/migrations/backfill-search-prefixes.js --project=<project-id>
node scripts/migrations/backfill-lifecycle-status.js --project=<project-id>
node scripts/migrations/reconcile-review-aggregates.js --project=<project-id>
```

Dry runs read bounded document-ID pages, calculate proposed changes, print summary counts, and perform no Firestore writes. Optional dry-run checkpoint and manifest paths can be supplied with `--checkpoint=<path>` and `--manifest=<path>`.

Write mode additionally requires both checkpoint and manifest paths:

```text
--write --checkpoint=<path> --manifest=<path>
```

For the recognized production project `meetmap-addis`, write mode is rejected unless `--confirm-production` is also present. Supplying these flags is an authorization mechanism for the command, not authorization from this document to execute a production migration.

The checkpoint schema version is `1`. Every non-empty checkpoint is bound to its migration name, schema version, Firebase project ID, and execution mode (`dry-run` or `write`). The command validates that identity before Firebase initialization and rejects any mismatch without reading or writing Firestore. A dry-run checkpoint cannot be reused for a production write, and a write checkpoint cannot be reused for a dry run. Start write mode with a new checkpoint path, then reuse only that write-mode checkpoint when resuming the same migration and project.

The checkpoint also contains the last processed document ID, timestamp, and counts. Lifecycle checkpoints retain independent `events` and `hangouts` cursors so progress in one collection cannot discard progress in the other. Checkpoints are atomically replaced after a successfully processed page. Infrastructure or batch-write failure leaves the prior checkpoint in place so the page can be retried. Resume with the same migration, project, mode, and checkpoint path. Batch size defaults to 100 and is restricted to 1 through 400 with `--batch-size=<n>`.

The manifest is append-only JSON Lines. It records execution metadata and field-level `proposed`, `pending`, `changed`, or `error` records without storing review text, user profiles, email, phone, tokens, or other private document content. A `pending` record is written before each write batch and a `changed` record afterward. If execution stops between them, the operator must verify those paths before resuming.

Search migration updates only places where `searchPrefixes` is absent and uses the same lower-case, whitespace normalization, word-boundary, 50-character, and 200-prefix contract as the Flutter search index. Lifecycle migration updates only missing event/hangout statuses to `active` and preserves every explicit value. Aggregate reconciliation treats review documents, including anonymized and repeated-user reviews, as authoritative and updates only differing trusted aggregate fields plus `aggregateUpdatedAt`.

All three commands are idempotent. Search and lifecycle reruns skip populated fields; aggregate reruns skip already-correct totals. Recoverable malformed documents are recorded and skipped while processing continues. A non-zero error count means the migration did not fully succeed even when other documents were processed.

No automatic rollback command is provided. Search/lifecycle rollback must use the exact manifest paths and reviewed old-state records, never a collection-wide field deletion. Aggregate rollback should normally rerun reconciliation from authoritative reviews; catastrophic recovery uses the pre-migration Firestore export. Production aggregate execution still requires the controlled review-write window described above.

The tooling is covered by Firebase emulator tests for dry-run immutability, exact prefix behavior, missing-field-only writes, explicit-state preservation, malformed data, repeated execution, bounded checkpoint resume, authoritative aggregates, anonymized/multiple reviews, empty review sets, and unrelated-field preservation. Emulator success does not authorize or prove a production migration.

For direct emulator CLI checks, set the standard Admin SDK emulator variable before running a command. For PowerShell:

```powershell
$env:FIRESTORE_EMULATOR_HOST='127.0.0.1:8181'
node scripts/migrations/backfill-search-prefixes.js --project=demo-meetmap-addis
```

Production or non-emulator execution intentionally requires valid Application Default Credentials in addition to the explicit project and write-safety flags. Credentials must never be passed as CLI arguments or committed to the repository.

## Deployment Sequence

1. Finalize Android application ID, signing ownership, Firebase Android app, Google OAuth fingerprints, and Play registration.
2. Create a Firestore export and capture baseline counts. Obtain explicit migration/deployment approval.
3. Deploy indexes with `firebase deploy --only firestore:indexes`; wait for the geographic index to become `READY`.
4. Deploy the reviewed backward-compatible rules with `firebase deploy --only firestore:rules`; run authenticated and unauthenticated smoke checks.
5. Enable Blaze and deploy Functions with `firebase deploy --only functions`; verify trigger/callable health and logs.
6. In a controlled write window, run aggregate reconciliation and the missing-field-only search/lifecycle backfills. Verify counts and samples before closing the window.
7. Configure and validate Play Integrity App Check with an internal release build. Do not enable broader enforcement until valid production tokens are observed.
8. Build the signed release AAB and execute the real-device smoke plan against the intended project.
9. Release first through Play internal testing, then a small closed test. Expand only after monitoring remains healthy.

Rules, indexes, Functions, migrations, and the client must not be deployed as one unobserved operation. Record the deployed Git commit and operator for every step.

## Real-Device Smoke Test

Use two disposable accounts on a release build.

- Sign up, email/password login, Google login, logout, cold-start restoration, and A -> B -> A account switching.
- Edit each profile and confirm private account fields never appear on another profile.
- Open Home and Explore; paginate places; search mixed-case and multi-word prefixes; clear and repeat searches.
- Grant and deny location; verify nearby results, map bounds, pins, and directions without default/fake origins.
- Open events and hangouts; confirm active content appears and archived/inactive content does not.
- Save and unsave multiple places; restart and switch accounts; confirm saved state and search history remain UID-scoped.
- Follow and unfollow between the disposable accounts; confirm self-follow is unavailable and counts/state survive restart.
- Create, edit if exposed, and delete reviews; verify place aggregate changes once and remains correct after restart.
- Test offline startup from cache, reconnection refresh, pagination failure/retry, and no infinite loaders.
- Delete one disposable account; verify Auth identity and private documents are removed, reviews are anonymized, places become system-managed, events archived, hangouts inactive, relationships removed, and the other account remains untouched.
- After deletion, relaunch and confirm local private/session/search/saved data for the deleted UID is gone.

## Rollback Plan

| Operation | Rollback |
| --- | --- |
| Rules | Keep the prior rules file/commit and redeploy it. Validate that rollback remains compatible with already-written documents. |
| Functions | Redeploy the previous known-good commit. Do not delete the aggregate trigger while review writes continue unless another trusted aggregate path is active. |
| Client | Halt rollout or publish the previous signed version through Play. Firestore changes must remain backward-compatible with that client. |
| Indexes | Leave additional indexes in place during incident response; they cost storage but do not alter data. Remove only after proving no deployed query depends on them. |
| Search/lifecycle backfills | Use the export or the exact migration manifest. Never issue an unbounded inverse update. Coordinate with client rollback. |
| Aggregate reconciliation | Restore from export only for catastrophic corruption; normally rerun reconciliation from authoritative reviews. |
| App Check | Prefer a controlled enforcement rollback in Firebase Console while investigating valid-token failures; do not remove callable auth checks. |

Every irreversible or destructive operation requires a dry-run result, backup location, operator approval, project-ID confirmation, and post-operation verification.

## Minimum Monitoring

Before closed testing, configure practical alerts and review ownership for:

- Cloud Functions invocation errors and retries, especially aggregate and account deletion failures;
- Firestore permission-denied and missing-index errors;
- Firebase Authentication and Google sign-in failures;
- App Check invalid/missing token metrics before and after enforcement;
- Cloudinary and Gebeta quota/error dashboards;
- release crashes and application-not-responding reports through Play Console, plus Crashlytics when beta scope justifies adding it;
- unexpected growth in reads, writes, aggregate markers, Functions invocations, and image/map usage.

No additional observability platform is required for initial controlled testing.

## Priority Decision

### MUST DO BEFORE PRODUCTION

- Finalize package identity and release signing ownership.
- Configure release Firebase/Google OAuth and Play Integrity App Check.
- Enable Blaze and deploy/test required Functions.
- Deploy reviewed rules and the geographic index.
- Back up data, reconcile aggregates, and backfill missing search/lifecycle fields.
- Restrict and validate Cloudinary/Gebeta client configuration.
- Pass the two-account release-device smoke test and rollback rehearsal.

### SHOULD DO SOON

- Add automated crash reporting before testing expands beyond a controlled group.
- Monitor bounded network follower-count queries and first-page geographic completeness.
- Record deployment operators, commit hashes, migration manifests, and baseline usage.

### CAN DEFER

- External search infrastructure, fuzzy ranking, and semantic search.
- Geohashes or another geospatial backend.
- Aggregate-marker retention without a safe replay guarantee.
- Saved-relationship pagination until measured list size requires it.
- Denormalized follower counts until current bounded aggregation becomes a measured problem.
- Microservices, Kubernetes, complex caching, and additional state-management frameworks.
