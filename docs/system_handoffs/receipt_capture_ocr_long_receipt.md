# Receipt Capture, OCR, And Long Receipt Living Handoff

## Current Status

`PRESENT / VERIFIED SUBSET / NEEDS RECONCILIATION`. Native/import capture,
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
- `DEFERRED`: user-selectable retention, 90-day default, seven-day reminder,
  advance warning, similarity evidence, proof thumbnail, and Review/Save/Keep/
  Delete workflow. This is a dedicated future subsystem, not consolidation work.
- `NEEDS RECONCILIATION`: ReceiptCamera, Receipt_OCR, and Long_Receipt source
  history still requires semantic feature-level comparison; final device proof
  and full platform builds are not complete.

## Rolling Log

- 2026-07-22: Created as the receipt-intelligence system record and preserved
  the product-owner-approved ownership, review, and deferred-draft boundaries.
- 2026-07-22: Recorded the explicit split-allocation semantic checkpoint; mode
  visibility differences remain a separate product-flow review.
