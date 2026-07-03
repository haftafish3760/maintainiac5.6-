import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/work_supply_parser_qa_release_one_readiness.dart';

void main() {
  test(
    'readiness separates completed wave evidence from missing pipeline cells',
    () {
      final root = Directory.systemTemp.createTempSync(
        'maintainiac_release_one_readiness_',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      final wave = File('${root.path}/wave.json')
        ..writeAsStringSync(
          jsonEncode({
            'totalCellCount': 96,
            'completedCellCount': 96,
            'failedCellCount': 0,
            'unsafe': false,
            'liveServicesAllowed': false,
            'writesProductionCatalog': false,
          }),
        );
      final pipeline = File('${root.path}/pipeline.json')
        ..writeAsStringSync(
          jsonEncode({
            'expectedCells': 24,
            'presentCells': 1,
            'missingCells': 23,
            'unsafeCells': 0,
            'liveServicesAllowed': false,
            'writesProductionCatalog': false,
          }),
        );
      final fixtures = File('${root.path}/fixtures.json')
        ..writeAsStringSync(
          jsonEncode({
            'totalCells': 24,
            'generatedFixtureCount': 24,
            'missingFixtureCount': 0,
            'readyForParserExecution': true,
            'unsafeFindings': [],
            'liveServicesAllowed': false,
            'writesProductionCatalog': false,
            'firebaseWritesAllowed': false,
            'ocrCameraExpensesTouched': false,
          }),
        );
      final output = '${root.path}/readiness.json';

      final exit = runWorkSupplyParserQaReleaseOneReadiness(
        [
          '--wave-report',
          wave.path,
          '--pipeline-status',
          pipeline.path,
          '--fixture-readiness',
          fixtures.path,
          '--output',
          output,
        ],
        stdout: _MemorySink(),
        stderr: _MemorySink(),
      );

      expect(exit, 0);
      final report = jsonDecode(File(output).readAsStringSync()) as Map;
      expect(report['releaseOneParserEvidenceReady'], isTrue);
      expect(report['releaseOneFixtureEvidenceReady'], isTrue);
      expect(report['releaseOnePipelineArtifactsReady'], isFalse);
      expect(
        report['nextActions'].toString(),
        contains('pipeline artifact root'),
      );
    },
  );
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
