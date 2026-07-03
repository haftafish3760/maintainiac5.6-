import 'dart:io';

import '../test/support/qa_harness/qa_harness.dart';
import '../test/support/qa_harness/qa_suite_presets.dart';
import '../test/support/qa_harness/qa_threshold_gate.dart';

const _usage =
    'dart run tool/maintainiac_qa_backbone.dart '
    '[--profile smoke|full|release] [--preset main] '
    '[--suites maintainiac.qa_backbone_contract,qa.threshold_gate] '
    '[--output build/parser_qa_reports] [--strict]';

Future<void> main(List<String> args) async {
  final result = await runMaintainiacQaBackbone(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (result.exitCode != 0) exitCode = result.exitCode;
}

Future<MaintainiacQaBackboneCommandResult> runMaintainiacQaBackbone(
  List<String> args, {
  required IOSink stdout,
  required IOSink stderr,
}) async {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return const MaintainiacQaBackboneCommandResult(exitCode: 0);
  }
  final profile = _value(args, 'profile', 'smoke');
  final preset = _value(args, 'preset', 'main');
  final suiteCsv = _value(args, 'suites', '');
  final output = _value(args, 'output', 'build/parser_qa_reports');
  final strict = args.contains('--strict');
  final suiteFilter = qaSuiteFilterFrom(suiteCsv: suiteCsv, preset: preset);
  final runConfig = QaRunConfig(
    profile: profile,
    preset: preset,
    suiteFilter: suiteFilter,
  );
  final context = QaContext(
    strict: strict,
    redactor: const QaRedactor(),
    profile: profile,
    suiteFilter: suiteFilter,
    thresholds: QaThresholds.forProfile(profile),
  );
  final report = await runQaHarnessWithThresholdGate(
    harness: const QaHarness(
      domain: 'maintainiac_main',
      suites: [MaintainiacQaBackboneSuite()],
    ),
    context: context,
    runConfig: runConfig,
  );
  final artifact = await writeQaReport(report: report, outputDirectory: output);
  stdout.writeln(report.toSummary());
  stdout.writeln(
    'MAINTAINIAC_QA_ARTIFACT json=${artifact.timestampedJsonPath} '
    'latestJson=${artifact.latestJsonPath} '
    'latestSummary=${artifact.latestSummaryPath} '
    'packHealthJson=${artifact.timestampedPackHealthJsonPath} '
    'latestPackHealthJson=${artifact.latestPackHealthJsonPath}',
  );
  final hasBlockingFailures = report.results.any(
    (result) => result.hasBlockingFailures,
  );
  if (strict && hasBlockingFailures) {
    stderr.writeln('Maintainiac QA backbone failed strict mode.');
    return MaintainiacQaBackboneCommandResult(
      exitCode: 1,
      report: report,
      artifact: artifact,
    );
  }
  return MaintainiacQaBackboneCommandResult(
    exitCode: 0,
    report: report,
    artifact: artifact,
  );
}

class MaintainiacQaBackboneCommandResult {
  const MaintainiacQaBackboneCommandResult({
    required this.exitCode,
    this.report,
    this.artifact,
  });

  final int exitCode;
  final QaReport? report;
  final QaReportArtifact? artifact;
}

String _value(List<String> args, String key, String fallback) {
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (arg == '--$key' && index + 1 < args.length) return args[index + 1];
    if (arg.startsWith('--$key=')) return arg.substring(key.length + 3);
  }
  return fallback;
}
