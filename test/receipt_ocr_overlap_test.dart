import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_service.dart';

void main() {
  test(
    'ocr preserves one exact boundary line because purchase count is ambiguous',
    () async {
      final result = await const ReceiptOcrService()
          .recognizeTextFromAttachments([
            _textAttachment(
              id: 'section-top',
              text: 'LOWES\nPVC COUPLING 2.49\nPVC GLUE 7.99',
            ),
            _textAttachment(
              id: 'section-bottom',
              text: 'PVC GLUE 7.99\nPIPE STRAP 3.49\nTOTAL 13.97',
            ),
          ]);

      expect(result.rawText, contains('LOWES'));
      expect(result.rawText, contains('PIPE STRAP 3.49'));
      expect('PVC GLUE 7.99'.allMatches(result.rawText), hasLength(2));
      expect('PVC GLUE 7.99'.allMatches(result.appFillText), hasLength(2));
      expect(
        result.warnings.single,
        contains('possible overlapping receipt line'),
      );
      expect(
        result.structuredWarnings.single.kind,
        ReceiptOcrWarningKind.probableOverlap,
      );
      expect(result.structuredWarnings.single.needsReview, isTrue);
      expect(result.diagnostics.reviewWarningCount, 1);
      expect(
        result.diagnostics.countForWarningKind(
          ReceiptOcrWarningKind.duplicateText,
        ),
        0,
      );
      expect(result.warnings.single, contains('Nothing was changed'));
      expect(result.diagnostics.severity, ReceiptOcrReviewSeverity.review);
      expect(result.diagnostics.hadDuplicateOrOverlapText, isTrue);
      expect(result.diagnostics.rawLineCount, 6);
      expect(result.diagnostics.parserLineCount, 6);
      expect(
        result.appFillText.indexOf('PVC COUPLING 2.49'),
        lessThan(result.appFillText.indexOf('PIPE STRAP 3.49')),
      );
    },
  );

  test('ocr warns about probable overlap without changing text', () async {
    final result = await const ReceiptOcrService()
        .recognizeTextFromAttachments([
          _textAttachment(
            id: 'section-top',
            text: 'LOWES\nPVC GLUE 7.99\nPVC PIPE 12.49',
          ),
          _textAttachment(
            id: 'section-bottom',
            text: 'PVC GLUE 8.99\nPIPE STRAP 3.49\nTOTAL 24.97',
          ),
        ]);

    expect('PVC GLUE'.allMatches(result.rawText), hasLength(2));
    expect('PVC GLUE'.allMatches(result.appFillText), hasLength(2));
    expect(
      result.warnings.single,
      contains('possible overlapping receipt line'),
    );
    expect(
      result.structuredWarnings.single.kind,
      ReceiptOcrWarningKind.probableOverlap,
    );
    expect(result.structuredWarnings.single.needsReview, isTrue);
    expect(result.diagnostics.reviewWarningCount, 1);
    expect(result.warnings.single, contains('Nothing was changed'));
    expect(result.diagnostics.severity, ReceiptOcrReviewSeverity.review);
    expect(result.diagnostics.hadDuplicateOrOverlapText, isTrue);
    expect(result.diagnostics.rawLineCount, result.diagnostics.parserLineCount);
  });

  test('ocr preserves one normalized boundary match for review', () async {
    final result = await const ReceiptOcrService()
        .recognizeTextFromAttachments([
          _textAttachment(
            id: 'section-top',
            text: 'LOWES\nPVC GLUE 7.99\nPVC PIPE 12.49',
          ),
          _textAttachment(
            id: 'section-bottom',
            text: 'PVC GLUE 799T\nPIPE STRAP 3 49\nTOTAL 23.97',
          ),
        ]);

    expect('PVC GLUE'.allMatches(result.rawText), hasLength(2));
    expect('PVC GLUE'.allMatches(result.appFillText), hasLength(2));
    expect(result.appFillText, contains('PIPE STRAP 3 49'));
    expect(
      result.structuredWarnings.map((warning) => warning.kind),
      contains(ReceiptOcrWarningKind.probableOverlap),
    );
    expect(result.diagnostics.parserLineCount, result.diagnostics.rawLineCount);
  });

  test(
    'ocr keeps legitimate duplicate items inside the same receipt section',
    () async {
      final result = await const ReceiptOcrService()
          .recognizeTextFromAttachments([
            _textAttachment(
              id: 'single-section',
              text: '''
LOWES
2X4X8 KD STUD 4.29
2X4X8 KD STUD 4.29
SUBTOTAL 8.58
TAX 0.60
TOTAL 9.18
''',
            ),
          ]);

      expect('2X4X8 KD STUD 4.29'.allMatches(result.rawText), hasLength(2));
      expect('2X4X8 KD STUD 4.29'.allMatches(result.appFillText), hasLength(2));
      expect(
        result.structuredWarnings.map((warning) => warning.kind),
        isNot(contains(ReceiptOcrWarningKind.duplicateText)),
      );
      expect(result.diagnostics.hadDuplicateOrOverlapText, isFalse);
    },
  );

  test(
    'ocr preserves indistinguishable repeated purchases across a section edge',
    () async {
      final result = await const ReceiptOcrService()
          .recognizeTextFromAttachments([
            _textAttachment(
              id: 'top',
              text: '''
LOWES
1/2 IN COPPER 90 ELBOW 1.49
1/2 IN COPPER 90 ELBOW 1.49
''',
            ),
            _textAttachment(
              id: 'bottom',
              text: '''
1/2 IN COPPER 90 ELBOW 1.49
1/2 IN COPPER 90 ELBOW 1.49
TOTAL 5.96
''',
            ),
          ]);

      expect(
        '1/2 IN COPPER 90 ELBOW 1.49'.allMatches(result.appFillText),
        hasLength(4),
      );
      expect(
        result.structuredWarnings.map((warning) => warning.kind),
        contains(ReceiptOcrWarningKind.probableOverlap),
      );
      expect(
        result.structuredWarnings.map((warning) => warning.kind),
        isNot(contains(ReceiptOcrWarningKind.duplicateText)),
      );
    },
  );

  test(
    'repeated purchases cross OCR handoff and reconcile without line loss',
    () async {
      final ocr = await const ReceiptOcrService().recognizeTextFromAttachments([
        _textAttachment(
          id: 'top',
          text: '''
LOWES
1/2 IN COPPER 90 ELBOW 1.49
1/2 IN COPPER 90 ELBOW 1.49
''',
        ),
        _textAttachment(
          id: 'bottom',
          text: '''
1/2 IN COPPER 90 ELBOW 1.49
1/2 IN COPPER 90 ELBOW 1.49
TOTAL 5.96
''',
        ),
      ]);

      final parsed = parseExpenseReceiptOcrResult(ocr);

      expect(parsed.lines, hasLength(4));
      expect(parsed.diagnostics.lineSubtotal, 5.96);
      expect(parsed.diagnostics.expectedSubtotalOrTotal, 5.96);
      expect(parsed.diagnostics.reconciled, isTrue);
      expect(parsed.diagnostics.hasParserDuplicateOverlapReview, isTrue);
    },
  );

  test(
    'ambiguous repeated purchases stay visible when receipt math disagrees',
    () async {
      final ocr = await const ReceiptOcrService().recognizeTextFromAttachments([
        _textAttachment(
          id: 'top',
          text: '''
LOWES
1/2 IN COPPER 90 ELBOW 1.49
1/2 IN COPPER 90 ELBOW 1.49
''',
        ),
        _textAttachment(
          id: 'bottom',
          text: '''
1/2 IN COPPER 90 ELBOW 1.49
1/2 IN COPPER 90 ELBOW 1.49
TOTAL 7.45
''',
        ),
      ]);

      final parsed = parseExpenseReceiptOcrResult(ocr);

      expect(parsed.lines, hasLength(4));
      expect(parsed.diagnostics.lineSubtotal, 5.96);
      expect(parsed.diagnostics.expectedSubtotalOrTotal, 7.45);
      expect(parsed.diagnostics.reconciled, isFalse);
      expect(
        parsed.warnings.join(' '),
        contains('do not match the receipt total'),
      );
    },
  );

  test(
    'ocr suppresses a distinct ordered multi-line section overlap',
    () async {
      final result = await const ReceiptOcrService()
          .recognizeTextFromAttachments([
            _textAttachment(
              id: 'top',
              text: '''
LOWES
PVC GLUE 7.99
PVC PIPE 12.49
''',
            ),
            _textAttachment(
              id: 'bottom',
              text: '''
PVC GLUE 7.99
PVC PIPE 12.49
PIPE STRAP 3.49
TOTAL 23.97
''',
            ),
          ]);

      expect('PVC GLUE 7.99'.allMatches(result.appFillText), hasLength(1));
      expect('PVC PIPE 12.49'.allMatches(result.appFillText), hasLength(1));
      expect(
        result.diagnostics.rawLineCount - result.diagnostics.parserLineCount,
        2,
      );
    },
  );

  test(
    'ocr keeps repeated item later in a section when it is not section overlap',
    () async {
      final result = await const ReceiptOcrService()
          .recognizeTextFromAttachments([
            _textAttachment(
              id: 'top',
              text: '''
WALMART
SHOP TOWELS 8.97
AA BATTERIES 16.99
''',
            ),
            _textAttachment(
              id: 'bottom',
              text: '''
TRASH BAGS 18.49
NITRILE GLOVES 14.99
AA BATTERIES 16.99
TOTAL 59.46
''',
            ),
          ]);

      expect('AA BATTERIES 16.99'.allMatches(result.rawText), hasLength(2));
      expect('AA BATTERIES 16.99'.allMatches(result.appFillText), hasLength(2));
      expect(
        result.structuredWarnings.map((warning) => warning.kind),
        isNot(contains(ReceiptOcrWarningKind.duplicateText)),
      );
      expect(
        result.structuredWarnings.map((warning) => warning.kind),
        contains(ReceiptOcrWarningKind.sectionGap),
      );
    },
  );

  test(
    'ocr warns when neighboring long receipt sections have no overlap',
    () async {
      final result = await const ReceiptOcrService()
          .recognizeTextFromAttachments([
            _textAttachment(
              id: 'top',
              text: '''
LOWES
PVC GLUE 7.99
PVC PIPE 12.49
''',
            ),
            _textAttachment(
              id: 'bottom',
              text: '''
PIPE STRAP 3.49
NITRILE GLOVES 14.99
TOTAL 38.96
''',
            ),
          ]);

      expect(result.appFillText, contains('PVC GLUE 7.99'));
      expect(result.appFillText, contains('PIPE STRAP 3.49'));
      expect(result.warnings.join(' '), contains('no repeated receipt text'));
      expect(
        result.structuredWarnings.map((warning) => warning.kind),
        contains(ReceiptOcrWarningKind.sectionGap),
      );
      expect(
        result.diagnostics.countForWarningKind(
          ReceiptOcrWarningKind.sectionGap,
        ),
        1,
      );
      expect(result.diagnostics.severity, ReceiptOcrReviewSeverity.review);
      expect(result.diagnostics.hadDuplicateOrOverlapText, isTrue);
    },
  );

  test('ocr keeps same description with different price for review', () async {
    final result = await const ReceiptOcrService()
        .recognizeTextFromAttachments([
          _textAttachment(id: 'section-top', text: 'LOWES\nPVC GLUE 7.99'),
          _textAttachment(
            id: 'section-bottom',
            text: 'PVC GLUE 8 99\nTOTAL 16.98',
          ),
        ]);

    expect('PVC GLUE'.allMatches(result.appFillText), hasLength(2));
    expect(
      result.structuredWarnings.map((warning) => warning.kind),
      contains(ReceiptOcrWarningKind.probableOverlap),
    );
    expect(result.diagnostics.rawLineCount, result.diagnostics.parserLineCount);
  });

  test(
    'ocr handles long receipt sections with repeated overlap lines',
    () async {
      final result = await const ReceiptOcrService()
          .recognizeTextFromAttachments([
            _textAttachment(
              id: 'section-1',
              text: '''
WALMART
06/20/2026
SHOP TOWELS 8.97
CASE WATER 5.99
AA BATTERIES 16.99
''',
            ),
            _textAttachment(
              id: 'section-2',
              text: '''
AA BATTERIES 16.99
TRASH BAGS 18.49
NITRILE GLOVES 14.99
PHONE CHARGER 12.88
''',
            ),
            _textAttachment(
              id: 'section-3',
              text: '''
PHONE CHARGER 12.88
HOT DOG COMBO 1.50
TOTAL 79.81
''',
            ),
          ]);

      expect(result.rawText, contains('WALMART'));
      expect('AA BATTERIES 16.99'.allMatches(result.rawText), hasLength(2));
      expect('PHONE CHARGER 12.88'.allMatches(result.rawText), hasLength(2));
      expect('AA BATTERIES 16.99'.allMatches(result.appFillText), hasLength(2));
      expect(
        'PHONE CHARGER 12.88'.allMatches(result.appFillText),
        hasLength(2),
      );
      expect(result.appFillText, contains('HOT DOG COMBO 1.50'));
      expect(result.diagnostics.hadDuplicateOrOverlapText, isTrue);
      expect(result.diagnostics.rawLineCount, 12);
      expect(result.diagnostics.parserLineCount, 12);
      expect(
        result.structuredWarnings.map((warning) => warning.kind),
        contains(ReceiptOcrWarningKind.probableOverlap),
      );
    },
  );
}

ReceiptAttachmentRecord _textAttachment({
  required String id,
  required String text,
}) {
  return ReceiptAttachmentRecord(
    id: id,
    path: '',
    kind: ReceiptAttachmentKind.emailText,
    dataSaverLevel: ReceiptDataSaverLevel.balanced,
    createdAt: DateTime(2026, 6, 12),
    importedText: text,
  );
}
