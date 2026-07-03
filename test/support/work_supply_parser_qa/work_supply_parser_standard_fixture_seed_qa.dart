import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserStandardFixtureSeedSuite extends QaSuite {
  const WorkSupplyParserStandardFixtureSeedSuite()
    : super('inventory.standard_fixture_seed_contract');

  static const _cases = [
    _StandardFixtureSeed(
      id: 'plumbing_standard_en_us_priority_cell_review',
      rawLine: 'ACE 3/4 CPVC BALL VALVE',
      tradeScope: 'Plumbing',
      localePackId: 'en-US',
    ),
    _StandardFixtureSeed(
      id: 'plumbing_standard_es_us_priority_cell_review',
      rawLine: 'VALVULA BOLA CPVC 3/4',
      tradeScope: 'Plumbing',
      localePackId: 'es-US',
    ),
    _StandardFixtureSeed(
      id: 'electrical_standard_en_us_priority_cell_review',
      rawLine: 'HD 20A SINGLE POLE BRKR',
      tradeScope: 'Electrical',
      localePackId: 'en-US',
    ),
    _StandardFixtureSeed(
      id: 'electrical_standard_es_us_priority_cell_review',
      rawLine: 'DISYUNTOR UN POLO 20A',
      tradeScope: 'Electrical',
      localePackId: 'es-US',
    ),
    _StandardFixtureSeed(
      id: 'hvac_standard_en_us_priority_cell_review',
      rawLine: 'GRAINGER RUN CAPACITOR 45/5 MFD',
      tradeScope: 'HVAC',
      localePackId: 'en-US',
    ),
    _StandardFixtureSeed(
      id: 'hvac_standard_es_us_priority_cell_review',
      rawLine: 'CAPACITOR MARCHA 45/5 MFD',
      tradeScope: 'HVAC',
      localePackId: 'es-US',
    ),
  ];

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final matches = <String, String>{};

    if (!context.isFullProfile) {
      return timer.finish(
        suite: name,
        checked: _cases.length,
        failures: failures,
        maxFailures: context.maxFailuresPerSuite,
        metrics: {
          'mode': 'standard-fixture-seed-smoke',
          'caseIds': [for (final seed in _cases) seed.id],
          'note':
              'Parser calls are full/release profile only because catalog startup exceeds the smoke runtime budget on Windows.',
        },
      );
    }

    for (final seed in _cases) {
      final match = matchReceiptLineToCatalog(
        seed.rawLine,
        tradeScope: seed.tradeScope,
        localePackId: seed.localePackId,
        maxCandidates: 24,
      );
      if (match == null) {
        failures.add(
          _failure(
            seed,
            message: 'Standard priority fixture seed did not match anything.',
            expected: seed.tradeScope,
            actual: 'null',
            fix: 'Add aliases, receipt patterns, or locale expansion evidence.',
          ),
        );
        continue;
      }
      matches[seed.id] = '${match.item.trade}:${match.item.name}';
      if (match.item.trade != seed.tradeScope) {
        failures.add(
          _failure(
            seed,
            message: 'Standard priority fixture seed matched the wrong trade.',
            expected: seed.tradeScope,
            actual: '${match.item.trade}:${match.item.name}',
            fix: 'Add trade-context scoring or cross-trade negative evidence.',
          ),
        );
      }
      if (match.confidence > .99) {
        failures.add(
          _failure(
            seed,
            message:
                'Standard priority fixture seed became too certain for a review seed.',
            expected: '<= 0.99 confidence',
            actual: '${match.confidence}:${match.item.name}',
            fix:
                'Keep review-seed fixtures conservative until exact merchant/SKU evidence is available.',
          ),
        );
      }
    }

    return timer.finish(
      suite: name,
      checked: _cases.length,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'scope': 'Release-one Standard fixture seeds for en-US and es-US',
        'matches': matches,
      },
    );
  }

  QaFailure _failure(
    _StandardFixtureSeed seed, {
    required String message,
    required String expected,
    required String actual,
    required String fix,
  }) {
    return QaFailure(
      suite: name,
      id: 'standard_fixture_seed:${seed.id}',
      message: message,
      severity: QaSeverity.warning,
      expected: expected,
      actual: actual,
      suggestedFix: fix,
      metadata: const {'triageCategory': QaFailureTriage.fixture},
    );
  }
}

class _StandardFixtureSeed {
  const _StandardFixtureSeed({
    required this.id,
    required this.rawLine,
    required this.tradeScope,
    required this.localePackId,
  });

  final String id;
  final String rawLine;
  final String tradeScope;
  final String localePackId;
}
