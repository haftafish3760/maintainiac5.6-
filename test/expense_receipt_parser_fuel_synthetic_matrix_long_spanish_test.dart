part of 'expense_receipt_parser_fuel_synthetic_matrix_test.dart';

void _registerLongSpanishFuelMatrixTests() {
  test('keeps fuel intact on a long Spanish convenience-store ticket', () {
    final parsed = parseExpenseReceiptText('''
Gasolinera del Sol
07/02/2026
Bomba 06
Gasolina Regular 87
Galones 8,750
Precio/Galón 3,599
Venta Combustible 31,49
Café grande 2,25
Agua botella 1,50
Sandwich de pavo 6,49
Papas fritas 2,29
Liquido limpiaparabrisas 5,99
Lavado de auto 10,00
Barra de proteina 3,19
Bolsa de hielo 2,99
Descuento combustible -0,50
Impuesto ventas 1,22
Subtotal 59,51
Total 60,73
Tarjeta credito 60,73
Autorización previa 120,00
Carga parcial
No lleno
Odometro 106340
''');

    final fuelLines = parsed.lines
        .where((line) => line.category == 'Fuel')
        .toList();
    expect(fuelLines, hasLength(1));
    final fuel = fuelLines.single;
    expect(fuel.fuelType, 'Gasoline');
    expect(fuel.description, contains('87'));
    expect(fuel.quantity, 8.75);
    expect(fuel.unitPrice, 3.599);
    expect(fuel.subtotal, 31.49);
    expect(fuel.odometerReading, 106340);
    expect(fuel.fillType, 'Partial fill');
    expect(parsed.lines.map((line) => line.category), contains('Meals'));
    expect(parsed.lines.map((line) => line.category), contains('Groceries'));
    expect(
      parsed.lines.map((line) => line.category),
      contains('Vehicle Supplies'),
    );
    expect(parsed.enteredTax, 1.22);
    expect(parsed.enteredTotal, 60.73);
    expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 1);
    expect(
      parsed.diagnostics.parserTaskCount('parser_expense_family_mixed_receipt'),
      greaterThan(0),
    );
    expect(
      parsed.diagnostics.parserTaskCount('auth_detail_line_excluded'),
      greaterThan(0),
    );
  });
}
