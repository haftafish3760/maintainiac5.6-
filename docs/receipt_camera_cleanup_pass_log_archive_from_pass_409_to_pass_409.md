# Receipt Camera Cleanup Pass Log Archive - Pass 409

This archive keeps older receipt camera cleanup passes out of the active log so
each log file stays under the 500-line rule.

## Pass 409 - 13:15:17 EDT to 13:17:07 EDT

Scope:
- Tightened `tool/receipt_camera_footprint_audit.dart` so PDF receipt
  import/viewer helpers are excluded from the camera/OCR source total.
- Added machine-readable `excludedPathFragments` evidence and updated
  `receipt_camera_footprint_audit_test.dart` to require the PDF exclusion.

Why:
- The camera/OCR footprint should not count PDF import/viewer code when reporting
  the native receipt camera/OCR pipeline size.

Verification:
- Passed targeted `dart analyze` for the footprint audit and test.
- Passed focused `flutter test test/receipt_camera_footprint_audit_test.dart
  -r compact`.
- Passed updated `dart run tool/receipt_camera_footprint_audit.dart`.
- Passed `bash tool/receipt_fast_guard_gate.sh` and `git diff --check`.
- Corrected footprint is now `total_receipt_camera_ocr_source` at 1.68 MB.
