import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/work_supply_parser_qa_pipeline.dart';
import '../tool/work_supply_parser_qa_pipeline_status.dart';

void main() {
  test(
    'pipeline status reports present and missing local matrix cells',
    () async {
      final output = await Directory.systemTemp.createTemp(
        'maintainiac_parser_pipeline_status_',
      );
      addTearDown(() => output.delete(recursive: true));

      final pipelineExit = await runWorkSupplyParserQaPipeline(
        [
          '--execute',
          '--locales',
          'en-US,es-US',
          '--limit',
          '4',
          '--output-root',
          output.path,
        ],
        stdout: _MemorySink(),
        stderr: _MemorySink(),
      );
      expect(pipelineExit, 0);

      final stdout = _MemorySink();
      final reportDir = '${output.path}/status_reports';
      final statusExit = runWorkSupplyParserQaPipelineStatus(
        [
          '--output-root',
          output.path,
          '--report-dir',
          reportDir,
          '--trades',
          'plumbing,electrical',
          '--scopes',
          'residential',
          '--tiers',
          'core',
          '--locales',
          'en-US,es-US',
        ],
        stdout: stdout,
        stderr: _MemorySink(),
      );

      expect(statusExit, 0);
      expect(stdout.content, contains('QA_ECONOMICAL_PIPELINE_STATUS'));
      expect(
        stdout.content,
        contains('QA_ECONOMICAL_PIPELINE_STATUS_ARTIFACT'),
      );
      final summary = _extractStatusSummary(stdout.content);
      expect(summary['expectedCells'], 4);
      expect(summary['presentCells'], 2);
      expect(summary['missingCells'], 2);
      expect(summary['unsafeCells'], 0);
      expect(summary['parserCalls'], 0);
      expect(summary['parserEvidenceCells'], 0);
      expect(summary['missingParserEvidenceCells'], 2);
      expect(summary['requireComplete'], isFalse);
      expect(summary['liveServicesAllowed'], isFalse);
      expect(summary['writesProductionCatalog'], isFalse);
      final cells = (summary['cells'] as List).cast<Map>();
      expect(cells.where((cell) => cell['status'] == 'present'), hasLength(2));
      expect(cells.where((cell) => cell['status'] == 'missing'), hasLength(2));
      expect(cells.every((cell) => cell['localOnlySafe'] == true), isTrue);
      expect(cells.every((cell) => cell['parserCalls'] == 0), isTrue);
      expect(
        cells
            .where((cell) => cell['status'] == 'present')
            .every((cell) => cell['parserEvidenceReady'] == false),
        isTrue,
      );
      final latestStatus = File('$reportDir/latest_pipeline_status.json');
      expect(latestStatus.existsSync(), isTrue);
      final artifactSummary =
          jsonDecode(latestStatus.readAsStringSync()) as Map;
      expect(artifactSummary['presentCells'], 2);
      expect(artifactSummary['missingCells'], 2);
    },
  );

  test('pipeline status can fail when required cells are missing', () async {
    final output = await Directory.systemTemp.createTemp(
      'maintainiac_parser_pipeline_status_required_',
    );
    addTearDown(() => output.delete(recursive: true));

    final stdout = _MemorySink();
    final statusExit = runWorkSupplyParserQaPipelineStatus(
      [
        '--output-root',
        output.path,
        '--trades',
        'plumbing',
        '--scopes',
        'residential',
        '--tiers',
        'core',
        '--locales',
        'en-US,es-US',
        '--require-complete',
      ],
      stdout: stdout,
      stderr: _MemorySink(),
    );

    expect(statusExit, 2);
    final summary = _extractStatusSummary(stdout.content);
    expect(summary['requireComplete'], isTrue);
    expect(summary['parserCalls'], 0);
    expect(summary['parserEvidenceCells'], 0);
    expect(summary['missingParserEvidenceCells'], 0);
    expect(summary['missingCells'], 2);
    expect(summary['presentCells'], 0);
  });

  test(
    'pipeline status fails when a local summary allows live services',
    () async {
      final output = await Directory.systemTemp.createTemp(
        'maintainiac_parser_pipeline_status_unsafe_',
      );
      addTearDown(() => output.delete(recursive: true));
      final reportDir = Directory(
        '${output.path}/plumbing/residential/core/en-US/pipeline_reports',
      )..createSync(recursive: true);
      File('${reportDir.path}/latest_pipeline_summary.json').writeAsStringSync(
        jsonEncode({
          'trade': 'plumbing',
          'marketScope': 'residential',
          'tier': 'core',
          'localePackId': 'en-US',
          'liveServicesAllowed': true,
          'writesProductionCatalog': false,
          'blueprintPath': '${output.path}/fake_blueprints.json',
          'fixturePath': '${output.path}/fake_fixtures.json',
        }),
      );

      final stdout = _MemorySink();
      final statusExit = runWorkSupplyParserQaPipelineStatus(
        ['--output-root', output.path, '--locales', 'en-US'],
        stdout: stdout,
        stderr: _MemorySink(),
      );

      expect(statusExit, 1);
      expect(stdout.content, contains('"unsafeCells": 1'));
      expect(stdout.content, contains('"localOnlySafe": false'));
    },
  );

  test('pipeline status separates parser evidence from local safety', () async {
    final output = await Directory.systemTemp.createTemp(
      'maintainiac_parser_pipeline_status_parser_evidence_',
    );
    addTearDown(() => output.delete(recursive: true));
    final reportDir = Directory(
      '${output.path}/plumbing/residential/core/en-US/pipeline_reports',
    )..createSync(recursive: true);
    File('${reportDir.path}/latest_pipeline_summary.json').writeAsStringSync(
      jsonEncode({
        'trade': 'plumbing',
        'marketScope': 'residential',
        'tier': 'core',
        'localePackId': 'en-US',
        'liveServicesAllowed': false,
        'writesProductionCatalog': false,
        'parserCalls': 48,
        'blueprintPath': '${output.path}/fake_blueprints.json',
        'fixturePath': '${output.path}/fake_fixtures.json',
      }),
    );

    final stdout = _MemorySink();
    final statusExit = runWorkSupplyParserQaPipelineStatus(
      ['--output-root', output.path, '--locales', 'en-US'],
      stdout: stdout,
      stderr: _MemorySink(),
    );

    expect(statusExit, 0);
    final summary = _extractStatusSummary(stdout.content);
    final cell = (summary['cells'] as List).single as Map;
    expect(summary['parserCalls'], 48);
    expect(summary['parserEvidenceCells'], 1);
    expect(summary['missingParserEvidenceCells'], 0);
    expect(cell['localOnlySafe'], isTrue);
    expect(cell['parserEvidenceReady'], isTrue);
  });
}

Map<String, Object?> _extractStatusSummary(String output) {
  const marker = 'QA_ECONOMICAL_PIPELINE_STATUS ';
  final start = output.indexOf(marker);
  expect(start, isNonNegative);
  final jsonStart = start + marker.length;
  final nextMarker = output.indexOf(
    '\nQA_ECONOMICAL_PIPELINE_STATUS_ARTIFACT',
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
