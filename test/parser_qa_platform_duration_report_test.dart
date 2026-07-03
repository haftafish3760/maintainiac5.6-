import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/parser_qa_platform/parser_qa_duration_report.dart';

void main() {
  test(
    'shared parser QA duration report supports non-inventory report names',
    () {
      final root = Directory.systemTemp.createTempSync(
        'maintainiac_platform_duration_',
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
                'durationMs': 300,
                'exitCode': 0,
              },
              {
                'cellId': 'maintenance_belts_en_US',
                'trade': 'maintenance',
                'tier': 'standard',
                'localePackId': 'en-US',
                'durationMs': 900,
                'exitCode': 0,
              },
            ],
          }),
        );

      final report = buildParserQaDurationReport(
        ParserQaDurationReportOptions(
          summaryPath: summary.path,
          outputPath: '${root.path}/duration_report.json',
          reportName: 'maintenance_parser_qa_duration_report',
        ),
      );

      expect(report['report'], 'maintenance_parser_qa_duration_report');
      expect(report['cellCount'], 2);
      expect(report['averageDurationMs'], 600);
      expect(
        ((report['slowestCells'] as List).first as Map)['cellId'],
        'maintenance_belts_en_US',
      );
    },
  );
}
