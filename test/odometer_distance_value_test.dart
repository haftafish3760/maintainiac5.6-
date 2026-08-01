// Regression tests for exact tenth-unit odometer parsing and display.
//
// Owns miles/kilometers, locale convention, serialization, range, and
// presentation-conversion coverage. It does not test vehicle settings,
// Dashboard widgets, trip GPS accuracy, or confirmed history mutation.

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/odometer/odometer_distance_value.dart';

void main() {
  test('whole Start Day input becomes an exact optional tenth', () {
    final value = OdometerDistanceValue.tryParse(
      '298,150',
      unit: OdometerDistanceUnit.miles,
    );

    expect(value?.tenths, 2981500);
    expect(value?.format(), '298,150.0');
  });

  test('one decimal digit is retained without floating-point mileage', () {
    final value = OdometerDistanceValue.tryParse(
      '298150.7',
      unit: OdometerDistanceUnit.miles,
    );

    expect(value?.tenths, 2981507);
    expect(value?.format(), '298,150.7');
  });

  test('hundredths and malformed grouping are rejected, not rounded', () {
    for (final raw in ['12.34', '1,00.0', '-1', '', '1 000.0']) {
      expect(
        OdometerDistanceValue.tryParse(raw, unit: OdometerDistanceUnit.miles),
        isNull,
        reason: raw,
      );
    }
  });

  test('decimal-comma countries retain exact kilometer tenths', () {
    final value = OdometerDistanceValue.tryParse(
      '123.456,7',
      unit: OdometerDistanceUnit.kilometers,
      convention: OdometerNumberConvention.decimalComma,
    );

    expect(value?.tenths, 1234567);
    expect(
      value?.format(convention: OdometerNumberConvention.decimalComma),
      '123.456,7',
    );
  });

  test('unit conversion is presentation-only and rounded to one tenth', () {
    final miles = OdometerDistanceValue.fromTenths(
      tenths: 100,
      unit: OdometerDistanceUnit.miles,
    )!;

    expect(miles.displayTenthsIn(OdometerDistanceUnit.kilometers), 161);
    expect(miles.tenths, 100);
    expect(miles.unit, OdometerDistanceUnit.miles);
  });

  test('differences require the same physical odometer unit', () {
    final start = OdometerDistanceValue.fromTenths(
      tenths: 1000,
      unit: OdometerDistanceUnit.miles,
    )!;
    final end = OdometerDistanceValue.fromTenths(
      tenths: 1017,
      unit: OdometerDistanceUnit.miles,
    )!;
    final kilometers = OdometerDistanceValue.fromTenths(
      tenths: 1017,
      unit: OdometerDistanceUnit.kilometers,
    )!;

    expect(end.differenceTenthsFrom(start), 17);
    expect(start.differenceTenthsFrom(end), isNull);
    expect(kilometers.differenceTenthsFrom(start), isNull);
  });

  test('serialized values preserve exact unit and tenths', () {
    final original = OdometerDistanceValue.fromTenths(
      tenths: 987654,
      unit: OdometerDistanceUnit.kilometers,
    )!;
    final restored = OdometerDistanceValue.fromMap(original.toMap());

    expect(restored?.tenths, original.tenths);
    expect(restored?.unit, original.unit);
  });

  test('invalid schemas, units, and oversized readings fail closed', () {
    expect(
      OdometerDistanceValue.fromMap(const {
        'schema': 'unknown',
        'tenths': 10,
        'unit': 'miles',
      }),
      isNull,
    );
    expect(
      OdometerDistanceValue.fromMap(const {
        'schema': OdometerDistanceValue.schema,
        'tenths': 10,
        'unit': 'yards',
      }),
      isNull,
    );
    expect(
      OdometerDistanceValue.fromTenths(
        tenths: OdometerDistanceValue.maximumTenths + 1,
        unit: OdometerDistanceUnit.miles,
      ),
      isNull,
    );
  });
}
