import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  test('missing bottom edge and totals recommends next receipt section', () {
    final decision = ReceiptPhotoCoverageDecision.fromSignals(
      quality: const ReceiptPhotoQualityCheck(
        width: 1200,
        height: 1800,
        focusScore: 18,
        isLikelyReadable: true,
      ),
      diagnostics: const {
        ReceiptCaptureDiagnosticKeys.receiptBottomEdgeDetected: false,
        ReceiptCaptureDiagnosticKeys.receiptSubtotalDetected: false,
        ReceiptCaptureDiagnosticKeys.receiptTotalDetected: false,
        ReceiptCaptureDiagnosticKeys.receiptTotalAmountDetected: false,
        'subtotalCandidateLineCount': 0,
        'totalCandidateLineCount': 0,
      },
    );

    expect(decision.status, ReceiptPhotoCoverageStatus.likelyCutOff);
    expect(decision.reasonCode, 'missing_bottom_edge_and_totals');
    expect(decision.shouldPromptForMorePhotos, isTrue);
    expect(decision.isMissingBottomEdgeAndTotals, isTrue);
    expect(decision.completionDialogTitle, 'Add the bottom of this receipt?');
    expect(decision.addSectionButtonLabel, 'Add Bottom Section');
    expect(decision.continueAnywayButtonLabel, 'Save & Continue');
    expect(
      decision.evidenceContractCode,
      'bottom_edge_missing_plus_totals_words_and_amount_missing',
    );
    expect(
      decision.evidenceContractLabel,
      'Bottom edge, subtotal/total words, and total amount evidence are missing.',
    );
    expect(
      decision.evidenceRationaleCode,
      'edge_missing_and_totals_words_amount_missing',
    );
    expect(
      decision.evidenceRationaleLabel,
      contains('receipt-edge evidence, subtotal/total word evidence'),
    );
    expect(
      decision.guidance,
      contains('Two checks agree that the receipt may continue'),
    );
    expect(decision.guidance, contains('the bottom edge was not detected'));
    expect(
      decision.guidance,
      contains('subtotal/total words plus the total amount'),
    );
    expect(decision.guidance, contains('top ghost-slice guide'));
    expect(
      decision.guidance,
      contains('subtotal, total, and final lines can be matched'),
    );
    expect(
      decision.continuationCaptureContractLabel,
      contains('top ghost-slice guide'),
    );
    expect(
      decision.continuationCaptureContractLabel,
      contains('subtotal, total, and final lines can be matched'),
    );
    expect(
      decision.completionEvidenceSummaryLabel,
      contains(
        'Bottom edge missing plus subtotal/total words and total amount missing',
      ),
    );
    expect(
      decision.privacySafeEvidenceContract,
      containsPair(
        'continuationCaptureContractCode',
        'bottom_edge_totals_missing_use_ghost_overlap',
      ),
    );
    expect(
      decision.privacySafeEvidenceContract,
      containsPair('bottomEdgeAndTotalsMissingTogether', true),
    );
    expect(
      decision.privacySafeEvidenceContract,
      containsPair('ghostGuidePlacementCode', 'top_ghost_slice'),
    );
    expect(
      decision.privacySafeEvidenceContract,
      containsPair(
        'ghostGuideRepeatLineTargetCode',
        'repeat_3_to_5_readable_lines',
      ),
    );
    expect(
      decision.privacySafeEvidenceContract,
      containsPair(
        'ghostGuideMatchTargetCode',
        'subtotal_total_and_final_lines',
      ),
    );
    expect(
      decision.privacySafeEvidenceContract,
      containsPair(
        'evidenceRationaleCode',
        'edge_missing_and_totals_words_amount_missing',
      ),
    );
    expect(
      decision.completionDialogMessage,
      contains('subtotal/total may need manual review'),
    );

    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/top-only-proof.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/top-only-ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: ReceiptStitchResult.notNeeded(['/tmp/top-only-ocr.jpg']),
      captureDiagnosticsByPhotoPath: {
        '/tmp/top-only-proof.jpg': {
          ReceiptCaptureDiagnosticKeys.photoCoverageStatus:
              decision.status.name,
          ReceiptCaptureDiagnosticKeys.photoCoverageReason: decision.reasonCode,
          ReceiptCaptureDiagnosticKeys.photoCoverageNeedsMorePhotos:
              decision.shouldPromptForMorePhotos,
        },
      },
    );

    expect(result.needsAnotherReceiptSectionBeforeDetails, isTrue);
    expect(
      result.firstPossiblePartialReceiptReasonCode,
      'missing_bottom_edge_and_totals',
    );
    expect(
      result.acceptedPhotoHandoffActionLabel,
      contains(
        'Add the bottom receipt section and repeat 3-5 readable lines in the top ghost slice',
      ),
    );
    expect(
      result.acceptedPhotoHandoffRoute,
      'photo_review_add_next_receipt_section',
    );
    expect(
      result.acceptedPhotoHandoffNextScreen,
      'receipt_photo_capture_bottom_section',
    );
    expect(
      result.acceptedPhotoHandoffNextStepLabel,
      contains(
        'subtotal, total, and final lines can be matched before receipt details',
      ),
    );
    expect(
      result.acceptedPhotoHandoffProcessingLabel,
      contains('Receipt details stay paused'),
    );
    expect(result.acceptedPhotoHandoffMustOpenFilledReview, isFalse);
    expect(result.acceptedPhotoHandoffMustOpenReceiptDetails, isFalse);
    expect(
      result.nextReviewHandoffLabel,
      contains(
        'subtotal, total, and final lines can be matched before receipt details',
      ),
    );
    expect(
      result.nextReviewMatchReadinessLabel,
      contains(
        'subtotal, total, and final lines can be matched or confirm this photo already shows the full receipt',
      ),
    );
  });

  test('detected totals avoid long receipt prompt when bottom is present', () {
    final decision = ReceiptPhotoCoverageDecision.fromSignals(
      quality: const ReceiptPhotoQualityCheck(
        width: 1200,
        height: 1800,
        focusScore: 18,
        isLikelyReadable: true,
      ),
      diagnostics: const {
        ReceiptCaptureDiagnosticKeys.receiptBottomEdgeDetected: true,
        ReceiptCaptureDiagnosticKeys.receiptSubtotalDetected: true,
        ReceiptCaptureDiagnosticKeys.receiptTotalDetected: true,
        ReceiptCaptureDiagnosticKeys.receiptTotalAmountDetected: true,
        'subtotalCandidateLineCount': 1,
        'totalCandidateLineCount': 1,
      },
    );

    expect(decision.reasonCode, isNot('missing_bottom_edge_and_totals'));
    expect(decision.shouldPromptForMorePhotos, isFalse);
    expect(
      decision.evidenceContractCode,
      'single_signal_or_manual_coverage_review',
    );
    expect(
      decision.privacySafeEvidenceContract,
      containsPair('bottomEdgeAndTotalsMissingTogether', false),
    );
  });

  test('detected totals do not force ghost guide when bottom edge is weak', () {
    final decision = ReceiptPhotoCoverageDecision.fromSignals(
      quality: const ReceiptPhotoQualityCheck(
        width: 1200,
        height: 1800,
        focusScore: 18,
        isLikelyReadable: true,
      ),
      diagnostics: const {
        ReceiptCaptureDiagnosticKeys.receiptBottomEdgeDetected: false,
        ReceiptCaptureDiagnosticKeys.receiptBottomEdgeStatus:
            'bottom_soft_or_missing',
        ReceiptCaptureDiagnosticKeys.latestFramingSignal:
            ReceiptNativeCoverageSignalValues.possiblyCutOff,
        ReceiptCaptureDiagnosticKeys.latestEdgeCoverage: .76,
        ReceiptCaptureDiagnosticKeys.receiptSubtotalDetected: true,
        ReceiptCaptureDiagnosticKeys.receiptTotalDetected: true,
        ReceiptCaptureDiagnosticKeys.receiptTotalAmountDetected: true,
        ReceiptCaptureDiagnosticKeys.receiptTotalsTextEvidenceStatus:
            'subtotal_and_total_found',
        'subtotalCandidateLineCount': 1,
        'totalCandidateLineCount': 1,
      },
    );

    expect(decision.reasonCode, 'native_cut_off_readable_check');
    expect(decision.status, ReceiptPhotoCoverageStatus.likelyComplete);
    expect(decision.isMissingBottomEdgeAndTotals, isFalse);
    expect(
      decision.continuationCaptureContractCode,
      isNot('bottom_edge_totals_missing_use_ghost_overlap'),
    );
    expect(decision.shouldPromptForMorePhotos, isFalse);
    expect(decision.guidance, contains('Check that the top and bottom'));
  });

  test('non-finite coverage diagnostics are treated as missing evidence', () {
    final decision = ReceiptPhotoCoverageDecision.fromSignals(
      quality: const ReceiptPhotoQualityCheck(
        width: 1200,
        height: 1800,
        focusScore: 18,
        isLikelyReadable: true,
      ),
      diagnostics: {
        ReceiptCaptureDiagnosticKeys.latestFramingSignal:
            ReceiptNativeCoverageSignalValues.possiblyCutOff,
        ReceiptCaptureDiagnosticKeys.latestEdgeCoverage: double.nan,
        ReceiptCaptureDiagnosticKeys.latestCapturedBottomEdgeScore:
            double.infinity,
        ReceiptCaptureDiagnosticKeys.receiptSubtotalDetected: false,
        ReceiptCaptureDiagnosticKeys.receiptTotalDetected: false,
        ReceiptCaptureDiagnosticKeys.receiptTotalAmountDetected: false,
        'subtotalCandidateLineCount': double.infinity,
        'totalCandidateLineCount': double.nan,
        ReceiptCaptureDiagnosticKeys.receiptTotalsTextEvidenceStatus:
            'not_found',
      },
    );

    expect(decision.status, ReceiptPhotoCoverageStatus.likelyCutOff);
    expect(decision.reasonCode, 'missing_bottom_edge_and_totals');
    expect(decision.isMissingBottomEdgeAndTotals, isTrue);
    expect(decision.shouldPromptForMorePhotos, isTrue);
    expect(
      decision.continuationCaptureContractCode,
      'bottom_edge_totals_missing_use_ghost_overlap',
    );
  });

  test('fractional totals counts do not satisfy completion evidence', () {
    final decision = ReceiptPhotoCoverageDecision.fromSignals(
      quality: const ReceiptPhotoQualityCheck(
        width: 1200,
        height: 1800,
        focusScore: 18,
        isLikelyReadable: true,
      ),
      diagnostics: const {
        ReceiptCaptureDiagnosticKeys.receiptBottomEdgeDetected: false,
        ReceiptCaptureDiagnosticKeys.receiptSubtotalDetected: false,
        ReceiptCaptureDiagnosticKeys.receiptTotalDetected: false,
        ReceiptCaptureDiagnosticKeys.receiptTotalAmountDetected: false,
        'subtotalCandidateLineCount': .6,
        'totalCandidateLineCount': '0.7',
        ReceiptCaptureDiagnosticKeys.receiptTotalsTextEvidenceStatus:
            'not_found',
      },
    );

    expect(decision.status, ReceiptPhotoCoverageStatus.likelyCutOff);
    expect(decision.reasonCode, 'missing_bottom_edge_and_totals');
    expect(decision.shouldPromptForMorePhotos, isTrue);
    expect(
      decision.ghostGuideMatchTargetCode,
      'subtotal_total_and_final_lines',
    );
  });

  test('bottom soft or missing status prompts without a boolean edge flag', () {
    final decision = ReceiptPhotoCoverageDecision.fromSignals(
      quality: const ReceiptPhotoQualityCheck(
        width: 1200,
        height: 1800,
        focusScore: 18,
        isLikelyReadable: true,
      ),
      diagnostics: const {
        ReceiptCaptureDiagnosticKeys.receiptBottomEdgeStatus:
            'bottom_soft_or_missing',
        ReceiptCaptureDiagnosticKeys.receiptSubtotalDetected: false,
        ReceiptCaptureDiagnosticKeys.receiptTotalDetected: false,
        ReceiptCaptureDiagnosticKeys.receiptTotalAmountDetected: false,
        'subtotalCandidateLineCount': 0,
        'totalCandidateLineCount': 0,
        ReceiptCaptureDiagnosticKeys.receiptTotalsTextEvidenceStatus: 'missing',
      },
    );

    expect(decision.status, ReceiptPhotoCoverageStatus.likelyCutOff);
    expect(decision.reasonCode, 'missing_bottom_edge_and_totals');
    expect(decision.shouldPromptForMorePhotos, isTrue);
    expect(
      decision.continuationCaptureContractCode,
      'bottom_edge_totals_missing_use_ghost_overlap',
    );
  });

  test('tax line alone does not satisfy bottom totals completion evidence', () {
    final decision = ReceiptPhotoCoverageDecision.fromSignals(
      quality: const ReceiptPhotoQualityCheck(
        width: 1400,
        height: 1800,
        focusScore: 22,
        isLikelyReadable: true,
      ),
      diagnostics: const {
        ReceiptCaptureDiagnosticKeys.receiptBottomEdgeDetected: false,
        ReceiptCaptureDiagnosticKeys.receiptSubtotalDetected: false,
        ReceiptCaptureDiagnosticKeys.receiptTotalDetected: false,
        ReceiptCaptureDiagnosticKeys.receiptTotalAmountDetected: false,
        'subtotalCandidateLineCount': 0,
        'totalCandidateLineCount': 0,
        'taxCandidateLineCount': 1,
        'receiptSummaryLineCount': 1,
        ReceiptCaptureDiagnosticKeys.receiptTotalsTextEvidenceStatus:
            'not_found',
      },
    );

    expect(decision.reasonCode, 'missing_bottom_edge_and_totals');
    expect(decision.shouldPromptForMorePhotos, isTrue);
    expect(decision.ghostGuidePlacementCode, 'top_ghost_slice');
    expect(
      decision.ghostGuideMatchTargetCode,
      'subtotal_total_and_final_lines',
    );
    expect(
      decision.guidance,
      contains('subtotal/total words plus the total amount'),
    );
  });
}
