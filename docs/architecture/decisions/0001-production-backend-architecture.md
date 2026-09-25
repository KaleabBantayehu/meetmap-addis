# ADR 0001: Production Backend Architecture

- Status: Accepted
- Date: 2026-09-25
- Decision owners: MeetMap Addis engineering and product
- Scope: Production architecture for the existing MeetMap Addis product

## Context

MeetMap Addis is transitioning from an academic MVP into a production application for real market testing. Its core product is place discovery in Addis Ababa, including places, search, filtering, maps, directions, reviews, saved places, and user profiles. Events, hangouts, and basic networking exist, but they do not determine the core backend decision.

The current client is built with Flutter using a feature-based structure, Provider state management, and repository interfaces between providers and infrastructure implementations. Firebase Authentication and Cloud Firestore provide authentication and application data. Firebase App Check provides app attestation. Cloudinary provides media storage and delivery, and Gebeta provides maps, geocoding, and directions.

The production audit identified material problems:

- unclear ownership of user-controlled and trusted data;
- no trusted backend owner for derived values;
- stale denormalized place review aggregates;
- Firestore security rules that require further production hardening and deployment verification;
- unbounded reads and N+1 access patterns;
- incomplete search and geo query contracts;
- caches without sufficient user ownership and freshness rules;
- unsigned media-upload abuse risk;
- insufficient production observability.

These problems require production engineering, but they do not currently demonstrate that Firestore is fundamentally incompatible with the product.

## Decision

MeetMap Addis will keep its current core technology stack and strengthen it for production. It will not migrate to Supabase/PostgreSQL or introduce a custom backend at this stage.

The target stack is:

- Flutter for the Android client;
- the existing feature-based Flutter project structure;
- Provider for application state;
- repository interfaces between providers and infrastructure;
- Firebase Authentication;
- Cloud Firestore;
- Firebase App Check;
- Firebase Cloud Functions 2nd generation for trusted backend operations;
- Cloudinary for media storage and delivery, subject to production hardening;
- Gebeta for maps, geocoding, and directions.

This decision is not based on preserving already-written code. Firebase is retained because, once supplemented with trusted backend operations and explicit query and security contracts, it fits the current product's authentication, mobile integration, offline behavior, data access, operational burden, and development requirements.

The existing dependency direction remains:

```text
UI
  -> Provider
    -> Repository interface
      -> Firebase or external-service implementation
```

This is a useful infrastructure boundary. It permits implementations to evolve later without requiring the Flutter UI to depend directly on a replacement backend.

## Architectural Principle: Client Trust

The Flutter client is not trusted with business-critical derived data.

The production architecture must distinguish user-owned data from trusted or backend-derived data.

User-controlled data includes, subject to validation and authorization:

- public name;
- bio;
- avatar;
- place descriptive content where permitted;
- review text and rating;
- saved-place relationships.

Trusted or backend-controlled data includes:

- `isVerified`;
- moderation status;
- featured status;
- `ratingSum`;
- `reviewCount`;
- `rating`;
- aggregate counters;
- follower counters;
- attendee counters if membership is introduced;
- other derived or business-critical fields.

Authentication identifies the caller. App Check attests that a request likely came from an authentic application installation. Firestore rules authorize direct database operations. Cloud Functions perform trusted operations. None of these controls replaces the others.

## Production Architecture

```text
Flutter UI
    |
Feature Providers
    |
Repository interfaces
    |
+---------------------------+
| Firebase client SDKs      |
| Authentication/Firestore  |
+---------------------------+
    |
+---------------------------+
| Trusted Cloud Functions   |
| 2nd generation            |
| aggregates/trusted ops    |
+---------------------------+
    |
Cloud Firestore
    |
Indexed product data

External services:
Cloudinary -> media storage and delivery
Gebeta     -> maps, geocoding, and directions

Potential future path, only when measured requirements justify it:
Firestore -> trusted synchronization -> external search index
```

Cloud Functions are not a general replacement API for every operation. Direct client access remains appropriate where Firestore rules can safely enforce ownership and validation. Trusted functions are used where the client must not control the outcome.

## Review Aggregate Design

The authoritative review location remains:

```text
places/{placeId}/reviews/{reviewId}
```

Place documents will expose maintained aggregate fields:

```text
ratingSum
reviewCount
rating
aggregateUpdatedAt
```

The production flow is:

```text
Review create/update/delete
    -> Firestore review document
    -> trusted Cloud Function 2nd gen
    -> transactional and idempotent aggregate update
    -> places/{placeId}
    -> clients read maintained aggregate fields
```

The Flutter client must not directly modify `ratingSum`, `reviewCount`, or `rating`.

