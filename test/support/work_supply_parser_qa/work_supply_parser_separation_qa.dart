import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserSeparationSafetySuite extends QaSuite {
  const WorkSupplyParserSeparationSafetySuite()
    : super('inventory.separation_safety');

  static const _cases = [
    _SeparationCase(
      id: 'sku_only_not_item',
      line: 'SKU 123456 789012',
      risk:
          'SKU or part number tokens must not become normal item words by themselves.',
      expectedDisposition: 'unknown_or_review',
    ),
    _SeparationCase(
      id: 'same_sku_unknown_merchant',
      line: '123456 PVC',
      risk:
          'Same-looking numbers across merchants must not automatically identify an item.',
      expectedDisposition: 'unknown_or_review',
    ),
    _SeparationCase(
      id: 'brand_only_not_identity',
      line: 'SHARKBITE 1/2',
      risk:
          'Brand names are hints, not complete canonical item identity without type evidence.',
      expectedDisposition: 'unknown_or_review',
    ),
    _SeparationCase(
      id: 'model_only_not_material',
      line: 'M18 5.0 BATTERY',
      risk:
          'Tool batteries and model numbers must not be forced into material inventory.',
      expectedDisposition: 'tool_or_review',
    ),
    _SeparationCase(
      id: 'tool_not_stock_material',
      line: 'MILWAUKEE PIPE WRENCH 14 IN',
      risk:
          'Tools should stay separate from countable job materials unless equipment inventory is explicit.',
      expectedDisposition: 'tool_or_review',
    ),
    _SeparationCase(
      id: 'consumable_not_countable_material',
      line: 'PVC PRIMER PURPLE 8 OZ',
      risk:
          'Primer/cement/solvent can be consumables, not pipe or fitting stock.',
      expectedDisposition: 'consumable_or_review',
    ),
    _SeparationCase(
      id: 'sealant_not_stock_material',
      line: 'SILICONE CAULK WHITE 10 OZ',
      risk:
          'Caulk/sealant should classify as consumable or review, not structural material.',
      expectedDisposition: 'consumable_or_review',
    ),
    _SeparationCase(
      id: 'fee_not_inventory',
      line: 'ENVIRONMENTAL FEE 2.00',
      risk:
          'Fees must remain linked to the evidence and never become inventory items.',
      expectedDisposition: 'not_inventory',
    ),
    _SeparationCase(
      id: 'deposit_not_inventory',
      line: 'CORE CHARGE DEPOSIT 18.00',
      risk: 'Deposits/core charges must not become inventory stock.',
      expectedDisposition: 'not_inventory',
    ),
    _SeparationCase(
      id: 'return_not_stock_increase',
      line: 'RETURN -1 1/2 PEX ELBOW -3.29',
      risk: 'Returns and negative quantities must never increase stock.',
      expectedDisposition: 'return_review',
    ),
    _SeparationCase(
      id: 'pvc_conduit_not_plumbing_pipe',
      line: '3/4 PVC COND COUPLING',
      risk:
          'PVC conduit should not be forced into plumbing when electrical context is visible.',
      expectedDisposition: 'cross_trade_review',
    ),
    _SeparationCase(
      id: 'water_filter_not_hvac_filter',
      line: 'WATER FILTER CARTRIDGE 10 IN',
      risk:
          'Filter terms must preserve water/HVAC/oil ambiguity unless enough evidence exists.',
      expectedDisposition: 'cross_trade_review',
    ),
  ];

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final dispositions = <String, int>{};
    final unique = <String>{};

    for (final testCase in _cases) {
      dispositions.update(
        testCase.expectedDisposition,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      final normalized = _normalize(testCase.line);
      if (!unique.add(normalized)) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'duplicate_separation_case:${testCase.id}',
            message: 'Separation safety case duplicates another case line.',
            severity: QaSeverity.warning,
            actual: testCase.line,
            suggestedFix:
                'Keep separation cases distinct so each one protects a unique parser boundary.',
            metadata: const {'triageCategory': QaFailureTriage.fixture},
          ),
        );
      }
    }

    if (context.isFullProfile) {
      for (final testCase in _cases.take(context.maxGeneratedCases)) {
        final match = matchReceiptLineToCatalog(
          testCase.line,
          maxCandidates: 24,
        );
        if (match == null) continue;
        if (_isUnsafeConfidentMatch(testCase, match)) {
          failures.add(
            QaFailure(
              suite: name,
              id: 'unsafe_separation_match:${testCase.id}',
              message:
                  'Risky separation case produced a confident inventory match.',
              expected: testCase.expectedDisposition,
              actual:
                  '${match.item.trade} / ${match.item.name} confidence=${match.confidence}',
              suggestedFix:
                  'Add SKU/brand/tool/consumable/fee/return separation rules or lower confidence until review context is available.',
              metadata: {
                'triageCategory': QaFailureTriage.conflict,
                'risk': testCase.risk,
                'line': context.redactor(testCase.line),
              },
            ),
          );
        }
      }
    }

    return timer.finish(
      suite: name,
      checked:
          _cases.length +
          (context.isFullProfile
              ? _cases.take(context.maxGeneratedCases).length
              : 0),
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'caseCount': _cases.length,
        'uniqueCaseCount': unique.length,
        'dispositions': dispositions,
        'parserCalls': context.isFullProfile
            ? _cases.take(context.maxGeneratedCases).length
            : 0,
      },
    );
  }

  bool _isUnsafeConfidentMatch(
    _SeparationCase testCase,
    ReceiptLineMatch match,
  ) {
    if (match.confidence < .82) return false;
    final itemText = _normalize(
      '${match.item.trade} ${match.item.category} ${match.item.system} '
      '${match.item.itemType} ${match.item.name} ${match.item.variant}',
    );
    switch (testCase.expectedDisposition) {
      case 'not_inventory':
      case 'return_review':
      case 'unknown_or_review':
        return true;
      case 'tool_or_review':
        return !itemText.contains('tool') && !itemText.contains('safety');
      case 'consumable_or_review':
        return !itemText.contains('consumable') &&
            !itemText.contains('adhesive') &&
            !itemText.contains('sealant') &&
            !itemText.contains('primer') &&
            !itemText.contains('cement');
      case 'cross_trade_review':
        return true;
      default:
        return true;
    }
  }
}

class _SeparationCase {
  const _SeparationCase({
    required this.id,
    required this.line,
    required this.risk,
    required this.expectedDisposition,
  });

  final String id;
  final String line;
  final String risk;
  final String expectedDisposition;
}

String _normalize(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9/\-.\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
