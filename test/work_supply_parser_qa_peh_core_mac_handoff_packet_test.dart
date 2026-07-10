import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/work_supply_parser_qa_peh_core_mac_handoff_packet.dart';

void main() {
  test('PEH Mac handoff packet bundles commands and refresh path', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_peh_mac_packet_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);

    _writeJson('build/parser_qa_pipeline/mac_wave.json', {
      'measurementCommandCount': 4,
      'rollupCommandCount': 2,
      'measurementCommands': [
        {'trade': 'electrical'},
        {'trade': 'electrical'},
        {'trade': 'hvac'},
        {'trade': 'hvac'},
      ],
      'rollupCommands': [
        {'trade': 'electrical'},
        {'trade': 'hvac'},
      ],
    });
    _writeJson('build/parser_qa_pipeline/windows.json', {
      'readyForMacMeasurementWave': true,
    });
    _writeJson('build/parser_qa_pipeline/peh_core_measurement_gap.json', {
      'totalRemainingChecked': 38,
      'nextTradesByRemainingGap': ['hvac'],
      'tradeGaps': [
        {'trade': 'hvac', 'remainingChecked': 38},
      ],
    });
    _writeJson('build/parser_qa_pipeline/peh_core_claim_readiness.json', {
      'blockingFindings': ['trade_not_ready:hvac', 'mac_wave_not_merge_ready'],
      'nextActions': ['Keep the hvac Mac wave running.'],
    });

    final stdout = _MemorySink();
    final exit = runWorkSupplyParserQaPehCoreMacHandoffPacket(
      const [
        '--branch',
        'feature/test',
        '--commit',
        'abc123',
        '--mac-wave',
        'build/parser_qa_pipeline/mac_wave.json',
        '--windows-status',
        'build/parser_qa_pipeline/windows.json',
      ],
      stdout: stdout,
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    final summary = _readJson(
      'build/parser_qa_pipeline/peh_core_mac_handoff_packet.json',
    );
    expect(summary['branch'], 'feature/test');
    expect(summary['commit'], 'abc123');
    expect(summary['inventoryExecutionBranch'], 'feature/test');
    expect(summary['inventoryExecutionCommit'], 'abc123');
    expect(summary['reusableBaselineBranch'], isNotEmpty);
    expect(summary['reusableCheckpointMarkdownPath'], 'docs/reusable_parsing_qa_checkpoint.md');
    expect(summary['reusableHandoffMarkerPath'], 'docs/reusable_parsing_qa_handoff_marker.md');
    expect(summary['measurementGapPath'], 'build/parser_qa_pipeline/peh_core_measurement_gap.json');
    expect(summary['claimReadinessPath'], 'build/parser_qa_pipeline/peh_core_claim_readiness.json');
    expect(summary['totalRemainingChecked'], 38);
    expect(summary['nextTradesByRemainingGap'].toString(), contains('hvac'));
    expect(summary['tradeGaps'].toString(), contains('remainingChecked'));
    expect(summary['claimBlockingFindings'].toString(), contains('trade_not_ready:hvac'));
    expect((summary['executionOrder'] as List).length, greaterThanOrEqualTo(4));
    expect(summary['measurementCommandCount'], 4);
    expect(summary['rollupCommandCount'], 2);
    expect(summary['refreshCommand'].toString(), contains('work_supply_parser_qa_peh_core_post_mac_refresh.dart'));
    expect(summary['refreshCommand'].toString(), contains('--root'));
    expect(stdout.content, contains('QA_PEH_CORE_MAC_HANDOFF_PACKET'));
  });

  test('PEH Mac handoff packet auto-resolves branch and commit from git', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_peh_mac_packet_git_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);

    Process.runSync('git', ['init']);
    Process.runSync('git', ['config', 'user.email', 'qa@example.com']);
    Process.runSync('git', ['config', 'user.name', 'QA Bot']);
    final marker = File('README.txt')..writeAsStringSync('packet');
    Process.runSync('git', ['add', marker.path]);
    Process.runSync('git', ['commit', '-m', 'init']);

    _writeJson('build/parser_qa_pipeline/mac_wave.json', {
      'measurementCommandCount': 4,
      'rollupCommandCount': 2,
      'measurementCommands': const [],
      'rollupCommands': const [],
    });
    _writeJson('build/parser_qa_pipeline/windows.json', {
      'readyForMacMeasurementWave': true,
    });

    final exit = runWorkSupplyParserQaPehCoreMacHandoffPacket(
      const [
        '--mac-wave',
        'build/parser_qa_pipeline/mac_wave.json',
        '--windows-status',
        'build/parser_qa_pipeline/windows.json',
      ],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    final summary = _readJson(
      'build/parser_qa_pipeline/peh_core_mac_handoff_packet.json',
    );
    expect(summary['branch'], isNotEmpty);
    expect((summary['commit'] as String).length, greaterThanOrEqualTo(7));
    expect(summary['inventoryExecutionBranch'], summary['branch']);
    expect(summary['inventoryExecutionCommit'], summary['commit']);
  });

  test('PEH Mac handoff packet blocks missing readiness baseline', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_peh_mac_packet_blocked_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);

    _writeJson('build/parser_qa_pipeline/mac_wave.json', {
      'measurementCommandCount': 4,
      'rollupCommandCount': 2,
      'measurementCommands': const [],
      'rollupCommands': const [],
    });
    _writeJson('build/parser_qa_pipeline/windows.json', {
      'readyForMacMeasurementWave': false,
    });

    final exit = runWorkSupplyParserQaPehCoreMacHandoffPacket(
      const [
        '--mac-wave',
        'build/parser_qa_pipeline/mac_wave.json',
        '--windows-status',
        'build/parser_qa_pipeline/windows.json',
      ],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 1);
    final summary = _readJson(
      'build/parser_qa_pipeline/peh_core_mac_handoff_packet.json',
    );
    expect(summary['readyForMacMeasurementWave'], isFalse);
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
