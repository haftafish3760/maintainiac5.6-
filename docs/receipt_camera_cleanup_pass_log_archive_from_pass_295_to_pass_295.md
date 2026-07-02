## Pass 295 - 10:04:36 EDT to 10:04:36 EDT

Scope:
- Split OCR parser handoff readiness, downstream readiness, summary math,
  line-sequence, review-signal, structure, and noise status getters out of
  `receipt_ocr_parser_handoff.dart` into
  `receipt_ocr_parser_handoff_status.dart`.
- Kept the core handoff class focused on the recognized line buckets, primary
  amount accessors, item counts, and role counts.
- Wired the new status part into `receipt_ocr_contract.dart`.
- Reduced `receipt_ocr_parser_handoff.dart` from 285 lines to 154 lines; the
  new status part is 134 lines.

Verification:
- Passed `dart format`, targeted `dart analyze`, focused OCR parser handoff,
  item-family, vendor-review, long-receipt diagnostics, and fuel-unknown tests.
- Passed `bash tool/receipt_fast_guard_gate.sh`, `git diff --check`, and the
  standalone `dart run tool/receipt_camera_footprint_audit.dart`; footprint
  remains `total_receipt_camera_ocr_source` at 1.76 MB.
