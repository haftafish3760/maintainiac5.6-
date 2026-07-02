import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';
import 'package:maintaniac/shared/receipts/receipt_processing_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

void main() {
  test('anchors duplicate overlap review to OCR source sections', () {
    const ocr = ReceiptOcrResult(
      rawText: '''
LOWE'S HOME IMPROVEMENT
06/20/2026
PVC GLUE 7.99
PVC GLUE 7.99
PAINTERS TAPE 5.99
SUBTOTAL 21.97
TAX 1.54
TOTAL 23.51
''',
      parserText: '''
LOWE'S HOME IMPROVEMENT
06/20/2026
PVC GLUE 7.99
PVC GLUE 7.99
PAINTERS TAPE 5.99
SUBTOTAL 21.97
TAX 1.54
TOTAL 23.51
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
      ],
    );

    final parsed = parseExpenseReceiptOcrResult(
      ocr,
      capability: const ReceiptDeviceCapability.highCapacity(),
      parserDepth: ReceiptParserDepth.lineItems,
    );

    expect(parsed.lines, hasLength(3));
    expect(parsed.diagnostics.hasParserDuplicateOverlapReview, isTrue);
    expect(parsed.diagnostics.hasParserDuplicateOverlapSourceLabels, isTrue);
    expect(parsed.diagnostics.parserDuplicateOverlapAnchorCount, 1);
    expect(parsed.diagnostics.parserDuplicateOverlapSourceLabels, [
      'Source line 3 -> Section 2 line 1',
    ]);
    expect(parsed.diagnostics.parserDuplicateOverlapConfidenceLabels, [
      'high-confidence overlap',
    ]);
    expect(
      parsed.diagnostics.parserDuplicateOverlapConfidenceSummaryLabel,
      'high-confidence overlap',
    );
    expect(
      parsed.diagnostics.parserDuplicateOverlapReviewLabel,
      'Check repeated overlap near Source line 3 -> Section 2 line 1',
    );
    expect(
      parsed.diagnostics.parserDuplicateOverlapReviewInstruction,
      'Compare Source line 3 -> Section 2 line 1 (adjacent overlap) before saving so repeated receipt overlap is not counted twice.',
    );
  });

  test('anchors near duplicate OCR overlap review to source sections', () {
    const ocr = ReceiptOcrResult(
      rawText: '''
LOWE'S HOME IMPROVEMENT
06/20/2026
PVC GLUE 7.99
PVC CLUE 7.99
PAINTERS TAPE 5.99
SUBTOTAL 21.97
TAX 1.54
TOTAL 23.51
''',
      parserText: '''
LOWE'S HOME IMPROVEMENT
06/20/2026
PVC GLUE 7.99
PVC CLUE 7.99
PAINTERS TAPE 5.99
SUBTOTAL 21.97
TAX 1.54
TOTAL 23.51
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
      ],
    );

    final parsed = parseExpenseReceiptOcrResult(
      ocr,
      capability: const ReceiptDeviceCapability.highCapacity(),
      parserDepth: ReceiptParserDepth.lineItems,
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
    expect(parsed.diagnostics.parserDuplicateOverlapSourceLabels, [
      'Source line 3 -> Section 2 line 1',
    ]);
    expect(parsed.diagnostics.parserDuplicateOverlapConfidenceLabels, [
      'probable OCR overlap',
    ]);
    expect(
      parsed.diagnostics.parserDuplicateOverlapReviewInstruction,
      'Compare Source line 3 -> Section 2 line 1 (adjacent overlap) before saving so repeated receipt overlap is not counted twice.',
    );
  });

  test('anchors mixed exact and fuzzy OCR overlap review to source sections', () {
    const ocr = ReceiptOcrResult(
      rawText: '''
LOWE'S HOME IMPROVEMENT
06/20/2026
PVC GLUE 7.99
PVC GLUE 7.99
PAINTERS TAPE 5.99
PAINTERS TAPF 5.99
SUBTOTAL 27.96
TAX 1.96
TOTAL 29.92
''',
      parserText: '''
LOWE'S HOME IMPROVEMENT
06/20/2026
PVC GLUE 7.99
PVC GLUE 7.99
PAINTERS TAPE 5.99
PAINTERS TAPF 5.99
SUBTOTAL 27.96
TAX 1.96
TOTAL 29.92
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
        ReceiptOcrParserLineLocation(sectionNumber: 3, sectionLineNumber: 3),
        ReceiptOcrParserLineLocation(sectionNumber: 3, sectionLineNumber: 4),
      ],
    );

    final parsed = parseExpenseReceiptOcrResult(
      ocr,
      capability: const ReceiptDeviceCapability.highCapacity(),
      parserDepth: ReceiptParserDepth.lineItems,
    );

    expect(parsed.lines, hasLength(4));
    expect(
      parsed.warnings,
      contains(
        '2 possible repeated receipt lines found. Compare exact and fuzzy OCR overlap before saving.',
      ),
    );
    expect(
      parsed.diagnostics.parserTaskCount('long_receipt_duplicate_text'),
      1,
    );
    expect(
      parsed.diagnostics.parserTaskCount('long_receipt_near_duplicate_text'),
      1,
    );
    expect(parsed.diagnostics.parserDuplicateOverlapSourceLabels, [
      'Source line 3 -> Section 2 line 1',
      'Section 2 line 2 -> Section 3 line 1',
    ]);
    expect(parsed.diagnostics.parserDuplicateOverlapConfidenceLabels, [
      'high-confidence overlap',
      'probable OCR overlap',
    ]);
    expect(
      parsed.diagnostics.parserDuplicateOverlapEvidenceSummaryLabel,
      '2 overlap anchors | high-confidence overlap, probable OCR overlap | adjacent overlap',
    );
  });
}
