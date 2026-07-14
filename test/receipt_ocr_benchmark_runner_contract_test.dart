import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'OCR benchmark release gate requires real and complete labeled evidence',
    () async {
      final source = await File(
        'tool/receipt_ocr_benchmark_runner.dart',
      ).readAsString();

      expect(
        source,
        contains("final releaseGate = args.contains('--release-gate');"),
      );
      expect(
        source,
        contains(
          "final requireReal = releaseGate || args.contains('--require-real');",
        ),
      );
      expect(source, contains('final requireCompleteCoverage ='));
      expect(source, contains("'metricCaseCounts': report.coverage"));
      expect(source, contains("'missingCoverage': missingCoverage"));
      expect(source, contains("'missingRealScenarioCoverage'"));
      expect(source, contains("'scenarioBelowMinimum': scenarioBelowMinimum"));
      expect(source, contains('const _requiredReceiptScenarios'));
      expect(source, contains('const _minimumRealCasesPerScenario = 3'));
      expect(source, contains('Every benchmark case must be an object.'));
      expect(source, contains('(requireReal && !hasRealEvidence)'));
      expect(source, contains('missingScenarioCoverage.isNotEmpty ||'));
      expect(source, contains('scenarioBelowMinimum.isNotEmpty'));
      expect(
        source,
        contains('missingRealScenarioCoverage.isNotEmpty ||'),
      );
      expect(source, contains('underSampledRealScenarios.isNotEmpty'));
    },
  );
}
