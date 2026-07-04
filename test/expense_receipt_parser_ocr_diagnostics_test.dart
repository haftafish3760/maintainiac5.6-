import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';
import 'package:maintaniac/shared/receipts/receipt_processing_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

void main() {
  test('preserves OCR item review buckets through parser diagnostics', () {
    const ocr = ReceiptOcrResult(
      rawText: '''
WALMART
06/12/2026
GENERAL MDSE 17.48
TOTAL 17.48
''',
      parserText: '''
WALMART
06/12/2026
GENERAL MDSE 17.48
TOTAL 17.48
      ''',
      textByAttachmentId: {'photo-1': 'WALMART'},
      source: ReceiptProcessingSource.photo,
      parserLineSourceLocations: [
        ReceiptOcrParserLineLocation(sectionNumber: 1, sectionLineNumber: 1),
        ReceiptOcrParserLineLocation(sectionNumber: 1, sectionLineNumber: 2),
        ReceiptOcrParserLineLocation(sectionNumber: 2, sectionLineNumber: 1),
        ReceiptOcrParserLineLocation(sectionNumber: 2, sectionLineNumber: 2),
      ],
    );

    final parsed = parseExpenseReceiptOcrResult(
      ocr,
      capability: const ReceiptDeviceCapability.highCapacity(),
    );

    expect(parsed.lines.single.description, 'General Mdse');
    expect(parsed.lines.single.ocrSourceLineId, 'ocr_line_002_item');
    expect(parsed.lines.single.ocrSourceLineNumber, 3);
    expect(parsed.lines.single.ocrSourceSectionNumber, 2);
    expect(parsed.lines.single.ocrSourceSectionLineNumber, 1);
    expect(parsed.lines.single.hasOcrSourceLine, isTrue);
    expect(parsed.lines.single.ocrSourceLineLabel, 'OCR section 2 line 1');
    expect(
      parsed.lines.single.receiptProofLineReferenceLabel,
      'Section 2 line 1',
    );
    expect(
      parsed.lines.single.privacySafeProofReference['ocrSourceSectionNumber'],
      2,
    );
    expect(
      parsed
          .lines
          .single
          .privacySafeProofReference['ocrSourceSectionLineNumber'],
      1,
    );
    expect(parsed.diagnostics.ocrItemCandidateLineCount, 1);
    expect(parsed.diagnostics.ocrPricedLineCount, greaterThanOrEqualTo(1));
    expect(parsed.diagnostics.ocrParserReadyLineCount, 0);
    expect(parsed.diagnostics.ocrParserReviewSignalCount, 1);
    expect(
      parsed.diagnostics.ocrParserReadinessStatus,
      'no_parser_ready_items',
    );
    expect(parsed.diagnostics.ocrSourceSectionCount, 2);
    expect(
      parsed.diagnostics.ocrSourceSectionReviewLabel,
      '2 OCR sections in order',
    );
    expect(
      parsed.diagnostics.ocrSourceSectionReviewInstruction,
      contains('section order looks continuous'),
    );
    expect(parsed.diagnostics.hasOcrParserReadyStatus, isFalse);
    expect(parsed.diagnostics.ocrHighConfidenceItemLineCount, 0);
    expect(parsed.diagnostics.ocrReviewItemLineCount, 1);
    expect(parsed.diagnostics.ocrQuantitySignalItemLineCount, 0);
    expect(parsed.diagnostics.ocrSkuSignalItemLineCount, 0);
    expect(parsed.diagnostics.hasOcrLineRoleSignals, isTrue);
    expect(parsed.diagnostics.ocrLineRoleCount('item'), 1);
    expect(parsed.diagnostics.ocrGenericItemLineCount, 1);
    expect(parsed.diagnostics.ocrParserReadyItemLineIdCount, 0);
    expect(parsed.diagnostics.ocrReviewItemLineIdCount, 1);
    expect(parsed.diagnostics.hasOcrReadyItemLineIds, isFalse);
    expect(parsed.diagnostics.hasOcrReviewItemLineIds, isTrue);
    expect(parsed.diagnostics.ocrLineIdsForRole('item'), ['ocr_line_002_item']);
    expect(parsed.diagnostics.ocrParserBucketCount('item_needs_review'), 1);
    expect(parsed.diagnostics.ocrSummaryMathStatus, 'incomplete');
    expect(parsed.diagnostics.ocrSummaryMathReconciled, isFalse);
    expect(parsed.diagnostics.ocrLineSequenceStatus, 'expected_order');
    expect(parsed.diagnostics.ocrReceiptStructureStatus, 'line_item_review');
    expect(parsed.diagnostics.hasOcrParserReadyLines, isFalse);
    expect(parsed.diagnostics.hasOcrParserReviewSignals, isTrue);
    expect(parsed.diagnostics.hasOcrItemReviewSignals, isTrue);
    expect(parsed.diagnostics.hasOcrInventoryPrepSignals, isFalse);
    expect(parsed.diagnostics.hasOcrGenericItemSignals, isTrue);
    expect(parsed.diagnostics.hasOcrCompleteSummaryMath, isFalse);
    expect(parsed.diagnostics.hasOcrSummaryMathMismatch, isFalse);
    expect(parsed.diagnostics.hasOcrExpectedLineSequence, isTrue);
    expect(parsed.diagnostics.hasOcrLineSequenceReview, isFalse);
    expect(parsed.diagnostics.hasOcrReceiptStructureReview, isTrue);
  });

  test('normalizes malformed OCR source locations before expense review', () {
    const ocr = ReceiptOcrResult(
      rawText: '''
WALMART
06/12/2026
GENERAL MDSE 17.48
TOTAL 17.48
''',
      parserText: '''
WALMART
06/12/2026
GENERAL MDSE 17.48
TOTAL 17.48
      ''',
      textByAttachmentId: {'photo-1': 'WALMART'},
      source: ReceiptProcessingSource.photo,
      parserLineSourceLocations: [
        ReceiptOcrParserLineLocation(sectionNumber: 1, sectionLineNumber: 1),
        ReceiptOcrParserLineLocation(sectionNumber: 1, sectionLineNumber: 2),
        ReceiptOcrParserLineLocation(sectionNumber: -4, sectionLineNumber: 0),
        ReceiptOcrParserLineLocation(sectionNumber: 1, sectionLineNumber: 4),
      ],
    );

    final parsed = parseExpenseReceiptOcrResult(
      ocr,
      capability: const ReceiptDeviceCapability.highCapacity(),
    );
    final line = parsed.lines.single;

    expect(line.ocrSourceLineId, 'ocr_line_002_item');
    expect(line.ocrSourceLineNumber, 3);
    expect(line.ocrSourceSectionNumber, 1);
    expect(line.ocrSourceSectionLineNumber, 1);
    expect(line.receiptLineNumberLabel, 'Line 1');
    expect(line.privacySafeProofReference['ocrSourceSectionNumber'], 1);
    expect(line.privacySafeProofReference['ocrSourceSectionLineNumber'], 1);
    expect(line.toMap().toString(), isNot(contains('-4')));
  });

  test('preserves OCR item family mix through parser diagnostics', () {
    const ocr = ReceiptOcrResult(
      rawText: '''
CORNER MARKET 52
06/12/2026
BANANAS 4011 1.29
SHOP TOWELS 5.00
SUBTOTAL 6.29
TAX 0.41
TOTAL 6.70
EBT FOOD 1.29
VISA 5.41
''',
      parserText: '''
CORNER MARKET 52
06/12/2026
BANANAS 4011 1.29
SHOP TOWELS 5.00
SUBTOTAL 6.29
TAX 0.41
TOTAL 6.70
EBT FOOD 1.29
VISA 5.41
''',
      textByAttachmentId: {'photo-1': 'private receipt text omitted'},
      source: ReceiptProcessingSource.photo,
    );

    final parsed = parseExpenseReceiptOcrResult(
      ocr,
      capability: const ReceiptDeviceCapability.highCapacity(),
    );

    expect(parsed.lines, hasLength(2));
    expect(
      parsed.diagnostics.parserItemExpenseFamilyStatus,
      'mixed_item_families',
    );
    expect(
      parsed.diagnostics.parserItemExpenseFamilySummaryLabel,
      'Parser mixed families: food/grocery, vehicle supplies',
    );
    expect(
      parsed.diagnostics.parserItemExpenseFamilyCounts['food_or_grocery'],
      1,
    );
    expect(
      parsed.diagnostics.parserItemExpenseFamilyCounts['vehicle_supplies'],
      1,
    );
    expect(parsed.diagnostics.hasParserMixedItemExpenseFamilies, isTrue);
    expect(parsed.diagnostics.hasAnyMixedItemExpenseFamilies, isTrue);
    expect(
      parsed.diagnostics.parserTaskCount('parser_expense_family_mixed_receipt'),
      2,
    );
    expect(
      parsed.diagnostics.ocrItemExpenseFamilyStatus,
      'mixed_item_families',
    );
    expect(
      parsed.diagnostics.ocrItemExpenseFamilySummaryLabel,
      'Mixed receipt families: food/grocery, vehicle supplies',
    );
    expect(parsed.diagnostics.hasOcrMixedItemExpenseFamilies, isTrue);
    expect(parsed.diagnostics.ocrItemExpenseFamilyCounts['food_or_grocery'], 1);
    expect(
      parsed.diagnostics.ocrItemExpenseFamilyCounts['vehicle_supplies'],
      1,
    );
    expect(
      parsed.diagnostics.ocrParserTaskCount('expense_family_mixed_receipt'),
      2,
    );
    expect(
      parsed.diagnostics.parserTaskSummaryLabel,
      contains('Mixed receipt families: food/grocery, vehicle supplies'),
    );
  });

  test('flags missing long-receipt section gap in parser diagnostics', () {
    final parsed = parseExpenseReceiptOcrResult(
      _sectionedOcrResult(
        locations: const [
          ReceiptOcrParserLineLocation(sectionNumber: 1, sectionLineNumber: 1),
          ReceiptOcrParserLineLocation(sectionNumber: 1, sectionLineNumber: 2),
          ReceiptOcrParserLineLocation(sectionNumber: 3, sectionLineNumber: 1),
          ReceiptOcrParserLineLocation(sectionNumber: 3, sectionLineNumber: 2),
        ],
      ),
      capability: const ReceiptDeviceCapability.highCapacity(),
    );

    expect(
      parsed.diagnostics.ocrSourceSectionContinuityStatus,
      'missing_section_gap',
    );
    expect(parsed.diagnostics.ocrSourceSectionCount, 2);
    expect(parsed.diagnostics.hasOcrSourceSectionReview, isTrue);
    expect(
      parsed.diagnostics.ocrSourceSectionReviewLabel,
      '2 OCR sections with a gap',
    );
    expect(
      parsed.diagnostics.ocrSourceSectionReviewInstruction,
      contains('Add or retake the missing middle or bottom section'),
    );
  });

  test('flags out-of-order long-receipt sections in parser diagnostics', () {
    final parsed = parseExpenseReceiptOcrResult(
      _sectionedOcrResult(
        locations: const [
          ReceiptOcrParserLineLocation(sectionNumber: 2, sectionLineNumber: 1),
          ReceiptOcrParserLineLocation(sectionNumber: 2, sectionLineNumber: 2),
          ReceiptOcrParserLineLocation(sectionNumber: 1, sectionLineNumber: 1),
          ReceiptOcrParserLineLocation(sectionNumber: 1, sectionLineNumber: 2),
        ],
      ),
      capability: const ReceiptDeviceCapability.highCapacity(),
    );

    expect(
      parsed.diagnostics.ocrSourceSectionContinuityStatus,
      'out_of_order_sections',
    );
    expect(parsed.diagnostics.ocrSourceSectionCount, 2);
    expect(parsed.diagnostics.hasOcrSourceSectionReview, isTrue);
    expect(
      parsed.diagnostics.ocrSourceSectionReviewLabel,
      '2 OCR sections out of order',
    );
    expect(
      parsed.diagnostics.ocrSourceSectionReviewInstruction,
      contains('Review the receipt photos from top to bottom before saving'),
    );
  });

  test('OCR parser enrichment keeps stable line IDs ahead of line numbers', () {
    const ocr = ReceiptOcrResult(
      rawText: '''
STORE
06/12/2026
PVC PIPE 14.50
TOTAL 14.50
''',
      parserText: '''
STORE
06/12/2026
PVC PIPE 14.50
TOTAL 14.50
''',
      textByAttachmentId: {'photo-1': 'stable line receipt text omitted'},
      source: ReceiptProcessingSource.photo,
      parserLineSourceLocations: [
        ReceiptOcrParserLineLocation(sectionNumber: 1, sectionLineNumber: 1),
        ReceiptOcrParserLineLocation(sectionNumber: 1, sectionLineNumber: 2),
        ReceiptOcrParserLineLocation(sectionNumber: 4, sectionLineNumber: 7),
        ReceiptOcrParserLineLocation(sectionNumber: 4, sectionLineNumber: 8),
      ],
    );

    final parsed = parseExpenseReceiptOcrResult(
      ocr,
      capability: const ReceiptDeviceCapability.highCapacity(),
    );

    expect(parsed.lines, hasLength(1));
    expect(parsed.lines.single.ocrSourceLineId, 'ocr_line_002_item');
    expect(parsed.lines.single.ocrSourceLineNumber, 3);
    expect(parsed.lines.single.ocrSourceSectionNumber, 4);
    expect(parsed.lines.single.ocrSourceSectionLineNumber, 7);
    expect(
      parsed.lines.single.receiptProofLineReferenceLabel,
      'Section 4 line 7',
    );
  });

  test('OCR parser enrichment rejects duplicate line-number overwrite shape', () {
    final source = File(
      'lib/screens/expenses/data/expense_receipt_parser_ocr_handoff_logic.dart',
    ).readAsStringSync();
    final enrichmentStart = source.indexOf(
      'ExpenseReceiptParseResult _withOcrParserLineEvidence',
    );
    final enrichmentEnd = source.indexOf(
      'String? _preferSpecificParserExpenseFamily',
      enrichmentStart,
    );
    final enrichment = source.substring(enrichmentStart, enrichmentEnd);

    expect(enrichment, contains('handoff.lineDraftsById[sourceLineId]'));
    expect(enrichment, contains('mapped.putIfAbsent(draft.safeLineNumber'));
    expect(enrichment, isNot(contains('mapped.putIfAbsent(draft.lineNumber')));
    expect(enrichment, isNot(contains('draft.lineNumber: draft')));
  });
}

ReceiptOcrResult _sectionedOcrResult({
  required List<ReceiptOcrParserLineLocation> locations,
}) {
  return ReceiptOcrResult(
    rawText: _sectionedReceiptText,
    parserText: _sectionedReceiptText,
    textByAttachmentId: const {'photo-1': 'sectioned receipt text omitted'},
    source: ReceiptProcessingSource.photo,
    parserLineSourceLocations: locations,
  );
}

const _sectionedReceiptText = '''
LOWE'S
06/12/2026
PVC PIPE 14.50
TOTAL 14.50
''';
