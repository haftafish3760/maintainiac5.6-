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
    expect(
      settingsSheet,
      contains('Maintainiac uses its own receipt camera when available'),
    );
    expect(settingsSheet, contains('Backup scanner and photo options'));
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
      contains('Maintainiac uses its own receipt camera when available'),
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
    expect(settingsSheet, contains('open Cleanup And Backup'));
    expect(settingsSheet, contains('You preview the actual saved proof'));
    expect(reviewControls, contains('Save Space'));
    expect(reviewControls, contains('Cleanup And Backup'));
    expect(reviewControls, contains("return 'Next';"));
    expect(reviewControls, contains('_ReceiptPreviewActionTray'));
    expect(reviewControls, contains('_ReceiptSectionStripHeader'));
    expect(reviewControls, contains('_ReceiptActionRailButton'));
    expect(
      reviewControls,
      contains(
        'Photo captured. Add a photo if the receipt continues, crop or retake if needed, or tap Next to review item prices.',
      ),
    );
    expect(
      reviewControls,
      contains(
        'receipt photos ready. Check order, add the next section if needed, or tap Next to review item prices.',
      ),
    );
    expect(sectionLabels, contains('Receipt Sections'));
    expect(reviewControls, contains('addNextSectionLabel'));
    expect(reviewControls, contains('Backup image'));
    expect(reviewControls, contains('OCR uses the clear photo first'));
    expect(
      reviewScreen,
      contains(
        '_ReceiptReviewMode.preview => _photoPaths.length > 1 ? 132.0 : 104.0',
      ),
    );
    expect(
      reviewScreen,
      contains('maxHeight: _reviewBottomControlsMaxHeight(context)'),
    );
    expect(reviewScreen, contains('double _reviewBottomControlsMaxHeight'));
    expect(reviewScreen, contains('132.0 : 104.0'));
    expect(reviewScreen, contains('_ReceiptReviewMode.preview => .18'));
    expect(reviewScreen, contains('_ReceiptReviewMode.stitch => 126.0'));
    expect(reviewScreen, contains('_ReceiptReviewMode.dataSaver => 142.0'));
    expect(reviewScreen, contains('Widget _buildReviewBottomControls'));
    expect(reviewScreen, contains('return controls;'));
    expect(
      reviewScreen,
      contains('if (!didPop) _leaveReceiptReviewWithoutSaving();'),
    );
    expect(reviewActions, contains('Navigator.of(context).pop();'));
    expect(
      reviewActions,
      contains('unawaited(_cleanupAbandonedReceiptReview())'),
    );
    expect(
      reviewActions,
      contains('Future<void> _deleteAbandonedStagedReviewPhotos()'),
    );
    expect(
      reviewActions,
      contains('ReceiptProofStorage.instance.deleteStagedAttachments'),
    );
    expect(reviewActions, contains('ReceiptAttachmentStorageState.staged'));
    expect(reviewScreen, isNot(contains('_confirmExit')));
    expect(
      reviewScreen,
      isNot(contains('Tap the receipt to hide controls. Pinch to zoom.')),
    );
    expect(reviewScreen, isNot(contains('class _ReceiptImageViewportHint')));
    expect(dataSaverPanel, contains('Saved proof image'));
    expect(
      dataSaverPanel,
      contains('Receipt reading uses the clear OCR source'),
    );
    expect(dataSaverPanel, isNot(contains('Saved copy')));
    expect(reviewControls, contains('_ReceiptPreviewActionTray'));
    expect(reviewControls, contains('_ReceiptSinglePhotoActionRow'));
    expect(reviewControls, contains('Scrollbar('));
    expect(reviewControls, contains('SingleChildScrollView('));
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
    expect(reviewControls, contains('Previous Pair'));
    expect(reviewControls, contains('Next Pair'));
    expect(
      reviewControls,
      contains(r'Sections ${pairIndex + 1}-${pairIndex + 2}'),
    );
    expect(reviewControls, contains(r'Bottom of section ${pairIndex + 1}'));
    expect(reviewControls, contains(r'Top of section ${pairIndex + 2}'));
    expect(reviewControls, contains('Combined Receipt Ready'));
    expect(reviewControls, contains('Safe Fallback Ready'));
    expect(reviewControls, contains('Long Receipt Match'));
    expect(reviewControls, contains("label: 'Match Photos'"));
    expect(reviewControls, contains("return 'Next';"));
    expect(reviewControls, contains('Safe Fallback Ready'));
    expect(reviewControls, contains('waitingForStitch'));
    expect(reviewControls, contains('continueEnabled'));
    expect(reviewControls, contains("return 'Next';"));
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
      contains('Repeat 3-5 readable lines from this bottom area'),
    );
    expect(
      reviewActions,
      contains('Keep the ghost slice near the top of the next photo'),
    );
    expect(reviewActions, contains('repeating 3-5 readable receipt lines'));
    expect(reviewActions, contains('Open Receipt Camera'));
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
    expect(reviewScreen, contains('Line up repeated receipt text'));
    expect(reviewScreen, contains('Combined Receipt Preview'));
    expect(reviewScreen, contains('Next will review them from top to bottom'));
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
    expect(reviewControls, contains('minimumSize: const Size(92, 38)'));
    expect(reviewControls, contains('minimumSize: const Size(35, 35)'));
    expect(reviewControls, contains('minimumSize: const Size(0, 34)'));
    expect(reviewControls, contains("'Add Another Photo'"));
    expect(reviewControls, contains("label: 'Add Another Photo'"));
    expect(reviewControls, contains("label: 'Add Photo'"));
    expect(sectionLabels, contains("'Add Next Photo'"));
    expect(reviewControls, contains('_ReceiptOrderThumbnail'));
    expect(reviewScreen, contains('BoxFit.contain'));
    expect(
      reviewScreen,
      contains(
        '_ReceiptReviewMode.preview => _photoPaths.length > 1 ? 132.0 : 104.0',
      ),
    );
    expect(reviewScreen, contains('_ReceiptReviewMode.order => 112.0'));
    expect(reviewScreen, contains('_ReceiptReviewMode.stitch => 126.0'));
    expect(reviewScreen, contains('_ReceiptReviewMode.dataSaver => 142.0'));
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
      contains('Backup receipt capture uses the phone camera/gallery surfaces'),
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
    final models = await File(
      'lib/shared/widgets/receipt_capture/receipt_capture_models.dart',
    ).readAsString();
    final reviewScreen = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart',
    ).readAsString();
    final reviewControls = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart',
    ).readAsString();
    final receiptEntryScreen = await File(
      'lib/screens/expenses/entry/expense_receipt_entry_screen.dart',
    ).readAsString();

    expect(reviewActions, contains('prepareForOcrAndBackup'));
    expect(reviewActions, contains('captureDiagnosticsByPath'));
    expect(reviewActions, contains('staged.captureDiagnosticsByPhotoPath'));
    expect(reviewActions, contains('preparationDiagnostics'));
    expect(reviewActions, contains('prepared.preparation'));
    expect(reviewActions, contains('.toDiagnostics()'));
    expect(
      reviewActions,
      contains('preparationDiagnosticsByOcrPath: preparationDiagnostics'),
    );
    expect(
      reviewActions,
      contains('captureDiagnosticsByPhotoPath: captureDiagnostics'),
    );
    expect(
      models,
      contains(
        'final Map<String, Map<String, Object?>> captureDiagnosticsByPhotoPath',
      ),
    );
    expect(reviewScreen, contains('previewPreparedBackupFile'));
    expect(reviewScreen, contains('optimizePreparedBackupFile'));
    expect(reviewControls, contains('_ReceiptOcrProofLaneCard'));
    expect(reviewControls, contains('_ReceiptDataSaverReviewCopy'));
    expect(reviewControls, contains('Receipt Details And Backup Image'));
    expect(reviewScreen, contains('_deleteGeneratedDataSaverPreviews'));
    expect(reviewScreen, contains('_deleteGeneratedStitchPreview'));
    expect(reviewActions, contains('_deleteUnusedBestShotCandidatePhotos'));
    expect(reviewActions, contains('_deleteGeneratedEditPhotos'));
    expect(imageProcessor, contains('prepareReceiptSourceFile'));
    expect(imageProcessor, contains('prepareReceiptSourceWithReport'));
    expect(imageProcessor, contains('ReceiptImagePreparationReport'));
    expect(imageProcessor, contains('usedEnhancedOcrSource'));
    expect(imageProcessor, contains('cleanupActions'));
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
    expect(
      importActions,
      contains('widget.onReceiptPhotoReviewAccepted?.call(result)'),
    );
    expect(
      receiptEntryScreen,
      contains('_recordReceiptPhotoPreparationTelemetry(result)'),
    );
    expect(
      receiptEntryScreen,
      contains('preparationDiagnosticsByOcrPath.values'),
    );
    expect(
      receiptEntryScreen,
      contains('captureDiagnosticsByPhotoPath.values'),
    );
    expect(receiptEntryScreen, contains('captureDiagnosticsCount'));
    expect(receiptEntryScreen, contains('brightnessBuckets'));
    expect(receiptEntryScreen, contains('readabilitySignalBuckets'));
    expect(receiptEntryScreen, contains('exposureAssistStatuses'));
    expect(receiptEntryScreen, contains('framingConfidenceBuckets'));
    expect(receiptEntryScreen, contains('focusStatusBuckets'));
    expect(receiptEntryScreen, contains('autoCaptureStatusBuckets'));
    expect(receiptEntryScreen, contains('edgeDetectionEnabledCount'));
    expect(receiptEntryScreen, contains('edgeOverlayEnabledCount'));
    expect(receiptEntryScreen, contains('tapFocusEnabledCount'));
    expect(receiptEntryScreen, contains('pinchZoomEnabledCount'));
    expect(receiptEntryScreen, contains('brightnessSliderEnabledCount'));
    expect(receiptEntryScreen, contains('shadowWarningEnabledCount'));
    expect(receiptEntryScreen, contains('textTooSmallWarningEnabledCount'));
    expect(receiptEntryScreen, contains('autoCropSuggestionEnabledCount'));
    expect(receiptEntryScreen, contains('grayscalePreviewEnabledCount'));
    expect(receiptEntryScreen, contains('contrastBoostEnabledCount'));
    expect(receiptEntryScreen, contains('shadowReductionEnabledCount'));
    expect(receiptEntryScreen, contains('orientationCorrectionEnabledCount'));
    expect(receiptEntryScreen, contains('tapFocusTotal'));
    expect(receiptEntryScreen, contains('zoomChangeTotal'));
    expect(receiptEntryScreen, contains('manualBrightnessChangeTotal'));
    expect(receiptEntryScreen, contains('autoCaptureTriggerTotal'));
    expect(receiptEntryScreen, contains('latestFramingConfidence'));
    expect(receiptEntryScreen, contains('_diagnosticStringCounts'));
    expect(receiptEntryScreen, contains('_diagnosticIntSum'));
    expect(receiptEntryScreen, contains('_diagnosticBoolTrueCount'));
    expect(receiptEntryScreen, contains('scannerCleanupUsedCount'));
    expect(receiptEntryScreen, contains('cleanupActions'));
    expect(receiptEntryScreen, contains('stitchFallbackReason'));
    expect(receiptEntryScreen, contains('diagnosticReasonLabel'));
    expect(receiptEntryScreen, contains('stitchConfidenceBucket'));
    expect(receiptEntryScreen, isNot(contains('receiptText')));
    expect(importActions, contains('ReceiptAttachmentReadState.readIntoForm'));
    expect(importActions, contains('ReceiptAttachmentReadState.unreadable'));
    expect(importActions, contains('appAssistedEnabledFor(widget.area)'));
    expect(importActions, contains('widget.onImportedText == null'));
    expect(importActions, contains('result.ocrSourcePhotoPaths.isEmpty'));
    expect(
      importActions,
      contains(
        'Receipt backup image saved. App-assisted receipt filling is turned off for this area.',
      ),
    );
    expect(
      importActions,
      contains(
        r'Receipt backup image saved: ${result.savedProofCountLabel}. No clear OCR source was available for app-assisted receipt filling.',
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
    expect(attachmentPanel, contains('onReceiptPhotoReviewAccepted'));
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
        'One combined receipt image was read. Review what Maintainiac filled in below.',
      ),
    );
    expect(
      importActions,
      contains(
        'Receipt photos were read from top to bottom. Review what Maintainiac filled in below.',
      ),
    );
    expect(
      importActions,
      contains(
        'Receipt photo was read. Review what Maintainiac filled in below.',
      ),
    );
    expect(
      importActions.indexOf('_readReviewedPhotosForReceiptForm(result)'),
      lessThan(
        importActions.indexOf(
          '_deleteTemporaryOcrPhotos(result.ocrSourcePhotoPaths)',
        ),
      ),
    );
    expect(
      importActions.indexOf(
        'widget.onReceiptPhotoReviewAccepted?.call(result)',
      ),
      lessThan(importActions.indexOf('_startReviewedPhotoReadStatus(result)')),
    );
  });
}
