# Maintenance Receipt Parser Roadmap

Status: manual durability, pure-parser, editable review, local draft-resume,
and confirmed-command application foundations implemented; broader receipt
coverage and commercial validation remain incomplete.

Canonical checkout: `/Users/rbbie/Documents/Maintainiac_5.7_Active`

## Non-negotiable lane boundaries

- Work only inside the canonical checkout. Do not create a repository, branch,
  worktree, alternate checkout, or sibling implementation.
- Maintenance receipt parsing begins after OCR. Do not change the camera, OCR,
  image preparation, stitching, PDF, or native capture systems.
- The parser is pure and local: text plus explicit vehicle context in,
  reviewable suggestions out. It must not import Hive, Firebase, camera, OCR,
  expense UI, or widget code.
- OCR and parser output are evidence, not truth. Never create tracked
  maintenance, log completed work, update the odometer, or write cloud data
  until the user reviews and confirms it.
- A purchased part or fluid does not prove installation. Parts-store receipts
  default to maintenance setup/review. Completed service history requires
  service-specific evidence and user confirmation.
- The selected vehicle is identified by its stable vehicle ID. A nickname is
  display text only. Receipt odometer readings never silently replace
  `GlobalOdometerController` truth.
- Local storage is immediate truth. Firebase is an optional mirror/backup owned
  by the durable-storage lane. Do not add Firebase rules or direct parser
  writes here.
- Keep raw receipt/OCR text and proof paths local. Any future cloud metadata
  must use redacted, minimal, user-confirmed fields.
- Do not touch Work Supplies/Materials parser or UI. Shared QA infrastructure
  may be reused without changing its inventory behavior.
- Keep every maintenance-receipt source, test, fixture, and maintenance-only
  gate file below 500 lines. The maintenance gate enforces this ceiling.

## Current evidence and gaps

- Manual maintenance selection, detailed item setup, service logging, active
  vehicle header, and global odometer UI exist.
- The canonical manual catalog now contains 26 periodic/time-based families.
  Timing Belt, Transfer Case Fluid, and PCV Valve were added manual-first with
  Basic mileage/month defaults before receipt rules. Bare ATF remains
  system-ambiguous; transmission or transfer-case suggestions require the
  maintained system to be named.
- Finalized `MaintenanceRecord` and `MaintenanceServiceEvent` data now use a
  versioned local Hive snapshot with serialized writes, stable vehicle IDs,
  persist-before-memory commit, duplicate-event protection, legacy nickname
  migration, and last-known-good backup recovery. App startup hydrates this
  local truth before `runApp`.
- Tracked items now use a reversible archive lifecycle. "Stop Tracking"
  requires confirmation, retains setup and service history, survives restart,
  and can be restored for the active vehicle from Maintenance Settings. Adding
  the same archived item restores its stable record instead of duplicating it.
- A regression exposed and fixed an aliased-list commit defect that could erase
  service events during a records-only update. Commit inputs are now copied
  before current state is cleared.
- Maintenance records and events remain joined to the stable vehicle ID across
  a nickname change and restart. Service detail display resolves the current
  nickname from that ID rather than treating the historical label as identity.
- The setup-draft resume widget case passed in isolation but previously hung
  after a service-log Hive write in the same Flutter test process. Its
  production behavior was preserved and the real-Hive resume case was moved to
  an isolated test file. The ordered maintenance UI and isolated draft-resume
  files now pass together without removing assertions.
- Verified 2026-07-23 evidence: 30 maintenance persistence/draft/UI/history
  tests, 69 selected vehicle/global-odometer tests, and the 197-check maintenance
  receipt gate passed. The receipt gate includes 191 parser/review/draft/UI/
  application tests, one manual-prefill check, four shared adapter-contract
  checks, and the legacy expense-to-maintenance non-mutation regression.
  Focused maintenance analysis reported no issues. This is source/test
  evidence, not device or field proof.
- Existing expense parsing has narrow maintenance hints for engine oil and tire
  rotation. It is not the canonical maintenance parser and must not become the
  persistence owner.
