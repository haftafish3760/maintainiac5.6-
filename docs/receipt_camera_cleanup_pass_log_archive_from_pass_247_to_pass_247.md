# Receipt Camera Cleanup Pass Log Archive - Pass 247

Archived from the active receipt camera cleanup pass log so the active file
stays under the 500-line rule.

## Pass 247 - 08:43:39 EDT to 08:44:50 EDT

Scope:
- Split PDF inspector header reads, sampled byte reads, range reads, header
  offset detection, and sampled-byte holder out of `receipt_pdf_inspector.dart`
  into `receipt_pdf_inspector_bytes.dart`.
- Kept the public inspector, risk-flag detection, document-signal detection,
  page estimation, and warning/status composition in the original inspector.
- Updated `receipt_camera_io_guard.dart` so safe PDF inspector file reads are
  allowed at the new bytes-part path.
- Reduced `receipt_pdf_inspector.dart` from 366 lines to 304 lines; the new
  bytes helper part is 64 lines.

Verification:
- Passed `dart format` for the touched inspector and guard files.
- Passed targeted `dart analyze` for the PDF inspector and camera I/O guard.
- Passed focused `flutter test` for `receipt_pdf_hardening_test.dart`,
  `receipt_pdf_inspector_security_flags_test.dart`,
  `receipt_pdf_inspector_edge_cases_test.dart`, and
  `receipt_ocr_service_pdf_security_test.dart`.
- Passed `dart run tool/receipt_camera_io_guard.dart` and `git diff --check`
  for the touched files.
