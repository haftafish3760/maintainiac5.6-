## Pass 290 - 09:57:53 EDT to 09:57:53 EDT

Scope:
- Split receipt photo review scaffold/build rendering out of
  `receipt_photo_review_screen.dart` into `receipt_photo_review_build.dart`.
- Kept public widget setup, state fields, initial mode/selection logic,
  lifecycle disposal, async scheduling triggers, and the build entrypoint in
  the original screen file.
- Updated photo-review source readers so source-contract tests still cover the
  moved scaffold/body rendering.
- Reduced `receipt_photo_review_screen.dart` from 291 lines to 205 lines; the
  new build part is 94 lines.

Verification:
- Passed focused `flutter test` for photo-review controls layout, long-receipt
  guidance, async lifecycle, save lifecycle, and camera help.
- Passed source audit, `bash tool/receipt_fast_guard_gate.sh`, and `git diff
  --check`; footprint remains `total_receipt_camera_ocr_source` at 1.75 MB.
