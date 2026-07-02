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
    expect(parsed.diagnostics.classificationReadyLineCount, 1);
    expect(parsed.diagnostics.hasClassificationReadyLines, isTrue);
    expect(parsed.diagnostics.hasMixedReceiptMathBasis, isTrue);
    expect(parsed.diagnostics.hasParserCategoryCounts, isTrue);
    expect(parsed.diagnostics.parserCategoryCount('fuel'), 1);
    expect(parsed.diagnostics.hasParserCategoryReady, isTrue);
    expect(parsed.diagnostics.hasParserCategoryReview, isFalse);
    expect(parsed.diagnostics.hasParserRequiredFieldStatusCounts, isTrue);
    expect(
      parsed.diagnostics.parserRequiredFieldStatusCount('vendor_ready'),
      1,
    );
    expect(
      parsed.diagnostics.parserRequiredFieldStatusCount('item_price_ready'),
      1,
    );
    expect(
      parsed.diagnostics.parserRequiredFieldStatusCount('category_ready'),
      1,
    );
    expect(
      parsed.diagnostics.parserRequiredFieldStatusCount(
        'parser_required_ready_total',
      ),
      8,
    );
    expect(parsed.diagnostics.hasParserRequiredFieldMissing, isFalse);
    expect(parsed.diagnostics.hasParserRequiredFieldReview, isFalse);
    expect(
      parsed.diagnostics.parserRequiredFieldStatusLabel,
      'parser_required_receipt_fields:ready=8;review=0;missing=0',
    );
    expect(
      parsed.diagnostics.parserDownstreamReadinessStatus,
      'vehicle_cost_ready',
    );
    expect(
      parsed.diagnostics.parserDownstreamReadinessCount('vendor_ready'),
      1,
    );
    expect(
      parsed.diagnostics.parserDownstreamReadinessCount('priced_line_ready'),
      1,
    );
    expect(parsed.diagnostics.parserDownstreamReadinessCount('total_ready'), 1);
    expect(
      parsed.diagnostics.parserCategoryHealthCount('category_fuel_ready'),
      1,
    );
    expect(
      parsed.diagnostics.parserCategoryHealthCount(
        'category_family_fuel_ready',
      ),
      1,
    );
    expect(
      parsed.diagnostics.parserCategoryFamilyConfidenceCount('fuel', 'strong') +
          parsed.diagnostics.parserCategoryFamilyConfidenceCount(
            'fuel',
            'ready',
          ),
      1,
    );
    expect(parsed.diagnostics.hasParserCategoryPackLimits, isFalse);
    expect(parsed.diagnostics.hasParserCategoryWeakConfidence, isFalse);
    expect(parsed.diagnostics.parserCategoryReviewActionCode, 'ready');
    expect(
      parsed.diagnostics.localReceiptParserRoutingCode,
      'fuel_simple_local',
    );
    expect(parsed.diagnostics.keepsSimpleReceiptLocal, isTrue);
    expect(parsed.diagnostics.shouldOfferDetailedParserPack, isFalse);
    expect(
      parsed.diagnostics.localReceiptParserRoutingLabel,
      contains('Fuel and simple receipt details stay local'),
    );
    expect(
      parsed.diagnostics.localReceiptParserRoutingSummaryLabel,
      'Fuel receipt stayed local',
    );
    expect(
      parsed.diagnostics.localReceiptParserRoutingActionLabel,
      contains('Review fuel amount'),
    );
    expect(
      parsed.diagnostics.parserCategoryReviewActionLabel,
      'Receipt lines are ready to review and save.',
    );
    expect(
      parsed.diagnostics.receiptClassificationSummaryLabel,
      '1 priced line ready; tax ready for mixed split',
    );
    expect(parsed.lineSubtotal, closeTo(48.75, .001));
    expect(parsed.receiptSubtotal, closeTo(48.75, .001));
    expect(parsed.receiptTax, closeTo(2.93, .001));
    expect(parsed.receiptTotal, closeTo(51.68, .001));
    expect(parsed.effectiveTaxRate, closeTo(2.93 / 48.75, .001));
    expect(parsed.businessTotal, closeTo(51.68, .001));
    expect(parsed.personalTotal, closeTo(0, .001));
    expect(
      parsed.businessTotalForLine(parsed.lines.single),
      closeTo(51.68, .001),
    );
  });

  test('parses dot separated OCR receipt dates', () {
    final parsed = parseExpenseReceiptText('''
Quick Fuel
07.09.21 13:14
Pump 03 Diesel 12.500 GAL 48.75
Subtotal 48.75
Sales Tax 2.93
Total 51.68
''');

    expect(parsed.merchantName, 'Quick Fuel');
    expect(parsed.receiptDate, DateTime(2021, 7, 9));
    expect(parsed.receiptTimeMinutes, (13 * 60) + 14);
    expect(parsed.enteredSubtotal, 48.75);
    expect(parsed.enteredTax, 2.93);
    expect(parsed.enteredTotal, 51.68);
    expect(parsed.lines, hasLength(1));
    expect(parsed.lines.single.category, 'Fuel');
    expect(parsed.diagnostics.parserRequiredFieldStatusCount('date_ready'), 1);
  });

  test(
    'parses damaged OCR receipt time without transaction false positives',
    () {
      final parsed = parseExpenseReceiptText('''
River Road Mart 418
O7.O9.2I 13.I4
TRANS 13:14
AUTH 1314
Shop Towels 5.00
Subtotal 5.00
Tax 0.00
Total 5.00
''');

      expect(parsed.merchantName, 'River Road Mart 418');
      expect(parsed.receiptDate, DateTime(2021, 7, 9));
      expect(parsed.receiptTimeMinutes, (13 * 60) + 14);
      expect(parsed.enteredTotal, 5.00);
      expect(parsed.lines, hasLength(1));
      expect(parsed.lines.single.description.toLowerCase(), contains('towels'));
      expect(
        parsed.lines.map((line) => line.description.toLowerCase()),
        isNot(contains('trans')),
      );
      expect(
        parsed.lines.map((line) => line.description.toLowerCase()),
        isNot(contains('auth')),
      );
    },
  );
}
