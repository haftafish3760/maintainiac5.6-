import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _runnerProcessTimeout = Timeout(Duration(minutes: 2));

void main() {
  test(
    'pure Dart receipt QA runner can focus long receipt fixtures',
    () async {
      await _expectFocusedPack(
        pack: 'long_receipt',
        expectedFixtureCount: 4,
        expectedFixtureNames: const [
          'top section without bottom total asks for continuation',
          'middle section overlap still needs bottom total',
          'bottom section without repeated date still captures totals',
          'stitched overlap surfaces duplicate review diagnostics',
        ],
      );
    },
    timeout: _runnerProcessTimeout,
  );

  test(
    'pure Dart receipt QA runner can focus maintenance fixtures',
    () async {
      await _expectFocusedPack(
        pack: 'maintenance',
        expectedFixtureCount: 2,
        expectedFixtureNames: const [
          'oil change interval baseline',
          'oil change odometer due interval',
        ],
      );
    },
    timeout: _runnerProcessTimeout,
  );

  test(
    'pure Dart receipt QA runner can focus fuel fixtures',
    () async {
      await _expectFocusedPack(
        pack: 'fuel',
        expectedFixtureCount: 2,
        expectedFixtureNames: const [
          'diesel station baseline',
          'split row fuel with tender rows',
        ],
      );
    },
    timeout: _runnerProcessTimeout,
  );

  test(
    'pure Dart receipt QA runner can focus noisy OCR fixtures',
    () async {
      await _expectFocusedPack(
        pack: 'noisy',
        expectedFixtureCount: 4,
        expectedFixtureNames: const [
          'swapped total and date characters',
          'noisy fuel subtotal tax and total',
          'home center material OCR letter number swaps',
          'home center truncated material rows',
        ],
      );
    },
    timeout: _runnerProcessTimeout,
  );

  test(
    'pure Dart receipt QA runner can focus retail fixtures',
    () async {
      await _expectFocusedPack(
        pack: 'retail',
        expectedFixtureCount: 4,
        expectedFixtureNames: const [
          'mixed retail baseline',
          'retail tax total with tender row',
          'mixed business and personal line allocation',
          'non business marker line allocation',
        ],
      );
    },
    timeout: _runnerProcessTimeout,
  );

  test(
    'pure Dart receipt QA runner can focus adjustment fixtures',
    () async {
      await _expectFocusedPack(
        pack: 'adjustment',
        expectedFixtureCount: 1,
        expectedFixtureNames: const [
          'coupon and store discount adjustment rows',
        ],
      );
    },
    timeout: _runnerProcessTimeout,
  );

  test(
    'pure Dart receipt QA runner can focus contractor supply fixtures',
    () async {
      await _expectFocusedPack(
        pack: 'contractor_supply',
        expectedFixtureCount: 2,
        expectedFixtureNames: const [
          'home center material quantities and packs',
          'split OCR material description rows rejoin cleanly',
        ],
      );
    },
    timeout: _runnerProcessTimeout,
  );

  test(
    'pure Dart receipt QA runner can focus damaged OCR fixtures',
    () async {
      await _expectFocusedPack(
        pack: 'damaged_ocr',
        expectedFixtureCount: 7,
        expectedFixtureNames: const [
          'blurry receipt source requires retake guidance',
          'glare washed receipt source requires retake guidance',
          'low light receipt source requires retake guidance',
          'partial crop source stays in crop or retake review',
          'weak low contrast text asks for review before OCR',
          'wrinkled long receipt top section still asks for continuation',
          'smudged long receipt overlap keeps duplicate review diagnostics',
        ],
      );
    },
    timeout: _runnerProcessTimeout,
  );

  test(
    'pure Dart receipt QA runner can focus privacy/admin fixtures',
    () async {
      await _expectFocusedPack(
        pack: 'privacy_admin',
        expectedFixtureCount: 2,
        expectedFixtureNames: const [
          'card auth address and phone stay privacy metadata',
          'fleet card and reference rows never become purchase lines',
        ],
      );
    },
    timeout: _runnerProcessTimeout,
  );

  test(
    'pure Dart receipt QA runner can focus device-tier fixtures',
    () async {
      await _expectFocusedPack(
        pack: 'device_tiers',
        expectedFixtureCount: 2,
        expectedFixtureNames: const [
          'older phone keeps receipt OCR workload lean',
          'critical storage defers optional packs and cloud assists',
        ],
      );
    },
    timeout: _runnerProcessTimeout,
  );
}

Future<void> _expectFocusedPack({
  required String pack,
  required int expectedFixtureCount,
  required List<String> expectedFixtureNames,
}) async {
  final result = await Process.run('dart', [
    'run',
    'tool/receipt_qa_runner.dart',
    '--pack=$pack',
    '--fail-under=1.0',
    '--json',
  ]);

  expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');

  final report =
      jsonDecode(_extractJsonObject(result.stdout as String))
          as Map<String, Object?>;
  final fixtures = report['fixtures']! as List<Object?>;
  final packScores = report['packScores']! as Map<String, Object?>;
  final fixtureNames = fixtures.map((fixture) {
    return (fixture! as Map<String, Object?>)['name'];
  });

  expect(report['pack'], pack);
  expect(report['score'], greaterThanOrEqualTo(1.0));
  expect(packScores.keys, [pack]);
  expect(fixtures, hasLength(expectedFixtureCount));
  expect(fixtureNames, containsAll(expectedFixtureNames));
  for (final fixture in fixtures.cast<Map<String, Object?>>()) {
    expect(fixture['pack'], pack);
    expect(fixture['score'], greaterThanOrEqualTo(1.0));
    expect(fixture['issues'], isEmpty);
  }
}

String _extractJsonObject(String output) {
  final start = output.indexOf('{');
  final end = output.lastIndexOf('}');
  if (start < 0 || end <= start) {
    throw FormatException('Receipt QA runner did not emit JSON.', output);
  }
  return output.substring(start, end + 1);
}
