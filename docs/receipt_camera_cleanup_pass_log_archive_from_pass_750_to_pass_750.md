# Receipt Camera Cleanup Pass Log Archive - Pass 750

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active
cleanup log under the project line-count cap.

## Pass 750 - 03:55:19 EDT to active cleanup

Scope:
- Hardened native live-to-saved luma parity diagnostics so non-finite preview or
  saved-photo brightness values cannot be bucketed as healthy preview-match
  evidence.
- Added Android/iOS source regressions proving non-finite live/saved luma and
  non-finite parity deltas resolve to `unknown`.
- Recorded `BUG-RECEIPT-0238` under `camera_capture_quality`.
- Archived Pass 725 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for native live-to-saved parity
  regressions.
- Passed focused Android/iOS native bridge quality regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
