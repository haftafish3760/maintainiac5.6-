part of 'expense_ledger_models.dart';

String _receiptOcrCommandCenterTextOrEmpty(String value) {
  final text = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (text.isEmpty || text.length > 220) return '';
  if (_receiptOcrLooksPrivateForCommandCenter(text)) return '';
  return text;
}

String _receiptOcrCommandCenterTokenOrEmpty(String value) {
  final token = value.trim();
  if (token.isEmpty || token.length > 80) return '';
  if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(token)) return '';
  if (_receiptOcrLooksPrivateForCommandCenter(token)) return '';
  if (!_receiptOcrKnownRecoveryTokens.contains(token)) return '';
  return token;
}

const _receiptOcrKnownRecoveryTokens = <String>{
  'add_missing_section',
  'attach_proof',
  'attach_safe_pdf',
  'choose_clearest_source',
  'manual_entry',
  'paste_cleaner_text',
  'replace_pdf_or_add_photo',
  'retake_or_review_photo',
  'retake_photo',
  'retake_photo_or_add_section',
  'review_overlap',
  'review_receipt_manually',
  'review_saved_proof',
  'scan_receipt_with_photos',
  'use_smaller_pdf_or_photos',
  'manual_receipt_entry',
  'receipt_attachment',
  'receipt_pdf',
  'receipt_photo',
  'receipt_review',
  'receipt_sections',
  'receipt_sources',
  'receipt_text',
  'receipt_overlap',
};

bool _receiptOcrLooksPrivateForCommandCenter(String value) {
  final lower = value.toLowerCase();
  final sensitivePatterns = <RegExp>[
    RegExp(r'[/\\][a-z0-9_. -]+[/\\]', caseSensitive: false),
    RegExp(r'\b[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}\b'),
    RegExp(r'\(?\b\d{3}\)?[-.\s]\d{3}[-.\s]\d{4}\b'),
    RegExp(r'\$?\b\d{1,5}[.,]\d{2}\b'),
    RegExp(r'\b\d{4,}\b'),
    RegExp(
      r'\b(?:invoice|auth|transaction|terminal|address|street|st\.?|avenue|ave\.?|lane|ln\.?|road|rd\.?|drive|dr\.?|boulevard|blvd\.?|suite|unit|zip)\b',
    ),
    RegExp(
      r'\b(?:lowe|lowes|lowe'
      's|walmart|target|amazon|shell|exxon|mobil|chevron|marathon|sheetz|private store|customer)\b',
    ),
    RegExp(r'\.(?:jpg|jpeg|png|heic|pdf)\b'),
  ];
  return sensitivePatterns.any((pattern) => pattern.hasMatch(lower));
}

String _receiptOcrIssueForWarningKind(String kind) {
  return switch (kind) {
    'photoQuality' => 'Receipt photo needs review',
    'photoReadFailure' => 'Receipt photo could not be read',
    'pdfReadFailure' => 'Receipt PDF could not be read',
    'pdfSafety' => 'Receipt PDF was blocked for safety',
    'pdfTooLarge' => 'Receipt PDF is too large',
    'sourceSkipped' => 'Receipt source was skipped',
    'sectionGap' => 'Possible missing receipt section',
    'duplicateText' => 'Duplicate receipt lines ignored',
    'noReadableText' => 'No readable receipt text',
    _ => '',
  };
}

String _receiptOcrActionForWarningKind(String kind) {
  return switch (kind) {
    'photoQuality' =>
      'Retake or crop the receipt if focus, lighting, or full-page coverage is not good enough.',
    'photoReadFailure' =>
      'Check the receipt photo proof, then retake or enter the receipt manually if the image cannot be read.',
    'pdfReadFailure' =>
      'Try a readable PDF, a receipt photo, or pasted receipt text.',
    'pdfSafety' =>
      'Keep the PDF as proof only and ask for a safe PDF, receipt photo, or pasted receipt text.',
    'pdfTooLarge' =>
      'Use fewer PDF pages, a smaller file, or readable receipt photos.',
    'sourceSkipped' =>
      'Check whether the skipped receipt source was saved as proof only.',
    'sectionGap' =>
      'Check receipt photos from top to bottom and add the missing middle section if needed.',
    'duplicateText' =>
      'Check long receipt overlap so the same charge was not counted twice.',
    'noReadableText' =>
      'Retake the receipt, add another section, or enter the receipt manually.',
    _ => '',
  };
}

