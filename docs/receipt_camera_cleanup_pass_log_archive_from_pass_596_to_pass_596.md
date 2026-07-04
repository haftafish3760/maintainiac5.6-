# Receipt Camera Cleanup Pass Log Archive - Pass 596

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active
cleanup pass log under the project line-count cap.

## Pass 596 - 20:46:21 EDT to 20:50:14 EDT

Scope:
- Removed tap-focus as a default receipt-camera behavior so continuous
  autofocus and readability guidance are the primary camera path.
- Changed shared camera settings plus Android and iOS native fallback defaults
  so `tapFocusEnabled` is false unless explicitly enabled by settings.
- Removed the standard camera-shell "Tap text to focus" chip and replaced it
  with continuous-focus/readability copy through "Auto sharpness".
- Updated native diagnostics policy defaults from focus-assist-first wording to
  continuous-focus/readability-first wording.
- Recorded `BUG-RECEIPT-0117` under `camera_capture_quality`.

Verification:
- Fixed stale QA expectations that still counted tap-focus as a required
  default native control.
- Passed targeted Dart format/analyzer for the shared camera contract/shell and
  native bridge source-contract regressions.
- Passed focused Flutter regressions for the native camera contract/session,
  shell, Android/iOS bridge defaults, coverage contract, and native UI health.
- Passed cleanup log gate, doc-size gate, source audit, and whitespace check.
