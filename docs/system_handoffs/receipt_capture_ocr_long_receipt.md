# Receipt Capture, OCR, And Long Receipt Living Handoff

## Current Status

`CONSOLIDATED SUBSET / DEVICE QA PENDING`. Native/import capture,
app-private staging, OCR evidence, editable handoff, duplicate detection, and
long-receipt support exist. This is suggestion-only intelligence.

## Implemented Evidence

- Capture/staging/recovery: `lib/shared/widgets/receipt_capture/`
- OCR contracts/evidence/layout: `lib/shared/receipts/`
- Incoming share routing: `lib/app/incoming_receipt_destination_screen.dart`
- Expense review integration: `lib/screens/expenses/entry/`
- Requirements and prior evidence: `docs/receipt_camera_release_one_blueprint.md`,
  `docs/long_receipt_stitching_cross_platform_handoff_2026_07_15.md`

## Product Boundaries

- Every receipt is reviewed by the user. Never silently route Fuel versus
  Expense versus Work Supplies/Materials/Inventory.
- External originals are read-only. App-private temporary files may be cleaned
  only after completion or explicit discard. Selected proof requires explicit
  in-app user deletion. Duplicate detection warns; it does not silently act.
- Work Supplies, Materials, and Inventory are one existing system.

## Verified / Deferred / Remaining

- `VERIFIED SUBSET`: `16ef2f82` recovery/cleanup (38 focused tests), `6bf01ced`
  OCR evidence/recovery (39), `63e2d49c` editable candidate handoff (25).
- `VERIFIED SUBSET`: source commits `7b053a05b` and `27694e9d1` were compared.
  Explicit split ownership was integrated; printed receipt evidence was already
  preserved by the newer 5.7 display/source/provenance separation. Analyzer
  clean and 26 focused tests passed.
- `VERIFIED SUBSET`: source commits `7c6f3acdd` through `5f1392d04` in the
  evidence/capture handoff cluster were compared. Newer 5.7 structured handoff,
  provenance, crop recovery, settings, and review owners already cover the
  unique behavior; 33 focused tests passed.
- `VERIFIED SUBSET`: benchmark commits `3137cc972` through `78d78ebb1` plus the
  benchmark portion of `8ea7fd15f` were compared. Current 5.7 retains the
  privacy-safe real-evidence release gates; 7 focused tests passed. The bundled
  synthetic sample is not release evidence.
- `VERIFIED SUBSET`: recovery/classification/ownership commits `92c14ffa0`
  through `ca3c29504` were compared. Newer 5.7 recovery and visible suggestion
  models were retained. The older automatic multi-consumer route was rejected
  because OCR must not choose Fuel or Inventory ownership; 51 tests passed.
- `CONSOLIDATED`: all 62 source-only commits in
  `Maintainiac_5.6_Long_Receipt` were reopened after the rejected bulk trial and
  compared against the current 5.7 owners. The unique visual-orientation guard
  for native previous-section ghost crops and source-integrity guards for real
  receipt probes were integrated without importing an older parallel review
  UI. Analyzer, Swift parse, Android Kotlin compile, and 11 focused tests passed;
  3 opt-in real-photo probes were skipped because fixture paths were not set.
- `DEFERRED`: user-selectable retention, 90-day default, seven-day reminder,
  advance warning, similarity evidence, proof thumbnail, and Review/Save/Keep/
  Delete workflow. This is a dedicated future subsystem, not consolidation work.
- `REMAINING`: ReceiptCamera is consolidated and Receipt_OCR and Long_Receipt
  source history have been semantically reconciled. Final project-wide gates,
  real-receipt fixtures, and physical-device proof are not complete.

## Rolling Log

- 2026-07-22: Created as the receipt-intelligence system record and preserved
  the product-owner-approved ownership, review, and deferred-draft boundaries.
- 2026-07-22: Recorded the explicit split-allocation semantic checkpoint; mode
  visibility differences remain a separate product-flow review.
- 2026-07-22: Recorded evidence/capture and OCR benchmark clusters as present in
  newer 5.7 equivalents after 33-test and 7-test targeted gates.
- 2026-07-22: Closed the remaining OCR recovery/classification cluster while
  preserving user-selected routing and rejecting automatic domain dispatch.
- 2026-07-22: Reopened all 62 Long Receipt source-only commits, integrated the
  two unique native/source-integrity safeguards, retained the newer 5.7 review
  owner, and passed analyzer, focused, Swift-parse, and Android compile gates.