- Baseline on 2026-07-23: the broad
  `expense_receipt_parser_materials_maintenance_test.dart` file stalled in its
  first HVAC/materials case for more than 30 seconds. The maintenance gate
  therefore selects only that file's oil-maintenance regression. Do not claim
  the broad file is green; its catalog stall belongs to the existing expense /
  Materials parser lane.
- The reusable parser QA platform already declares a `maintenance_parser`
  adapter and forbids cloud, Hive, camera, OCR, and expenses at the parser
  boundary.
- A pure receipt-review mapper now keeps every candidate undecided until the
  user acts, distinguishes setup/service/both/expense/ignore choices, requires
  explicit installation confirmation before a parts purchase can become
  history, requires explicit resolution of returns/exchanges and
  estimates/declined work, blocks unresolved odometer conflicts, and emits
  inert commands with evidence line references but no raw receipt text.
- Receipt-assisted setup now defaults to Basic: item plus mileage/time
  intervals, without product-specific details. Parser-extracted oil type,
  viscosity, tire size, part number, and similar values remain reviewable
  Advanced suggestions. Advanced must be explicitly selected; the setup mode
  is draft-persistent, command-integrity-bound, and application-validated.
  Legacy drafts without an explicit mode migrate to Basic.
- Normalized source text receives a local SHA-256 fingerprint. Confirmed review
  commands receive deterministic, vehicle-specific SHA-256 IDs binding parser
  schema, candidate, decision, Basic/Advanced mode, details, service evidence,
  intervals, and merchant, establishing an exact-retry idempotency key without
  embedding raw receipt text. Post-review payload edits are rejected before a
  durable mutation. The current canonical identity namespace is v3.
- Parts-merchant text such as an "oil change kit" now requires strong
  performed-work evidence before it can be classified as completed service;
  ambiguous bundled lines remain manual review.
- Synthetic purchase/service coverage now includes Advance, O'Reilly, NAPA,
  AutoZone, Carquest, Pep Boys, a dealership parts counter, Valvoline, Take 5,
  and independent shop examples across oil/filter, brake, battery,
  transmission, coolant, brake, differential and power-steering fluids, engine/
  cabin/fuel filters, spark plugs, serpentine belt, radiator hose, tires,
  wipers, and washer fluid. A 75W-90 gear-oil regression prevents generic
  synthetic/viscosity text from creating an Engine Oil false positive. This is
  early fixture coverage, not merchant-wide accuracy proof.
- Split description/price lines now use completed parts-store transaction
  evidence, including branded AutoZone battery/group text, without claiming
  installation. Invalid metadata dates no longer hide a later valid receipt
  date. On mixed shop invoices, line-level estimate/quote/proposed language
  prevents that item from inheriting completion evidence from unrelated paid
  work. Unscoped declined/return headings force conservative manual review
  rather than leaking completion or purchase intent across lines.
- Conservative comparison normalization handles selected high-confidence text
  damage (`0IL`, `AUT0ZONE`, `0DOMETER`, and Unicode dash variants) without
  changing the source-faithful evidence snippet. Named-month dates are accepted
  alongside numeric dates.
- Parser work is bounded to 2 MiB, 5,000 non-empty rows, and 500 normalized
  characters per row. Exceeding those limits emits a manual-review warning and
  cannot remain `readyForReview`; a synthetic oversized-corpus regression
  covers that fail-safe behavior.
- Ambiguous numeric dates now follow explicit supported locale conventions and
  always require confirmation. An unsupported locale leaves an ambiguous date
  unset instead of guessing. An explicit reference date prevents future
  receipt dates from silently prefilling service history and still allows a
  later valid date to be found. Generic next-due evidence on a multi-operation
  invoice is restricted to engine oil; another item needs item-specific
  schedule wording, preventing interval leakage across unrelated services.
- Next-service calendar dates are parsed separately from the receipt service
  date, so a due date printed first cannot become completed-service history.
  Supported later dates may prefill a one-to-36-month Basic interval only when
  they form an exact calendar-month span, including month-end clamping.
  Ambiguous, unsupported-locale, reversed, and non-whole-month schedules force
  review instead of inventing an interval. Generic due dates retain the same
  multi-item isolation as mileage schedules.
