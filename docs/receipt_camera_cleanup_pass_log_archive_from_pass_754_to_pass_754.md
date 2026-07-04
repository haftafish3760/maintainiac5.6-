# Receipt Camera Cleanup Pass Log Archive - Pass 754

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active
cleanup log under the project line-count cap.

## Pass 754 - 04:03:12 EDT to active cleanup

Scope:
- Hardened Android and iOS live readability so non-finite brightness, motion, or
  shadow samples cannot fall through to `lighting_ok`.
- Added explicit `readability_unknown` diagnostics for malformed native live
  quality samples while leaving manual capture available.
- Added Android/iOS source regressions for non-finite live readability inputs.
- Recorded `BUG-RECEIPT-0242` under `camera_capture_quality`.
- Archived Pass 727 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for native readability regressions.
- Passed focused Android/iOS native analysis exposure regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
