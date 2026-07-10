import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/work_supply_parser_qa_duration_report.dart';

void main() {
  test('duration report summarizes slowest cells', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_duration_report_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final summary = File('${root.path}/summary.json')
      ..writeAsStringSync(
        jsonEncode({
          'results': [
            {
              'cellId': 'fast',
              'trade': 'plumbing',
              'tier': 'core',
              'localePackId': 'en-US',
              'durationMs': 100,
              'exitCode': 0,
            },
            {
              'cellId': 'slow',
              'trade': 'hvac',
              'tier': 'complete',
              'localePackId': 'es-US',
              'durationMs': 900,
              'exitCode': 0,
            },
          ],
        }),
      );
    final output = '${root.path}/duration.json';
    final stdout = _MemorySink();

    final exit = runWorkSupplyParserQaDurationReport(
      ['--summary', summary.path, '--output', output],
      stdout: stdout,
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    expect(stdout.content, contains('QA_DURATION_REPORT'));
    final report = jsonDecode(File(output).readAsStringSync()) as Map;
    expect(report['cellCount'], 2);
    expect(report['totalDurationMs'], 1000);
    expect(report['averageDurationMs'], 500);
    expect(((report['slowestCells'] as List).first as Map)['cellId'], 'slow');
  });

  test('duration report can read in-progress queue status results', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_duration_status_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final status = File('${root.path}/latest_status.json')
      ..writeAsStringSync(
        jsonEncode({
          'state': 'running',
          'completedCellCount': 1,
          'activeCellId': 'electrical_residential_complete_en_US',
          'results': [
            {
              'cellId': 'plumbing_residential_core_en_US',
              'trade': 'plumbing',
              'tier': 'core',
              'localePackId': 'en-US',
              'durationMs': 1200,
              'exitCode': 0,
            },
          ],
        }),
      );
    final output = '${root.path}/duration_status.json';

    final exit = runWorkSupplyParserQaDurationReport(
      ['--summary', status.path, '--output', output],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    final report = jsonDecode(File(output).readAsStringSync()) as Map;
    expect(report['cellCount'], 1);
    expect(report['totalDurationMs'], 1200);
    expect(((report['slowestCells'] as List).single as Map)['tier'], 'core');
  });
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
