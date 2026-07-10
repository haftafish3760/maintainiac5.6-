import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/work_supply_parser_qa_matrix_pipeline.dart';
import '../tool/work_supply_parser_qa_pipeline_status.dart';

void main() {
  test('matrix pipeline dry-run plans top residential core trades', () async {
    final output = await Directory.systemTemp.createTemp(
      'maintainiac_parser_matrix_dry_',
    );
    addTearDown(() => output.delete(recursive: true));

    final stdout = _MemorySink();
    final exit = await runWorkSupplyParserQaMatrixPipeline(
      ['--limit', '3', '--output-root', output.path],
      stdout: stdout,
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    expect(stdout.content, contains('QA_ECONOMICAL_MATRIX_PIPELINE'));
    expect(stdout.content, contains('"dryRun": true'));
    expect(stdout.content, contains('"writesProductionCatalog": false'));
    final summary = _extractMatrixSummary(stdout.content);
    expect(summary['results'], hasLength(3));
  });

  test('matrix pipeline execute feeds status require-complete gate', () async {
    final output = await Directory.systemTemp.createTemp(
      'maintainiac_parser_matrix_execute_',
    );
    addTearDown(() => output.delete(recursive: true));

    final exit = await runWorkSupplyParserQaMatrixPipeline(
      [
        '--execute',
        '--trades',
        'plumbing,electrical,hvac',
        '--scopes',
        'residential',
        '--tiers',
        'core',
        '--locales',
        'en-US,es-US',
        '--limit',
        '3',
        '--output-root',
        output.path,
      ],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );
    expect(exit, 0);

    final statusOut = _MemorySink();
    final statusExit = runWorkSupplyParserQaPipelineStatus(
      [
        '--output-root',
        output.path,
        '--trades',
        'plumbing,electrical,hvac',
        '--scopes',
        'residential',
        '--tiers',
        'core',
        '--locales',
        'en-US,es-US',
        '--require-complete',
      ],
      stdout: statusOut,
      stderr: _MemorySink(),
    );

    expect(statusExit, 0);
    expect(statusOut.content, contains('"presentCells": 6'));
    expect(statusOut.content, contains('"missingCells": 0'));
    expect(statusOut.content, contains('"unsafeCells": 0'));
  });

  test('matrix pipeline can run the status gate itself', () async {
    final output = await Directory.systemTemp.createTemp(
      'maintainiac_parser_matrix_status_gate_',
    );
    addTearDown(() => output.delete(recursive: true));

    final stdout = _MemorySink();
    final exit = await runWorkSupplyParserQaMatrixPipeline(
      [
        '--execute',
        '--status-gate',
        '--trades',
        'plumbing,electrical,hvac',
        '--scopes',
        'residential',
        '--tiers',
        'core',
        '--locales',
        'en-US,es-US',
        '--limit',
        '2',
        '--output-root',
        output.path,
      ],
      stdout: stdout,
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    expect(stdout.content, contains('QA_ECONOMICAL_PIPELINE_STATUS'));
    expect(stdout.content, contains('"presentCells": 6'));
    final summary = _extractMatrixSummary(stdout.content);
    expect(summary['statusGate'], isTrue);
    expect(summary['statusGateExitCode'], 0);
    expect(
      File(
        '${output.path}/status_reports/latest_pipeline_status.json',
      ).existsSync(),
      isTrue,
    );
  });

  test('matrix pipeline single-locale execute matches status layout', () async {
    final output = await Directory.systemTemp.createTemp(
      'maintainiac_parser_matrix_single_locale_',
    );
    addTearDown(() => output.delete(recursive: true));

    final stdout = _MemorySink();
    final exit = await runWorkSupplyParserQaMatrixPipeline(
      [
        '--execute',
        '--status-gate',
        '--trades',
        'plumbing',
        '--scopes',
        'residential',
        '--tiers',
        'core',
        '--locales',
        'en-US',
        '--limit',
        '2',
        '--output-root',
        output.path,
      ],
      stdout: stdout,
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    expect(stdout.content, contains('"presentCells": 1'));
    expect(stdout.content, contains('"missingCells": 0'));
    expect(
      File(
        '${output.path}/plumbing/residential/core/en-US/pipeline_reports/'
        'latest_pipeline_summary.json',
      ).existsSync(),
      isTrue,
    );
  });

  test(
    'matrix pipeline passes generated fixture runner intent through',
    () async {
      final output = await Directory.systemTemp.createTemp(
        'maintainiac_parser_matrix_run_fixtures_',
      );
      addTearDown(() => output.delete(recursive: true));

      final stdout = _MemorySink();
      final exit = await runWorkSupplyParserQaMatrixPipeline(
        [
          '--run-fixtures',
          '--trades',
          'plumbing',
          '--scopes',
          'residential',
          '--tiers',
          'core',
          '--locales',
          'en-US',
          '--limit',
          '2',
          '--output-root',
          output.path,
        ],
        stdout: stdout,
        stderr: _MemorySink(),
      );

      expect(exit, 0);
      expect(stdout.content, contains('"runFixtures": true'));
      expect(stdout.content, contains('run_generated_parser_fixtures'));
      expect(stdout.content, contains('"willExecute": false'));
      final summary = _extractMatrixSummary(stdout.content);
      expect(summary['runFixtures'], isTrue);
    },
  );

  test('matrix pipeline passes fixture run caps through', () async {
    final stdout = _MemorySink();
    final exit = await runWorkSupplyParserQaMatrixPipeline(
      [
        '--run-fixtures',
        '--trades',
        'plumbing',
        '--locales',
        'en-US',
        '--limit',
        '500',
        '--fixture-run-limit',
        '25',
        '--fixture-run-timeout-ms',
        '60000',
        '--fixture-run-stale-report-timeout-ms',
        '300000',
      ],
      stdout: stdout,
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    expect(stdout.content, contains('"limit": 500'));
    expect(stdout.content, contains('"fixtureRunLimit": 25'));
    expect(stdout.content, contains('"fixtureRunTimeoutMs": 60000'));
    expect(
      stdout.content,
      contains('"fixtureRunStaleReportTimeoutMs": 300000'),
    );
    expect(
      stdout.content,
      contains('work_supply_parser_qa_run_generated_fixtures.dart'),
    );
    expect(stdout.content, contains('--max-cases'));
    expect(stdout.content, contains('25'));
    expect(stdout.content, contains('--timeout-ms'));
    expect(stdout.content, contains('60000'));
    expect(stdout.content, contains('--stale-report-timeout-ms'));
    expect(stdout.content, contains('300000'));
    final summary = _extractMatrixSummary(stdout.content);
    expect(summary['fixtureRunLimit'], 25);
    expect(summary['fixtureRunTimeoutMs'], 60000);
    expect(summary['fixtureRunStaleReportTimeoutMs'], 300000);
  });

  test('matrix pipeline first-round preset plans capped QA gate', () async {
    final stdout = _MemorySink();
    final exit = await runWorkSupplyParserQaMatrixPipeline(
      [
        '--first-round',
        '--trades',
        'plumbing',
        '--locales',
        'en-US',
        '--output-root',
        'build/parser_qa_pipeline/first-round-dry',
      ],
      stdout: stdout,
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    expect(stdout.content, contains('"firstRound": true'));
    expect(stdout.content, contains('"runFixtures": true'));
    expect(stdout.content, contains('"statusGate": true'));
    expect(stdout.content, contains('"fixtureRunLimit": 25'));
    expect(stdout.content, contains('"dryRun": true'));
    expect(stdout.content, contains('QA_ECONOMICAL_PIPELINE_STATUS'));
  });
}

Map<String, Object?> _extractMatrixSummary(String output) {
  const marker = 'QA_ECONOMICAL_MATRIX_PIPELINE ';
  final start = output.indexOf(marker);
  expect(start, isNonNegative);
  final jsonStart = start + marker.length;
  final nextMarker = output.indexOf(
    '\nQA_ECONOMICAL_MATRIX_PIPELINE_ARTIFACT',
    jsonStart,
  );
  final jsonText = nextMarker == -1
      ? output.substring(jsonStart)
      : output.substring(jsonStart, nextMarker);
  return jsonDecode(jsonText) as Map<String, Object?>;
}

class _MemorySink implements IOSink {
  final _buffer = StringBuffer();

  String get content => _buffer.toString();

  @override
  void write(Object? object) => _buffer.write(object);

  @override
  void writeln([Object? object = '']) => _buffer.writeln(object);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
