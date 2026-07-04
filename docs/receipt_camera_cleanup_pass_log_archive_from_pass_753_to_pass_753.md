# Receipt Camera Cleanup Pass Log Archive - Pass 753

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active
cleanup log under the project line-count cap.

## Pass 753 - 04:02:09 EDT to active cleanup

Scope:
- Hardened Android and iOS optional auto-capture readiness so malformed live
  framing bounds cannot count as edge-ready capture evidence.
- Reused the native usable-bounds guard added in Pass 752 for auto-capture
  decisions, keeping manual shutter behavior unaffected.
- Added Android/iOS auto-capture source regressions for the usable-bounds guard.
- Recorded `BUG-RECEIPT-0241` under `camera_capture_quality`.

Verification:
- Passed targeted Dart format/analyzer for native auto-capture regressions.
- Passed focused Android/iOS native auto-capture bridge regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
