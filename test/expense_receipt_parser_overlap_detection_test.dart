import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';

void main() {
  test('warns about adjacent near duplicate lines from OCR overlap noise', () {
    final parsed = parseExpenseReceiptText('''
LOWE'S HOME IMPROVEMENT
06/20/2026
PVC GLUE 7.99
PVC CLUE 7.99
PAINTERS TAPE 5.99
SUBTOTAL 21.97
TAX 1.54
TOTAL 23.51
''');

    expect(parsed.lines, hasLength(3));
    expect(
      parsed.warnings,
      contains(
        'Possible repeated receipt line found. Compare fuzzy OCR overlap before saving.',
      ),
    );
    expect(
      parsed.diagnostics.parserTaskCount('long_receipt_duplicate_text'),
      0,
    );
    expect(
      parsed.diagnostics.parserTaskCount('long_receipt_near_duplicate_text'),
      1,
    );
    expect(
      parsed.diagnostics.parserTaskCount('long_receipt_probable_overlap'),
      1,
    );
    expect(parsed.diagnostics.hasParserDuplicateOverlapReview, isTrue);
    expect(parsed.diagnostics.parserDuplicateOverlapAnchorCount, 1);
    expect(parsed.diagnostics.parserDuplicateOverlapSourceLabels, [
      'Line 3 -> Line 4',
    ]);
    expect(parsed.diagnostics.parserDuplicateOverlapWindowLabels, [
      'adjacent overlap',
    ]);
  });

  test('does not flag short same-price neighboring items as OCR overlap', () {
    final parsed = parseExpenseReceiptText('''
LOCAL HARDWARE
06/20/2026
BOLT 1.99
BELT 1.99
PAINTERS TAPE 5.99
SUBTOTAL 9.97
TAX 0.70
TOTAL 10.67
''');

    expect(parsed.lines, hasLength(3));
    expect(parsed.warnings.join(' '), isNot(contains('repeated receipt')));
    expect(
      parsed.diagnostics.parserTaskCount('long_receipt_duplicate_text'),
      0,
    );
    expect(
      parsed.diagnostics.parserTaskCount('long_receipt_near_duplicate_text'),
      0,
    );
    expect(parsed.diagnostics.hasParserDuplicateOverlapReview, isFalse);
  });

  test('flags repeated overlap lines separated by one OCR noise line', () {
    final parsed = parseExpenseReceiptText('''
LOWE'S HOME IMPROVEMENT
06/20/2026
PVC GLUE 7.99
SMUDGED BARCODE TEXT 0.01
PVC CLUE 7.99
PAINTERS TAPE 5.99
SUBTOTAL 21.98
TAX 1.54
TOTAL 23.52
''');

    expect(parsed.lines, hasLength(4));
    expect(
      parsed.warnings,
      contains(
        'Possible repeated receipt line found. Compare fuzzy OCR overlap around the noise line before saving.',
      ),
    );
    expect(
      parsed.diagnostics.parserTaskCount('long_receipt_near_duplicate_text'),
      1,
    );
    expect(
      parsed.diagnostics.parserTaskCount('long_receipt_probable_overlap'),
      1,
    );
    expect(parsed.diagnostics.parserDuplicateOverlapSourceLabels, [
      'Line 3 -> Line 5',
    ]);
    expect(parsed.diagnostics.parserDuplicateOverlapWindowLabels, [
      'one-line gap overlap',
    ]);
  });

  test('labels exact one-line-gap overlap as high-confidence evidence', () {
    final parsed = parseExpenseReceiptText('''
LOWE'S HOME IMPROVEMENT
06/20/2026
PVC GLUE 7.99
SMUDGED BARCODE TEXT 0.01
PVC GLUE 7.99
PAINTERS TAPE 5.99
SUBTOTAL 21.98
TAX 1.54
TOTAL 23.52
''');

    expect(parsed.diagnostics.parserDuplicateOverlapWindowLabels, [
      'one-line gap overlap',
    ]);
    expect(parsed.diagnostics.parserDuplicateOverlapConfidenceLabels, [
      'high-confidence one-line overlap',
    ]);
  });

  test('does not flag different same-price items across one normal item', () {
    final parsed = parseExpenseReceiptText('''
LOCAL HARDWARE
06/20/2026
BOLT 1.99
PAINTERS TAPE 5.99
BELT 1.99
SUBTOTAL 9.97
TAX 0.70
TOTAL 10.67
''');

    expect(parsed.lines, hasLength(3));
    expect(parsed.diagnostics.hasParserDuplicateOverlapReview, isFalse);
    expect(parsed.diagnostics.parserDuplicateOverlapSourceLabels, isEmpty);
  });

  test('summarizes multiple duplicate overlap anchors compactly', () {
    final parsed = parseExpenseReceiptText('''
LOWE'S HOME IMPROVEMENT
06/20/2026
PVC GLUE 7.99
PVC GLUE 7.99
PAINTERS TAPE 5.99
PAINTERS TAPE 5.99
SUBTOTAL 27.96
TAX 1.96
TOTAL 29.92
''');

    expect(parsed.diagnostics.hasParserDuplicateOverlapReview, isTrue);
    expect(
      parsed.diagnostics.parserDuplicateOverlapAnchorCount,
      greaterThanOrEqualTo(2),
    );
    expect(
      parsed.diagnostics.parserDuplicateOverlapReviewLabel,
      contains('Check repeated overlap'),
    );
  });

  test('summarizes mixed exact and fuzzy overlap anchors honestly', () {
    final parsed = parseExpenseReceiptText('''
LOWE'S HOME IMPROVEMENT
06/20/2026
PVC GLUE 7.99
PVC GLUE 7.99
PAINTERS TAPE 5.99
PAINTERS TAPE 5.98
SUBTOTAL 27.95
TAX 1.96
TOTAL 29.91
''');

    expect(parsed.diagnostics.hasParserDuplicateOverlapReview, isTrue);
    expect(
      parsed.diagnostics.parserDuplicateOverlapConfidenceSummaryLabel,
      contains('high-confidence'),
    );
    expect(
      parsed.diagnostics.parserDuplicateOverlapAnchorCount,
      greaterThanOrEqualTo(1),
    );
  });
}
