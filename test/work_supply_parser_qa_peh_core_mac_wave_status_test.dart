import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/work_supply_parser_qa_peh_core_mac_wave_status.dart';

void main() {
  test('PEH Mac wave status passes when both rollups are merge-ready', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_peh_mac_wave_ready_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);

    _writeJson('build/parser_qa_pipeline/mac_wave.json', {
      'maxCases': 25,
      'minPassRate': 0.90,
      'measurementCommands': [
        {'trade': 'electrical'},
        {'trade': 'electrical'},
        {'trade': 'hvac'},
        {'trade': 'hvac'},
      ],
      'rollupCommands': [
        {
          'trade': 'electrical',
          'command': [
            'dart',
            'run',
            'tool/work_supply_parser_qa_generated_run_status.dart',
            '--output',
            'build/parser_qa_pipeline/mac_electrical.json',
          ],
        },
        {
          'trade': 'hvac',
          'command': [
            'dart',
            'run',
            'tool/work_supply_parser_qa_generated_run_status.dart',
            '--output',
            'build/parser_qa_pipeline/mac_hvac.json',
          ],
        },
      ],
    });
    _writeStatus('build/parser_qa_pipeline/mac_electrical.json', checkedTotal: 50);
    _writeStatus('build/parser_qa_pipeline/mac_hvac.json', checkedTotal: 50);

    final stdout = _MemorySink();
    final exit = runWorkSupplyParserQaPehCoreMacWaveStatus(
      const ['--mac-wave', 'build/parser_qa_pipeline/mac_wave.json'],
      stdout: stdout,
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    final summary = _readJson('build/parser_qa_pipeline/peh_core_mac_wave_status.json');
    expect(summary['readyToMergeIntoClaim'], isTrue);
    expect(summary['completedRollupCount'], 2);
    expect(summary['missingRollupCount'], 0);
    expect(summary['readyTradeCount'], 2);
    expect(stdout.content, contains('QA_PEH_CORE_MAC_WAVE_STATUS'));
  });

  test('PEH Mac wave status blocks missing or under-target rollups', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_peh_mac_wave_blocked_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);

    _writeJson('build/parser_qa_pipeline/mac_wave.json', {
      'maxCases': 25,
      'minPassRate': 0.90,
      'measurementCommands': [
        {'trade': 'electrical'},
        {'trade': 'electrical'},
        {'trade': 'hvac'},
        {'trade': 'hvac'},
      ],
      'rollupCommands': [
        {
          'trade': 'electrical',
          'command': [
            'dart',
            'run',
            'tool/work_supply_parser_qa_generated_run_status.dart',
            '--output',
            'build/parser_qa_pipeline/mac_electrical.json',
          ],
        },
        {
          'trade': 'hvac',
          'command': [
            'dart',
            'run',
            'tool/work_supply_parser_qa_generated_run_status.dart',
            '--output',
            'build/parser_qa_pipeline/mac_hvac.json',
          ],
        },
      ],
    });
    _writeStatus(
      'build/parser_qa_pipeline/mac_electrical.json',
      checkedTotal: 25,
      underMinCheckedCells: 1,
    );

    final exit = runWorkSupplyParserQaPehCoreMacWaveStatus(
      const ['--mac-wave', 'build/parser_qa_pipeline/mac_wave.json'],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 1);
    final summary = _readJson('build/parser_qa_pipeline/peh_core_mac_wave_status.json');
    expect(summary['readyToMergeIntoClaim'], isFalse);
    expect(summary['missingRollupCount'], 1);
    expect(summary['blockingFindings'].toString(), contains('rollup_not_merge_ready:electrical'));
    expect(summary['blockingFindings'].toString(), contains('missing_rollup_status:hvac'));
  });
}

void _writeJson(String path, Map<String, Object?> value) {
  final file = File(path)..parent.createSync(recursive: true);
  file.writeAsStringSync(jsonEncode(value));
}

void _writeStatus(
  String path, {
  required int checkedTotal,
  int failureCount = 0,
  double passRate = 1.0,
  int underMinCheckedCells = 0,
  int underMinPassRateCells = 0,
  bool liveServicesAllowed = false,
  bool writesProductionCatalog = false,
  bool firebaseWritesAllowed = false,
  bool ocrCameraExpensesTouched = false,
}) {
  _writeJson(path, {
    'checkedTotal': checkedTotal,
    'failureCount': failureCount,
    'passRate': passRate,
    'underMinCheckedCells': underMinCheckedCells,
    'underMinPassRateCells': underMinPassRateCells,
    'liveServicesAllowed': liveServicesAllowed,
    'writesProductionCatalog': writesProductionCatalog,
    'firebaseWritesAllowed': firebaseWritesAllowed,
    'ocrCameraExpensesTouched': ocrCameraExpensesTouched,
  });
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
