import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/work_supply_parser_qa_peh_core_mac_wave_commands.dart';

void main() {
  test('PEH Mac wave commands cover electrical and hvac locales plus rollups', () {
    final stdout = _MemorySink();

    final exit = runWorkSupplyParserQaPehCoreMacWaveCommands(
      const [
        '--trades',
        'electrical,hvac',
        '--max-cases',
        '25',
        '--chunk-size',
        '25',
        '--min-pass-rate',
        '0.90',
      ],
      stdout: stdout,
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    final summary = _extract(stdout.content);
    expect(summary['selectedTrades'], ['electrical', 'hvac']);
    expect(summary['selectionSource'], 'explicit_trades');
    expect(summary['measurementCommandCount'], 4);
    expect(summary['rollupCommandCount'], 2);
    expect(summary['maxCases'], 25);
    expect(summary['chunkSize'], 25);
    expect(summary['minPassRate'], 0.9);
    final measurementCommands = summary['measurementCommands'] as List<dynamic>;
    expect(
      measurementCommands.toString(),
      contains('build/parser_qa_generated/work_supply_parser/electrical/residential/core/en-US/generated_fixtures.json'),
    );
    expect(
      measurementCommands.toString(),
      contains('build/parser_qa_generated/work_supply_parser/hvac/residential/core/es-US/generated_fixtures.json'),
    );
    final rollups = summary['rollupCommands'] as List<dynamic>;
    expect(
      rollups.toString(),
      contains('build/parser_qa_pipeline/mac_electrical_core_generated_run_status_25.json'),
    );
    expect(
      rollups.toString(),
      contains('build/parser_qa_pipeline/mac_hvac_core_generated_run_status_25.json'),
    );
    expect(
      summary['plumbingFocusedRuntimeCommand'].toString(),
      contains('Menards PVC sanitary tee'),
    );
  });

  test('PEH Mac wave commands can write an artifact', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_peh_mac_wave_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final output = '${root.path}/mac_wave.json';

    final exit = runWorkSupplyParserQaPehCoreMacWaveCommands(
      ['--output', output, '--trades', 'electrical,hvac'],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    final summary =
        jsonDecode(File(output).readAsStringSync()) as Map<String, Object?>;
    expect(summary['measurementCommandCount'], 4);
    expect(summary['rollupCommandCount'], 2);
  });

  test('PEH Mac wave commands can narrow to the remaining gap trades', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_peh_mac_wave_gap_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);

    final gapFile = File('build/parser_qa_pipeline/peh_core_measurement_gap.json')
      ..parent.createSync(recursive: true);
    gapFile.writeAsStringSync(jsonEncode({
      'nextTradesByRemainingGap': ['hvac'],
    }));

    final stdout = _MemorySink();
    final exit = runWorkSupplyParserQaPehCoreMacWaveCommands(
      const [],
      stdout: stdout,
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    final summary = _extract(stdout.content);
    expect(summary['selectedTrades'], ['hvac']);
    expect(summary['selectionSource'], 'measurement_gap');
    expect(summary['measurementCommandCount'], 2);
    expect(summary['rollupCommandCount'], 1);
  });

  test('PEH Mac wave commands reject invalid pass-rate gates', () {
    final stderr = _MemorySink();

    final exit = runWorkSupplyParserQaPehCoreMacWaveCommands(
      const ['--min-pass-rate', '0'],
      stdout: _MemorySink(),
      stderr: stderr,
    );

    expect(exit, 64);
    expect(stderr.content, contains('--min-pass-rate'));
  });
}

Map<String, Object?> _extract(String output) {
  const marker = 'QA_PEH_CORE_MAC_WAVE_COMMANDS ';
  final start = output.indexOf(marker);
  expect(start, isNonNegative);
  final endMarker = '\nQA_PEH_CORE_MAC_WAVE_COMMANDS_ARTIFACT ';
  final end = output.indexOf(endMarker, start);
  final jsonText =
      end == -1
          ? output.substring(start + marker.length)
          : output.substring(start + marker.length, end);
  return jsonDecode(jsonText)
      as Map<String, Object?>;
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
