import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/work_supply_parser_qa_run_intelligence_report.dart';

void main() {
  test('run intelligence report summarizes healthy running wave', () async {
    final root = await Directory.systemTemp.createTemp(
      'maintainiac_run_intel_',
    );
    addTearDown(() => root.delete(recursive: true));
    final wave = Directory('${root.path}/wave-001')..createSync();
    final queue = Directory('${wave.path}/queue/q1')
      ..createSync(recursive: true);
    File('${wave.path}/wave_summary.json').writeAsStringSync(
      jsonEncode({
        'waveId': 'wave-001',
        'qaLayer': 'fixture-v1',
        'queueSummaryPath': '${queue.path}/summary.json',
        'liveServicesAllowed': false,
        'writesProductionCatalog': false,
        'firebaseWritesAllowed': false,
        'ocrCameraExpensesTouched': false,
      }),
    );
    File('${queue.path}/latest_status.json').writeAsStringSync(
      jsonEncode({
        'state': 'running',
        'cellCount': 24,
        'completedCellCount': 12,
        'failedCellCount': 0,
        'activeCellId': 'electrical_residential_standard_en_US',
        'liveServicesAllowed': false,
        'writesProductionCatalog': false,
      }),
    );
    File('${wave.path}/duration_report.json').writeAsStringSync(
      jsonEncode({
        'averageDurationMs': 140000,
        'slowestCells': [
          {'durationMs': 190000},
        ],
      }),
    );
    File('${wave.path}/batch_size_advice.json').writeAsStringSync(
      jsonEncode({
        'recommendation': 'increase',
        'recommendedFixtureRunLimit': 118,
      }),
    );

    final stdout = _MemorySink();
    final exit = runWorkSupplyParserQaRunIntelligenceReport(
      ['--root', root.path, '--wave-id', 'wave-001'],
      stdout: stdout,
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    final report =
        jsonDecode(
              File(
                '${wave.path}/run_intelligence_report.json',
              ).readAsStringSync(),
            )
            as Map;
    expect(report['completedCellCount'], 12);
    expect(report['failedCellCount'], 0);
    expect(report['unsafe'], isFalse);
    expect(report['recommendedFixtureRunLimit'], 118);
    expect(report['nextActions'].toString(), contains('Continue queue'));
    expect(
      File('${wave.path}/run_intelligence_report.txt').existsSync(),
      isTrue,
    );
    expect(stdout.content, contains('QA_RUN_INTELLIGENCE_REPORT_ARTIFACT'));
  });

  test(
    'run intelligence report exits nonzero for failed or unsafe waves',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'maintainiac_run_intel_failed_',
      );
      addTearDown(() => root.delete(recursive: true));
      final wave = Directory('${root.path}/wave-failed')..createSync();
      File('${wave.path}/wave_plan.json').writeAsStringSync(
        jsonEncode({
          'waveId': 'wave-failed',
          'liveServicesAllowed': false,
          'writesProductionCatalog': false,
          'firebaseWritesAllowed': false,
          'ocrCameraExpensesTouched': false,
        }),
      );
      final queue = Directory('${wave.path}/queue')..createSync();
      File('${queue.path}/latest_status.json').writeAsStringSync(
        jsonEncode({
          'state': 'failed',
          'cellCount': 2,
          'completedCellCount': 2,
          'failedCellCount': 1,
          'liveServicesAllowed': false,
          'writesProductionCatalog': true,
        }),
      );

      final exit = runWorkSupplyParserQaRunIntelligenceReport(
        ['--root', root.path, '--wave-id', 'wave-failed'],
        stdout: _MemorySink(),
        stderr: _MemorySink(),
      );

      expect(exit, 1);
      final report =
          jsonDecode(
                File(
                  '${wave.path}/run_intelligence_report.json',
                ).readAsStringSync(),
              )
              as Map;
      expect(report['unsafe'], isTrue);
      expect(report['nextActions'].toString(), contains('Stop'));
    },
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
