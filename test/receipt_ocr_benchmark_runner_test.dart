import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'benchmark scores labeled input and release gate rejects synthetic-only evidence',
    () async {
      final ordinary = await Process.run('dart', [
        'tool/receipt_ocr_benchmark_runner.dart',
        '--input=test/fixtures/receipt_qa/ocr_benchmark_sample.json',
      ]);
      expect(ordinary.exitCode, 0, reason: '${ordinary.stderr}');
      final report =
          jsonDecode(ordinary.stdout as String) as Map<String, dynamic>;
      expect(report['caseCount'], 2);
      expect(report['hasRealEvidence'], isFalse);
      expect(report['metrics']['total'], 1);

      final release = await Process.run('dart', [
        'tool/receipt_ocr_benchmark_runner.dart',
        '--input=test/fixtures/receipt_qa/ocr_benchmark_sample.json',
        '--release-gate',
      ]);
      expect(release.exitCode, 1);
      final gated =
          jsonDecode(release.stdout as String) as Map<String, dynamic>;
      expect(gated['missingRealScenarioCoverage'], isNotEmpty);
      expect(gated['underSampledRealScenarios'], isNotEmpty);
    },
  );

  test('benchmark provenance rejects raw text and file paths', () async {
    final temp = await Directory.systemTemp.createTemp('ocr_benchmark_');
    addTearDown(() => temp.delete(recursive: true));
    final input = File('${temp.path}/unsafe.json');
    await input.writeAsString(
      jsonEncode({
        'cases': [
          {
            'id': 'unsafe',
            'provenance': {
              'sourceId': 'unsafe',
              'sourceKind': 'camera',
              'engine': 'fixture',
              'processingVersion': 'v1',
              'rawText': 'private receipt',
            },
            'expected': {'text': 'TOTAL 1.00'},
            'actual': {'text': 'TOTAL 1.00'},
          },
        ],
      }),
    );
    final result = await Process.run('dart', [
      'tool/receipt_ocr_benchmark_runner.dart',
      '--input=${input.path}',
    ]);
    expect(result.exitCode, 65);
    expect(result.stderr, contains('must not contain raw text or file paths'));
  });
}
