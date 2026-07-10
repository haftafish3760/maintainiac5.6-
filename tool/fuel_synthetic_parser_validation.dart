part of 'fuel_synthetic_parser_runner.dart';

void _checkExpectedFuelLine(
  List<String> issues,
  Iterable<dynamic> fuelLines, {
  required String fuelType,
  required double quantity,
  required double amount,
  required double unitPrice,
  required String unit,
  required int? odometer,
  required String fillType,
}) {
  final matches = fuelLines.where((line) => line.fuelType == fuelType);
  if (matches.length != 1) {
    issues.add('fuel_type_${fuelType}_line_count_${matches.length}');
    return;
  }
  final fuel = matches.single;
  _expectNear(
    issues,
    field: '${fuelType}_quantity',
    actual: fuel.quantity,
    expected: quantity,
  );
  _expectNear(
    issues,
    field: '${fuelType}_subtotal',
    actual: fuel.subtotal,
    expected: amount,
  );
  _expectNear(
    issues,
    field: '${fuelType}_unit_price',
    actual: fuel.unitPrice,
    expected: unitPrice,
    tolerance: .015,
  );
  if (fuel.unit != unit) {
    issues.add('${fuelType}_unit_expected_${unit}_got_${fuel.unit}');
  }
  if (odometer != null && fuel.odometerReading != odometer) {
    issues.add(
      '${fuelType}_odometer_expected_${odometer}_got_${fuel.odometerReading}',
    );
  }
  if (fuel.fillType != fillType) {
    issues.add(
      '${fuelType}_fill_type_expected_${fillType}_got_${fuel.fillType}',
    );
  }
}

String _commaDecimalText(String text) {
  return text.replaceAllMapped(RegExp(r'\b(\d+)\.(\d{2,4})\b'), (match) {
    return '${match.group(1)},${match.group(2)}';
  });
}

String _dirtyFuelText(String text) {
  return text
      .replaceAll('PRICE', 'PR1CE')
      .replaceAll('Price', 'Pr1ce')
      .replaceAll('GALLONS', 'GALL0NS')
      .replaceAll('Gallons', 'Gall0ns')
      .replaceAll('FUEL', 'FUE1')
      .replaceAll('Fuel', 'Fue1')
      .replaceAll('DIESEL', 'D1ESEL')
      .replaceAll('Diesel', 'D1esel')
      .replaceAll(' GAL ', ' GA1 ');
}
