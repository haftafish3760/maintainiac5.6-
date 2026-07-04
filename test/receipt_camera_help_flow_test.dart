import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_camera_source_readers.dart';

void main() {
  test('receipt capture exposes camera help and long receipt guidance', () async {
    final settingsSheet = await readReceiptCaptureSettingsSource();
    final helpSheet =
        await File(
          'lib/shared/widgets/receipt_capture/receipt_camera_help_sheet.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_camera_first_use_intro_sheet.dart',
        ).readAsString();
    final reviewControls = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart',
    ).readAsString();
    final reviewPreviewControls =
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_primary_row.dart',
        ).readAsString();
    final reviewPreviewActionTray =
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_action_tray.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_action_status.dart',
        ).readAsString();
    final reviewCropAndProofControls = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_crop_and_proof_controls.dart',
    ).readAsString();
    final contextControls = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_context_controls.dart',
    ).readAsString();
    final modeControls = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_mode_controls.dart',
    ).readAsString();
    final commonControls = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_common_controls.dart',
    ).readAsString();
    final reviewActions = await readReceiptPhotoReviewSaveActionsSource();
    final reviewScreen = await readReceiptPhotoReviewScreenSource();
    final sectionLabels = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_section_labels.dart',
    ).readAsString();
    final importActions =
        await File(
          'lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_attachment_camera_actions.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_attachment_review_read_actions.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_attachment_native_signal_documents.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_attachment_native_signal_helpers.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_attachment_ocr_source_signals.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_attachment_ocr_source_continuation_signals.dart',
        ).readAsString();
    final attachmentOcrSourceRiskFlags = await File(
      'lib/shared/widgets/receipt_capture/receipt_attachment_ocr_source_risk_flags.dart',
    ).readAsString();
    final attachmentPublishHelpers =
        await File(
          'lib/shared/widgets/receipt_capture/receipt_attachment_publish_helpers.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_attachment_publish_signals.dart',
        ).readAsString();
    final dataSaverPanel = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_data_saver_panel.dart',
    ).readAsString();
    expect(settingsSheet, contains('Receipt Photo Help'));
    expect(settingsSheet, isNot(contains('How Receipt Photos Work')));
    expect(helpSheet, contains('Receipt Photo Help'));
    expect(helpSheet, contains('Before Your First Receipt Photo'));
    expect(helpSheet, contains('Continue To Camera'));
    expect(helpSheet, contains('Open Receipt Settings'));
    expect(helpSheet, contains('Clear Photo First'));
    expect(helpSheet, contains('Review Before Saving'));
    expect(helpSheet, contains('Receipt Camera Controls'));
    expect(
      helpSheet,
      contains(
        'Use the in-camera settings for receipt help, long receipt guidance, flash, readability guidance, and saved proof size.',
      ),
    );
    expect(helpSheet, contains('continuous autofocus/readability guidance'));
    expect(helpSheet, isNot(contains('flash, focus')));
    expect(helpSheet, contains('Storage And Privacy'));
    expect(helpSheet, contains('installChoice.userFacingDownloadChoiceLabel'));
    expect(importActions, contains('parserPackInstallChoice'));
    expect(attachmentOcrSourceRiskFlags, contains('ocr_source_retake_risk'));
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
    expect(attachmentPublishHelpers, contains('openReceiptCaptureSettings()'));
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
    expect(settingsSheet, contains('settings.privacySafeCapabilityLabel'));
    expect(settingsSheet, contains('Detected safely:'));
    expect(settingsSheet, isNot(contains('deviceManufacturer')));
    expect(settingsSheet, isNot(contains('deviceModel')));
    expect(settingsSheet, isNot(contains('deviceName')));
    expect(settingsSheet, contains('Show Long Receipt Tips'));
    expect(settingsSheet, contains('Saved Receipt Proof Size'));
    expect(
      settingsSheet,
      contains('OCR still uses the clearest receipt source first'),
    );
    expect(settingsSheet, contains('Receipt Details And Saved Proof'));
    expect(
      settingsSheet,
      contains('installChoice.userFacingDownloadChoiceLabel'),
    );
    expect(settingsSheet, contains('hasOptionalCloudAssist'));
    expect(
      settingsSheet,
      contains('defaultDataSaverShouldOfferOptionalLocalParserPacks'),
    );
    _expectNoCloudRequiredCopy(settingsSheet);
    _expectNoCloudRequiredCopy(helpSheet);
    _expectNoCloudRequiredCopy(importActions);
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
    expect(settingsSheet, contains('open Receipt Details And Saved Proof'));
    expect(settingsSheet, contains('You preview the actual saved proof'));
    expect(settingsSheet, contains('static String _choiceTooltip'));
    expect(
      settingsSheet,
      contains('Good balance for review, phone space, and cloud backup.'),
    );
    expect(
      settingsSheet,
      contains('Smallest saved proof. Saves the most space'),
    );
    expect(modeControls, contains('Proof Size'));
    expect(
      reviewCropAndProofControls,
      contains('Receipt Details And Saved Proof'),
    );
    expect(reviewControls, contains("return 'Next: Review Receipt Details';"));
    expect(reviewControls, contains('_ReceiptPreviewActionTray'));
    expect(reviewPreviewControls, contains('_ReceiptMultiPhotoActionRail'));
    expect(reviewPreviewControls, contains('_ReceiptSectionPositionChip'));
    expect(commonControls, contains('_ReceiptActionRailButton'));
    expect(
      contextControls,
      contains(
        'Photo captured locally. Next opens receipt details. Use Add Another Photo only if the receipt continues.',
      ),
    );
    expect(
      reviewPreviewActionTray,
      contains('receipt sections are saved locally.'),
    );
    expect(reviewPreviewActionTray, contains('Next opens receipt'));
    expect(
      reviewPreviewActionTray,
      contains('details with item prices, totals, and business/personal use.'),
    );
    expect(sectionLabels, contains('Receipt Sections'));
    expect(reviewPreviewControls, contains('addNextSectionLabel'));
    expect(contextControls, contains('Saved proof'));
    expect(contextControls, contains('OCR uses the clear photo first'));
    expect(
      reviewScreen,
      contains(
        '_ReceiptReviewMode.preview => _photoPaths.length > 1 ? 164.0 : 142.0',
      ),
    );
    expect(
      reviewScreen,
      contains('maxHeight: _reviewBottomControlsMaxHeight(context)'),
    );
    expect(reviewScreen, contains('double _reviewBottomControlsMaxHeight'));
    expect(reviewScreen, contains('164.0 : 142.0'));
    expect(reviewScreen, contains('_ReceiptReviewMode.preview => .20'));
    expect(reviewScreen, contains('_ReceiptReviewMode.stitch => .20'));
    expect(reviewScreen, contains('_ReceiptReviewMode.dataSaver => .20'));
    expect(reviewScreen, contains('_ReceiptReviewMode.stitch => 164.0'));
    expect(reviewScreen, contains('_ReceiptReviewMode.dataSaver => 168.0'));
    expect(reviewScreen, contains('Widget _buildReviewBottomControls'));
    expect(reviewScreen, contains('return controls;'));
    expect(
      reviewScreen,
      contains('if (!didPop) leaveReceiptReviewWithoutSaving();'),
    );
    expect(reviewActions, contains('final navigator = Navigator.of(context);'));
    expect(reviewActions, contains('ReceiptPhotoReviewResult.keptForLater'));
    expect(reviewActions, contains('navigator.pop(keptForLaterResult);'));
    expect(
      reviewActions,
      isNot(contains('Future<void> _cleanupAbandonedReceiptReview()')),
    );
    expect(
      reviewActions,
      contains('await _deleteGeneratedEditPhotos(_photoPaths.toSet())'),
    );
    expect(importActions, contains('ReceiptAttachmentStorageState.staged'));
    expect(reviewScreen, isNot(contains('_confirmExit')));
    expect(
      reviewScreen,
      isNot(contains('Tap the receipt to hide controls. Pinch to zoom.')),
    );
    expect(reviewScreen, isNot(contains('class _ReceiptImageViewportHint')));
    expect(dataSaverPanel, contains('Saved proof image'));
    expect(
      dataSaverPanel,
      contains('Receipt assistance uses the clear OCR source'),
    );
    expect(
      dataSaverPanel,
      contains(
        'The image behind this panel is the saved proof preview. Receipt assistance uses the clear OCR source first.',
      ),
    );
    expect(dataSaverPanel, contains('Proof kept after reading'));
    expect(dataSaverPanel, contains('Backup status'));
    expect(dataSaverPanel, isNot(contains('Cloud backup copy')));
    expect(dataSaverPanel, isNot(contains('Saved copy')));
    expect(reviewControls, contains('_ReceiptPreviewActionTray'));
    expect(reviewPreviewControls, contains('_ReceiptSinglePhotoActionRow'));
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
  });
}

void _expectNoCloudRequiredCopy(String source) {
  final lower = source.toLowerCase();
  expect(lower, isNot(contains('cloud required')));
  expect(lower, isNot(contains('requires cloud')));
  expect(lower, isNot(contains('must use cloud')));
  expect(lower, isNot(contains('cloud-only')));
  expect(lower, isNot(contains('cloud only')));
  expect(lower, isNot(contains('internet required')));
}
