# Receipt Camera World-Class QA Standard

Maintainiac receipt capture is not allowed to be "works on my phone" quality.
The camera/OCR/parser pipeline must be scored like a production money app:
capture quality, OCR handoff, parser accuracy, privacy-safe diagnostics, and
device/storage behavior all need their own gates.

## Benchmark Behaviors

Current market/product signals:

- Expensify SmartScan sets the baseline expectation that a user can snap a
  receipt and have merchant, date, and amount filled automatically.
- Dext sets the line-item benchmark: automatic line-item and tax extraction is
  a product-level feature, not a nice-to-have.
- QuickBooks sets the accounting workflow benchmark: receipt OCR should produce
  amount, date, location/merchant, and category/matching candidates that remain
  reviewable before saving.
- Google ML Kit sets the local OCR engineering boundary: text recognition is
  image-quality dependent and returns structured text pieces that should be
  scored by line/block/source, not treated as one untrusted blob.

Maintainiac's bar is higher for contractor use because receipts can feed
expenses, work supplies, inventory, maintenance intervals, and admin
diagnostics.

## Release Gates

Every receipt camera/OCR release candidate must pass these gates:

- `capture`: photo is clear enough, in focus, not too dark, not too small, and
  contains the needed receipt section.
- `coverage`: bottom edge and total/subtotal evidence are present, or the app
  asks for another section before opening receipt details.
- `ocr_text`: merchant, date, total, tax, and visible line prices are extracted
  into structured OCR evidence with per-line confidence.
- `parser`: fuel, retail, contractor supply, and maintenance receipt fields are
  classified without confusing tender/auth/reference rows for purchases.
- `maintenance`: oil type, tire rotation, service name, mileage, next-service
  text, and interval hints are detected when present.
- `admin_diagnostics`: failure reports include stage, reason, device tier,
  storage class, capture route, OCR source policy, parser readiness, and safe
  image-quality evidence without raw user text.
- `privacy`: no raw receipt text, personal names, card numbers, addresses, or
  unredacted original images leave the device unless an explicit admin-safe
  diagnostic path redacts them first.
- `device_storage`: old/low-end devices must downgrade work, defer optional
  packs, and avoid choking memory; low storage must trigger local/cloud policy.
- `firebase`: upload payloads must be schema-stable, redacted, resumable, and
  small enough for mobile sync.

## Fixture Packs

The QA corpus must include at least these packs:

- `fuel`: pump rows, gallons, price per gallon, discounts, fleet card/auth rows,
  subtotal/tax/total, and regional convenience-store naming.
- `retail`: common purchases, multiple line items, coupons, returns, tender
  lines, tax, and split business/personal use.
- `maintenance`: oil changes, oil viscosity, filters, tire rotation, mileage,
  next service due, brake/inspection/tire service, and shop names.
- `contractor_supply`: Lowe's, Home Depot, Menards, supply-house receipts,
  quantities, SKU-like lines, material names, and inventory handoff candidates.
- `long_receipt`: multi-photo top/middle/bottom sections with overlap evidence,
  missing-bottom prompts, and stitched OCR source checks.
- `damaged_ocr`: blur, glare, shadows, faded ink, wrinkles, skew, partial crop,
  low contrast, and OCR token swaps such as `O`/`0`.
- `privacy_admin`: card/tender/reference rows, personal address-like lines,
  phone numbers, and safe diagnostic payload checks.
- `device_tiers`: low memory, low storage, older Android/iPhone capability,
  offline OCR, optional pack unavailable, and cloud-assist disabled.

## Score Targets

Pre-alpha gates may be lower while the cleanup is active, but the release
trajectory is:

- Capture/coverage gate: 98%+ on fixture corpus.
- OCR text contract: 95%+ field-level readiness on supported receipt classes.
- Parser readiness: 90%+ for first supported receipt families, then ratchet up.
- Maintenance receipt signal detection: 90%+ before maintenance automation is
  allowed to create reminders.
- Privacy/admin redaction: 100%; no exceptions.
- Crash-free focused receipt tests: 100%.

Any failed gate must produce a named issue and a suggested next action. A single
average score is not enough.

## Current Local Runner

`tool/receipt_qa_runner.dart` now reports dimension scores for:

- `capture`
- `ocr_text`
- `production_parser`
- `business_personal`
- `parser`
- `maintenance`
- `privacy_admin`
- `device_storage`

