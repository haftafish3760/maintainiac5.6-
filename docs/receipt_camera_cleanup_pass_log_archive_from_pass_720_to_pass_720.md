# Receipt Camera Cleanup Pass Log Archive - Pass 720

This file archives Pass 720 from `docs/receipt_camera_cleanup_pass_log.md` to
keep the active cleanup log under the 500-line limit enforced by
`tool/receipt_cleanup_log_gate.sh`.

## Pass 720 - 02:45:00 EDT to active cleanup

Scope:
- Tightened native byte-budget validation so the service enforces the largest
  positive value from `photoByteSize` and `totalCapturedByteSize`.
- Added a regression where per-photo bytes are small but total captured bytes
  exceed the session budget.
- Recorded `BUG-RECEIPT-0208` under `source_preservation`.
- Archived Pass 693 from the active cleanup log to keep the doc under cap.

Verification:
- Passed Dart format/analyzer for native total-byte validation.
- Passed focused native path validation regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
