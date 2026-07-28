import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/trip_tracking_qa/trip_tracking_field_evidence.dart';

void main() {
  test('real-device field-evidence template stays safely importable', () {
    final decoded = jsonDecode(
      File(
        'docs/gps_assisted_tracking/GPS_FIELD_EVIDENCE_TEMPLATE.json',
      ).readAsStringSync(),
    );
    final evidence = TripTrackingFieldEvidence.fromMap(
      Map<String, Object?>.from(decoded as Map),
    );

    expect(evidence.toSafeSummary()['coordinatesIncluded'], isFalse);
    expect(evidence.toSafeSummary()['routeGeometryIncluded'], isFalse);
  });

  test('field evidence compares only coordinate-minimized mileage', () {
    final evidence = TripTrackingFieldEvidence.fromMap({
      'platform': 'android',
      'odometerMiles': 10.0,
      'filteredGpsMiles': 9.8,
      'expectedWalkingStops': 3,
      'detectedWalkingStops': 2,
      'matchedWalkingStops': 2,
    });
    expect(evidence.absoluteDistanceErrorMiles, closeTo(.2, .0001));
    expect(evidence.toSafeSummary()['coordinatesIncluded'], isFalse);
    expect(evidence.toSafeSummary()['walkingStopCountDelta'], -1);
    expect(evidence.toSafeSummary()['missedWalkingStops'], 1);
    expect(evidence.toSafeSummary()['falseWalkingStops'], 0);
    expect(evidence.toSafeSummary()['providerRequestObserved'], isFalse);
    expect(evidence.toSafeSummary()['backgroundCollectionObserved'], isFalse);
    expect(
      evidence.toSafeSummary()['recoveryAfterBackgroundObserved'],
      isFalse,
    );
  });

  test('field evidence rejects coordinates and invalid values', () {
    expect(
      () => TripTrackingFieldEvidence.fromMap({
        'platform': 'ios',
        'odometerMiles': 1.0,
        'filteredGpsMiles': 1.0,
        'latitude': 35.0,
      }),
      throwsFormatException,
    );
    expect(
      () => TripTrackingFieldEvidence.fromMap({
        'platform': 'ios',
        'odometerMiles': 100000.1,
        'filteredGpsMiles': 1.0,
      }),
      throwsFormatException,
    );
  });

  test('field evidence rejects abbreviated coordinates and precise time', () {
    for (final unsafeKey in const ['lat', 'lng', 'polyline', 'recordedAt']) {
      expect(
        () => TripTrackingFieldEvidence.fromMap({
          'platform': 'ios',
          'odometerMiles': 1.0,
          'filteredGpsMiles': 1.0,
          unsafeKey: 'unsafe',
        }),
        throwsFormatException,
        reason: unsafeKey,
      );
    }
  });

  test('field evidence rejects arbitrary metadata fields', () {
    expect(
      () => TripTrackingFieldEvidence.fromMap({
        'platform': 'android',
        'odometerMiles': 1.0,
        'filteredGpsMiles': 1.0,
        'notes': 'customer address',
      }),
      throwsFormatException,
    );
  });

  test('field evidence rejects malformed walking-stop counts', () {
    expect(
      () => TripTrackingFieldEvidence.fromMap({
        'platform': 'android',
        'odometerMiles': 10.0,
        'filteredGpsMiles': 9.8,
        'expectedWalkingStops': -1,
      }),
      throwsFormatException,
    );
    expect(
      () => TripTrackingFieldEvidence.fromMap({
        'platform': 'android',
        'odometerMiles': 10.0,
        'filteredGpsMiles': 9.8,
        'expectedWalkingStops': 10001,
      }),
      throwsFormatException,
    );
  });

  test('field evidence rejects impossible stop matching totals', () {
    expect(
      () => TripTrackingFieldEvidence.fromMap({
        'platform': 'ios',
        'odometerMiles': 10.0,
        'filteredGpsMiles': 9.8,
        'expectedWalkingStops': 1,
        'detectedWalkingStops': 1,
        'matchedWalkingStops': 2,
      }),
      throwsFormatException,
    );
  });

  test('field evidence requires provider proof before background recovery', () {
    for (final evidence in [
      {
        'platform': 'android',
        'odometerMiles': 1.0,
        'filteredGpsMiles': 1.0,
        'backgroundCollectionObserved': true,
      },
      {
        'platform': 'android',
        'odometerMiles': 1.0,
        'filteredGpsMiles': 1.0,
        'providerRequestObserved': true,
        'recoveryAfterBackgroundObserved': true,
      },
    ]) {
      expect(
        () => TripTrackingFieldEvidence.fromMap(evidence),
        throwsFormatException,
      );
    }
  });
}
