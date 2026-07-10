import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/work_supply_parser_qa_background_queue_status.dart';

void main() {
  test('background queue status reads latest status artifact', () async {
    final root = await Directory.systemTemp.createTemp(
      'maintainiac_background_queue_status_',
    );
    addTearDown(() => root.delete(recursive: true));
    final queue = Directory('${root.path}/queue-a')..createSync();
    File('${queue.path}/latest_status.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'queueId': 'queue-a',
        'state': 'running',
        'cellCount': 4,
        'completedCellCount': 2,
        'failedCellCount': 0,
        'activeCellId': 'plumbing_residential_standard_es_US',
        'activeCellStartedAtIso': '2026-07-04T14:00:00.000Z',
        'activeCellElapsedMs': 0,
        'dryRun': false,
        'liveServicesAllowed': false,
        'writesProductionCatalog': false,
        'firebaseWritesAllowed': false,
        'ocrCameraExpensesTouched': false,
        'results': [
          {
            'cellId': 'plumbing_residential_core_en_US',
            'exitCode': 0,
            'liveServicesAllowed': false,
            'writesProductionCatalog': false,
            'firebaseWritesAllowed': false,
            'ocrCameraExpensesTouched': false,
          },
        ],
      }),
    );

    final stdout = _MemorySink();
    final exit = runWorkSupplyParserQaBackgroundQueueStatus(
      ['--root', root.path, '--queue-id', 'queue-a'],
      stdout: stdout,
      stderr: _MemorySink(),
      now: DateTime.parse('2026-07-04T14:03:00.000Z'),
    );

    expect(exit, 0);
    expect(stdout.content, contains('QA_BACKGROUND_QUEUE_STATUS'));
    expect(stdout.content, contains('"state": "running"'));
    expect(stdout.content, contains('plumbing_residential_standard_es_US'));
    expect(stdout.content, contains('"activeCellElapsedMs": 180000'));
    expect(stdout.content, contains('firebaseWritesAllowed'));
    expect(stdout.content, contains('ocrCameraExpensesTouched'));
    expect(stdout.content, contains('"unsafeFlagCount": 0'));
  });

  test('background queue status fails unsafe live-service evidence', () async {
    final root = await Directory.systemTemp.createTemp(
      'maintainiac_background_queue_status_unsafe_',
    );
    addTearDown(() => root.delete(recursive: true));
    final queue = Directory('${root.path}/queue-unsafe')..createSync();
    File('${queue.path}/latest_status.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'queueId': 'queue-unsafe',
        'state': 'complete',
        'cellCount': 1,
        'completedCellCount': 1,
        'failedCellCount': 0,
        'dryRun': false,
        'liveServicesAllowed': false,
        'writesProductionCatalog': false,
        'firebaseWritesAllowed': true,
        'ocrCameraExpensesTouched': false,
        'results': [
          {
            'cellId': 'electrical_residential_core_es_US',
            'exitCode': 0,
            'liveServicesAllowed': false,
            'writesProductionCatalog': true,
            'firebaseWritesAllowed': false,
            'ocrCameraExpensesTouched': false,
          },
        ],
      }),
    );

    final stdout = _MemorySink();
    final stderr = _MemorySink();
    final exit = runWorkSupplyParserQaBackgroundQueueStatus(
      ['--root', root.path, '--queue-id', 'queue-unsafe'],
      stdout: stdout,
      stderr: stderr,
    );

    expect(exit, 1);
    expect(stdout.content, contains('"unsafeFlagCount": 2'));
    expect(stdout.content, contains('top_level:firebaseWritesAllowed'));
    expect(
      stdout.content,
      contains('electrical_residential_core_es_US:writesProductionCatalog'),
    );
    expect(stderr.content, contains('Unsafe background queue evidence'));
  });

  test('background queue status fails stale active cell evidence', () async {
    final root = await Directory.systemTemp.createTemp(
      'maintainiac_background_queue_status_stale_',
    );
    addTearDown(() => root.delete(recursive: true));
    final queue = Directory('${root.path}/queue-stale')..createSync();
    File('${queue.path}/latest_status.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'queueId': 'queue-stale',
        'state': 'running',
        'cellCount': 6,
        'completedCellCount': 0,
        'failedCellCount': 0,
        'activeCellId': 'plumbing_residential_core_en_US',
        'activeCellStartedAtIso': '2026-07-04T14:00:00.000Z',
        'activeCellElapsedMs': 0,
        'dryRun': false,
        'liveServicesAllowed': false,
        'writesProductionCatalog': false,
        'firebaseWritesAllowed': false,
        'ocrCameraExpensesTouched': false,
        'results': [],
      }),
    );

    final stdout = _MemorySink();
    final stderr = _MemorySink();
    final exit = runWorkSupplyParserQaBackgroundQueueStatus(
      [
        '--root',
        root.path,
        '--queue-id',
        'queue-stale',
        '--max-active-cell-ms',
        '900000',
      ],
      stdout: stdout,
      stderr: stderr,
      now: DateTime.parse('2026-07-04T14:20:00.000Z'),
    );

    expect(exit, 1);
    expect(stdout.content, contains('"activeCellStale": true'));
    expect(stdout.content, contains('"maxActiveCellMs": 900000'));
    expect(stdout.content, contains('"activeCellElapsedMs": 1200000'));
    expect(stderr.content, contains('Stale active background queue cell'));
  });

  test('background queue status fails stale status update evidence', () async {
    final root = await Directory.systemTemp.createTemp(
      'maintainiac_background_queue_status_age_',
    );
    addTearDown(() => root.delete(recursive: true));
    final queue = Directory('${root.path}/queue-status-age')..createSync();
    File('${queue.path}/latest_status.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'queueId': 'queue-status-age',
        'state': 'running',
        'cellCount': 6,
        'completedCellCount': 0,
        'failedCellCount': 0,
        'updatedAtIso': '2026-07-04T14:00:00.000Z',
        'dryRun': false,
        'liveServicesAllowed': false,
        'writesProductionCatalog': false,
        'firebaseWritesAllowed': false,
        'ocrCameraExpensesTouched': false,
        'results': [],
      }),
    );

    final stdout = _MemorySink();
    final stderr = _MemorySink();
    final exit = runWorkSupplyParserQaBackgroundQueueStatus(
      [
        '--root',
        root.path,
        '--queue-id',
        'queue-status-age',
        '--max-status-age-ms',
        '900000',
      ],
      stdout: stdout,
      stderr: stderr,
      now: DateTime.parse('2026-07-04T14:20:00.000Z'),
    );

    expect(exit, 1);
    expect(stdout.content, contains('"statusStale": true'));
    expect(stdout.content, contains('"maxStatusAgeMs": 900000'));
    expect(stdout.content, contains('"statusAgeMs": 1200000'));
    expect(stderr.content, contains('Stale background queue status'));
  });

  test('background queue status fails when no artifact exists', () {
    final stderr = _MemorySink();
    final exit = runWorkSupplyParserQaBackgroundQueueStatus(
      ['--root', 'not-a-real-status-root'],
      stdout: _MemorySink(),
      stderr: stderr,
    );

    expect(exit, 66);
    expect(stderr.content, contains('No background queue status found'));
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
