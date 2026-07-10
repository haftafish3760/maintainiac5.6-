# Expense Release-One Blueprint

This is the release-one architecture map for the Maintainiac expense app. It
connects receipt camera, OCR handoff, receipt parsing, manual entry, PDF import,
expense records, reports, diagnostics, QA, and future collaboration between two
Codex workers without letting the work drift into unrelated modules.

The dedicated second-worker handoff lives in
`docs/expense_codex_b_handoff.md`.

## Release-One Target

Release one should make expenses dependable enough for real users to record
money, attach proof, review OCR/parser suggestions, classify business/personal
use, recover from mistakes, and export defensible records. The goal is not
perfect automation. The goal is a trustworthy expense app where manual review is
clear, saved records are stable, and each known bug becomes a regression test.

## Source Of Truth

- Hive/local storage is the immediate source of truth.
- Firestore/cloud sync is a mirror or backup, not the brain.
- OCR, parser, camera, PDF, and automation output are suggestion data until the
  user confirms them.
- User-confirmed financial data must never be silently overwritten.
- Recaps, reports, exports, PDFs, invoices, and admin summaries read source
  records; they do not mutate trips, expenses, inventory, odometer records, or
  receipt proof.
- Original receipt captures and imported files are source evidence. Cropped,
  stitched, OCR-ready, compressed, redacted, and PDF-rendered copies are derived
  artifacts.

## Major Lanes

### Lane A - Shared Receipt Camera

Owned by the receipt camera blueprint:
`docs/receipt_camera_release_one_blueprint.md`.

Responsibilities:

- native Android CameraX and iOS AVFoundation capture contracts
- clear single-photo capture
- multi-photo long receipt capture
- retake by segment index
- ghost/overlap guidance
- blur, glare, low-light, crop, edge, and bottom-coverage warnings
- conservative stitching and ordered fallback
- source preservation and derived-artifact lineage
- camera handoff to OCR/parser review

### Lane B - Expense Intake UX

Responsibilities:

- expense home, category picker, and date-aware add flow
- manual expense entry with no receipt
- receipt-backed expense entry
- PDF/photo/file import entry
- simple receipt mode for price/total-focused review
- detailed receipt mode for line-item review
- business, personal, and split classification
- vehicle/work-profile context when applicable
- draft recovery after interruption
- clear back behavior on every step

### Lane C - Receipt OCR And Parser Review

Responsibilities:

- ML Kit local OCR handoff from camera/PDF/import sources
- optional premium OCR contract later
- raw OCR text and structured line/block preservation as suggestions
- merchant, date, subtotal, tax, total, payment hint, line amount, fuel detail,
  discount, refund, tip, split-payment, and warning extraction
- confidence and warning model
- low-confidence review gates
- no invented values
- user-confirmed values outrank OCR/parser values
- Spanish/English receipt keyword support for release-one basics

### Lane D - Expense Record Model And Storage

Responsibilities:

- stable expense id and receipt id references
- event date, optional time, created/updated timestamps
- category, subcategory, notes, payment context
- business/personal/split classification
- vehicle/work-profile assignment where applicable
- receipt proof references and derived artifact references
- audit trail for corrections
- draft store and recovery lifecycle
- local save, edit, copy, delete, and restore-safe behavior

### Lane E - Fuel Expense Specialization

Responsibilities:

- odometer-first fuel flow
- gasoline, diesel, electric charging, and future fuel/energy types
- gallons, liters where needed, kWh, unit price, subtotal, tax, and total
- topped-off vs partial-fill state
- MPG/cost-per-mile calculations from source records
- business vs personal fuel allocation from mileage/trip data, not a manual fuel
  business/personal toggle
- parser hints for gallons, unit price, pump, grade, and charging receipts

### Lane F - PDF And File Intake

Responsibilities:

- import PDF/photo/file from platform pickers and share/open-in flows
- inspect PDF safely before OCR or rendering
- render receipt pages to reviewable images when safe
- reject encrypted, huge, malformed, suspicious, or unsupported PDFs with clear
  recovery actions