String _receiptOcrRecoveryActionFor(String kind, String source) {
  return switch (kind) {
    'noSource' => 'attach_proof',
    'sourceSkipped' => 'review_saved_proof',
    'duplicateText' || 'probableOverlap' => 'review_overlap',
    'sectionGap' => 'add_missing_section',
    'pdfSafety' => 'attach_safe_pdf',
    'pdfTooLarge' => 'use_smaller_pdf_or_photos',
    'pdfUnreadable' => 'replace_pdf_or_add_photo',
    'pluginUnavailable' => 'manual_entry',
    'photoQuality' => 'retake_or_review_photo',
    'photoReadFailure' => 'retake_photo',
    'pdfReadFailure' => 'scan_receipt_with_photos',
    'unknown' => 'review_receipt_manually',
    'noReadableText' || '' => _receiptOcrSourceRecoveryAction(source),
    _ => _receiptOcrSourceRecoveryAction(source),
  };
}

String _receiptOcrSourceRecoveryAction(String source) {
  return switch (source) {
    'photo' => 'retake_photo_or_add_section',
    'pdf' => 'scan_receipt_with_photos',
    'importedText' => 'paste_cleaner_text',
    'mixed' => 'choose_clearest_source',
    'none' => 'attach_proof',
    _ => 'review_receipt_manually',
  };
}

String _receiptOcrRecoveryTargetFor(String kind, String source) {
  return switch (kind) {
    'noSource' => 'receipt_attachment',
    'duplicateText' || 'probableOverlap' => 'receipt_overlap',
    'sectionGap' => 'receipt_sections',
    'pdfSafety' ||
    'pdfTooLarge' ||
    'pdfUnreadable' ||
    'pdfReadFailure' => 'receipt_pdf',
    'pluginUnavailable' => 'manual_receipt_entry',
    'photoQuality' || 'photoReadFailure' => 'receipt_photo',
    'sourceSkipped' ||
    'noReadableText' ||
    'unknown' ||
    '' => _receiptOcrSourceRecoveryTarget(source),
    _ => _receiptOcrSourceRecoveryTarget(source),
  };
}

String _receiptOcrSourceRecoveryTarget(String source) {
  return switch (source) {
    'photo' => 'receipt_photo',
    'pdf' => 'receipt_pdf',
    'importedText' => 'receipt_text',
    'mixed' => 'receipt_sources',
    'none' => 'receipt_attachment',
    _ => 'receipt_review',
  };
}

String _receiptOcrRecoverySummaryFor(String kind, String source) {
  return switch (kind) {
    'noSource' =>
      'Attach a receipt photo, readable PDF, or pasted receipt text.',
    'sourceSkipped' =>
      'Review the saved proof or turn receipt assistance back on.',
    'duplicateText' ||
    'probableOverlap' => 'Check the long-receipt overlap before saving.',
    'sectionGap' =>
      'Add the missing receipt section or confirm the photos are in order.',
    'pdfSafety' =>
      'Attach a safe PDF copy, scan with photos, or continue by hand.',
    'pdfTooLarge' => 'Use a smaller PDF or scan the receipt with photos.',
    'pdfUnreadable' || 'pdfReadFailure' =>
      'Scan the receipt with photos, attach a clearer PDF, or continue by hand.',
    'pluginUnavailable' => 'Continue with manual entry for this build.',
    'photoQuality' =>
      'Retake the photo if store, date, total, tax, or item prices are not readable.',
    'photoReadFailure' =>
      'Retake the photo, add another clear section, or continue by hand.',
    'unknown' => 'Review the receipt proof and filled fields before saving.',
    'noReadableText' || '' => _receiptOcrSourceRecoverySummary(source),
    _ => _receiptOcrSourceRecoverySummary(source),
  };
}

String _receiptOcrSourceRecoverySummary(String source) {
  return switch (source) {
    'photo' =>
      'Retake the receipt photo, add the missing long-receipt section, or continue by hand.',
    'pdf' => 'Scan the receipt with photos or continue by hand.',
    'importedText' => 'Paste cleaner receipt text or continue by hand.',
    'mixed' =>
      'Choose the clearest receipt source, add a clearer photo, or continue by hand.',
    'none' => 'Attach a receipt photo, readable PDF, or pasted receipt text.',
    _ => 'Review the receipt proof and filled fields before saving.',
  };
}
