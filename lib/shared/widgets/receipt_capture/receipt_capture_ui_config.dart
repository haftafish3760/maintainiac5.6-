import 'package:flutter/material.dart';

import 'receipt_photo_review_ui_config.dart';

/// Product-facing presentation controls for the receipt workflow.
///
/// This keeps product copy and layout choices editable while camera capture,
/// image preparation, OCR, and parsing remain independent of the UI layer.
class ReceiptCaptureUiConfig {
  const ReceiptCaptureUiConfig({
    this.review = const ReceiptPhotoReviewUiConfig(),
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
  });

  final ReceiptPhotoReviewUiConfig review;
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

  ReceiptCaptureUiConfig copyWith({
    ReceiptPhotoReviewUiConfig? review,
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
  }) {
    return ReceiptCaptureUiConfig(
      review: review ?? this.review,
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
    );
  }
}