The aggregate implementation must handle create, edit, and delete operations. Firestore events can be retried and are not guaranteed to arrive in order. Processing must therefore be idempotent, use transactions for aggregate mutations, and prevent duplicate event application. The implementation should retain enough event identity or state to determine whether a transition has already been applied.

An eventual reconciliation operation must recompute aggregate fields from authoritative review documents. Reconciliation repairs historical corruption, failed processing, and legacy inconsistencies. It is a recovery mechanism, not the normal card-read path.

Individual place cards must never fetch their own review collections. Cards consume the maintained aggregate on the place document. This avoids an N+1 review-read pattern across Home, Explore, Search, and Saved.

This ADR defines the contract only. It does not implement the function.

## Query And Discovery Architecture

Downloading the complete places collection is not the permanent production discovery architecture.

Production collection access will move toward:

- cursor pagination;
- bounded Firestore queries;
- indexes matching actual query shapes;
- backend-maintained values used by sorting and filtering;
- normalized search fields;
- one centralized filter contract rather than duplicated filtering rules;
- bounded geo candidate queries followed by exact distance calculation;
- elimination of N+1 saved-place and networking reads.

Fallback caching may improve offline experience, but it must not become the source of authorization or trusted business data. User-specific caches must be scoped to the authenticated user and have explicit invalidation and freshness behavior.

## Search Decision

MeetMap Addis will not introduce Algolia, Typesense, OpenSearch, or another dedicated search engine now.

Search will evolve in two stages.

### Stage 1: Firestore Search Contract

- Store normalized search fields through trusted or validated writes.
- Use indexed and bounded Firestore queries.
- Paginate result sets.
- Centralize category, price, purpose, amenity, rating, and location filters.
- Measure relevance failures, query limits, latency, and cost.

### Stage 2: Dedicated Search Only With Evidence

A dedicated search engine may be introduced if real usage demonstrates an unmet requirement for:

- fuzzy matching;
- multilingual search;
- relevance ranking;
- autocomplete;
- compound discovery search that Firestore cannot reasonably provide.

If introduced, the search index will be synchronized from trusted backend events. Flutter clients will not arbitrarily write search documents.

## Geo Decision

Gebeta remains responsible for:

- map display;
- geocoding;
- route and direction functionality.

Cloud Firestore remains the source of truth for MeetMap place, event, and hangout data. Gebeta is not the application database.

Production geo discovery will use a bounded location strategy, such as a validated location point plus geohash query fields. Exact distance calculations occur only after obtaining a bounded candidate set. The app will not permanently download every place and calculate all distances on-device.

Missing coordinates remain null or unknown. Missing or malformed locations must not be converted into fake coordinates such as `0,0`.

## Security And Data Ownership Requirements

Production Firestore rules must enforce ownership, schemas, and trusted-field boundaries.

### Reviews

- The caller must be authenticated.
- `userId` must match the authenticated user.
- `placeId` must match the parent place document.
- `userId` and `placeId` are immutable after creation.
- Ratings must be numeric and within the supported range.
- Allowed fields, field types, and text/list lengths must be validated.
- Aggregate fields remain outside client control.

### Places

- `createdBy` must match the authenticated creator on creation.
- Ownership cannot be reassigned by the client.
- Aggregate fields cannot be modified by clients.
- Trusted moderation and featured fields cannot be self-assigned.
- Public content creation and editing must be subject to validation and the selected moderation policy.

### Users

- Public profile data and private account/contact data should be separated appropriately.
- Users cannot self-assign trusted fields such as `isVerified`, roles, or moderation status.
- Relationship and counter fields cannot be freely client-controlled.
- Cached user data must not cross account boundaries.

### Relationships And Counters

- Saved-place relationships belong to the authenticated user.
- Follow edges must prevent self-follow and cross-user manipulation.
- Derived follower counts are backend-controlled.
- Attendee counters, if membership is introduced, are derived from authoritative membership documents.

These are architectural requirements. This ADR does not claim that every requirement is already implemented or deployed.

## Alternatives Considered

### A. Firebase And Cloud Functions

Strengths:

- strong fit with mobile authentication and Flutter SDKs;
- Firestore offline and cache capabilities;
- direct access protected by security rules;
- App Check integration;
- trusted event-driven and callable backend operations;
- low infrastructure and database operations burden;
- repository boundaries already support isolated infrastructure implementations.

Tradeoffs:

- relational data requires careful modeling and denormalization;
- full-text search and advanced relevance are limited;
- geo queries require an explicit geohash-style strategy;
- read costs can grow through N+1 or unbounded queries;
- trusted aggregate and moderation workflows require backend code;
- vendor-specific APIs and security rules create lock-in.

Conclusion: best fit for the current product once the missing production contracts are added.

### B. Supabase And PostgreSQL

Strengths:

- SQL and relational integrity;
- transactions and database triggers;
- natural modeling of follows, saves, memberships, and review relationships;
- PostGIS for geo queries;
- PostgreSQL full-text search;
- flexible reporting and compound querying.

