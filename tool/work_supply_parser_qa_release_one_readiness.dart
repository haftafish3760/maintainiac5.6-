import 'dart:convert';
import 'dart:io';

import '../test/support/parser_qa_platform/parser_qa_release_readiness.dart';

const _usage =
    'dart run tool/work_supply_parser_qa_release_one_readiness.dart '
    '[--wave-report build/parser_qa_batch_waves/pass252-final-wave-report.json] '
    '[--pipeline-status build/parser_qa_pipeline/status_reports/latest_pipeline_status.json] '
    '[--fixture-readiness build/parser_qa_pipeline/fixture_readiness_rollup.json] '
    '[--output build/parser_qa_batch_waves/release_one_readiness.json]';

const _governedReportFields = [
  'releaseOneParserEvidenceReady',
  'releaseOnePipelineArtifactsReady',
  'releaseOneFixtureEvidenceReady',
  'fixtureReadinessReady',
  'pipelineMissingCells',
  'nextActions',
];

Future<void> main(List<String> args) async {
  final exit = runWorkSupplyParserQaReleaseOneReadiness(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

int runWorkSupplyParserQaReleaseOneReadiness(
  List<String> args, {
  required IOSink stdout,
  required IOSink stderr,
}) {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    stdout.writeln('Governed fields: ${_governedReportFields.join(', ')}');
    return 0;
  }
  final waveReportPath = _value(args, 'wave-report', '');
  final pipelineStatusPath = _value(args, 'pipeline-status', '');
  final fixtureReadinessPath = _value(args, 'fixture-readiness', '');
  if (waveReportPath.isEmpty || pipelineStatusPath.isEmpty) {
    stderr.writeln('--wave-report and --pipeline-status are required.');
    return 64;
  }
  final waveFile = File(waveReportPath);
  final output = _value(
    args,
    'output',
    '${waveFile.parent.path}/release_one_readiness.json',
  );
  try {
    final readiness = buildParserQaReleaseReadiness(
      ParserQaReleaseReadinessOptions(
        waveReportPath: waveReportPath,
        pipelineStatusPath: pipelineStatusPath,
        fixtureReadinessPath: fixtureReadinessPath,
        outputPath: output,
        reportName: 'work_supply_parser_qa_release_one_readiness',
      ),
    );
    final json = const JsonEncoder.withIndent('  ').convert(readiness);
    stdout.writeln('QA_RELEASE_ONE_READINESS $json');
    stdout.writeln('QA_RELEASE_ONE_READINESS_ARTIFACT json=$output');
    return readiness['unsafe'] == true || readiness['waveReady'] != true
        ? 1
        : 0;
  } on FileSystemException catch (error) {
    stderr.writeln(error.message);
    return 66;
  }
}

String _value(List<String> args, String key, String fallback) {
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (arg == '--$key' && index + 1 < args.length) return args[index + 1];
    if (arg.startsWith('--$key=')) return arg.substring(key.length + 3);
  }
  return fallback;
}
