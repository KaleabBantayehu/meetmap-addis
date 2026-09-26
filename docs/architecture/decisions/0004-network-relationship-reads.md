# ADR 0004: Network Relationship Reads

- Status: Accepted
- Date: 2026-09-26
- Decision owners: MeetMap Addis engineering and product
- Scope: Following state and relationship counts

## Context

Network discovery previously read one following document and hydrated one complete
followers subcollection for every displayed user. Read operations therefore grew
linearly with the discovery list and transferred relationship documents when the
UI only needed existence and counts.

Relationships remain authoritative in the existing two-sided subcollections:
`users/{uid}/following/{targetUid}` and
`users/{targetUid}/followers/{uid}`. Public profile arrays are not authoritative.

## Decision

The current user's follow state is loaded with document-ID `whereIn` queries
against their own `following` subcollection. Target IDs are deduplicated and
chunked to Firestore's query limit.

Follower and following counts use Firestore aggregation `count()` queries. The
client does not download complete relationship collections and does not write
count fields to public profiles. Follow and unfollow continue using the existing
transaction that writes or deletes both relationship documents.

## Security And Lifecycle

Existing Firestore rules remain unchanged. A user can read their own following
state, authenticated users can read follower relationships, and clients cannot
create relationships for another identity or fabricate trusted counts.

ADR 0003 cleanup remains compatible because it deletes both sides of every edge
involving the deleted UID. Batched reads observe those authoritative documents and
therefore cannot retain a deleted relationship after refresh.

## Session Isolation

Relationship summaries are session-specific and are not persisted in a global
cache. `NetworkProvider` validates both UID and session generation before applying
an asynchronous response.

## Limitation

Firestore cannot group exact follower counts by parent user across these existing
subcollections. Discovery therefore uses one lightweight aggregation query per
unique displayed target, issued through one repository operation. A future
trusted backend may maintain protected count fields if this cost becomes material;
clients must not maintain those fields themselves.
