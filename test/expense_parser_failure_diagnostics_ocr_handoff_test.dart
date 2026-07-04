import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_parser_failure_diagnostics.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';
import 'package:maintaniac/shared/receipts/receipt_ocr_contract.dart';
import 'package:maintaniac/shared/receipts/receipt_processing_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_assistance_policy.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  group('ExpenseParserFailureDiagnostics OCR handoff causes', () {
    test('marks OCR parser-readiness failures with exact handoff causes', () {
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
        textByAttachmentId: {'photo-1': 'private receipt text omitted'},
        source: ReceiptProcessingSource.photo,
      );
      final result = parseExpenseReceiptOcrResult(
        ocr,
        capability: const ReceiptDeviceCapability.highCapacity(),
      );

      final diagnostic = ExpenseParserFailureDiagnostics.diagnosticFor(result);

      expect(
        ExpenseParserFailureDiagnostics.outcomeFor(result),
        ExpenseParserTelemetryOutcome.needsReview,
      );
      expect(diagnostic, isNotNull);
      expect(diagnostic!.confirmedCause, 'receipt_ocr_no_parser_ready_items');
      expect(diagnostic.failedAt, 'ocr_to_parser_item_confidence_handoff');
      expect(
        diagnostic.evidence,
        contains('ocr_readiness_no_parser_ready_items'),
      );
      expect(diagnostic.evidence, contains('ocr_downstream_proof_total_only'));
      expect(diagnostic.evidence, contains('ocr_ready_0'));
      expect(diagnostic.evidence, contains('local_route_simple_expense_local'));
      expect(diagnostic.evidence, contains('local_kept_true'));
      expect(diagnostic.evidence, contains('optional_pack_false'));
    });

    test('prioritizes OCR parser task buckets as exact handoff causes', () {
      final base = parseExpenseReceiptText('''
Quick Fuel
06/11/2026
Diesel 12.50 GAL 3.90 48.75
Subtotal 48.75
Tax 2.93
Total 51.68
''');

      void expectCause(
        Map<String, int> taskCounts,
        String expectedCause,
        String expectedStage,
      ) {
        final result = base.copyWith(
          diagnostics: base.diagnostics.copyWith(
            ocrParserTaskCounts: taskCounts,
          ),
        );
        final diagnostic = ExpenseParserFailureDiagnostics.diagnosticFor(
          result,
        );

        expect(diagnostic, isNotNull);
        expect(diagnostic!.confirmedCause, expectedCause);
        expect(diagnostic.failedAt, expectedStage);
        expect(diagnostic.evidence, contains('ocr_tasks_'));
        expect(
          ExpenseParserFailureDiagnostics.outcomeFor(result),
          ExpenseParserTelemetryOutcome.needsReview,
        );
        expect(
          result.diagnostics.ocrParserReviewCauseCodes,
          contains(expectedCause),
        );
      }

      expectCause(
        {'date_missing': 1},
        'receipt_ocr_missing_date',
        'ocr_to_parser_date_handoff',
      );
      expectCause(
        {'ocr_no_readable_text': 1},
        'receipt_ocr_no_readable_text',
        'ocr_to_parser_no_text_handoff',
      );
      expectCause(
        {'photo_read_failed': 1},
        'receipt_ocr_photo_read_failed',
        'ocr_to_parser_photo_read_handoff',
      );
      expectCause(
        {'photo_tiny_text_review': 1},
        'receipt_ocr_photo_tiny_text',
        'ocr_to_parser_tiny_text_handoff',
      );
      expectCause(
        {'photo_small_proof_review': 1},
        'receipt_ocr_small_proof_copy',
        'ocr_to_parser_small_proof_handoff',
      );
      expectCause(
        {'photo_retake_recommended_review': 1},
        'receipt_ocr_photo_retake_recommended',
        'ocr_to_parser_photo_retake_handoff',
      );
      expectCause(
        {'photo_crop_or_retake_review': 1},
        'receipt_ocr_photo_crop_or_retake',
        'ocr_to_parser_photo_crop_handoff',
      );
      expectCause(
        {'photo_readability_or_closer_review': 1},
        'receipt_ocr_photo_readability_or_closer',
        'ocr_to_parser_photo_readability_handoff',
      );
      expectCause(
        {'photo_saved_dark_or_exposure_review': 1},
        'receipt_ocr_photo_saved_dark_or_exposure',
        'ocr_to_parser_photo_exposure_handoff',
      );
      expectCause(
        {'photo_saved_soft_blur_review': 1},
        'receipt_ocr_photo_saved_soft_blur',
        'ocr_to_parser_photo_focus_handoff',
      );
      expectCause(
        {'photo_saved_glare_review': 1},
        'receipt_ocr_photo_saved_glare',
        'ocr_to_parser_photo_glare_handoff',
      );
      expectCause(
        {'photo_saved_bottom_quality_review': 1},
        'receipt_ocr_photo_saved_bottom_quality',
        'ocr_to_parser_photo_bottom_quality_handoff',
      );
      expectCause(
        {'photo_quality_review': 1},
        'receipt_ocr_photo_quality_review',
        'ocr_to_parser_photo_quality_handoff',
      );
      expectCause(
        {'long_receipt_section_gap': 1},
        'receipt_ocr_long_receipt_section_gap',
        'ocr_to_parser_long_receipt_section_handoff',
      );
      expectCause(
        {'long_receipt_probable_overlap': 1},
        'receipt_ocr_long_receipt_probable_overlap',
        'ocr_to_parser_long_receipt_overlap_handoff',
      );
      expectCause(
        {'long_receipt_duplicate_text': 1},
        'receipt_ocr_long_receipt_duplicate_text',
        'ocr_to_parser_long_receipt_duplicate_handoff',
      );
      expectCause(
        {'summary_missing': 1},
        'receipt_ocr_missing_summary',
        'ocr_to_parser_summary_handoff',
      );
      expectCause(
        {'tax_missing': 1},
        'receipt_ocr_missing_tax',
        'ocr_to_parser_tax_handoff',
      );
      expectCause(
        {'line_sequence_needs_review': 1},
        'receipt_ocr_line_sequence_review',
        'ocr_to_parser_line_sequence_handoff',
      );
      expectCause(
        {'summary_math_needs_review': 1},
        'receipt_ocr_summary_math_review',
        'ocr_to_parser_summary_math_handoff',
      );
    });

    test('maps source quality action handoff to retake diagnostic cause', () {
      final sourceHandoff = ReceiptOcrSourceHandoffSummary.fromAttachments([
        ReceiptAttachmentRecord(
          id: 'photo-1',
          path: '/tmp/receipt.jpg',
          kind: ReceiptAttachmentKind.photo,
          dataSaverLevel: ReceiptDataSaverLevel.balanced,
          createdAt: DateTime(2026, 7, 1),
          riskFlags: const [
            'ocr_source_quality_action_retake_recommended_continue_allowed',
            'ocr_source_quality_family_retake',
          ],
        ),
      ]);
      expect(
        sourceHandoff.photoQualityRiskCounts,
        containsPair(
          'ocr_source_quality_action_retake_recommended_continue_allowed',
          1,
        ),
      );
      final ocr = ReceiptOcrResult(
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
        textByAttachmentId: const {'photo-1': 'private receipt text omitted'},
        source: ReceiptProcessingSource.photo,
        sourceHandoffSummary: sourceHandoff,
      );
      final result = parseExpenseReceiptOcrResult(
        ocr,
        capability: const ReceiptDeviceCapability.highCapacity(),
      );

      final diagnostic = ExpenseParserFailureDiagnostics.diagnosticFor(result);

      expect(
        result.diagnostics.ocrParserTaskCount(
          'photo_retake_recommended_review',
        ),
        1,
      );
      expect(
        result.diagnostics.ocrParserReviewCauseCodes,
        contains('receipt_ocr_photo_retake_recommended'),
      );
      expect(diagnostic, isNotNull);
      expect(
        diagnostic!.confirmedCause,
        'receipt_ocr_photo_retake_recommended',
      );
      expect(diagnostic.failedAt, 'ocr_to_parser_photo_retake_handoff');
      expect(diagnostic.evidence, contains('photo_retake_recommended_review'));
    });

    test('keeps long receipt OCR warning task buckets after parser handoff', () {
      const ocr = ReceiptOcrResult(
        rawText: '''
LOWE'S
06/12/2026
PVC GLUE 7.99
TOTAL 7.99
''',
        parserText: '''
LOWE'S
06/12/2026
PVC GLUE 7.99
TOTAL 7.99
''',
        textByAttachmentId: {'photo-1': 'private receipt text omitted'},
        source: ReceiptProcessingSource.photo,
        warnings: [
          'Ignored 1 repeated receipt line for app-assisted fill. Original receipt text was kept; review line items before saving.',
          'Found 1 possible overlapping receipt line. Nothing was changed automatically; review line items before saving.',
          'Found 1 receipt section break with no repeated receipt text between sections. Possible missing receipt section; check photo order and line items before saving.',
        ],
      );

      final result = parseExpenseReceiptOcrResult(
        ocr,
        capability: const ReceiptDeviceCapability.highCapacity(),
      );

      expect(
        result.diagnostics.ocrParserTaskCounts['long_receipt_duplicate_text'],
        1,
      );
      expect(
        result.diagnostics.ocrParserTaskCounts['long_receipt_probable_overlap'],
        1,
      );
      expect(
        result.diagnostics.ocrParserTaskCounts['long_receipt_section_gap'],
        1,
      );
    });
  });
}
