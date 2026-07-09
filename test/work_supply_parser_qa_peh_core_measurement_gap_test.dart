import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/work_supply_parser_qa_peh_core_measurement_gap.dart';

void main() {
  test('PEH measurement gap reports remaining checked coverage by trade', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_peh_measurement_gap_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);

    _writeJson('build/parser_qa_pipeline/windows.json', {
      'readyToClaimNinetyPlus': false,
      'readyForMacMeasurementWave': true,
      'targetChecked': {'plumbing': 100, 'electrical': 50, 'hvac': 50},
      'trades': [
        {
          'trade': 'plumbing',
          'checkedTotal': 100,
          'sampleSizedEvidence': false,
          'readyToClaimNinetyPlus': true,
        },
        {
          'trade': 'electrical',
          'checkedTotal': 12,
          'sampleSizedEvidence': true,
          'readyToClaimNinetyPlus': false,
        },
        {
          'trade': 'hvac',
          'checkedTotal': 12,
          'sampleSizedEvidence': true,
          'readyToClaimNinetyPlus': false,
        },
      ],
    });

    final stdout = _MemorySink();
    final exit = runWorkSupplyParserQaPehCoreMeasurementGap(
      const ['--windows-status', 'build/parser_qa_pipeline/windows.json'],
      stdout: stdout,
      stderr: _MemorySink(),
    );

    expect(exit, 1);
    final summary = _readJson(
      'build/parser_qa_pipeline/peh_core_measurement_gap.json',
    );
    expect(summary['totalRemainingChecked'], 76);
    expect(summary['nextTradesByRemainingGap'].toString(), contains('electrical'));
    expect(summary['nextTradesByRemainingGap'].toString(), contains('hvac'));
    expect(stdout.content, contains('QA_PEH_CORE_MEASUREMENT_GAP'));
  });

  test('PEH measurement gap returns zero when all targets are met', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_peh_measurement_gap_ready_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);

    _writeJson('build/parser_qa_pipeline/windows.json', {
      'readyToClaimNinetyPlus': true,
      'readyForMacMeasurementWave': true,
      'targetChecked': {'plumbing': 100, 'electrical': 50, 'hvac': 50},
      'trades': [
        {
          'trade': 'plumbing',
          'checkedTotal': 100,
          'sampleSizedEvidence': false,
          'readyToClaimNinetyPlus': true,
        },
        {
          'trade': 'electrical',
          'checkedTotal': 50,
          'sampleSizedEvidence': false,
          'readyToClaimNinetyPlus': true,
        },
        {
          'trade': 'hvac',
          'checkedTotal': 50,
          'sampleSizedEvidence': false,
          'readyToClaimNinetyPlus': true,
        },
      ],
    });

    final exit = runWorkSupplyParserQaPehCoreMeasurementGap(
      const ['--windows-status', 'build/parser_qa_pipeline/windows.json'],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    final summary = _readJson(
      'build/parser_qa_pipeline/peh_core_measurement_gap.json',
    );
    expect(summary['totalRemainingChecked'], 0);
    expect(summary['nextTradesByRemainingGap'], isEmpty);
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
