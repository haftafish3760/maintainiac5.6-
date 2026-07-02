# Receipt Camera Cleanup Pass Log Archive - Pass 175

Archived from the active cleanup log to keep
`docs/receipt_camera_cleanup_pass_log.md` under the 500-line file-size rule.

## Pass 175 - 06:44:32 EDT to 06:47:10 EDT

Scope:
- Split storage, parser-pack, cloud fallback, and optional-download footprint
  policy coverage out of `test/receipt_assistance_policy_diagnostics_test.dart`
  into `test/receipt_assistance_footprint_policy_test.dart`.
- Kept hardware diagnostics, native camera controls, camera tier scaling, large
  photo review behavior, and low-storage local OCR decisioning in the original
  diagnostics test.
- Reduced the original diagnostics test from 477 lines to 174 lines; the new
  footprint policy test is 308 lines.

Verification:
- Focused verification passed on the first run: `dart format`, targeted
  `dart analyze`, `flutter test
  test/receipt_assistance_policy_diagnostics_test.dart
  test/receipt_assistance_footprint_policy_test.dart -r compact`,
  focused source audit, and `git diff --check`.
- Touched files remain under 500 lines and the source audit reported no files
  over the project limit.
