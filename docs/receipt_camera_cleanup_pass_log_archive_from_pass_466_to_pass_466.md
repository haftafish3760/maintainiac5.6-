# Receipt Camera Cleanup Pass Log Archive - Pass 466

## Pass 466 - 17:01:04 EDT to 17:06:54 EDT

Scope:
- Treated the shared receipt/camera/OCR pipeline as app-wide infrastructure for
  expenses first, with inventory/work supplies as downstream consumers, not as a
  one-off OCR text extractor.
- Fixed the quiet OCR pipeline launcher after repeated detached-run failures:
  generated runners now preserve command argument boundaries, prefer `screen`,
  restore the repo working directory, expose runner lifecycle metadata, and use
  a login-shell payload command that actually stays alive after Codex returns.
- Changed the OCR pipeline and quality-gate launchers to rewrite payload scripts
  into the quiet batch directory and execute those payloads through a quoted
  login-shell command.
- Hardened `tool/receipt_ocr_pipeline_run.sh` so each run clears stale phase
  logs/regression task files before writing the current summary.
- Updated the quiet-batch policy gate and focused contract test so the
  non-monitoring launcher behavior, copied payload execution, stale-log cleanup,
  and no-live-log workflow are permanent regression guards.

Failures fixed during this pass:
- Detached OCR pipeline runs were failing or going stale before meaningful QA
  because macOS/screen execution treated direct script paths and bad generated
  command quoting inconsistently.
- The pipeline phase directory could retain stale phase logs from earlier failed
  attempts, making failure triage ambiguous.
- The policy gate initially failed from unescaped Dart shell-string assertions;
  fixed those before restarting the pipeline.

Verification:
- Passed `bash -n` for the edited launcher and pipeline shell scripts.
- Passed `dart format`, `dart analyze tool/receipt_quiet_batch_policy_gate.dart`,
  and `dart run tool/receipt_quiet_batch_policy_gate.dart`.
- Passed `flutter test test/receipt_quiet_batch_policy_gate_contract_test.dart
  -r compact`.
- Passed targeted `git diff --check` and line-count checks on edited launcher,
  policy, pipeline, and focused test files.
- Restarted `receipt_ocr_pipeline` as a detached quiet batch; the metadata check
  showed `status=running`, `running=true`, `runner_started=true`, and
  `runner_finished=false`. Did not watch or tail the running pipeline.
