import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_report_retention.dart';

void main() {
  test(
    'pruneQaReportArtifacts preserves latest aliases and dry-runs safely',
    () {
      final directory = Directory.systemTemp.createTempSync(
        'parser_qa_retention_dry_',
      );
      addTearDown(() {
        if (directory.existsSync()) {
          directory.deleteSync(recursive: true);
        }
      });

      _seedReports(directory, domain: 'inventory_parser', count: 4);
      final latestJson = _touch(directory, 'latest_inventory_parser.json');
      final latestSummary = _touch(directory, 'latest_inventory_parser.txt');
      final latestPackHealth = _touch(
        directory,
        'latest_inventory_parser_pack_health.json',
      );

      final summary = pruneQaReportArtifacts(
        domain: 'inventory_parser',
        outputDirectory: directory.path,
        keepLatestTimestamped: 2,
        dryRun: true,
      );

      expect(summary.deletedCount, 4);
      expect(summary.deletedTimestampedReports, hasLength(2));
      expect(summary.deletedPackHealthReports, hasLength(2));
      expect(summary.keptTimestampedReports, hasLength(2));
      expect(summary.keptPackHealthReports, hasLength(2));
      expect(summary.preservedAliases, contains(latestJson.path));
      expect(summary.preservedAliases, contains(latestSummary.path));
      expect(summary.preservedAliases, contains(latestPackHealth.path));
      expect(directory.listSync().whereType<File>(), hasLength(11));
    },
  );

  test(
    'pruneQaReportArtifacts deletes old files only for the selected domain',
    () {
      final directory = Directory.systemTemp.createTempSync(
        'parser_qa_retention_delete_',
      );
      addTearDown(() {
        if (directory.existsSync()) {
          directory.deleteSync(recursive: true);
        }
      });

      _seedReports(directory, domain: 'inventory_parser', count: 5);
      _seedReports(directory, domain: 'maintenance_parser', count: 3);
      _touch(directory, 'latest_inventory_parser.json');
      _touch(directory, 'latest_inventory_parser.txt');
      _touch(directory, 'latest_inventory_parser_pack_health.json');

      final summary = pruneQaReportArtifacts(
        domain: 'inventory_parser',
        outputDirectory: directory.path,
        keepLatestTimestamped: 2,
      );

      expect(summary.deletedTimestampedReports, hasLength(3));
      expect(summary.deletedPackHealthReports, hasLength(3));
      for (final path in summary.deletedTimestampedReports) {
        expect(File(path).existsSync(), isFalse);
        expect(path, contains('inventory_parser_'));
        expect(path, isNot(contains('maintenance_parser')));
      }
      for (final path in summary.deletedPackHealthReports) {
        expect(File(path).existsSync(), isFalse);
        expect(path, contains('inventory_parser_pack_health_'));
      }

      final inventoryTimestamped = directory
          .listSync()
          .whereType<File>()
          .where(
            (file) =>
                file.uri.pathSegments.last.startsWith('inventory_parser_2026'),
          )
          .toList();
      final maintenanceFiles = directory
          .listSync()
          .whereType<File>()
          .where(
            (file) =>
                file.uri.pathSegments.last.startsWith('maintenance_parser_'),
          )
          .toList();

      expect(inventoryTimestamped, hasLength(2));
      expect(maintenanceFiles, hasLength(6));
      expect(
        File('${directory.path}/latest_inventory_parser.json').existsSync(),
        isTrue,
      );
      expect(
        File('${directory.path}/latest_inventory_parser.txt').existsSync(),
        isTrue,
      );
      expect(
        File(
          '${directory.path}/latest_inventory_parser_pack_health.json',
        ).existsSync(),
        isTrue,
      );
    },
  );

  test('pruneQaReportArtifacts rejects unsafe zero-retention requests', () {
    expect(
      () => pruneQaReportArtifacts(
        domain: 'inventory_parser',
        keepLatestTimestamped: 0,
      ),
      throwsArgumentError,
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
