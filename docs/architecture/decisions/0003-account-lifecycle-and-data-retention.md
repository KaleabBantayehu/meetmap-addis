# ADR 0003: Account Lifecycle And Data Retention

- Status: Accepted
- Date: 2026-09-26
- Decision owners: MeetMap Addis engineering and product
- Scope: Account deletion, retained public contributions, and private-data cleanup

## Context

Deleting only a Firebase Authentication identity would leave private data,
relationship edges, and public content tied to a UID that no longer represents an
active account. Allowing the Flutter client to perform cross-user cleanup would
require unsafe privileges and could leave partially deleted state.

MeetMap also contains public contributions whose value is not owned exclusively by
their creator. A place may contain other users' reviews, trusted rating aggregates,
and saved-place references. Reviews are independent experience records under ADR
0002. Blindly deleting this content would damage discovery data and user trust.

## Alternatives Considered

### Delete all authored content

This gives a simple ownership result but destroys useful public history, including
content contributed by other users under retained places.

### Retain content with the deleted UID

This preserves data but leaves an identity association and creates orphaned
ownership that no active user can manage.

### Retain, anonymize, and transfer lifecycle control to a trusted boundary

Public content remains useful while the deleted identity is removed. Trusted
backend or moderation tooling controls the retained content afterward.

## Decision

MeetMap chooses retain, anonymize, and trusted lifecycle ownership. Account
deletion is requested by the authenticated user through a callable Cloud Function.
The Admin SDK performs privileged cleanup. Ordinary clients receive no recursive
deletion or lifecycle-management permission.

Firebase Authentication remains authoritative for authentication identity and is
deleted only after Firestore cleanup succeeds.

## Data Lifecycle

- `/users/{uid}` and all nested private account, saved-place, following, and
  follower documents are deleted.
- Relationship documents involving the UID under other users are deleted.
- Reviews retain rating, text, creation time, and document identity. Their `userId`
  becomes `null`, with trusted deletion metadata, so no Firebase identity can gain
  ownership of an anonymized review.
- Places retain their data and aggregates, clear `createdBy`, and transition to
  `lifecycleStatus: systemManaged`.
- Events clear `createdBy` and transition to `lifecycleStatus: archived`.
- Hangouts clear `createdBy` and transition to `lifecycleStatus: inactive`.

The lifecycle fields and ownership transition are written only by the trusted
backend. They are not accepted by ordinary client create/update rule contracts.

## Review And Aggregate Implications

Review anonymization does not change `rating`, so `ratingSum`, `reviewCount`, and
`rating` remain unchanged. The existing aggregate trigger sees an update with a
zero rating delta. Review deletion is not part of normal account deletion.

## Private Account Contract

`/users/{uid}/private/account` continues to contain `email`, `phoneNumber`,
`notificationsEnabled`, `createdAt`, and `updatedAt`. Email mirrors Firebase Auth
and is not editable through profile updates. No additional speculative preference
or authentication fields are introduced.

## Retry And Idempotency

Firestore transitions use convergent values, relationship deletion tolerates
missing documents, recursive profile deletion tolerates prior cleanup, and a
missing Auth user is treated as already deleted. Firebase Auth deletion occurs
last so an interrupted Firestore cleanup can be retried while the requester is
still authenticated.

## Security Implications

The callable derives the target UID exclusively from the verified authentication
context. It does not accept another UID from client data. App Check is enforced.
Firestore rules continue denying client deletion of public profiles and private
account documents, trusted lifecycle-field injection, aggregate mutation, and
cross-user relationship manipulation.

## Active Discovery Reads

Event and hangout models continue treating a missing `lifecycleStatus` as
`active` for legacy deserialization and cached-data compatibility. Firestore
cannot query for documents where a field is absent, while `!=` and `not-in`
queries also exclude missing fields. Production activation of lifecycle-aware
reads therefore requires a controlled backfill before the matching client is
released:

- existing events without the field receive `lifecycleStatus: active`;
- existing hangouts without the field receive `lifecycleStatus: active`;
- retained events and hangouts keep their trusted `archived` and `inactive`
  statuses;
- new client-created events and hangouts write `active` explicitly.

After that backfill, active discovery queries use an equality filter before
document-ID pagination. This prevents known archived or inactive documents from
consuming page reads and keeps `hasMore` tied to active documents. Provider and
cache filtering remains as defense in depth. Place discovery is unchanged:
`systemManaged` places are retained public content and remain discoverable.

The lifecycle equality plus document-ID ordering uses Firestore's built-in
single-field index. Featured events add equality filters for `lifecycleStatus`
and `isFeatured`; this query uses Firestore index merging unless the production
project explicitly requests a composite index. No speculative index is added.

## Reassessment Triggers

Revisit this decision if legal deletion requirements require public-content
removal, moderation needs a richer lifecycle, public contributions gain transfer
or appeal workflows, or Firebase introduces a materially safer native deletion
mechanism for this data graph.
