import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/work_supply_parser_qa_peh_core_merged_status_rollup.dart';

void main() {
  test('PEH merged status rollup clears when all trades hit targets', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_peh_merged_rollup_ready_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);

    _writeStatus('build/parser_qa_pipeline/plumbing.json', checkedTotal: 100);
    _writeStatus('build/parser_qa_pipeline/electrical.json', checkedTotal: 50);
    _writeStatus('build/parser_qa_pipeline/hvac.json', checkedTotal: 50);

    final stdout = _MemorySink();
    final exit = runWorkSupplyParserQaPehCoreMergedStatusRollup(
      const [
        '--plumbing-status',
        'build/parser_qa_pipeline/plumbing.json',
        '--electrical-status',
        'build/parser_qa_pipeline/electrical.json',
        '--hvac-status',
        'build/parser_qa_pipeline/hvac.json',
      ],
      stdout: stdout,
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    final rollup = _readJson(
      'build/parser_qa_pipeline/peh_core_merged_status_rollup.json',
    );
    expect(rollup['underTargetTradeCount'], 0);
    expect(rollup['readyToClaimNinetyPlus'], isTrue);
    expect(stdout.content, contains('QA_PEH_CORE_MERGED_STATUS_ROLLUP'));
  });

  test('PEH merged status rollup blocks missing or under-target Mac trades', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_peh_merged_rollup_blocked_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);

    _writeStatus('build/parser_qa_pipeline/plumbing.json', checkedTotal: 100);
    _writeStatus(
      'build/parser_qa_pipeline/electrical.json',
      checkedTotal: 25,
      firebaseWritesAllowed: true,
    );

    final exit = runWorkSupplyParserQaPehCoreMergedStatusRollup(
      const [
        '--plumbing-status',
        'build/parser_qa_pipeline/plumbing.json',
        '--electrical-status',
        'build/parser_qa_pipeline/electrical.json',
        '--hvac-status',
        'build/parser_qa_pipeline/missing.json',
      ],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 2);
    final rollup = _readJson(
      'build/parser_qa_pipeline/peh_core_merged_status_rollup.json',
    );
    expect(rollup['missingTradeCount'], 1);
    expect(rollup['unsafeTradeCount'], 2);
    expect(rollup['readyToClaimNinetyPlus'], isFalse);
  });
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
}) {
  final file = File(path)..parent.createSync(recursive: true);
  file.writeAsStringSync(
    jsonEncode({
      'checkedTotal': checkedTotal,
      'failureCount': failureCount,
      'passRate': passRate,
      'parserCalls': parserCalls,
      'unsafeCells': unsafeCells,
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
