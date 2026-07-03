import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/parser_qa_platform/parser_qa_queue_watchdog.dart';

void main() {
  test('shared queue watchdog supports non-inventory parser queues', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_platform_watchdog_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final status = File('${root.path}/latest_status.json')
      ..writeAsStringSync(
        jsonEncode({
          'state': 'running',
          'updatedAtIso': DateTime.now().toUtc().toIso8601String(),
          'activeCellId': 'maintenance_filters_en_US',
          'activeCellStartedAtIso': DateTime.now()
              .toUtc()
              .subtract(const Duration(minutes: 2))
              .toIso8601String(),
          'activeCellElapsedMs': 0,
          'completedCellCount': 4,
          'failedCellCount': 0,
          'liveServicesAllowed': false,
          'writesProductionCatalog': false,
        }),
      );

    final report = buildParserQaQueueWatchdog(
      ParserQaQueueWatchdogOptions(
        statusPath: status.path,
        outputPath: '${root.path}/queue_watchdog.json',
        reportName: 'maintenance_parser_qa_queue_watchdog',
        maxStatusAgeMs: 900000,
        maxActiveCellMs: 900000,
      ),
    );

    expect(report['report'], 'maintenance_parser_qa_queue_watchdog');
    expect(report['activeCellId'], 'maintenance_filters_en_US');
    expect(report['healthy'], isTrue);
    expect(report['activeCellElapsedMs'], greaterThanOrEqualTo(120000));
  });
}
