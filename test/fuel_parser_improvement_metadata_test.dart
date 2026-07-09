import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';
import 'package:maintaniac/screens/expenses/data/fuel_parser_improvement_metadata.dart';

void main() {
  test('exports only redacted fuel parser improvement metadata', () {
    final parsed = parseExpenseReceiptText('''
SHELL PRIVATE STORE
06/12/2026
PUMP 4
DIESEL
GALLONS 12.500
PRICE/GAL 3.899
FUEL SALE 48.74
VISA 4111111111111111 48.74
AUTH 998877
TRACE 123456
ODOMETER 94000
''');

    final metadata = FuelParserImprovementMetadata.fromParseResult(parsed);
    final map = metadata.toMap();
    final encoded = map.toString().toLowerCase();

    expect(map['schema'], 'fuel_parser_improvement_metadata_v1');
    expect(map['receiptFamily'], 'fuel_only');
    expect(map['localeBucket'], 'english_us');
    expect(map['fuelLineCount'], 1);
    expect(map['nonFuelLineCount'], 0);
    expect(map['redactionStatus'], 'redacted_counts_only');
    expect(metadata.fuelTypeCounts['diesel'], 1);
    expect(metadata.unitCounts['gallon'], 1);
    expect(metadata.excludedPrivateLineCount, greaterThan(0));

    for (final privateHint in const [
      'shell private store',
      '4111111111111111',
      '998877',
      '123456',
      '94000',
      '48.74',
      'visa',
      'trace',
      'auth 998877',
    ]) {
      expect(encoded, isNot(contains(privateHint)));
    }
  });

  test('classifies Spanish and bilingual fuel metadata without raw lines', () {
    final parsed = parseExpenseReceiptText('''
Gasolinera Privada
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

    final metadata = FuelParserImprovementMetadata.fromParseResult(parsed);
    final encoded = metadata.toMap().toString().toLowerCase();

    expect(metadata.localeBucket, 'spanish_us');
    expect(metadata.fuelTypeCounts['gasoline'], 1);
    expect(metadata.unitCounts['gallon'], 1);
    expect(metadata.parserTaskCounts['fuel_line_ready'], 1);
    expect(metadata.excludedPrivateLineCount, greaterThan(0));

    for (final privateHint in const [
      'gasolinera privada',
      'efectivo',
      'cambio',
      '81100',
      '30.00',
      '2.78',
      '27.22',
    ]) {
      expect(encoded, isNot(contains(privateHint)));
    }
  });

  test('classifies Spanish EV charging metadata without raw fee text', () {
    final parsed = parseExpenseReceiptText('''
Estacion Privada EVgo
06/14/2026
Carga eléctrica
Energía 31.20 kWh 13.10
Tarifa/kWh 0.420
Cuota de sesión 1.25
Tarifa por inactividad 2.00
Tarjeta 16.35
Autorización 554433
Total 16.35
Odometro 45210
''');

    final metadata = FuelParserImprovementMetadata.fromParseResult(parsed);
    final encoded = metadata.toMap().toString().toLowerCase();

    expect(metadata.receiptFamily, 'mixed_fuel');
    expect(metadata.localeBucket, 'spanish_us');
    expect(metadata.fuelLineCount, 1);
    expect(metadata.nonFuelLineCount, 2);
    expect(metadata.fuelTypeCounts['electric'], 1);
    expect(metadata.unitCounts['kwh'], 1);
    expect(metadata.parserTaskCounts['fuel_line_ready'], 1);
    expect(metadata.excludedPrivateLineCount, greaterThan(0));

    for (final privateHint in const [
      'estacion privada evgo',
      'energía',
      'cuota de sesión',
      'tarifa por inactividad',
      'tarjeta',
      'autorización',
      '554433',
      '45210',
      '16.35',
      '13.10',
      '1.25',
      '2.00',
    ]) {
      expect(encoded, isNot(contains(privateHint)));
    }
  });

  test('protects fuel loyalty driver vehicle and contact identity rows', () {
    final parsed = parseExpenseReceiptText('''
KROGER FUEL CENTER
06/22/2026
PUMP 09
REGULAR UNLEADED
GALLONS 11.250
PRICE/GAL 3.399
FUEL SALE 38.24
MEMBER 777788889999
ALT ID 5551239876
DRIVER ID AB1277
VEHICLE ID TRUCK-44
VIN 1FTFW1E55NFA12345
LICENSE PLATE TX KLT9001
PHONE 555-123-4567
EMAIL fuel.user@example.com
TOTAL 38.24
ODOMETER 99120
''');

    final metadata = FuelParserImprovementMetadata.fromParseResult(parsed);
    final encoded = metadata.toMap().toString().toLowerCase();

    expect(parsed.lines, hasLength(1));
    expect(parsed.lines.single.category, 'Fuel');
    expect(parsed.lines.single.fuelType, 'Gasoline');
    expect(metadata.fuelLineCount, 1);
    expect(metadata.nonFuelLineCount, 0);
    expect(metadata.parserTaskCounts['identity_detail_line_excluded'], 8);
    expect(metadata.excludedPrivateLineCount, greaterThanOrEqualTo(8));

    for (final privateHint in const [
      'kroger fuel center',
      '777788889999',
      '5551239876',
      'ab1277',
      'truck-44',
      '1ftfw1e55nfa12345',
      'klt9001',
      '555-123-4567',
      'fuel.user@example.com',
      '99120',
      '38.24',
    ]) {
      expect(encoded, isNot(contains(privateHint)));
    }
  });
}
