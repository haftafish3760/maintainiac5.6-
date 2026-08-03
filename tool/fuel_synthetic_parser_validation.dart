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

String _sectionedFuelReceiptText(String text, {required int style}) {
  final rows = text.split('\n');
  void insertBefore(RegExp pattern, String label) {
    final index = rows.indexWhere((row) => pattern.hasMatch(row));
    if (index > 0) rows.insert(index, label);
  }

  switch (style) {
    case 0:
      rows.insert(1, '--- STORE HEADER ---');
      insertBefore(
        RegExp(r'^(?:pump|bomba|nozzle|fuel qty)', caseSensitive: false),
        '--- DISPENSER DETAILS ---',
      );
      insertBefore(
        RegExp(
          r'^(?:fuel sale|venta combustible|amt |amount paid)',
          caseSensitive: false,
        ),
        '--- FUEL PURCHASE ---',
      );
      insertBefore(
        RegExp(r'^(?:cash|card|visa|total)', caseSensitive: false),
        '--- PAYMENT SUMMARY ---',
      );
      return rows.join('\n');
    case 1:
      rows.insert(1, '[ RECEIPT HEADER ]');
      insertBefore(
        RegExp(r'^total\b', caseSensitive: false),
        '--- FINAL TOTAL ---',
      );
      return rows.join('\n');
    default:
      insertBefore(
        RegExp(r'^(?:odometer|odo|hubometer|mileage)\b', caseSensitive: false),
        '--- VEHICLE REFERENCE ---',
      );
      return rows.join('\n');
  }
}

String _dirtyFuelText(String text, {required int variant}) {
  final characterConfusions = text
      .replaceAll('PRICE', 'PR1CE')
      .replaceAll('Price', 'Pr1ce')
      .replaceAll('GALLONS', 'GALL0NS')
      .replaceAll('Gallons', 'Gall0ns')
      .replaceAll('FUEL', 'FUE1')
      .replaceAll('Fuel', 'Fue1')
      .replaceAll('DIESEL', 'D1ESEL')
      .replaceAll('Diesel', 'D1esel')
      .replaceAll('PROPANE', 'PR0PANE')
      .replaceAll('Propane', 'Pr0pane')
      .replaceAll('HYDROGEN', 'HYDR0GEN')
      .replaceAll('Hydrogen', 'Hydr0gen')
      .replaceAll('METHANOL', 'METHAN0L')
      .replaceAll('Methanol', 'Methan0l')
      .replaceAll('PRECIO', 'PREC1O')
      .replaceAll('Precio', 'Prec1o')
      .replaceAll('GALONES', 'GAL0NES')
      .replaceAll('Galones', 'Gal0nes')
      .replaceAll('COMBUSTIBLE', 'C0MBUSTIBLE')
      .replaceAll('Combustible', 'C0mbustible')
      .replaceAll('Diésel', 'D1ésel')
      .replaceAll(' GAL ', ' GA1 ');
  switch (variant) {
    case 0: // Faded thermal print: common character confusions.
      return characterConfusions;
    case 1: // Fold/crease: blank bands and whitespace fragmentation.
      return characterConfusions
          .replaceAll('\n', '\n\n')
          .replaceAll('PUMP ', 'PUMP  ')
          .replaceAll('TOTAL ', 'TOTAL  ');
    case 2: // Skewed image: labels and values often acquire separators.
      return characterConfusions
          .replaceAll('PPU ', 'PPU: ')
          .replaceAll('VOL ', 'VOL: ')
          .replaceAll('AMT ', 'AMT: ')
          .replaceAll('TOTAL ', 'TOTAL: ');
    default: // Smudge/shadow: localized punctuation and glyph loss.
      return characterConfusions
          .replaceAll('PRICE/', 'PRICE /')
          .replaceAll('FUEL SALE', 'FUEL  SALE')
          .replaceAll('ODOMETER ', 'ODO  ');
  }
}
