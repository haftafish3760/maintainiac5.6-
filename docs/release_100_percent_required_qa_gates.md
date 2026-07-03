# Release 100 Percent Required QA Gates

This document defines the required quality bar before any public release of Mainteniac 5.6 or any related app in the ecosystem. It applies to the entire app, not only inventory.

The goal is not "tests exist." The goal is release evidence that proves the app is accurate, secure, private, recoverable, fast enough, and safe for real users.

## Release Rule

No feature area is considered release-ready until every applicable gate below is covered by tests, fixtures, review evidence, focused rerun commands, and release signoff.

If a gate is not applicable, the release notes must say why.

## Required To Be 100 Percent Before Release

This standard applies to everything in Mainteniac, not only the inventory parser. A feature, screen, service, pack, workflow, admin report, sync path, or user-facing action is not release-ready until the required QA evidence proves it is complete for its intended release scope.

For every release candidate, each feature area must prove:

- the happy path works
- the common real-world path works
- the worst reasonable user input is handled safely
- the user cannot accidentally create bad records
- ambiguous results require review instead of silent action
- local storage authority is clearly defined
- remote mirrors cannot overwrite truth without approved conflict handling
- financial, inventory, job, estimate, and invoice totals cannot be duplicated
- all user-controlled input is hostile by default
- private user data is redacted or excluded from diagnostics
- old devices and low-storage devices degrade safely
- interrupted operations recover or roll back cleanly
- every previously fixed bug has a regression lock
- focused rerun commands exist for surgical retesting
- app-wide release gates pass before public rollout

Nothing should be marked complete just because it has code. It is complete only when the code, data, tests, fixtures, failure reports, and rerun commands all agree.

## App-Wide Feature Areas That Must Meet This Bar

The 100 percent release gate applies to at least these areas:

- account creation and onboarding
- authentication and session handling
- permissions and employee roles
- dashboard and navigation
- inventory and materials
- catalog packs and language packs
- inventory parser and search
- receipt import routing after OCR hands data off
- expenses after OCR/parser handoff
- estimates
- invoices
- active jobs
- calendar and scheduling
- customer records
- vehicle and fleet inventory
- sync and local persistence
- Firebase or Firestore mirror behavior
- admin and Command One diagnostics
- support tickets
- settings and user preferences
- subscriptions or payments if added
- route/GPS workflows when added

Each area must have its own coverage matrix or be explicitly covered inside a shared matrix with clear requirement IDs.

## Cross-Feature Workflow Gates

Some failures happen between screens, not inside one screen. These workflows must be tested end-to-end before release:

- receipt text becomes review-only parser candidates
- approved material candidates add to inventory
- approved material candidates add to an estimate
- an estimate becomes an active job
- active job material changes flow to invoice totals
- inventory stock changes stay tied to the right vehicle
- employee permissions limit what can be viewed or changed
- customer/job records do not leak into diagnostics
- local Hive state remains authoritative when remote mirrors are stale
- duplicate receipt/import attempts do not double count cost or stock
- pack downloads, updates, and rollbacks do not corrupt local state
- admin reports summarize health without exposing private data

## Required Gates

### Master Coverage Matrix

Every major feature must have a coverage matrix before release.

Required fields:

- requirement id
- feature area
- user workflow
- risk level
- QA suite or test file
- fixture source
- expected behavior
- current status
- focused rerun command
- last verified date
- release owner or reviewer

Status values:

- missing
- partial
- written-not-validated
- validated-local
- validated-device
- release-ready

### Golden Regression Corpus

Every major workflow must have locked golden fixtures.

Required coverage:

- known-good examples
- known-bad examples
- previous bugs that must stay fixed
- edge cases from real user behavior
- merchant/vendor-specific cases where applicable
- locale/language cases where applicable
- device/profile cases where applicable
- source immutability cases where applicable

### Differential Regression

Every parser, catalog, pack, workflow, storage, or sync change must support old-vs-new comparison before release.

Required checks:

- old result vs new result
- changed candidate or record
- changed confidence or status
- changed destination routing
- changed financial amount
- changed storage state
- reason for the change
- approved change vs blocking regression

### Mutation Testing

Critical logic must have mutation-style tests that prove the tests fail when important rules are broken.

Required mutation areas:

- aliases and synonyms
- normalization
- confidence scoring
- category routing
- permission gates
- dangerous words
- privacy redaction
- storage authority
- sync conflict handling
- financial calculations
- import/export validation
- source immutability

### Property And Fuzz Testing

