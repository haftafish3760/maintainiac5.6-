import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/parser_qa_platform/parser_qa_platform.dart';

void main() {
  test('shared parser QA platform exports reusable reporting primitives', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_platform_exports_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final summary = File('${root.path}/summary.json')
      ..writeAsStringSync(
        jsonEncode({
          'results': [
            {
              'cellId': 'maintenance_filters_en_US',
              'trade': 'maintenance',
              'tier': 'core',
              'localePackId': 'en-US',
              'durationMs': 100,
              'exitCode': 0,
            },
          ],
        }),
      );

    final duration = buildParserQaDurationReport(
      ParserQaDurationReportOptions(
        summaryPath: summary.path,
        outputPath: '${root.path}/duration_report.json',
        reportName: 'maintenance_duration',
      ),
    );
    final advice = buildParserQaBatchSizeAdvice(
      ParserQaBatchSizeAdvisorOptions(
        durationReportPath: '${root.path}/duration_report.json',
        outputPath: '${root.path}/batch_size_advice.json',
        reportName: 'maintenance_advice',
        currentLimit: 25,
        targetCellMs: 300000,
        minCompletedCells: 1,
      ),
    );

    expect(duration['report'], 'maintenance_duration');
    expect(advice['report'], 'maintenance_advice');
    expect(advice['recommendation'], 'increase');
  });
}
