import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/work_supply_parser_qa_batch_size_advisor.dart';

void main() {
  test('batch size advisor recommends increasing when cells are fast', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_batch_advisor_fast_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final report = _writeDurationReport(
      root,
      cellCount: 8,
      averageDurationMs: 100000,
      slowestDurationMs: 120000,
    );
    final output = '${root.path}/advice.json';

    final exit = runWorkSupplyParserQaBatchSizeAdvisor(
      [
        '--duration-report',
        report.path,
        '--current-fixture-run-limit',
        '25',
        '--target-cell-ms',
        '300000',
        '--output',
        output,
      ],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    final advice = jsonDecode(File(output).readAsStringSync()) as Map;
    expect(advice['recommendation'], 'increase');
    expect(advice['recommendedFixtureRunLimit'], greaterThan(25));
    expect(advice['liveServicesAllowed'], false);
  });

  test('batch size advisor avoids increasing over slow-cell budget', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_batch_advisor_slow_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final report = _writeDurationReport(
      root,
      cellCount: 8,
      averageDurationMs: 240000,
      slowestDurationMs: 450000,
    );
    final output = '${root.path}/advice.json';

    final exit = runWorkSupplyParserQaBatchSizeAdvisor(
      [
        '--duration-report',
        report.path,
        '--current-fixture-run-limit',
        '25',
        '--target-cell-ms',
        '300000',
        '--output',
        output,
      ],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    final advice = jsonDecode(File(output).readAsStringSync()) as Map;
    expect(advice['recommendation'], isNot('increase'));
    expect(advice['recommendedFixtureRunLimit'], lessThanOrEqualTo(25));
    expect(advice['reason'], contains('above the target budget'));
  });

  test('batch size advisor holds with too little completed evidence', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_batch_advisor_small_sample_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final report = _writeDurationReport(
      root,
      cellCount: 1,
      averageDurationMs: 100000,
      slowestDurationMs: 100000,
    );
    final output = '${root.path}/advice.json';

    final exit = runWorkSupplyParserQaBatchSizeAdvisor(
      [
        '--duration-report',
        report.path,
        '--current-fixture-run-limit',
        '45',
        '--target-cell-ms',
        '300000',
        '--min-completed-cells',
        '6',
        '--output',
        output,
      ],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    final advice = jsonDecode(File(output).readAsStringSync()) as Map;
    expect(advice['recommendation'], 'hold');
    expect(advice['recommendedFixtureRunLimit'], 45);
    expect(advice['reason'], contains('at least 6 completed cells'));
  });
}

File _writeDurationReport(
  Directory root, {
  required int cellCount,
  required int averageDurationMs,
  required int slowestDurationMs,
}) {
  return File('${root.path}/duration_report.json')..writeAsStringSync(
    jsonEncode({
      'cellCount': cellCount,
      'averageDurationMs': averageDurationMs,
      'slowestCells': [
        {
          'cellId': 'slowest',
          'trade': 'plumbing',
          'tier': 'core',
          'localePackId': 'en-US',
          'durationMs': slowestDurationMs,
          'exitCode': 0,
        },
      ],
    }),
  );
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