- A data-driven synthetic corpus now describes merchant, receipt kind,
  per-item expected action, and forbidden candidates in JSON. Twenty-five
  exact corpus cases run through the maintenance gate so another model can
  expand coverage by adding fixtures instead of duplicating test logic. A
  separate 26-case layout corpus labels layout and recognized-text damage
  classes and covers wrapped descriptions, detached prices, bounded three-row
  fragments, service aliases, merchant OCR aliases, general and warehouse
  retailers, retailer service boundaries, transaction adjustments, true
  returns/exchanges, warranty work, and alias-collision guards.
  Detailed extraction also retains candidate-scoped filter part numbers, brake
  axle, oil type and weight, tire brand/type and size, and wiper sizes in
  editable Advanced setup fields. The exact corpus defaults to exact
  candidate-set matching and repeats every case under case, whitespace, and
  CRLF transformations.
- Persistable evidence snippets redact VINs, emails, formatted phone numbers,
  payment-number sequences, long account-like numbers, and street addresses.
  Raw receipt text remains outside the draft and finalized maintenance record.
- An editable receipt-review screen now shows the maintenance-native active
  vehicle row and live global odometer, requires a decision per candidate,
  exposes redacted evidence and editable details, blocks a stale active-vehicle
  binding, confirms contradictory evidence, and returns inert commands only.
  Cancel/discard, validation, conflict, and no-mutation widget paths are gated.
- `openMaintenanceReceiptTextReview` is the maintenance-owned text boundary for
  future OCR coordination. It accepts source text, binds the current stable
  vehicle ID and live odometer, parses locally, and opens review without
  importing camera/OCR code or retaining the raw text.
- Receipt review choices now persist as a versioned local draft keyed by stable
  vehicle ID plus the normalized source-text SHA-256 fingerprint. Re-scanning
  the same text restores the review, Maintenance home lists resumable receipt
  drafts, and confirm/discard clears the draft through the same serialized
  write queue. Draft payloads omit raw source text, VINs, and email addresses.
- A receipt application service now revalidates confirmed commands and can
  commit setup records plus completed-service events in one local durable
  snapshot. Exact retries are idempotent, a changed active vehicle or incomplete
  service evidence rejects the whole batch, failed storage leaves memory
  unchanged, and the service never updates global odometer truth. It is not yet
  invoked automatically by the review/OCR handoff.
- Finalized setup records and service events retain bounded receipt command,
  source-fingerprint, and parser-version provenance through restart without raw
  receipt text. Purchase-only setup stays incomplete and opens the existing
  manual detail flow. Basic setup retains receipt-suggested intervals without
  saving product details; explicit Advanced setup retains reviewed details.
  Catalog matching is case-insensitive so parser capitalization cannot
  silently select the wrong item.
- The maintenance text boundary now also exposes a full review-and-confirm
  orchestration path. Review remains mutation-free, a second dialog states the
  exact setup/history counts and that odometer truth will not change, cancel
  preserves the local draft, and a successful durable/idempotent save clears
  only that vehicle-and-fingerprint draft.
- The generic `ReceiptOcrHandoffDestination` currently has expense, fuel, and
  inventory routes but no dedicated maintenance route. Change that only in an
  explicitly coordinated OCR-handoff integration pass; parser development does
  not require it.

## Target architecture

1. `ReceiptOcrHandoff` supplies source-faithful text and diagnostics.
2. The pure maintenance parser returns a versioned result containing:
   receipt kind, merchant/date hints, ranked maintenance candidates, extracted
   details, service/due odometer evidence, interval evidence, confidence,
   warnings, and safe evidence references.
3. A maintenance review mapper combines parser output with the selected stable
   vehicle ID and current global odometer snapshot. It never mutates either.
4. The review UI asks the user per candidate:
   track this item, log confirmed completed service, keep as expense only, or
   ignore. Setup defaults to Basic intervals; Advanced item details require an
   explicit selection. Every inferred field remains editable.
