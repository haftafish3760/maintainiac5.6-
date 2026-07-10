import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/work_supply_parser_qa_report_digest.dart';

void main() {
  test('report digest extracts suite metrics for admin review', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_report_digest_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final report = File('${root.path}/report.json')
      ..writeAsStringSync(
        jsonEncode({
          'domain': 'work_supply_inventory_parser',
          'strict': false,
          'checked': 1200,
          'actualFailureCount': 2,
          'severityCounts': {'warning': 2, 'error': 0, 'critical': 0},
          'adminHealth': {'status': 'needs review'},
          'results': [
            {
              'name': 'inventory.item_metadata_depth',
              'checked': 1192,
              'actualFailureCount': 2,
              'durationMs': 50,
              'metrics': {
                'scoreBuckets': {'strong': 10, 'needs_enrichment': 2},
                'warningsByPriorityScope': [
                  {
                    'name': 'release_one_residential_priority_trades',
                    'count': 1,
                  },
                ],
                'checkedByPriorityScope': [
                  {
                    'name': 'release_one_residential_priority_trades',
                    'count': 12,
                  },
                ],
                'topMissingSignals': [
                  {'name': 'negativeMatchTokens', 'count': 1},
                ],
              },
            },
          ],
        }),
      );
    final output = '${root.path}/digest.json';
    final stdout = _MemorySink();

    final exit = runWorkSupplyParserQaReportDigest(
      ['--report', report.path, '--output', output],
      stdout: stdout,
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    expect(File(output).existsSync(), isTrue);
    expect(stdout.content, contains('QA_REPORT_DIGEST'));
    expect(stdout.content, contains('release_one_residential_priority_trades'));
  });

  test('report digest fails clearly when report is missing', () {
    final stderr = _MemorySink();

    final exit = runWorkSupplyParserQaReportDigest(
      ['--report', 'missing-report.json'],
      stdout: _MemorySink(),
      stderr: stderr,
    );

    expect(exit, 66);
    expect(stderr.content, contains('Report not found'));
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
