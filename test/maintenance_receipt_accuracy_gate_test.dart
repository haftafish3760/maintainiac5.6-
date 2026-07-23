import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/maintenance/data/maintenance_receipt_parser.dart';
import 'package:maintaniac/screens/maintenance/maintenance_models.dart';

const _minimumAccuracy = .90;

void main() {
  final fixtures = _loadFixtures();

  test('development corpus measures every maintenance family', () {
    final expectedFamilies = <String>{
      for (final fixture in fixtures) ...fixture.actions.keys,
    };
    final catalogFamilies = maintenanceCatalog.map((item) => item.name).toSet();

    expect(expectedFamilies, unorderedEquals(catalogFamilies));
    expect(
      maintenanceReceiptSupportedItemNames,
      unorderedEquals(catalogFamilies),
    );
  });

  test('development corpus clears field-level 90 percent floor', () {
    var merchantCorrect = 0;
    var kindCorrect = 0;
    var exactCandidateSets = 0;
    final measurements = <String, _FamilyMeasurement>{
      for (final item in maintenanceCatalog)
        item.name: _FamilyMeasurement(item.name),
    };

    for (final fixture in fixtures) {
      final result = parseMaintenanceReceipt(
        MaintenanceReceiptParserInput(
          activeVehicleId: 'accuracy_vehicle',
          activeVehicleName: 'Accuracy Vehicle',
          currentOdometer: 100000,
          sourceText: fixture.sourceText,
        ),
      );
      if (result.merchantName == fixture.merchant) merchantCorrect++;
      if (result.kind.name == fixture.kind) kindCorrect++;

      final predicted = {
        for (final candidate in result.candidates)
          candidate.itemName: candidate.action.name,
      };
      if (_sameMap(predicted, fixture.actions)) exactCandidateSets++;

      for (final entry in measurements.entries) {
        final expectedAction = fixture.actions[entry.key];
        final predictedAction = predicted[entry.key];
        entry.value.observe(
          expectedAction: expectedAction,
          predictedAction: predictedAction,
        );
      }
    }

    _expectFloor('merchant accuracy', merchantCorrect, fixtures.length);
    _expectFloor('receipt-kind accuracy', kindCorrect, fixtures.length);
    _expectFloor(
      'exact candidate-set accuracy',
      exactCandidateSets,
      fixtures.length,
    );
    for (final measurement in measurements.values) {
      measurement.expectCommercialFloor();
    }
  });

  test(
    'accuracy floor is explicitly development evidence, not release proof',
    () {
      expect(_minimumAccuracy, .90);
      expect(
        File('docs/maintenance_receipt_parser_roadmap.md').readAsStringSync(),
        contains(
          'A green synthetic development gate is not real-receipt holdout proof.',
        ),
      );
    },
  );
}

List<_AccuracyFixture> _loadFixtures() {
  final decoded =
      jsonDecode(
            File(
              'test/fixtures/maintenance_receipts/synthetic_corpus.json',
            ).readAsStringSync(),
          )
          as List<dynamic>;
  return [
    for (final value in decoded)
      _AccuracyFixture.fromJson((value as Map).cast<String, dynamic>()),
  ];
}

class _AccuracyFixture {
  const _AccuracyFixture({
    required this.id,
    required this.merchant,
    required this.kind,
    required this.sourceText,
    required this.actions,
  });

  final String id;
  final String merchant;
  final String kind;
  final String sourceText;
  final Map<String, String> actions;

  factory _AccuracyFixture.fromJson(Map<String, dynamic> json) {
    final actions = (json['actions'] as Map).cast<String, String>();
    final fixture = _AccuracyFixture(
      id: '${json['id'] ?? ''}'.trim(),
      merchant: '${json['merchant'] ?? ''}'.trim(),
      kind: '${json['kind'] ?? ''}'.trim(),
      sourceText: '${json['sourceText'] ?? ''}',
      actions: Map.unmodifiable(actions),
    );
    if (fixture.id.isEmpty ||
        fixture.merchant.isEmpty ||
        fixture.kind.isEmpty ||
        fixture.sourceText.trim().isEmpty) {
      throw FormatException('Accuracy fixture is incomplete: ${fixture.id}');
    }
    return fixture;
  }
}

class _FamilyMeasurement {
  _FamilyMeasurement(this.family);

  final String family;
  int truePositive = 0;
  int falsePositive = 0;
  int falseNegative = 0;
  int expectedActions = 0;
  int correctActions = 0;

  void observe({
    required String? expectedAction,
    required String? predictedAction,
  }) {
    if (expectedAction != null) {
      expectedActions++;
      if (predictedAction == null) {
        falseNegative++;
      } else {
        truePositive++;
        if (predictedAction == expectedAction) correctActions++;
      }
    } else if (predictedAction != null) {
      falsePositive++;
    }
  }

  void expectCommercialFloor() {
    expect(expectedActions, greaterThan(0), reason: '$family fixture coverage');
    _expectFloor(
      '$family precision',
      truePositive,
      truePositive + falsePositive,
    );
    _expectFloor('$family recall', truePositive, truePositive + falseNegative);
    _expectFloor('$family action accuracy', correctActions, expectedActions);
  }
}

void _expectFloor(String label, int correct, int total) {
  expect(total, greaterThan(0), reason: '$label denominator');
  final measured = correct / total;
  expect(
    measured,
    greaterThanOrEqualTo(_minimumAccuracy),
    reason: '$label was ${(measured * 100).toStringAsFixed(2)}%',
  );
}

bool _sameMap(Map<String, String> first, Map<String, String> second) {
  if (first.length != second.length) return false;
  for (final entry in first.entries) {
    if (second[entry.key] != entry.value) return false;
  }
  return true;
}
