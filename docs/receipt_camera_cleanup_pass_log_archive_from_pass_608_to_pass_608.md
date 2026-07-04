# Receipt Camera Cleanup Pass Log Archive - Pass 608

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active pass
log under the project line-count cap.

## Pass 608 - 21:15:24 EDT to active cleanup

Scope:
- Retired tap-to-focus from the user-facing native receipt camera settings so
  continuous autofocus and readability guidance remain the primary camera
  behavior.
- Hardened the session config so legacy `tapFocusEnabled` requests cannot
  enable focus-assist tags or native tap-focus arguments.
- Hardened the shared camera shell so preview taps do not route to focus
  callbacks even if a legacy caller passes tap-focus settings.
- Recorded `BUG-RECEIPT-0129` under `camera_capture_quality`.
- Archived Pass 588 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format for the touched camera settings, session, shell,
  and regression tests.
- Passed targeted analyzer for native camera contract and shell sources/tests.
- Passed focused Flutter regressions for native camera contract and shell.
