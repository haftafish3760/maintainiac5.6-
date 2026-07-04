# Receipt Camera Cleanup Pass Log Archive - Pass 594

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active pass
log under the project line-count cap.

## Pass 594 - 20:41:22 EDT to 20:42:20 EDT

Scope:
- Hardened Android native auto-capture session parsing so blocked or
  unavailable auto-capture keeps `requiredStableFrames` and cooldown diagnostics
  at zero instead of clamping them back to runtime minimums.
- Hardened iOS native auto-capture session parsing with the same zero-when-
  blocked threshold behavior.
- Added Android and iOS source-contract regressions for honest blocked
  auto-capture threshold diagnostics.
- Recorded `BUG-RECEIPT-0115` under `native_bridge`.

Verification:
- Passed targeted Dart format/analyzer for native auto-capture source-contract
  regressions.
- Passed focused Flutter Android and iOS native auto-capture/settings
  regressions.
