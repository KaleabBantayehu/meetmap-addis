# ADR 0002: Review Experience Policy

- Status: Accepted
- Date: 2026-09-26
- Decision owners: MeetMap Addis engineering and product
- Scope: Review identity, trust boundaries, aggregation, and future verification

## Context

MeetMap is a place-discovery product. A person may visit the same place more than
once and have meaningfully different experiences because service, atmosphere,
pricing, accessibility, or suitability for a purpose can change over time.

Treating a user identity as permanently entitled to exactly one review per place
would collapse those experiences into one mutable record. It would require users
to overwrite history and would make a later experience indistinguishable from an
edit to an earlier one.

MeetMap currently stores each review as an independent document at:

```text
places/{placeId}/reviews/{reviewId}
```

The application does not currently have a trusted Experience, Visit, Booking,
Reservation, Check-in, or Attendance entity. MeetMap therefore cannot truthfully
claim that a review represents a verified visit or transaction.

## Alternatives Considered

### 1. One review ever per user and place

This would simplify duplicate prevention and make each user's latest opinion easy
to identify. It is too restrictive for MeetMap because repeat visits can represent
separate, valid experiences. It would also erase review history whenever a user
updates their single record.

### 2. Unlimited unrestricted reviews

The current document structure can technically store multiple reviews from one
user for one place. Treating that capability as permission for unrestricted or
automated posting would expose ratings to spam and manipulation. This is not the
product policy.

### 3. Multiple reviews representing separate experiences

Each review remains an independent record of an experience. Stronger eligibility
and verification can be added later if MeetMap introduces a trusted experience
source. This preserves valid repeat feedback without making a verification claim
the current product cannot support.

## Decision

MeetMap chooses option 3.

The governing principle is:

> Reviews represent experiences, not identities.

A user may create multiple reviews for the same place when those reviews describe
genuinely different experiences. Each review remains an independent document with
its own review ID. Users may edit and delete reviews they own under the existing
ownership rules.

MeetMap does not currently label reviews as verified experiences. It also does not
introduce arbitrary cooldowns, quotas, or time limits without evidence and a
defined product contract.

## Current Implementation Boundary

The existing `ReviewModel`, nested Firestore review path, ownership rules, and
review repository support independent review documents. There is no Experience or
Visit entity and no relationship from a review to a trusted booking, reservation,
check-in, or attendance record.

This decision documents the current contract; it does not require a schema change,
review implementation change, Firestore rules change, or data migration.

## Trust And Abuse Considerations

Supporting repeat experiences does not make review spam acceptable. Repeated or
coordinated reviews may distort place ratings, reduce user trust, and increase
moderation burden.

MeetMap will base future controls on observed abuse, moderation evidence, and a
defined experience model. Potential controls must preserve legitimate repeat
experiences and must not present unverified reviews as verified. No speculative
cooldown or submission limit is adopted by this decision.

## Aggregate Implications

The trusted Cloud Functions aggregate contract remains valid:

- Review creation adds its rating to `ratingSum` and increments `reviewCount`.
- Review updates adjust `ratingSum` by the rating delta without changing the count.
- Review deletion subtracts its rating and decrements `reviewCount`.
- The displayed aggregate is derived from the trusted aggregate fields rather than
  client-written rating values.

Each independent review contributes once to the aggregate. The existing
transactional and idempotent aggregate handling does not depend on one review per
user per place, so no aggregate implementation change is required.

If moderation later excludes or removes a review, aggregate maintenance must
account for that state through the same trusted backend boundary.

## Business-Review Independence

Businesses must not receive a technical mechanism to reward, penalize, or pressure
users for changing ratings. Any future business response, reputation, promotion,
or incentive capability must preserve the independence of review content and
ratings. Commercial participation must not grant authority to alter user reviews
or trusted rating aggregates.

## Future Evolution

If MeetMap later introduces trusted reservations, bookings, check-ins, QR visits,
event attendance, or another verified experience mechanism, reviews may reference
that entity. A trusted backend could then enforce review eligibility and expose a
verified-experience status based on server-controlled evidence.

That evolution should preserve existing review history and define how legacy,
unverified reviews coexist with verified reviews. This ADR does not create that
entity or verification workflow.

## Reassessment Triggers

Revisit this decision when one or more of the following occurs:

- Review spam or coordinated rating manipulation becomes observable.
- Repeated reviews materially distort place ratings.
- MeetMap introduces bookings, reservations, check-ins, attendance, or another
  trusted experience source.
- Business reputation or response requirements need a formal product contract.
- Moderation evidence supports a specific eligibility, frequency, or abuse rule.
- User research shows confusion about multiple reviews from the same person.

Any reassessment must define the product contract first, preserve review ownership
and business-review independence, and keep aggregate updates within a trusted
backend boundary.
