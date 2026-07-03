# Receipt Camera Cleanup Pass Log Archive - Pass 462

## Pass 462 - 16:38:45 EDT to 16:40:46 EDT

Scope:
- Strengthened the one-command OCR/camera pipeline failure workflow.
- Added `tool/receipt_pipeline_failure_to_regression.dart`, which reads a
  failed pipeline run's `failure_report.txt` and creates a regression task under
  `/tmp/maintainiac_receipt_ocr_pipeline/<run>/regression_tasks/`.
- Wired `tool/receipt_ocr_pipeline_run.sh` so a failed phase writes the normal
  failure report and then generates the regression task automatically.
- Expanded `tool/receipt_quiet_batch_policy_gate.dart` so the pipeline must
  include the failure-to-regression generator.
- Updated `docs/receipt_ocr_pipeline_blueprint.json` and the QA standard with
  the failure-to-regression command and policy.

Verification:
- Passed Dart format for the new generator and policy gate.
- Passed `bash -n tool/receipt_ocr_pipeline_run.sh`.
- Passed JSON parse for `docs/receipt_ocr_pipeline_blueprint.json`.
- Passed `dart analyze tool/receipt_pipeline_failure_to_regression.dart
  tool/receipt_quiet_batch_policy_gate.dart`.
- Passed `dart run tool/receipt_quiet_batch_policy_gate.dart`.
- Passed `bash tool/receipt_cleanup_log_gate.sh` and targeted
  `git diff --check`.
- Did not start the OCR pipeline, Flutter, or the full receipt QA runner during
  this pass.
