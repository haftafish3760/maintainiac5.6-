# Receipt Camera Cleanup Pass Log Archive - Pass 483

Archived from the live cleanup log to keep the active receipt camera pass log
under the project line-count cap.

## Pass 483 - 23:57:00 EDT to 00:02:30 EDT

Scope:
- Extended the permanent receipt QA runner so synthetic fixtures can assert
  parsed line review modes and visible receipt line number labels.
- Pinned contractor supply fixtures to detailed-line review mode and source-line
  labels, protecting the later inventory/job-proof workflow that needs stable
  receipt line references.
- Added QA-runner contract coverage so contractor supply fixtures must keep
  line review mode and line label checks.
- Recorded `BUG-RECEIPT-0002` after a fixture expectation mismatch proved that
  item labels preserve source receipt rows, not compact item indexes.
- Archived Pass 462 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format and analyzer for the receipt QA runner and
  contract test.
- Passed `dart run tool/receipt_qa_runner.dart --pack=contractor_supply
  --fail-under=1.0 --summary-json` after correcting the fixture expectation.
- Passed focused Flutter contract case
  `test/receipt_qa_runner_contract_test.dart --plain-name "pure Dart receipt QA
  runner reports required dimensions and fixtures"`.
- The first contractor fixture run correctly failed before the expectation fix,
  and that fixture-generation bug is now logged as `BUG-RECEIPT-0002`.
