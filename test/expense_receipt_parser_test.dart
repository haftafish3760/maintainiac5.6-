import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_assistance_policy.dart';

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
    expect(parsed.fieldConfidences['merchant']?.label, 'Review');
    expect(parsed.fieldConfidences['merchant']?.reason, contains('header'));
    expect(parsed.fieldConfidences['date']?.label, 'Good');
    expect(parsed.fieldConfidences['time']?.label, 'Good');
    expect(parsed.fieldConfidences['subtotal']?.label, 'Good');
    expect(parsed.fieldConfidences['tax']?.label, 'Good');
    expect(parsed.fieldConfidences['total']?.label, 'Good');
    expect(parsed.fieldConfidences['receiptMath']?.label, 'Good');
    expect(
      parsed.diagnostics.confidenceForField('receiptMath')?.reason,
      contains('reconcile'),
    );
  });

  test('tracks parser confidence for known merchant and inferred totals', () {
    final parsed = parseExpenseReceiptText('''
LOWE'S HOME IMPROVEMENT
PVC GLUE 7.99
Tax 0.56
Total 8.55
''', fallbackDate: DateTime(2026, 6, 12));

    expect(parsed.merchantName, "Lowe's");
    expect(parsed.receiptDate, DateTime(2026, 6, 12));
    expect(parsed.enteredSubtotal, closeTo(7.99, .001));
    expect(parsed.fieldConfidences['merchant']?.label, 'Good');
    expect(
      parsed.fieldConfidences['merchant']?.reason,
      'Merchant matched a known receipt profile.',
    );
    expect(parsed.fieldConfidences['date']?.label, 'Review');
    expect(
      parsed.fieldConfidences['date']?.reason,
      'Receipt date used the selected day as a fallback.',
    );
    expect(parsed.fieldConfidences['subtotal']?.label, 'Review');
    expect(
      parsed.fieldConfidences['subtotal']?.reason,
      'Subtotal was inferred from other receipt totals.',
    );
    expect(parsed.fieldConfidences['tax']?.label, 'Good');
    expect(parsed.fieldConfidences['total']?.label, 'Good');
    expect(parsed.fieldConfidences['receiptMath']?.label, 'Review');
    expect(
      parsed.fieldConfidences['receiptMath']?.reason,
      contains('inferred or missing'),
    );
  });

  test('light parser depth reads receipt header and totals only', () {
    final parsed = parseExpenseReceiptText('''
LOWE'S HOME IMPROVEMENT
06/12/2026
1/2 IN COPPER 90 ELBOW 7.48
SAW BLADE 19.98
Subtotal 27.46
Tax 1.92
Total 29.38
''', parserDepth: ReceiptParserDepth.proofTotalsOnly);

    expect(parsed.merchantName, "Lowe's");
    expect(parsed.receiptDate, DateTime(2026, 6, 12));
    expect(parsed.enteredSubtotal, 27.46);
    expect(parsed.enteredTax, 1.92);
    expect(parsed.enteredTotal, 29.38);
    expect(parsed.lines, isEmpty);
    expect(parsed.warnings.single, contains('header and totals only'));
    expect(parsed.quality.needsReview, isTrue);
    expect(parsed.diagnostics.parserDepth, ReceiptParserDepth.proofTotalsOnly);
    expect(parsed.diagnostics.lineSummaryLabel, 'No line items parsed');
    expect(parsed.diagnostics.catalogSummaryLabel, 'Catalog matching skipped');
  });

  test('medium parser depth keeps line items but skips inventory matching', () {
    final parsed = parseExpenseReceiptText('''
LOWE'S HOME IMPROVEMENT
06/12/2026
25PK #8 X 1-1/4 WOOD SCREWS 6.98
TOTAL 6.98
''', parserDepth: ReceiptParserDepth.lineItems);

    expect(parsed.lines.single.category, 'Materials');
    expect(parsed.lines.single.catalogItemId, isNull);
    expect(parsed.lineReviews.single.catalogItemName, isNull);
    expect(parsed.diagnostics.parserDepth, ReceiptParserDepth.lineItems);
    expect(parsed.diagnostics.materialLineCount, 1);
    expect(parsed.diagnostics.catalogMatchedLineCount, 0);
    expect(parsed.diagnostics.catalogSummaryLabel, 'Catalog matching skipped');
    expect(
      parsed.lineReviews.single.reason,
      contains('catalog matching was skipped'),
    );
  });

  test('does not turn Lowe address ZIP text into a receipt total', () {
    final parsed = parseExpenseReceiptText('''
LOWE'S HOME CENTERS, LLC
6400 BRODIE LANE
AUSTIN, TX 78745 (512) 895-5560
SALE
SALES#: S2313USO 3644746  TRANS#: 18854480 07-09-21
23536 OATEY 14-OZ PLUMBERS PUTTY       2.99
SUBTOTAL:                              2.99
TAX:                                   0.25
INVOICE 10394  TOTAL:                  3.24
07/09/21 13:14:57
''');

    expect(parsed.merchantName, "Lowe's");
    expect(parsed.enteredSubtotal, 2.99);
    expect(parsed.enteredTax, 0.25);
    expect(parsed.enteredTotal, 3.24);
    expect(parsed.enteredTotal, isNot(787.45));
    expect(parsed.lines, hasLength(1));
    expect(parsed.lines.single.subtotal, 2.99);
  });

  test('heavy parser depth allows inventory catalog matching', () {
    final parsed = parseExpenseReceiptText('''
LOWE'S HOME IMPROVEMENT
06/12/2026
25PK #8 X 1-1/4 WOOD SCREWS 6.98
TOTAL 6.98
''', parserDepth: ReceiptParserDepth.inventoryMatching);

    expect(parsed.lines.single.category, 'Materials');
    expect(parsed.lines.single.catalogItemName, '#8 x 1-1/4 in Wood Screws');
    expect(
      parsed.lineReviews.single.catalogItemName,
      '#8 x 1-1/4 in Wood Screws',
    );
    expect(parsed.lines.single.catalogMatchConfidence, isNotNull);
    expect(
      parsed.diagnostics.parserDepth,
      ReceiptParserDepth.inventoryMatching,
    );
    expect(parsed.diagnostics.catalogMatchedLineCount, 1);
    expect(parsed.diagnostics.catalogSummaryLabel, contains('1 of 1'));
    expect(parsed.diagnostics.reconciled, isTrue);
    expect(
      parsed.diagnostics.reconciliationLabel,
      'Line total matches receipt total',
    );
    expect(parsed.diagnostics.hasCompleteExplicitTotals, isFalse);
    expect(parsed.diagnostics.taxMathReconciled, isFalse);
    expect(parsed.diagnostics.totalsMathLabel, 'Receipt total math incomplete');
    expect(parsed.diagnostics.trustLabel, 'Ready to review');
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
      expect(parsed.lines[0].rawReceiptText, '1/2 IN COPPER 90 ELBOW 7.48');
      expect(
        parsed.lines[0].receiptEvidenceText,
        parsed.lines[0].rawReceiptText,
      );
      expect(
        parsed.lines[0].parserConfidence,
        parsed.lineReviews[0].confidence,
      );
      expect(parsed.lines[0].parserReviewLabel, parsed.lineReviews[0].label);
      expect(parsed.lines[0].parserReviewReason, parsed.lineReviews[0].reason);
      expect(
        parsed.lines[0].parserNeedsReview,
        parsed.lineReviews[0].needsReview,
      );
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

  test(
    'recognizes built-in regional fuel and convenience merchant profiles',
    () {
      final fixtures = <({String rawName, String expectedMerchant})>[
        (rawName: 'WAWA FOOD MARKET', expectedMerchant: 'Wawa'),
        (rawName: '7ELEVEN STORE', expectedMerchant: '7-Eleven'),
        (rawName: '7-ELEVEN HAWAII', expectedMerchant: '7-Eleven Hawaii'),
        (rawName: 'AMPM STORE', expectedMerchant: 'ampm'),
        (rawName: 'CASEYS GENERAL STORE', expectedMerchant: "Casey's"),
        (rawName: 'KWIK STAR #112', expectedMerchant: 'Kwik Trip'),
        (rawName: 'CUMBERLAND FARMS', expectedMerchant: 'Cumberland Farms'),
        (
          rawName: 'HOLIDAY STATIONSTORE',
          expectedMerchant: 'Holiday Stationstores',
        ),
        (rawName: 'TOWN PUMP', expectedMerchant: 'Town Pump'),
        (rawName: 'SPINX STORE', expectedMerchant: 'Spinx'),
        (rawName: 'PARKERS KITCHEN', expectedMerchant: "Parker's"),
        (rawName: 'CEFCO #1045', expectedMerchant: 'CEFCO'),
        (rawName: 'GATE EXPRESS', expectedMerchant: 'GATE'),
        (rawName: 'ENMARKET', expectedMerchant: 'Enmarket'),
        (rawName: 'OXXO #104', expectedMerchant: 'OXXO'),
        (rawName: 'KENT KWIK', expectedMerchant: 'Kent Kwik'),
        (rawName: 'MEGA SAVER', expectedMerchant: 'Mega Saver'),
        (
          rawName: 'GREEN VALLEY GROCERY',
          expectedMerchant: 'Green Valley Grocery',
        ),
        (rawName: 'JACKSONS FOOD STORES', expectedMerchant: 'Jacksons'),
        (rawName: 'REDWOOD MARKET', expectedMerchant: 'Redwood Markets'),
        (rawName: 'EXTRAMILE', expectedMerchant: 'ExtraMile'),
        (rawName: 'MIRABITO', expectedMerchant: 'Mirabito'),
        (rawName: 'BYRNE DAIRY', expectedMerchant: 'Byrne Dairy'),
        (rawName: 'DASH IN', expectedMerchant: 'Dash In'),
      ];

      for (final fixture in fixtures) {
        final parsed = parseExpenseReceiptText('''
${fixture.rawName}
06/23/2026
PUMP 04 REG UNL 10.000 GAL 35.90
TOTAL 35.90
''');

        expect(
          parsed.merchantName,
          fixture.expectedMerchant,
          reason: fixture.rawName,
        );
        expect(parsed.lines.single.category, 'Fuel', reason: fixture.rawName);
        expect(parsed.lines.single.quantity, 10.0, reason: fixture.rawName);
        expect(
          parsed.lines.single.fuelType,
          'Gasoline',
          reason: fixture.rawName,
        );
        expect(
          parsed.lineReviews.single.label,
          'Good',
          reason: fixture.rawName,
        );
      }
    },
  );

  test(
    'recognizes major fuel brands and avoids convenience false positives',
    () {
      final fuelBrands = <({String rawName, String expectedMerchant})>[
        (rawName: 'SHELL OIL', expectedMerchant: 'Shell'),
        (rawName: 'EXXONMOBIL', expectedMerchant: 'Exxon'),
        (rawName: 'BP#2841', expectedMerchant: 'BP'),
        (rawName: 'CHEVRON EXTRAMILE', expectedMerchant: 'Chevron'),
        (rawName: 'MARATHON PETROLEUM', expectedMerchant: 'Marathon'),
        (rawName: 'PHILLIPS66', expectedMerchant: 'Phillips 66'),
        (rawName: 'SINCLAIR', expectedMerchant: 'Sinclair'),
        (rawName: 'VALERO', expectedMerchant: 'Valero'),
      ];

      for (final fixture in fuelBrands) {
        final parsed = parseExpenseReceiptText('''
${fixture.rawName}
06/23/2026
DIESEL 18.000 GAL 68.22
TOTAL 68.22
''');

        expect(
          parsed.merchantName,
          fixture.expectedMerchant,
          reason: fixture.rawName,
        );
        expect(parsed.lines.single.category, 'Fuel', reason: fixture.rawName);
        expect(parsed.lines.single.fuelType, 'Diesel', reason: fixture.rawName);
      }

      final holidayGift = parseExpenseReceiptText('''
LOCAL GIFT SHOP
06/23/2026
HOLIDAY CARD 4.99
TOTAL 4.99
''');

      expect(holidayGift.merchantName, 'Local Gift Shop');
      expect(
        holidayGift.lines.where((line) => line.category == 'Fuel'),
        isEmpty,
      );
    },
  );

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

  test('parses split-row truck stop fuel receipts with rewards discounts', () {
    final parsed = parseExpenseReceiptText('''
PILOT TRVL CTR
06/23/2026 05:42 AM
PUMP 12
PRODUCT DIESEL
GALLONS 18.425
PRICE/GAL 3.699
FUEL SALE 68.15
REWARDS DISC -1.20
TOTAL 66.95
VISA FLEET CARD 66.95
AUTH 442193
TRACE 77801
ODOMETER 184220
''');

    expect(parsed.merchantName, 'Pilot Flying J');
    expect(parsed.receiptDate, DateTime(2026, 6, 23));
    expect(parsed.receiptTimeMinutes, (5 * 60) + 42);
    expect(parsed.enteredTotal, 66.95);
    expect(parsed.lines, hasLength(2));
    expect(parsed.lines.first.category, 'Fuel');
    expect(parsed.lines.first.quantity, 18.425);
    expect(parsed.lines.first.unit, 'gallon');
    expect(parsed.lines.first.unitPrice, 3.699);
    expect(parsed.lines.first.fuelType, 'Diesel');
    expect(parsed.lines.first.odometerReading, 184220);
    expect(parsed.lines.last.category, 'Receipt Adjustment');
    expect(parsed.lines.last.subtotal, -1.20);
    expect(parsed.diagnostics.reconciled, isTrue);
  });

  test('parses faded gasoline receipts with separate GALS and PPG rows', () {
    final parsed = parseExpenseReceiptText('''
SHELL OIL
O6/23/2O26 O7:O5 AM
PUMP O3
REG UNL
GALS 12.347
PPG 3.459
FUEL SALE 42.71
TOTAL 42.71
FLEET CARD 42.71
DRIVER ID 1042
''');

    expect(parsed.merchantName, 'Shell');
    expect(parsed.receiptDate, DateTime(2026, 6, 23));
    expect(parsed.receiptTimeMinutes, (7 * 60) + 5);
    expect(parsed.lines.single.category, 'Fuel');
    expect(parsed.lines.single.quantity, 12.347);
    expect(parsed.lines.single.unitPrice, 3.459);
    expect(parsed.lines.single.fuelType, 'Gasoline');
    expect(parsed.diagnostics.reconciled, isTrue);
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

  test('ignores saved, cash back, and change rows when reading totals', () {
    final parsed = parseExpenseReceiptText('''
WALMART
06/20/2026
SHOP TOWELS 8.97
CASE WATER 5.99
YOU SAVED 3.50
TOTAL SAVINGS 3.50
CASH BACK 20.00
CHANGE DUE 0.54
SUBTOTAL 14.96
TAX 1.05
TOTAL 16.01
VISA CARD 36.01
''');

    expect(parsed.enteredSubtotal, 14.96);
    expect(parsed.enteredTax, 1.05);
    expect(parsed.enteredTotal, 16.01);
    expect(parsed.lines, hasLength(2));
    final descriptions = parsed.lines
        .map((line) => line.description.toLowerCase())
        .join(' ');
    expect(descriptions, isNot(contains('saved')));
    expect(descriptions, isNot(contains('cash back')));
    expect(parsed.diagnostics.reconciled, isTrue);
  });

  test('uses tender amount only when explicit receipt total is missing', () {
    final parsed = parseExpenseReceiptText('''
WALMART
06/20/2026
GEN MDSE 17.48
CASE WATER 5.99
SHOP TOWELS 8.97
GIFT CARD BALANCE 12.00
VISA CARD 32.44
''');

    expect(parsed.enteredTotal, 32.44);
    expect(parsed.lines, hasLength(3));
    final descriptions = parsed.lines
        .map((line) => line.description.toLowerCase())
        .join(' ');
    expect(descriptions, isNot(contains('gift card')));
    expect(parsed.diagnostics.reconciled, isTrue);
  });

  test('keeps positive balance due but ignores stored value balances', () {
    final parsed = parseExpenseReceiptText('''
SUPPLY HOUSE
06/20/2026
PVC FITTING 4.29
STORE CREDIT BALANCE 25.00
BALANCE DUE 4.29
''');

    expect(parsed.enteredTotal, 4.29);
    expect(parsed.lines, hasLength(1));
    expect(parsed.lines.single.description, 'Pvc Fitting');
    expect(parsed.diagnostics.reconciled, isTrue);
  });

  test('parses compact OCR cents and tax suffixes on item rows', () {
    final parsed = parseExpenseReceiptText('''
ACE HARDWARE
06/20/2026
SKU 123456 PVC GLUE 799T
SHOP TOWELS 897
MERCHANDISE TOTAL 16.96
STATE TAX 1.19
ORDER TOTAL 18.15
''');

    expect(parsed.merchantName, 'Ace Hardware');
    expect(parsed.enteredSubtotal, 16.96);
    expect(parsed.enteredTax, 1.19);
    expect(parsed.enteredTotal, 18.15);
    expect(parsed.lines, hasLength(2));
    expect(parsed.lines.first.category, 'Materials');
    expect(parsed.lines.first.description.toLowerCase(), contains('pvc glue'));
    expect(
      parsed.lines.first.description.toLowerCase(),
      isNot(contains('sku')),
    );
    expect(parsed.lines.first.subtotal, 7.99);
    expect(parsed.lines.last.category, 'Vehicle Supplies');
    expect(parsed.lines.last.subtotal, 8.97);
    expect(parsed.diagnostics.reconciled, isTrue);
  });

  test(
    'parses CR and trailing minus returns without treating them as payments',
    () {
      final parsed = parseExpenseReceiptText('''
LOWE'S HOME IMPROVEMENT
06/20/2026
PVC PIPE 12.00
RETURN PVC PIPE 1200CR
PAINTERS TAPE 599
TOTAL 5.99
''');

      expect(parsed.lines, hasLength(3));
      expect(parsed.lines[0].subtotal, 12.00);
      expect(parsed.lines[1].subtotal, -12.00);
      expect(parsed.lines[1].category, 'Materials');
      expect(parsed.lines[1].parserNeedsReview, isFalse);
      expect(parsed.lines[2].subtotal, 5.99);
      expect(parsed.diagnostics.reconciled, isTrue);
    },
  );

  test('parses spaced OCR prices, line numbers, item ids, and quantities', () {
    final parsed = parseExpenseReceiptText('''
THE HOME DEPOT
06/20/2026
LINE 01 123456 PVC COUPLING 2 @ 3.99 7 98
25PK #8 WOOD SCREWS 6 98T
QTY: 3 SHOP TOWELS 26 91
SUBTOTAL 41 87
TAX 2 93
TOTAL 44 80
''');

    expect(parsed.enteredSubtotal, 41.87);
    expect(parsed.enteredTax, 2.93);
    expect(parsed.enteredTotal, 44.80);
    expect(parsed.lines, hasLength(3));
    expect(parsed.lines[0].category, 'Materials');
    expect(parsed.lines[0].description.toLowerCase(), contains('pvc coupling'));
    expect(
      parsed.lines[0].description.toLowerCase(),
      isNot(contains('123456')),
    );
    expect(parsed.lines[0].subtotal, 7.98);
    expect(parsed.lines[0].quantity, 2);
    expect(parsed.lines[0].unitPrice, 3.99);
    expect(parsed.lines[1].category, 'Materials');
    expect(parsed.lines[1].unitsPerPackage, 25);
    expect(parsed.lines[1].subtotal, 6.98);
    expect(parsed.lines[2].category, 'Vehicle Supplies');
    expect(parsed.lines[2].quantity, 3);
    expect(parsed.lines[2].subtotal, 26.91);
    expect(parsed.diagnostics.reconciled, isTrue);
  });

  test('ignores gift card and store credit tenders but keeps item totals', () {
    final parsed = parseExpenseReceiptText('''
HOME DEPOT
06/20/2026
1/2 COPPER ELBOW 748T
GIFT CARD 3.00
STORE CREDIT 4.48
TOTAL 7.48
''');

    expect(parsed.enteredTotal, 7.48);
    expect(parsed.lines, hasLength(1));
    expect(parsed.lines.single.category, 'Materials');
    expect(parsed.lines.single.subtotal, 7.48);
    expect(parsed.diagnostics.reconciled, isTrue);
  });

  test(
    'recognizes negative receipt adjustments without lowering confidence',
    () {
      final parsed = parseExpenseReceiptText('''
CVS PHARMACY
06/20/2026
SHOP TOWELS 8.97
MFR COUPON -2.00
STORE DISCOUNT (1.50)
SUBTOTAL 5.47
TAX 0.38
TOTAL 5.85
''');

      expect(parsed.enteredSubtotal, 5.47);
      expect(parsed.enteredTotal, 5.85);
      expect(parsed.lines, hasLength(3));
      expect(parsed.lines[0].category, 'Vehicle Supplies');
      expect(parsed.lines[0].subtotal, 8.97);
      expect(parsed.lines[1].category, 'Receipt Adjustment');
      expect(parsed.lines[1].subtotal, -2.00);
      expect(parsed.lines[1].parserNeedsReview, isFalse);
      expect(parsed.lines[1].parserReviewLabel, 'Good');
      expect(parsed.lines[1].parserReviewReason, contains('coupon'));
      expect(parsed.lines[2].category, 'Receipt Adjustment');
      expect(parsed.lines[2].subtotal, -1.50);
      expect(parsed.lines[2].parserNeedsReview, isFalse);
      expect(parsed.lines[2].parserReviewLabel, 'Good');
      expect(parsed.lines[2].parserReviewReason, contains('discount'));
      expect(
        parsed.warnings.any((warning) => warning.contains('do not match')),
        isFalse,
      );
      expect(parsed.diagnostics.negativeLineCount, 2);
      expect(parsed.diagnostics.adjustmentLineCount, 2);
      expect(parsed.diagnostics.hasAdjustments, isTrue);
      expect(parsed.diagnostics.reconciled, isTrue);
    },
  );

  test('keeps returned item category when negative line names the item', () {
    final parsed = parseExpenseReceiptText('''
LOWE'S HOME IMPROVEMENT
06/20/2026
PVC PIPE 12.00
RETURN PVC PIPE -12.00
PAINTERS TAPE 5.99
TOTAL 5.99
''');

    expect(parsed.lines, hasLength(3));
    expect(parsed.lines[0].category, 'Materials');
    expect(parsed.lines[0].subtotal, 12.00);
    expect(parsed.lines[1].category, 'Materials');
    expect(parsed.lines[1].subtotal, -12.00);
    expect(parsed.lines[1].parserNeedsReview, isFalse);
    expect(parsed.lines[1].parserReviewReason, contains('return/refund'));
    expect(parsed.lines[2].category, 'Materials');
    expect(parsed.lines[2].subtotal, 5.99);
    expect(
      parsed.warnings.any((warning) => warning.contains('do not match')),
      isFalse,
    );
  });

  test('flags unlabeled negative receipt lines for review', () {
    final parsed = parseExpenseReceiptText('''
WALMART
06/20/2026
SHOP TOWELS 8.97
MISC ADJ -1.00
TOTAL 7.97
''');

    expect(parsed.lines, hasLength(2));
    expect(parsed.lines.last.subtotal, -1.00);
    expect(parsed.lines.last.parserNeedsReview, isTrue);
    expect(
      parsed.lines.last.parserReviewReason,
      contains('missing an adjustment label'),
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

  test('warns when explicit subtotal tax and total do not reconcile', () {
    final parsed = parseExpenseReceiptText('''
THE HOME DEPOT
06/12/2026
PVC GLUE 7.99
PIPE STRAP 2.01
Subtotal 10.00
Tax 0.80
Total 12.80
''');

    expect(parsed.lines, hasLength(2));
    expect(parsed.diagnostics.hasCompleteExplicitTotals, isTrue);
    expect(parsed.diagnostics.taxMathReconciled, isFalse);
    expect(parsed.diagnostics.taxMathDifference, closeTo(-2.00, .001));
    expect(
      parsed.diagnostics.totalsMathLabel,
      'Subtotal plus tax differs by \$2.00',
    );
    expect(parsed.diagnostics.trustLabel, 'Needs receipt math review');
    expect(
      parsed.warnings,
      contains(
        'Receipt subtotal plus tax (\$10.80) does not match the receipt total (\$12.80). Review receipt math and OCR mistakes.',
      ),
    );
  });

  test(
    'marks inferred receipt math as incomplete instead of overconfident',
    () {
      final parsed = parseExpenseReceiptText('''
LOWE'S HOME IMPROVEMENT
06/12/2026
PVC GLUE 7.99
Tax 0.56
Total 8.55
''');

      expect(parsed.enteredSubtotal, closeTo(7.99, .001));
      expect(parsed.diagnostics.hasExplicitSubtotal, isFalse);
      expect(parsed.diagnostics.hasExplicitTax, isTrue);
      expect(parsed.diagnostics.hasExplicitTotal, isTrue);
      expect(parsed.diagnostics.hasCompleteExplicitTotals, isFalse);
      expect(parsed.diagnostics.taxMathReconciled, isFalse);
      expect(
        parsed.diagnostics.totalsMathLabel,
        'Receipt total math incomplete',
      );
      expect(
        parsed.warnings.any((warning) => warning.contains('subtotal plus tax')),
        isFalse,
      );
    },
  );

  test('flags receipts where most parsed lines need review', () {
    final parsed = parseExpenseReceiptText('''
CORNER STORE
06/12/2026
AA 1.00
BB 2.00
PVC GLUE 7.99
Total 10.99
''');

    expect(parsed.lines, hasLength(3));
    expect(parsed.diagnostics.reviewLineCount, greaterThanOrEqualTo(2));
    expect(parsed.diagnostics.reviewRatio, greaterThanOrEqualTo(.5));
    expect(parsed.diagnostics.needsHeavyReview, isTrue);
    expect(parsed.diagnostics.trustLabel, 'Needs line review');
    expect(
      parsed.warnings,
      contains(
        'Most parsed receipt lines need review before saving this receipt.',
      ),
    );
  });

  test('normalizes common OCR letter and number swaps before parsing', () {
    final homeCenter = parseExpenseReceiptText('''
H0ME DEP0T
O6/19/2O26
1/2  IN   C0PPER  9O  ELB0W   7.48
PVC  GLUE  7,99
T0TAL 15.47
''');

    expect(homeCenter.merchantName, 'The Home Depot');
    expect(homeCenter.receiptDate, DateTime(2026, 6, 19));
    expect(homeCenter.enteredTotal, 15.47);
    expect(homeCenter.lines, hasLength(2));
    expect(
      homeCenter.lines.first.description.toLowerCase(),
      contains('copper'),
    );
    expect(homeCenter.lines.first.description.toLowerCase(), contains('elbow'));
    expect(homeCenter.lines.first.category, 'Materials');
    expect(homeCenter.lines.first.subtotal, 7.48);
    expect(homeCenter.lines.last.category, 'Materials');
    expect(homeCenter.lines.last.subtotal, 7.99);

    final fuel = parseExpenseReceiptText('''
SHEETZ
O6/19/2O26 O7:15 AM
PUMP O4 UNLEADED 14.25O GAL 47.O1
T0TAL 47.O1
''');

    expect(fuel.merchantName, 'Sheetz');
    expect(fuel.receiptDate, DateTime(2026, 6, 19));
    expect(fuel.receiptTimeMinutes, (7 * 60) + 15);
    expect(fuel.enteredTotal, 47.01);
    expect(fuel.lines.single.category, 'Fuel');
    expect(fuel.lines.single.quantity, 14.25);
    expect(fuel.lines.single.unit, 'gallon');
    expect(fuel.lines.single.subtotal, 47.01);
  });

  test('normalizes damaged Lowe OCR merchant text before matching profile', () {
    final parsed = parseExpenseReceiptText('''
L0WES H0ME IMPR0VEMENT
O6/2O/2O26
PVC C0UPLING 2.49
PVC GLUE 7,99
AM0UNT PAID 10.48
''');

    expect(parsed.merchantName, "Lowe's");
    expect(parsed.receiptDate, DateTime(2026, 6, 20));
    expect(parsed.enteredTotal, 10.48);
    expect(parsed.lines, hasLength(2));
    expect(parsed.lines.map((line) => line.category), [
      'Materials',
      'Materials',
    ]);
  });

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
