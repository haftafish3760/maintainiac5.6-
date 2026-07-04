# Receipt Camera Cleanup Pass Log Archive - Pass 697

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the project line-count cap.

## Pass 697 - 01:23:00 EDT to active cleanup

Scope:
- Removed stale active handoff wording that still said users can tap to focus
  during the production receipt camera flow.
- Replaced it with continuous autofocus/readability guidance plus pinch zoom,
  brightness/exposure, and torch controls where supported.
- Extended the active camera docs focus-policy regression to cover the long
  2026-07-03 receipt camera handoff and reject tap-to-focus flow wording.
- Recorded `BUG-RECEIPT-0184` under `camera_capture_quality`.
- Archived Pass 637 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart analyzer for the active camera docs focus-policy test.
- Passed focused Flutter active camera docs focus-policy regression.
