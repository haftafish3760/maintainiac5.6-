import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/parser_qa_platform/parser_qa_run_intelligence.dart';

void main() {
  test(
    'shared parser QA run intelligence supports non-inventory adapters',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'maintainiac_parser_platform_intel_',
      );
      addTearDown(() => root.delete(recursive: true));
      final wave = Directory('${root.path}/maintenance-wave-001')..createSync();
      final queue = Directory('${wave.path}/queue/q1')
        ..createSync(recursive: true);
      File('${wave.path}/wave_plan.json').writeAsStringSync(
        jsonEncode({
          'waveId': 'maintenance-wave-001',
          'qaLayer': 'maintenance-fixture-v1',
          'queueSummaryPath': '${queue.path}/summary.json',
          'liveServicesAllowed': false,
          'writesProductionCatalog': false,
          'firebaseWritesAllowed': false,
          'ocrCameraExpensesTouched': false,
        }),
      );
      File('${queue.path}/latest_status.json').writeAsStringSync(
        jsonEncode({
          'state': 'running',
          'cellCount': 10,
          'completedCellCount': 4,
          'failedCellCount': 0,
          'activeCellId': 'maintenance_filters_en_US',
          'liveServicesAllowed': false,
          'writesProductionCatalog': false,
        }),
      );

      final result = buildParserQaRunIntelligenceReport(
        ParserQaRunIntelligenceOptions(
          root: root.path,
          waveId: 'maintenance-wave-001',
          output: '${wave.path}/run_intelligence_report.json',
          reportName: 'maintenance_parser_qa_run_intelligence_report',
          consolePrefix: 'QA_MAINTENANCE_RUN_INTELLIGENCE',
          artifactPrefix: 'QA_MAINTENANCE_RUN_INTELLIGENCE_ARTIFACT',
        ),
      );

      expect(result.exitCode, 0);
      expect(
        result.report['report'],
        'maintenance_parser_qa_run_intelligence_report',
      );
      expect(result.report['activeCellId'], 'maintenance_filters_en_US');
      expect(result.report['remainingCellCount'], 6);
      expect(
        result.report['nextActions'].toString(),
        contains('Continue queue'),
      );
      expect(File(result.outputPath).existsSync(), isTrue);
      expect(File(result.textOutputPath).existsSync(), isTrue);
    },
  );
}
