# Receipt Camera Cleanup Pass Log Archive - Pass 758

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the project line cap while preserving pass history.

## Pass 758 - 04:08:20 EDT to active cleanup

Scope:
- Hardened Android and iOS pre-capture exposure prep so non-finite live
  brightness cannot trigger last-second exposure changes before saving a
  receipt photo.
- Kept malformed brightness on the existing `brightness_unknown` pre-capture
  skip path.
- Added Android/iOS native exposure source regressions for finite pre-capture
  brightness checks.
- Recorded `BUG-RECEIPT-0246` under `camera_capture_quality`.
- Archived Pass 730 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for pre-capture exposure regressions.
- Passed focused Android/iOS native analysis exposure regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
