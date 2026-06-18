import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';

void main() {
  test('parses fuel receipt text into editable receipt fields', () {
    final parsed = parseExpenseReceiptText('''
Quick Fuel
06/11/2026 08:14 AM
Pump 03 Diesel 12.500 GAL 48.75
Subtotal 48.75
Sales Tax 2.93
Total 51.68
''');

    expect(parsed.merchantName, 'Quick Fuel');
    expect(parsed.receiptDate, DateTime(2026, 6, 11));
    expect(parsed.receiptTimeMinutes, (8 * 60) + 14);
    expect(parsed.enteredSubtotal, 48.75);
    expect(parsed.enteredTax, 2.93);
    expect(parsed.enteredTotal, 51.68);
    expect(parsed.lines, hasLength(1));
    expect(parsed.lines.single.category, 'Fuel');
    expect(parsed.lines.single.quantity, 12.5);
    expect(parsed.lines.single.unit, 'gallon');
    expect(parsed.lines.single.fuelType, 'Diesel');
  });

  test('parses mixed receipt text and keeps amount-only categories simple', () {
    final parsed = parseExpenseReceiptText('''
Verizon Wireless
2026-06-09
Monthly phone service 86.42
USB cable qty 2 18.00
Total 104.42
''');

    expect(parsed.merchantName, 'Verizon Wireless');
    expect(parsed.receiptDate, DateTime(2026, 6, 9));
    expect(parsed.enteredTotal, 104.42);
    expect(parsed.lines.map((line) => line.category), [
      'Cell Phone',
      'Uncategorized',
    ]);
    expect(parsed.lines.first.unit, 'each');
    expect(parsed.lines.first.quantity, 1);
    expect(parsed.lines.last.quantity, 2);
    expect(parsed.lineReviews.last.needsReview, isTrue);
  });

  test('normalizes auto parts merchant and maintenance receipt lines', () {
    final parsed = parseExpenseReceiptText('''
ADVANCE AUTO PARTS
Store 04218
6/12/26 7:03 PM
OIL FILTER PH8A 12,99
5QT FULL SYNTHETIC MOTOR OIL 34.99
CORE CHARGE 0.00
SUB-TOTAL 47.98
TAX 3.36
AMOUNT PAID 51.34
''');

    expect(parsed.merchantName, 'Advance Auto Parts');
    expect(parsed.receiptDate, DateTime(2026, 6, 12));
    expect(parsed.receiptTimeMinutes, (19 * 60) + 3);
    expect(parsed.enteredSubtotal, 47.98);
    expect(parsed.enteredTax, 3.36);
    expect(parsed.enteredTotal, 51.34);
    expect(parsed.lines.map((line) => line.category), [
      'Maintenance',
      'Maintenance',
    ]);
    expect(parsed.lineReviews, hasLength(2));
    expect(
      parsed.lineReviews.every((review) => review.label == 'Good'),
      isTrue,
    );
    expect(parsed.quality.label, 'Good');
  });

  test(
    'classifies contractor material and tool receipts with review guidance',
    () {
      final parsed = parseExpenseReceiptText('''
THE HOME DEPOT
2026-06-10
1/2 IN COPPER 90 ELBOW 7.48
QTY 2 SAW BLADE 19.98
MISC ITEM 4.50
TOTAL 31.96
''');

      expect(parsed.merchantName, 'The Home Depot');
      expect(parsed.lines.map((line) => line.category), [
        'Materials',
        'Tools',
        'Uncategorized',
      ]);
      expect(parsed.lines[1].quantity, 2);
      expect(parsed.lineReviews[0].label, 'Good');
      expect(parsed.lineReviews[1].label, 'Good');
      expect(parsed.lineReviews[2].needsReview, isTrue);
      expect(
        parsed.warnings.last,
        contains('1 parsed receipt line needs review'),
      );
    },
  );

  test('recognizes hardware and auto chain merchant confidence context', () {
    final hardware = parseExpenseReceiptText('''
ACE HARDWARE
06/12/2026
GALV PIPE COUPLING 4.29
NITRILE GLOVES 12.99
TOTAL 17.28
''');

    expect(hardware.merchantName, 'Ace Hardware');
    expect(hardware.lines.map((line) => line.category), [
      'Materials',
      'Safety Gear',
    ]);
    expect(hardware.lineReviews.first.label, 'Good');
    expect(hardware.lineReviews.last.label, 'Good');

    final auto = parseExpenseReceiptText('''
NAPA AUTO PARTS
06/12/2026
ALTERNATOR 189.99
SHOP TOWELS 8.99
TOTAL 198.98
''');

    expect(auto.merchantName, 'NAPA Auto Parts');
    expect(auto.lines.map((line) => line.category), [
      'Vehicle Parts',
      'Vehicle Supplies',
    ]);
    expect(auto.lineReviews.first.label, 'Good');
    expect(auto.lineReviews.last.label, 'Good');
  });

  test('recognizes grocery and fast food merchant defaults', () {
    final groceries = parseExpenseReceiptText('''
KROGER
06/12/2026
CASE WATER 5.99
BANANA 1.42
TOTAL 7.41
''');

    expect(groceries.merchantName, 'Kroger');
    expect(groceries.lines.map((line) => line.category), [
      'Groceries',
      'Groceries',
    ]);
    expect(
      groceries.lineReviews.every((review) => review.label == 'Good'),
      isTrue,
    );

    final meal = parseExpenseReceiptText('''
CHICK-FIL-A
06/12/2026
COMBO MEAL 10.89
DRINK 2.19
TOTAL 13.08
''');

    expect(meal.merchantName, 'Chick-fil-A');
    expect(meal.lines.map((line) => line.category), ['Meals', 'Meals']);
    expect(meal.lineReviews.every((review) => review.label == 'Good'), isTrue);
  });

  test('uses review confidence when merchant default is the only match', () {
    final parsed = parseExpenseReceiptText('''
WALMART
06/12/2026
GENERAL MDSE 17.48
TOTAL 17.48
''');

    expect(parsed.merchantName, 'Walmart');
    expect(parsed.lines.single.category, 'Uncategorized');
    expect(parsed.lineReviews.single.label, 'Poor');
    expect(parsed.lineReviews.single.guidance, contains('Low confidence'));
  });

  test('uses fuel signals for grocery and club fuel receipts', () {
    final krogerFuel = parseExpenseReceiptText('''
KROGER FUEL CENTER
06/12/2026 07:12 AM
Pump 04
Regular Unleaded 14.250 GAL 47.01
Total 47.01
''');

    expect(krogerFuel.merchantName, 'Kroger');
    expect(krogerFuel.lines.single.category, 'Fuel');
    expect(krogerFuel.lines.single.quantity, 14.25);
    expect(krogerFuel.lines.single.fuelType, 'Gasoline');
    expect(krogerFuel.lineReviews.single.label, 'Good');

    final samsFuel = parseExpenseReceiptText('''
SAM'S CLUB FUEL
06/12/2026
Diesel Fuel 22.100 Gallons 83.76
Total 83.76
''');

    expect(samsFuel.merchantName, "Sam's Club");
    expect(samsFuel.lines.single.category, 'Fuel');
    expect(samsFuel.lines.single.fuelType, 'Diesel');
  });

  test('recognizes regional fuel and expanded service merchants', () {
    final sheetz = parseExpenseReceiptText('''
SHEETZ
06/12/2026
PUMP 07 UNLEADED 12.00 GAL 42.84
TOTAL 42.84
''');

    expect(sheetz.merchantName, 'Sheetz');
    expect(sheetz.lines.single.category, 'Fuel');

    final takeFive = parseExpenseReceiptText('''
TAKE 5 OIL CHANGE
06/12/2026
FULL SYNTHETIC OIL CHANGE 79.99
SHOP SUPPLIES 4.99
TOTAL 84.98
''');

    expect(takeFive.merchantName, 'Take 5 Oil Change');
    expect(takeFive.lines.map((line) => line.category), [
      'Maintenance',
      'Repair',
    ]);
  });

  test('parses fuel abbreviations, unit price, and odometer hints', () {
    final parsed = parseExpenseReceiptText('''
PILOT TRAVEL CENTER
06/12/2026 06:45 AM
Odometer: 298240
Pump 12
UNL 12.50 @ 3.459 43.24
TOTAL 43.24
''');

    expect(parsed.merchantName, 'Pilot Flying J');
    expect(parsed.lines.single.category, 'Fuel');
    expect(parsed.lines.single.quantity, 12.5);
    expect(parsed.lines.single.unit, 'gallon');
    expect(parsed.lines.single.unitPrice, 3.459);
    expect(parsed.lines.single.odometerReading, 298240);
    expect(parsed.lines.single.fuelType, 'Gasoline');
    expect(parsed.lines.single.fillType, 'Full fill-up');
  });

  test('parses fuel receipts with gallons before the amount', () {
    final parsed = parseExpenseReceiptText('''
EXXON
06/12/2026
Product Regular Unleaded
GAL 10.250 PRICE/GAL 3.399 AMOUNT 34.84
TOTAL 34.84
''');

    expect(parsed.merchantName, 'Exxon');
    expect(parsed.lines.single.category, 'Fuel');
    expect(parsed.lines.single.quantity, 10.25);
    expect(parsed.lines.single.unitPrice, 3.399);
    expect(parsed.lines.single.fuelType, 'Gasoline');
  });

  test('parses EV charging and DEF as fuel subtypes', () {
    final ev = parseExpenseReceiptText('''
ChargePoint
06/12/2026
Energy 34.75 kWh 16.33
Total 16.33
''');

    expect(ev.merchantName, 'ChargePoint');
    expect(ev.lines.single.category, 'Fuel');
    expect(ev.lines.single.quantity, 34.75);
    expect(ev.lines.single.unit, 'kWh');
    expect(ev.lines.single.fuelType, 'Electric');

    final def = parseExpenseReceiptText('''
LOVE'S TRAVEL STOP
06/12/2026
DEF Fluid 2.500 GAL 10.00
Total 10.00
''');

    expect(def.merchantName, "Love's");
    expect(def.lines.single.category, 'Fuel');
    expect(def.lines.single.quantity, 2.5);
    expect(def.lines.single.fuelType, 'DEF');
  });

  test('ignores tender rows so payment lines do not become expenses', () {
    final parsed = parseExpenseReceiptText('''
Advance Auto Parts
06/12/2026
Brake Caliper 154.21
Subtotal 154.21
Tax 10.79
Debit Tender 165.00
Approval 123456
Amount Paid 165.00
''');

    expect(parsed.lines, hasLength(1));
    expect(parsed.lines.single.description, 'Brake Caliper');
    expect(parsed.lines.single.category, 'Vehicle Parts');
    expect(parsed.enteredTotal, 165.00);
    expect(
      parsed.warnings.any((warning) => warning.contains('do not match')),
      isFalse,
    );
  });

  test('warns when parsed line totals do not reconcile with subtotal', () {
    final parsed = parseExpenseReceiptText('''
LOWE'S HOME IMPROVEMENT
06/12/2026
PVC PIPE 12.00
Subtotal 42.00
Tax 2.52
Total 44.52
''');

    expect(parsed.lines, hasLength(1));
    expect(parsed.lines.single.category, 'Materials');
    expect(
      parsed.warnings,
      contains(
        'Parsed line totals (\$12.00) do not match the receipt subtotal (\$42.00). Review missing lines, discounts, and OCR mistakes.',
      ),
    );
    expect(parsed.quality.needsReview, isTrue);
    expect(parsed.quality.reasons.join(' '), contains('do not match'));
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
