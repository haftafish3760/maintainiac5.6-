import 'package:flutter/material.dart';

import 'receipt_photo_review_ui_config.dart';

/// Product-facing presentation controls for the receipt workflow.
///
/// This keeps product copy and layout choices editable while camera capture,
/// image preparation, OCR, and parsing remain independent of the UI layer.
class ReceiptCaptureUiConfig {
  const ReceiptCaptureUiConfig({
    this.review = const ReceiptPhotoReviewUiConfig(),
    this.settings = const ReceiptCaptureSettingsUiConfig(),
    this.pageBackgroundColor = const Color(0xFF050607),
    this.surfaceColor = const Color(0xFF11181B),
    this.borderColor = const Color(0xFF526168),
    this.primaryActionColor = const Color(0xFF28A745),
    this.firstUseTitle = 'Receipt Assist',
    this.firstUsePrompt =
        'Would you like Maintainiac to help fill out receipt details?',
    this.firstUseExplanation =
        'Receipt Assist reads the accepted photo and suggests totals and lines. You review everything before saving.',
    this.enableAssistLabel = 'Yes, Use Receipt Assist',
    this.manualEntryLabel = 'No, Manual Entry',
    this.showFirstUsePromiseList = true,
    this.showManualEntryReminder = true,
    this.showReadProgressSteps = true,
    this.progressAcceptedLabel = 'Photo accepted',
    this.progressReadingLabel = 'Reading receipt text',
    this.progressOpeningLabel = 'Opening receipt details',
  });

  final ReceiptPhotoReviewUiConfig review;
  final ReceiptCaptureSettingsUiConfig settings;
  final Color pageBackgroundColor;
  final Color surfaceColor;
  final Color borderColor;
  final Color primaryActionColor;
  final String firstUseTitle;
  final String firstUsePrompt;
  final String firstUseExplanation;
  final String enableAssistLabel;
  final String manualEntryLabel;
  final bool showFirstUsePromiseList;
  final bool showManualEntryReminder;
  final bool showReadProgressSteps;
  final String progressAcceptedLabel;
  final String progressReadingLabel;
  final String progressOpeningLabel;

  ReceiptCaptureUiConfig copyWith({
    ReceiptPhotoReviewUiConfig? review,
    ReceiptCaptureSettingsUiConfig? settings,
    Color? pageBackgroundColor,
    Color? surfaceColor,
    Color? borderColor,
    Color? primaryActionColor,
    String? firstUseTitle,
    String? firstUsePrompt,
    String? firstUseExplanation,
    String? enableAssistLabel,
    String? manualEntryLabel,
    bool? showFirstUsePromiseList,
    bool? showManualEntryReminder,
    bool? showReadProgressSteps,
    String? progressAcceptedLabel,
    String? progressReadingLabel,
    String? progressOpeningLabel,
  }) {
    return ReceiptCaptureUiConfig(
      review: review ?? this.review,
      settings: settings ?? this.settings,
      pageBackgroundColor: pageBackgroundColor ?? this.pageBackgroundColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      borderColor: borderColor ?? this.borderColor,
      primaryActionColor: primaryActionColor ?? this.primaryActionColor,
      firstUseTitle: firstUseTitle ?? this.firstUseTitle,
      firstUsePrompt: firstUsePrompt ?? this.firstUsePrompt,
      firstUseExplanation: firstUseExplanation ?? this.firstUseExplanation,
      enableAssistLabel: enableAssistLabel ?? this.enableAssistLabel,
      manualEntryLabel: manualEntryLabel ?? this.manualEntryLabel,
      showFirstUsePromiseList:
          showFirstUsePromiseList ?? this.showFirstUsePromiseList,
      showManualEntryReminder:
          showManualEntryReminder ?? this.showManualEntryReminder,
      showReadProgressSteps:
          showReadProgressSteps ?? this.showReadProgressSteps,
      progressAcceptedLabel:
          progressAcceptedLabel ?? this.progressAcceptedLabel,
      progressReadingLabel: progressReadingLabel ?? this.progressReadingLabel,
      progressOpeningLabel: progressOpeningLabel ?? this.progressOpeningLabel,
    );
  }
}

class ReceiptCaptureSettingsUiConfig {
  const ReceiptCaptureSettingsUiConfig({
    this.backTooltip = 'Back',
    this.helpLabel = 'Receipt Photo Help',
    this.resetLabel = 'Reset Receipt Photo Defaults',
    this.applyLabel = 'Apply Settings',
    this.showHelpAction = true,
    this.showResetAction = true,
    this.showApplyAction = true,
  });

  final String backTooltip;
  final String helpLabel;
  final String resetLabel;
  final String applyLabel;
  final bool showHelpAction;
  final bool showResetAction;
  final bool showApplyAction;

  ReceiptCaptureSettingsUiConfig copyWith({
    String? backTooltip,
    String? helpLabel,
    String? resetLabel,
    String? applyLabel,
    bool? showHelpAction,
    bool? showResetAction,
    bool? showApplyAction,
  }) {
    return ReceiptCaptureSettingsUiConfig(
      backTooltip: backTooltip ?? this.backTooltip,
      helpLabel: helpLabel ?? this.helpLabel,
      resetLabel: resetLabel ?? this.resetLabel,
      applyLabel: applyLabel ?? this.applyLabel,
      showHelpAction: showHelpAction ?? this.showHelpAction,
      showResetAction: showResetAction ?? this.showResetAction,
      showApplyAction: showApplyAction ?? this.showApplyAction,
    );
  }
}
