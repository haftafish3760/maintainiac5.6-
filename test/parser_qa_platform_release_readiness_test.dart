import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/parser_qa_platform/parser_qa_release_readiness.dart';

void main() {
  test('release readiness supports non-inventory parser adapters', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_platform_release_readiness_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final wave = File('${root.path}/maintenance_wave.json')
      ..writeAsStringSync(
        jsonEncode({
          'totalCellCount': 8,
          'completedCellCount': 8,
          'failedCellCount': 0,
          'unsafe': false,
          'liveServicesAllowed': false,
          'writesProductionCatalog': false,
        }),
      );
    final pipeline = File('${root.path}/maintenance_pipeline.json')
      ..writeAsStringSync(
        jsonEncode({
          'expectedCells': 8,
          'presentCells': 8,
          'missingCells': 0,
          'unsafeCells': 0,
          'liveServicesAllowed': false,
          'writesProductionCatalog': false,
        }),
      );
    final report = buildParserQaReleaseReadiness(
      ParserQaReleaseReadinessOptions(
        waveReportPath: wave.path,
        pipelineStatusPath: pipeline.path,
        outputPath: '${root.path}/readiness.json',
        reportName: 'maintenance_parser_release_readiness',
      ),
    );

    expect(report['report'], 'maintenance_parser_release_readiness');
    expect(report['releaseOneParserEvidenceReady'], isTrue);
    expect(report['releaseOnePipelineArtifactsReady'], isTrue);
    expect(report['pipelineMissingCells'], 0);
  });
}
