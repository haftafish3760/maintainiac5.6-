# Receipt Camera Cleanup Pass Log Archive - Pass 591

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active pass
log under the project line-count cap.

## Pass 591 - 20:32:44 EDT to 20:36:37 EDT

Scope:
- Reframed the receipt camera focus contract so continuous autofocus is the
  primary capture behavior and tap-to-focus is only optional focus assist.
- Added shared focus/readability policy diagnostics for continuous focus,
  brightness assist, sharpness guidance, and live readability guidance.
- Updated user-facing camera quality guidance to tell users to hold steady and
  let the camera refocus before using focus assist.
- Added `focus_assist` as a native control contract alias while preserving
  legacy `tapFocus...` bridge diagnostics for compatibility.
- Recorded `BUG-RECEIPT-0114` under `camera_capture_quality`.

Verification:
- Fixed one focused regression mismatch for devices without focus-assist
  support and one health-tag alias mismatch before proceeding.
- Passed targeted Dart analyzer for the edited receipt camera contract,
  guidance, diagnostics, and regression tests.
- Passed focused Flutter regressions for native camera contract/session,
  privacy diagnostics, assistance policy diagnostics, quality guidance, and
  native UI health.
