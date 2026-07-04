import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/work_supply_parser_qa_generated_run_status.dart';

void main() {
  test('generated run status reports complete local-only cells', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_generated_run_status_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);
    _writeRun(
      'build/reports/plumbing/residential/core/en-US/reports/latest_generated_fixture_run.json',
      checked: 110,
      parserCalls: 126,
    );
    _writeRun(
      'build/reports/plumbing/residential/core/es-US/reports/latest_generated_fixture_run.json',
      checked: 110,
      parserCalls: 126,
    );

    final exit = runWorkSupplyParserQaGeneratedRunStatus(
      [
        '--report-root',
        'build/reports',
        '--trades',
        'plumbing',
        '--tiers',
        'core',
        '--locales',
        'en-US,es-US',
        '--require-complete',
      ],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    final status = _readJson(
      'build/parser_qa_pipeline/core_generated_run_status.json',
    );
    expect(status['expectedCells'], 2);
    expect(status['presentCells'], 2);
    expect(status['missingCells'], 0);
    expect(status['failedCells'], 0);
    expect(status['unsafeCells'], 0);
    expect(status['checkedTotal'], 220);
    expect(status['parserCalls'], 252);
    expect(status['liveServicesAllowed'], isFalse);
    final cells = status['cells'] as List;
    expect(cells, everyElement(containsPair('localOnlySafe', true)));
    expect(
      cells,
      everyElement(containsPair('safetyMissingFields', isEmpty)),
    );
  });

  test(
    'generated run status fails require-complete when a cell is missing',
    () {
      final root = Directory.systemTemp.createTempSync(
        'maintainiac_generated_run_missing_',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      final previous = Directory.current;
      Directory.current = root;
      addTearDown(() => Directory.current = previous);

      final exit = runWorkSupplyParserQaGeneratedRunStatus(
        [
          '--report-root',
          'build/reports',
          '--trades',
          'plumbing',
          '--tiers',
          'core',
          '--locales',
          'en-US',
          '--require-complete',
        ],
        stdout: _MemorySink(),
        stderr: _MemorySink(),
      );

      expect(exit, 2);
      final status = _readJson(
        'build/parser_qa_pipeline/core_generated_run_status.json',
      );
      expect(status['missingCells'], 1);
    },
  );

  test('generated run status fails failed or unsafe report cells', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_generated_run_unsafe_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);
    _writeRun(
      'build/reports/plumbing/residential/core/en-US/reports/latest_generated_fixture_run.json',
      checked: 110,
      failureCount: 1,
      liveServicesAllowed: true,
    );

    final exit = runWorkSupplyParserQaGeneratedRunStatus(
      [
        '--report-root',
        'build/reports',
        '--trades',
        'plumbing',
        '--tiers',
        'core',
        '--locales',
        'en-US',
        '--require-complete',
      ],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 1);
    final status = _readJson(
      'build/parser_qa_pipeline/core_generated_run_status.json',
    );
    expect(status['failedCells'], 1);
    expect(status['unsafeCells'], 1);
  });

  test('generated run status fails reports missing explicit safety fields', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_generated_run_missing_safety_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);
    _writeRun(
      'build/reports/plumbing/residential/core/en-US/reports/latest_generated_fixture_run.json',
      checked: 110,
      includeSafetyFields: false,
    );

    final exit = runWorkSupplyParserQaGeneratedRunStatus(
      [
        '--report-root',
        'build/reports',
        '--trades',
        'plumbing',
        '--tiers',
        'core',
        '--locales',
        'en-US',
        '--require-complete',
      ],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 1);
    final status = _readJson(
      'build/parser_qa_pipeline/core_generated_run_status.json',
    );
    expect(status['unsafeCells'], 1);
    final cells = status['cells'] as List;
    expect(cells.single, containsPair('localOnlySafe', false));
    expect(
      cells.single['safetyMissingFields'],
      contains('firebaseWritesAllowed'),
    );
  });
}

void _writeRun(
  String path, {
  required int checked,
  int failureCount = 0,
  int parserCalls = 0,
  bool liveServicesAllowed = false,
  bool writesProductionCatalog = false,
  bool firebaseWritesAllowed = false,
  bool ocrCameraExpensesTouched = false,
  bool includeSafetyFields = true,
}) {
  final file = File(path)..parent.createSync(recursive: true);
  final payload = {
    'fixturePath': 'build/generated_fixtures.json',
    'checked': checked,
    'failureCount': failureCount,
    'parserCalls': parserCalls,
    if (includeSafetyFields) ...{
      'liveServicesAllowed': liveServicesAllowed,
      'writesProductionCatalog': writesProductionCatalog,
      'firebaseWritesAllowed': firebaseWritesAllowed,
      'ocrCameraExpensesTouched': ocrCameraExpensesTouched,
    },
  };
  file.writeAsStringSync(jsonEncode(payload));
}

Map<String, Object?> _readJson(String path) {
  return jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;
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
