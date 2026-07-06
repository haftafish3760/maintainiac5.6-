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
      durationMs: 7000,
    );
    _writeRun(
      'build/reports/plumbing/residential/core/es-US/reports/latest_generated_fixture_run.json',
      checked: 110,
      parserCalls: 126,
      durationMs: 9000,
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
    expect(status['durationMs'], 16000);
    expect(status['liveServicesAllowed'], isFalse);
    final cells = status['cells'] as List;
    expect(cells, everyElement(containsPair('localOnlySafe', true)));
    expect(cells, everyElement(containsPair('safetyMissingFields', isEmpty)));
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

  test('generated run status recovers parser calls from chunk reports', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_generated_run_recover_parser_calls_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);
    final reportDir = Directory(
      'build/reports/electrical/residential/core/en-US/reports',
    )..createSync(recursive: true);
    final chunkOne = File('${reportDir.path}/chunks/001/run.json')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(jsonEncode({'parserCalls': 17}));
    final chunkTwo = File('${reportDir.path}/chunks/002/run.json')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(jsonEncode({'parserCalls': 19}));
    File(
      '${reportDir.path}/latest_generated_fixture_run.json',
    ).writeAsStringSync(
      jsonEncode({
        'fixturePath': 'build/generated_fixtures.json',
        'checked': 20,
        'failureCount': 0,
        'chunkReports': [
          {
            'checked': 10,
            'failureCount': 0,
            'durationMs': 1700,
            'reportPath': chunkOne.path,
          },
          {
            'checked': 10,
            'failureCount': 0,
            'durationMs': 1900,
            'reportPath': chunkTwo.path,
          },
        ],
        'liveServicesAllowed': false,
        'writesProductionCatalog': false,
        'firebaseWritesAllowed': false,
        'ocrCameraExpensesTouched': false,
      }),
    );

    final exit = runWorkSupplyParserQaGeneratedRunStatus(
      [
        '--report-root',
        'build/reports',
        '--trades',
        'electrical',
        '--tiers',
        'core',
        '--locales',
        'en-US',
        '--require-complete',
      ],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    final status = _readJson(
      'build/parser_qa_pipeline/core_generated_run_status.json',
    );
    final cells = status['cells'] as List;

    expect(exit, 0);
    expect(status['parserCalls'], 36);
    expect(status['durationMs'], 3600);
    expect(cells.single, containsPair('parserCalls', 36));
    expect(cells.single, containsPair('durationMs', 3600));
    expect(cells.single, containsPair('localOnlySafe', true));
  });

  test('generated run status fails complete cells without parser calls', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_generated_run_missing_parser_calls_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);
    _writeRun(
      'build/reports/electrical/residential/core/en-US/reports/latest_generated_fixture_run.json',
      checked: 110,
      parserCalls: 0,
    );

    final exit = runWorkSupplyParserQaGeneratedRunStatus(
      [
        '--report-root',
        'build/reports',
        '--trades',
        'electrical',
        '--tiers',
        'core',
        '--locales',
        'en-US',
        '--require-complete',
      ],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    final status = _readJson(
      'build/parser_qa_pipeline/core_generated_run_status.json',
    );
    final cells = status['cells'] as List;

    expect(exit, 1);
    expect(status['unsafeCells'], 1);
    expect(cells.single, containsPair('parserCalls', 0));
    expect(cells.single, containsPair('localOnlySafe', false));
  });

  test('generated run status fails cells below the minimum checked gate', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_generated_run_min_checked_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);
    _writeRun(
      'build/reports/electrical/residential/core/en-US/reports/latest_generated_fixture_run.json',
      checked: 6,
      parserCalls: 6,
    );

    final exit = runWorkSupplyParserQaGeneratedRunStatus(
      [
        '--report-root',
        'build/reports',
        '--trades',
        'electrical',
        '--tiers',
        'core',
        '--locales',
        'en-US',
        '--require-complete',
        '--min-checked-per-cell',
        '50',
      ],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    final status = _readJson(
      'build/parser_qa_pipeline/core_generated_run_status.json',
    );
    final cells = status['cells'] as List;

    expect(exit, 1);
    expect(status['underMinCheckedCells'], 1);
    expect(status['minCheckedPerCell'], 50);
    expect(cells.single, containsPair('underMinChecked', true));
    expect(cells.single, containsPair('minCheckedPerCell', 50));
    expect(cells.single, containsPair('localOnlySafe', false));
  });

  test('generated run status fails incomplete chunk reports', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_generated_run_incomplete_chunks_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);
    _writeRun(
      'build/reports/hvac/residential/core/en-US/reports/latest_generated_fixture_run.json',
      checked: 75,
      parserCalls: 91,
      plannedChunkCount: 4,
      completedChunkCount: 3,
    );

    final exit = runWorkSupplyParserQaGeneratedRunStatus(
      [
        '--report-root',
        'build/reports',
        '--trades',
        'hvac',
        '--tiers',
        'core',
        '--locales',
        'en-US',
        '--require-complete',
      ],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    final status = _readJson(
      'build/parser_qa_pipeline/core_generated_run_status.json',
    );
    final cells = status['cells'] as List;

    expect(exit, 1);
    expect(status['unsafeCells'], 1);
    expect(cells.single, containsPair('chunkRunComplete', false));
    expect(cells.single, containsPair('localOnlySafe', false));
  });

  test('generated run status fails timeout chunk reports', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_generated_run_timeout_chunks_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);
    _writeRun(
      'build/reports/electrical/residential/core/en-US/reports/latest_generated_fixture_run.json',
      checked: 6,
      parserCalls: 8,
      plannedChunkCount: 1,
      completedChunkCount: 1,
      nonZeroChunkExitCount: 1,
      timedOutChunkCount: 1,
    );

    final exit = runWorkSupplyParserQaGeneratedRunStatus(
      [
        '--report-root',
        'build/reports',
        '--trades',
        'electrical',
        '--tiers',
        'core',
        '--locales',
        'en-US',
        '--require-complete',
      ],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    final status = _readJson(
      'build/parser_qa_pipeline/core_generated_run_status.json',
    );
    final cells = status['cells'] as List;

    expect(exit, 1);
    expect(status['unsafeCells'], 1);
    expect(cells.single, containsPair('nonZeroChunkExitCount', 1));
    expect(cells.single, containsPair('timedOutChunkCount', 1));
    expect(cells.single, containsPair('localOnlySafe', false));
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
  int? plannedChunkCount,
  int? completedChunkCount,
  int? nonZeroChunkExitCount,
  int? timedOutChunkCount,
  int? durationMs,
}) {
  final file = File(path)..parent.createSync(recursive: true);
  final payload = <String, Object?>{
    'fixturePath': 'build/generated_fixtures.json',
    'checked': checked,
    'failureCount': failureCount,
    'parserCalls': parserCalls,
    'durationMs': ?durationMs,
    if (includeSafetyFields) ...{
      'liveServicesAllowed': liveServicesAllowed,
      'writesProductionCatalog': writesProductionCatalog,
      'firebaseWritesAllowed': firebaseWritesAllowed,
      'ocrCameraExpensesTouched': ocrCameraExpensesTouched,
    },
  };
  if (plannedChunkCount != null) {
    payload['plannedChunkCount'] = plannedChunkCount;
  }
  if (completedChunkCount != null) {
    payload['completedChunkCount'] = completedChunkCount;
  }
  if (nonZeroChunkExitCount != null) {
    payload['nonZeroChunkExitCount'] = nonZeroChunkExitCount;
  }
  if (timedOutChunkCount != null) {
    payload['timedOutChunkCount'] = timedOutChunkCount;
  }
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
