# ADR 0007: Bounded Geospatial Discovery

## Status

Accepted for Phase 3.5.

## Context

Nearby discovery previously filtered the currently loaded general place list.
That list was not a geographic candidate set and its completeness depended on
unrelated discovery pagination. Loading every place before calculating distance
would make reads grow with the full place collection.

## Decision

Places continue using their existing numeric `latitude` and `longitude` fields.
No duplicate GeoPoint or geohash representation is introduced. Map candidates
are queried with bounded latitude and longitude ranges, ordered by latitude,
longitude, and document ID, with at most 50 candidates per page.

Radius discovery converts the center and radius into a bounding rectangle,
loads one bounded candidate page, and applies deterministic Haversine distance
filtering in the repository. Results are sorted by exact distance. Map discovery
uses the current Gebeta visible region and replaces stale candidates only when
the newest request for the current session completes.

The cursor encodes `(latitude, longitude, documentId)` and uses the existing
`PageResult` contract. A candidate page can contain fewer final radius results
after exact filtering; `hasMore` describes remaining candidates.

## Compatibility And Indexing

Legacy documents with missing or malformed coordinates deserialize to invalid
`0,0` coordinates and are safely excluded from geographic queries and local
distance calculations. Existing valid coordinates require no migration.

The Firestore query requires the committed collection-scope composite index on
ascending `latitude`, ascending `longitude`, and ascending document ID. Rules
already restrict coordinate changes to the existing place-owner update contract
and validate coordinate ranges, so no security-rule expansion is required.

## Limitations

Antimeridian-crossing bounds are rejected. This is appropriate for the current
Addis Ababa product boundary. Radius pagination follows geographic candidate
order rather than exact-distance order across all pages. The current UI loads
the first bounded candidate page; additional map-page UX is deferred until
observed density requires it.
