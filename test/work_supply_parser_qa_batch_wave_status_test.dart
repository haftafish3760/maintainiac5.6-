import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/work_supply_parser_qa_batch_wave_status.dart';

void main() {
  test('batch wave status reads queue progress and safety flags', () async {
    final root = await Directory.systemTemp.createTemp(
      'maintainiac_batch_wave_status_',
    );
    addTearDown(() => root.delete(recursive: true));
    final wave = Directory('${root.path}/wave-001')..createSync();
    final queue = Directory('${wave.path}/queue/queue-001')
      ..createSync(recursive: true);
    File('${wave.path}/wave_summary.json').writeAsStringSync(
      jsonEncode({
        'waveId': 'wave-001',
        'qaLayer': 'merchant-abbreviation-v1',
        'accumulatedWaveIds': ['wave-000', 'wave-001'],
        'dryRun': false,
        'queueSummaryPath': '${queue.path}/summary.json',
        'liveServicesAllowed': false,
        'writesProductionCatalog': false,
        'firebaseWritesAllowed': false,
        'ocrCameraExpensesTouched': false,
      }),
    );
    File('${queue.path}/summary.json').writeAsStringSync(jsonEncode({}));
    File('${queue.path}/latest_status.json').writeAsStringSync(
      jsonEncode({
        'state': 'running',
        'cellCount': 6,
        'completedCellCount': 4,
        'failedCellCount': 0,
        'activeCellId': 'hvac_residential_core_en_US',
        'liveServicesAllowed': false,
        'writesProductionCatalog': false,
      }),
    );

    final stdout = _MemorySink();
    final exit = runWorkSupplyParserQaBatchWaveStatus(
      ['--root', root.path, '--wave-id', 'wave-001'],
      stdout: stdout,
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    expect(stdout.content, contains('QA_BATCH_WAVE_STATUS'));
    expect(stdout.content, contains('merchant-abbreviation-v1'));
    expect(stdout.content, contains('hvac_residential_core_en_US'));
    expect(stdout.content, contains('"completedCellCount": 4'));
    expect(stdout.content, contains('"firebaseWritesAllowed": false'));
  });

  test('batch wave status rejects failed queue cells', () async {
    final root = await Directory.systemTemp.createTemp(
      'maintainiac_batch_wave_status_failed_',
    );
    addTearDown(() => root.delete(recursive: true));
    final wave = Directory('${root.path}/wave-failed')..createSync();
    File('${wave.path}/wave_summary.json').writeAsStringSync(
      jsonEncode({
        'waveId': 'wave-failed',
        'queueSummaryPath': '',
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
        'writesProductionCatalog': false,
      }),
    );

    final exit = runWorkSupplyParserQaBatchWaveStatus(
      ['--root', root.path, '--wave-id', 'wave-failed'],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 1);
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
