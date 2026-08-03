part of 'expense_receipt_parser_fuel_formats_test.dart';

void _registerFuelFormatEdgeCaseTests() {
  test(
    'does not promote fuel station and terminal identifiers to fuel lines',
    () {
      final parsed = parseExpenseReceiptText('''
Sheetz 754
07/15/2026 09:01 PM
12871 Richmond Highway
Concord VA 24538
Pump No: 10
E15 (88 @ \$3.049/G
Volume: 15.743 Gal
Gas Total: \$48.00
Total \$48.00
Approval: 030597
Term: 20754
Pointz: 2957
Tier: FRIEND
Pointz value: 29.57
Tier credit: 7.54
''', targetCategory: 'Fuel');

      expect(parsed.merchantName, 'Sheetz');
      expect(parsed.enteredTotal, 48);
      expect(parsed.lines, hasLength(1));
      final fuel = parsed.lines.single;
      expect(fuel.category, 'Fuel');
      expect(fuel.description, contains('E15'));
      expect(fuel.quantity, 15.743);
      expect(fuel.unit, 'gallon');
      expect(fuel.unitPrice, 3.049);
      expect(fuel.subtotal, 48);
      expect(
        parsed.lines.map((line) => line.description).join(' '),
        allOf(isNot(contains('Term')), isNot(contains('Pointz'))),
      );
    },
  );

  test(
    'rejects monetary-looking fuel terminal and loyalty metadata variants',
    () {
      const receipt = '''
SHEETZ 754
07/15/2026 09:01 PM
PUMP 10
E15 15.743 GAL @ 3.049 48.00
TOTAL 48.00
''';
      const metadataRows = [
        'Pointz value: 29.57',
        'Points: 29.57',
        'Tier credit: 7.54',
        'Loyalty value: 48.00',
        'Member number: 48.00',
        'Reward balance: 12.34',
        'Terminal code: 12.34',
        'Term: 207.54',
        'AID: 12.34',
        'TVR: 7.54',
        'TSI: 1.23',
        'ARQC: 45.67',
        'Issuer value: 3.04',
        'Contactless value: 48.00',
        'Capture amount: 48.00',
      ];

      for (final metadata in metadataRows) {
        final parsed = parseExpenseReceiptText(
          '$receipt$metadata',
          targetCategory: 'Fuel',
        );
        expect(parsed.lines, hasLength(1), reason: metadata);
        final fuel = parsed.lines.single;
        expect(fuel.category, 'Fuel', reason: metadata);
        expect(fuel.fuelType, 'E15', reason: metadata);
        expect(fuel.quantity, 15.743, reason: metadata);
        expect(fuel.unitPrice, 3.049, reason: metadata);
        expect(fuel.subtotal, 48, reason: metadata);
      }
    },
  );

  test(
    'does not borrow another grade price on a multi-product fuel receipt',
    () {
      final parsed = parseExpenseReceiptText('''
SHELL
07/18/2026
PUMP 04 PREMIUM 5.000 GAL 20.00
PUMP 05 REGULAR 10.000 GAL @ 3.500 35.00
TOTAL 55.00
''');

      final fuel = parsed.lines
          .where((line) => line.category == 'Fuel')
          .toList();
      expect(fuel, hasLength(2));
      final premium = fuel.singleWhere(
        (line) => line.description.toLowerCase().contains('premium'),
      );
      final regular = fuel.singleWhere(
        (line) => line.description.toLowerCase().contains('regular'),
      );
      expect(premium.quantity, 5);
      expect(premium.subtotal, 20);
      expect(premium.unitPrice, 4);
      expect(regular.quantity, 10);
      expect(regular.subtotal, 35);
      expect(regular.unitPrice, 3.5);
    },
  );

  test('keeps an explicit grade price when its row needs math review', () {
    final parsed = parseExpenseReceiptText('''
SHELL
07/18/2026
PUMP 04 PREMIUM 5.000 GAL @ 4.000 18.00
PUMP 05 REGULAR 5.000 GAL @ 3.500 17.50
TOTAL 35.50
''');

    final premium = parsed.lines.singleWhere(
      (line) => line.description.toLowerCase().contains('premium'),
    );
    expect(premium.quantity, 5);
    expect(premium.subtotal, 18);
    expect(premium.unitPrice, 4);
    expect(
      parsed.diagnostics.parserTaskCount('fuel_amount_math_needs_review'),
      1,
    );
  });

  test('keeps super and Spanish supreme octane grades out of fuel volume', () {
    final english = parseExpenseReceiptText('''
EXPRESS FUEL
06/30/2026
SUPER UNLEADED 93 10.250 @ 3.899 39.97
TOTAL 39.97
''');
    final spanish = parseExpenseReceiptText('''
MERCADO COMBUSTIBLE
06/30/2026
GASOLINA SUPREMA 89 GALONES 8.500 @ 3.599 30.59
TOTAL 30.59
''');

    for (final parsed in [english, spanish]) {
      expect(parsed.lines, hasLength(1));
      expect(parsed.lines.single.category, 'Fuel');
      expect(parsed.lines.single.fuelType, 'Gasoline');
    }
    expect(english.lines.single.quantity, 10.25);
    expect(english.lines.single.unitPrice, 3.899);
    expect(spanish.lines.single.quantity, 8.5);
    expect(spanish.lines.single.unitPrice, 3.599);
  });

  test('does not carry per gallon rewards metadata onto personal items', () {
    final parsed = parseExpenseReceiptText('''
RIVER ROAD MART 418
06/04/2026
Pump 14 B20 DIESEL 7.625 GAL 28.37
FUEL REWARDS -0.100/GAL
BEER 6PK 11.99
CIGARETTES 8.75
LOTTERY SCRATCHER 5.00
TOTAL 54.11
''');

    final fuelLines = parsed.lines.where((line) => line.category == 'Fuel');
    expect(fuelLines, hasLength(1));
    final fuel = fuelLines.single;
    expect(fuel.description, contains('B20 Diesel'));
    expect(fuel.fuelType, 'Diesel');
    expect(fuel.quantity, 7.625);
    expect(fuel.subtotal, 28.37);
    expect(fuel.unitPrice, closeTo(3.721, .001));

    final personalLines = parsed.lines.where(
      (line) => line.category == 'Personal',
    );
    expect(personalLines, hasLength(3));
    expect(
      personalLines.map((line) => line.description).join(' '),
      isNot(contains('Fuel Rewards')),
    );
    expect(parsed.personalTotal, closeTo(25.74, .001));
  });

  test('parses HVO and lower renewable-diesel blend labels as diesel', () {
    final hvo = parseExpenseReceiptText('''
FLEET FUEL DEPOT
06/30/2026
PUMP 04
HVO100 18.500 @ 4.199 77.68
TOTAL 77.68
ODOMETER 144220
''');

    expect(hvo.lines, hasLength(1));
    final hvoFuel = hvo.lines.single;
    expect(hvoFuel.category, 'Fuel');
    expect(hvoFuel.fuelType, 'Diesel');
    expect(hvoFuel.quantity, 18.5);
    expect(hvoFuel.unitPrice, 4.199);
    expect(hvoFuel.subtotal, 77.68);

    final rd20 = parseExpenseReceiptText('''
RENEWABLE FUEL STOP
06/30/2026
PRODUCT RD20
GALLONS 12.250
PRICE/GAL 3.899
FUEL SALE 47.76
TOTAL 47.76
ODOMETER 144480
''');

    expect(rd20.lines, hasLength(1));
    expect(rd20.lines.single.fuelType, 'Diesel');
    expect(rd20.lines.single.quantity, 12.25);
    expect(rd20.lines.single.unitPrice, 3.899);
    expect(rd20.lines.single.subtotal, 47.76);
  });

  test('uses GGE and DGE to distinguish renewable natural gas delivery', () {
    final cng = parseExpenseReceiptText('''
RENEWABLE GAS FLEET
06/30/2026
RENEWABLE NATURAL GAS
GGE 11.500
PRICE/GGE 2.899
FUEL SALE 33.34
TOTAL 33.34
ODOMETER 74480
''');

    expect(cng.lines, hasLength(1));
    expect(cng.lines.single.fuelType, 'CNG');
    expect(cng.lines.single.unit, 'GGE');
    expect(cng.lines.single.quantity, 11.5);
    expect(cng.lines.single.unitPrice, 2.899);
    expect(cng.lines.single.subtotal, 33.34);

    final lng = parseExpenseReceiptText('''
RENEWABLE GAS FLEET
06/30/2026
RNG
DGE 12.000
PRICE/DGE 3.200
FUEL SALE 38.40
TOTAL 38.40
ODOMETER 74680
''');

    expect(lng.lines, hasLength(1));
    expect(lng.lines.single.fuelType, 'LNG');
    expect(lng.lines.single.unit, 'DGE');
    expect(lng.lines.single.quantity, 12);
    expect(lng.lines.single.unitPrice, 3.2);
    expect(lng.lines.single.subtotal, 38.40);
  });

  test('parses clear on-road and spelled-out sulfur diesel labels', () {
    final parsed = parseExpenseReceiptText('''
COMMERCIAL FUEL STOP
07/01/2026
ON-ROAD CLEAR DIESEL
ULTRA LOW SULFUR DIESEL 16.250 @ 3.899 63.36
TOTAL 63.36
ODOMETER 144560
''');

    expect(parsed.lines, hasLength(1));
    final fuel = parsed.lines.single;
    expect(fuel.category, 'Fuel');
    expect(fuel.fuelType, 'Diesel');
    expect(fuel.description.toLowerCase(), contains('on-road'));
    expect(fuel.quantity, 16.25);
    expect(fuel.unitPrice, 3.899);
    expect(fuel.subtotal, 63.36);
  });

  test('parses compact FlexFuel and Gasohol labels', () {
    final flexFuel = parseExpenseReceiptText('''
FUEL STATION
07/01/2026
FLEXFUEL E85 10.000 @ 2.799 27.99
TOTAL 27.99
''');

    expect(flexFuel.lines, hasLength(1));
    expect(flexFuel.lines.single.fuelType, 'E85');
    expect(flexFuel.lines.single.quantity, 10);

    final gasohol = parseExpenseReceiptText('''
FUEL STATION
07/01/2026
GASOHOL 87
GALLONS 8.000
PRICE/GAL 3.500
FUEL SALE 28.00
TOTAL 28.00
''');

    expect(gasohol.lines, hasLength(1));
    expect(gasohol.lines.single.fuelType, 'Gasoline');
    expect(gasohol.lines.single.description, contains('87'));
    expect(gasohol.lines.single.quantity, 8);
    expect(gasohol.lines.single.unitPrice, 3.5);
  });

  test('parses hyphenated ethanol and ethanol-free dispenser labels', () {
    final e85 = parseExpenseReceiptText('''
FUEL STATION
07/01/2026
E-85 FLEXFUEL 10.000 @ 2.799 27.99
TOTAL 27.99
''');

    expect(e85.lines, hasLength(1));
    expect(e85.lines.single.fuelType, 'E85');
    expect(e85.lines.single.quantity, 10);

    final e0 = parseExpenseReceiptText('''
FUEL STATION
07/01/2026
E-0 ETHANOL FREE 8.000 @ 3.500 28.00
TOTAL 28.00
''');

    expect(e0.lines, hasLength(1));
    expect(e0.lines.single.fuelType, 'Gasoline');
    expect(e0.lines.single.quantity, 8);
  });

  test('keeps dirty hyphenated E85 gallons and unit price in their roles', () {
    final parsed = parseExpenseReceiptText('''
WAWA
06/15/2026
PUMP 15
PRODUCT E-85 FLEXFUE1
GALL0NS 16.375
PR1CE/GAL 2.885
FUE1 SALE 47.24
CASH TENDER 57.24
CHANGE DUE 10.00
TANK NOT FULL
TOTAL 47.24
ODO 56168
''');

    expect(parsed.lines, hasLength(1));
    final fuel = parsed.lines.single;
    expect(fuel.fuelType, 'E85');
    expect(fuel.quantity, 16.375);
    expect(fuel.unitPrice, 2.885);
    expect(fuel.subtotal, 47.24);
    expect(fuel.odometerReading, 56168);
  });

  test('parses K-1 kerosene and US-Spanish Gas LP labels', () {
    final kerosene = parseExpenseReceiptText('''
RURAL FUEL DEPOT
07/02/2026
K-1 4.500 @ 4.919 22.14
TOTAL 22.14
''');

    expect(kerosene.lines, hasLength(1));
    expect(kerosene.lines.single.fuelType, 'Kerosene');
    expect(kerosene.lines.single.quantity, 4.5);
    expect(kerosene.lines.single.unitPrice, 4.919);

    final propane = parseExpenseReceiptText('''
ENERGIA DEL BARRIO
07/02/2026
GAS LP 8.000 @ 2.669 21.35
TOTAL 21.35
''');

    expect(propane.lines, hasLength(1));
    expect(propane.lines.single.fuelType, 'Propane');
    expect(propane.lines.single.quantity, 8);
    expect(propane.lines.single.unitPrice, 2.669);
  });

  test('does not read L.P. Gas as liters beside alternate fuel prices', () {
    final parsed = parseExpenseReceiptText('''
SUNOCO
06/04/2026
FUEL QTY 12.625
PPG 2.713
CASH PRICE/GAL 2.713
CREDIT PRICE/GAL 2.813
L.P. GAS FUEL 35.51
COFFEE LARGE 2.49
CAR WASH ULTIMATE 8.00
AMOUNT PAID 46.00
MILEAGE 49321
''');

    final propane = parsed.lines.singleWhere(
      (line) => line.fuelType == 'Propane',
    );
    expect(propane.quantity, 12.625);
    expect(propane.unit, 'gallon');
    expect(propane.unitPrice, 2.813);
    expect(propane.subtotal, 35.51);
    expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 1);
  });

  test('uses printed Spanish K-1 gallons and discounted unit price', () {
    final parsed = parseExpenseReceiptText('''
EXXON
06/06/2026
Bomba 14
Producto Queroseno K-1
Galones 12.625
Precio/Galón 4.930
Descuento/Galón -0.100
Venta Combustible 60.98
Total 60.98
Odometro 56865
''');

    expect(parsed.lines, hasLength(1));
    final kerosene = parsed.lines.single;
    expect(kerosene.fuelType, 'Kerosene');
    expect(kerosene.quantity, 12.625);
    expect(kerosene.unit, 'gallon');
    expect(kerosene.unitPrice, 4.83);
    expect(kerosene.subtotal, 60.98);
  });
}
