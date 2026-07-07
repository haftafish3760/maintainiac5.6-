import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_long_guidance_sources.dart';

void main() {
  test('receipt capture keeps long receipt and photo review guidance', () async {
    final sources = await readReceiptLongGuidanceSources();

    expect(sources.reviewControls, isNot(contains('Move Earlier')));
    expect(sources.reviewControls, isNot(contains('Move Later')));
    expect(sources.reviewPreviewControls, contains('Match Photos'));
    expect(sources.modeControls, contains('Photo Order'));
    expect(sources.modeControls, contains('Check Photo Order'));
    expect(sources.orderControls, contains('_ReceiptOrderToolControls'));
    expect(sources.modeControls, contains('_ReceiptToolModeHeader'));
    expect(
      sources.modeControls,
      contains('Photo 1 is the top; each next photo continues lower.'),
    );
    expect(
      sources.orderControls,
      contains('_ReceiptPhotoSectionLabels.moveEarlierLabel'),
    );
    expect(
      sources.orderControls,
      contains('_ReceiptPhotoSectionLabels.moveLaterLabel'),
    );
    expect(
      sources.orderControls,
      contains('_ReceiptPhotoSectionLabels.addNextPhotoLabel'),
    );
    expect(
      sources.orderControls,
      contains('_ReceiptPhotoSectionLabels.retakeLabel'),
    );
    expect(sources.orderControls, contains('retakeSemanticLabel'));
    expect(sources.sectionLabels, contains('Retake keeps this spot'));
    expect(sources.sectionLabels, contains('Add Next Receipt Photo'));
    expect(sources.sectionLabels, contains('Retake Section'));
    expect(
      sources.sectionLabels,
      contains(r'Retake $section, the bottom receipt photo'),
    );
    expect(sources.modeControls, contains('Preview'));
    expect(sources.stitchControls, contains('Manual match'));
    expect(
      sources.stitchControls,
      contains('Line up the repeated receipt text'),
    );
    expect(sources.stitchControls, contains('Previous Pair'));
    expect(sources.stitchControls, contains('Next Pair'));
    expect(
      sources.stitchControls,
      contains(r'Sections ${pairIndex + 1}-${pairIndex + 2}'),
    );
    expect(
      sources.stitchControls,
      contains(r'Bottom of section ${pairIndex + 1}'),
    );
    expect(
      sources.stitchControls,
      contains(r'Top of section ${pairIndex + 2}'),
    );
    expect(sources.stitchControls, contains('Combined Receipt Ready'));
    expect(sources.stitchControls, contains('Safe Fallback Ready'));
    expect(sources.modeControls, contains('Long Receipt Match'));
    expect(sources.modeControls, contains("label: 'Match Photos'"));
    expect(
      sources.reviewControls,
      contains(
        "return photoPaths.length > 1 ? 'Check Photo Match' : 'Use Photo';",
      ),
    );
    expect(sources.reviewControls, contains('waitingForStitch'));
    expect(sources.reviewControls, contains('continueEnabled'));
    expect(
      sources.reviewControls,
      contains("return photoPaths.length == 1 ? 'Use Photo' : 'Use Photos';"),
    );
    expect(
      sources.reviewControls,
      isNot(contains('Choose The Best Receipt Photo')),
    );
    expect(sources.reviewControls, isNot(contains('Use This Photo')));
    expect(sources.reviewActions, contains('_needsStitchReviewBeforeSave'));
    expect(
      sources.reviewActions,
      contains('_reviewMode = _ReceiptReviewMode.stitch'),
    );
    expect(
      sources.reviewActions,
      contains('ReceiptImagePicker.takeBackupReceiptPhotoSet()'),
    );
    expect(sources.reviewActions, contains('fromPhoneCameraBackupPaths'));
    expect(
      sources.reviewActions,
      contains('phone_camera_backup_receipt_photo'),
    );
    expect(
      sources.reviewActions,
      contains('Opening the phone camera as backup capture'),
    );
    expect(sources.reviewActions, contains('_showLongReceiptAlignmentGuide'));
    expect(sources.reviewActions, contains('alignmentReasonCode:'));
    expect(sources.reviewActions, contains('alignmentGuidance:'));
    expect(
      sources.captureActions,
      contains('final targetPhotoPath = _photoPaths[_selectedIndex]'),
    );
    expect(
      sources.captureActions,
      contains(
        'final retakeContext = ReceiptPhotoRetakeAlignmentContext.build(',
      ),
    );
    expect(sources.captureActions, contains('previousSectionGuidePhotoPath'));
    expect(sources.captureActions, contains('preferredGuidePhotoPath'));
    expect(sources.captureActions, contains('alignmentReasonCode:'));
    expect(sources.captureActions, contains('retakeContext?.guidanceCode'));
    expect(sources.captureActions, contains('alignmentGuidance:'));
    expect(sources.captureActions, contains('retakeContext?.guidanceText'));
    expect(sources.captureActions, contains('previousSectionReasonCode:'));
    expect(sources.captureActions, contains('previousSectionGuidance:'));
    expect(
      sources.captureActions,
      contains('final retakePlan = ReceiptPhotoRetakeOrderPlan.build('),
    );
    expect(
      sources.reviewActions,
      contains('final movePlan = ReceiptPhotoMoveOrderPlan.build('),
    );
    expect(
      sources.captureActions,
      contains('_selectedIndex = retakePlan.selectedIndex'),
    );
    expect(sources.captureActions, contains('_replaceCurrentPhotoPath('));
    expect(sources.captureActions, contains('..addAll(retakePlan.photoPaths)'));
    expect(
      sources.captureActions,
      contains('captureDiagnosticsForReplacementPaths'),
    );
    expect(
      sources.captureActions,
      contains('captureDiagnosticsForInsertedPhotoPaths'),
    );
    expect(sources.captureActions, contains('_mergeOrderCaptureDiagnostics'));
    expect(
      sources.captureActions,
      contains('for (final entry in pickedDiagnostics.entries)'),
    );
    expect(
      sources.captureActions,
      contains('...?pickedDiagnostics[entry.key]'),
    );
    expect(sources.captureActions, contains('_mergeRetakeCaptureDiagnostics'));
    expect(
      sources.nativeGhostGuide,
      contains('previousSectionGuideUsesNextContext'),
    );
    expect(
      sources.nativeGhostGuide,
      contains('next_section_top_context_ghost_at_top_repeat_3_to_5_lines'),
    );
    expect(sources.nativeGhostGuide, contains('next_section_top_lines'));
    expect(sources.nativeGhostShell, contains('Match the next section'));
    expect(sources.reviewActions, contains('Retake Top Receipt Section'));
    expect(sources.reviewActions, contains('Retake Middle Receipt Section'));
    expect(sources.reviewActions, contains('Retake Bottom Receipt Section'));
    expect(sources.reviewActions, contains('Retake Section'));
    expect(sources.reviewActions, contains('Line Up The Next Receipt Photo'));
    expect(sources.reviewControls, contains('Add Bottom Section'));
    expect(
      sources.reviewTopBar,
      contains(
        'Add the bottom receipt section and repeat 3-5 readable lines in the top ghost slice before receipt details',
      ),
    );
    expect(
      sources.reviewPreviewControls,
      contains(
        'Add the bottom receipt section and repeat 3-5 readable lines in the top ghost slice before receipt details',
      ),
    );
    expect(
      sources.reviewActions,
      contains(
        'Use the bottom of the last photo as the top ghost-slice guide.',
      ),
    );
    expect(sources.reviewActions, contains('_ReceiptAlignmentGuidePreview'));
    expect(
      sources.reviewActions,
      contains('Repeat 3-5 readable lines from this bottom area'),
    );
    expect(
      sources.reviewActions,
      contains(
        'Put 3-5 repeated readable lines in the top ghost slice so subtotal, total, and final lines can be matched.',
      ),
    );
    expect(
      sources.reviewActions,
      contains('repeating 3-5 readable receipt lines'),
    );
    expect(sources.sectionLabels, contains('Add Next Receipt Photo'));
    expect(sources.reviewActions, isNot(contains('Open Receipt Camera')));
    expect(sources.reviewActions, isNot(contains('Prepare Receipt Review')));
    expect(sources.reviewActions, isNot(contains('Leave Without Saving')));
    expect(sources.reviewActions, contains('_confirmRemoveCurrentPhoto'));
    expect(sources.reviewActions, contains('Remove receipt photo?'));
    expect(
      sources.reviewActions,
      contains('make sure the remaining photos still cover every line'),
    );
    expect(
      sources.reviewActions,
      contains(
        'Wait for the photo match check, then choose how receipt details should be filled.',
      ),
    );
    expect(sources.reviewControls, isNot(contains('Next: Stitch And Review')));
    expect(
      sources.reviewScreen,
      contains('late var _reviewMode = _initialReviewMode()'),
    );
    expect(sources.reviewScreen, contains('_buildEmptyReviewRecovery'));
    expect(sources.reviewScreen, contains('Receipt photo was not available.'));
    expect(sources.reviewScreen, contains('No receipt fields were changed.'));
    expect(
      sources.reviewScreen,
      contains('_ReceiptReviewMode _initialReviewMode()'),
    );
    expect(
      sources.reviewScreen,
      contains(
        '!widget.bestShotCandidateMode && _initialPhotoPaths.length > 1',
      ),
    );
    expect(
      sources.reviewScreen,
      contains('uniqueNormalizedReceiptPhotoPaths(widget.initialPhotoPaths)'),
    );
    expect(sources.reviewScreen, contains('Review Photos Top To Bottom'));
    expect(
      sources.reviewScreen,
      contains('Line up 3-5 repeated readable receipt lines'),
    );
    expect(sources.reviewScreen, contains('Combined Receipt Preview'));
    expect(
      sources.reviewScreen,
      contains('Next will review them from top to bottom'),
    );
    expect(
      sources.stitchControls,
      contains("final fallbackRecoveryLabel = failedPairLabel.isEmpty"),
    );
    expect(sources.stitchControls, contains('Fix Photo Order'));
    expect(sources.stitchControls, contains(r'Fix $failedPairLabel'));
    expect(sources.stitchControls, contains('Next Reviews Top To Bottom'));
    expect(sources.reviewScreen, contains('ReceiptStitchDeviceLimits'));
    expect(sources.reviewScreen, contains('_deviceCapability.stitchLimits'));
    expect(sources.policySource, contains('ReceiptCapabilityTier.light'));
    expect(sources.policySource, contains('maxOutputPixels: 9000000'));
    expect(sources.policySource, contains('maxOutputHeight: 14000'));
    expect(
      sources.reviewScreen,
      contains('maxOutputPixels: _stitchDeviceLimits.maxOutputPixels'),
    );
    expect(
      sources.reviewSaveActions,
      contains('maxOutputPixels: _stitchDeviceLimits.maxOutputPixels'),
    );
    expect(sources.reviewScreen, contains('bottomInset'));
    expect(
      sources.reviewPreviewControls,
      contains('minimumSize: const Size(0, 38)'),
    );
    expect(
      sources.contextControls,
      contains('minimumSize: const Size(35, 35)'),
    );
    expect(sources.commonControls, contains('minimumSize: const Size(0, 32)'));
    expect(sources.sectionLabels, contains("'Add Another Photo'"));
    expect(sources.reviewPreviewControls, contains('addNextSectionLabel'));
    expect(sources.sectionLabels, contains("'Add Next Receipt Photo'"));
    expect(sources.orderControls, contains('_ReceiptOrderThumbnail'));
    expect(sources.reviewScreen, contains('BoxFit.contain'));
    expect(
      sources.reviewScreen,
      contains(
        '_ReceiptReviewMode.preview => _photoPaths.length > 1 ? 188.0 : 166.0',
      ),
    );
    expect(sources.reviewScreen, contains('_ReceiptReviewMode.order => 142.0'));
    expect(
      sources.reviewScreen,
      contains('_ReceiptReviewMode.stitch => 164.0'),
    );
    expect(
      sources.reviewScreen,
      contains('_ReceiptReviewMode.dataSaver => 168.0'),
    );
    expect(
      sources.reviewScreen,
      isNot(contains('EdgeInsets.fromLTRB(12, 64, 12, 230)')),
    );
    expect(sources.reviewTopBar, contains('sectionLabel'));
    expect(sources.reviewTopBar, contains('Best photo'));
    expect(sources.reviewTopBar, contains('Check photo order'));
    expect(sources.reviewTopBar, contains('Match receipt photos'));
    expect(sources.reviewTopBar, contains('Review Receipt Photo'));
    expect(sources.reviewTopBar, contains('Save space preview'));
    expect(sources.reviewTopBar, contains('Leave photo review'));
    expect(sources.reviewTopBar, isNot(contains('Back to receipt form')));
    expect(sources.reviewTopBar, contains('Icons.arrow_back_rounded'));
    expect(sources.reviewTopBar, isNot(contains('Close receipt preview')));
    expect(sources.reviewTopBar, contains('Add Another Photo'));
    expect(sources.reviewTopBar, contains('Move Photo Up'));
    expect(sources.reviewTopBar, contains('Move Photo Down'));
    expect(sources.reviewActions, contains('moveCurrentReceiptPhoto'));
    expect(
      sources.imageEditActions,
      allOf(
        contains('mode == _ReceiptReviewMode.order'),
        contains('_deleteStaleDataSaverPreviewFiles'),
        contains('staleDataSaverPreviewPaths'),
        contains('_removePhotoReviewCachesForPath'),
        contains('_previewKeysInFlight.removeWhere'),
        contains('_dataSaverPreviewKeysInFlight.removeWhere'),
      ),
    );
    expect(sources.reviewActions, contains('_replaceCurrentPhotoPath('));
    expect(sources.reviewActions, contains('_removePhotoReviewCachesForPath('));
    expect(sources.edgeCropper, contains('topLeft'));
    expect(sources.edgeCropper, contains('bottomRight'));
    expect(sources.edgeCropper, contains('_notifyAfterLayout'));
    expect(sources.productStandard, contains('## Hardening Pass Map'));
    expect(sources.productStandard, contains('App-Assisted Handoff'));
    expect(sources.imagePicker, contains('ReceiptPickedPhotoSet'));
    expect(sources.imagePicker, contains('receiptCameraImageQuality = 100'));
    expect(
      sources.imagePicker,
      contains('preferredCameraDevice: CameraDevice.rear'),
    );
    expect(sources.imagePicker, contains('requestFullMetadata: false'));
    expect(
      sources.imagePicker,
      contains('Backup receipt capture uses the phone camera/gallery surfaces'),
    );
    expect(sources.productStandard, contains('Long Receipt Capture'));
    expect(
      sources.productStandard,
      contains('Business/Personal/Mixed Classification'),
    );
    expect(sources.productStandard, contains('fill a reviewable receipt form'));
    expect(sources.productStandard, contains('fill the receipt review'));
    expect(sources.productStandard, contains('reviewed separately'));
    expect(sources.productStandard, isNot(contains('read receipt')));
    expect(sources.productStandard, isNot(contains('or read receipt')));
    expect(sources.realDeviceScript, contains('fill the receipt review'));
    expect(
      sources.realDeviceScript,
      contains('App-Assisted Filled Receipt Review'),
    );
    expect(sources.realDeviceScript, contains('top-to-bottom photo review'));
    expect(
      sources.realDeviceScript,
      isNot(contains('read or use the receipt')),
    );
    expect(
      sources.realDeviceScript,
      isNot(contains('Wait for receipt reading')),
    );
    expect(
      sources.productStandard,
      contains(
        'Never OCR the smaller saved proof when a cleaner prepared source exists.',
      ),
    );
  });
}
