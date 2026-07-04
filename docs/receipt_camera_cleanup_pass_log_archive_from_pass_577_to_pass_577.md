# Receipt Camera Cleanup Pass Log Archive - Pass 577

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the live pass
log under the project line-count cap.

## Pass 577 - 09:44:18 EDT to 09:51:14 EDT

Scope:
- Hardened manual receipt crop processing so zero-size or non-finite display
  and crop rectangles are rejected before pixel scaling.
- Added regression coverage proving unusable crop bounds fail with a stable
  crop-bound error instead of creating an unsafe derived receipt image.
- Recorded `BUG-RECEIPT-0093` under `camera_capture_quality`.
- Archived Passes 549 and 544 out of the live cleanup log to keep the active
  log under the project line-count cap.

Verification:
- Fixed the first targeted analyzer failure by importing Flutter material for
  `Rect` in the crop-bound regression test.
- Passed targeted Dart format/analyzer for the image processor and focused
  crop-bound regression coverage.
- Passed focused Flutter regression
  `test/receipt_image_rotation_test.dart --plain-name "receipt image processor
  rejects unusable crop bounds"`.
