import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/work_supply_parser_qa_prune_reports.dart';

void main() {
  test('QA report prune tool dry-runs by default', () {
    final directory = Directory.systemTemp.createTempSync(
      'parser_qa_prune_dry_',
    );
    addTearDown(() {
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
    });
    _seedReports(directory, domain: 'work_supply_inventory_parser', count: 3);

    final result = runQaReportPrune([
      '--output-dir',
      directory.path,
      '--keep',
      '1',
    ]);

    expect(result.exitCode, 0);
    expect(result.stdout, contains('QA_RETENTION_SUMMARY'));
    expect(result.stdout, contains('"dryRun": true'));
    expect(result.stdout, contains('"deletedCount": 4'));
    expect(directory.listSync().whereType<File>(), hasLength(6));
  });

  test('QA report prune tool execute mode deletes only selected domain', () {
    final directory = Directory.systemTemp.createTempSync(
      'parser_qa_prune_execute_',
    );
    addTearDown(() {
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
    });
    _seedReports(directory, domain: 'work_supply_inventory_parser', count: 4);
    _seedReports(directory, domain: 'maintenance_parser', count: 2);
    _touch(directory, 'latest_work_supply_inventory_parser.json');
    _touch(directory, 'latest_work_supply_inventory_parser.txt');
    _touch(directory, 'latest_work_supply_inventory_parser_pack_health.json');

    final result = runQaReportPrune([
      '--output-dir',
      directory.path,
      '--keep',
      '2',
      '--execute',
    ]);

    expect(result.exitCode, 0);
    expect(result.stdout, contains('"dryRun": false'));
    expect(result.stdout, contains('"deletedCount": 4'));
    final remaining =
        directory
            .listSync()
            .whereType<File>()
            .map((file) => file.uri.pathSegments.last)
            .toList()
          ..sort();

    expect(
      remaining
          .where((name) => name.startsWith('work_supply_inventory_parser_2026'))
          .length,
      2,
    );
    expect(
      remaining
          .where(
            (name) =>
                name.startsWith('work_supply_inventory_parser_pack_health_'),
          )
          .length,
      2,
    );
    expect(
      remaining.where((name) => name.startsWith('maintenance_parser_')).length,
      4,
    );
    expect(remaining, contains('latest_work_supply_inventory_parser.json'));
    expect(remaining, contains('latest_work_supply_inventory_parser.txt'));
    expect(
      remaining,
      contains('latest_work_supply_inventory_parser_pack_health.json'),
    );
  });
}

void _seedReports(
  Directory directory, {
  required String domain,
  required int count,
}) {
  for (var index = 0; index < count; index += 1) {
    final stamp = '20260102T03040${index}000000';
    final report = _touch(directory, '${domain}_$stamp.json');
    final packHealth = _touch(directory, '${domain}_pack_health_$stamp.json');
    final modified = DateTime(2026, 1, 2, 3, 4, index);
    report.setLastModifiedSync(modified);
    packHealth.setLastModifiedSync(modified);
  }
}

File _touch(Directory directory, String name) {
  final file = File('${directory.path}${Platform.pathSeparator}$name');
  file.writeAsStringSync('{}');
  return file;
}
