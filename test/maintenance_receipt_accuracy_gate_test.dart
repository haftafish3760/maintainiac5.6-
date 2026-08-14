import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/maintenance/data/maintenance_receipt_parser.dart';
import 'package:maintaniac/screens/maintenance/maintenance_models.dart';

import 'support/maintenance_receipt_synthetic_corpus.dart';

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
      final predictedCandidates = {
        for (final candidate in result.candidates)
          candidate.itemName: candidate,
      };
      if (_sameMap(predicted, fixture.actions)) exactCandidateSets++;

      for (final entry in measurements.entries) {
        final expectedAction = fixture.actions[entry.key];
        final predictedAction = predicted[entry.key];
        entry.value.observe(
          expectedAction: expectedAction,
          predictedAction: predictedAction,
          expectedFields: fixture.fields[entry.key] ?? const {},
          predictedFields: predictedCandidates[entry.key]?.toJson() ?? const {},
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
  return [
    for (final value in loadMaintenanceReceiptSyntheticCorpus())
      _AccuracyFixture.fromJson(value),
  ];
}

class _AccuracyFixture {
  const _AccuracyFixture({
    required this.id,
    required this.merchant,
    required this.kind,
    required this.sourceText,
    required this.actions,
    required this.fields,
  });

  final String id;
  final String merchant;
  final String kind;
  final String sourceText;
  final Map<String, String> actions;
  final Map<String, Map<String, Object?>> fields;

  factory _AccuracyFixture.fromJson(Map<String, dynamic> json) {
    final actions = (json['actions'] as Map).cast<String, String>();
    final rawFields = (json['fields'] as Map?) ?? const <String, Object?>{};
    final fixture = _AccuracyFixture(
      id: '${json['id'] ?? ''}'.trim(),
      merchant: '${json['merchant'] ?? ''}'.trim(),
      kind: '${json['kind'] ?? ''}'.trim(),
      sourceText: '${json['sourceText'] ?? ''}',
      actions: Map.unmodifiable(actions),
      fields: Map<String, Map<String, Object?>>.unmodifiable({
        for (final entry in rawFields.entries)
          '${entry.key}': Map<String, Object?>.unmodifiable(
            Map<String, Object?>.from(entry.value as Map),
          ),
      }),
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
  final Map<String, int> expectedFields = {};
  final Map<String, int> correctFields = {};

  void observe({
    required String? expectedAction,
    required String? predictedAction,
    required Map<String, Object?> expectedFields,
    required Map<String, Object?> predictedFields,
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
    for (final field in expectedFields.entries) {
      this.expectedFields.update(
        field.key,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      if (predictedFields[field.key] == field.value) {
        correctFields.update(
          field.key,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }
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
    for (final field in expectedFields.entries) {
      _expectFloor(
        '$family ${field.key} accuracy',
        correctFields[field.key] ?? 0,
        field.value,
      );
    }
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
