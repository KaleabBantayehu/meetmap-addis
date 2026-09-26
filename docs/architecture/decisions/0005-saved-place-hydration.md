# ADR 0005: Saved Place Hydration

- Status: Accepted
- Date: 2026-09-26
- Decision owners: MeetMap Addis engineering and product
- Scope: Reading saved-place relationships and place documents

## Context

Saved places are stored as relationships under
`users/{uid}/saved_places/{placeId}`. The previous client loaded those
relationships and then read each referenced place document separately, producing
one additional Firestore request for every saved place.

## Decision

MeetMap reads the current user's saved relationships once, orders them by
`savedAt` descending, and hydrates place documents with document-ID `whereIn`
queries in batches of 30. Returned documents are mapped by ID and reconstructed in
saved order because Firestore does not preserve the input order of `whereIn`.

Duplicate relationship IDs are ignored. Missing or deleted place documents are
omitted without deleting the saved relationship. Place documents remain the
authoritative data source; their contents are not duplicated into relationships.

## Security And Lifecycle

The repository verifies the current Firebase Auth UID before reading. Existing
rules continue to restrict saved relationships to their owner while places retain
their existing read contract. System-managed places remain readable and are not
filtered by `createdBy`.

ADR 0003 account deletion remains unchanged: recursive deletion removes the
deleted user's saved relationships but never deletes the underlying places.

## Session And Cache Isolation

`SavedProvider` validates UID and session generation before applying or caching a
hydration result. Hydrated data continues to use the existing UID-scoped cache
keys. A stale response from user A cannot populate user B's state or cache.

## Limitation

The saved relationship collection itself is not paginated in this phase. Place
hydration is bounded per query, but a future saved-screen pagination phase may be
needed if individual saved collections become large.
