import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_service.dart';

void main() {
  test(
    'receipt section handoff matrix protects app fill before parser review',
    () async {
      final cases = [
        _ReceiptSectionHandoffCase(
          name: 'clean ordered long retail sections',
          sections: const [
            '''
WALMART
06/21/2026
GEN MDSE 17.48
CASE WATER 5.99
SHOP TOWELS 8.97
AA BATTERIES 16.99
            ''',
            '''
SHOP TOWELS 8.97
AA BATTERIES 16.99
TRASH BAGS 18.49
NITRILE GLOVES 14.99
PHONE CHARGER 12.88
''',
            '''
NITRILE GLOVES 14.99
PHONE CHARGER 12.88
HOT DOG BUNS 3.48
SUBTOTAL 99.27
TAX 6.95
TOTAL 106.22
''',
          ],
          expectedMerchant: 'Walmart',
          expectedTotal: 106.22,
          expectedParserLineCount: 8,
          expectedOcrSeverity: ReceiptOcrReviewSeverity.review,
          mustContainWarning: 'Ignored 4 repeated receipt lines',
          duplicateLine: 'PHONE CHARGER 12.88',
          expectedRawOccurrences: 2,
          expectedAppFillOccurrences: 1,
          expectParserReconciled: true,
        ),
        _ReceiptSectionHandoffCase(
          name: 'missing middle section remains reviewable',
          sections: const [
            '''
LOWE'S HOME IMPROVEMENT
06/21/2026
2X4X8 KD STUD 4.29
1/2 IN COPPER 90 ELBOW 7.48
''',
            '''
5LB DECK SCREWS 32.49
NITRILE GLOVES 12.99
SUBTOTAL 84.71
TAX 5.93
TOTAL 90.64
''',
          ],
          expectedMerchant: "Lowe's",
          expectedTotal: 90.64,
          expectedParserLineCount: 4,
          expectedOcrSeverity: ReceiptOcrReviewSeverity.review,
          mustContainWarning: 'Possible missing receipt section',
          expectParserReconciled: false,
          expectedTrustLabel: 'Needs receipt math review',
        ),
        _ReceiptSectionHandoffCase(
          name: 'out of order sections are not trusted',
          sections: const [
            '''
THE HOME DEPOT
06/22/2026
PVC GLUE 7.99
PVC PRIMER 8.99
''',
            '''
SAW BLADE 19.98
SUBTOTAL 72.44
TAX 5.07
TOTAL 77.51
''',
            '''
PVC PRIMER 8.99
5LB DECK SCREWS 32.49
''',
          ],
          expectedMerchant: 'The Home Depot',
          expectedTotal: 77.51,
          expectedParserLineCount: 5,
          expectedOcrSeverity: ReceiptOcrReviewSeverity.review,
          mustContainWarning: 'Possible missing receipt section',
          duplicateLine: 'PVC PRIMER 8.99',
          expectedRawOccurrences: 2,
          expectedAppFillOccurrences: 2,
          expectParserReconciled: false,
          expectedTrustLabel: 'Needs receipt math review',
        ),
        _ReceiptSectionHandoffCase(
          name: 'similar item names with different amounts are preserved',
          sections: const [
            '''
LOWE'S
06/23/2026
PVC GLUE 7.99
PVC PIPE 12.49
''',
            '''
PVC GLUE 8.99
PIPE STRAP 3.49
SUBTOTAL 32.96
TAX 2.31
TOTAL 35.27
''',
          ],
          expectedMerchant: "Lowe's",
          expectedTotal: 35.27,
          expectedParserLineCount: 4,
          expectedOcrSeverity: ReceiptOcrReviewSeverity.review,
          mustContainWarning: 'possible overlapping receipt line',
          duplicateLine: 'PVC GLUE',
          expectedRawOccurrences: 2,
          expectedAppFillOccurrences: 2,
          expectParserReconciled: true,
        ),
      ];

      for (final testCase in cases) {
        final result = await const ReceiptOcrService()
            .recognizeTextFromAttachments(testCase.attachments);
        final parsed = parseExpenseReceiptText(result.appFillText);

        expect(
          result.diagnostics.severity,
          testCase.expectedOcrSeverity,
          reason: testCase.name,
        );
        expect(
          result.warnings.join('\n'),
          contains(testCase.mustContainWarning),
          reason: testCase.name,
        );
        expect(parsed.merchantName, testCase.expectedMerchant);
        expect(parsed.enteredTotal, testCase.expectedTotal);
        expect(
          parsed.diagnostics.detectedLineCount,
          testCase.expectedParserLineCount,
          reason: testCase.name,
        );
        expect(
          parsed.diagnostics.reconciled,
          testCase.expectParserReconciled,
          reason: testCase.name,
        );
        if (testCase.expectedTrustLabel != null) {
          expect(parsed.diagnostics.trustLabel, testCase.expectedTrustLabel);
        }
        if (testCase.duplicateLine != null) {
          expect(
            testCase.duplicateLine!.allMatches(result.rawText),
            hasLength(testCase.expectedRawOccurrences),
            reason: testCase.name,
          );
          expect(
            testCase.duplicateLine!.allMatches(result.appFillText),
            hasLength(testCase.expectedAppFillOccurrences),
            reason: testCase.name,
          );
        }
      }
    },
  );

  test(
    'ocr app fill suppresses distinct ordered overlap across long sections',
    () async {
      final result = await const ReceiptOcrService()
          .recognizeTextFromAttachments([
            _textAttachment(
              id: 'top',
              text: '''
THE HOME DEPOT
06/20/2026
2X4X8 KD STUD 4.29
PVC GLUE 7.99
PVC PRIMER 8.99
''',
            ),
            _textAttachment(
              id: 'middle',
              text: '''
PVC GLUE 7.99
PVC PRIMER 8.99
5LB DECK SCREWS 32.49
SAW BLADE 19.98
''',
            ),
            _textAttachment(
              id: 'bottom',
              text: '''
5LB DECK SCREWS 32.49
SAW BLADE 19.98
NITRILE GLOVES 12.99
TOTAL 105.72
''',
            ),
          ]);

      expect(result.rawText, contains('THE HOME DEPOT'));
      expect('PVC GLUE 7.99'.allMatches(result.rawText), hasLength(2));
      expect('PVC PRIMER 8.99'.allMatches(result.rawText), hasLength(2));
      expect('5LB DECK SCREWS 32.49'.allMatches(result.rawText), hasLength(2));
      expect('SAW BLADE 19.98'.allMatches(result.rawText), hasLength(2));
      expect('PVC GLUE 7.99'.allMatches(result.appFillText), hasLength(1));
      expect('PVC PRIMER 8.99'.allMatches(result.appFillText), hasLength(1));
      expect(
        '5LB DECK SCREWS 32.49'.allMatches(result.appFillText),
        hasLength(1),
      );
      expect('SAW BLADE 19.98'.allMatches(result.appFillText), hasLength(1));
      expect(result.stats.importedTextRead, 3);
      expect(
        result.warnings.single,
        contains('Ignored 4 repeated receipt lines'),
      );
      expect(result.diagnostics.severity, ReceiptOcrReviewSeverity.review);
      expect(result.diagnostics.hadDuplicateOrOverlapText, isTrue);
      expect(result.diagnostics.rawLineCount, 13);
      expect(result.diagnostics.parserLineCount, 9);
    },
  );

  test(
    'ocr app fill keeps similar but different line amounts for review',
    () async {
      final result = await const ReceiptOcrService()
          .recognizeTextFromAttachments([
            _textAttachment(
              id: 'front',
              text: '''
LOWES
PVC GLUE 7.99
PVC PIPE 12.49
''',
            ),
            _textAttachment(
              id: 'back',
              text: '''
PVC GLUE 8.99
PIPE STRAP 3.49
TOTAL 32.96
''',
            ),
          ]);

      expect('PVC GLUE'.allMatches(result.appFillText), hasLength(2));
      expect(
        result.warnings.single,
        contains('possible overlapping receipt line'),
      );
      expect(result.warnings.single, contains('Nothing was changed'));
      expect(result.diagnostics.severity, ReceiptOcrReviewSeverity.review);
      expect(result.diagnostics.hadDuplicateOrOverlapText, isTrue);
      expect(
        result.diagnostics.rawLineCount,
        result.diagnostics.parserLineCount,
      );
    },
  );
}

class _ReceiptSectionHandoffCase {
  const _ReceiptSectionHandoffCase({
    required this.name,
    required this.sections,
    required this.expectedMerchant,
    required this.expectedTotal,
    required this.expectedParserLineCount,
    required this.expectedOcrSeverity,
    required this.mustContainWarning,
    required this.expectParserReconciled,
    this.duplicateLine,
    this.expectedRawOccurrences = 0,
    this.expectedAppFillOccurrences = 0,
    this.expectedTrustLabel,
  });

  final String name;
  final List<String> sections;
  final String expectedMerchant;
  final double expectedTotal;
  final int expectedParserLineCount;
  final ReceiptOcrReviewSeverity expectedOcrSeverity;
  final String mustContainWarning;
  final bool expectParserReconciled;
  final String? duplicateLine;
  final int expectedRawOccurrences;
  final int expectedAppFillOccurrences;
  final String? expectedTrustLabel;

  List<ReceiptAttachmentRecord> get attachments {
    return [
      for (var index = 0; index < sections.length; index++)
        _textAttachment(id: '$name-$index', text: sections[index]),
    ];
  }
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
    createdAt: DateTime(2026, 6, 20),
    importedText: text,
  );
}
