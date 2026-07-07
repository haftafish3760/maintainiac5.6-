import 'package:flutter_test/flutter_test.dart';

import 'helpers/expense_receipt_assisted_review_source_fixture.dart';

void main() {
  test('assisted receipt review exposes handoff and install metadata', () async {
    final source = await readAssistedReviewSourceFixture();
    final entryScreen = source.entryScreen;
    final stateActions = source.stateActions;
    final attachmentPanel = source.attachmentPanel;
    final importActions = source.importActions;
    final parseReview = source.parseReview;
    final parseModels = source.parseModels;
    final receiptModels = source.receiptModels;
    final telemetry = source.telemetry;
    expect(
      entryScreen,
      contains('processingInFlight: _scanningReceiptPhotos'),
    );
    expect(
      entryScreen,
      contains('onAddOrRetakePhoto: _scrollToReceiptPhotoRecovery'),
    );
    expect(parseReview, contains('processingInFlight'));
    expect(entryScreen, contains("stageLabel: _receiptReadHandoffStage"));
    expect(
      entryScreen,
      contains('routeResultLabel: _receiptReadHandoffRouteResult'),
    );
    expect(
      entryScreen,
      contains('_receiptReadHandoffDecision = result.nextReviewHandoffLabel'),
    );
    expect(
      entryScreen,
      contains(
        '_receiptBrainLowStorageDownloadRiskCounts =\n          result.receiptBrainLowStorageDownloadRiskCounts',
      ),
    );
    expect(
      entryScreen,
      contains(
        '_receiptBrainFullOfflineMustStayOptionalCounts =\n          result.receiptBrainFullOfflineMustStayOptionalCounts',
      ),
    );
    expect(
      entryScreen,
      contains(
        '_receiptBrainFullOfflineExceedsBaseGuardrailCounts =\n          result.receiptBrainFullOfflineExceedsBaseGuardrailCounts',
      ),
    );
    expect(
      entryScreen,
      contains(
        '_receiptInstallRequiredSegmentCounts =\n          result.receiptInstallRequiredSegmentCounts',
      ),
    );
    expect(
      entryScreen,
      contains(
        '_receiptInstallFullOfflineSegmentCounts =\n          result.receiptInstallFullOfflineSegmentCounts',
      ),
    );
    expect(
      entryScreen,
      contains(
        '_receiptInstallLowStorageImpactCounts =\n          result.receiptInstallLowStorageImpactCounts',
      ),
    );
    expect(
      entryScreen,
      contains(
        '_receiptInstallRecommendedDistributionCounts =\n          result.receiptInstallRecommendedDistributionCounts',
      ),
    );
    expect(
      entryScreen,
      contains(
        '_receiptReadHandoffRouteResult =\n          result.acceptedPhotoHandoffRouteResultLabel',
      ),
    );
    expect(parseReview, contains("stageLabel.trim().isEmpty"));
    expect(parseReview, contains('Preparing receipt details'));
    expect(
      parseReview,
      contains(
        'Receipt details are still opening from the accepted photo. Review opens after OCR and parsing finish this handoff.',
      ),
    );
    expect(
      parseReview,
      contains(
        "decision.toLowerCase().contains('add bottom receipt section')",
      ),
    );
    expect(
      parseReview,
      contains("final photoRecoveryLabel = needsBottomSection"),
    );
    expect(parseReview, contains("'Add Bottom Section'"));
    expect(parseReview, contains("'Retake / Add Photo'"));
    expect(parseReview, isNot(contains("const Text('Add / Retake')")));
    expect(
      parseReview,
      contains('onPressed: processingInFlight ? null : onReviewDetails'),
    );
    expect(
      parseReview,
      contains(
        "processingInFlight\n                      ? 'Preparing'",
      ),
    );
    expect(
      entryScreen,
      contains(
        '_receiptReadHandoffAction = result.acceptedPhotoHandoffActionLabel',
      ),
    );
    expect(
      importActions,
      contains('final processing = result.acceptedPhotoHandoffProcessingLabel'),
    );
    expect(importActions, contains(r'Photo review accepted. $processing'));
    expect(
      stateActions,
      contains(
        '_receiptReadHandoffDecision = _receiptDecisionLabelForParsedReceipt',
      ),
    );
    expect(
      stateActions,
      contains(
        '_receiptReadHandoffAction = _receiptActionLabelForParsedReceipt',
      ),
    );
    expect(
      stateActions,
      contains('_receiptReadHandoffStage = _receiptStageLabelForParsedReceipt'),
    );
    expect(entryScreen, contains('localReceiptParserRoutingSummaryLabel'));
    expect(entryScreen, contains('_receiptDecisionLabelForParsedReceipt'));
    expect(entryScreen, contains('_receiptActionLabelForParsedReceipt'));
    expect(entryScreen, contains('_receiptStageLabelForParsedReceipt'));
    expect(entryScreen, contains("return 'Add bottom receipt section';"));
    expect(parseModels, contains('localReceiptParserRoutingSummaryLabel'));
    expect(parseModels, contains('localReceiptParserRoutingActionLabel'));
    expect(parseModels, contains('receiptBrainParserLimitSummaryLabel'));
    expect(parseModels, contains('receiptBrainParserLimitActionLabel'));
    expect(parseReview, contains('receiptBrainLimitLabel'));
    expect(parseReview, contains('receiptBrainLimitColor'));
    expect(parseReview, contains('receiptBrainParserLimitSummaryLabel'));
    expect(parseReview, contains('receiptBrainParserLimitActionLabel'));
    expect(entryScreen, contains("'privacySafeOcrHandoffEvidence'"));
    expect(
      entryScreen,
      contains('...result.privacySafeReceiptReaderHandoffMetadata'),
    );
    expect(receiptModels, contains("'receiptReaderHandoffSchema'"));
    expect(receiptModels, contains("'receiptDetailsHandoffSchema'"));
    expect(receiptModels, contains("'receiptReaderHandoffRoute'"));
    expect(receiptModels, contains("'receiptDetailsHandoffRoute'"));
    expect(receiptModels, contains("'receiptReaderHandoffNextScreen'"));
    expect(receiptModels, contains("'receiptDetailsHandoffNextScreen'"));
    expect(receiptModels, contains('acceptedPhotoHandoffProcessingLabel'));
    expect(receiptModels, contains("'receiptReaderHandoffProcessingLabel'"));
    expect(receiptModels, contains("'receiptDetailsHandoffProcessingLabel'"));
    expect(
      receiptModels,
      contains('Maintainiac reads the clearest OCR source first'),
    );
    expect(receiptModels, contains("'receiptReaderHandoffUserAction'"));
    expect(receiptModels, contains("'receiptDetailsHandoffUserAction'"));
    expect(receiptModels, contains("'receiptReaderHandoffRouteResultLabel'"));
    expect(receiptModels, contains("'receiptDetailsHandoffRouteResultLabel'"));
    expect(receiptModels, contains('acceptedPhotoHandoffRouteResultLabel'));
    expect(receiptModels, contains("'acceptedPhotoWarningProfile'"));
    expect(receiptModels, contains("'acceptedPhotoWarningActionLabel'"));
    expect(receiptModels, contains("'savedPhotoWarningReviewActions'"));
    expect(receiptModels, contains('savedPhotoWarningReviewActionLabels'));
    expect(receiptModels, contains('acceptedPhotoWarningReviewActionLabel'));
    expect(receiptModels, contains("'receiptBrainBaseSizeDecisionCounts'"));
    expect(receiptModels, contains("'receiptBrainBaseSizeDecisionOutcome'"));
    expect(receiptModels, contains("'receiptBrainBaseNeedsSizeReviewCounts'"));
    expect(receiptModels, contains("'receiptBrainBaseBlocksLowStorageCounts'"));
    expect(
      receiptModels,
      contains("'receiptBrainFullOfflineExceedsBaseGuardrailCounts'"),
    );
    expect(
      receiptModels,
      contains("'receiptBrainFullOfflineMustStayOptionalCounts'"),
    );
    expect(
      receiptModels,
      contains("'receiptBrainLowStorageDownloadRiskCounts'"),
    );
    expect(
      receiptModels,
      contains("'receiptBrainLowStorageDownloadRiskOutcome'"),
    );
    expect(receiptModels, contains("'receiptProofStoragePolicyCounts'"));
    expect(receiptModels, contains("'receiptProofStoragePolicyOutcome'"));
    expect(attachmentPanel, contains('receiptProofStoragePolicyOutcome'));
    expect(attachmentPanel, contains('receiptProofStoragePolicyCounts'));
    expect(receiptModels, contains('smaller saved proof copy is kept'));
    expect(receiptModels, contains("'receiptInstallRequiredSegmentCounts'"));
    expect(receiptModels, contains("'receiptInstallRequiredSegmentOutcome'"));
    expect(receiptModels, contains("'receiptInstallFullOfflineSegmentCounts'"));
    expect(
      receiptModels,
      contains("'receiptInstallFullOfflineSegmentOutcome'"),
    );
    expect(receiptModels, contains("'receiptInstallLowStorageImpactCounts'"));
    expect(receiptModels, contains("'receiptInstallLowStorageImpactOutcome'"));
    expect(
      receiptModels,
      contains("'receiptInstallRecommendedDistributionCounts'"),
    );
    expect(
      receiptModels,
      contains("'receiptInstallRecommendedDistributionOutcome'"),
    );
    expect(
      receiptModels,
      contains("'receiptInstallCameraShellParserFreeCounts'"),
    );
    expect(
      receiptModels,
      contains("'receiptInstallBaseUsefulOnTinyPhonesCounts'"),
    );
    expect(
      receiptModels,
      contains("'receiptInstallOptionalPacksRequireConsentCounts'"),
    );
    expect(
      receiptModels,
      contains("'receiptBrainBaseVersusFullOfflineSummaryCounts'"),
    );
    expect(
      receiptModels,
      contains("'receiptRequiredBaseFootprintStatusCounts'"),
    );
    expect(
      receiptModels,
      contains("'receiptRequiredBaseFootprintStatusOutcome'"),
    );
    expect(
      receiptModels,
      contains("'receiptRequiredBaseFootprintCanShipCounts'"),
    );
    expect(
      receiptModels,
      contains("'receiptRequiredBaseFootprintReviewReasonCounts'"),
    );
    expect(
      entryScreen,
      contains('...result.privacySafeReceiptReaderHandoffMetadata'),
    );
    expect(telemetry, contains("'ocrSourcePreparationDecisionCounts'"));
    expect(
      entryScreen,
      contains('onReceiptReadStarted: _markReceiptReadStarted'),
    );
    expect(
      entryScreen,
      contains('onReceiptReadFinished: _markReceiptReadFinished'),
    );
    expect(
      entryScreen,
      contains('onReceiptCaptureDiagnostic: _recordReceiptCaptureDiagnostic'),
    );
    expect(
      entryScreen,
      contains('bool _isNonFailureReceiptCaptureDiagnostic(String reason)'),
    );
    expect(entryScreen, contains("'review_accepted'"));
    expect(entryScreen, contains("'recovery_review_accepted'"));
    expect(entryScreen, contains("'recovery_review_closed'"));
    expect(entryScreen, contains("'user_closed_review'"));
    expect(entryScreen, contains("'user_canceled_before_photo'"));
  });
}
