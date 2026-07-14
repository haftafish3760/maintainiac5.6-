import 'package:flutter_test/flutter_test.dart';

import 'helpers/expense_receipt_assisted_review_source_fixture.dart';

void main() {
  test('assisted receipt review exposes detail mode and save guardrails', () async {
    final source = await readAssistedReviewSourceFixture();
    final entryScreen = source.entryScreen;
    final stateActions = source.stateActions;
    final parseReview = source.parseReview;
    final parseModels = source.parseModels;
    final photoControls = source.photoControls;
    final totals = source.totals;
    expect(entryScreen, contains('receiptContinuationReasonCode:'));
    expect(entryScreen, contains('receiptContinuationGuidance:'));
    expect(
      entryScreen,
      contains('_lastOcrDiagnostics?.receiptCompletionReviewReasonCode'),
    );
    expect(
      entryScreen,
      contains(
        "_lastOcrDiagnostics?.receiptMissingBottomEdgeAndTotals == true",
      ),
    );
    expect(entryScreen, contains('missingBottomEdgeAndTotals:'));
    expect(
      parseReview,
      contains(
        'Your receipt proof is saved. Maintainiac is extracting text and filling receipt details now. Keep this screen open.',
      ),
    );
    expect(parseReview, contains('Receipt Details Ready'));
    expect(
      parseReview,
      contains(
        'Your receipt proof is saved. Maintainiac already prepared receipt details, but this receipt still needs review before saving.',
      ),
    );
    expect(
      parseReview,
      contains(
        'Review the store, date, total, tax, item prices, and Business/Personal/Mixed choices below before saving.',
      ),
    );
    expect(
      parseReview,
      contains('Do not go back unless you want to keep checking the photo.'),
    );
    expect(parseReview, contains('Review What The App Filled In'));
    expect(
      parseReview,
      contains('Check the store, date, total, tax, and item prices.'),
    );
    expect(parseReview, contains('Simple price review'));
    expect(parseReview, contains('Detailed item review'));
    expect(parseReview, contains('Basic receipt review'));
    expect(
      entryScreen,
      contains('var _receiptReviewModeChangedByUser = false;'),
    );
    expect(entryScreen, contains('_receiptReviewModeChangedByUser = true;'));
    expect(parseReview, contains('Price-first review'));
    expect(parseReview, contains('Full-line review'));
    expect(parseReview, contains('Business/Personal/Mixed ready'));
    expect(parseReview, contains('Classify receipt total'));
    expect(parseReview, contains('class _ReceiptReviewNextStepCallout'));
    expect(parseReview, contains('primaryNextStepLabel'));
    expect(
      parseReview,
      contains(
        'Next: add the bottom receipt section before final classification.',
      ),
    );
    expect(
      parseReview,
      contains(
        'Next: use the receipt total as Business or Personal, or add line items manually.',
      ),
    );
    expect(
      parseReview,
      contains(
        'Next: add receipt lines manually or retake/add a clearer receipt photo.',
      ),
    );
    expect(
      parseReview,
      contains(
        'Next: choose All Business, All Personal, or Mixed, then check highlighted lines.',
      ),
    );
    expect(
      parseReview,
      contains(
        'Next: choose All Business, All Personal, or Mixed, then save when totals look right.',
      ),
    );
    expect(parseReview, contains('Material review ready'));
    expect(parseReview, contains('diagnostics?.parserReadinessStatus'));
    expect(parseReview, contains('diagnostics?.pricedLineCount'));
    expect(stateActions, contains('ocrDownstreamReadinessStatus'));
    expect(stateActions, contains('ocrDownstreamReadinessCounts'));
    expect(stateActions, contains('receiptReviewFlowStarted'));
    expect(stateActions, contains('receiptReadHandoffStage'));
    expect(stateActions, contains('receiptReadHandoffAction'));
    expect(stateActions, contains('receiptReadHandoffDecision'));
    expect(stateActions, contains('receiptReadHandoffRouteResult'));
    expect(stateActions, contains('receiptReadHandoffProofCount'));
    expect(stateActions, contains('receiptReadHandoffOcrSourceCount'));
    expect(parseReview, contains('Check highlighted lines'));
    expect(parseReview, contains('No line warnings'));
    expect(parseReview, contains('Receipt reading looked good'));
    expect(parseReview, contains('line.ocrSourceLineLabel'));
    expect(parseReview, contains(r'$sourceLineLabel: $evidence'));
    expect(parseReview, contains('label: sourceLineLabel'));
    expect(parseReview, contains('line.parserExpenseFamilyLabel'));
    expect(parseReview, contains('line.parserHintLabel'));
    expect(parseReview, contains('line.hasOcrSourceLine'));
    expect(parseReview, contains('line.receiptProofLineReferenceLabel'));
    expect(parseReview, contains('proofLineLabel'));
    expect(parseReview, contains(r'$proofLineLabel proof'));
    expect(parseReview, contains('line.clientProofReviewLabel'));
    expect(parseReview, contains('_ReceiptLineEvidenceChip'));
    expect(entryScreen, contains('No Receipt Lines Yet'));
    expect(
      entryScreen,
      contains('void _markReceiptOcrCompleted(ReceiptOcrResult result)'),
    );
    expect(
      entryScreen,
      contains('Map<String, Object> _ocrCompletionReviewMetadata'),
    );
    expect(entryScreen, contains('receiptCompletionReviewReasonCode'));
    expect(entryScreen, contains('receiptCompletionReviewActionLabel'));
    expect(entryScreen, contains('receiptPostCaptureRouteStatus'));
    expect(entryScreen, contains('receiptPostCaptureRouteLabel'));
    expect(entryScreen, contains('_receiptPostCaptureRouteStageLabel'));
    expect(entryScreen, contains('_receiptPostCaptureRouteResultLabel'));
    expect(entryScreen, contains('receiptMayNeedBottomSection'));
    expect(entryScreen, contains('receiptMissingBottomEdgeAndTotals'));
    expect(entryScreen, contains('receiptBottomTotalsEvidenceLabel'));
    expect(entryScreen, contains('ocrSourceBottomCoverageRiskDetected'));
    expect(entryScreen, contains('ocrSourceCoverageSignalCounts'));
    expect(entryScreen, contains('diagnostics.ocrSourceCoverageSignalCounts'));
    expect(entryScreen, contains('ocrSourceContinuationSignalCounts'));
    expect(
      entryScreen,
      contains('diagnostics.ocrSourceContinuationSignalCounts'),
    );
    expect(
      entryScreen,
      contains('if (diagnostics.receiptMissingBottomEdgeAndTotals)'),
    );
    expect(parseModels, contains('ocrSourceCoverageReviewCode'));
    expect(parseModels, contains('ocrSourceCoverageReviewLabel'));
    expect(parseModels, contains('ocrSourceCoverageReviewInstruction'));
    expect(parseModels, contains('ocrSourceCoverageReviewActionLabel'));
    expect(parseModels, contains('ocrPhotoQualityActionReviewCode'));
    expect(parseModels, contains('ocrPhotoQualityActionReviewLabel'));
    expect(parseModels, contains('ocrPhotoQualityActionReviewInstruction'));
    expect(parseModels, contains('ocrPhotoQualityActionReviewActionLabel'));
    expect(parseModels, contains('Add bottom receipt section first'));
    expect(parseModels, contains('Retake recommended'));
    expect(parseModels, contains('Crop or retake photo'));
    expect(parseModels, contains('ocrSourceContinuationSignalCounts'));
    expect(parseModels, contains('ocrSourceContinuationReviewCode'));
    expect(parseModels, contains('ocrSourceContinuationReviewLabel'));
    expect(parseModels, contains('ocrSourceContinuationReviewInstruction'));
    expect(parseModels, contains('ocrSourceContinuationReviewActionLabel'));
    expect(parseModels, contains('missingBottomTotalsEvidenceCode'));
    expect(parseModels, contains('missingBottomTotalsEvidenceLabel'));
    expect(parseModels, contains('missingBottomTotalsEvidenceFamilyCount'));
    expect(
      parseModels,
      contains('missingBottomTotalsLocalEvidenceReviewLabel'),
    );
    expect(parseModels, contains('Bottom edge and totals missing'));
    expect(parseModels, contains('Bottom continuation uses top ghost slice'));
    expect(
      parseModels,
      contains('Add the bottom receipt section with the top ghost-slice guide'),
    );
    expect(parseReview, contains('hasOcrSourceMissingBottomCoverageEvidence'));
    expect(parseReview, contains('hasOcrSourceBottomOverlapGhostContinuation'));
    expect(parseReview, contains('ocrSourceCoverageReviewInstruction'));
    expect(parseReview, contains('ocrSourceCoverageReviewActionLabel'));
    expect(parseReview, contains('ocrPhotoQualityActionReviewLabel'));
    expect(parseReview, contains('ocrPhotoQualityActionReviewInstruction'));
    expect(parseReview, contains('ocrPhotoQualityActionReviewActionLabel'));
    expect(parseReview, contains('ocrSourceContinuationReviewInstruction'));
    expect(parseReview, contains('ocrSourceContinuationReviewActionLabel'));
    expect(parseReview, contains('missingBottomTotalsEvidenceLabel'));
    expect(parseReview, contains('coverageReviewLabel'));
    expect(parseReview, contains('ocrSourceGhostSliceAlignmentStatus'));
    expect(entryScreen, contains('receiptSubtotalCandidateLineCount'));
    expect(entryScreen, contains('receiptTotalCandidateLineCount'));
    expect(
      entryScreen,
      contains('onReceiptOcrCompleted: _markReceiptOcrCompleted'),
    );
    expect(
      stateActions,
      contains('parseExpenseReceiptOcrResultWithLocalMemory'),
    );
    expect(
      stateActions,
      contains('_ocrCompletionReviewMetadata(ocr.diagnostics)'),
    );
    expect(
      stateActions,
      contains('ocr.diagnostics.receiptMayNeedBottomSection'),
    );
    expect(stateActions, contains('ocrSourceContinuationSignalCounts'));
    expect(
      stateActions,
      contains('result.diagnostics.ocrSourceContinuationSignalCounts'),
    );
    expect(
      stateActions,
      contains('ocr.diagnostics.receiptPostCaptureRouteStatus'),
    );
    expect(
      stateActions,
      contains('_receiptPostCaptureRouteStageLabel(ocr.diagnostics)'),
    );
    expect(
      stateActions,
      contains(
        '_receiptPostCaptureRouteResultLabel(\n          ocr.diagnostics',
      ),
    );
    expect(entryScreen, contains('Receipt details need next section'));
    expect(entryScreen, contains('Receipt details need store check'));
    expect(
      entryScreen,
      contains('_receiptMissingBottomEdgeAndTotalsRouteResultLabel'),
    );
    expect(
      entryScreen,
      contains('Receipt details are waiting on the bottom receipt section'),
    );
    expect(entryScreen, contains('Receipt details need a bottom check'));
    expect(entryScreen, contains('Receipt details need bottom check'));
    expect(
      stateActions,
      contains('ocr.diagnostics.receiptMissingBottomEdgeAndTotals'),
    );
    expect(
      stateActions,
      contains('_receiptMissingBottomEdgeAndTotalsRouteResultLabel'),
    );
    expect(
      entryScreen,
      contains(
        'final missingBottomEdgeAndTotals =\n'
        '            diagnostics?.receiptMissingBottomEdgeAndTotals == true;',
      ),
    );
    expect(
      entryScreen,
      contains("_receiptReadHandoffDecision = 'Add bottom receipt section';"),
    );
    expect(
      entryScreen,
      contains(
        "_receiptReadHandoffStage = 'Receipt details need bottom section';",
      ),
    );
    expect(
      stateActions,
      contains('parsed = _withReceiptBrainHandoffDiagnostics'),
    );
    expect(stateActions, contains('receiptBrainLowStorageDownloadRiskCounts'));
    expect(
      stateActions,
      contains('receiptBrainFullOfflineMustStayOptionalCounts'),
    );
    expect(
      stateActions,
      contains('receiptBrainFullOfflineExceedsBaseGuardrailCounts'),
    );
    expect(stateActions, contains('receiptInstallRequiredSegmentCounts'));
    expect(stateActions, contains('receiptInstallFullOfflineSegmentCounts'));
    expect(stateActions, contains('receiptInstallLowStorageImpactCounts'));
    expect(
      stateActions,
      contains('receiptInstallRecommendedDistributionCounts'),
    );
    expect(stateActions, contains('receiptInstallCameraShellParserFreeCounts'));
    expect(
      stateActions,
      contains('receiptInstallBaseUsefulOnTinyPhonesCounts'),
    );
    expect(
      stateActions,
      contains('receiptInstallOptionalPacksRequireConsentCounts'),
    );
    expect(parseModels, contains('receiptInstallFootprintSummaryLabel'));
    expect(parseModels, contains('receiptInstallFootprintOutcome'));
    expect(
      stateActions,
      contains('void _applyDefaultReviewModeForParsedReceipt'),
    );
    expect(stateActions, contains('_receiptReviewModeChangedByUser'));
    expect(stateActions, contains('diagnostics.hasOcrInventoryPrepSignals'));
    expect(
      stateActions,
      contains('_detailEntryMode = _ReceiptDetailEntryMode.detailedItems;'),
    );
    expect(stateActions, contains('localParserScope'));
    expect(entryScreen, contains('String get _receiptNoLineTitleLabel'));
    expect(entryScreen, contains('String get _receiptNoLineSubtitleLabel'));
    expect(entryScreen, contains('String get _receiptNoLineReasonLabel'));
    expect(entryScreen, contains('String get _receiptNoLineNextStepLabel'));
    expect(entryScreen, contains('String get _receiptNoLineOcrOutcomeLabel'));
    expect(
      entryScreen,
      contains('String get _receiptNoLineParserOutcomeLabel'),
    );
    expect(
      entryScreen,
      contains('ReceiptOcrWarning? get _primaryNoLineOcrWarning'),
    );
    expect(entryScreen, contains('Opening Receipt Details'));
    expect(entryScreen, contains('No Readable Receipt Text'));
    expect(entryScreen, contains('Receipt Text Found, Lines Need Help'));
    expect(entryScreen, contains('Receipt Reading'));
    expect(entryScreen, contains('Receipt Details'));
    expect(entryScreen, contains('What Happened'));
    expect(entryScreen, contains('Next Step'));
    expect(entryScreen, contains('warning.actionLabel'));
    expect(entryScreen, contains('ReceiptOcrWarning.compareByPriority'));
    expect(
      entryScreen,
      contains(r'Needs manual review: ${primaryWarning.label}'),
    );
    expect(parseReview, contains('maxLines: 2'));
    expect(entryScreen, contains('Add Line Manually'));
    expect(entryScreen, contains('_addReceiptTotalLine'));
    expect(entryScreen, contains('Use Total As Business'));
    expect(entryScreen, contains('Use Total As Personal'));
    expect(entryScreen, contains("label: 'Split Total'"));
    expect(
      entryScreen,
      contains('_detailEntryMode != _ReceiptDetailEntryMode.quickClassify'),
    );
    expect(
      entryScreen,
      contains('_detailEntryMode == _ReceiptDetailEntryMode.detailedItems'),
    );
    expect(entryScreen, contains("'Review item lines': review"));
    expect(entryScreen, contains("'Check material matches': review"));
    expect(
      entryScreen,
      contains(
        'Receipt text was found, but item lines still need review. Use the receipt total if that is enough, or add lines manually.',
      ),
    );
    expect(entryScreen, contains('Item lines need review'));
    expect(
      photoControls,
      contains(
        'Photo match will use ordered sections from top to bottom because stitching was not safe enough.',
      ),
    );
    expect(parseReview, contains('_ReceiptNoLineRecoveryChip'));
    expect(parseReview, contains('_ReceiptFieldConfidenceRow'));
    expect(parseReview, contains('Fields to check'));
    expect(parseReview, contains("'receiptMath' => 'Receipt math'"));
    expect(parseReview, contains("'lineItems' => 'Line items'"));
    expect(totals, contains('splitPercentIssueCount'));
    expect(totals, contains('One mixed line needs a business percent.'));
    expect(totals, contains('mixed lines need business percents.'));
    expect(entryScreen, contains('splitPercentIssueCount'));
    expect(entryScreen, contains('_splitLinesMissingBusinessPercentCount'));
    expect(entryScreen, contains('line.businessPercent! < 0'));
    expect(entryScreen, contains('line.businessPercent! > 1'));
  });
}
