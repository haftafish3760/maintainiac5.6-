import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('receipt capture exposes camera help and long receipt guidance', () async {
    final settingsSheet = await File(
      'lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart',
    ).readAsString();
    final helpSheet = await File(
      'lib/shared/widgets/receipt_capture/receipt_camera_help_sheet.dart',
    ).readAsString();
    final reviewControls = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart',
    ).readAsString();
    final reviewTopBar = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart',
    ).readAsString();
    final reviewActions = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart',
    ).readAsString();
    final imagePicker = await File(
      'lib/shared/widgets/receipt_capture/receipt_image_picker.dart',
    ).readAsString();
    final reviewScreen = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart',
    ).readAsString();
    final sectionLabels = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_section_labels.dart',
    ).readAsString();
    final reviewSaveActions = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart',
    ).readAsString();
    final importActions = await File(
      'lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart',
    ).readAsString();
    final dataSaverPanel = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_data_saver_panel.dart',
    ).readAsString();
    final edgeCropper = await File(
      'lib/shared/widgets/receipt_capture/receipt_edge_cropper.dart',
    ).readAsString();
    final productStandard = await File(
      'docs/receipt_camera_ocr_product_standard.md',
    ).readAsString();
    final realDeviceScript = await File(
      'docs/receipt_real_device_test_script.md',
    ).readAsString();

    expect(settingsSheet, contains('Receipt Photo Help'));
    expect(settingsSheet, isNot(contains('How Receipt Photos Work')));
    expect(helpSheet, contains('Receipt Photo Help'));
    expect(helpSheet, contains('Before Your First Receipt Photo'));
    expect(helpSheet, contains('Continue To Camera'));
    expect(helpSheet, contains('Open Receipt Settings'));
    expect(helpSheet, contains('Clear Photo First'));
    expect(helpSheet, contains('Review Before Saving'));
    expect(helpSheet, contains('Storage And Privacy'));
    expect(helpSheet, contains('profile.summaryLabel'));
    expect(helpSheet, isNot(contains('deviceModel')));
    expect(helpSheet, isNot(contains('availableRamLabel')));
    expect(importActions, contains('_showFirstUseReceiptCameraIntro'));
    expect(importActions, contains('!settings.cameraSetupComplete'));
    expect(importActions, contains('settings.setCameraSetupComplete(true)'));
    expect(
      importActions,
      contains('_ReceiptFirstUseCameraAction.openSettings'),
    );
    expect(importActions, contains('_openReceiptCaptureSettings()'));
    expect(settingsSheet, contains('Expense Receipt Settings'));
    expect(
      settingsSheet,
      contains('Let Maintainiac Help Fill Expense Receipts'),
    );
    expect(settingsSheet, contains('Receipt Scanner'));
    expect(settingsSheet, contains('Android, it opens the phone camera first'));
    expect(settingsSheet, contains('Google Play Services scanner update'));
    expect(settingsSheet, contains('Show Long Receipt Tips'));
    expect(settingsSheet, contains('Receipt Backup Image Size'));
    expect(settingsSheet, contains('Expense Receipt Review Detail'));
    expect(settingsSheet, contains('Show Prices Only'));
    expect(settingsSheet, contains('Show Full Item Details'));
    expect(
      settingsSheet,
      contains(
        'Choose what Maintainiac shows after it reads an expense receipt.',
      ),
    );
    expect(settingsSheet, contains('Business, Personal, or Split'));
    expect(settingsSheet, contains('ExpenseSettingsScope.maybeOf(context)'));
    expect(settingsSheet, contains('ExpenseReceiptReviewStyle.simpleAmounts'));
    expect(
      settingsSheet,
      contains('ExpenseReceiptReviewStyle.fullItemDetails'),
    );
    expect(
      settingsSheet,
      contains(
        'On iPhone, Maintainiac can use the built-in document scanner. On Android, it opens the phone camera first',
      ),
    );
    expect(settingsSheet, contains('Apply Settings'));
    expect(
      settingsSheet,
      contains(
        'Changes save as soon as you tap a switch or size choice. Apply Settings closes this screen.',
      ),
    );
    expect(settingsSheet, contains('Reset Receipt Photo Defaults'));
    expect(settingsSheet, contains('Reset Defaults'));
    expect(settingsSheet, contains('open Saved Proof Size'));
    expect(settingsSheet, contains('You preview the actual saved proof'));
    expect(reviewControls, contains('Save Space'));
    expect(reviewControls, contains('Saved Proof Size'));
    expect(reviewControls, contains("return 'Next';"));
    expect(reviewControls, contains('_ReceiptPreviewActionTray'));
    expect(reviewControls, contains('_ReceiptPreviewActionRail'));
    expect(reviewControls, contains('_ReceiptActionRailButton'));
    expect(
      reviewControls,
      contains(
        'If the receipt continues, add another photo. Otherwise tap Next to review the filled receipt.',
      ),
    );
    expect(
      reviewControls,
      contains(
        'receipt photos ready. Check order and match, then tap Next to review the filled receipt.',
      ),
    );
    expect(reviewControls, contains('Saved proof copy'));
    expect(reviewControls, contains('OCR uses the clear photo first'));
    expect(
      reviewScreen,
      contains(
        '_ReceiptReviewMode.preview => _photoPaths.length > 1 ? 126 : 96',
      ),
    );
    expect(
      reviewScreen,
      contains('maxHeight: _reviewBottomControlsMaxHeight(context)'),
    );
    expect(reviewScreen, contains('double _reviewBottomControlsMaxHeight'));
    expect(reviewScreen, contains('150.0 : 112.0'));
    expect(reviewScreen, contains('_ReceiptReviewMode.stitch => 176.0'));
    expect(reviewScreen, contains('_ReceiptReviewMode.dataSaver => 170.0'));
    expect(reviewScreen, contains('Widget _buildReviewBottomControls'));
    expect(
      reviewScreen,
      contains(
        'if (_reviewMode == _ReceiptReviewMode.preview) return controls',
      ),
    );
    expect(
      reviewScreen,
      contains('if (!didPop) _leaveReceiptReviewWithoutSaving();'),
    );
    expect(reviewActions, contains('Navigator.of(context).pop();'));
    expect(
      reviewActions,
      contains('unawaited(_cleanupAbandonedReceiptReview())'),
    );
    expect(reviewScreen, isNot(contains('_confirmExit')));
    expect(
      reviewScreen,
      isNot(contains('Tap the receipt to hide controls. Pinch to zoom.')),
    );
    expect(reviewScreen, isNot(contains('class _ReceiptImageViewportHint')));
    expect(dataSaverPanel, contains('Saved proof image'));
    expect(dataSaverPanel, contains('OCR already uses the clear photo first'));
    expect(dataSaverPanel, isNot(contains('Saved copy')));
    expect(reviewControls, isNot(contains('SingleChildScrollView')));
    expect(reviewControls, isNot(contains('_ReceiptPreviewStatusPill')));
    expect(reviewControls, isNot(contains('_ReceiptToolChip')));
    expect(settingsSheet, isNot(contains('Use App Assistance In')));
    expect(settingsSheet, isNot(contains('Performance Mode')));
    expect(settingsSheet, isNot(contains('Automatic Receipt Setup')));
    expect(settingsSheet, isNot(contains('Photo Reading Accuracy')));
    expect(settingsSheet, isNot(contains('Google Vision Access')));
    expect(settingsSheet, isNot(contains('Save And Open Receipt Scanner')));
    expect(settingsSheet, isNot(contains('Your Current Receipt Setup')));
    expect(settingsSheet, isNot(contains('Quick setup before')));
    expect(helpSheet, contains('Receipt Photo Help'));
    expect(helpSheet, contains('Long Receipts'));
    expect(helpSheet, contains('App-Assisted Receipt Fill'));
    expect(helpSheet, contains('Business, Personal, Or Split'));
    expect(helpSheet, contains('Storage And Backup'));
    expect(helpSheet, isNot(contains('Live Guidance')));
    expect(helpSheet, isNot(contains('Guided Capture')));
    expect(reviewControls, isNot(contains('Move Earlier')));
    expect(reviewControls, isNot(contains('Move Later')));
    expect(reviewControls, contains('Match'));
    expect(reviewControls, contains('Order'));
    expect(reviewControls, contains('Check Photo Order'));
    expect(reviewControls, contains('_ReceiptOrderToolControls'));
    expect(reviewControls, contains('_ReceiptToolModeHeader'));
    expect(reviewControls, contains('Photo 1 should be the top'));
    expect(
      reviewControls,
      contains('_ReceiptPhotoSectionLabels.moveEarlierLabel'),
    );
    expect(
      reviewControls,
      contains('_ReceiptPhotoSectionLabels.moveLaterLabel'),
    );
    expect(
      reviewControls,
      contains('_ReceiptPhotoSectionLabels.addNextPhotoLabel'),
    );
    expect(reviewControls, contains('_ReceiptPhotoSectionLabels.retakeLabel'));
    expect(sectionLabels, contains('Retake keeps this spot'));
    expect(sectionLabels, contains('Add Next Photo'));
    expect(sectionLabels, contains('Retake Bottom'));
    expect(reviewControls, contains('Preview'));
    expect(reviewControls, contains('Manual match'));
    expect(reviewControls, contains('Line up the repeated receipt text'));
    expect(reviewControls, contains('Previous Photos'));
    expect(reviewControls, contains('Next Photos'));
    expect(reviewControls, contains(r"'Pair ${pairIndex + 1} of $totalPairs'"));
    expect(reviewControls, contains('Ready To Review One Receipt Image'));
    expect(reviewControls, contains('Check Photo Match'));
    expect(reviewControls, contains("return 'Next';"));
    expect(reviewControls, contains('Review Photos Top To Bottom'));
    expect(reviewControls, contains('waitingForStitch'));
    expect(reviewControls, contains('continueEnabled'));
    expect(reviewControls, isNot(contains('Next: Review Receipt')));
    expect(reviewControls, isNot(contains('Choose The Best Receipt Photo')));
    expect(reviewControls, isNot(contains('Use This Photo')));
    expect(reviewActions, contains('_needsStitchReviewBeforeSave'));
    expect(reviewActions, contains('_reviewMode = _ReceiptReviewMode.stitch'));
    expect(reviewActions, contains('ReceiptImagePicker.takeReceiptPhotoSet()'));
    expect(reviewActions, contains('_showLongReceiptAlignmentGuide'));
    expect(reviewActions, contains('Line Up The Next Receipt Photo'));
    expect(
      reviewActions,
      contains('Use the bottom of the last photo as your guide.'),
    );
    expect(reviewActions, contains('_ReceiptAlignmentGuidePreview'));
    expect(
      reviewActions,
      contains('Repeat a few lines from this bottom area in the next photo.'),
    );
    expect(
      reviewActions,
      contains('Maintainiac cannot draw over that camera screen'),
    );
    expect(reviewActions, contains('Open Camera'));
    expect(reviewActions, isNot(contains('Prepare Receipt Review')));
    expect(reviewActions, isNot(contains('Leave Without Saving')));
    expect(reviewActions, contains('_confirmRemoveCurrentPhoto'));
    expect(reviewActions, contains('Remove receipt photo?'));
    expect(
      reviewActions,
      contains('make sure the remaining photos still cover every line'),
    );
    expect(
      reviewActions,
      contains(
        'Wait for the photo match check, then choose how the receipt review should be filled.',
      ),
    );
    expect(reviewControls, isNot(contains('Next: Stitch And Review')));
    expect(
      reviewScreen,
      contains('late var _reviewMode = _initialReviewMode()'),
    );
    expect(reviewScreen, contains('_buildEmptyReviewRecovery'));
    expect(reviewScreen, contains('Receipt photo was not available.'));
    expect(reviewScreen, contains('No receipt fields were changed.'));
    expect(reviewScreen, contains('_ReceiptReviewMode _initialReviewMode()'));
    expect(
      reviewScreen,
      contains(
        '!widget.bestShotCandidateMode && widget.initialPhotoPaths.length > 1',
      ),
    );
    expect(reviewScreen, contains('Review Photos Top To Bottom'));
    expect(reviewScreen, contains('Match repeated receipt text'));
    expect(reviewScreen, contains('Combined Receipt Preview'));
    expect(reviewScreen, contains('app reviews each photo from top to bottom'));
    expect(reviewControls, contains('Fix Photo Order'));
    expect(reviewControls, contains('Next Reviews Top To Bottom'));
    expect(reviewScreen, contains('ReceiptStitchDeviceLimits'));
    expect(reviewScreen, contains('_deviceCapability.stitchLimits'));
    final policySource = await File(
      'lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart',
    ).readAsString();
    expect(policySource, contains('ReceiptCapabilityTier.light'));
    expect(policySource, contains('maxOutputPixels: 9000000'));
    expect(policySource, contains('maxOutputHeight: 14000'));
    expect(
      reviewScreen,
      contains('maxOutputPixels: _stitchDeviceLimits.maxOutputPixels'),
    );
    expect(
      reviewSaveActions,
      contains('maxOutputPixels: _stitchDeviceLimits.maxOutputPixels'),
    );
    expect(reviewScreen, contains('bottomInset'));
    expect(reviewControls, contains('minimumSize: const Size(124, 38)'));
    expect(reviewControls, contains('minimumSize: const Size(35, 35)'));
    expect(reviewControls, contains('minimumSize: const Size(0, 34)'));
    expect(reviewControls, contains("'Add Another Photo'"));
    expect(reviewControls, contains("'Add Photo'"));
    expect(reviewControls, contains('_ReceiptOrderThumbnail'));
    expect(reviewScreen, contains('BoxFit.contain'));
    expect(
      reviewScreen,
      contains(
        '_ReceiptReviewMode.preview => _photoPaths.length > 1 ? 126 : 96',
      ),
    );
    expect(reviewScreen, contains('_ReceiptReviewMode.order => 118'));
    expect(reviewScreen, contains('_ReceiptReviewMode.stitch => 142'));
    expect(reviewScreen, contains('_ReceiptReviewMode.dataSaver => 126'));
    expect(
      reviewScreen,
      isNot(contains('EdgeInsets.fromLTRB(12, 64, 12, 230)')),
    );
    expect(reviewTopBar, contains('sectionLabel'));
    expect(reviewTopBar, contains('Best photo'));
    expect(reviewTopBar, contains('Check photo order'));
    expect(reviewTopBar, contains('Match receipt photos'));
    expect(reviewTopBar, contains('Review receipt photo'));
    expect(reviewTopBar, contains('Save space preview'));
    expect(reviewTopBar, contains('Back to receipt form'));
    expect(reviewTopBar, contains('Icons.arrow_back_rounded'));
    expect(reviewTopBar, isNot(contains('Close receipt preview')));
    expect(reviewTopBar, contains('Add Another Photo'));
    expect(reviewTopBar, contains('Move Photo Up'));
    expect(reviewTopBar, contains('Move Photo Down'));
    expect(reviewActions, contains('_moveCurrentPhoto'));
    expect(
      await File(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_image_edit_actions.dart',
      ).readAsString(),
      allOf(
        contains('mode == _ReceiptReviewMode.order'),
        contains('_deleteStaleDataSaverPreviewFiles'),
        contains('staleDataSaverPreviewPaths'),
        contains('_removePhotoReviewCachesForPath'),
        contains('_previewKeysInFlight.removeWhere'),
        contains('_dataSaverPreviewKeysInFlight.removeWhere'),
      ),
    );
    expect(reviewActions, contains('_replaceCurrentPhotoPath('));
    expect(reviewActions, contains('_removePhotoReviewCachesForPath('));
    expect(edgeCropper, contains('topLeft'));
    expect(edgeCropper, contains('bottomRight'));
    expect(edgeCropper, contains('_notifyAfterLayout'));
    expect(productStandard, contains('## Hardening Pass Map'));
    expect(productStandard, contains('App-Assisted Handoff'));
    expect(imagePicker, contains('ReceiptPickedPhotoSet'));
    expect(imagePicker, contains('receiptCameraImageQuality = 100'));
    expect(imagePicker, contains('preferredCameraDevice: CameraDevice.rear'));
    expect(imagePicker, contains('requestFullMetadata: false'));
    expect(
      imagePicker,
      contains(
        'Production receipt capture uses the phone camera/gallery surfaces',
      ),
    );
    expect(productStandard, contains('Long Receipt Capture'));
    expect(productStandard, contains('Business/Personal/Mixed Classification'));
    expect(productStandard, contains('fill a reviewable receipt form'));
    expect(productStandard, contains('fill the receipt review'));
    expect(productStandard, contains('reviewed separately'));
    expect(productStandard, isNot(contains('read receipt')));
    expect(productStandard, isNot(contains('or read receipt')));
    expect(realDeviceScript, contains('fill the receipt review'));
    expect(realDeviceScript, contains('App-Assisted Filled Receipt Review'));
    expect(realDeviceScript, contains('top-to-bottom photo review'));
    expect(realDeviceScript, isNot(contains('read or use the receipt')));
    expect(realDeviceScript, isNot(contains('Wait for receipt reading')));
    expect(
      productStandard,
      contains(
        'Never OCR the compressed backup copy when a cleaner prepared source exists.',
      ),
    );
  });

  test('reviewed camera photos read OCR sources before saved copies', () async {
    final reviewActions = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart',
    ).readAsString();
    final importActions = await File(
      'lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart',
    ).readAsString();

    final imageProcessor = await File(
      'lib/shared/widgets/receipt_capture/receipt_image_processor.dart',
    ).readAsString();
    final reviewScreen = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart',
    ).readAsString();

    expect(reviewActions, contains('prepareForOcrAndBackup'));
    expect(reviewScreen, contains('previewPreparedBackupFile'));
    expect(reviewScreen, contains('optimizePreparedBackupFile'));
    expect(reviewScreen, contains('_deleteGeneratedDataSaverPreviews'));
    expect(reviewScreen, contains('_deleteGeneratedStitchPreview'));
    expect(reviewActions, contains('_deleteUnusedBestShotCandidatePhotos'));
    expect(reviewActions, contains('_deleteGeneratedEditPhotos'));
    expect(imageProcessor, contains('prepareReceiptSourceFile'));
    expect(imageProcessor, contains('previewPreparedBackupFile'));
    expect(imageProcessor, contains('optimizePreparedBackupFile'));
    expect(imageProcessor, contains('_deleteFileQuietly'));
    expect(imageProcessor, contains('optimizeFile'));
    expect(
      imageProcessor.indexOf('prepareReceiptSourceFile'),
      lessThan(imageProcessor.indexOf('optimizeFile')),
    );
    expect(
      reviewActions,
      contains('ocrSourcePaths.add(prepared.ocrSourcePath)'),
    );
    expect(reviewActions, contains('savedPaths.add(prepared.backupPath)'));
    expect(reviewActions, contains('...stitch.ocrSourcePaths'));
    expect(importActions, contains('_readReviewedPhotosForReceiptForm'));
    expect(importActions, contains('_markReviewedPhotosReadState'));
    expect(importActions, contains('ReceiptAttachmentReadState.readIntoForm'));
    expect(importActions, contains('ReceiptAttachmentReadState.unreadable'));
    expect(importActions, contains('appAssistedEnabledFor(widget.area)'));
    expect(importActions, contains('widget.onImportedText == null'));
    expect(importActions, contains('result.ocrSourcePhotoPaths.isEmpty'));
    expect(
      importActions,
      contains(
        'Receipt photo saved as proof. App-assisted filling is turned off for this area.',
      ),
    );
    expect(
      importActions,
      contains(
        'Receipt photo saved as proof. No clear OCR source was available for app-assisted filling.',
      ),
    );
    expect(importActions, contains('result.ocrSourcePhotoPaths'));
    expect(importActions, contains('_qualityForOcrSourceIndex'));
    expect(importActions, contains('_weakestPhotoQuality'));
    expect(importActions, contains('.withPhotoQuality('));
    final attachmentPanel = await File(
      'lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart',
    ).readAsString();
    expect(attachmentPanel, contains('_photoReadStateByPath'));
    expect(attachmentPanel, contains('_photoIdByPath'));
    expect(attachmentPanel, contains('_photoAttachmentIdForPath'));
    expect(attachmentPanel, contains('readState:'));
    expect(attachmentPanel, contains('attachment.readState'));
    expect(importActions, contains('previousPhotoIdByPath'));
    expect(importActions, contains('_deleteTemporaryOcrPhotos'));
    expect(
      importActions,
      contains('final keptReceiptPhotos = _photoPaths.toSet()'),
    );
    expect(
      importActions,
      contains('if (keptReceiptPhotos.contains(sourcePath)) continue'),
    );
    expect(importActions, contains('_reviewedPhotoReadSuccessMessage'));
    expect(
      importActions,
      contains(
        'The matched receipt photo was read. Review the filled fields below.',
      ),
    );
    expect(
      importActions,
      contains(
        'Receipt photos were read from top to bottom. Review the filled fields below.',
      ),
    );
    expect(
      importActions,
      contains('Receipt photo was read. Review the filled fields below.'),
    );
    expect(
      importActions.indexOf('_readReviewedPhotosForReceiptForm(result)'),
      lessThan(
        importActions.indexOf(
          '_deleteTemporaryOcrPhotos(result.ocrSourcePhotoPaths)',
        ),
      ),
    );
  });
}
