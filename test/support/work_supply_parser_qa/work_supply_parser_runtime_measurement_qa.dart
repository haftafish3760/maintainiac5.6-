import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserRuntimeMeasurementSuite extends QaSuite {
  const WorkSupplyParserRuntimeMeasurementSuite()
    : super('inventory.runtime_measurement');

  static const _probeLine = 'ELEC TAPE';
  static const _probeTradeScope = 'Electrical';
  static const _maxFullProbeMs = 120000;

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];

    if (!context.isFullProfile) {
      return timer.finish(
        suite: name,
        checked: 4,
        failures: failures,
        maxFailures: context.maxFailuresPerSuite,
        metrics: const {
          'mode': 'runtime-measurement-smoke',
          'parserCalls': 0,
          'coldStartMeasured': false,
          'warmCacheMeasured': false,
          'note':
              'Full/release profiles measure parser cold-ish and warm-cache probes.',
        },
      );
    }

    final coldTimer = Stopwatch()..start();
    final coldMatch = matchReceiptLineToCatalog(
      _probeLine,
      tradeScope: _probeTradeScope,
      maxCandidates: 24,
    );
    coldTimer.stop();

    final warmTimer = Stopwatch()..start();
    final warmMatch = matchReceiptLineToCatalog(
      _probeLine,
      tradeScope: _probeTradeScope,
      maxCandidates: 24,
    );
    warmTimer.stop();

    final totalProbeMs =
        coldTimer.elapsedMilliseconds + warmTimer.elapsedMilliseconds;
    if (coldMatch == null || warmMatch == null) {
      failures.add(
        QaFailure(
          suite: name,
          id: 'runtime_probe_missing_match',
          message: 'Runtime probe line did not produce a parser candidate.',
          severity: QaSeverity.error,
          expected: 'stable Electrical candidate for $_probeLine',
          actual:
              'cold=${coldMatch?.item.name ?? 'null'}; warm=${warmMatch?.item.name ?? 'null'}',
          suggestedFix:
              'Fix the runtime probe fixture or parser alias before using runtime metrics.',
          metadata: const {'triageCategory': QaFailureTriage.performance},
        ),
      );
    } else if (coldMatch.item.id != warmMatch.item.id) {
      failures.add(
        QaFailure(
          suite: name,
          id: 'runtime_probe_not_deterministic',
          message: 'Cold and warm runtime probes returned different items.',
          severity: QaSeverity.error,
          expected: coldMatch.item.id,
          actual: warmMatch.item.id,
          suggestedFix:
              'Parser runtime profiling must not hide nondeterministic candidate ranking.',
          metadata: const {'triageCategory': QaFailureTriage.performance},
        ),
      );
    }
    if (totalProbeMs > _maxFullProbeMs) {
      failures.add(
        QaFailure(
          suite: name,
          id: 'runtime_probe_exceeded_budget',
          message:
              'Runtime probe exceeded the full-profile measurement budget.',
          severity: QaSeverity.warning,
          expected: '<= $_maxFullProbeMs ms',
          actual: '$totalProbeMs ms',
          suggestedFix:
              'Profile catalog construction, receipt indexes, and fallback candidate scans.',
          metadata: const {'triageCategory': QaFailureTriage.performance},
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked: 4,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'parserCalls': 2,
        'probeLine': _probeLine,
        'tradeScope': _probeTradeScope,
        'coldStartMs': coldTimer.elapsedMilliseconds,
        'warmCacheMs': warmTimer.elapsedMilliseconds,
        'totalProbeMs': totalProbeMs,
        'coldMatchId': coldMatch?.item.id ?? '',
        'warmMatchId': warmMatch?.item.id ?? '',
      },
    );
  }
}
