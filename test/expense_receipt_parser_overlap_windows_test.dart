import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';
import 'package:maintaniac/shared/receipts/receipt_processing_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

void main() {
  test('anchors one-line-gap OCR overlap review to source sections', () {
    const ocr = ReceiptOcrResult(
      rawText: '''
LOWE'S HOME IMPROVEMENT
06/20/2026
PVC GLUE 7.99
SMUDGED BARCODE TEXT 0.01
PVC CLUE 7.99
PAINTERS TAPE 5.99
SUBTOTAL 21.98
TAX 1.54
TOTAL 23.52
''',
      parserText: '''
LOWE'S HOME IMPROVEMENT
06/20/2026
PVC GLUE 7.99
SMUDGED BARCODE TEXT 0.01
PVC CLUE 7.99
PAINTERS TAPE 5.99
SUBTOTAL 21.98
TAX 1.54
TOTAL 23.52
''',
      textByAttachmentId: {'photo-1': 'LOWES'},
      source: ReceiptProcessingSource.photo,
      parserLineSourceLocations: [
        ReceiptOcrParserLineLocation(sectionNumber: 1, sectionLineNumber: 1),
        ReceiptOcrParserLineLocation(sectionNumber: 1, sectionLineNumber: 2),
        ReceiptOcrParserLineLocation(sectionNumber: 1, sectionLineNumber: 3),
        ReceiptOcrParserLineLocation(sectionNumber: 2, sectionLineNumber: 1),
        ReceiptOcrParserLineLocation(sectionNumber: 2, sectionLineNumber: 2),
        ReceiptOcrParserLineLocation(sectionNumber: 2, sectionLineNumber: 3),
        ReceiptOcrParserLineLocation(sectionNumber: 2, sectionLineNumber: 4),
        ReceiptOcrParserLineLocation(sectionNumber: 2, sectionLineNumber: 5),
        ReceiptOcrParserLineLocation(sectionNumber: 2, sectionLineNumber: 6),
      ],
    );

    final parsed = parseExpenseReceiptOcrResult(
      ocr,
      capability: const ReceiptDeviceCapability.highCapacity(),
      parserDepth: ReceiptParserDepth.lineItems,
    );

    expect(parsed.lines, hasLength(4));
    expect(
      parsed.diagnostics.parserTaskCount('long_receipt_near_duplicate_text'),
      1,
    );
    expect(
      parsed.diagnostics.parserTaskCount('long_receipt_probable_overlap'),
      1,
    );
    expect(parsed.diagnostics.parserDuplicateOverlapSourceLabels, [
      'Source line 3 -> Section 2 line 2',
    ]);
    expect(parsed.diagnostics.parserDuplicateOverlapWindowLabels, [
      'one-line gap overlap',
    ]);
    expect(parsed.diagnostics.parserDuplicateOverlapConfidenceLabels, [
      'review OCR overlap',
    ]);
    expect(
      parsed.diagnostics.parserDuplicateOverlapReviewInstruction,
      'Compare Source line 3 -> Section 2 line 2 (one-line gap overlap) before saving so repeated receipt overlap is not counted twice.',
    );
  });

  test('anchors exact one-line-gap OCR overlap as high-confidence evidence', () {
    const ocr = ReceiptOcrResult(
      rawText: '''
LOWE'S HOME IMPROVEMENT
06/20/2026
PVC GLUE 7.99
SMUDGED BARCODE TEXT 0.01
PVC GLUE 7.99
PAINTERS TAPE 5.99
SUBTOTAL 21.98
TAX 1.54
TOTAL 23.52
''',
      parserText: '''
LOWE'S HOME IMPROVEMENT
06/20/2026
PVC GLUE 7.99
SMUDGED BARCODE TEXT 0.01
PVC GLUE 7.99
PAINTERS TAPE 5.99
SUBTOTAL 21.98
TAX 1.54
TOTAL 23.52
''',
      textByAttachmentId: {'photo-1': 'LOWES'},
      source: ReceiptProcessingSource.photo,
      parserLineSourceLocations: [
        ReceiptOcrParserLineLocation(sectionNumber: 1, sectionLineNumber: 1),
        ReceiptOcrParserLineLocation(sectionNumber: 1, sectionLineNumber: 2),
        ReceiptOcrParserLineLocation(sectionNumber: 1, sectionLineNumber: 3),
        ReceiptOcrParserLineLocation(sectionNumber: 2, sectionLineNumber: 1),
        ReceiptOcrParserLineLocation(sectionNumber: 2, sectionLineNumber: 2),
        ReceiptOcrParserLineLocation(sectionNumber: 2, sectionLineNumber: 3),
        ReceiptOcrParserLineLocation(sectionNumber: 2, sectionLineNumber: 4),
        ReceiptOcrParserLineLocation(sectionNumber: 2, sectionLineNumber: 5),
        ReceiptOcrParserLineLocation(sectionNumber: 2, sectionLineNumber: 6),
      ],
    );

    final parsed = parseExpenseReceiptOcrResult(
      ocr,
      capability: const ReceiptDeviceCapability.highCapacity(),
      parserDepth: ReceiptParserDepth.lineItems,
    );

    expect(parsed.lines, hasLength(4));
    expect(
      parsed.diagnostics.parserTaskCount('long_receipt_duplicate_text'),
      1,
    );
    expect(
      parsed.diagnostics.parserTaskCount('long_receipt_near_duplicate_text'),
      0,
    );
    expect(
      parsed.warnings,
      contains(
        'Possible repeated receipt line found. Compare the repeated line around the OCR noise before saving.',
      ),
    );
    expect(parsed.diagnostics.parserDuplicateOverlapAnchorCount, 1);
    expect(parsed.diagnostics.parserDuplicateOverlapSourceLabels, [
      'Source line 3 -> Section 2 line 2',
    ]);
    expect(parsed.diagnostics.parserDuplicateOverlapWindowLabels, [
      'one-line gap overlap',
    ]);
    expect(parsed.diagnostics.parserDuplicateOverlapConfidenceLabels, [
      'high-confidence one-line overlap',
    ]);
    expect(
      parsed.diagnostics.parserDuplicateOverlapEvidenceSummaryLabel,
      '1 overlap anchor | high-confidence one-line overlap | one-line gap overlap',
    );
  });

  test('bounds OCR overlap source summaries across many sections', () {
    const ocr = ReceiptOcrResult(
      rawText: '''
LOWE'S HOME IMPROVEMENT
06/20/2026
PVC GLUE 7.99
PVC GLUE 7.99
PAINTERS TAPE 5.99
PAINTERS TAPE 5.99
PIPE STRAP 2.49
PIPE STRAP 2.49
SUBTOTAL 32.94
TAX 2.31
TOTAL 35.25
''',
      parserText: '''
LOWE'S HOME IMPROVEMENT
06/20/2026
PVC GLUE 7.99
PVC GLUE 7.99
PAINTERS TAPE 5.99
PAINTERS TAPE 5.99
PIPE STRAP 2.49
PIPE STRAP 2.49
SUBTOTAL 32.94
TAX 2.31
TOTAL 35.25
''',
      textByAttachmentId: {'photo-1': 'LOWES'},
      source: ReceiptProcessingSource.photo,
      parserLineSourceLocations: [
        ReceiptOcrParserLineLocation(sectionNumber: 1, sectionLineNumber: 1),
        ReceiptOcrParserLineLocation(sectionNumber: 1, sectionLineNumber: 2),
        ReceiptOcrParserLineLocation(sectionNumber: 1, sectionLineNumber: 3),
        ReceiptOcrParserLineLocation(sectionNumber: 2, sectionLineNumber: 1),
        ReceiptOcrParserLineLocation(sectionNumber: 2, sectionLineNumber: 2),
        ReceiptOcrParserLineLocation(sectionNumber: 3, sectionLineNumber: 1),
        ReceiptOcrParserLineLocation(sectionNumber: 3, sectionLineNumber: 2),
        ReceiptOcrParserLineLocation(sectionNumber: 4, sectionLineNumber: 1),
        ReceiptOcrParserLineLocation(sectionNumber: 4, sectionLineNumber: 2),
        ReceiptOcrParserLineLocation(sectionNumber: 4, sectionLineNumber: 3),
        ReceiptOcrParserLineLocation(sectionNumber: 4, sectionLineNumber: 4),
      ],
    );

    final parsed = parseExpenseReceiptOcrResult(
      ocr,
      capability: const ReceiptDeviceCapability.highCapacity(),
      parserDepth: ReceiptParserDepth.lineItems,
    );

    expect(parsed.lines, hasLength(6));
    expect(
      parsed.diagnostics.parserTaskCount('long_receipt_duplicate_text'),
      3,
    );
    expect(parsed.diagnostics.parserDuplicateOverlapAnchorCount, 3);
    expect(parsed.diagnostics.parserDuplicateOverlapSourceLabels, [
      'Source line 3 -> Section 2 line 1',
      'Section 2 line 2 -> Section 3 line 1',
      'Section 3 line 2 -> Section 4 line 1',
    ]);
    expect(
      parsed.diagnostics.parserDuplicateOverlapSourceSummaryLabel,
      'Source line 3 -> Section 2 line 1, Section 2 line 2 -> Section 3 line 1, +1 more',
    );
    expect(
      parsed.diagnostics.parserDuplicateOverlapReviewInstruction,
      'Compare Source line 3 -> Section 2 line 1, Section 2 line 2 -> Section 3 line 1, +1 more (adjacent overlap) before saving so repeated receipt overlap is not counted twice.',
    );
    expect(
      parsed.diagnostics.parserDuplicateOverlapEvidenceSummaryLabel,
      '3 overlap anchors | high-confidence overlap | adjacent overlap',
    );
  });
}
