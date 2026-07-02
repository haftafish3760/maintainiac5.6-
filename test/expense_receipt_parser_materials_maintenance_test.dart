import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';

void main() {
  test('classifies HVAC supply house receipt lines as materials', () {
    final parsed = parseExpenseReceiptText('''
UNITED REFRIGERATION
06/21/2026
35/5 MFD RUN CAPACITOR 18.49
16X25X1 PLEATED FILTER 9.99
FOIL HVAC TAPE 12.99
TOTAL 41.47
''');

    expect(parsed.merchantName, 'United Refrigeration');
    expect(parsed.lines, hasLength(3));
    expect(parsed.lines.map((line) => line.category), [
      'Materials',
      'Materials',
      'Materials',
    ]);
    expect(parsed.diagnostics.reviewRatio, lessThanOrEqualTo(1 / 3));
    expect(parsed.diagnostics.trustLabel, isNot('Needs line review'));
  });

  test('extracts oil change maintenance hints without logging maintenance', () {
    final parsed = parseExpenseReceiptText('''
TAKE 5 OIL CHANGE
06/12/2026 08:30 AM
Odometer: 100000
Full Synthetic Oil Change 5W-30 79.99
Oil Filter 12.99
Next Service Due 105000
Every 6 months
Subtotal 92.98
Tax 5.58
Total 98.56
''');

    expect(parsed.lines.map((line) => line.category), [
      'Maintenance',
      'Maintenance',
    ]);
    expect(parsed.maintenanceHints, hasLength(1));
    final hint = parsed.maintenanceHints.single;
    expect(hint.itemName, 'Engine Oil');
    expect(hint.serviceType, 'Oil Change');
    expect(hint.oilWeight, '5W-30');
    expect(hint.detail, 'Full Synthetic');
    expect(hint.serviceOdometer, 100000);
    expect(hint.dueOdometer, 105000);
    expect(hint.intervalMiles, 5000);
    expect(hint.intervalMonths, 6);
    expect(hint.label, 'Good');

    final shortDue = parseExpenseReceiptText('''
QUICK LUBE
2026-06-30
5W-20 SYNTHETIC OIL 39.99
OIL FILTER 8.49
TIRE ROTATION 19.99
SALES TAX 4.11
TOTAL 72.58
NEXT SERVICE 92,500 MILES
''');

    expect(shortDue.maintenanceHints, hasLength(greaterThanOrEqualTo(1)));
    final shortDueHint = shortDue.maintenanceHints.first;
    expect(shortDueHint.serviceType, 'Oil Change');
    expect(shortDueHint.oilWeight, '5W-20');
    expect(shortDueHint.dueOdometer, 92500);
  });

  test('parses material quantities, packs, and measured lengths', () {
    final parsed = parseExpenseReceiptText('''
LOWE'S HOME IMPROVEMENT
06/12/2026
2 @ 4.98 2X4X8 KD STUD 9.96
25PK #8 X 1-1/4 WOOD SCREWS 6.98
12 FT ROMEX 12/2 W/G 34.80
TOTAL 51.74
''');

    expect(parsed.merchantName, "Lowe's");
    expect(parsed.lines.map((line) => line.category), [
      'Materials',
      'Materials',
      'Materials',
    ]);
    expect(parsed.lines[0].quantity, 2);
    expect(parsed.lines[0].unitsPerPackage, 1);
    expect(parsed.lines[1].quantity, 1);
    expect(parsed.lines[1].unitsPerPackage, 25);
    expect(parsed.lines[1].unit, 'each');
    expect(parsed.lines[2].quantity, 1);
    expect(parsed.lines[2].unitsPerPackage, 12);
    expect(parsed.lines[2].unit, 'foot');
  });

  test('joins split OCR description and amount rows for material receipts', () {
    final parsed = parseExpenseReceiptText('''
LOWE'S HOME IMPROVEMENT
123 MAIN ST
06/12/2026
PVC PIPE SCH40 10 FT
14.50
25PK #8 X 1-1/4 WOOD SCREWS
6.98
2 EA 1/2 IN COPPER COUPLING
8.97
SUBTOTAL 30.45
TAX 2.13
TOTAL 32.58
''');

    expect(parsed.merchantName, "Lowe's");
    expect(parsed.lines, hasLength(3));
    expect(parsed.lines.map((line) => line.category), [
      'Materials',
      'Materials',
      'Materials',
    ]);
    expect(parsed.lines.first.description.toLowerCase(), contains('pvc pipe'));
    expect(parsed.lines.first.subtotal, 14.50);
    expect(parsed.lines.first.unitsPerPackage, 10);
    expect(parsed.lines.first.unit, 'foot');
    expect(parsed.lines[1].unitsPerPackage, 25);
    expect(parsed.lines[2].quantity, 2);
    expect(
      parsed.lines.first.description.toLowerCase(),
      isNot(contains('lowe')),
    );
    expect(parsed.diagnostics.reconciled, isTrue);
  });

  test('does not attach merchant or address rows to first priced item', () {
    final parsed = parseExpenseReceiptText('''
THE HOME DEPOT
200 STORE WAY
06/12/2026
PVC GLUE 7.99
TOTAL 7.99
''');

    expect(parsed.lines, hasLength(1));
    expect(parsed.lines.single.description, 'Pvc Glue');
    expect(
      parsed.lines.single.description.toLowerCase(),
      isNot(contains('home depot')),
    );
    expect(parsed.lines.single.category, 'Materials');
  });

  test(
    'uses pending description when OCR puts only price metadata on next row',
    () {
      final parsed = parseExpenseReceiptText('''
CITY ELECTRIC SUPPLY
06/12/2026
20A GFCI RECEPTACLE
ITEM PRICE 18.49
1/2 EMT CONDUIT 10 FT
EXTENDED 8.99
TOTAL 27.48
''');

      expect(parsed.lines, hasLength(2));
      expect(parsed.lines.first.description.toLowerCase(), contains('gfci'));
      expect(parsed.lines.first.subtotal, 18.49);
      expect(
        parsed.lines.last.description.toLowerCase(),
        contains('emt conduit'),
      );
      expect(parsed.lines.last.unitsPerPackage, 10);
      expect(parsed.lines.last.unit, 'foot');
      expect(parsed.diagnostics.reconciled, isTrue);
    },
  );

  test(
    'uses pending description when OCR puts quantity and at-price on next row',
    () {
      final parsed = parseExpenseReceiptText('''
CITY ELECTRIC SUPPLY
06/12/2026
20A GFCI RECEPTACLE
2 EA @ 18.49 36.98
TOTAL 36.98
''');

      expect(parsed.lines, hasLength(1));
      expect(parsed.lines.single.description, '20a Gfci Receptacle');
      expect(
        parsed.lines.single.description.toLowerCase(),
        isNot(contains('@')),
      );
      expect(parsed.lines.single.category, 'Materials');
      expect(parsed.lines.single.quantity, 2);
      expect(parsed.lines.single.subtotal, 36.98);
      expect(parsed.lines.single.unitPrice, 18.49);
      expect(parsed.diagnostics.reconciled, isTrue);
    },
  );

  test(
    'recognizes plumbing, paint, electrical, and roofing supply receipts',
    () {
      final plumbing = parseExpenseReceiptText('''
FERGUSON ENTERPRISES
06/12/2026
3 EA 1/2 IN COPPER COUPLING 8.97
10 FT PVC PIPE SCH40 14.50
TOTAL 23.47
''');

      expect(plumbing.merchantName, 'Ferguson');
      expect(plumbing.lines.map((line) => line.category), [
        'Materials',
        'Materials',
      ]);
      expect(plumbing.lines.first.quantity, 3);
      expect(plumbing.lines.last.unitsPerPackage, 10);
      expect(plumbing.lines.last.unit, 'foot');

      final paint = parseExpenseReceiptText('''
SHERWIN WILLIAMS
06/12/2026
PROCLASSIC PAINT 1 GAL 49.99
CAULK WHITE 4.99
TOTAL 54.98
''');

      expect(paint.merchantName, 'Sherwin-Williams');
      expect(paint.lines.map((line) => line.category), [
        'Materials',
        'Materials',
      ]);
      expect(paint.lines.first.unitsPerPackage, 1);
      expect(paint.lines.first.unit, 'gallon');

      final electrical = parseExpenseReceiptText('''
CITY ELECTRIC SUPPLY
06/12/2026
20A GFCI RECEPTACLE 18.49
1/2 EMT CONDUIT 10 FT 8.99
TOTAL 27.48
''');

      expect(electrical.merchantName, 'City Electric Supply');
      expect(electrical.lines.map((line) => line.category), [
        'Materials',
        'Materials',
      ]);

      final roofing = parseExpenseReceiptText('''
BEACON BUILDING PRODUCTS
06/12/2026
DRIP EDGE WHITE 12 FT 11.99
FLASHING TAPE 29.99
TOTAL 41.98
''');

      expect(roofing.merchantName, 'Beacon Building Products');
      expect(roofing.lines.map((line) => line.category), [
        'Materials',
        'Materials',
      ]);
    },
  );
}
