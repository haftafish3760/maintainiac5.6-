# Receipt Camera Cleanup Pass Log Archive - Pass 722

This file archives Pass 722 from `docs/receipt_camera_cleanup_pass_log.md` to
keep the active cleanup log under the 500-line limit enforced by
`tool/receipt_cleanup_log_gate.sh`.

## Pass 722 - 02:51:00 EDT to active cleanup

Scope:
- Fixed native over-budget capture handling so existing sections are returned
  only when a close-after-capture flow was actually pending.
- Kept add-photo/retake flows on the camera after an over-budget section so the
  user can retry instead of being forced into review with older sections.
- Added Android/iOS bridge source regressions for the
  `shouldReturnExistingSections` guard.
- Recorded `BUG-RECEIPT-0211` under `multi_photo_ordering`.
- Archived Pass 695 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused Android/iOS bridge
  regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
