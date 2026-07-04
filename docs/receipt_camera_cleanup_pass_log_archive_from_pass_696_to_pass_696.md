# Receipt Camera Cleanup Pass Log Archive - Pass 696

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the project line-count cap.

## Pass 696 - 01:18:00 EDT to active cleanup

Scope:
- Removed stale active native-camera service spec wording that still listed tap
  focus as a camera hardware control.
- Reworded native service current-state guidance around continuous
  focus/readability instead of generic focus adjustment.
- Extended the active camera docs focus-policy regression to cover the native
  service spec and reject tap focus as an active control list item.
- Recorded `BUG-RECEIPT-0183` under `camera_capture_quality`.
- Archived Pass 636 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart analyzer for the active camera docs focus-policy test.
- Passed focused Flutter active camera docs focus-policy regression.
