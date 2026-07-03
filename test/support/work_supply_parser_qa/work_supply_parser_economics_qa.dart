import 'dart:convert';
import 'dart:io';

import 'package:maintaniac/screens/work_supplies/data/work_supply_parser_candidate_models.dart';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserEconomicsContractSuite extends QaSuite {
  const WorkSupplyParserEconomicsContractSuite()
    : super('inventory.economics_contract');

  static const _validPurchaseTypes = {
    'each',
    'pack',
    'box',
    'case',
    'bag',
    'roll',
    'linear_foot',
    'square_foot',
  };

  static const _validUnits = {
    'each',
    'ea',
    'piece',
    'pc',
    'ft',
    'lf',
    'sq ft',
    'roll',
    'pack',
    'box',
    'case',
    'bag',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final fixtures = _loadFixtures()
        .where((fixture) => fixture.caseType == 'quantity_price')
        .toList(growable: false);

    for (final fixture in fixtures) {
      _positiveNumber(
        failures,
        fixture,
        'expectedQuantity',
        fixture.expectedQuantity,
      );
      _positiveNumber(
        failures,
        fixture,
        'expectedUnitsPerPackage',
        fixture.expectedUnitsPerPackage,
      );
      _positiveNumber(
        failures,
        fixture,
        'expectedSubtotal',
        fixture.expectedSubtotal,
      );
      final taxRate = fixture.expectedTaxRate;
      if (taxRate < 0 || taxRate > .2) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'invalid_tax_rate:${fixture.id}',
            message: 'Quantity/price fixture has invalid expectedTaxRate.',
            expected: '0.0 through 0.2',
            actual: '$taxRate',
            suggestedFix:
                'Use decimal tax rate such as 0.053 or 0 for untaxed fixture lines.',
          ),
        );
      }
      if (!_validPurchaseTypes.contains(fixture.expectedPurchaseType)) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'invalid_purchase_type:${fixture.id}',
            message: 'Quantity/price fixture has unsupported purchase type.',
            expected: _validPurchaseTypes.join(', '),
            actual: fixture.expectedPurchaseType,
            suggestedFix:
                'Normalize purchase type so inventory math can calculate package and unit costs.',
          ),
        );
      }
      if (!_validUnits.contains(fixture.expectedUnit)) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'invalid_unit:${fixture.id}',
            message: 'Quantity/price fixture has unsupported expected unit.',
            expected: _validUnits.join(', '),
            actual: fixture.expectedUnit,
            suggestedFix:
                'Use a supported inventory unit or extend the contract intentionally.',
          ),
        );
      }
      final totalUnits =
          fixture.expectedQuantity * fixture.expectedUnitsPerPackage;
      if (totalUnits <= 0) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'non_positive_total_units:${fixture.id}',
            message:
                'Quantity/price fixture cannot produce positive total units.',
            expected: '> 0',
            actual: '$totalUnits',
            suggestedFix:
                'Fix quantity or unitsPerPackage so unit-cost math is safe.',
          ),
        );
      }
      final unitCostWithTax = totalUnits <= 0
          ? 0.0
          : (fixture.expectedSubtotal * (1 + fixture.expectedTaxRate)) /
                totalUnits;
      if (unitCostWithTax <= 0 || unitCostWithTax.isNaN) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'invalid_unit_cost:${fixture.id}',
            message:
                'Quantity/price fixture cannot compute positive unit cost.',
            expected: 'positive unit cost',
            actual: '$unitCostWithTax',
            suggestedFix:
                'Fix expected subtotal, tax rate, quantity, or pack quantity.',
          ),
        );
      }
      final candidate = WorkSupplyParserCandidate(
        rawLine: fixture.id,
        cleanedLine: fixture.id,
        reviewStatus: 'needsReview',
        suggestedInventoryAction: WorkSupplyParserSuggestedAction.reviewOnly,
        quantityPurchased: fixture.expectedQuantity,
        packageQuantity: fixture.expectedUnitsPerPackage,
        stockQuantityCandidate: totalUnits,
        unit: fixture.expectedUnit,
        unitPrice: unitCostWithTax,
        lineTotal: fixture.expectedSubtotal * (1 + fixture.expectedTaxRate),
      );
      final restored = WorkSupplyParserCandidate.fromMap(candidate.toMap());
      if (!restored.hasConsistentStockQuantity) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'candidate_stock_quantity_mismatch:${fixture.id}',
            message:
                'Parser candidate quantity/package extraction does not reconcile stock quantity.',
            expected: '${restored.calculatedStockQuantity}',
            actual: '${restored.stockQuantityCandidate}',
            suggestedFix:
                'Keep quantityPurchased, packageQuantity, and stockQuantityCandidate mathematically aligned before routing to inventory, jobs, or estimates.',
            metadata: const {'triageCategory': QaFailureTriage.quantity},
          ),
        );
      }
      if ((restored.calculatedUnitPrice - unitCostWithTax).abs() > .01) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'candidate_unit_price_mismatch:${fixture.id}',
            message:
                'Parser candidate unit price does not reconcile from line total and stock quantity.',
            expected: unitCostWithTax.toStringAsFixed(2),
            actual: restored.calculatedUnitPrice.toStringAsFixed(2),
            suggestedFix:
                'Preserve lineTotal and package quantity so estimate/job material costing remains accurate.',
            metadata: const {'triageCategory': QaFailureTriage.economics},
          ),
        );
      }
    }

    if (fixtures.isEmpty) {
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_quantity_price_fixtures',
          message: 'No quantity/price fixtures are available.',
          severity: QaSeverity.warning,
          expected: 'at least one quantity_price fixture',
          actual: '0',
          suggestedFix:
              'Add receipt fixtures that exercise quantity, package quantity, unit, subtotal, and tax math.',
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked: fixtures.length * 9 + 1,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'quantityPriceFixtureCount': fixtures.length,
        'candidateExtractionChecksPerFixture': 2,
      },
    );
  }

  void _positiveNumber(
    List<QaFailure> failures,
    _EconomicsFixture fixture,
    String field,
    double value,
  ) {
    if (value > 0 && !value.isNaN) return;
    failures.add(
      QaFailure(
        suite: name,
        id: 'invalid_$field:${fixture.id}',
        message: 'Quantity/price fixture field must be a positive number.',
        expected: '> 0',
        actual: '$value',
        suggestedFix: 'Set $field to a positive numeric value.',
      ),
    );
  }
}