- preserve the imported source file or source reference according to storage mode
- create derived preview/OCR artifacts without mutating source evidence
- include PDF receipt proof in export/audit packages

### Lane G - Reports, Export, And Audit Packets

Responsibilities:

- expense calendar and day views
- weekly/monthly/category totals
- CSV export from source records
- receipt/proof inclusion when available
- tax/audit packet export
- user-selected destination and storage checks
- export progress and completion summary
- no report/export mutation of source expenses

### Lane H - Diagnostics And Admin Health

Responsibilities:

- local-first privacy-safe telemetry
- failure diagnostics for camera, OCR, parser, save, sync, export, and PDF import
- app version, platform, device tier, storage mode, plan status, online/offline
  status, workflow step, confirmed cause, missing evidence, and retry count
- summary-only Command One/admin health
- no receipt images, raw OCR text, item descriptions, merchant names, addresses,
  phone numbers, notes, file paths, transaction numbers, or private line content
  in admin telemetry
- one bounded summary document shape for Firestore health when sync is enabled

### Lane I - QA, Fixtures, And Regression

Responsibilities:

- deterministic tests for every financial calculation
- parser fixtures for every parser rule
- synthetic receipt and PDF fixtures
- real receipt fixture format with redaction support
- every confirmed bug becomes a regression test
- generalized bug-family tests when the root cause can affect multiple cases
- offline/restart/conflict tests for sync/storage rules
- source audit, doc size, line-count, privacy redaction, and quality gates

## Two-Codex Work Split

Parallel work is possible only with strict boundaries. Do not let two models edit
the same files in the same pass window.

### Codex A - Camera And Shared Receipt Infrastructure

Primary ownership:

- `lib/shared/widgets/receipt_capture/**`
- `lib/shared/receipts/**`
- Android/iOS native receipt camera bridge files
- camera, image quality, stitching, OCR-source handoff, and receipt attachment
  tests
- `docs/receipt_camera_release_one_blueprint.md`
- receipt camera cleanup logs and receipt camera gates

Focus:

- camera capture
- long receipt flow
- source preservation
- image quality
- stitching/fallback
- OCR handoff contract
- camera-specific regression fixtures

### Codex B - Expense App And Derived Outputs

Primary ownership:

- `lib/screens/expenses/**`
- expense record stores, ledgers, draft stores, category flows, review flows, and
  export handoff files
- app-generated PDF/export files
- expense telemetry and Command One/admin summary files
- expense parser/review tests that consume the shared receipt handoff
- `docs/expense_release_one_blueprint.md`

Focus:

- expense home and add flow
- manual and receipt-backed expense review
- simple/detailed line review
- business/personal/split UX
- fuel expense specialization
- PDF/file intake as an expense source
- reports/export/audit packet behavior
- expense diagnostics and privacy-safe telemetry

### Shared Contract Boundary

Both workers may read shared contracts, but only one worker edits a shared
contract in a given branch. Shared contracts include:

- receipt capture result models
- OCR-source handoff models
- expense receipt parser result models
- receipt proof/storage models
- telemetry redaction schemas
- source audit and quality gates

If both lanes need a shared contract change, create a small integration branch
first, merge it, then let both workers rebase or reclone from that branch.

## GitHub Coordination Rules

Use branches as work lanes:

- `codex/expense-camera-lane`
- `codex/expense-app-lane`
- `codex/expense-contract-integration`

Safe workflow:

1. Push the current known-good 5.6 state to GitHub.
2. Each Codex worker clones or checks out its own branch.
3. Each worker reads this blueprint, `PROJECT_RULES.md`, and the production
   directive before editing.
4. Each worker stays inside its owned paths unless a documented dependency
   requires a contract edit.
5. Each worker runs targeted checks before pushing.
6. Integration happens through `codex/expense-contract-integration`, not by
   copying files manually between machines.
7. Resolve conflicts by contract ownership, not by whichever branch is newer.
8. After integration passes targeted checks, run the appropriate milestone gate.

