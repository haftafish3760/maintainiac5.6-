import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/receipts/receipt_processing_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_service.dart';

void main() {
  test('ocr totals evidence can trigger missing bottom coverage decision', () {
    const result = ReceiptOcrResult(
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
      textByAttachmentId: {'photo-1': 'private receipt text omitted'},
      source: ReceiptProcessingSource.photo,
    );

    final diagnostics = result.diagnostics;
    final coverageDecision = ReceiptPhotoCoverageDecision.fromSignals(
      quality: const ReceiptPhotoQualityCheck(
        width: 1200,
        height: 1800,
        focusScore: 18,
        isLikelyReadable: true,
      ),
      diagnostics: {
        ...diagnostics.receiptTotalsCoverageEvidenceDiagnostics,
        ReceiptCaptureDiagnosticKeys.receiptBottomEdgeDetected: false,
        ReceiptCaptureDiagnosticKeys.receiptBottomEdgeStatus:
            'bottom_soft_or_missing',
      },
    );

    expect(diagnostics.receiptTotalsTextEvidenceStatus, 'missing');
    expect(diagnostics.receiptMayNeedBottomSection, isTrue);
    expect(
      diagnostics.receiptBottomTotalsEvidenceLabel,
      'totals_missing_edge_ok',
    );
    expect(diagnostics.ocrSourceBottomCoverageRiskDetected, isFalse);
    expect(diagnostics.receiptMissingBottomEdgeAndTotals, isFalse);
    expect(
      diagnostics.parserTaskCounts['receipt_totals_text_missing_review'],
      1,
    );
    expect(
      diagnostics.parserTaskCounts['receipt_possible_lower_section_missing'],
      1,
    );
    expect(
      diagnostics.parserTaskCounts['receipt_missing_totals_manual_review'],
      1,
    );
    expect(
      diagnostics.parserSignalSummaryLabel,
      contains('totals need manual review'),
    );
    expect(
      diagnostics.parserTaskCounts.containsKey(
        'receipt_missing_bottom_edge_and_totals',
      ),
      isFalse,
    );
    expect(
      diagnostics.parserTaskCounts.containsKey(
        'receipt_bottom_section_continuation_needed',
      ),
      isFalse,
    );
    expect(
      diagnostics.receiptCompletionReviewReasonCode,
      'possible_missing_bottom_totals',
    );
    expect(
      diagnostics.receiptCompletionReviewActionLabel,
      'Check bottom section or enter total manually',
    );
    expect(
      diagnostics.receiptPostCaptureRouteStatus,
      'parsed_receipt_review_check_total',
    );
    expect(
      diagnostics.receiptPostCaptureRouteLabel,
      'Continue to receipt review and check the missing total.',
    );
    expect(
      diagnostics
          .receiptTotalsCoverageEvidenceDiagnostics['receiptMayNeedBottomSection'],
      isTrue,
    );
    expect(
      diagnostics
          .receiptTotalsCoverageEvidenceDiagnostics['receiptBottomTotalsEvidenceLabel'],
      'totals_missing_edge_ok',
    );
    expect(
      diagnostics
          .receiptTotalsCoverageEvidenceDiagnostics['receiptMissingBottomEdgeAndTotals'],
      isFalse,
    );
    expect(
      diagnostics
          .receiptTotalsCoverageEvidenceDiagnostics['ocrSourceBottomCoverageRiskDetected'],
      isFalse,
    );
    expect(
      diagnostics
          .receiptTotalsCoverageEvidenceDiagnostics['receiptPostCaptureRouteStatus'],
      'parsed_receipt_review_check_total',
    );
    expect(
      diagnostics.receiptTotalsCoverageEvidenceDiagnostics.containsKey(
        'ocrSourceContinuationSignalCounts',
      ),
      isFalse,
    );
    expect(coverageDecision.status, ReceiptPhotoCoverageStatus.likelyCutOff);
    expect(coverageDecision.reasonCode, 'missing_bottom_edge_and_totals');
    expect(coverageDecision.shouldPromptForMorePhotos, isTrue);
    expect(
      coverageDecision.continuationCaptureContractCode,
      'bottom_edge_totals_missing_use_ghost_overlap',
    );
    expect(coverageDecision.guidance, contains('top ghost-slice guide'));
  });
}
