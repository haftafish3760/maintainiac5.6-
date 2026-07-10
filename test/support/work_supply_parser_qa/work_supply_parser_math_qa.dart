import 'dart:convert';
import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserReceiptMathSuite extends QaSuite {
  const WorkSupplyParserReceiptMathSuite()
    : super('inventory.math_reconciliation');

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final fixtures = _loadFixtures()
        .where((fixture) => fixture.caseType == 'quantity_price')
        .toList(growable: false);

    for (final fixture in fixtures) {
      final totalUnits =
          fixture.expectedQuantity * fixture.expectedUnitsPerPackage;
      final taxAmount = fixture.expectedSubtotal * fixture.expectedTaxRate;
      final lineTotal = fixture.expectedSubtotal + taxAmount;
      final unitCost = totalUnits <= 0 ? 0.0 : lineTotal / totalUnits;
      _closeTo(
        failures,
        fixture,
        field: 'line_total',
        actual: lineTotal,
        expected: fixture.expectedLineTotal,
        tolerance: .01,
      );
      _positive(failures, fixture, field: 'total_units', value: totalUnits);
      _positive(failures, fixture, field: 'unit_cost', value: unitCost);
      if (fixture.expectedUnit == 'ft' &&
          fixture.expectedPurchaseType != 'linear_foot') {
        failures.add(
          QaFailure(
            suite: name,
            id: 'linear_unit_wrong_purchase_type:${fixture.id}',
            message: 'Linear-foot fixture must use linear_foot purchase type.',
            expected: 'linear_foot',
            actual: fixture.expectedPurchaseType,
            suggestedFix:
                'Keep unit and purchase type aligned so estimate/job material costing stays correct.',
          ),
        );
      }
      if (fixture.expectedPurchaseType == 'pack' &&
          fixture.expectedUnitsPerPackage <= 1) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'pack_without_pack_quantity:${fixture.id}',
            message: 'Pack fixture does not carry unitsPerPackage > 1.',
            expected: '> 1',
            actual: '${fixture.expectedUnitsPerPackage}',
            suggestedFix:
                'Set unitsPerPackage so inventory stock and job costing split package purchases correctly.',
          ),
        );
      }
    }

    return timer.finish(
      suite: name,
      checked: fixtures.length * 5,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {'quantityPriceFixtureCount': fixtures.length},
    );
  }

  void _closeTo(
    List<QaFailure> failures,
    _MathFixture fixture, {
    required String field,
    required double actual,
    required double expected,
    required double tolerance,
  }) {
    if ((actual - expected).abs() <= tolerance) return;
    failures.add(
      QaFailure(
        suite: name,
        id: '${field}_mismatch:${fixture.id}',
        message: 'Receipt math fixture does not reconcile.',
        expected: expected.toStringAsFixed(2),
        actual: actual.toStringAsFixed(2),
        suggestedFix:
            'Fix quantity, subtotal, tax rate, or expected total for this fixture.',
      ),
    );
  }

  void _positive(
    List<QaFailure> failures,
    _MathFixture fixture, {
    required String field,
    required double value,
  }) {
    if (value > 0 && !value.isNaN && !value.isInfinite) return;
    failures.add(
      QaFailure(
        suite: name,
        id: 'invalid_$field:${fixture.id}',
        message: 'Receipt math produced an invalid value.',
        expected: 'positive finite number',
        actual: '$value',
        suggestedFix:
            'Fix fixture economics so material costing is safe to use for inventory, jobs, and estimates.',
      ),
    );
  }
}

class _MathFixture {
  const _MathFixture({
    required this.id,
    required this.caseType,
    required this.expectedQuantity,
    required this.expectedUnitsPerPackage,
    required this.expectedPurchaseType,
    required this.expectedUnit,
    required this.expectedSubtotal,
    required this.expectedTaxRate,
    required this.expectedLineTotal,
  });

  final String id;
  final String caseType;
  final double expectedQuantity;
  final double expectedUnitsPerPackage;
  final String expectedPurchaseType;
  final String expectedUnit;
  final double expectedSubtotal;
  final double expectedTaxRate;
  final double expectedLineTotal;

  static _MathFixture fromJson(Map<String, Object?> json) {
    final subtotal = _double(json['expectedSubtotal']);
    final taxRate = _double(json['expectedTaxRate']);
    return _MathFixture(
      id: json['id'] as String? ?? 'fixture_without_id',
      caseType: json['caseType'] as String? ?? '',
      expectedQuantity: _double(json['expectedQuantity']),
      expectedUnitsPerPackage: _double(json['expectedUnitsPerPackage']),
      expectedPurchaseType: json['expectedPurchaseType'] as String? ?? '',
      expectedUnit: json['expectedUnit'] as String? ?? '',
      expectedSubtotal: subtotal,
      expectedTaxRate: taxRate,
      expectedLineTotal: _double(
        json['expectedLineTotal'],
        fallback: subtotal * (1 + taxRate),
      ),
    );
  }
}

List<_MathFixture> _loadFixtures() {
  final file = File('test/fixtures/work_supply_parser/golden_fixtures.json');
  if (!file.existsSync()) return const [];
  final decoded = jsonDecode(file.readAsStringSync()) as List<dynamic>;
  return [
    for (final entry in decoded)
      _MathFixture.fromJson((entry as Map).cast<String, Object?>()),
  ];
}

double _double(Object? value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}
