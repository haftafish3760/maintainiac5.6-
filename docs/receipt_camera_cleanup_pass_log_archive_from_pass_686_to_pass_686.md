# Receipt Camera Cleanup Pass Log Archive - Pass 686

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the project line-count cap.

## Pass 686 - 00:41:29 EDT to active cleanup

Scope:
- Capped impossible OCR receipt line and section numbers before they can appear
  in proof labels, redaction anchors, serialized expense maps, parser handoff
  labels, or privacy-safe handoff contracts.
- Added regression coverage for huge malformed OCR row/section metadata so this
  class of line-numbering bug cannot return quietly.
- Split receipt line privacy/proof tests into
  `test/expense_receipt_line_privacy_test.dart` to keep the original receipt
  line record test under the project line-count cap.
- Fixed receipt bug ledger gate drift so existing barcode/QR and camera
  review-state regression categories remain accepted by the permanent gate.
- Recorded `BUG-RECEIPT-0172` under `receipt_line_numbering`.
- Recorded `BUG-RECEIPT-0173` under `qa_harness`.
- Archived Pass 615 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for receipt line and parser handoff
  files.
- Passed focused Flutter receipt line, receipt line privacy, and OCR parser
  handoff regressions.
- First ledger gate run failed on stale allowed categories; fixed and reran the
  gate before milestone push.
