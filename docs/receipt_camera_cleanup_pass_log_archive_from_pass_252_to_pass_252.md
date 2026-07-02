# Receipt Camera Cleanup Pass Log Archive - Pass 252

Archived from `receipt_camera_cleanup_pass_log.md` to keep the active log under
the 500-line source/documentation guardrail.

## Pass 252 - 08:49:00 EDT to 08:53:34 EDT

Scope:
- Split QA check construction out of `receipt_qa_scoring.dart` into
  `receipt_qa_scoring_checks.dart`.
- Kept issue-code collection and final fixture report construction in the
  original scoring file while moving dimension/name/pass check generation for
  OCR text, production parser, fuel, maintenance, business/personal, privacy,
  and device-storage readiness into the new QA scoring checks part.
- Reduced `receipt_qa_scoring.dart` from 375 lines to 180 lines; the new checks
  part is 230 lines.

Failures fixed during this pass:
- First focused QA-runner compile failed because the new part used the wrong
  maintenance hint type name. Replaced `ExpenseMaintenanceHint` with
  `ExpenseReceiptMaintenanceHint` and reran the same focused verification.

Verification:
- Rerun passed `dart format` for the touched QA runner/scoring files.
- Rerun passed targeted `dart analyze` for `tool/receipt_qa_runner.dart` and
  `test/receipt_qa_runner_contract_test.dart`.
- Rerun passed `dart run tool/receipt_qa_runner.dart --json --fail-under=0.0`.
- Rerun passed focused `flutter test test/receipt_qa_runner_contract_test.dart
  -r compact` and `git diff --check` for the touched QA files.
