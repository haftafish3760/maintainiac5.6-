## Pass 141 - 05:45:00 EDT to 05:50:23 EDT

Scope:
- Hardened the photo-review crop preview loader so missing, empty, corrupt, and
  wrong-file-type receipt image bytes are handled by the shared safe decoder
  instead of raw UI-layer image decoding.
- Added a public `ReceiptImageProcessor.decodeReceiptImageBytes` helper so UI
  paths can reuse the same no-throw decode behavior as OCR source prep.
- Added a decoder regression covering the unreadable-byte family and tightened
  the photo-review async lifecycle source contract so crop loading cannot
  reintroduce raw `img.decodeImage(bytes)` calls.

Failures fixed during this pass:
- The first focused verification failed analyzer on stale imports in
  `receipt_photo_review_screen.dart`; the imports were removed and the focused
  verification was rerun before accepting the pass.

Verification:
- Focused photo-edit decode verification passed:
  `dart format`, `dart analyze`, `flutter test
  test/receipt_image_ocr_source_guard_test.dart
  test/receipt_photo_review_async_lifecycle_test.dart -r compact`,
  `dart run tool/maintainiac_source_audit.dart --include-tests`, and
  `git diff --check` for the touched photo-review/image-processor files.
- The focused test run passed all 4 tests, including the new unreadable-byte
  decoder family regression.
- Touched files remain under 500 lines:
  `receipt_image_processor.dart` 413 lines,
  `receipt_photo_review_screen.dart` 281 lines,
  `receipt_photo_review_image_edit_actions.dart` 246 lines,
  `receipt_image_ocr_source_guard_test.dart` 128 lines, and
  `receipt_photo_review_async_lifecycle_test.dart` 387 lines.

Known follow-up:
- `ReceiptImageProcessor.rotateFile` still has a direct file read before decode
  and should be moved onto the shared safe read path with a focused regression.
