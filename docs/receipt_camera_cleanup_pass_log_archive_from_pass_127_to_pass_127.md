# Receipt Camera Cleanup Pass Log Archive - Pass 127

This archive preserves older receipt camera cleanup pass evidence moved out of
the active log to keep every pass-log file under the 500-line rule.

## Pass 127 - 04:33:30 EDT to 04:37:27 EDT

Scope:
- Split long copy/regex lines across shared receipt capture, OCR parser signal,
  PDF inspection, photo coverage, photo review, and Android native camera close
  files.
- Extracted repeated receipt-review guidance suffixes into local variables in
  `expense_receipt_parse_review_guidance.dart`.
- Reduced the broad receipt-scope long-line diagnostic backlog from 16 files to
  6 files.

Verification:
- `dart run tool/maintainiac_source_audit.dart` over the 10 touched files with
  `--max-line-length=220` passed.
- `dart analyze` over the nine touched Dart files passed with no issues.
- `flutter test test/receipt_qa_runner_contract_test.dart -r compact` passed.
- `bash tool/android_receipt_camera_compile_gate.sh` passed; Gradle reported
  `BUILD SUCCESSFUL`.
- `git diff --check` passed.
- Touched files remain under 500 lines and under 220 characters per line,
  including `ReceiptCameraCaptureClose.kt` at 305 lines and
  `expense_receipt_parse_review_guidance.dart` at 406 lines.

Known follow-up:
- The long-line backlog is now limited to the giant telemetry snapshot builder
  and five test files. The telemetry builder still requires structural
  decomposition rather than blind formatting.
