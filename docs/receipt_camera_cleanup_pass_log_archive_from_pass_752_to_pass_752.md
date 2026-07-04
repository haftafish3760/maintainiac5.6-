# Receipt Camera Cleanup Pass Log Archive - Pass 752

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active
cleanup log under the project line-count cap.

## Pass 752 - 03:59:57 EDT to active cleanup

Scope:
- Hardened Android and iOS live receipt framing so malformed or non-finite
  bounds cannot appear as `framing_ok`.
- Added explicit invalid-bounds diagnostics for frame guidance and perspective
  readiness while preserving `receipt_not_found` for genuinely missing frames.
- Added Android/iOS source regressions for malformed live framing bounds.
- Recorded `BUG-RECEIPT-0240` under `camera_capture_quality`.
- Archived Pass 726 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for native framing regressions.
- Passed focused Android/iOS native analysis exposure regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
