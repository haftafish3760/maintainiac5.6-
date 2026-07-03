import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/work_supply_parser_qa_batch_wave_report.dart';

void main() {
  test('batch wave report aggregates complete safe waves', () async {
    final root = await Directory.systemTemp.createTemp(
      'maintainiac_batch_wave_report_',
    );
    addTearDown(() => root.delete(recursive: true));
    _writeWave(
      root: root,
      waveId: 'core-wave',
      cells: 6,
      completed: 6,
      failed: 0,
    );
    _writeWave(
      root: root,
      waveId: 'standard-wave',
      cells: 6,
      completed: 6,
      failed: 0,
    );
    final output = '${root.path}/report.json';
    final stdout = _MemorySink();

    final exit = runWorkSupplyParserQaBatchWaveReport(
      [
        '--root',
        root.path,
        '--wave-ids',
        'core-wave,standard-wave',
        '--output',
        output,
      ],
      stdout: stdout,
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    expect(stdout.content, contains('QA_BATCH_WAVE_REPORT'));
    final report = jsonDecode(File(output).readAsStringSync()) as Map;
    expect(report['waveCount'], 2);
    expect(report['totalCellCount'], 12);
    expect(report['completedCellCount'], 12);
    expect(report['failedCellCount'], 0);
    expect(report['allComplete'], true);
    expect(report['unsafe'], false);
  });

  test('batch wave report fails when a wave has failed cells', () async {
    final root = await Directory.systemTemp.createTemp(
      'maintainiac_batch_wave_report_failed_',
    );
    addTearDown(() => root.delete(recursive: true));
    _writeWave(
      root: root,
      waveId: 'failed-wave',
      cells: 6,
      completed: 6,
      failed: 1,
    );

    final exit = runWorkSupplyParserQaBatchWaveReport(
      ['--root', root.path, '--wave-ids', 'failed-wave'],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 1);
  });
}

void _writeWave({
  required Directory root,
  required String waveId,
  required int cells,
  required int completed,
  required int failed,
}) {
  final wave = Directory('${root.path}/$waveId')..createSync();
  final queue = Directory('${wave.path}/queue')..createSync();
  File('${wave.path}/wave_summary.json').writeAsStringSync(
    jsonEncode({
      'waveId': waveId,
      'qaLayer': 'generated-fixture-first-round',
      'accumulatedWaveIds': [waveId],
      'dryRun': false,
      'queueSummaryPath': '',
      'liveServicesAllowed': false,
      'writesProductionCatalog': false,
      'firebaseWritesAllowed': false,
      'ocrCameraExpensesTouched': false,
    }),
  );
  File('${queue.path}/latest_status.json').writeAsStringSync(
    jsonEncode({
      'state': failed == 0 && completed == cells ? 'complete' : 'failed',
      'cellCount': cells,
      'completedCellCount': completed,
      'failedCellCount': failed,
      'liveServicesAllowed': false,
      'writesProductionCatalog': false,
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
