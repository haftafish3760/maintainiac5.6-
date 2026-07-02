# Receipt Camera Cleanup Pass Log Archive - Pass 243

Archived from the active receipt camera cleanup pass log so the active file
stays under the 500-line rule.

## Pass 243 - 08:37:33 EDT to 08:38:31 EDT

Scope:
- Split recovery-safety and privacy assertions out of
  `receipt_native_capture_staging_manifest_expectations.dart` into
  `receipt_native_capture_staging_recovery_safety_expectations.dart`.
- Kept the accepted native capture manifest helper focused on capture
  diagnostics while preserving a delegated check for interruption recovery,
  OCR original-source policy, staged-photo cleanup, and no receipt/customer
  content leakage.
- Reduced the manifest expectations helper from 421 lines to 357 lines; the
  new recovery-safety helper is 71 lines.

Verification:
- Passed `dart format` for both touched helper files.
- Passed targeted `dart analyze` for the helper files and
  `receipt_native_capture_staging_test.dart`.
- Passed focused `flutter test test/receipt_native_capture_staging_test.dart
  -r compact`.
- Passed `git diff --check` for the touched helper/test files.
