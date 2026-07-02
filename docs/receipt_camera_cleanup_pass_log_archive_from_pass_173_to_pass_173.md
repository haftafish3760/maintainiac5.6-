# Receipt Camera Cleanup Pass Log Archive - Pass 173

Archived from the active cleanup log to keep
`docs/receipt_camera_cleanup_pass_log.md` under the 500-line file-size rule.

## Pass 173 - 06:40:58 EDT to 06:43:24 EDT

Scope:
- Archived active `Pass 153` and `Pass 155` into focused archive files so the
  active cleanup log stays under the 500-line rule after concurrent entries.
- Split OCR handoff, saved-line review, split-use controls, photo navigation,
  and telemetry source-contract coverage out of
  `test/expense_receipt_assisted_review_overlap_native_test.dart` into
  `test/expense_receipt_assisted_review_handoff_native_test.dart`.
- Kept overlap/parser/native diagnostic coverage in the original test file.

Verification:
- Focused verification passed on the first run: `dart format`, targeted
  `dart analyze`, `flutter test
  test/expense_receipt_assisted_review_overlap_native_test.dart
  test/expense_receipt_assisted_review_handoff_native_test.dart -r compact`,
  focused source audit, and `git diff --check`.
- Touched files remain under 500 lines:
  `expense_receipt_assisted_review_overlap_native_test.dart` 252 lines,
  `expense_receipt_assisted_review_handoff_native_test.dart` 241 lines,
  active cleanup log 477 lines before final archiving, and new pass archives
  25 and 30 lines.
