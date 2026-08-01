// Regression tests for unit-aware trip distance presentation.
//
// Owns miles, kilometers, decimal convention, and truth-boundary checks.
// It does not test GPS acceptance, route geometry, settings UI, or persistence.

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/odometer/odometer_distance_value.dart';
import 'package:maintaniac/shared/trip_tracking/trip_distance_presentation.dart';

void main() {
  test('same accepted meters present as miles or kilometers', () {
    final miles = TripDistancePresentation.fromAcceptedMeters(
      acceptedMeters: 1609.344,
      displayUnit: OdometerDistanceUnit.miles,
    )!;
    final kilometers = TripDistancePresentation.fromAcceptedMeters(
      acceptedMeters: 1609.344,
      displayUnit: OdometerDistanceUnit.kilometers,
    )!;

    expect(miles.format(), '1.0');
    expect(miles.unitSymbol, 'mi');
    expect(kilometers.format(), '1.6');
    expect(kilometers.unitSymbol, 'km');
    expect(miles.acceptedMeters, kilometers.acceptedMeters);
  });

  test('French-style decimal comma does not alter stored evidence', () {
    final distance = TripDistancePresentation.fromAcceptedMeters(
      acceptedMeters: 12345,
      displayUnit: OdometerDistanceUnit.kilometers,
    )!;

    expect(
      distance.format(convention: OdometerNumberConvention.decimalComma),
      '12,3',
    );
    expect(distance.acceptedMeters, 12345);
    expect(distance.toSafeMap()['acceptedMetersChanged'], isFalse);
    expect(distance.toSafeMap()['odometerChanged'], isFalse);
    expect(distance.toSafeMap()['gpsTruthClaimed'], isFalse);
  });

  test('invalid accepted meter evidence fails closed', () {
    for (final value in [double.nan, double.infinity, -0.1]) {
      expect(
        TripDistancePresentation.fromAcceptedMeters(
          acceptedMeters: value,
          displayUnit: OdometerDistanceUnit.miles,
        ),
        isNull,
      );
    }
  });

  test('zero distance remains an explicit one-decimal value', () {
    final distance = TripDistancePresentation.fromAcceptedMeters(
      acceptedMeters: 0,
      displayUnit: OdometerDistanceUnit.miles,
    )!;

    expect(distance.format(), '0.0');
    expect(distance.displayValue.tenths, 0);
  });
}
