# Receipt Camera Cleanup Pass Log Archive - Pass 135

This archive preserves older receipt camera cleanup pass evidence moved out of
the active log to keep every pass-log file under the 500-line rule.

## Pass 135 - 04:47:00 EDT to 04:59:38 EDT

Scope:
- Hardened `tool/receipt_qa_runner.dart` so command-line QA fails on weak
  fixture, pack, or dimension scores instead of only checking the average
  receipt score.
- Added actionable blocker text that names the exact overall, pack, dimension,
  or fixture score below the configured `--fail-under` threshold.
- Added a receipt QA contract test proving the runner exits nonzero and emits
  those blockers when a threshold is impossible to satisfy.

Failures fixed during this pass:
- The first new Flutter contract test timed out at the default 30 seconds
  because `dart run` invokes build hooks on this machine. The standalone probe
  proved the runner behavior, then the test was corrected with a 2-minute
  timeout and rerun.
- Two shell probes had quoting/variable-name mistakes while checking the
  impossible-threshold output. Those were command errors only, not app/source
  failures, and the safe probe confirmed the intended nonzero runner exit.

Verification:
- `dart analyze tool/receipt_qa_runner.dart
  test/receipt_qa_runner_contract_test.dart` passed with no issues.
- `dart run tool/maintainiac_source_audit.dart --include-tests
  tool/receipt_qa_runner.dart test/receipt_qa_runner_contract_test.dart`
  passed with both files under 500 lines and `maxLineLength=220`.
- `dart run tool/receipt_qa_runner.dart --fail-under=0.90 --json` passed with
  14 fixtures, 100.0% score, and no blockers.
- `dart run tool/receipt_qa_runner.dart --fail-under=1.01 --json` exited
  nonzero and reported overall, pack, dimension, and fixture blockers.
- `flutter test test/receipt_qa_runner_contract_test.dart -r compact` passed
  all 9 receipt QA contract tests.
- `bash tool/receipt_quality_gate.sh` passed against current source:
  analyzer, source audit, pure Dart receipt QA, contract tests, Android
  receipt camera compile, iOS/native build, OCR service tests, and processing
  contract tests all completed successfully.
- `git diff --check -- tool/receipt_qa_runner.dart
  test/receipt_qa_runner_contract_test.dart` passed.
- Touched files remain under the 500-line rule:
  `receipt_qa_runner.dart` 345 lines and
  `receipt_qa_runner_contract_test.dart` 277 lines.

Known follow-up:
- Continue expanding the fixture corpus toward more real-world receipt
  variance, but keep the runner itself strict so weak packs or dimensions
  cannot hide behind a strong average.
