## Pass 144 - 05:53:38 EDT to 05:56:05 EDT

Scope:
- Hardened the PDF OCR raster path so attachment byte reads after preflight use
  an explicit safe helper instead of a raw `File(attachment.path).readAsBytes()`
  call.
- Added a controlled internal exception for missing, empty, or unreadable PDF
  raster bytes so the OCR service keeps the existing skipped-PDF warning path.
- Added a source-contract regression proving the OCR service keeps the safe
  PDF raster byte helper and does not reintroduce the raw attachment read.

Failures fixed during this pass:
- The first focused verification surfaced an analyzer info for an unnecessary
  `dart:typed_data` import. The import was removed and the focused gate was
  rerun before accepting the pass.

Verification:
- Focused PDF raster-read verification passed:
  `dart format`, `dart analyze`, `flutter test
  test/receipt_ocr_service_read_warnings_test.dart -r compact`,
  `dart run tool/maintainiac_source_audit.dart --include-tests`, and
  `git diff --check` for the OCR service and warning test.
- `test/receipt_ocr_service_read_warnings_test.dart` passed all 6 tests,
  including the new safe PDF raster byte read source-contract regression.
- Touched files remain under 500 lines:
  `receipt_ocr_service.dart` 368 lines and
  `receipt_ocr_service_read_warnings_test.dart` 319 lines.

Known follow-up:
- `receipt_pdf_inspector.dart` and PDF viewer paths still have direct file-read
  paths that need separate inspection before deciding whether to change them.