It currently includes fixture packs for fuel, noisy OCR, retail, contractor
supply, maintenance, long receipts, damaged OCR, privacy/admin, and device
tiers. Fuel coverage includes a diesel baseline and a split-row tender receipt.
Noisy OCR coverage includes swapped `O`/`0` characters in dates, gallons,
totals, subtotal, and tax labels. Contractor-supply coverage includes
home-center material quantities, packs, and split OCR material rows. Maintenance
coverage includes oil/filter/tire-rotation text plus odometer, due-mileage,
oil-weight, and interval wording. Long-receipt coverage separates top, middle,
and bottom sections so missing-bottom guidance is scored apart from
bottom-section total capture. Damaged-OCR coverage scores production
`ReceiptPhotoQualityCheck` outputs for blur, glare, crop, and low-contrast
review paths. Privacy/admin coverage checks card/auth/reference, address/phone,
and private name-like rows without leaking raw sensitive tokens in summary
output. Device-tier coverage checks memory/storage, local photo, stitch, cloud
assist, and auto-capture budgets.

The current runner scores production parser behavior through pure Dart entry
points and must stay at or above the configured `--fail-under` threshold with an
empty blocker list. JSON reports include `fieldOutcomeCounts` so merchant, date,
total, line-item, fuel, maintenance, business/personal, privacy/admin,
device-storage, capture-quality, and parser-readiness outcomes are visible as
exact matches, acceptable normalized matches, misses, false positives, and
privacy violations instead of only one average score.
JSON reports also include `fixtureManifest` with
`receipt_qa_fixture_manifest_v1`, current inline Dart fixture source files per
pack, and the required expected-field list. This is a guarded stepping stone
toward external JSON/CSV fixtures; `externalFixtureFilesReady` remains `false`
until those files actually exist and are loaded by the runner.
The manifest now pins the external fixture migration plan too:
`receipt_qa_fixture_v1` files under `test/fixtures/receipt_qa/<pack>.json`,
with raw OCR text allowed only inside fixture files and excluded from summary
reports. The schema lives at
`test/fixtures/receipt_qa/receipt_qa_fixture_v1.schema.json` and is checked by
the runner contract before fixture files are migrated. It is also protected by
`tool/receipt_external_fixture_schema_gate.dart` so schema drift can be checked
without launching Flutter or the full receipt QA runner.
The migration checklist lives at
`test/fixtures/receipt_qa/fixture_pack_inventory.json`; it lists each planned
pack file as `pending_inline_migration` until the runner actually loads the
external fixture files.

Long QA commands should be launched with `tool/receipt_quiet_batch.sh` and
checked with `tool/receipt_quiet_batch_status.sh`. The status helper reports
metadata only and must not tail `run.log`; this policy is enforced by
`tool/receipt_quiet_batch_policy_gate.dart`.
Use `tool/receipt_start_quiet_quality_gate.sh` for the expensive receipt quality
gate so it starts detached and records results under the quiet-batch directory.
Use `tool/receipt_start_ocr_pipeline.sh` for the larger unattended OCR/camera
pipeline. Its blueprint is `docs/receipt_ocr_pipeline_blueprint.json`, and its
phase logs are written under `/tmp/maintainiac_receipt_ocr_pipeline`.
When a phase fails, `tool/receipt_pipeline_failure_to_regression.dart` turns the
failure report into a regression task so the fix must harden the whole failure
family before the pipeline is rerun.
They also include `fixtureFieldCoverage`, a counts-only view of required
expected fields per pack. That coverage report deliberately omits raw fixture
text so QA logs can show external-fixture readiness without leaking receipt
content.

`test/receipt_qa_runner_contract_test.dart` protects the runner contract itself:
the JSON report must include the required dimensions, supported pack list, pack
scores, field outcome counts, key fixture names, no blockers, and 90%+ scores
for the runner, every fixture, every pack, and every dimension. Focused pack
runs are covered by `test/receipt_qa_runner_pack_focus_test.dart`, and unknown
packs must fail with a blocker even when `--fail-under=0`.

## Next Test Work

1. Convert the versioned fixture manifest from inline Dart source files to
   actual JSON/CSV fixture files loaded by the runner.
2. Move the current per-field outcome reporting from derived check fields toward
   expected-field fixture files with explicit exact, normalized, missed,
   false-positive, and privacy-violation labels.
3. Add image-quality fixtures for synthetic blur/skew/shadow/crop metadata.
4. Add admin diagnostic snapshot tests that prove safe failure reports are useful
   without leaking user data.
5. Add device-tier budgets for memory, local OCR source count, stitch size, and
   optional parser pack behavior.
