import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/work_supply_parser_qa_peh_core_refresh.dart';

void main() {
  test('PEH refresh regenerates downstream artifacts from ready inputs', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_peh_refresh_ready_',
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
          'command': ['dart', 'run', '--output', 'build/parser_qa_pipeline/mac_electrical.json'],
        },
        {
          'trade': 'hvac',
          'command': ['dart', 'run', '--output', 'build/parser_qa_pipeline/mac_hvac.json'],
        },
      ],
    });
    _writeJson('build/parser_qa_pipeline/windows.json', {
      'trades': [
        {
          'trade': 'plumbing',
          'checkedTotal': 100,
          'failureCount': 0,
          'passRate': 1.0,
          'readyToClaimNinetyPlus': true,
        },
      ],
    });
    _writeStatus('build/parser_qa_pipeline/plumbing.json', checkedTotal: 100);
    _writeStatus('build/parser_qa_pipeline/mac_electrical.json', checkedTotal: 50);
    _writeStatus('build/parser_qa_pipeline/mac_hvac.json', checkedTotal: 50);

    final stdout = _MemorySink();
    final exit = runWorkSupplyParserQaPehCoreRefresh(
      const [
        '--mac-wave',
        'build/parser_qa_pipeline/mac_wave.json',
        '--windows-status',
        'build/parser_qa_pipeline/windows.json',
        '--plumbing-status',
        'build/parser_qa_pipeline/plumbing.json',
        '--electrical-status',
        'build/parser_qa_pipeline/mac_electrical.json',
        '--hvac-status',
        'build/parser_qa_pipeline/mac_hvac.json',
      ],
      stdout: stdout,
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    expect(
      _readJson('build/parser_qa_pipeline/peh_core_mac_wave_status.json')['readyToMergeIntoClaim'],
      isTrue,
    );
    expect(
      _readJson('build/parser_qa_pipeline/peh_core_merged_status_rollup.json')['readyToClaimNinetyPlus'],
      isTrue,
    );
    expect(
      _readJson('build/parser_qa_pipeline/peh_core_claim_readiness.json')['readyToClaimNinetyPlus'],
      isTrue,
    );
    expect(stdout.content, contains('QA_PEH_CORE_REFRESH'));
  });

  test('PEH refresh preserves blocked state when Mac evidence is missing', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_peh_refresh_blocked_',
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
          'command': ['dart', 'run', '--output', 'build/parser_qa_pipeline/mac_electrical.json'],
        },
        {
          'trade': 'hvac',
          'command': ['dart', 'run', '--output', 'build/parser_qa_pipeline/mac_hvac.json'],
        },
      ],
    });
    _writeJson('build/parser_qa_pipeline/windows.json', {
      'trades': [
        {
          'trade': 'plumbing',
          'checkedTotal': 100,
          'failureCount': 0,
          'passRate': 1.0,
          'readyToClaimNinetyPlus': true,
        },
      ],
    });
    _writeStatus('build/parser_qa_pipeline/plumbing.json', checkedTotal: 100);

    final exit = runWorkSupplyParserQaPehCoreRefresh(
      const [
        '--mac-wave',
        'build/parser_qa_pipeline/mac_wave.json',
        '--windows-status',
        'build/parser_qa_pipeline/windows.json',
        '--plumbing-status',
        'build/parser_qa_pipeline/plumbing.json',
        '--electrical-status',
        'build/parser_qa_pipeline/mac_electrical.json',
        '--hvac-status',
        'build/parser_qa_pipeline/mac_hvac.json',
      ],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, greaterThan(0));
    expect(
      _readJson('build/parser_qa_pipeline/peh_core_mac_wave_status.json')['readyToMergeIntoClaim'],
      isFalse,
    );
    expect(
      _readJson('build/parser_qa_pipeline/peh_core_claim_readiness.json')['readyToClaimNinetyPlus'],
      isFalse,
    );
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
  int parserCalls = 12,
  bool liveServicesAllowed = false,
  bool writesProductionCatalog = false,
  bool firebaseWritesAllowed = false,
  bool ocrCameraExpensesTouched = false,
  int unsafeCells = 0,
  int underMinCheckedCells = 0,
  int underMinPassRateCells = 0,
}) {
  final file = File(path)..parent.createSync(recursive: true);
  file.writeAsStringSync(
    jsonEncode({
      'checkedTotal': checkedTotal,
      'failureCount': failureCount,
      'passRate': passRate,
      'parserCalls': parserCalls,
      'unsafeCells': unsafeCells,
      'underMinCheckedCells': underMinCheckedCells,
      'underMinPassRateCells': underMinPassRateCells,
      'liveServicesAllowed': liveServicesAllowed,
      'writesProductionCatalog': writesProductionCatalog,
      'firebaseWritesAllowed': firebaseWritesAllowed,
      'ocrCameraExpensesTouched': ocrCameraExpensesTouched,
    }),
  );
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
