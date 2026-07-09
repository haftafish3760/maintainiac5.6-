import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';

void main() {
  test(
    'parses prepaid cash fuel without treating cash or change as expenses',
    () {
      final parsed = parseExpenseReceiptText('''
SUNOCO
06/09/2026
PREPAY PUMP 05
REG UNL
GALLONS 11.425
PRICE/GAL 3.499
FUEL SALE 39.98
CASH TENDER 50.00
CHANGE DUE 10.02
TOTAL 39.98
ODOMETER 72110
''');

      expect(parsed.lines, hasLength(1));
      final fuel = parsed.lines.single;
      expect(fuel.category, 'Fuel');
      expect(fuel.fuelType, 'Gasoline');
      expect(fuel.quantity, 11.425);
      expect(fuel.unitPrice, 3.499);
      expect(fuel.subtotal, 39.98);
      expect(fuel.odometerReading, 72110);
      expect(parsed.enteredTotal, 39.98);
      expect(parsed.businessTotal, 39.98);
      expect(
        parsed.diagnostics.parserTaskCount('cash_tender_line_excluded'),
        1,
      );
      expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 1);
    },
  );

  test('ignores unused prepaid fuel refund rows as payment detail', () {
    final parsed = parseExpenseReceiptText('''
SUNOCO
06/18/2026
PREPAY PUMP 05
REG UNL
GALLONS 9.775
PRICE/GAL 3.499
FUEL SALE 34.20
CASH PREPAY 50.00
UNUSED PREPAY REFUND 15.80
TOTAL 34.20
ODOMETER 72440
''');

    expect(parsed.lines, hasLength(1));
    final fuel = parsed.lines.single;
    expect(fuel.category, 'Fuel');
    expect(fuel.fuelType, 'Gasoline');
    expect(fuel.quantity, 9.775);
    expect(fuel.unitPrice, 3.499);
    expect(fuel.subtotal, 34.20);
    expect(fuel.odometerReading, 72440);
    expect(parsed.enteredTotal, 34.20);
    expect(parsed.businessTotal, 34.20);
    expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 1);
  });

  test(
    'parses Spanish cash fuel without treating efectivo or cambio as expenses',
    () {
      final parsed = parseExpenseReceiptText('''
Gasolinera Del Sol
06/10/2026
Prepago Bomba 2
Gasolina Regular
Galones 8.250
Precio/Galón 3.299
Venta Combustible 27.22
Efectivo 30.00
Cambio 2.78
Total 27.22
Odometro 81100
''');

      expect(parsed.lines, hasLength(1));
      final fuel = parsed.lines.single;
      expect(fuel.category, 'Fuel');
      expect(fuel.fuelType, 'Gasoline');
      expect(fuel.quantity, 8.25);
      expect(fuel.unitPrice, 3.299);
      expect(fuel.subtotal, 27.22);
      expect(fuel.odometerReading, 81100);
      expect(parsed.enteredTotal, 27.22);
      expect(parsed.businessTotal, 27.22);
      expect(
        parsed.diagnostics.parserTaskCount('cash_tender_line_excluded'),
        1,
      );
      expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 1);
    },
  );

  test('ignores pay-at-pump preauthorization holds on fuel receipts', () {
    final parsed = parseExpenseReceiptText('''
SHELL
06/16/2026
PAY AT PUMP
PUMP 04
REGULAR UNLEADED
GALLONS 12.200
PRICE/GAL 3.459
FUEL SALE 42.20
PREAUTH HOLD 125.00
AUTH APPROVED 772201
VISA 42.20
TOTAL 42.20
ODOMETER 90520
''');

    expect(parsed.lines, hasLength(1));
    final fuel = parsed.lines.single;
    expect(fuel.category, 'Fuel');
    expect(fuel.fuelType, 'Gasoline');
    expect(fuel.quantity, 12.2);
    expect(fuel.unitPrice, 3.459);
    expect(fuel.subtotal, 42.20);
    expect(fuel.odometerReading, 90520);
    expect(parsed.enteredTotal, 42.20);
    expect(parsed.businessTotal, 42.20);
    expect(
      parsed.diagnostics.parserTaskCount('auth_detail_line_excluded'),
      greaterThan(0),
    );
    expect(
      parsed.diagnostics.parserTaskCount('transaction_line_excluded'),
      greaterThan(0),
    );
    expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 1);
  });

  test('ignores Spanish autorización previa fuel hold amounts', () {
    final parsed = parseExpenseReceiptText('''
Gasolinera Del Sol
06/16/2026
Pago en bomba
Bomba 6
Gasolina Regular
Galones 9.500
Precio/Galón 3.299
Venta Combustible 31.34
Autorización previa 150.00
Tarjeta 31.34
Total 31.34
Odometro 82240
''');

    expect(parsed.lines, hasLength(1));
    final fuel = parsed.lines.single;
    expect(fuel.category, 'Fuel');
    expect(fuel.fuelType, 'Gasoline');
    expect(fuel.quantity, 9.5);
    expect(fuel.unitPrice, 3.299);
    expect(fuel.subtotal, 31.34);
    expect(fuel.odometerReading, 82240);
    expect(parsed.enteredTotal, 31.34);
    expect(parsed.businessTotal, 31.34);
    expect(
      parsed.diagnostics.parserTaskCount('auth_detail_line_excluded'),
      greaterThan(0),
    );
    expect(
      parsed.diagnostics.parserTaskCount('transaction_line_excluded'),
      greaterThan(0),
    );
    expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 1);
  });

  test('keeps mixed convenience receipt fuel and non-fuel lines separated', () {
    final parsed = parseExpenseReceiptText('''
PILOT TRVL CTR
06/07/2026
PUMP 12
PRODUCT DIESEL
GALLONS 18.425
PRICE/GAL 3.699
FUEL SALE 68.15
COFFEE LARGE 2.49
BEEF JERKY 7.99
CAR WASH 10.00
TOTAL 88.63
VISA 88.63
ODOMETER 184220
''');

    final fuel = parsed.lines.singleWhere((line) => line.category == 'Fuel');
    expect(fuel.fuelType, 'Diesel');
    expect(fuel.quantity, 18.425);
    expect(fuel.unitPrice, 3.699);
    expect(fuel.subtotal, 68.15);
    expect(fuel.odometerReading, 184220);
    expect(parsed.lines.map((line) => line.category), contains('Meals'));
    expect(
      parsed.lines.map((line) => line.category),
      contains('Vehicle Supplies'),
    );
    expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 1);
    expect(
      parsed.diagnostics.parserTaskCount('parser_expense_family_mixed_receipt'),
      greaterThan(0),
    );
  });

  test('keeps Spanish mixed fuel receipt lines separated', () {
    final parsed = parseExpenseReceiptText('''
La Tienda Mobil
06/08/2026
Bomba 3
Gasolina Regular
Galones 9.750
Precio/Galón 3.459
Venta Combustible 33.73
Café grande 2.25
Agua botella 1.50
Total 37.48
Tarjeta 37.48
Odometro 60210
''');

    final fuel = parsed.lines.singleWhere((line) => line.category == 'Fuel');
    expect(fuel.fuelType, 'Gasoline');
    expect(fuel.quantity, 9.75);
    expect(fuel.unitPrice, 3.459);
    expect(fuel.subtotal, 33.73);
    expect(fuel.odometerReading, 60210);
    expect(parsed.lines.map((line) => line.category), contains('Meals'));
    expect(parsed.lines.map((line) => line.category), contains('Groceries'));
    expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 1);
    expect(
      parsed.diagnostics.parserTaskCount('parser_expense_family_mixed_receipt'),
      greaterThan(0),
    );
  });

  test('keeps Spanish fuel discounts as receipt adjustments', () {
    final parsed = parseExpenseReceiptText('''
La Estrella Fuel
06/11/2026
Bomba 5
Producto Gasolina Regular
Galones 10.000
Precio/Galón 3.299
Venta Combustible 32.99
Descuento combustible -0.60
Total 32.39
Tarjeta 32.39
Odometro 61420
''');

    expect(parsed.lines, hasLength(2));
    final fuel = parsed.lines.first;
    expect(fuel.category, 'Fuel');
    expect(fuel.fuelType, 'Gasoline');
    expect(fuel.quantity, 10);
    expect(fuel.unitPrice, 3.299);
    expect(fuel.subtotal, 32.99);
    expect(fuel.odometerReading, 61420);
    final adjustment = parsed.lines.last;
    expect(adjustment.category, 'Receipt Adjustment');
    expect(adjustment.subtotal, -0.60);
    expect(parsed.enteredTotal, 32.39);
    expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 1);
  });

  test('parses Spanish and bilingual fuel receipt terms used in the US', () {
    final gasolina = parseExpenseReceiptText('''
Mercado La Estrella
06/04/2026
Bomba 4
Gasolina Regular
Galones 10.250
Precio/Galón 3.399
Venta Combustible 34.84
Total 34.84
Odometro 51220
''');

    expect(gasolina.merchantName, 'Mercado La Estrella');
    expect(gasolina.lines, hasLength(1));
    expect(gasolina.lines.single.category, 'Fuel');
    expect(gasolina.lines.single.fuelType, 'Gasoline');
    expect(gasolina.lines.single.quantity, 10.25);
    expect(gasolina.lines.single.unitPrice, 3.399);
    expect(gasolina.lines.single.subtotal, 34.84);
    expect(gasolina.lines.single.odometerReading, 51220);
    expect(gasolina.diagnostics.parserTaskCount('fuel_line_ready'), 1);

    final diesel = parseExpenseReceiptText('''
RANCHO TRUCK STOP
06/05/2026
Bomba 7
Producto Diésel
Galones 18.500
Precio por galón 3.799
Venta de combustible 70.28
Tarjeta flota 70.28
Autorización 77331
Total 70.28
Odómetro 181420
''');

    expect(diesel.merchantName, 'Rancho Truck Stop');
    expect(diesel.lines, hasLength(1));
    expect(diesel.lines.single.category, 'Fuel');
    expect(diesel.lines.single.fuelType, 'Diesel');
    expect(diesel.lines.single.quantity, 18.5);
    expect(diesel.lines.single.unitPrice, 3.799);
    expect(diesel.lines.single.subtotal, 70.28);
    expect(diesel.lines.single.odometerReading, 181420);
    expect(diesel.diagnostics.parserTaskCount('fuel_line_ready'), 1);
  });

  test('parses EV charging when kWh rate and amount are split across rows', () {
    final parsed = parseExpenseReceiptText('''
ChargePoint
06/01/2026
EV CHARGING
kWh 8.75
Rate 0.442
FUEL SALE 3.87
TOTAL 3.87
Odometer 43000
''');

    expect(parsed.lines, hasLength(1));
    final line = parsed.lines.single;
    expect(line.category, 'Fuel');
    expect(line.fuelType, 'Electric');
    expect(line.unit, 'kWh');
    expect(line.quantity, 8.75);
    expect(line.unitPrice, .442);
    expect(line.subtotal, 3.87);
    expect(line.odometerReading, 43000);
    expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 1);
  });

  test(
    'synthetic fuel matrix parses gas diesel flex and electric receipts',
    () {
      final cases = _syntheticFuelReceipts();
      final failures = <String>[];

      for (final receipt in cases) {
        final parsed = parseExpenseReceiptText(receipt.text);
        final fuelLines = parsed.lines.where((line) => line.category == 'Fuel');
        final line = fuelLines.length == 1 ? fuelLines.single : null;
        final context = '${receipt.name}\n${receipt.text}\n$parsed';

        if (line == null) {
          failures.add(
            '${receipt.name}: expected one fuel line, got '
            '${fuelLines.length}. $context',
          );
          continue;
        }
        _expectNear(
          failures,
          receipt.name,
          'quantity',
          line.quantity,
          receipt.quantity,
        );
        _expectNear(
          failures,
          receipt.name,
          'subtotal',
          line.subtotal,
          receipt.amount,
        );
        _expectNear(
          failures,
          receipt.name,
          'unitPrice',
          line.unitPrice,
          receipt.unitPrice,
          tolerance: .015,
        );
        if (line.unit != receipt.unit) {
          failures.add(
            '${receipt.name}: expected unit ${receipt.unit}, got ${line.unit}.',
          );
        }
        if (line.fuelType != receipt.fuelType) {
          failures.add(
            '${receipt.name}: expected fuelType ${receipt.fuelType}, '
            'got ${line.fuelType}.',
          );
        }
        if (parsed.diagnostics.parserTaskCount('fuel_line_ready') < 1) {
          failures.add('${receipt.name}: missing fuel_line_ready diagnostic.');
        }
      }

      expect(failures, isEmpty, reason: failures.take(20).join('\n\n'));
      expect(cases.length, 28);
    },
  );
}

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
