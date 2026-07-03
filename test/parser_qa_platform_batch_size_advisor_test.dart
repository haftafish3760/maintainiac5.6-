import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/parser_qa_platform/parser_qa_batch_size_advisor.dart';

void main() {
  test('shared batch-size advisor supports non-inventory parser adapters', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_platform_advisor_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final durationReport = File('${root.path}/duration_report.json')
      ..writeAsStringSync(
        jsonEncode({
          'cellCount': 8,
          'averageDurationMs': 100000,
          'slowestCells': [
            {
              'cellId': 'maintenance_filters_en_US',
              'trade': 'maintenance',
              'tier': 'core',
              'localePackId': 'en-US',
              'durationMs': 120000,
              'exitCode': 0,
            },
          ],
        }),
      );

    final advice = buildParserQaBatchSizeAdvice(
      ParserQaBatchSizeAdvisorOptions(
        durationReportPath: durationReport.path,
        outputPath: '${root.path}/batch_size_advice.json',
        reportName: 'maintenance_parser_qa_batch_size_advisor',
        currentLimit: 25,
        targetCellMs: 300000,
        minCompletedCells: 6,
      ),
    );

    expect(advice['report'], 'maintenance_parser_qa_batch_size_advisor');
    expect(advice['recommendation'], 'increase');
    expect(advice['recommendedFixtureRunLimit'], greaterThan(25));
    expect(
      ((advice['slowestCells'] as List).single as Map)['cellId'],
      'maintenance_filters_en_US',
    );
  });
}
