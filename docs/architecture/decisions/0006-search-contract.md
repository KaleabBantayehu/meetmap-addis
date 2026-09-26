# ADR 0006: Bounded Place Search Contract

## Status

Accepted for Phase 3.4.

## Context

Place search previously queried the case-sensitive `name` field, returned at
most 20 documents without a cursor, and merged those results with whichever
discovery pages happened to be loaded locally. Matching and completeness
therefore depended on capitalization and unrelated browsing state.

## Decision

Each place stores a bounded `searchPrefixes` list derived from its public
`name`, `category`, `location`, and tags. Values are trimmed, lower-cased, and
have repeated whitespace collapsed. Prefixes begin at each word boundary, so
`coffee` matches `Tomoca Coffee`, while arbitrary substring `moca` does not.

Queries shorter than two characters do not access Firestore. Other queries use
`arrayContains` on the exact normalized prefix, order by document ID, fetch one
lookahead document, and return `PageResult<PlaceModel>` with a document-ID
cursor. Search pages contain 20 results by default and suppress duplicates when
appended.

Empty search retains the existing bounded discovery/suggestion experience. It
does not query every place. Offline search applies the same prefix semantics to
the bounded place pages already cached on the device and is not globally
complete.

## Compatibility And Activation

Legacy places without `searchPrefixes` remain available through normal place
discovery and direct reads, but Firestore search cannot return them. Before
production activation, existing places must be backfilled once using the same
normalization and prefix generation contract. This phase does not modify
production data.

New client-created places include the field. Firestore rules keep it optional
for legacy-client and legacy-document compatibility, but bound it to 200 entries
when present; only place creators may change it through the existing place
update contract. The field affects discovery only; it grants no access and is
not an ownership or aggregate authority. Firestore rules cannot prove lowercase
normalization, so a future trusted write path should derive the field if search
ranking becomes security- or business-sensitive.

The query uses Firestore's array and document-ID indexes. No speculative
composite index is introduced; emulator and production query verification must
confirm whether the active Firebase project requests an explicit index.

## Limitations

This contract provides normalized word-prefix matching, not arbitrary contains,
fuzzy matching, relevance ranking, or semantic search. Explore filters remain
client-side over loaded pages and therefore are not globally complete. An
external search service becomes justified only when measured product needs
require typo tolerance, ranked multi-filter search, or richer full-text
semantics that this bounded Firestore contract cannot provide.
