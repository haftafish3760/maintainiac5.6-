import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_service.dart';

void main() {
  test(
    'ocr keeps raw exact overlap text but suppresses it for app fill',
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
      expect('PVC GLUE 7.99'.allMatches(result.appFillText), hasLength(1));
      expect(
        result.warnings.single,
        contains('Ignored 1 repeated receipt line for app-assisted fill'),
      );
      expect(
        result.structuredWarnings.single.kind,
        ReceiptOcrWarningKind.duplicateText,
      );
      expect(result.structuredWarnings.single.needsReview, isTrue);
      expect(result.diagnostics.reviewWarningCount, 1);
      expect(
        result.diagnostics.countForWarningKind(
          ReceiptOcrWarningKind.duplicateText,
        ),
        1,
      );
      expect(
        result.warnings.single,
        contains('Original receipt text was kept'),
      );
      expect(result.diagnostics.severity, ReceiptOcrReviewSeverity.review);
      expect(result.diagnostics.hadDuplicateOrOverlapText, isTrue);
      expect(result.diagnostics.rawLineCount, 6);
      expect(result.diagnostics.parserLineCount, 5);
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

  test('ocr suppresses overlap when price formatting changes', () async {
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
    expect('PVC GLUE'.allMatches(result.appFillText), hasLength(1));
    expect(result.appFillText, contains('PIPE STRAP 3 49'));
    expect(
      result.structuredWarnings.map((warning) => warning.kind),
      contains(ReceiptOcrWarningKind.duplicateText),
    );
    expect(
      result.diagnostics.parserLineCount,
      result.diagnostics.rawLineCount - 1,
    );
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
      expect('AA BATTERIES 16.99'.allMatches(result.appFillText), hasLength(1));
      expect(
        'PHONE CHARGER 12.88'.allMatches(result.appFillText),
        hasLength(1),
      );
      expect(result.appFillText, contains('HOT DOG COMBO 1.50'));
      expect(result.diagnostics.hadDuplicateOrOverlapText, isTrue);
      expect(result.diagnostics.rawLineCount, 12);
      expect(result.diagnostics.parserLineCount, 10);
      expect(
        result.structuredWarnings.map((warning) => warning.kind),
        contains(ReceiptOcrWarningKind.duplicateText),
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