5. A maintenance application service validates the confirmed command and writes
   one atomic local transaction: finalized maintenance record/event, receipt
   proof reference, and audit metadata.
6. Optional durable-storage mirroring consumes the confirmed local record. The
   parser never calls Firebase.
7. Dashboard and every screen observe the same global odometer/vehicle owners.

## Delivery phases

### Phase 0 - Baseline and ownership

- Recheck Git status before every pass.
- Preserve unrelated device-capability, durable-storage, trip, and inventory
  changes.
- Run the smallest applicable test first. Stop on the first red gate.
- Keep the exact failing command and file in the handoff.

Exit: clean maintenance lane inventory, focused baseline evidence, no ownership
collision.

### Phase 1 - Manual maintenance durability

- Introduce stable IDs and schema versions for maintenance records and service
  events without using vehicle nicknames as keys.
- Persist finalized records/events locally with migration, validation,
  serialized writes, crash recovery, duplicate protection, and export/restore
  coverage.
- Preserve current setup/detail/manual logging behavior.
- Coordinate only the mirror contract with the durable-storage owner.

Exit: create, edit, restart, restore, delete/archive, and service-history flows
are locally durable for multiple vehicles. No receipt parser dependency.

Current status: partial. Create, edit, service logging, restart restoration,
reversible archive/restore, history preservation, vehicle-rename continuity,
legacy identity migration, duplicate rejection, low-storage refusal, and backup
recovery are covered. Full export/import, service-event correction/void
semantics, and multi-vehicle lifecycle matrices still need implementation and
proof before this phase exits.

### Phase 2 - Pure parser contract

- Keep `maintenance_receipt_parser.dart` free of framework and service
  dependencies.
- Separate receipt kind from maintenance candidates.
- Separate product purchase evidence from completed service evidence.
- Preserve confidence, warnings, evidence line numbers, and redacted snippets.
- Make all suggestions confirmation-only and deterministic.

Exit: deterministic unit tests and adapter boundary checks pass locally.

### Phase 3 - Auto-parts purchase coverage

Build synthetic plus licensed/consented real fixtures for Advance Auto Parts,
AutoZone, O'Reilly, NAPA, Carquest, Pep Boys, dealer parts counters, warehouse
clubs, general retailers, and independent parts stores. Cover:

- engine oil type and viscosity; brand and quantity are not required fields;
- oil/air/cabin/fuel filters and part numbers;
- batteries, group size, core charges, warranties;
- brake pads, rotors, fluid, axle/position;
- coolant, transmission, differential, power-steering, and washer fluids;
- spark plugs, ignition parts, belts, hoses, wipers, bulbs, tires, and sensors;
- returns, exchanges, discounts, coupons, bundles, core credits, split
  descriptions, OCR damage, duplicate windows, and multiple vehicles.

Exit: no purchase-only fixture can create completed service; required-field and
false-positive budgets meet the release threshold.

### Phase 4 - Service invoice coverage

Cover quick-lube shops, tire shops, dealerships, national chains, independent
shops, fleet work orders, mobile mechanics, and DIY handwritten/manual review.
Extract only when supported:

- performed operation versus recommendation/estimate/declined work;
- service date, odometer in/out, next due odometer/date;
- labor/part grouping, quantity, fluid type/specification, position/axle;
- warranty/comeback/no-charge work and multi-operation invoices.

Exit: estimates and declined work never become history; completed work remains
reviewable and editable.

Current status: partial. Explicit performed/completed and
declined/recommended headings now scope following maintenance candidates until
another explicit status heading resets the section. Ambiguous document-level
estimates remain manual-review only. Explicit completed sections also support
terse zero-dollar warranty/comeback item rows without inventing completion from
`NO CHARGE` alone. Odometer out, in, and clearly historical readings now have
deterministic precedence; reversed in/out evidence forces review and never
mutates canonical odometer state. Because canonical maintenance values are
currently miles-only, kilometer-labeled service, due, and interval evidence is
kept out of mile fields and requires manual conversion/review; a separately
proven mile reading remains usable. Real multi-operation invoice validation,
labor/part grouping, and broader warranty/comeback coverage remain open.

