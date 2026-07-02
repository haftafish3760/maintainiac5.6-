import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';
import 'package:maintaniac/shared/receipts/receipt_processing_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

void main() {
  test('parses hybrid travel mart OCR into mixed local expense families', () {
    const ocr = ReceiptOcrResult(
      rawText: '''
COUNTY LINE TRAVEL MART
07/01/2026 06:42 AM
PUMP 07
DIESEL
QTY 18.250 GAL
PRICE/G 3.899
FUEL AMT 71.16
COFFEE 2.19
BOTTLED WATER 1.49
PVC ADAPTER 3/4IN 4.29
MERCH TOTAL 79.13
LOCAL TAX 0.48
TOTAL DUE 79.61
VISA 79.61
AUTH 998877
REF 123456
''',
      parserText: '''
COUNTY LINE TRAVEL MART
07/01/2026 06:42 AM
PUMP 07
DIESEL
QTY 18.250 GAL
PRICE/G 3.899
FUEL AMT 71.16
COFFEE 2.19
BOTTLED WATER 1.49
PVC ADAPTER 3/4IN 4.29
MERCH TOTAL 79.13
LOCAL TAX 0.48
TOTAL DUE 79.61
VISA 79.61
AUTH 998877
REF 123456
''',
      textByAttachmentId: {'photo-1': 'private receipt text omitted'},
      source: ReceiptProcessingSource.photo,
    );

    final parsed = parseExpenseReceiptOcrResult(
      ocr,
      capability: const ReceiptDeviceCapability.highCapacity(),
    );

    expect(parsed.merchantName, 'County Line Travel Mart');
    expect(parsed.receiptDate, DateTime(2026, 7, 1));
    expect(parsed.receiptTimeMinutes, (6 * 60) + 42);
    expect(parsed.lines, hasLength(4));
    final fuel = parsed.lines.singleWhere((line) => line.category == 'Fuel');
    expect(fuel.fuelType, 'Diesel');
    expect(fuel.quantity, 18.25);
    expect(fuel.unitPrice, 3.899);
    expect(fuel.parserExpenseFamily, 'fuel');
    expect(
      parsed.lines.any((line) => line.rawReceiptText.contains('AUTH')),
      isFalse,
    );
    expect(
      parsed.lines.any((line) => line.rawReceiptText.contains('REF')),
      isFalse,
    );
    expect(
      parsed.diagnostics.ocrItemExpenseFamilyStatus,
      'mixed_item_families',
    );
    expect(
      parsed.diagnostics.parserItemExpenseFamilyStatus,
      'mixed_item_families',
    );
    expect(parsed.diagnostics.parserItemExpenseFamilyCounts['fuel'], 1);
    expect(
      parsed.diagnostics.parserItemExpenseFamilyCounts['food_or_grocery'],
      2,
    );
    expect(parsed.diagnostics.parserItemExpenseFamilyCounts['materials'], 1);
    expect(parsed.diagnostics.hasAnyMixedItemExpenseFamilies, isTrue);
    expect(
      parsed.diagnostics.mixedItemFamilyReviewLabel,
      'Parser mixed families: food/grocery, fuel, materials',
    );
    expect(parsed.diagnostics.reconciled, isTrue);
  });

  test(
    'keeps convenience fuel and store items separate on hybrid receipts',
    () {
      final parsed = parseExpenseReceiptText('''
RIVER ROAD MARKET
06/23/2026
PUMP 04
REGULAR UNLEADED 10.000 GAL 35.90
COFFEE 2.19
CHIPS 1.79
TOTAL 39.88
''');

      expect(parsed.merchantName, 'River Road Market');
      expect(parsed.lines, hasLength(3));
      expect(parsed.lines.first.category, 'Fuel');
      expect(parsed.lines[1].category, 'Meals');
      expect(parsed.lines.last.category, isNot('Fuel'));
      expect(parsed.lines.last.description.toLowerCase(), contains('chips'));
      expect(parsed.lines.first.quantity, 10.0);
      expect(parsed.lines.first.fuelType, 'Gasoline');
      expect(parsed.diagnostics.reconciled, isTrue);
    },
  );

  test('keeps club fuel and grocery items separate on one receipt', () {
    final parsed = parseExpenseReceiptText('''
SAM'S CLUB
06/23/2026
DIESEL FUEL 22.100 GALLONS 83.76
CASE WATER 5.99
SNACK PACK 8.49
TOTAL 98.24
''');

    expect(parsed.merchantName, "Sam's Club");
    expect(parsed.lines, hasLength(3));
    expect(parsed.lines.map((line) => line.category), [
      'Fuel',
      'Groceries',
      'Groceries',
    ]);
    expect(parsed.lines.first.fuelType, 'Diesel');
    expect(parsed.diagnostics.reconciled, isTrue);
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
}