Danger signs:

- both workers editing the same model file
- both workers editing the same store file
- one worker changing parser output shape while the other changes review save
  code without a contract branch
- pushing unverified generated files or private receipt samples
- weakening tests to make branch integration easier

## Milestones

### Milestone 1 - Expense Architecture Locked

Evidence:

- this blueprint exists and is linked
- production directive guard passes
- source audit and doc size gates pass
- owned-path split is documented

### Milestone 2 - Camera Handoff Ready

Evidence:

- receipt camera release-one milestone gates pass
- camera handoff has source references, derived artifacts, quality warnings,
  stitch confidence, and review status
- expense review can consume the handoff without owning camera internals

### Milestone 3 - Manual Expense Ready

Evidence:

- manual expense create/edit/copy/delete works
- drafts recover after interruption
- business/personal/split classification is stable
- records save to local source-of-truth storage
- financial totals are deterministic

### Milestone 4 - Receipt Expense Ready

Evidence:

- receipt-backed add flow works from photo/PDF/import sources
- simple and detailed review modes work
- OCR/parser suggestions require confirmation
- line numbers and receipt proof references survive save/edit/export
- every low-confidence parser result requires review

### Milestone 5 - Fuel Expense Ready

Evidence:

- odometer-first fuel entry works
- topped-off and partial-fill behavior is tested
- gasoline, diesel, and electric charging flows are represented
- MPG and cost-per-mile calculations use source records
- fuel receipt parser hints are reviewed before save

### Milestone 6 - PDF/File Intake Ready

Evidence:

- safe PDF inspection and rejection rules pass
- readable PDFs can become reviewable receipt sources
- malformed, encrypted, huge, wrong-type, and empty files have regression tests
- source files are preserved according to storage mode

### Milestone 7 - Reports And Export Ready

Evidence:

- calendar/day/category totals read source records
- CSV and audit export packages include records and receipt proof references
- exports do not mutate source records
- low-storage and destination-failure paths are recoverable

### Milestone 8 - Diagnostics And Privacy Ready

Evidence:

- local failure diagnostics cover camera, OCR, parser, save, PDF, export, and
  sync paths
- Command One/admin summaries are aggregate-only
- privacy redaction guards reject private content
- Firestore health shape remains bounded and summary-only

### Milestone 9 - Release Candidate

Evidence:

- targeted lane tests pass
- expense fast guard passes
- receipt/camera quality gate passes
- source audit passes
- doc/log gates pass
- line-count cap passes
- Android and iOS smoke checks pass when devices are available
- known limitations are documented instead of hidden

## Pass Budget

Planning anchors for release-one quality:

- Camera/shared receipt infrastructure: 1,500-2,500 passes.
- Expense intake, records, and review: 2,500-5,000 passes.
- Receipt parser for expenses: 1,500-3,500 passes.
- PDF/file intake and receipt PDFs: 1,500-4,000 passes.
- Diagnostics, reporting, export, and release hardening: 1,500-3,000 passes.
- Spanish release-one support across UI/parser keywords: 500-1,200 passes.

The realistic combined release-one expense system range is about 9,000-19,200
focused passes after the camera reset, with ongoing real-receipt hardening after
release. A 30,000-pass long-term polish target is reasonable for world-class
depth, but it should not block moving into release-candidate work once evidence
proves the release-one milestones.

## Non-Negotiable QA Rules

- Never build on a failing analyzer, QA runner, source audit, or quality gate.
- Fix failures before adding features.
- Run targeted checks during work and full gates at milestones.
- Do not continuously monitor long-running commands.
- Do not weaken tests, suppress warnings, or remove assertions to pass.
- Every bug fixed gets a regression test.
- Every financial calculation gets deterministic tests.
- Every parser rule gets fixtures.
- Every file/PDF failure family gets malformed, empty, huge, wrong-type, and
  corrupted-input regressions where applicable.
- Every sync/storage rule gets offline, restart, and conflict tests before it is
  release-ready.
