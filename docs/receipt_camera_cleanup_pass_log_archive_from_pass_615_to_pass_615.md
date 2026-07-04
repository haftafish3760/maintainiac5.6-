# Receipt Camera Cleanup Pass Log Archive - Pass 615

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the project line cap.

## Pass 615 - 21:35:42 EDT to active cleanup

Scope:
- Hardened capture readiness so optional auto capture cannot fire just because
  the frame is stable when the photo quality still needs manual review.
- Added `manual_only_quality_review` for soft focus, low contrast, dim
  readable frames, and other noncritical review-needed receipt photos.
- Kept manual shutter available in those cases so the user remains in control.
- Added regression coverage for soft, low-contrast, and dim review-needed
  receipt photos.
- Recorded `BUG-RECEIPT-0136` under `camera_capture_quality`.

Verification:
- Passed targeted Dart format/analyzer for receipt photo quality readiness.
- Passed focused Flutter receipt camera quality guidance regressions.
- Passed cleanup log, doc size, source audit, and diff whitespace gates.

