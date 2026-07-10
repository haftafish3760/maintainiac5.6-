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
          'firebaseWritesAllowed': false,
          'ocrCameraExpensesTouched': false,
        }),
      );
    final pipeline = File('${root.path}/maintenance_pipeline.json')
      ..writeAsStringSync(
        jsonEncode({
          'expectedCells': 8,
          'presentCells': 8,
          'missingCells': 0,
          'unsafeCells': 0,
          'parserCalls': 80,
          'liveServicesAllowed': false,
          'writesProductionCatalog': false,
          'firebaseWritesAllowed': false,
          'ocrCameraExpensesTouched': false,
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
    expect(report['pipelineHasParserEvidence'], isTrue);
    expect(report['pipelineMissingCells'], 0);
  });

  test('release readiness rejects complete pipeline without parser calls', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_platform_release_readiness_missing_calls_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final wave = File('${root.path}/inventory_wave.json')
      ..writeAsStringSync(
        jsonEncode({
          'totalCellCount': 6,
          'completedCellCount': 6,
          'failedCellCount': 0,
          'unsafe': false,
          'liveServicesAllowed': false,
          'writesProductionCatalog': false,
          'firebaseWritesAllowed': false,
          'ocrCameraExpensesTouched': false,
        }),
      );
    final pipeline = File('${root.path}/inventory_pipeline.json')
      ..writeAsStringSync(
        jsonEncode({
          'expectedCells': 6,
          'presentCells': 6,
          'missingCells': 0,
          'unsafeCells': 0,
          'parserCalls': 0,
          'liveServicesAllowed': false,
          'writesProductionCatalog': false,
          'firebaseWritesAllowed': false,
          'ocrCameraExpensesTouched': false,
        }),
      );
    final report = buildParserQaReleaseReadiness(
      ParserQaReleaseReadinessOptions(
        waveReportPath: wave.path,
        pipelineStatusPath: pipeline.path,
        outputPath: '${root.path}/readiness.json',
        reportName: 'inventory_parser_release_readiness',
      ),
    );

    expect(report['releaseOneParserEvidenceReady'], isTrue);
    expect(report['releaseOnePipelineArtifactsReady'], isFalse);
    expect(report['pipelineHasParserEvidence'], isFalse);
    expect(
      report['nextActions'].toString(),
      contains('missing parser-call evidence'),
    );
  });

  test('release readiness rejects unsafe mirror flags on wave or pipeline', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_platform_release_readiness_unsafe_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final wave = File('${root.path}/inventory_wave.json')
      ..writeAsStringSync(
        jsonEncode({
          'totalCellCount': 6,
          'completedCellCount': 6,
          'failedCellCount': 0,
          'unsafe': false,
          'liveServicesAllowed': false,
          'writesProductionCatalog': false,
          'firebaseWritesAllowed': true,
          'ocrCameraExpensesTouched': false,
        }),
      );
    final pipeline = File('${root.path}/inventory_pipeline.json')
      ..writeAsStringSync(
        jsonEncode({
          'expectedCells': 6,
          'presentCells': 6,
          'missingCells': 0,
          'unsafeCells': 0,
          'parserCalls': 60,
          'liveServicesAllowed': false,
          'writesProductionCatalog': false,
          'firebaseWritesAllowed': false,
          'ocrCameraExpensesTouched': false,
        }),
      );
    final report = buildParserQaReleaseReadiness(
      ParserQaReleaseReadinessOptions(
        waveReportPath: wave.path,
        pipelineStatusPath: pipeline.path,
        outputPath: '${root.path}/readiness.json',
        reportName: 'inventory_parser_release_readiness',
      ),
    );

    expect(report['unsafe'], isTrue);
    expect(report['releaseOneParserEvidenceReady'], isFalse);
    expect(report['releaseOnePipelineArtifactsReady'], isFalse);
  });
}
