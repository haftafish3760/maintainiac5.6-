## Pass 223 - 08:02:00 EDT to 08:05:07 EDT

Scope:
- Archived active Pass 202 into
  `receipt_camera_cleanup_pass_log_archive_from_pass_202_to_pass_202.md` so the
  active cleanup log stays under the 500-line rule.
- Split the trade-heavy back half of the synthetic contractor receipt fixture
  pack out of `synthetic_receipt_fixture_pack_test.dart` into
  `synthetic_trade_receipt_fixture_pack.dart`.
- Kept the fixture count, average score, and average quality thresholds in the
  original test so the full 14-receipt pack is still scored together.
- Reduced `synthetic_receipt_fixture_pack_test.dart` from 469 lines to
  279 lines; the new helper fixture pack is 196 lines.

Verification:
- Passed: `dart format`, targeted `dart analyze`, focused `flutter test
  test/synthetic_receipt_fixture_pack_test.dart -r compact`, and
  `git diff --check` for the touched fixture files.
