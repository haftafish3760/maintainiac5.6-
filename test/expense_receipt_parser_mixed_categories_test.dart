import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';

void main() {
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

  test(
    'classifies generic market grocery and vehicle supply families locally',
    () {
      final parsed = parseExpenseReceiptText('''
CORNER MARKET 52
06/12/2026
BANANAS 4011 1.29
SHOP TOWELS 5.00
SUBTOTAL 6.29
TAX 0.41
TOTAL 6.70
EBT FOOD 1.29
VISA 5.41
''');

      expect(parsed.lines, hasLength(2));
      expect(parsed.lines.map((line) => line.category), [
        'Groceries',
        'Vehicle Supplies',
      ]);
      expect(parsed.lines.first.parserExpenseFamily, 'food_or_grocery');
      expect(parsed.lines.last.parserExpenseFamily, 'vehicle_supplies');
      expect(
        parsed.diagnostics.parserItemExpenseFamilyStatus,
        'mixed_item_families',
      );
      expect(
        parsed.diagnostics.parserItemExpenseFamilySummaryLabel,
        'Parser mixed families: food/grocery, vehicle supplies',
      );
      expect(
        parsed.diagnostics.parserTaskCount(
          'parser_expense_family_mixed_receipt',
        ),
        2,
      );
      expect(parsed.diagnostics.hasParserMixedItemExpenseFamilies, isTrue);
    },
  );

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
}
