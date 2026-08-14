import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';

void main() {
  test('routes item-only receipt text to missing lower section review', () {
    final parsed = parseExpenseReceiptText('''
LOWE'S HOME IMPROVEMENT
06/20/2026
PVC GLUE 7.99
PAINTERS TAPE 5.99
''');

    expect(parsed.merchantName, "Lowe's");
    expect(parsed.lines, hasLength(2));
    expect(parsed.enteredSubtotal, isNull);
    expect(parsed.enteredTotal, 13.98);
    expect(parsed.totalCalculatedFromVisibleLines, isTrue);
    expect(parsed.diagnostics.hasExplicitTotal, isFalse);
    expect(
      parsed.warnings,
      contains(
        'The printed total was not found. A working total was calculated from the visible items. If the receipt continues, add the lower section before saving.',
      ),
    );
    expect(
      parsed.diagnostics.parserTaskCount(
        'receipt_missing_totals_manual_review',
      ),
      1,
    );
    expect(
      parsed.diagnostics.parserTaskCount('receipt_totals_text_missing_review'),
      1,
    );
    expect(
      parsed.diagnostics.parserTaskCount(
        'receipt_possible_lower_section_missing',
      ),
      1,
    );
    expect(
      parsed.diagnostics.parserTaskCount(
        'receipt_visible_lines_total_calculated_review',
      ),
      1,
    );
    expect(
      parsed.diagnostics.parserDownstreamReadinessStatus,
      'expense_lines_need_review',
    );
    expect(parsed.diagnostics.hasParserPossibleLowerSectionMissing, isTrue);
    expect(parsed.diagnostics.shouldSuggestLowerReceiptSection, isTrue);
    expect(
      parsed.diagnostics.lowerReceiptSectionReviewLabel,
      'Totals may be lower down',
    );
    expect(
      parsed.diagnostics.lowerReceiptSectionReviewInstruction,
      contains('add the lower section before final review'),
    );
    expect(
      parsed.diagnostics.receiptSequenceReviewStatus,
      'lower_section_may_be_missing',
    );
    expect(
      parsed.diagnostics.receiptSequenceReviewLabel,
      'Check lower receipt section',
    );
    expect(
      parsed.diagnostics.missingBottomTotalsEvidenceCode,
      'local_text_items_without_summary_totals',
    );
    expect(
      parsed.diagnostics.missingBottomTotalsLocalEvidenceReviewLabel,
      contains('priced lines but no subtotal or total'),
    );
    expect(parsed.diagnostics.missingBottomTotalsEvidenceFamilyCount, 1);
    expect(
      parsed.diagnostics.parserDownstreamReadinessCount(
        'receipt_missing_totals_manual_review',
      ),
      1,
    );
    expect(parsed.diagnostics.hasParserRequiredFieldMissing, isTrue);
    expect(parsed.quality.needsReview, isTrue);
    expect(
      parsed.fieldConfidences['receiptMath']?.reason,
      contains('incomplete'),
    );
  });

  test('routes footer-seen receipt without totals to OCR total review', () {
    final parsed = parseExpenseReceiptText('''
COUNTY LINE MARKET
06/20/2026
SHOP TOWELS 8.97
CASE WATER 5.99
UPC 012345678905
THANK YOU FOR SHOPPING
VISIT COUNTYLINE.EXAMPLE
''');

    expect(parsed.lines, hasLength(2));
    expect(parsed.enteredSubtotal, isNull);
    expect(parsed.enteredTotal, 14.96);
    expect(parsed.totalCalculatedFromVisibleLines, isTrue);
    expect(
      parsed.warnings,
      contains(
        'The printed total was not found. A working total was calculated from the visible items; check it before saving.',
      ),
    );
    expect(
      parsed.warnings,
      isNot(
        contains(
          'The printed total was not found. A working total was calculated from the visible items. If the receipt continues, add the lower section before saving.',
        ),
      ),
    );
    expect(
      parsed.diagnostics.parserTaskCount(
        'receipt_footer_seen_totals_missing_review',
      ),
      1,
    );
    expect(
      parsed.diagnostics.parserTaskCount(
        'receipt_possible_lower_section_missing',
      ),
      0,
    );
    expect(parsed.diagnostics.hasParserPossibleLowerSectionMissing, isFalse);
    expect(parsed.diagnostics.shouldSuggestLowerReceiptSection, isFalse);
    expect(
      parsed.diagnostics.missingBottomTotalsEvidenceCode,
      'local_text_footer_seen_totals_missing',
    );
    expect(
      parsed.diagnostics.missingBottomTotalsLocalEvidenceReviewLabel,
      contains('receipt footer evidence'),
    );
  });

  test('marks footer and summary totals as bottom-complete evidence', () {
    final parsed = parseExpenseReceiptText('''
COUNTY LINE MARKET
06/20/2026
SHOP TOWELS 8.97
CASE WATER 5.99
SUBTOTAL 14.96
TAX 1.05
TOTAL 16.01
UPC 012345678905
THANK YOU FOR SHOPPING
VISIT COUNTYLINE.EXAMPLE
''');

    expect(parsed.lines, hasLength(2));
    expect(parsed.enteredSubtotal, 14.96);
    expect(parsed.enteredTax, 1.05);
    expect(parsed.enteredTotal, 16.01);
    expect(parsed.diagnostics.shouldSuggestLowerReceiptSection, isFalse);
    expect(parsed.diagnostics.hasParserPossibleLowerSectionMissing, isFalse);
    expect(
      parsed.diagnostics.parserTaskCount('receipt_summary_totals_ready'),
      1,
    );
    expect(
      parsed.diagnostics.parserTaskCount('receipt_footer_or_barcode_seen'),
      greaterThanOrEqualTo(1),
    );
    expect(
      parsed.diagnostics.parserTaskCount('receipt_bottom_complete_ready'),
      1,
    );
    expect(parsed.diagnostics.missingBottomTotalsEvidenceCode, isEmpty);
  });

  test('marks full summary math as bottom-complete without footer text', () {
    final parsed = parseExpenseReceiptText('''
LOCAL HARDWARE
06/20/2026
PVC COUPLING 4.99
SHOP TOWELS 8.97
SUBTOTAL 13.96
TAX 1.12
TOTAL 15.08
''');

    expect(parsed.lines, hasLength(2));
    expect(parsed.enteredSubtotal, 13.96);
    expect(parsed.enteredTax, 1.12);
    expect(parsed.enteredTotal, 15.08);
    expect(parsed.diagnostics.shouldSuggestLowerReceiptSection, isFalse);
    expect(
      parsed.diagnostics.parserTaskCount('receipt_summary_totals_ready'),
      1,
    );
    expect(
      parsed.diagnostics.parserTaskCount('receipt_footer_or_barcode_seen'),
      0,
    );
    expect(
      parsed.diagnostics.parserTaskCount('receipt_bottom_complete_ready'),
      1,
    );
  });

  test('routes subtotal-only receipt text to final total review', () {
    final parsed = parseExpenseReceiptText('''
LOWE'S HOME IMPROVEMENT
06/20/2026
PVC GLUE 7.99
PAINTERS TAPE 5.99
SUBTOTAL 13.98
TAX 1.12
''');

    expect(parsed.merchantName, "Lowe's");
    expect(parsed.lines, hasLength(2));
    expect(parsed.enteredSubtotal, 13.98);
    expect(parsed.enteredTax, 1.12);
    expect(parsed.enteredTotal, closeTo(15.10, .001));
    expect(parsed.diagnostics.hasExplicitSubtotal, isTrue);
    expect(parsed.diagnostics.hasExplicitTax, isTrue);
    expect(parsed.diagnostics.hasExplicitTotal, isFalse);
    expect(
      parsed.warnings,
      contains(
        'The final printed total was not found. Check the working total, and add the lower section if the receipt continues.',
      ),
    );
    expect(
      parsed.diagnostics.parserTaskCount('receipt_partial_totals_review'),
      1,
    );
    expect(
      parsed.diagnostics.parserTaskCount('receipt_final_total_missing_review'),
      1,
    );
    expect(
      parsed.diagnostics.parserTaskCount(
        'receipt_possible_lower_section_missing',
      ),
      1,
    );
    expect(
      parsed.diagnostics.parserDownstreamReadinessStatus,
      'expense_lines_need_review',
    );
    expect(parsed.diagnostics.hasParserPossibleLowerSectionMissing, isTrue);
    expect(parsed.diagnostics.shouldSuggestLowerReceiptSection, isTrue);
    expect(
      parsed.diagnostics.lowerReceiptSectionReviewLabel,
      'Totals may be lower down',
    );
    expect(
      parsed.diagnostics.missingBottomTotalsEvidenceCode,
      'local_text_summary_without_final_total',
    );
    expect(
      parsed.diagnostics.missingBottomTotalsLocalEvidenceReviewLabel,
      contains('subtotal or tax lines but no final total'),
    );
    expect(parsed.diagnostics.missingBottomTotalsEvidenceFamilyCount, 1);
    expect(
      parsed.diagnostics.parserDownstreamReadinessCount(
        'receipt_final_total_missing_review',
      ),
      1,
    );
  });

  test('keeps repeated visible items when calculating a working total', () {
    final parsed = parseExpenseReceiptText('''
LOCAL HARDWARE
06/20/2026
HALF INCH ELBOW 1.25
HALF INCH ELBOW 1.25
HALF INCH ELBOW 1.25
''');

    expect(parsed.lines, hasLength(3));
    expect(parsed.enteredTotal, 3.75);
    expect(parsed.totalCalculatedFromVisibleLines, isTrue);
    expect(parsed.diagnostics.hasExplicitTotal, isFalse);
    expect(parsed.quality.needsReview, isTrue);
  });
}