Every text-entry, search, parser, import, barcode, and receipt-like input path must be fuzzed.

Required hostile inputs:

- huge input
- repeated tokens
- empty input
- whitespace-only input
- weird Unicode
- control characters
- directional override characters
- emoji and symbols
- SQL-like text
- NoSQL-like text
- path traversal
- script tags
- command-looking text
- regex backtracking traps
- malformed JSON
- malformed CSV
- malicious SKU or barcode

### Performance Budgets

Every major workflow must have explicit performance budgets.

Required measurements:

- cold start
- warm run
- indexing time
- search time
- parse time
- save time
- sync queue time
- memory growth
- slowest rule or operation
- device class impact
- older-phone conservative profile
- modern-phone full profile

### Persistence Chaos

Every workflow that writes data must be tested against interruption and corruption.

Required cases:

- app killed mid-write
- app killed mid-review
- low storage
- local database corruption
- interrupted import
- interrupted export
- interrupted pack download
- duplicate install
- duplicate receipt/import
- offline write
- stale mirror
- sync retry
- rollback to last known-good state

### Security Abuse

Every user-controlled input must be treated as hostile.

Required checks:

- no code execution from input
- no query injection path
- no path traversal
- no unsafe file import
- no CSV formula injection
- no malicious barcode or SKU impact
- no unbounded regex behavior
- no denial-of-service input path
- no private data in logs
- no unsafe admin diagnostics
- no live service writes from local QA

### Workflow Integrity

Every workflow must prove it writes only what the user approved.

Required checks:

- no silent writes
- no auto-save from ambiguous parser output
- no duplicate cost or inventory write
- no source mutation
- review-only candidate flow
- explainable warnings
- destination-specific approval
- rollback or undo path where appropriate

### Privacy Verification

No diagnostic, admin report, crash report, parser report, or sync payload may leak private user data.

Blocked data:

- raw receipt text unless explicitly required and redacted
- card numbers
- last four card digits
- customer names
- emails
- phone numbers
- addresses
- GPS coordinates
- receipt images
- job photos
- private notes
- employee private data

Allowed diagnostic data must be aggregate or redacted.

### Pack And Module Lifecycle

Any downloadable pack, module, catalog, language pack, or ruleset must prove safe lifecycle behavior.

Required checks:

- manifest validation
- checksum or signature strategy
- version compatibility
- missing pack fallback
- old pack migration
- duplicate install
- corrupt pack rejection
- partial download recovery
- rollback to previous known-good pack
- pack size reporting
- low-storage guard

### Human Correction Loop

Any user correction must become a reviewable proposal, not a silent global mutation.

Required outputs:

- proposed alias
- proposed negative rule
- proposed merchant rule
- proposed fixture
- proposed confidence adjustment
- proposed category/routing correction
- before/after evidence
- reviewer decision
- regression lock after approval

### Storage Authority

For inventory and any other local-first domain, local storage is the truth unless a feature-specific design explicitly says otherwise.

Inventory-specific rule:

- Hive is the inventory source of truth.
- Firebase or Firestore is mirror-only.
- Remote data must never overwrite newer or approved local inventory state without review.
- Failed remote sync must not roll back approved local inventory writes.

### Release Monitoring

Every released area must define what happens after release.

Required monitoring:

- crash-free sessions
- failure categories
- unknown/ambiguous rates
- false correction rate
- correction frequency
- device class failures
- slow workflow alerts
- sync failure rate
- rollback triggers
- canary thresholds

## Non-Negotiable Release Criteria

A release cannot go public if any of these are true:

- critical security test is missing
- critical privacy test is missing
- known regression is unfixed
- source mutation risk is unresolved
- storage authority is ambiguous
- parser or search can silently create bad user data
- financial totals can be duplicated or changed without review
- local QA hits live Firebase/Firestore unexpectedly
- app cannot recover from interrupted writes or corrupted packs
- release gates have not been run and reviewed

## Inventory Parser Relationship

The inventory parser QA harness is one implementation of this release standard. It does not replace the app-wide standard.

Every future major subsystem must receive the same treatment:

- Expenses
- OCR/camera/PDF pipeline
- invoices
- estimates
- jobs
- inventory
- route/GPS
- calendar
- permissions
- support
- admin/Command One
- sync/storage
- authentication
- payments/subscriptions if added

## Durable Reminder

Do not call a feature "done" because it works once. A feature is release-ready only when it has evidence that it works correctly, safely, privately, repeatedly, under hostile input, under interruption, under old-device constraints, and through future version changes.
