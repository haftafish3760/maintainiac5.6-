import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_camera_capture_layout_source_readers.dart';

void main() {
  test('receipt photo back protects captured images from silent discard', () async {
    final saveActions = await readReceiptPhotoReviewSaveActionsSource();
    final reviewScreen = await readReceiptPhotoReviewScreenSource();
    final models = await readReceiptCaptureModelsSource();

    expect(reviewScreen, contains('enum _ReceiptReviewExitAction'));
    expect(reviewScreen, contains('Return To Receipt Entry'));
    expect(reviewScreen, isNot(contains('Back To Receipt Form')));
    expect(saveActions, contains('_confirmReceiptReviewExit'));
    expect(saveActions, contains('final navigator = Navigator.of(context);'));
    expect(
      saveActions,
      contains('_coverageDecisionForPhotoPath(_photoPaths[selected])'),
    );
    expect(reviewScreen, contains('continueReceiptPhotoReview'));
    expect(saveActions, contains('_selectedExitCoverageDecision()'));
    expect(saveActions, contains("return 'Add Bottom Section';"));
    expect(
      saveActions,
      contains("widget.uiConfig.labelFor(\n      'continue',\n      widget.uiConfig.useReceiptLabel"),
    );
    expect(saveActions, contains('decision.shouldPromptForMorePhotos'));
    expect(
      saveActions,
      contains(
        r'Tap $nextLabel to add the bottom receipt section with the top ghost-slice guide',
      ),
    );
    expect(
      saveActions,
      contains(r'Tap $nextLabel only if this already shows the full receipt'),
    );
    expect(saveActions, contains('ReceiptPhotoReviewResult.keptForLater'));
    expect(
      saveActions,
      contains('_captureDiagnosticsWithReceiptBrainDefaults'),
    );
    expect(
      saveActions,
      contains('_defaultReceiptBrainDiagnosticsForReviewPhoto'),
    );
    expect(saveActions, contains('receiptBrainFootprintSummaryFor'));
    expect(saveActions, contains('...footprint.toPrivacySafeDiagnostics()'));
    expect(saveActions, contains('receiptBrainDiagnosticsSource'));
    expect(saveActions, contains('receipt_photo_review_default_local_policy'));
    expect(saveActions, contains('if (!beginReceiptReviewClose()) return;'));
    expect(saveActions, contains('navigator.pop(keptForLaterResult);'));
    expect(saveActions, contains('bool beginReceiptReviewClose()'));
    expect(
      saveActions,
      contains(
        'if (!mounted || _reviewDisposed || _closingReview) return false;',
      ),
    );
    expect(saveActions, contains('const _PickedReceiptPhotos.canceled()'));
    expect(saveActions, contains('if (nativePicked.wasCanceled)'));
    final emptyRecoveryLayout = reviewScreen.substring(
      reviewScreen.indexOf('Widget _buildEmptyReviewRecovery()'),
      reviewScreen.indexOf('Widget _buildPhotoSurface'),
    );
    expect(emptyRecoveryLayout, contains('return PopScope('));
    expect(emptyRecoveryLayout, contains('canPop: false'));
    expect(
      emptyRecoveryLayout,
      contains('if (!didPop) leaveReceiptReviewWithoutSaving();'),
    );
    expect(emptyRecoveryLayout, contains('Return To Receipt Entry'));
    expect(saveActions, contains('Review receipt details from this photo?'));
    expect(saveActions, contains('Review receipt details from these photos?'));
    expect(saveActions, contains('saved locally for recovery'));
    expect(saveActions, contains('Receipt details have not been filled yet.'));
    expect(
      saveActions,
      contains(
        'This receipt photo is saved locally for recovery and will not be deleted, but receipt details have not been opened from it yet.',
      ),
    );
    expect(
      saveActions,
      contains(
        'These receipt photos are saved locally for recovery and will not be deleted, but receipt details have not been opened from them yet.',
      ),
    );
    expect(saveActions, contains('_isRecoverableReviewPhoto'));
    expect(
      saveActions,
      contains(
        r"return 'Tap $nextLabel to use $target and open receipt details. $saveWithoutFilling';",
      ),
    );
    expect(
      saveActions,
      contains(
        'final target = hasMultipleSections ? \'the ordered photos\' : \'this photo\';',
      ),
    );
    expect(saveActions, contains('Save Photo Without Filling'));
    expect(saveActions, contains('Save Photos Without Filling'));
    expect(saveActions, isNot(contains('Save Photo For Later')));
    expect(saveActions, isNot(contains('Save Photos For Later')));
    expect(saveActions, isNot(contains('Keep Photo Saved For Later')));
    expect(saveActions, isNot(contains('Keep Photos Saved For Later')));
    expect(
      saveActions,
      contains(
        'final hasEditedReviewPhotos = _photoPaths.any(_generatedEditPaths.contains)',
      ),
    );
    final reviewDispose = reviewScreen.substring(
      reviewScreen.indexOf('@override\n  void dispose()'),
      reviewScreen.indexOf('@override\n  Widget build(BuildContext context)'),
    );
    expect(
      reviewDispose,
      contains('unawaited(_deleteGeneratedEditPhotos(_photoPaths.toSet()));'),
    );
    expect(
      reviewDispose,
      isNot(contains('unawaited(_deleteGeneratedEditPhotos(const {}));')),
    );
    expect(
      saveActions,
      contains(
        'Edited crop/rotation copies currently shown here will also be kept for this review.',
      ),
    );
    expect(saveActions, isNot(contains('Leave Without Reading')));
    expect(saveActions, isNot(contains('Leave Unattached')));
    expect(saveActions, isNot(contains('Delete Staged Photo')));
    expect(saveActions, isNot(contains('Delete Staged Photos')));
    final staging = await readReceiptNativeCaptureStagingSource();
    expect(staging, contains('Done was pressed after photos were captured.'));
    expect(staging, contains('Done was pressed before a photo was saved.'));
    expect(staging, isNot(contains('Next was pressed')));
    expect(saveActions, contains('Back to Photos'));
    expect(saveActions, isNot(contains('Stay In Review')));
    expect(saveActions, contains('Text(nextLabel)'));
    expect(saveActions, contains('_selectedExitCoverageDecision()'));
    expect(models, contains('1 clear combined receipt image'));
    expect(models, contains('clear ordered receipt sections'));
    expect(
      saveActions,
      contains('if (_closingReview || _confirmingReviewExit) return;'),
    );
    expect(saveActions, contains("if (_openingCamera) {"));
    expect(
      saveActions,
      contains("_showCameraError('Camera is opening. Wait a moment.');"),
    );
    expect(saveActions, contains("if (_savingPhotos) {"));
    expect(
      saveActions,
      contains(
        "_showCameraError('Receipt photo is being prepared. Wait a moment.');",
      ),
    );
    expect(saveActions, contains("if (_cropProcessing) {"));
    expect(
      saveActions,
      contains(
        "_showCameraError('Finish or cancel crop before leaving this review.');",
      ),
    );
    expect(
      saveActions,
      contains(
        'if (!_reviewWorkActive ||\n        action == _ReceiptReviewExitAction.keepReviewing) {',
      ),
    );
  });

  test('possible partial receipt records decision without a second prompt', () async {
    final reviewScreen = await readReceiptPhotoReviewScreenSource();
    final saveActions = await readReceiptPhotoReviewSaveActionsSource();
    final completionActions = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_completion_actions.dart',
    ).readAsString();
    final controls = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_primary_row.dart',
    ).readAsString();

    expect(
      reviewScreen,
      contains(
        'enum _ReceiptContinueDecision { keepReviewing, addNextSection, continueAnyway }',
      ),
    );
    expect(reviewScreen, contains('_completionPromptedPhotoPaths'));
    expect(completionActions, contains('_confirmReceiptCompleteIfNeeded'));
    expect(
      completionActions,
      contains('String? get _completionCheckPhotoPath'),
    );
    expect(completionActions, contains('return _photoPaths.last;'));
    expect(
      completionActions,
      isNot(contains('_showSinglePhotoCompletionDialog')),
    );
    expect(
      completionActions,
      isNot(
        contains(
          '_completionPromptedPhotoPaths.add(photoPath);\n    final userDecision',
        ),
      ),
    );
    expect(
      completionActions,
      contains(
        '_completionPromptedPhotoPaths.add(photoPath);\n    _recordReceiptCompletionDecision(',
      ),
    );
    expect(
      completionActions,
      contains('decision: _ReceiptContinueDecision.continueAnyway'),
    );
    expect(
      saveActions.indexOf('await _confirmReceiptCompleteIfNeeded()'),
      lessThan(saveActions.indexOf('if (_needsStitchReviewBeforeSave)')),
    );
    expect(completionActions, contains('decision.shouldPromptForMorePhotos'));
    expect(
      completionActions,
      isNot(contains('decision.completionDialogTitle')),
    );
    expect(
      completionActions,
      isNot(contains('decision.continueAnywayButtonLabel')),
    );
    expect(saveActions, isNot(contains('Next: Review Details')));
    expect(
      completionActions,
      isNot(contains('decision.addSectionButtonLabel')),
    );
    expect(controls, contains("'Add Bottom Section'"));
    expect(controls, contains('uiConfig.addPhotoLabel'));
    final models = await readReceiptCaptureModelsSource();
    expect(models, contains('Add the bottom of this receipt?'));
    expect(models, contains('Add Bottom Section'));
    expect(completionActions, isNot(contains('Back to Photos')));
    expect(saveActions, isNot(contains('Stay In Review')));
    expect(
      completionActions,
      isNot(contains('await addAnotherReceiptPhoto();')),
    );
    expect(
      completionActions,
      contains('return _ReceiptContinueDecision.continueAnyway;'),
    );
  });

  test('long receipt stitch review shows plain decision evidence', () async {
    final orderControls = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_order_controls.dart',
    ).readAsString();
    final commonControls = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_common_controls.dart',
    ).readAsString();
    final stitchControls =
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_controls.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_readiness.dart',
        ).readAsString();
    final models = await readReceiptCaptureModelsSource();

    expect(models, contains('String get matchConfidenceLabel'));
    expect(models, contains('String get reviewPathLabel'));
    expect(models, contains('String get reviewDecisionLabel'));
    expect(models, contains('String get ocrHandoffChecklistLabel'));
    expect(models, contains('String get overlapExpectationLabel'));
    expect(models, contains('stitchPairDiagnosticCounts'));
    expect(models, contains('pair.diagnosticCode'));
    expect(models, contains(r'fallback_$reason'));
    expect(models, contains('String get userFallbackReasonLabel'));
    expect(models, contains('Overlap was not clear enough'));
    expect(models, contains('Receipt is too long for this device'));
    expect(models, contains('1 combined receipt image'));
    expect(models, contains('receipt sections top to bottom'));
    expect(models, contains('make sure no middle section is missing'));
    expect(models, contains('Repeat 3-5 readable lines between sections'));
    expect(orderControls, contains('Receipt details open in this order.'));
    expect(stitchControls, contains("'Combined Receipt Ready'"));
    expect(stitchControls, contains("'Safe Fallback Ready'"));
    expect(stitchControls, contains('repeated receipt lines match safely'));
    expect(
      stitchControls,
      contains(
        'For bottom-section photos, keep 3-5 repeated readable lines in the top ghost slice',
      ),
    );
    expect(stitchControls, contains('Repeated receipt lines matched safely'));
    expect(stitchControls, contains('preview.userFallbackReasonLabel'));
    expect(stitchControls, contains('preview.ocrHandoffChecklistLabel'));
    expect(stitchControls, contains('preview.overlapExpectationLabel'));
    final reviewScreen = await readReceiptPhotoReviewScreenSource();
    expect(
      reviewScreen,
      contains('Line up 3-5 repeated readable receipt lines'),
    );
    expect(reviewScreen, contains('match guide'));
    expect(stitchControls, contains('Previous Pair'));
    expect(stitchControls, contains('Next Pair'));
    expect(stitchControls, contains('selectedPair.matchEvidenceLabel'));
    expect(
      stitchControls,
      contains("final fallbackRecoveryLabel = failedPairLabel.isEmpty"),
    );
    expect(stitchControls, contains("'Fix Photo Order'"));
    expect(stitchControls, contains("'Fix \$failedPairLabel'"));
    expect(commonControls, contains('_ReceiptLocalPhotoLimitStrip'));
    expect(
      commonControls,
      contains('You can still use these photos, but review '),
    );
    expect(commonControls, contains('every line before saving.'));
    expect(
      stitchControls,
      contains('You can still use each section in top-to-bottom order.'),
    );
  });

  test('reviewed receipt photos announce app fill handoff safely', () async {
    final importActions = await readReceiptAttachmentImportActionsSource();
    final ocrActions =
        await File(
          'lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_attachment_ocr_recovery_advice.dart',
        ).readAsString();
    final models = await readReceiptCaptureModelsSource();
    final panel = await readReceiptAttachmentPanelSource();

    expect(importActions, contains('_startReviewedPhotoReadStatus(result);'));
    expect(importActions, contains('_nextReceiptContinuationReasonCode()'));
    expect(importActions, contains('_nextReceiptContinuationGuidance()'));
    expect(importActions, contains('_nextReceiptForceLongReceiptMode()'));
    expect(importActions, contains('_nextReceiptForceAutoCapture(settings)'));
    expect(importActions, contains("return 'missing_bottom_edge_and_totals';"));
    expect(
      importActions,
      contains('if (_needsBottomReceiptSection) return true;'),
    );
    expect(
      importActions,
      contains('if (_needsBottomReceiptSection) return false;'),
    );
    expect(
      importActions,
      contains('_pauseReviewedPhotoReadUntilNextSection(result)'),
    );
    expect(
      importActions,
      contains(
        'Future<_ReceiptAttachmentReadResult> _readReviewedPhotosForReceiptForm',
      ),
    );
    expect(importActions, contains('_ReceiptAttachmentReadOutcome.skipped'));
    expect(importActions, contains('receiptPhotoReviewPausedBeforeOcr'));
    expect(
      importActions,
      contains(
        'Receipt photo saved. Add the bottom receipt section before receipt details open.',
      ),
    );
    expect(
      importActions,
      contains('result.finalReceiptSectionContinuationEvidenceLabel'),
    );
    expect(models, contains('String get savedProofCountLabel'));
    expect(models, contains('String get ocrSourceCountLabel'));
    expect(models, contains('String get nextReviewHandoffLabel'));
    expect(models, contains('String get nextReviewDiagnosticLabel'));
    expect(importActions, contains('result.nextReviewHandoffLabel'));
    expect(importActions, contains('result.acceptedPhotoHandoffActionLabel'));
    expect(models, contains('String get privacySafeOcrHandoffEvidenceLabel'));
    expect(models, contains('1 saved proof photo'));
    expect(models, contains('combined receipt image'));
    expect(
      importActions,
      contains(
        r'Photo review accepted. $processing $proofCount ready. Clear photo versions: $ocrSourceCount. $qualitySummary $reviewDecision $action',
      ),
    );
    expect(importActions, isNot(contains('Read receipt')));
    expect(importActions, isNot(contains('Evidence:')));
    expect(panel, contains('Opening Receipt Details'));
    expect(panel, contains('_needsBottomReceiptSection'));
    expect(panel, contains('Add Bottom Section'));
    expect(panel, contains('Icons.vertical_align_bottom_rounded'));
    expect(panel, contains('? () => unawaited(takeReceiptPhoto())'));
    expect(
      panel,
      contains(
        'The filled receipt details appear here as soon as the photo is read.',
      ),
    );
    expect(
      importActions,
      isNot(
        contains(
          'Reading \$ocrSourceCount before the smaller saved proof copy is used for storage',
        ),
      ),
    );
    expect(
      importActions,
      contains('String _reviewedPhotoOcrSourceQualitySummary('),
    );
    expect(importActions, contains('Photo quality'));
    expect(importActions, contains('may need review'));
    expect(
      importActions,
      contains(
        r'Receipt proof saved: ${result.savedProofCountLabel}. No clear photo version was available to fill the receipt details.',
      ),
    );
    expect(
      importActions.indexOf('_startReviewedPhotoReadStatus(result);'),
      lessThan(
        importActions.indexOf('await _readReviewedPhotosForReceiptForm'),
      ),
    );
    expect(ocrActions, contains('String _receiptReadSourceSummary'));
    expect(ocrActions, contains('class _ReceiptReadRecoveryAdvice'));
    expect(
      ocrActions,
      contains(
        r'Reading $sourceSummary. When the details are ready, Maintainiac shows them so you can check the store, date, total, and item lines.',
      ),
    );
    expect(ocrActions, contains('await Future<void>.sync('));
  });
}
