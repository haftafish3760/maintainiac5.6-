import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserMerchantSuite extends QaSuite {
  const WorkSupplyParserMerchantSuite() : super('inventory.merchant_rules');

  static const _merchantAliases = {
    'THE HOME DEPOT #4655': 'home depot',
    'HD SUPPLY': 'home depot',
    'LOWE S HOME IMPROVEMENT': 'lowes',
    'LOWES #1184': 'lowes',
    'ACE HARDWARE': 'ace hardware',
    'FERGUSON ENTERPRISES': 'ferguson',
    'GRAINGER': 'grainger',
    'MENARDS': 'menards',
    'TRUE VALUE HARDWARE': 'true value',
    'WAL MART': 'walmart',
    'TRACTOR SUPPLY CO': 'tractor supply',
    'SUPPLYHOUSE.COM': 'supplyhouse',
    'WINSUPPLY': 'winsupply',
  };

  static const _merchantNoiseLines = [
    'THE HOME DEPOT STORE 4655',
    'LOWES HOME IMPROVEMENT',
    'ACE HARDWARE REWARDS',
    'FERGUSON COUNTER SALE',
    'GRAINGER WILL CALL',
    'MENARDS BIG CARD',
    'WALMART PAY',
    'TRACTOR SUPPLY CLUB',
    'SKU ITEM QTY EA',
  ];

  static const _skuDepartmentPatternLines = [
    'SKU 123456 ITEM 789 QTY 1 EA',
    'DEPT 26 PLUMBING AISLE 12 BAY 004',
    'LOWES ITEM # 123456 MODEL ABC-123',
    'HOME DEPOT SKU 000-000 DEPT 26',
    'AISLE 7 BAY 14 SHELF 2',
    'MFG MODEL UPC SKU QTY PRICE',
  ];

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final failures = <QaFailure>[];

    for (final entry in _merchantAliases.entries) {
      final actual = normalizeMerchantName(entry.key);
      if (actual != entry.value) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'merchant_alias:${_id(entry.key)}',
            message: 'Merchant alias normalized to the wrong canonical key.',
            expected: entry.value,
            actual: actual,
            suggestedFix:
                'Update receiptMerchantAliases before merchant-specific parser rules rely on this name.',
          ),
        );
      }
    }

    for (final line in _skuDepartmentPatternLines) {
      if (_looksLikeMerchantSkuOrDepartmentLine(line)) continue;
      failures.add(
        QaFailure(
          suite: name,
          id: 'merchant_structure_pattern:${_id(line)}',
          message:
              'Synthetic merchant SKU/department/header pattern was not recognized as structural receipt text.',
          expected: 'merchant structural line',
          actual: 'not recognized',
          suggestedFix:
              'Keep SKU, item, department, aisle, bay, model, and header-only lines out of confident item matching.',
          metadata: const {'triageCategory': QaFailureTriage.merchantRule},
        ),
      );
    }

    var warmupMs = 0;
    final slowestNoiseLines = <Map<String, Object?>>[];
    if (context.isFullProfile) {
      final warmup = Stopwatch()..start();
      for (final line in _merchantNoiseLines.take(3)) {
        matchReceiptLineToCatalog(line, maxCandidates: 12);
      }
      warmup.stop();
      warmupMs = warmup.elapsedMilliseconds;
    }

    final timer = QaStopwatch.start();
    if (context.isFullProfile) {
      for (final line in _merchantNoiseLines) {
        final lineTimer = Stopwatch()..start();
        final match = matchReceiptLineToCatalog(line, maxCandidates: 12);
        lineTimer.stop();
        slowestNoiseLines.add({
          'lineId': _id(line),
          'durationMs': lineTimer.elapsedMilliseconds,
        });
        if (match == null) continue;
        if (match.confidence >= .62) {
          failures.add(
            QaFailure(
              suite: name,
              id: 'merchant_noise_match:${_id(line)}',
              message: 'Merchant/noise receipt line produced an item match.',
              expected: 'unknown/no inventory candidate',
              actual:
                  '${match.item.trade} / ${match.item.name} confidence=${match.confidence}',
              suggestedFix:
                  'Add merchant/noise filters before SKU and department lines reach item scoring.',
            ),
          );
        }
      }
      slowestNoiseLines.sort(
        (a, b) => (b['durationMs'] as int).compareTo(a['durationMs'] as int),
      );
    }

    return timer.finish(
      suite: name,
      checked:
          _merchantAliases.length +
          _skuDepartmentPatternLines.length +
          (context.isFullProfile ? _merchantNoiseLines.length : 0),
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'merchantAliasCount': _merchantAliases.length,
        'skuDepartmentPatternCount': _skuDepartmentPatternLines.length,
        'noiseLineCount': _merchantNoiseLines.length,
        'parserCalls': context.isFullProfile ? _merchantNoiseLines.length : 0,
        'warmupMs': warmupMs,
        'slowestNoiseLines': slowestNoiseLines.take(5).toList(),
      },
    );
  }

  bool _looksLikeMerchantSkuOrDepartmentLine(String line) {
    final normalized = line.toLowerCase();
    final hasSkuOrItem = RegExp(
      r'\b(sku|item|model|upc|mfg)\b',
    ).hasMatch(normalized);
    final hasDepartmentOrLocation = RegExp(
      r'\b(dept|department|aisle|bay|shelf)\b',
    ).hasMatch(normalized);
    final hasHeaderColumns = RegExp(r'\b(qty|price|ea)\b').hasMatch(normalized);
    final hasModelNumber = RegExp(
      r'\bmodel\b.*\b[a-z0-9-]{3,}\b',
    ).hasMatch(normalized);
    return hasDepartmentOrLocation ||
        (hasSkuOrItem && (hasHeaderColumns || hasModelNumber));
  }

  String _id(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}
