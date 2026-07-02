import 'dart:io';

const _defaultRunName = 'receipt_ocr_pipeline';
const _rootBase = '/tmp/maintainiac_receipt_ocr_pipeline';

void main(List<String> args) {
  final runName = args.isEmpty ? _defaultRunName : args.first;
  final root = Directory('$_rootBase/$runName');
  final failureReport = File('${root.path}/failure_report.txt');
  final outputDir = Directory('${root.path}/regression_tasks');

  if (!failureReport.existsSync()) {
    stderr.writeln('No failure report found at ${failureReport.path}.');
    exitCode = 66;
    return;
  }

  final fields = _parseFailureReport(failureReport.readAsLinesSync());
  final phase = fields['FAILED_PHASE'] ?? 'unknown_phase';
  final log = fields['LOG'] ?? '${root.path}/phases/$phase.log';
  final family = _familyForPhase(phase);

  outputDir.createSync(recursive: true);
  final task = File('${outputDir.path}/${phase}_regression_task.md');
  task.writeAsStringSync(_taskMarkdown(runName, phase, log, family));

  stdout.writeln('Receipt regression task: ${task.path}');
}

Map<String, String> _parseFailureReport(List<String> lines) {
  final fields = <String, String>{};
  for (final line in lines) {
    final split = line.indexOf(' ');
    if (split <= 0) continue;
    fields[line.substring(0, split)] = line.substring(split + 1);
  }
  return fields;
}

String _familyForPhase(String phase) {
  return switch (phase) {
    'static_guardrails' => 'static_guardrails_and_source_size',
    'pure_receipt_qa' => 'pure_dart_receipt_qa',
    'camera_pipeline_contracts' => 'camera_capture_ocr_stitch_contracts',
    'native_camera_compile' => 'native_android_ios_camera_bridge',
    'full_receipt_quality_gate' => 'full_receipt_quality_gate',
    'regression_report' => 'regression_reporting',
    _ => 'unknown_receipt_ocr_pipeline_family',
  };
}

String _taskMarkdown(String runName, String phase, String log, String family) {
  return '''
# Receipt OCR Regression Task

Run: `$runName`
Failed phase: `$phase`
Failure family: `$family`
Phase log: `$log`

## Required Work

- Inspect the phase log and identify the root cause.
- Fix the production code, fixture, script, or contract that caused the failure.
- Add or extend a regression test for the whole failure family, not only the
  single failing example.
- Rerun `tool/receipt_start_ocr_pipeline.sh $runName` detached through the quiet
  pipeline launcher.

## Regression Standard

The fix is not complete until a future run fails if the same class of bug is
reintroduced.
''';
}
