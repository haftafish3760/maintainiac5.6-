# Receipt Camera Cleanup Pass Log Archive - Pass 171

This archive keeps the active receipt camera cleanup log under the 500-line
project limit while preserving the full pass history.

## Pass 171 - 06:36:00 EDT to 06:39:27 EDT

Scope:
- Archived oldest active log entries `Pass 151` and `Pass 152` into focused
  archive files so the active cleanup log stays under the 500-line rule.
- Split parser privacy-event regressions out of
  `test/receipt_privacy_event_test.dart` into
  `test/receipt_parser_privacy_event_test.dart`.
- Kept OCR/privacy image review coverage in the original file and parser
  redaction/math/duplicate-overlap coverage in the new parser-focused test.

Failures fixed during this pass:
- First focused analyze failed because `PrivacySafeReceiptEvent` still comes
  from the parser import for the original OCR/image privacy tests, and the new
  parser test carried an unused capture-model import. Restored the needed
  import and removed the unused one before rerunning the focused check.

Verification:
- Focused retry passed: `dart format`, targeted `dart analyze`,
  `flutter test test/receipt_privacy_event_test.dart
  test/receipt_parser_privacy_event_test.dart -r compact`,
  focused source audit, and `git diff --check`.
- Touched files remain under 500 lines:
  `receipt_privacy_event_test.dart` 254 lines,
  `receipt_parser_privacy_event_test.dart` 228 lines,
  active cleanup log 447 lines before this entry, and pass archives below
  40 lines each.
