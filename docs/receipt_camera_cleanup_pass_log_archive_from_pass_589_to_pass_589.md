# Receipt Camera Cleanup Pass Log Archive - Pass 589

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the project line-count cap.

## Pass 589 - 16:06:06 EDT to active cleanup

Scope:
- Classified generated work-supply catalog Dart files separately in the source
  audit instead of mixing generated data with hand-written receipt parser code.
- Added an explicit `--include-generated-catalog-data` source-audit mode so
  generated catalog files can still be audited intentionally.
- Added regression coverage proving generated catalog data is skipped by
  default and included when requested.
- Added regression coverage proving vendored native `.symlinks` plugin sources
  do not count against app-owned source caps.
- Hardened Add Another Photo ordering so inserted long-receipt sections carry
  anchor section, final section, offset, and order-policy diagnostics.
- Extended receipt result handoff counts so inserted section metadata reaches
  privacy-safe section-order outcomes and admin/QA summaries.
- Hardened manual move-earlier/move-later ordering so user-reordered receipt
  sections carry privacy-safe original/final section and direction evidence.
- Locked manual reorder plans to adjacent one-section moves so future UI
  controls cannot silently skip receipt sections.
- Added an explicit capture-flow review-depth override so detailed-line intent
  reaches the native camera session.
- Mapped expense simple/full review style to native price-only/detailed-line
  capture, while inventory and maintenance capture request detailed lines.
- Hardened camera quality diagnostics so normalized receipt photo path aliases
  cannot publish duplicate per-photo evidence.
- Added the local Google ML Kit barcode/QR scanner dependency and a shared
  scanner service for receipt, inventory, and maintenance callers.
- Added barcode/QR result models that normalize duplicate lookup values while
  keeping raw code text out of privacy-safe summaries.
- Blocked sensitive QR payload types such as Wi-Fi, contact, phone, geo, and
  driver-license values from inventory lookup suggestions.
- Added focused retake/order and source-contract regressions for inserted
  section metadata and stale inserted-path rejection.
- Added a focused regression for non-adjacent manual reorder requests.
- Added focused shared camera flow regressions for review-depth propagation.
- Added focused camera-result quality regression coverage for path aliases.
- Added focused barcode scanner service regressions for dedupe, invalid paths,
  sensitive payload handling, and platform failure warnings.
- Split section-order helper logic out of native-signal summaries after the
  source audit caught the file over the line cap.
- Recorded `BUG-RECEIPT-0106` and `BUG-RECEIPT-0107` under
  `multi_photo_ordering`.
- Recorded `BUG-RECEIPT-0108` and `BUG-RECEIPT-0109` under
  `multi_photo_ordering`.
- Recorded `BUG-RECEIPT-0110` under `receipt_line_review_mode`.
- Recorded `BUG-RECEIPT-0111` under `camera_capture_quality`.
- Recorded `BUG-RECEIPT-0112` under `barcode_qr_scanning`.
- Archived Pass 564 out of the live cleanup log to keep the active log under
  the project line-count cap.
- Archived Pass 565 out of the live cleanup log after this pass grew the active
  log past the cap.
- Archived Pass 566 out of the live cleanup log before recording result-level
  insert-order handoff coverage.
- Archived Pass 567 out of the live cleanup log before recording adjacent
  manual-reorder guard coverage.
- Archived Pass 568 out of the live cleanup log before recording camera-quality
  path identity coverage.
- Archived Pass 569 out of the live cleanup log before recording barcode/QR
  scanner coverage.

Verification:
- Passed focused Flutter source-audit contract regression coverage.
- Passed focused work-supply data source audit for hand-written files.
- Confirmed `--include-generated-catalog-data` still reports the oversized
  generated catalog data files.
- Passed targeted analyzer and focused Flutter tests for receipt retake/order
  and long-receipt guidance contracts.
- Passed focused receipt result stitch/scanner regressions for valid and
  malformed insert-after metadata.
- Passed focused manual reorder regressions and source contract coverage.
- Passed focused adjacent manual reorder regression coverage.
- Passed focused shared capture-flow review-depth regression coverage.
- Passed focused camera-result quality path identity regression coverage.
- Passed focused barcode scanner service regression coverage.
- Passed the receipt QA runner after the source-audit and long-receipt ordering
  cleanup batch.
- Passed scoped receipt source audit and cleanup/doc size gates.
- Passed `git diff --check`.
