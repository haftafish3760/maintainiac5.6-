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
    expect(summary['measurementCommandCount'], 4);
    expect(summary['rollupCommandCount'], 2);
    expect(summary['refreshCommand'].toString(), contains('work_supply_parser_qa_peh_core_refresh.dart'));
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