class _EconomicsFixture {
  const _EconomicsFixture({
    required this.id,
    required this.caseType,
    required this.expectedQuantity,
    required this.expectedUnitsPerPackage,
    required this.expectedPurchaseType,
    required this.expectedUnit,
    required this.expectedSubtotal,
    required this.expectedTaxRate,
  });

  final String id;
  final String caseType;
  final double expectedQuantity;
  final double expectedUnitsPerPackage;
  final String expectedPurchaseType;
  final String expectedUnit;
  final double expectedSubtotal;
  final double expectedTaxRate;

  static _EconomicsFixture fromJson(Map<String, Object?> json) {
    return _EconomicsFixture(
      id: json['id'] as String? ?? 'fixture_without_id',
      caseType: json['caseType'] as String? ?? '',
      expectedQuantity: _double(json['expectedQuantity']),
      expectedUnitsPerPackage: _double(json['expectedUnitsPerPackage']),
      expectedPurchaseType: json['expectedPurchaseType'] as String? ?? '',
      expectedUnit: json['expectedUnit'] as String? ?? '',
      expectedSubtotal: _double(json['expectedSubtotal']),
      expectedTaxRate: _double(json['expectedTaxRate']),
    );
  }
}

List<_EconomicsFixture> _loadFixtures() {
  final file = File('test/fixtures/work_supply_parser/golden_fixtures.json');
  if (!file.existsSync()) return const [];
  final decoded = jsonDecode(file.readAsStringSync()) as List<dynamic>;
  return [
    for (final entry in decoded)
      _EconomicsFixture.fromJson((entry as Map).cast<String, Object?>()),
  ];
}

double _double(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
