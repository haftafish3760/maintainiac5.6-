# Receipt Camera Cleanup Pass Log Archive - Pass 431

Archived from the active cleanup pass log so
`docs/receipt_camera_cleanup_pass_log.md` stays under the 500-line cap.

## Pass 431 - 14:16:33 EDT to 14:25:29 EDT

Scope:
- Stayed on pure Dart receipt QA depth for long-receipt stitching and parser
  diagnostic coverage.
- Added fixture-level `expectedParserTaskCounts` checks so QA can assert parser
  diagnostic task families, not only totals and line values.
- Added a stitched-overlap long-receipt fixture that requires duplicate-text and
  probable-overlap diagnostics while still preserving subtotal, tax, total, and
  merchant normalization.
- Updated the QA runner contract so the long-receipt pack now expects four
  fixtures, including the stitched-overlap diagnostic case.

Verification:
- Passed targeted format, analyzer, and diff-check batch for the edited QA
  runner, long-receipt fixture, scoring review, and contract test files.
- Passed pure Dart `long_receipt` QA at 4 fixtures, 84 checks, 84 passed, 0
  failed, score 1.0.
- Passed pure Dart all-pack QA at 17 fixtures, 464 checks, 464 passed, 0 failed,
  score 1.0.
- Passed `flutter test test/receipt_qa_runner_contract_test.dart -r compact`
  with 10 tests passing.
