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
        'dryRun': false,
        'liveServicesAllowed': false,
        'writesProductionCatalog': false,
        'firebaseWritesAllowed': false,
        'ocrCameraExpensesTouched': false,
        'results': [],
      }),
    );

    final stdout = _MemorySink();
    final exit = runWorkSupplyParserQaBackgroundQueueStatus(
      ['--root', root.path, '--queue-id', 'queue-a'],
      stdout: stdout,
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    expect(stdout.content, contains('QA_BACKGROUND_QUEUE_STATUS'));
    expect(stdout.content, contains('"state": "running"'));
    expect(stdout.content, contains('plumbing_residential_standard_es_US'));
    expect(stdout.content, contains('firebaseWritesAllowed'));
    expect(stdout.content, contains('ocrCameraExpensesTouched'));
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
