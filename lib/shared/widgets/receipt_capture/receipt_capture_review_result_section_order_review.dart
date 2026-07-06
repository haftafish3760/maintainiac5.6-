part of 'receipt_capture_models.dart';

extension ReceiptPhotoReviewResultSectionOrderOutcome
    on ReceiptPhotoReviewResult {
  String get receiptSectionOrderOutcome {
    final counts = receiptSectionOrderCounts;
    if (counts.isEmpty) return 'unknown';
    if (counts.keys.any((key) => key.startsWith('retake_invalid_'))) {
      return 'retake_order_invalid';
    }
    if (counts.keys.any((key) => key.startsWith('insert_invalid_'))) {
      return 'insert_order_invalid';
    }
    if (counts.keys.any((key) => key.startsWith('manual_reorder_invalid_'))) {
      return 'manual_reorder_invalid';
    }
    if ((counts['retake_preserved_original_slot'] ?? 0) > 0) {
      return 'retake_order_preserved';
    }
    if ((counts['insert_preserved_anchor_slot'] ?? 0) > 0) {
      return 'insert_order_preserved';
    }
    if ((counts['manual_reorder_preserved_photo_path'] ?? 0) > 0) {
      return 'manual_reorder_preserved';
    }
    if ((counts['policy_top_to_bottom_numbered_sections'] ?? 0) > 0 &&
        (counts['ghost_guide_visible'] ?? 0) > 0) {
      return 'numbered_sections_with_ghost_guide';
    }
    if ((counts['policy_top_to_bottom_numbered_sections'] ?? 0) > 0) {
      return 'numbered_sections_top_to_bottom';
    }
    if (counts.keys.any((key) => key.startsWith('multi_section_'))) {
      return 'multi_section_order_tracked';
    }
    return 'single_section_or_unordered';
  }

  String get receiptSectionOrderEvidenceLabel {
    final counts = receiptSectionOrderCounts;
    if (counts.isEmpty) return 'section_order=unknown';
    final outcome = receiptSectionOrderOutcome;
    final sectionCount = counts.entries
        .where((entry) => entry.key.startsWith('multi_section_'))
        .fold<int>(0, (total, entry) => total + entry.value);
    final ghost = (counts['ghost_guide_visible'] ?? 0) > 0
        ? 'ghost_visible'
        : (counts['ghost_guide_hidden'] ?? 0) > 0
        ? 'ghost_hidden'
        : 'ghost_unknown';
    final label =
        'section_order=$outcome;multi_section_photos=$sectionCount;$ghost';
    if (outcome == 'retake_order_invalid') return '$label;retake_invalid';
    if (outcome == 'insert_order_invalid') return '$label;insert_invalid';
    if (outcome == 'manual_reorder_invalid') {
      return '$label;manual_reorder_invalid';
    }
    if ((counts['retake_preserved_original_slot'] ?? 0) > 0) {
      return '$label;retake_preserved';
    }
    if ((counts['insert_preserved_anchor_slot'] ?? 0) > 0) {
      return '$label;insert_preserved';
    }
    if ((counts['manual_reorder_preserved_photo_path'] ?? 0) > 0) {
      return '$label;manual_reorder_preserved';
    }
    return label;
  }
}

extension ReceiptPhotoReviewResultSectionOrderReview
    on ReceiptPhotoReviewResult {
  bool get receiptSectionOrderNeedsReview =>
      receiptSectionOrderReviewActionCode.startsWith('review_') &&
      (receiptSectionOrderReviewActionCode.contains('_before_ocr') ||
          receiptSectionOrderOutcome.endsWith('_invalid'));

  String get receiptSectionOrderReviewActionCode {
    final outcome = receiptSectionOrderOutcome;
    final counts = receiptSectionOrderCounts;
    if (outcome == 'retake_order_invalid') {
      return 'review_retaken_section_order_before_ocr';
    }
    if (outcome == 'insert_order_invalid') {
      return 'review_inserted_section_order_before_ocr';
    }
    if (outcome == 'manual_reorder_invalid') {
      return 'review_manual_section_order_before_ocr';
    }
    if (outcome == 'numbered_sections_with_ghost_guide') {
      return 'review_long_receipt_order_with_ghost_guide';
    }
    if (outcome == 'numbered_sections_top_to_bottom') {
      return 'review_numbered_sections_top_to_bottom';
    }
    if (outcome == 'retake_order_preserved') {
      return 'review_retaken_section_then_continue';
    }
    if (outcome == 'insert_order_preserved') {
      return 'review_inserted_section_then_continue';
    }
    if (outcome == 'manual_reorder_preserved') {
      return 'review_reordered_sections_then_continue';
    }
    if (counts.keys.any((key) => key.startsWith('multi_section_'))) {
      return 'review_multi_section_order';
    }
    return 'review_single_section';
  }

  String get receiptSectionOrderReviewActionLabel {
    return switch (receiptSectionOrderReviewActionCode) {
      'review_retaken_section_order_before_ocr' =>
        'Review the retaken receipt section order before OCR reads the receipt.',
      'review_inserted_section_order_before_ocr' =>
        'Review the inserted receipt section order before OCR reads the receipt.',
      'review_manual_section_order_before_ocr' =>
        'Review the manually reordered receipt sections before OCR reads the receipt.',
      'review_long_receipt_order_with_ghost_guide' =>
        'Check each long-receipt section from top to bottom using the ghost overlap guide.',
      'review_numbered_sections_top_to_bottom' =>
        'Check numbered receipt sections from top to bottom before OCR.',
      'review_retaken_section_then_continue' =>
        'Confirm the retaken section stayed in its original receipt position.',
      'review_inserted_section_then_continue' =>
        'Confirm the inserted receipt section appears after the selected section.',
      'review_reordered_sections_then_continue' =>
        'Confirm the manual receipt section order before continuing.',
      'review_multi_section_order' =>
        'Check the multi-photo receipt order before OCR reads the receipt.',
      _ => 'Review the receipt photo before OCR reads the receipt.',
    };
  }
}
