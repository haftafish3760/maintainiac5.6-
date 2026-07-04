# Receipt Camera Cleanup Pass Log Archive - Pass 749

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active
cleanup log under the project line-count cap.

## Pass 749 - 03:52:44 EDT to active cleanup

Scope:
- Hardened native saved-photo bottom/top luma diagnostics so missing or
  non-finite values are bucketed as `unknown` instead of appearing as
  top/bottom brightness-close evidence.
- Added Android/iOS source regressions proving invalid bottom/top luma and
  non-finite delta values cannot look healthy.
- Recorded `BUG-RECEIPT-0237` under `camera_capture_quality`.
- Archived Pass 724 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for native quality source regressions.
- Passed focused Android/iOS native bridge quality regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
