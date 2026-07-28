import 'package:flutter_test/flutter_test.dart';

import 'helpers/expense_receipt_assisted_review_source_fixture.dart';

void main() {
  test('assisted receipt review exposes handoff and install metadata', () async {
    final source = await readAssistedReviewSourceFixture();
    final entryScreen = source.entryScreen;
    final stateActions = source.stateActions;
    final attachmentPanel = source.attachmentPanel;
    final attachmentOcr = source.attachmentOcr;
    final importActions = source.importActions;
    final parseReview = source.parseReview;
    final parseModels = source.parseModels;
    final receiptModels = source.receiptModels;
    final telemetry = source.telemetry;
    expect(entryScreen, contains('processingInFlight: _scanningReceiptPhotos'));
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
      contains("_receiptReadHandoffDecision = 'Reading receipt'"),
    );
    expect(
      entryScreen,
      isNot(
        contains('_receiptReadHandoffDecision = result.nextReviewHandoffLabel'),
      ),
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
        '_receiptReadHandoffRouteResult =\n          \'Accepted photo review is moving directly into receipt details.',
      ),
    );
    expect(
      entryScreen,
      contains('onReceiptPhotoReviewAccepted: _markReceiptPhotoReviewAccepted'),
    );
    expect(
      entryScreen,
      contains(
        '_scanningReceiptPhotos = false;\n      _receiptReviewFlowStarted = true;',
      ),
    );
    expect(
      entryScreen,
      contains(
        'onReceiptOcrResultForReview: _parseReceiptOcrResultFromCapture',
      ),
    );
    expect(
      entryScreen,
      contains('Future<void> _parseReceiptOcrResultFromCapture('),
    );
    expect(entryScreen, contains('ocr.appFillText.trim().isEmpty'));
    expect(entryScreen, contains("receipt_ocr_no_usable_text"));
    expect(entryScreen, contains('ocr_result_app_fill_text_empty'));
    expect(
      entryScreen,
      contains('final handoff = ReceiptOcrHandoff.forUserSelection('),
    );
    expect(
      entryScreen,
      contains('onExpensePrepared: (prepared) => preparedExpenseReview'),
    );
    expect(entryScreen, contains(').dispatch(handoff)'));
    expect(
      entryScreen,
      contains('prepareGenericExpenseReceiptOcrReviewInWorker'),
    );
    expect(entryScreen, contains('parserDepth: ReceiptParserDepth.lineItems'));
    expect(entryScreen, contains('maxCatalogCandidates: 0'));
    expect(
      attachmentOcr,
      contains(
        'final onOcrResultForReview = widget.onReceiptOcrResultForReview;',
      ),
    );
    expect(
      attachmentOcr,
      contains(
        '? onOcrResultForReview(result, traceId)\n              : onImportedText!(result.appFillText)',
      ),
    );
    final acceptedPhotoStatus = attachmentPanel.substring(
      attachmentPanel.indexOf('void _startReviewedPhotoReadStatus('),
      attachmentPanel.indexOf('bool _pauseReviewedPhotoReadUntilNextSection('),
    );
    expect(
      acceptedPhotoStatus,
      isNot(contains('widget.onReceiptReadStarted?.call();')),
    );
    expect(
      entryScreen,
      isNot(
        contains(
          '_receiptReadHandoffRouteResult =\n          result.acceptedPhotoHandoffRouteResultLabel',
        ),
      ),
    );
    expect(parseReview, contains('final stage = stageLabel.trim();'));
    expect(parseReview, contains('Extracting Receipt Information'));
    expect(parseReview, contains('LinearProgressIndicator'));
    expect(parseReview, contains(r'Step $currentStep of'));
    expect(parseReview, contains("'Reading receipt'"));
    expect(parseReview, contains("'Preparing details'"));
    expect(parseReview, contains("'Opening review'"));
    expect(parseReview, contains('final opacity = isCurrent'));
    expect(parseReview, contains('opacity: opacity'));
    expect(parseReview, contains('0.68'));
    expect(parseReview, contains('0.42'));
    expect(parseReview, contains(".contains('bottom')"));
    expect(parseReview, contains(".contains('manual')"));
    expect(parseReview, contains('photoActionLabel: needsBottom'));
    expect(parseReview, contains("'Add Bottom Section'"));
    expect(parseReview, contains("'Retake / Add Photo'"));
    expect(parseReview, contains("'Open Receipt Form'"));
    expect(parseReview, isNot(contains("const Text('Add / Retake')")));
    expect(parseReview, contains('if (!processingInFlight)'));
    expect(parseReview, contains('onPressed: onReviewDetails'));
    expect(
      parseReview,
      contains("status: stage.isEmpty ? 'Reading receipt text' : stage"),
    );
    expect(
      entryScreen,
      contains(
        'Extracting text from the accepted receipt photo. Receipt details will appear here automatically when the reader finishes.',
      ),
    );
    expect(
      entryScreen,
      isNot(
        contains(
          '_receiptReadHandoffAction = result.acceptedPhotoHandoffActionLabel',
        ),
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
      contains('Maintainiac reads the clearest receipt photo first'),
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
