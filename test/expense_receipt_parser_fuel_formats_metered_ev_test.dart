part of 'expense_receipt_parser_fuel_formats_test.dart';

void _registerFuelFormatMeteredEvTests() {
  test('keeps Spanish minute-billed charging out of kWh energy', () {
    final parsed = parseExpenseReceiptText('''
RED PUBLICA DE CARGA
30/06/2026
TARIFA POR MINUTO 30 MIN @ 0,200 6,00
TOTAL 6,00
''');

    expect(parsed.lines, hasLength(1));
    final fee = parsed.lines.single;
    expect(fee.category, 'Charging Fees');
    expect(fee.subtotal, 6);
    expect(parsed.lines.where((line) => line.unit == 'kWh'), isEmpty);
  });
}
