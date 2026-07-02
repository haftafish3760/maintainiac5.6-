import 'package:flutter_test/flutter_test.dart';

import 'helpers/expense_receipt_assisted_review_source_fixture.dart';

void main() {
  test(
    'assisted receipt review exposes classification and attachment flow',
    () async {
      final source = await readAssistedReviewSourceFixture();
      final entryScreen = source.entryScreen;
      final entryScaffold = source.entryScaffold;
      final stateActions = source.stateActions;
      final attachmentPanel = source.attachmentPanel;
      final attachmentOcr = source.attachmentOcr;
      final recap = source.recap;
      expect(entryScreen, contains('_ReceiptWholeUseReviewPanel'));
      expect(stateActions, contains('_markAllReceiptLines'));
      expect(recap, contains('Classify This Receipt'));
      expect(recap, contains('fieldConfidences: fieldConfidences'));
      expect(
        recap,
        contains('Choose Business, Personal, or Mixed. If it is Mixed'),
      );
      expect(recap, contains('All Business'));
      expect(recap, contains('All Personal'));
      expect(recap, contains('Mixed Receipt'));
      expect(recap, contains('class _ReceiptLineClassificationGuidance'));
      expect(recap, contains('class _ReceiptLineClassificationChecklist'));
      expect(recap, contains('OCR-filled'));
      expect(recap, contains('Check highlighted lines'));
      expect(recap, contains('business/personal totals'));
      expect(recap, contains('set the business percent'));
      expect(recap, contains('line needs'));
      expect(recap, contains('lines need'));
      expect(recap, contains('Use All Business or All Personal'));
      expect(recap, contains('What Maintainiac Found'));
      expect(
        recap,
        contains('Review the store, date, totals, and line confidence'),
      );
      expect(recap, contains('SCANNED RECEIPT REVIEW'));
      expect(recap, contains('STORE NOT FILLED YET'));
      expect(recap, contains("label: 'Subtotal'"));
      expect(recap, contains("label: 'Tax'"));
      expect(recap, contains('Split starts at 50/50'));
      expect(recap, contains('_showLineUseControls'));
      expect(recap, contains('Tap Mixed Receipt above'));
      expect(
        recap,
        contains(
          'Mixed totals include each line share plus allocated sales tax',
        ),
      );
      expect(recap, contains('_ReceiptMixedAllocationReview'));
      expect(recap, contains('MIXED ALLOCATION REVIEW'));
      expect(recap, contains('Business subtotal'));
      expect(recap, contains('Business tax/adjustment'));
      expect(recap, contains('Business final'));
      expect(recap, contains('Personal subtotal'));
      expect(recap, contains('Personal tax/adjustment'));
      expect(recap, contains('Personal final'));
      expect(recap, contains('sales tax, fees, discounts'));
      expect(recap, contains('Returns reduce their side'));
      expect(recap, contains('math.max(0, line.businessAmount)'));
      expect(recap, contains('math.max(0, line.personalAmount)'));
      expect(entryScreen, contains('_businessAdjustmentBase'));
      expect(entryScreen, contains('_personalAdjustmentBase'));
      expect(entryScreen, contains('_receiptAdjustmentBase'));
      expect(entryScreen, contains('math.max(0, line.businessAmount)'));
      expect(entryScreen, contains('math.max(0, line.personalAmount)'));
      expect(recap, contains('_ReceiptLineUseSegment'));
      expect(recap, contains('_ReceiptLineUseChip'));
      expect(recap, contains('allocationDetail'));
      expect(entryScreen, contains('onSetUse: _setReceiptLineUse'));
      expect(entryScreen, contains('String get _receiptDateLabel'));
      expect(entryScreen, contains('String get _receiptStoreAddressLabel'));
      expect(entryScreen, contains('_receiptFilledReviewDecisionLabel'));
      expect(entryScreen, contains('Open receipt details'));
      expect(entryScreen, contains('_receiptFilledReviewActionLabel'));
      expect(
        entryScreen,
        contains('Review store, date, tax, total, item prices'),
      );
      expect(entryScreen, contains('_buildReceiptAttachmentPanel'));
      expect(
        entryScreen,
        contains(
          'final showAttachmentBeforeReview = !_receiptReviewFlowStarted',
        ),
      );
      expect(entryScreen, contains('if (showAttachmentBeforeReview) ...['));
      expect(entryScreen, contains('_shouldShowCollapsedReceiptPhotoRecovery'));
      expect(entryScreen, contains('_ReceiptPhotoRecoveryPanel('));
      expect(entryScreen, contains('_receiptPhotoRecoveryKey'));
      expect(entryScreen, contains('_ocrTotalsEvidenceMissing'));
      expect(entryScreen, contains('_receiptMissingTotalsHandoffActionLabel'));
      expect(
        entryScreen,
        contains('_receiptMissingTotalsCoverageWarningLabel'),
      );
      expect(entryScreen, contains('_receiptMissingTotalsRouteResultLabel'));
      expect(entryScreen, contains('receiptTotalsTextEvidenceStatus'));
      expect(entryScreen, contains('receiptBottomEdgeStatusBuckets'));
      expect(entryScreen, contains('receiptBottomEdgeDetectedBuckets'));
      expect(entryScreen, contains('receiptSubtotalDetectedBuckets'));
      expect(entryScreen, contains('receiptTotalDetectedBuckets'));
      expect(entryScreen, contains('receiptTotalAmountDetectedBuckets'));
      expect(entryScreen, contains('receiptTotalsTextEvidenceStatusBuckets'));
      expect(entryScreen, contains('receiptSectionOrderCounts'));
      expect(entryScreen, contains('receiptSectionOrderOutcome'));
      expect(entryScreen, contains('Subtotal/total lines were not found'));
      expect(stateActions, contains('_receiptReadHandoffDecision'));
      expect(entryScreen, contains('_receiptFilledReviewDecisionLabel'));
      expect(stateActions, contains('_receiptDecisionLabelForParsedReceipt'));
      expect(stateActions, contains('Open manual receipt details'));
      expect(
        entryScaffold.indexOf('_ReceiptClassificationReviewPanel'),
        lessThan(entryScaffold.indexOf('_ReceiptWholeUseReviewPanel')),
      );
      expect(
        entryScaffold.indexOf('_ReceiptWholeUseReviewPanel'),
        lessThan(entryScaffold.indexOf('_ReceiptLineEvidenceReviewPanel')),
      );
      expect(
        entryScaffold.indexOf('_ReceiptLineEvidenceReviewPanel'),
        lessThan(entryScaffold.indexOf('_ReceiptRecapPanel')),
      );
      expect(
        entryScaffold.indexOf('_ReceiptRecapPanel'),
        lessThan(entryScaffold.indexOf('SharedReceiptStorePanel')),
      );
      expect(attachmentPanel, contains('_ReceiptReadReviewStatus'));
      expect(attachmentPanel, contains('this.onReceiptReadStarted'));
      expect(attachmentPanel, contains('this.onReceiptReadFinished'));
      expect(attachmentPanel, contains('this.onReceiptCaptureDiagnostic'));
      expect(attachmentPanel, contains('onReceiptCaptureDiagnostic'));
      expect(attachmentPanel, contains('_notifyReceiptCaptureDiagnostic'));
      expect(attachmentPanel, contains('nativeCaptureFailureStage'));
      expect(attachmentPanel, contains('extraMetadata'));
      expect(entryScreen, contains("reason == 'user_discarded_recovery'"));
      expect(
        entryScreen,
        contains('ExpenseTelemetryEventType.addExpenseAbandoned'),
      );
      expect(
        entryScreen,
        contains('ExpenseTelemetryEventType.imageAttachFailure'),
      );
      expect(entryScreen, contains('nativeRecoveryDiscardedPhotoCount'));
      expect(entryScreen, contains('nativeRecoveryDiscardedMultipleSections'));
      expect(entryScreen, contains('cloudAssistPlanBuckets'));
      expect(entryScreen, contains('localOcrModeBuckets'));
      expect(entryScreen, contains('parserDepthBuckets'));
      expect(entryScreen, contains('cloudOcrOptionalCount'));
      expect(entryScreen, contains('cloudInventoryOptionalCount'));
      expect(
        attachmentPanel,
        contains(
          "'nativeRecoveryEvidence': record.privacySafeRecoveryEvidenceLabel",
        ),
      );
      expect(attachmentOcr, contains('_readingForReview = true'));
      expect(attachmentOcr, contains('widget.onReceiptReadStarted?.call();'));
      expect(
        attachmentOcr,
        contains('widget.onReceiptReadFinished?.call(true);'),
      );
      expect(
        attachmentOcr,
        contains('widget.onReceiptReadFinished?.call(false);'),
      );
      expect(
        attachmentOcr,
        contains(
          r'Preparing $sourceSummary for app assistance. When text is found, Maintainiac shows the receipt details so you can check the store, date, total, and item lines.$cloudAssistSummary',
        ),
      );
      expect(
        attachmentOcr,
        contains(
          'Optional cloud help can be offered later if the user chooses it.',
        ),
      );
      expect(attachmentOcr, contains('capability.cloudAssistPlanFor('));
      expect(
        attachmentOcr,
        contains('cloudAssistedAvailable: cloudAssistPlan.cloudOcrOptional'),
      );
      expect(stateActions, contains('capability.cloudAssistPlanFor('));
      expect(
        stateActions,
        contains('cloudAssistedAvailable: cloudAssistPlan.cloudOcrOptional'),
      );
      expect(attachmentOcr, contains('_receiptReadSourceSummary(readable)'));
      expect(attachmentOcr, contains('_receiptReadRecoveryAdvice(readable)'));
      expect(attachmentOcr, contains('sourceQualityReviewAction'));
      expect(
        attachmentOcr,
        contains('Receipt bottom section still needs capture.'),
      );
      expect(attachmentOcr, contains('Receipt bottom photo needs review.'));
      expect(
        attachmentOcr,
        contains('Receipt photo saved too dark for reliable reading.'),
      );
      expect(
        attachmentOcr,
        contains('Receipt photo may be too soft for reliable reading.'),
      );
      expect(
        attachmentOcr,
        contains(
          r'Receipt assistance could not fill details for $sourceSummary',
        ),
      );
      expect(attachmentOcr, contains('class _ReceiptReadRecoveryAdvice'));
      expect(
        attachmentOcr,
        contains('Receipt photo text was not readable enough.'),
      );
      expect(attachmentOcr, contains('recoveryAdvice.primaryAction'));
      expect(attachmentOcr, contains('recoveryAdvice.shortAction'));
      expect(attachmentOcr, contains('_receiptReadStatusMessage = message;'));
      expect(
        stateActions,
        contains(
          'Receipt filled. Review the store, date, totals, and lines below before saving.',
        ),
      );
      expect(stateActions, contains('ocr.strongestActionMessage'));
      expect(stateActions, contains('_primaryParsedReceiptWarning(parsed)'));
      expect(
        stateActions,
        contains(
          'Receipt fields filled. Classify it as Business, Personal, or Mixed, then review the lines before saving.',
        ),
      );
      expect(
        entryScreen,
        contains('Opening receipt details from accepted photo'),
      );
      expect(entryScreen, contains('onReviewDetails: _scrollToReceiptReview'));
      expect(entryScreen, isNot(contains('Preparing saved receipt photo')));
    },
  );
}