### Phase 5 - Review and manual-flow integration

- Add maintenance as an explicit downstream destination only after ownership is
  coordinated.
- Prefill the existing manual setup/detail and service-log fields; do not create
  a parallel maintenance UI.
- Require the user to choose the active vehicle and resolve odometer conflicts.
- Allow setup-only, history-only, both, expense-only, or ignore per line.
- Show exact/estimated provenance and preserve corrections.

Exit: widget and lifecycle tests prove cancel/retry/restart behavior without
silent mutation.

Current status: partial. The framework-free review/validation contract,
editable review screen, maintenance-owned text handoff, and versioned local
review-draft restart/resume flow are implemented and gated. Purchase-
installation, contradictory evidence, active-vehicle change, field clearing,
cancel/discard, live-odometer conflict, same-text resume, and Maintenance-home
resume safeguards have no-mutation widget proof. The shared OCR destination is
  intentionally unchanged. Existing manual service-screen prefill,
  receipt-proof file linkage, and coordinated exposure from the OCR destination
  remain unimplemented.

### Phase 6 - Correction learning and optional packs

- Store user-confirmed merchant aliases and parsing corrections locally with
  version/provenance and an undo/reset path.
- Keep optional parser packs explicit, signed/checksummed, size-budgeted,
  locale-aware, and useful offline.
- An AI agent or ChatGPT backend is opt-in assistance only. It receives minimal
  redacted context, returns the same parser contract, and never outranks local
  user-confirmed values.

Exit: offline mode stays fully usable; cloud/AI failure never blocks manual
maintenance.

### Phase 7 - Commercial validation

- Differential, metamorphic, mutation, fuzz, malformed-input, locale, currency,
  performance, memory, low-storage, migration, replay, and duplicate-import QA.
- Holdout real-receipt sets with consent and privacy review.
- Physical-device review for UI/lifecycle only after explicit device
  authorization; parser correctness remains deterministic and device-neutral.
- Track precision/recall and false-positive budgets by merchant and item family,
  not only aggregate pass counts.

Exit: release evidence includes accuracy, false-positive rate, latency/memory,
durability, recovery, privacy, accessibility, and field validation. A green
analyzer or synthetic suite alone is not completion.

The user-set commercial release floor is 90% measured accuracy for every
supported maintenance family and required field, not merely a favorable
aggregate. Common families should target materially higher than the floor.
Purchase-to-service false positives, silent odometer mutation, and bypass of
final user confirmation remain zero-tolerance safety failures.
A green synthetic development gate is not real-receipt holdout proof. Release
evidence must measure consented receipts that were not used to author parser
rules, with results separated by maintenance family, merchant/layout family,
field, and recognized-text damage class.

## Quiet QA loop for each parser pass

1. Add or tighten one regression fixture that demonstrates the gap.
2. Keep each receipt file at 499 lines or fewer, then run
   `tool/maintenance_receipt_qa_gate.sh`.
3. Make the smallest parser-only change.
4. Rerun the exact failed test, then the gate.
5. Record new supported behavior and unresolved false positives.
6. Every 200-300 accepted passes, run an architecture/drift review with a
   stronger model before expanding the corpus.

Pass numbering and accepted-pass evidence live in
`docs/maintenance_receipt_parser_pass_log.md`. The current accepted pass is 56;
the next bundled app-work pass is 57. Duplicate-line cleanup remains OCR-owned,
not parser-owned.

## Handoff instructions for another Codex model

Read this file first. Then run:

```sh
git status --short --branch
tool/maintenance_receipt_qa_gate.sh
```

Do not edit unrelated dirty files. Work one fixture family at a time. Never
weaken a test or threshold merely to make a pass green. Never interpret a parts
purchase as completed service. Never update odometer state from parser output.
Never add direct Firebase, Hive, camera, OCR, or expense dependencies to the
pure parser. Stop and report the exact gate if shared ownership or a regression
blocks the pass.
