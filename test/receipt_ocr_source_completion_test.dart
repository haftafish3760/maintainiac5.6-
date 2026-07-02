import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/receipts/receipt_processing_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_service.dart';

void main() {
  test('user confirmed complete receipt separates review from continuation', () {
    final sourceHandoff = ReceiptOcrSourceHandoffSummary.fromAttachments([
      ReceiptAttachmentRecord(
        id: 'ocr-source-confirmed',
        path: '/tmp/receipt-confirmed.jpg',
        kind: ReceiptAttachmentKind.photo,
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
        createdAt: DateTime(2026, 6, 30),
        documentSignals: const [
          'receipt_continuation_missing_bottom_edge_and_totals',
          'receipt_completion_user_confirmed_complete_after_prompt',
          'receipt_completion_continue_anyway',
        ],
        riskFlags: const [
          'ocr_source_continuation_missing_bottom_totals_review',
          'ocr_source_completion_continue_anyway_review',
        ],
      ),
    ]);
    final result = ReceiptOcrResult(
      rawText: '''
LOWE'S
06/12/2026
PVC GLUE 7.99
''',
      parserText: '''
LOWE'S
06/12/2026
PVC GLUE 7.99
''',
      textByAttachmentId: const {'photo-1': 'private receipt text omitted'},
      source: ReceiptProcessingSource.photo,
      sourceHandoffSummary: sourceHandoff,
    );

    final diagnostics = result.diagnostics;
    final coverageEvidence =
        diagnostics.receiptTotalsCoverageEvidenceDiagnostics;

    expect(sourceHandoff.hasMissingBottomEdgeAndTotalsEvidence, isTrue);
    expect(sourceHandoff.hasUserConfirmedCompleteAfterPrompt, isTrue);
    expect(
      sourceHandoff
          .completionSignalCounts['receipt_completion_user_confirmed_complete_after_prompt'],
      1,
    );
    expect(
      diagnostics
          .ocrSourceCompletionSignalCounts['ocr_source_completion_continue_anyway_review'],
      1,
    );
    expect(diagnostics.receiptTotalsTextEvidenceStatus, 'missing');
    expect(diagnostics.receiptMayNeedBottomSection, isTrue);
    expect(diagnostics.receiptMissingBottomEdgeAndTotals, isTrue);
    expect(diagnostics.receiptCompletionUserConfirmedComplete, isTrue);
    expect(
      diagnostics.receiptCompletionReviewReasonCode,
      'user_confirmed_complete_missing_bottom_review',
    );
    expect(
      diagnostics.receiptCompletionReviewActionLabel,
      'Review user-confirmed receipt totals',
    );
    expect(
      diagnostics.receiptPostCaptureRouteStatus,
      'parsed_receipt_review_user_confirmed_complete',
    );
    expect(
      diagnostics.receiptPostCaptureRouteLabel,
      'Continue to receipt review and check the user-confirmed totals.',
    );
    expect(
      diagnostics.parserTaskCounts['receipt_totals_text_missing_review'],
      1,
    );
    expect(
      diagnostics.parserTaskCounts['receipt_possible_lower_section_missing'],
      1,
    );
    expect(
      diagnostics.parserTaskCounts['receipt_user_confirmed_complete_review'],
      1,
    );
    expect(
      diagnostics
          .parserTaskCounts['receipt_user_confirmed_missing_bottom_review'],
      1,
    );
    expect(
      diagnostics.parserTaskCounts.containsKey(
        'receipt_bottom_section_continuation_needed',
      ),
      isFalse,
    );
    expect(
      diagnostics.parserTaskCounts.containsKey(
        'receipt_missing_bottom_edge_and_totals',
      ),
      isFalse,
    );
    expect(
      diagnostics.parserSignalSummaryLabel,
      contains('user confirmed full receipt'),
    );
    expect(coverageEvidence['receiptCompletionUserConfirmedComplete'], isTrue);
    expect(
      coverageEvidence['ocrSourceCompletionSignalCounts'],
      containsPair('receipt_completion_continue_anyway', 1),
    );
  });

  test(
    'ocr source handoff bottom evidence only comes from coverage signals',
    () {
      final normalSource = ReceiptOcrSourceHandoffSummary.fromAttachments([
        ReceiptAttachmentRecord(
          id: 'ocr-source-normal',
          path: '/tmp/receipt-full.jpg',
          kind: ReceiptAttachmentKind.photo,
          dataSaverLevel: ReceiptDataSaverLevel.balanced,
          createdAt: DateTime(2026, 6, 30),
          documentSignals: const [
            'receipt_ocr_source_photo',
            'ocr_reads_prepared_source_not_saved_backup',
          ],
          riskFlags: const ['ocr_source_first_prepared_receipt_source'],
        ),
      ]);
      final possiblePartialSource =
          ReceiptOcrSourceHandoffSummary.fromAttachments([
            ReceiptAttachmentRecord(
              id: 'ocr-source-partial',
              path: '/tmp/receipt-top.jpg',
              kind: ReceiptAttachmentKind.photo,
              dataSaverLevel: ReceiptDataSaverLevel.balanced,
              createdAt: DateTime(2026, 6, 30),
              documentSignals: const [
                'receipt_handoff_possible_partial_receipt',
              ],
            ),
          ]);

      expect(normalSource.hasMissingBottomEdgeAndTotalsEvidence, isFalse);
      expect(normalSource.continuationSignalCounts, isEmpty);
      expect(
        possiblePartialSource.hasMissingBottomEdgeAndTotalsEvidence,
        isTrue,
      );
      expect(possiblePartialSource.status, 'possible_partial_receipt');
    },
  );
}
