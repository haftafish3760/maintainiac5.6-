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
    final uiConfig = await File(
      'lib/shared/widgets/receipt_capture/receipt_capture_ui_config.dart',
    ).readAsString();
    expect(settingsSheet, contains('uiConfig.settings.helpLabel'));
    expect(uiConfig, contains("this.helpLabel = 'Receipt Photo Help'"));
    expect(settingsSheet, isNot(contains('How Receipt Photos Work')));
    expect(helpSheet, contains('Receipt Photo Help'));
    expect(helpSheet, contains('uiConfig.firstUseTitle'));
    expect(helpSheet, contains('uiConfig.enableAssistLabel'));
    expect(helpSheet, contains('uiConfig.manualEntryLabel'));
    expect(uiConfig, contains("this.firstUseTitle = 'Receipt Assist'"));
    expect(
      uiConfig,
      contains(
        'Receipt Assist reads the accepted photo and suggests totals and lines. You review everything before saving.',
      ),
    );
    expect(helpSheet, isNot(contains('Clear Photo First')));
    expect(helpSheet, isNot(contains('Open Receipt Settings')));
    expect(helpSheet, isNot(contains('flash, focus')));
    expect(helpSheet, isNot(contains('Storage And Privacy')));
    expect(importActions, isNot(contains('parserPackInstallChoice')));
    expect(attachmentOcrSourceRiskFlags, contains('ocr_source_retake_risk'));
    expect(helpSheet, isNot(contains('profile.summaryLabel')));
    expect(helpSheet, isNot(contains('deviceModel')));
    expect(helpSheet, isNot(contains('availableRamLabel')));
    expect(importActions, contains('_showFirstUseReceiptCameraIntro'));
    expect(
      importActions,
      contains('!settings.hasReceiptAssistChoiceFor(widget.area)'),
    );
    expect(
      importActions,
      contains('settings.setReceiptAssistChoiceMadeFor(widget.area, true)'),
    );
    expect(
      helpSheet,
      contains('_ReceiptFirstUseCameraAction.useReceiptAssist'),
    );
    expect(helpSheet, contains('_ReceiptFirstUseCameraAction.manualEntry'));
    expect(attachmentPublishHelpers, contains('openReceiptCaptureSettings()'));
    expect(settingsSheet, contains('Expense Receipt Settings'));
    expect(
      settingsSheet,
      contains('Let Maintainiac Help Fill Expense Receipts'),
    );
    expect(settingsSheet, contains("title: 'Capture Flow'"));
    expect(settingsSheet, contains('ReceiptCaptureSettingsScope'));
    expect(settingsSheet, contains('settings.privacySafeCapabilityLabel'));
    expect(settingsSheet, contains('Detected safely:'));
    expect(settingsSheet, isNot(contains('deviceManufacturer')));
    expect(settingsSheet, isNot(contains('deviceModel')));
    expect(settingsSheet, isNot(contains('deviceName')));
    expect(settingsSheet, contains('Show Long Receipt Tips'));
    expect(settingsSheet, contains("title: 'Receipt Details And Saved Proof'"));
    expect(settingsSheet, contains('required this.hasSavedReceiptProof'));
    expect(settingsSheet, contains('if (!hasSavedReceiptProof) ...['));
    expect(
      settingsSheet,
      contains(
        'Saved Receipt Proof Size appears after your first receipt photo or file is attached.',
      ),
    );
    expect(
      settingsSheet,
      contains('Receipt Assist reads the full-quality temporary source'),
    );
    expect(settingsSheet, contains('After You Take Photos'));
    expect(
      settingsSheet,
      contains('Extra cloud or offline receipt help must remain optional'),
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
    expect(settingsSheet, contains('Simple Receipt'));
    expect(settingsSheet, contains('Detailed Receipt'));
    expect(
      settingsSheet,
      contains(
        'Choose what Maintainiac shows after it reads an expense receipt.',
      ),
    );
    expect(settingsSheet, contains('as all Business or all Personal'));
    expect(settingsSheet, contains('ExpenseSettingsScope.maybeOf(context)'));
    expect(settingsSheet, contains('ExpenseReceiptReviewStyle.simpleAmounts'));
    expect(
      settingsSheet,
      contains('ExpenseReceiptReviewStyle.fullItemDetails'),
    );
    expect(
      settingsSheet,
      contains('Capture settings do not replace your phone camera software.'),
    );
    expect(settingsSheet, contains('uiConfig.settings.applyLabel'));
    expect(settingsSheet, contains('Navigator.of(context).pop(true)'));
    expect(settingsSheet, contains('uiConfig.settings.resetLabel'));
    expect(settingsSheet, contains('Reset Defaults'));
    expect(settingsSheet, contains('uiConfig.settings.showHelpAction'));
    expect(settingsSheet, contains('inspect readability before saving'));
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
    expect(reviewControls, contains("return 'Use Receipt';"));
    expect(reviewControls, contains('_ReceiptPreviewActionTray'));
    expect(reviewPreviewControls, contains('_ReceiptMultiPhotoActionRail'));
    expect(reviewPreviewControls, contains('_ReceiptSectionPositionChip'));
    expect(commonControls, contains('_ReceiptActionRailButton'));
    expect(
      contextControls,
      contains(
        'Photo captured locally. Use this photo, retake it, or add another photo if the receipt continues.',
      ),
    );
    expect(
      reviewPreviewActionTray,
      contains('receipt sections are saved locally.'),
    );
    expect(reviewPreviewActionTray, contains('Use this receipt'));
    expect(
      reviewPreviewActionTray,
      contains('Use Receipt will use one combined receipt image.'),
    );
    expect(sectionLabels, contains('Receipt Sections'));
    expect(reviewPreviewControls, contains('addNextSectionLabel'));
    expect(contextControls, contains('Saved proof'));
    expect(contextControls, contains('OCR uses the clear photo first'));
    expect(reviewScreen, contains('widget.uiConfig.showTopBar'));
    expect(reviewScreen, contains('Expanded('));
    expect(reviewScreen, contains('_buildPhotoSurface('));
    expect(
      reviewScreen,
      contains('child: _buildReviewBottomControls(photoPath)'),
    );
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
    expect(dataSaverPanel, contains("label: 'Receipt assistance'"));
    expect(dataSaverPanel, contains("value: 'Uses clear photo first'"));
    expect(dataSaverPanel, contains('Capture source size'));
    expect(dataSaverPanel, isNot(contains('Original photo')));
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
