# Receipt Camera Cleanup Pass Log Archive - Pass 210

Archived from `receipt_camera_cleanup_pass_log.md` to keep the active log under
the 500-line project limit.

## Pass 210 - 07:41:51 EDT to 07:43:48 EDT

Scope:
- Archived active Pass 189 into
  `receipt_camera_cleanup_pass_log_archive_from_pass_189_to_pass_189.md` so the
  active cleanup log stays under the 500-line rule.
- Split hybrid travel-mart mixed-family/tender separation coverage out of
  `test/receipt_ocr_service_line_signals_test.dart` into
  `test/receipt_ocr_service_hybrid_travel_mart_test.dart`.
- Kept address/contact metadata suppression plus generic fuel, grocery, and
  hardware local parser role coverage in the original line-signals test.
- Removed unused temp-directory and path-provider mock setup from the original
  pure OCR contract test.

Verification:
- Focused verification passed on the first run: `dart format`, targeted
  `dart analyze`, `flutter test test/receipt_ocr_service_line_signals_test.dart
  test/receipt_ocr_service_hybrid_travel_mart_test.dart -r compact`, and
  `git diff --check`.
- Touched files remain under 500 lines:
  `receipt_ocr_service_line_signals_test.dart` 258 lines and
  `receipt_ocr_service_hybrid_travel_mart_test.dart` 125 lines.
