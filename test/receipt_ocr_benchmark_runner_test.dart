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

  test('benchmark reports a failing real scenario separately from fixtures',
      () async {
    final temp = await Directory.systemTemp.createTemp('ocr_benchmark_real_');
    addTearDown(() => temp.delete(recursive: true));
    final input = File('${temp.path}/real.json');
    await input.writeAsString(
      jsonEncode({
        'cases': [
          for (var index = 0; index < 3; index++)
            {
              'id': 'real-thermal-$index',
              'provenance': {
                'sourceId': 'opt-in-camera-$index',
                'sourceKind': 'camera',
                'engine': 'on_device',
                'processingVersion': 'v1',
                'scenarioTags': ['thermal'],
              },
              'expected': {
                'text': 'STORE\\nTOTAL 10.00',
                'merchant': 'STORE',
                'total': '10.00',
                'lines': ['STORE', 'TOTAL 10.00'],
                'route': 'expenseReview',
              },
              'actual': {
                'text': index == 0 ? 'STORE\\nTOTAL 99.99' : 'STORE\\nTOTAL 10.00',
                'merchant': 'STORE',
                'total': index == 0 ? '99.99' : '10.00',
                'lines': [
                  'STORE',
                  index == 0 ? 'TOTAL 99.99' : 'TOTAL 10.00',
                ],
                'route': 'expenseReview',
              },
            },
        ],
      }),
    );

    final result = await Process.run('dart', [
      'tool/receipt_ocr_benchmark_runner.dart',
      '--input=${input.path}',
    ]);
    expect(result.exitCode, 1);
    final report = jsonDecode(result.stdout as String) as Map<String, dynamic>;
    expect(report['hasRealEvidence'], isTrue);
    expect(report['realScenarioCaseCounts']['thermal'], 3);
    expect(report['realScenarioBelowMinimum']['thermal'], isNotEmpty);
  });

  test('benchmark rejects duplicate real receipt sources and release mixes',
      () async {
    final temp = await Directory.systemTemp.createTemp('ocr_benchmark_runs_');
    addTearDown(() => temp.delete(recursive: true));
    Map<String, Object?> caseFor({
      required String id,
      required String sourceId,
      required String engine,
      required String version,
    }) => {
      'id': id,
      'provenance': {
        'sourceId': sourceId,
        'sourceKind': 'camera',
        'engine': engine,
        'processingVersion': version,
        'scenarioTags': ['thermal'],
      },
      'expected': {'text': 'STORE\\nTOTAL 10.00', 'total': '10.00'},
      'actual': {'text': 'STORE\\nTOTAL 10.00', 'total': '10.00'},
    };

    final duplicate = File('${temp.path}/duplicate.json');
    await duplicate.writeAsString(jsonEncode({
      'cases': [
        caseFor(id: 'one', sourceId: 'capture-a', engine: 'local', version: 'v1'),
        caseFor(id: 'two', sourceId: 'capture-a', engine: 'local', version: 'v1'),
      ],
    }));
    final duplicateResult = await Process.run('dart', [
      'tool/receipt_ocr_benchmark_runner.dart',
      '--input=${duplicate.path}',
    ]);
    expect(duplicateResult.exitCode, 65);
    expect(duplicateResult.stderr, contains('Each physical receipt'));

    final mixed = File('${temp.path}/mixed.json');
    await mixed.writeAsString(jsonEncode({
      'cases': [
        caseFor(id: 'one', sourceId: 'capture-a', engine: 'local', version: 'v1'),
        caseFor(id: 'two', sourceId: 'capture-b', engine: 'local', version: 'v2'),
      ],
    }));
    final mixedResult = await Process.run('dart', [
      'tool/receipt_ocr_benchmark_runner.dart',
      '--input=${mixed.path}',
      '--release-gate',
    ]);
    expect(mixedResult.exitCode, 1);
    final mixedReport =
        jsonDecode(mixedResult.stdout as String) as Map<String, dynamic>;
    expect(mixedReport['mixedRealRunIdentities'], isTrue);
    expect(mixedReport['realRunIdentities'], ['local@v1', 'local@v2']);
  });
}
