import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/work_supply_parser_qa_queue_watchdog.dart';

void main() {
  test('queue watchdog passes for fresh healthy running status', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_queue_watchdog_fresh_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final status = _writeStatus(
      root,
      updatedAt: DateTime.now().toUtc(),
      activeCellElapsedMs: 120000,
    );
    final output = '${root.path}/watchdog.json';

    final exit = runWorkSupplyParserQaQueueWatchdog(
      [
        '--status',
        status.path,
        '--max-status-age-ms',
        '900000',
        '--max-active-cell-ms',
        '900000',
        '--output',
        output,
      ],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    final report = jsonDecode(File(output).readAsStringSync()) as Map;
    expect(report['healthy'], true);
    expect(report['findings'], isEmpty);
  });

  test('queue watchdog fails stale active cells', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_queue_watchdog_stale_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final status = _writeStatus(
      root,
      updatedAt: DateTime.now().toUtc(),
      activeCellElapsedMs: 950000,
    );
    final output = '${root.path}/watchdog.json';

    final exit = runWorkSupplyParserQaQueueWatchdog(
      [
        '--status',
        status.path,
        '--max-status-age-ms',
        '900000',
        '--max-active-cell-ms',
        '900000',
        '--output',
        output,
      ],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 1);
    final report = jsonDecode(File(output).readAsStringSync()) as Map;
    expect(report['healthy'], false);
    expect(report['findings'], contains('active_cell_stale'));
  });

  test('queue watchdog fails stale status updates', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_queue_watchdog_status_stale_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final status = _writeStatus(
      root,
      updatedAt: DateTime.now().toUtc().subtract(const Duration(minutes: 20)),
      activeCellElapsedMs: 120000,
    );
    final output = '${root.path}/watchdog.json';

    final exit = runWorkSupplyParserQaQueueWatchdog(
      [
        '--status',
        status.path,
        '--max-status-age-ms',
        '900000',
        '--max-active-cell-ms',
        '900000',
        '--output',
        output,
      ],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 1);
    final report = jsonDecode(File(output).readAsStringSync()) as Map;
    expect(report['healthy'], false);
    expect(report['findings'], contains('status_stale'));
  });

  test('queue watchdog computes elapsed from active cell start timestamp', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_queue_watchdog_started_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final status = _writeStatus(
      root,
      updatedAt: DateTime.now().toUtc(),
      activeCellStartedAt: DateTime.now().toUtc().subtract(
        const Duration(minutes: 4),
      ),
      activeCellElapsedMs: 0,
    );
    final output = '${root.path}/watchdog.json';

    final exit = runWorkSupplyParserQaQueueWatchdog(
      [
        '--status',
        status.path,
        '--max-status-age-ms',
        '900000',
        '--max-active-cell-ms',
        '900000',
        '--output',
        output,
      ],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    final report = jsonDecode(File(output).readAsStringSync()) as Map;
    expect(report['activeCellElapsedMs'], greaterThanOrEqualTo(240000));
    expect(report['findings'], isEmpty);
  });
}

File _writeStatus(
  Directory root, {
  required DateTime updatedAt,
  DateTime? activeCellStartedAt,
  required int activeCellElapsedMs,
}) {
  return File('${root.path}/latest_status.json')..writeAsStringSync(
    jsonEncode({
      'state': 'running',
      'updatedAtIso': updatedAt.toIso8601String(),
      'activeCellId': 'plumbing_residential_core_en_US',
      'activeCellStartedAtIso': (activeCellStartedAt ?? updatedAt)
          .toIso8601String(),
      'activeCellElapsedMs': activeCellElapsedMs,
      'completedCellCount': 4,
      'failedCellCount': 0,
      'liveServicesAllowed': false,
      'writesProductionCatalog': false,
      'firebaseWritesAllowed': false,
      'ocrCameraExpensesTouched': false,
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
