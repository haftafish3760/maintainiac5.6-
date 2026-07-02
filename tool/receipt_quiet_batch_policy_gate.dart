import 'dart:io';

const _launcherPath = 'tool/receipt_quiet_batch.sh';
const _statusPath = 'tool/receipt_quiet_batch_status.sh';
const _qualityGateLauncherPath = 'tool/receipt_start_quiet_quality_gate.sh';
const _ocrPipelineLauncherPath = 'tool/receipt_start_ocr_pipeline.sh';
const _ocrPipelineRunnerPath = 'tool/receipt_ocr_pipeline_run.sh';
const _failureRegressionPath =
    'tool/receipt_pipeline_failure_to_regression.dart';

void main() {
  final failures = <String>[];
  final launcher = _read(_launcherPath, failures);
  final status = _read(_statusPath, failures);
  final qualityGateLauncher = _read(_qualityGateLauncherPath, failures);
  final ocrPipelineLauncher = _read(_ocrPipelineLauncherPath, failures);
  final ocrPipelineRunner = _read(_ocrPipelineRunnerPath, failures);
  final failureRegression = _read(_failureRegressionPath, failures);
  if (failures.isEmpty) {
    _checkLauncher(launcher, failures);
    _checkStatusHelper(status, failures);
    _checkQualityGateLauncher(qualityGateLauncher, failures);
    _checkOcrPipelineLauncher(ocrPipelineLauncher, failures);
    _checkOcrPipelineRunner(ocrPipelineRunner, failures);
    _checkFailureRegression(failureRegression, failures);
  }

  if (failures.isNotEmpty) {
    stderr.writeln('Receipt quiet batch policy gate failed:');
    for (final failure in failures) {
      stderr.writeln('- $failure');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln('Receipt quiet batch policy gate: PASS');
}

String _read(String path, List<String> failures) {
  final file = File(path);
  if (!file.existsSync()) {
    failures.add('Missing quiet batch script: $path');
    return '';
  }
  return file.readAsStringSync();
}

void _checkLauncher(String text, List<String> failures) {
  _require(text, 'run.log', 'launcher must name run.log output', failures);
  _require(
    text,
    'run_command.sh',
    'launcher must create a detached runner script',
    failures,
  );
  _require(
    text,
    'args_literal="args=("',
    'launcher must generate a runner args array',
    failures,
  );
  _require(
    text,
    r'"\${args[@]}"',
    'launcher runner must preserve command argument boundaries',
    failures,
  );
  _require(
    text,
    'runner_started',
    'launcher must write a runner startup marker',
    failures,
  );
  _require(
    text,
    'runner_finished',
    'launcher must write a runner completion marker',
    failures,
  );
  _require(
    text,
    r'rm -f "$exit_code" "$pid_file"',
    'launcher must clear stale pid metadata before restart',
    failures,
  );
  _require(
    text,
    r'cd $(printf',
    'launcher runner must restore the repository working directory',
    failures,
  );
  _require(
    text,
    "printf '%s\\n' \"\\\$\\\$\"",
    'launcher runner must write its own pid',
    failures,
  );
  _require(
    text,
    'screen -dmS',
    'launcher must prefer detached screen when available',
    failures,
  );
  _require(
    text,
    'launchctl submit',
    'launcher must use macOS launchctl isolation when available',
    failures,
  );
  _require(
    text,
    r'.$(date +%s).$$',
    'launcher must use a unique launchctl label per run',
    failures,
  );
  _require(text, r'nohup bash "$runner"', 'launcher must use nohup', failures);
  _require(
    text,
    r'} > $(printf',
    'launcher must redirect command output',
    failures,
  );
  _require(
    text,
    'printf \'running\\n\' > "\$status"',
    'launcher must write running status',
    failures,
  );
  _require(
    text,
    "printf '%s\\n' \"\\\$code\" > \$(printf",
    'launcher must write exit code',
    failures,
  );
  _require(
    text,
    r'exit "\$code"',
    'launcher runner must exit with payload status',
    failures,
  );
  _require(
    text,
    r'nohup bash "$runner" >/dev/null 2>&1 </dev/null &',
    'launcher must detach command in background',
    failures,
  );
  _require(
    text,
    'trap finish EXIT',
    'launcher must finalize status on EXIT',
    failures,
  );
}

void _checkStatusHelper(String text, List<String> failures) {
  _require(
    text,
    'log_file="\$root/run.log"',
    'status helper must report log path',
    failures,
  );
  _require(
    text,
    'echo "log=\$log_file"',
    'status helper must print log path only',
    failures,
  );
  _require(
    text,
    'status="stale"',
    'status helper must expose stale dead-running batches',
    failures,
  );
  _require(
    text,
    r'[[ "$status" == "running" ]]',
    'status helper must only report running for active running jobs',
    failures,
  );
  _require(
    text,
    'runner_started=',
    'status helper must report runner startup metadata',
    failures,
  );
  _require(
    text,
    'runner_finished=',
    'status helper must report runner completion metadata',
    failures,
  );
  for (final blocked in const [
    'tail ',
    'less ',
    'more ',
    'sed ',
    'awk ',
    'grep ',
    'cat "\$log_file"',
    'cat \$log_file',
    '< "\$log_file"',
  ]) {
    if (text.contains(blocked)) {
      failures.add(
        'status helper must not read or stream run.log via `$blocked`.',
      );
    }
  }
}

void _checkQualityGateLauncher(String text, List<String> failures) {
  _require(
    text,
    'bash tool/receipt_quiet_batch.sh',
    'quality gate launcher must use quiet batch launcher',
    failures,
  );
  _require(
    text,
    r'''sed '' tool/receipt_quality_gate.sh > "$payload"''',
    'quality gate launcher must rewrite its payload into the quiet batch directory',
    failures,
  );
  _require(
    text,
    r'command_line="/bin/bash $(printf',
    'quality gate launcher must build a quoted login-shell command',
    failures,
  );
  _require(
    text,
    r'/bin/bash -lc "$command_line"',
    'quality gate launcher must execute the rewritten payload through a login shell',
    failures,
  );
  _require(
    text,
    'batch_name="\${1:-receipt_quality_gate}"',
    'quality gate launcher must default to receipt_quality_gate batch name',
    failures,
  );
  for (final blocked in const ['tail ', 'cat ', 'flutter test']) {
    if (text.contains(blocked)) {
      failures.add(
        'quality gate launcher must not stream logs or run Flutter directly.',
      );
    }
  }
}

void _checkOcrPipelineLauncher(String text, List<String> failures) {
  _require(
    text,
    'bash tool/receipt_quiet_batch.sh',
    'OCR pipeline launcher must use quiet batch launcher',
    failures,
  );
  _require(
    text,
    r'''sed '' tool/receipt_ocr_pipeline_run.sh > "$payload"''',
    'OCR pipeline launcher must rewrite its payload into the quiet batch directory',
    failures,
  );
  _require(
    text,
    r'payload_scripts="$batch_root/pipeline_scripts"',
    'OCR pipeline launcher must create staged shell-script payloads',
    failures,
  );
  _require(
    text,
    'RECEIPT_PIPELINE_SCRIPT_ROOT=',
    'OCR pipeline launcher must pass staged shell-script root',
    failures,
  );
  _require(
    text,
    r'command_line="RECEIPT_PIPELINE_SCRIPT_ROOT=$(printf',
    'OCR pipeline launcher must build a quoted login-shell command',
    failures,
  );
  _require(
    text,
    r'/bin/bash -lc "$command_line"',
    'OCR pipeline launcher must execute the rewritten payload through a login shell',
    failures,
  );
  _require(
    text,
    r'batch_name="${1:-receipt_ocr_pipeline}"',
    'OCR pipeline launcher must default to receipt_ocr_pipeline batch name',
    failures,
  );
}

void _checkOcrPipelineRunner(String text, List<String> failures) {
  for (final phase in const [
    'static_guardrails',
    'pure_receipt_qa',
    'camera_pipeline_contracts',
    'native_camera_compile',
    'full_receipt_quality_gate',
    'regression_report',
  ]) {
    _require(
      text,
      'phase $phase',
      'OCR pipeline missing phase `$phase`.',
      failures,
    );
  }
  _require(
    text,
    'failure_report.txt',
    'OCR pipeline must write a failure report',
    failures,
  );
  _require(
    text,
    r'rm -rf "$root"',
    'OCR pipeline must remove the stale temp run directory before each run',
    failures,
  );
  _require(
    text,
    'trap finish_pipeline EXIT',
    'OCR pipeline must finalize status on EXIT',
    failures,
  );
  _require(
    text,
    'pipeline_startup_or_unhandled_exit',
    'OCR pipeline must report startup or unhandled exits',
    failures,
  );
  _require(
    text,
    'pipeline_interrupted',
    'OCR pipeline must report interrupted runs separately',
    failures,
  );
  _require(
    text,
    'summary.tsv',
    'OCR pipeline must write a phase summary',
    failures,
  );
  _require(
    text,
    'tool/receipt_quality_gate.sh',
    'OCR pipeline must include the full receipt quality gate',
    failures,
  );
  _require(
    text,
    'run_repo_script()',
    'OCR pipeline must define stdin-safe repo script execution',
    failures,
  );
  _require(
    text,
    'repo_script_path()',
    'OCR pipeline must resolve staged shell-script payloads',
    failures,
  );
  _require(
    text,
    r'RECEIPT_PIPELINE_SCRIPT_ROOT',
    'OCR pipeline must honor staged shell-script root',
    failures,
  );
  for (final blocked in const [
    'bash tool/receipt_cleanup_log_gate.sh',
    'bash tool/receipt_doc_size_gate.sh',
    'bash tool/receipt_camera_pipeline_gate.sh',
    'bash tool/android_receipt_camera_compile_gate.sh',
    'bash tool/ios_receipt_camera_compile_gate.sh',
    'bash tool/receipt_quality_gate.sh',
    'bash tool/receipt_regression_report.sh',
  ]) {
    if (text.contains(blocked)) {
      failures.add(
        'OCR pipeline must not execute repo shell scripts by path: `$blocked`.',
      );
    }
  }
  _require(
    text,
    'write_regression_task()',
    'OCR pipeline must create failure regression tasks without dart run hooks',
    failures,
  );
  if (text.contains(
    'dart run tool/receipt_pipeline_failure_to_regression.dart',
  )) {
    failures.add(
      'OCR pipeline must not run the failure regression helper through dart run.',
    );
  }
  for (final blocked in const ['tail ', 'less ', 'more ']) {
    if (text.contains(blocked)) {
      failures.add('OCR pipeline runner must not live-stream phase logs.');
    }
  }
}

void _checkFailureRegression(String text, List<String> failures) {
  for (final required in const [
    'failure_report.txt',
    'regression_tasks',
    'FAILED_PHASE',
    'Failure family',
    'Add or extend a regression test',
    'future run fails if the same class of bug is',
  ]) {
    _require(
      text,
      required,
      'failure-to-regression generator missing `$required`.',
      failures,
    );
  }
}

void _require(
  String text,
  String needle,
  String message,
  List<String> failures,
) {
  if (!text.contains(needle)) {
    failures.add(message);
  }
}