Tradeoffs:

- requires a new relational schema and migrations;
- requires rewriting Firebase repository implementations and authentication integration;
- requires a new offline/cache strategy;
- introduces connection, query, migration, RLS, and operational responsibilities;
- migration risk would delay hardening of the existing product.

Conclusion: a legitimate future alternative, but its advantages do not currently justify a migration. It is not rejected permanently.

### C. Custom API And PostgreSQL

Strengths:

- maximum control over domain logic, authorization, queries, and portability;
- strong relational, geo, and reporting capabilities;
- client can be isolated from database details.

Tradeoffs:

- substantially greater engineering and operational responsibility;
- API hosting, scaling, observability, deployments, backups, incident response, and authentication integration become first-party responsibilities;
- longest path to a reliable market-test release;
- complexity is not justified by current product requirements.

Conclusion: unnecessary complexity at this stage.

## Why We Are Not Migrating Now

The decision is based on product fit and engineering economics, not sunk cost.

The core product can be served by bounded Firestore queries, maintained aggregates, secure ownership rules, Cloud Functions for trusted operations, and an evidence-driven search/geo evolution. The known failures are implementation and contract failures rather than proof that a document database cannot support the product.

Migration would not itself solve moderation, media abuse, cache ownership, observability, release operations, or product trust. Those responsibilities remain under every backend choice.

PostgreSQL becomes preferable if relational and analytical query requirements become central enough that modeling around Firestore consistently damages correctness, reliability, development speed, or cost.

## Decision Bias / Falsification

This decision is not based on:

- sunk-cost fallacy;
- appeal to popularity;
- an assumption that production necessarily means PostgreSQL;
- the claim that Firebase is preferable merely because it is easier;
- fear of migration;
- technology loyalty;
- premature optimization.

We will reassess based on evidence, not assumptions.

Firebase will be reconsidered if measured evidence shows that:

- Firestore is a fundamental mismatch for core discovery queries;
- relational complexity becomes the dominant source of defects or delivery delay;
- required geo operations are materially more reliable and economical with PostGIS;
- search requirements exceed what Firestore plus a justified external index can support;
- actual cost measurements show the architecture is economically inferior;
- operational limitations repeatedly constrain product reliability or development;
- production evidence shows that reliability or performance requirements cannot be met reasonably;
- vendor constraints prevent required data portability or regulatory compliance.

No arbitrary user-count threshold triggers migration. Query shape, reliability, cost, operational burden, and product requirements do.

## Production Principle

> Production-quality foundations, evidence-driven features.

MeetMap Addis will build foundational systems correctly enough for real production use. It will not intentionally design only for a small test group. It will also avoid speculative infrastructure for requirements that have not been demonstrated.

Build now:

- secure ownership and field validation;
- trusted aggregates;
- pagination architecture and bounded queries;
- production authentication and App Check;
- release signing and permanent application identity;
- observability;
- secure media handling;
- reliable and user-scoped caching.

Do not build without evidence:

- microservices;
- a dedicated search cluster;
- a recommendation engine;
- chat infrastructure;
- a notification platform;
- payment infrastructure;
- complex event architecture;
- PostgreSQL migration;
- a Clean Architecture rewrite;
- a new state-management framework.

## Production Architecture Versus Production Feature Scope

Production architecture means making the existing MeetMap product secure, reliable, scalable, observable, and trustworthy.

Production feature scope defines which user capabilities the product offers. Moving to production does not require inventing more features. Existing place discovery, review, saving, map, direction, profile, event, hangout, and networking behavior must be made truthful and reliable before new functionality expands the product surface.

Architecture work may create safe extension points, but it must not use hypothetical future features to justify current complexity.

## Consequences

Positive consequences:

- current mobile/offline strengths remain available;
- the client/repository boundary remains stable;
- trusted data gains a clear backend owner;
- migration risk does not delay production hardening;
- query, security, and cost problems can be addressed incrementally;
- the decision remains falsifiable through production evidence.

Costs and constraints:

- Cloud Functions and their deployment/testing workflow must be introduced;
- Firestore schema and security rules need explicit evolution and versioning;
- denormalized data requires reconciliation and monitoring;
- search and geo require staged indexing strategies;
- provider-specific services retain some vendor lock-in;
- a later PostgreSQL migration, if justified, will still require deliberate data and authentication migration.

## Decision Status

Decision: KEEP Firebase and strengthen the architecture.

Status: Accepted for production development.

Implementation: Not yet complete.

Next major engineering task: trusted review aggregate backend.

Next phases: security/data contracts -> query scalability -> search/geo -> media/cache hardening -> operations/release.

Reassessment: triggered by measurable evidence, not arbitrary user-count thresholds.
