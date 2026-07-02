# Receipt Camera Cleanup Pass Log Archive - Pass 237

Archived from the active receipt camera cleanup pass log so the active file
stays under the 500-line rule.

## Pass 237 - 08:28:00 EDT to 08:28:46 EDT

Scope:
- Split low-level PDF inspector active-content, active-action, substring, and
  encryption risk-flag coverage out of `receipt_pdf_hardening_test.dart` into
  `receipt_pdf_inspector_security_flags_test.dart`.
- Kept the main PDF hardening file focused on size, page-count, proof handling,
  non-receipt fit warnings, scanned-PDF warnings, EOF handling, and blocked
  disposition behavior.
- Reduced `receipt_pdf_hardening_test.dart` from 368 lines to 257 lines; the
  new inspector security flags test is 118 lines.

Verification:
- Passed `dart format` for both touched test files.
- Passed targeted `dart analyze` for both touched test files.
- Passed focused `flutter test` for `receipt_pdf_hardening_test.dart` and
  `receipt_pdf_inspector_security_flags_test.dart`.
- Passed `git diff --check` for both touched test files.
