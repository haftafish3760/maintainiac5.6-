# Receipt Camera Cleanup Pass Log Archive - Pass 490

Archived out of `docs/receipt_camera_cleanup_pass_log.md` during Pass 503 to
keep the active cleanup log under the project line-count cap.

## Pass 490 - 00:14:10 EDT to 00:16:05 EDT

Scope:
- Hardened OCR parser line draft labels so multi-section receipt review can use
  source-first line labels when section/line metadata is available.
- Added `sourceFirstLineLabel` to local review and privacy-safe parser summary
  maps while keeping parser-index `lineLabel` intact.
- Recorded `BUG-RECEIPT-0009` under `receipt_line_numbering`.
- Archived Pass 468 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed `dart format --set-exit-if-changed` for the parser model and focused
  parser-handoff test.
- Passed targeted analyzer for the parser model, focused test, and bug ledger
  gate.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.
- Passed full focused `flutter test
  test/receipt_ocr_service_parser_handoff_structure_test.dart -r compact`.

