import 'dart:convert';
import 'dart:io';

import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserDeterminismSuite extends QaSuite {
  const WorkSupplyParserDeterminismSuite() : super('inventory.determinism');

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final failures = <QaFailure>[];
    final cases = _determinismCases();

    if (!context.isFullProfile) {
      final timer = QaStopwatch.start();
      return timer.finish(
        suite: name,
        checked: cases.length,
        failures: failures,
        maxFailures: context.maxFailuresPerSuite,
        metrics: {
          'mode': 'determinism-case-build-smoke',
          'caseCount': cases.length,
          'parserCalls': 0,
          'note': 'Repeat parser assertions run in full/release profiles.',
        },
      );
    }

    final warmupTimer = Stopwatch()..start();
    matchReceiptLineToCatalog(
      'HD 3/4 PVC SCH40 COUPLING',
      tradeScope: 'Plumbing',
      maxCandidates: 24,
    );
    warmupTimer.stop();

    final timer = QaStopwatch.start();
    final selectedCases = cases.take(context.maxGeneratedCases);
    final caseTimings = <Map<String, Object?>>[];
    var parserCalls = 0;
    for (final testCase in selectedCases) {
      final caseTimer = Stopwatch()..start();
      final signatures = <String>[];
      for (var attempt = 0; attempt < 3; attempt += 1) {
        final match = matchReceiptLineToCatalog(
          testCase.line,
          tradeScope: testCase.tradeScope,
          localePackId: testCase.localePackId,
          maxCandidates: 24,
        );
        parserCalls += 1;
        signatures.add(_signature(match));
        if (match != null && match.rawText != testCase.line) {
          failures.add(
            QaFailure(
              suite: name,
              id: 'raw_line_changed:${testCase.id}:$attempt',
              message:
                  'Parser result did not preserve the exact raw input line.',
              expected: context.redactor(testCase.line),
              actual: context.redactor(match.rawText),
              suggestedFix:
                  'Keep normalization output separate from raw evidence fields.',
            ),
          );
        }
      }
      if (signatures.toSet().length != 1) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'nondeterministic_result:${testCase.id}',
            message: 'Same input/context produced different parser signatures.',
            expected: signatures.first,
            actual: signatures.join(' | '),
            suggestedFix:
                'Make candidate ordering, confidence, matched terms, and review state stable for identical parser inputs.',
            metadata: {
              'line': context.redactor(testCase.line),
              'tradeScope': testCase.tradeScope,
              'localePackId': testCase.localePackId,
            },
          ),
        );
      }
      caseTimer.stop();
      caseTimings.add({
        'id': testCase.id,
        'durationMs': caseTimer.elapsedMilliseconds,
        'tradeScope': testCase.tradeScope ?? '',
        'localePackId': testCase.localePackId,
      });
    }

    return timer.finish(
      suite: name,
      checked: cases.length,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'caseCount': cases.length,
        'parserCalls': parserCalls,
        'repeatCount': 3,
        'warmupMs': warmupTimer.elapsedMilliseconds,
        'warmupLine': 'HD 3/4 PVC SCH40 COUPLING',
        'semanticTimingExcludesWarmup': true,
        'slowestDeterminismCases':
            (caseTimings..sort(
                  (a, b) => (b['durationMs'] as int).compareTo(
                    a['durationMs'] as int,
                  ),
                ))
                .take(5)
                .toList(),
      },
    );
  }

  List<_DeterminismCase> _determinismCases() {
    final fixtures = _loadFixtures();
    final fixtureCases = [
      for (final fixture in fixtures)
        _DeterminismCase(
          id: fixture.id,
          line: fixture.rawLine,
          tradeScope: fixture.tradeScope,
          localePackId: fixture.localePackId,
        ),
    ];
    return [
      ...fixtureCases,
      const _DeterminismCase(id: 'generic_pvc_elbow', line: 'PVC EL 3/4'),
      const _DeterminismCase(
        id: 'scoped_plumbing_pvc_elbow',
        line: 'PVC EL 3/4',
        tradeScope: 'Plumbing',
      ),
      const _DeterminismCase(
        id: 'scoped_electrical_pvc_cond',
        line: 'PVC COND 3/4',
        tradeScope: 'Electrical',
      ),
      const _DeterminismCase(
        id: 'spanish_pex_codo',
        line: '1/2 CODO PEX 90',
        tradeScope: 'Plumbing',
        localePackId: 'es-US',
      ),
    ];
  }

  String _signature(ReceiptLineMatch? match) {
    if (match == null) return 'null';
    final terms = [...match.matchedTerms]..sort();
    return [
      match.item.id,
      match.item.trade,
      match.item.name,
      match.confidence.toStringAsFixed(4),
      match.confidenceLevel.name,
      match.needsReview ? 'review' : 'good',
      match.source.name,
      terms.join(','),
    ].join('::');
  }
}

class _DeterminismCase {
  const _DeterminismCase({
    required this.id,
    required this.line,
    this.tradeScope,
    this.localePackId = '',
  });

  final String id;
  final String line;
  final String? tradeScope;
  final String localePackId;
}

class _DeterminismFixture {
  const _DeterminismFixture({
    required this.id,
    required this.rawLine,
    this.tradeScope,
    this.localePackId = '',
  });

  final String id;
  final String rawLine;
  final String? tradeScope;
  final String localePackId;

  static _DeterminismFixture fromJson(Map<String, Object?> json) {
    return _DeterminismFixture(
      id: json['id'] as String? ?? 'fixture_without_id',
      rawLine: json['rawLine'] as String? ?? '',
      tradeScope: json['tradeScope'] as String?,
      localePackId: json['localePackId'] as String? ?? '',
    );
  }
}

List<_DeterminismFixture> _loadFixtures() {
  final file = File('test/fixtures/work_supply_parser/golden_fixtures.json');
  if (!file.existsSync()) return const [];
  final decoded = jsonDecode(file.readAsStringSync()) as List<dynamic>;
  return [
    for (final entry in decoded)
      _DeterminismFixture.fromJson((entry as Map).cast<String, Object?>()),
  ];
}
