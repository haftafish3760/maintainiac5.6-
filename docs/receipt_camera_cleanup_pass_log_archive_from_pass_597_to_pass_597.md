# Receipt Camera Cleanup Pass Log Archive - Pass 597

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active
cleanup pass log under the project line-count cap.

## Pass 597 - 20:50:44 EDT to 20:51:48 EDT

Scope:
- Hardened Android saved-photo auto-capture cooldown so successful captures use
  the configured `autoCaptureCooldownMs` instead of a hard-coded 2600ms delay.
- Hardened iOS saved-photo auto-capture cooldown with the same session-driven
  behavior.
- Added Android and iOS source-contract regressions rejecting hard-coded
  saved-photo cooldowns.
- Recorded `BUG-RECEIPT-0118` under `native_bridge`.

Verification:
- Passed targeted Dart format/analyzer for Android and iOS native auto-capture
  source-contract regressions.
- Passed focused Flutter Android native auto-capture regression.
- Passed focused Flutter iOS native settings/close regression separately for
  explicit evidence.
- Passed cleanup log gate, doc-size gate, source audit, and whitespace check.
