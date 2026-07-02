import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';
import 'package:maintaniac/shared/receipts/receipt_processing_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

void main() {
  test('OCR parser entry point respects older-phone local parser scope', () {
    const ocr = ReceiptOcrResult(
      rawText: '''
LOWE'S HOME IMPROVEMENT
06/12/2026
25PK #8 X 1-1/4 WOOD SCREWS 6.98
SUBTOTAL 6.98
TAX 0.49
TOTAL 7.47
''',
      parserText: '''
LOWE'S HOME IMPROVEMENT
06/12/2026
25PK #8 X 1-1/4 WOOD SCREWS 6.98
SUBTOTAL 6.98
TAX 0.49
TOTAL 7.47
''',
      textByAttachmentId: {'receipt-photo-1': 'LOWES'},
      source: ReceiptProcessingSource.photo,
    );

    final parsed = parseExpenseReceiptOcrResult(
      ocr,
      capability: const ReceiptDeviceCapability.olderPhone(),
    );

    expect(parsed.merchantName, "Lowe's");
    expect(parsed.receiptDate, DateTime(2026, 6, 12));
    expect(parsed.enteredSubtotal, 6.98);
    expect(parsed.enteredTax, .49);
    expect(parsed.enteredTotal, 7.47);
    expect(parsed.lines, isEmpty);
    expect(parsed.diagnostics.parserDepth, ReceiptParserDepth.proofTotalsOnly);
    expect(parsed.diagnostics.ocrItemCandidateLineCount, 1);
    expect(parsed.diagnostics.ocrTotalCandidateLineCount, 1);
    expect(
      parsed.diagnostics.ocrLeanLocalReadinessStatus,
      'proof_totals_ready_lines_deferred',
    );
    expect(parsed.diagnostics.hasOcrLeanLocalTotalsReady, isTrue);
    expect(parsed.diagnostics.hasOcrLeanLocalLineReview, isTrue);
    expect(
      parsed.diagnostics.ocrLeanLocalReadinessCount('parser_ready_item_lines'),
      1,
    );
    expect(
      parsed.diagnostics.ocrLeanLocalReadinessCount(
        'parser_ready_lines_deferred_by_device',
      ),
      1,
    );
    expect(
      parsed.diagnostics.ocrLeanLocalReadinessLabel,
      contains('totals-only receipt help'),
    );
    expect(
      ocr.parserHandoff.privacySafeParserHandoffContract,
      containsPair('leanLocalOcrReadinessStatus', 'line_items_ready'),
    );
    expect(parsed.warnings, contains(contains('header and totals only')));
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
    expect(parsed.diagnostics.hasParserCategoryPackLimits, isFalse);
    expect(
      parsed.diagnostics.parserCategoryHealthCount(
        'category_materials_pack_limited',
      ),
      0,
    );
    expect(
      parsed.diagnostics.parserCategoryFamilyConfidenceCount(
        'materials',
        'strong',
      ),
      1,
    );
    expect(parsed.diagnostics.parserCategoryReviewActionCode, 'ready');
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
}
