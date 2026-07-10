part of 'expense_receipt_parser_fuel_synthetic_matrix_test.dart';

List<_SyntheticFuelReceipt> _syntheticFuelReceipts() {
  final receipts = <_SyntheticFuelReceipt>[];
  final products = const [
    _SyntheticFuelProduct(
      label: 'REG UNL',
      fuelType: 'Gasoline',
      unit: 'gallon',
      basePrice: 3.199,
    ),
    _SyntheticFuelProduct(
      label: 'PREMIUM UNLEADED',
      fuelType: 'Gasoline',
      unit: 'gallon',
      basePrice: 4.099,
    ),
    _SyntheticFuelProduct(
      label: 'DIESEL',
      fuelType: 'Diesel',
      unit: 'gallon',
      basePrice: 3.899,
    ),
    _SyntheticFuelProduct(
      label: 'E85 FLEX FUEL',
      fuelType: 'E85',
      unit: 'gallon',
      basePrice: 2.799,
    ),
    _SyntheticFuelProduct(
      label: 'E15 UNLEADED 88',
      fuelType: 'E15',
      unit: 'gallon',
      basePrice: 3.059,
    ),
    _SyntheticFuelProduct(
      label: 'E-20 ETHANOL 20',
      fuelType: 'E20',
      unit: 'gallon',
      basePrice: 2.959,
    ),
    _SyntheticFuelProduct(
      label: 'E50 FLEX FUEL',
      fuelType: 'E50',
      unit: 'gallon',
      basePrice: 2.849,
    ),
    _SyntheticFuelProduct(
      label: 'E10 ETHANOL 10',
      fuelType: 'E10',
      unit: 'gallon',
      basePrice: 3.249,
    ),
    _SyntheticFuelProduct(
      label: 'ENERGY',
      fuelType: 'Electric',
      unit: 'kWh',
      basePrice: .439,
    ),
  ];
  final merchants = const [
    'SHELL',
    'EXXON',
    'PILOT TRVL CTR',
    'RIVER ROAD MART 418',
    'CHARGEPOINT',
    'SUNOCO',
  ];

  var index = 0;
  for (final product in products) {
    for (var layout = 0; layout < 4; layout += 1) {
      for (var sample = 0; sample < 1; sample += 1) {
        final merchant = merchants[(sample + layout) % merchants.length];
        final quantity = product.unit == 'kWh'
            ? 8.5 + (sample % 37) + (layout * .25)
            : 4.5 + (sample % 31) + (layout * .125);
        final unitPrice =
            product.basePrice + ((sample % 9) * .017) + (layout * .003);
        final amount = _money(quantity * unitPrice);
        final dateDay = (sample % 26) + 1;
        final pump = (sample % 18) + 1;
        final odometer = 42000 + (sample * 37) + (layout * 1000);
        final text = product.unit == 'kWh'
            ? _evReceipt(
                merchant: 'CHARGEPOINT',
                day: dateDay,
                quantity: quantity,
                unitPrice: unitPrice,
                amount: amount,
                odometer: odometer,
                layout: layout,
              )
            : _liquidFuelReceipt(
                merchant: merchant,
                product: product,
                day: dateDay,
                pump: pump,
                quantity: quantity,
                unitPrice: unitPrice,
                amount: amount,
                odometer: odometer,
                layout: layout,
              );
        receipts.add(
          _SyntheticFuelReceipt(
            name: 'synthetic_fuel_${index++}_${product.fuelType}_layout$layout',
            text: text,
            quantity: quantity,
            unitPrice: unitPrice,
            amount: amount,
            unit: product.unit,
            fuelType: product.fuelType,
          ),
        );
      }
    }
  }

  return receipts;
}

String _liquidFuelReceipt({
  required String merchant,
  required _SyntheticFuelProduct product,
  required int day,
  required int pump,
  required double quantity,
  required double unitPrice,
  required double amount,
  required int odometer,
  required int layout,
}) {
  final qty = quantity.toStringAsFixed(3);
  final price = unitPrice.toStringAsFixed(3);
  final total = amount.toStringAsFixed(2);
  switch (layout) {
    case 0:
      return '''
$merchant
06/${day.toString().padLeft(2, '0')}/2026
Pump $pump ${product.label} $qty GAL $total
TOTAL $total
ODOMETER $odometer
''';
    case 1:
      return '''
$merchant
06/${day.toString().padLeft(2, '0')}/2026
PUMP $pump
PRODUCT ${product.label}
GALLONS $qty
PRICE/GAL $price
FUEL SALE $total
TOTAL $total
ODO $odometer
''';
    case 2:
      return '''
$merchant
06/${day.toString().padLeft(2, '0')}/2026
${product.label} $qty @ $price $total
CARD SALE $total
AUTH 100${day}99
''';
    default:
      return '''
$merchant
06/${day.toString().padLeft(2, '0')}/2026
FUEL QTY $qty
PPG $price
${product.label} FUEL $total
AMOUNT PAID $total
MILEAGE $odometer
''';
  }
}

String _evReceipt({
  required String merchant,
  required int day,
  required double quantity,
  required double unitPrice,
  required double amount,
  required int odometer,
  required int layout,
}) {
  final qty = quantity.toStringAsFixed(2);
  final price = unitPrice.toStringAsFixed(3);
  final total = amount.toStringAsFixed(2);
  switch (layout) {
    case 0:
      return '''
$merchant
06/${day.toString().padLeft(2, '0')}/2026
Energy $qty kWh $total
Total $total
Odometer $odometer
''';
    case 1:
      return '''
$merchant
06/${day.toString().padLeft(2, '0')}/2026
EV CHARGING
Rate $price
Energy $qty kWh $total
TOTAL $total
''';
    case 2:
      return '''
$merchant
06/${day.toString().padLeft(2, '0')}/2026
Charging Session $qty kWh @ $price $total
Visa $total
Auth 7788
''';
    default:
      return '''
$merchant
06/${day.toString().padLeft(2, '0')}/2026
Electric fuel $total
Energy Delivered $qty kWh
Price/kWh $price
Amount Paid $total
Mileage $odometer
''';
  }
}

void _expectNear(
  List<String> failures,
  String name,
  String field,
  double? actual,
  double expected, {
  double tolerance = .01,
}) {
  if (actual == null || (actual - expected).abs() > tolerance) {
    failures.add(
      '$name: expected $field ${expected.toStringAsFixed(3)}, got $actual.',
    );
  }
}

double _money(double value) => (value * 100).round() / 100;

class _SyntheticFuelProduct {
  const _SyntheticFuelProduct({
    required this.label,
    required this.fuelType,
    required this.unit,
    required this.basePrice,
  });

  final String label;
  final String fuelType;
  final String unit;
  final double basePrice;
}

class _SyntheticFuelReceipt {
  const _SyntheticFuelReceipt({
    required this.name,
    required this.text,
    required this.quantity,
    required this.unitPrice,
    required this.amount,
    required this.unit,
    required this.fuelType,
  });

  final String name;
  final String text;
  final double quantity;
  final double unitPrice;
  final double amount;
  final String unit;
  final String fuelType;
}
