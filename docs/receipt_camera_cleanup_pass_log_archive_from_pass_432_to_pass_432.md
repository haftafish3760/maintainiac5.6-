# Receipt Camera Cleanup Pass Log Archive - Pass 432

Archived from the active cleanup pass log so
`docs/receipt_camera_cleanup_pass_log.md` stays under the 500-line cap.

## Pass 432 - 14:26:00 EDT to 14:30:29 EDT

Scope:
- Stayed on quiet, non-interactive receipt QA execution.
- Added `--summary-json` to `tool/receipt_qa_runner.dart` so gates can emit
  compact counts, scores, blockers, and failed fixture summaries without the
  full per-check fixture payload.
- Added contract coverage proving summary output excludes the full `fixtures`
  payload while preserving long-receipt counts and blocker fields.

Verification:
- Passed targeted format, analyzer, and diff-check batch for the QA runner,
  report model, and contract test.
- Passed `dart run tool/receipt_qa_runner.dart --pack=long_receipt
  --fail-under=1.0 --summary-json`: 4 fixtures, 84 checks, 84 passed, 0 failed,
  0 blockers, no full `fixtures` key.
- Passed `flutter test test/receipt_qa_runner_contract_test.dart -r compact`.
