import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/work_supply_parser_qa_peh_core_handoff_readiness.dart';

void main() {
  test('PEH handoff readiness passes when checkpoint and wave artifacts align', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_peh_handoff_ready_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);

    _writeJson('build/parser_qa_pipeline/windows.json', {
      'readyForMacMeasurementWave': true,
      'readyToClaimNinetyPlus': false,
      'tradeCount': 3,
    });
    _writeJson('build/parser_qa_pipeline/mac.json', {
      'selectedTrades': ['hvac'],
      'measurementCommandCount': 2,
      'measurementCommands': [
        {'trade': 'hvac'},
        {'trade': 'hvac'},
      ],
      'rollupCommandCount': 1,
      'rollupCommands': [
        {'trade': 'hvac'},
      ],
      'plumbingFocusedRuntimeCommand': ['flutter', 'test'],
    });

    final stdout = _MemorySink();
    final exit = runWorkSupplyParserQaPehCoreHandoffReadiness(
      const [
        '--windows-status',
        'build/parser_qa_pipeline/windows.json',
        '--mac-wave',
        'build/parser_qa_pipeline/mac.json',
      ],
      stdout: stdout,
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    final summary = _readJson(
      'build/parser_qa_pipeline/peh_core_handoff_readiness.json',
    );
    expect(summary['handoffReady'], isTrue);
    expect(summary['readyForMacMeasurementWave'], isTrue);
    expect(summary['readyToClaimNinetyPlus'], isFalse);
    expect(summary['blockingFindings'], isEmpty);
    expect(stdout.content, contains('QA_PEH_CORE_HANDOFF_READINESS'));
  });

  test('PEH handoff readiness blocks incomplete checkpoint package', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_peh_handoff_blocked_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);

    _writeJson('build/parser_qa_pipeline/windows.json', {
      'readyForMacMeasurementWave': false,
      'readyToClaimNinetyPlus': false,
      'tradeCount': 2,
    });
    _writeJson('build/parser_qa_pipeline/mac.json', {
      'selectedTrades': ['hvac'],
      'measurementCommandCount': 3,
      'measurementCommands': [
        {'trade': 'hvac'},
      ],
      'rollupCommandCount': 1,
      'rollupCommands': <Map<String, Object?>>[],
      'plumbingFocusedRuntimeCommand': <String>[],
    });

    final exit = runWorkSupplyParserQaPehCoreHandoffReadiness(
      const [
        '--windows-status',
        'build/parser_qa_pipeline/windows.json',
        '--mac-wave',
        'build/parser_qa_pipeline/mac.json',
      ],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 1);
    final summary = _readJson(
      'build/parser_qa_pipeline/peh_core_handoff_readiness.json',
    );
    expect(summary['handoffReady'], isFalse);
    expect(
      summary['blockingFindings'].toString(),
      contains('windows_status_not_ready_for_mac_measurement_wave'),
    );
    expect(
      summary['blockingFindings'].toString(),
      contains('unexpected_trade_count'),
    );
  });
}

void _writeJson(String path, Map<String, Object?> value) {
  final file = File(path)..parent.createSync(recursive: true);
  file.writeAsStringSync(jsonEncode(value));
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
