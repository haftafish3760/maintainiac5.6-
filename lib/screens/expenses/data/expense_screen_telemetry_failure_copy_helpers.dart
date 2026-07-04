part of 'expense_screen_telemetry.dart';

class _ResolvedExpenseFailure {
  const _ResolvedExpenseFailure({
    required this.workflowStep,
    required this.failedAt,
    required this.confirmedCause,
    required this.causeStatus,
    required this.evidence,
    required this.missingEvidence,
  });

  final String workflowStep;
  final String failedAt;
  final String confirmedCause;
  final String causeStatus;
  final String evidence;
  final String missingEvidence;
}

String _humanizeToken(String value) {
  final clean = value
      .replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'),
        (match) => '${match.group(1)} ${match.group(2)}',
      )
      .replaceAll(RegExp(r'[_\-.]+'), ' ')
      .trim();
  if (clean.isEmpty) return 'Unknown';
  final words = clean.split(RegExp(r'\s+'));
  return words
      .asMap()
      .entries
      .map((entry) {
        final lower = entry.value.toLowerCase();
        if (lower == 'ocr') return 'OCR';
        if (lower == 'pdf') return 'PDF';
        if (lower == 'hive') return 'Hive';
        if (entry.key == 0) {
          return entry.value[0].toUpperCase() + entry.value.substring(1);
        }
        return lower;
      })
      .join(' ');
}

String _causeStatusLabel(String status) {
  return status == ExpenseFailureCauseStatus.confirmed.name
      ? 'Confirmed cause'
      : 'Cause not confirmed';
}

String _missingEvidenceLabel(String missingEvidence) {
  if (missingEvidence == 'none') return 'No missing evidence';
  return 'Missing evidence: ${_compactReadableText(_privacySafeFailurePhrase(missingEvidence), 96)}';
}

String _evidenceLabel(String evidence) {
  return _compactReadableText(_privacySafeFailurePhrase(evidence), 96);
}

String _safeDiagnosticLabel(String value) {
  final safePhrase = _compactReadableText(_privacySafeFailurePhrase(value), 96);
  return _displayKnownAcronyms(safePhrase);
}

String _recommendedActionFor({
  required String workflowStep,
  required String confirmedCause,
  required String causeStatus,
  required String missingEvidence,
}) {
  if (causeStatus != ExpenseFailureCauseStatus.confirmed.name) {
    return 'Collect ${_privacySafeFailurePhrase(missingEvidence)} so the app can confirm the cause.';
  }
  final causeAction = switch (confirmedCause) {
    'receipt_photo_quality_needs_review' =>
      'Have the user retake the receipt with better focus, lighting, and full-page coverage before trusting OCR.',
    'receipt_photo_read_failed' =>
      'Check photo file access and image decoding, then ask for a retake or manual entry if the file is damaged.',
    'pdf_safety_blocked' =>
      'Keep the PDF as proof only, block text extraction, and ask for a safe copy or receipt photo.',
    'pdf_too_large' =>
      'Ask for fewer PDF pages, a smaller file, or receipt photos split into readable sections.',
    'pdf_unreadable' || 'pdf_read_failed' =>
      'Check PDF rendering and file validity, then ask for a readable PDF, receipt photo, or pasted text.',
    'ocr_plugin_unavailable' =>
      'Confirm the OCR plugin is bundled for this build and route the user to manual entry until it is available.',
    'receipt_source_skipped' =>
      'Check device capability limits and whether the skipped attachment was saved as proof only.',
    'possible_missing_receipt_section' =>
      'Ask the user to add the missing middle receipt section, then verify line order from top to bottom before saving.',
    'receipt_photo_overlap' =>
      'Review the stitch overlap area and adjust duplicate suppression so charges are not missed or counted twice.',
    'duplicate_receipt_text' =>
      'Review duplicate suppression for the overlap area so repeated long-receipt sections do not create duplicate charges.',
    'missing_receipt_attachment' =>
      'Ask the user to attach a receipt photo, PDF, or pasted receipt text before starting OCR.',
    'no_readable_text' =>
      'Check whether the attachment was blank, cropped, dark, or not a receipt, then ask for another section or manual entry.',
    'ocr_unknown_failure' =>
      'Open the OCR warning diagnostics, capture the warning kind, source, and device tier, then add a specific detector for this failure.',
    'receipt_parser_no_usable_fields' =>
      'Review OCR text quality and parser rules because no safe merchant, date, total, or line data could be filled.',
    'receipt_ocr_missing_vendor' =>
      'Inspect OCR header detection and vendor alias rules; the receipt text was read but no safe store-name candidate reached the parser.',
    'receipt_ocr_missing_date' =>
      'Inspect OCR date detection and receipt-header coverage; the OCR handoff did not provide a safe receipt date candidate.',
    'receipt_ocr_missing_total' =>
      'Inspect receipt bottom coverage and total-label detection; the OCR handoff did not provide a safe total candidate.',
    'receipt_ocr_missing_summary' =>
      'Inspect bottom-section coverage and summary-label detection; subtotal, tax, and total signals were missing from parser handoff.',
    'receipt_ocr_missing_tax' =>
      'Inspect tax-label detection and summary parsing; subtotal or summary evidence was present but no safe tax candidate reached the parser.',
    'receipt_ocr_no_priced_lines' =>
      'Inspect OCR price detection, contrast cleanup, and whether item prices are too small or cropped before parser handoff.',
    'receipt_ocr_no_item_lines' =>
      'Inspect item-line detection rules; OCR saw priced lines but none were safe receipt item rows.',
    'receipt_ocr_no_parser_ready_items' =>
      'Improve item confidence rules or ask for a clearer/additional receipt section because OCR found item lines but none were safe enough to trust.',
    'receipt_ocr_line_sequence_review' =>
      'Inspect long-receipt section order, overlap handling, and missing middle sections before trusting parsed line items.',
    'receipt_ocr_summary_math_review' =>
      'Inspect subtotal, tax, total, discount, fee, and return handling from the OCR handoff before trusting parsed totals.',
    'receipt_ocr_parser_readiness_review' =>
      'Review OCR parser-readiness buckets and add a focused fixture for the exact receipt shape before trusting automatic line fill.',
    'receipt_line_total_mismatch' =>
      'Add this receipt shape to parser tests and inspect missing, duplicated, return, discount, fee, or skipped long-receipt lines.',
    'receipt_subtotal_tax_total_mismatch' =>
      'Inspect subtotal, tax, fees, discounts, and total extraction before allowing the parsed totals to be trusted.',
    'receipt_parser_totals_found_no_safe_lines' =>
      'Keep the detected receipt total, route the user to total-only or manual line entry, and add a parser fixture for this receipt shape.',
    'receipt_totals_only_no_line_items' =>
      'Keep the receipt reviewable, but improve line detection for this vendor or device tier before expecting item-level detail.',
    'receipt_total_missing' =>
      'Inspect total-label detection and receipt bottom-section coverage; long receipts may be missing their final photo/PDF page.',
    'receipt_date_missing' =>
      'Inspect date-format parsing for this vendor and region.',
    'receipt_merchant_missing' =>
      'Add vendor aliases or header parsing coverage for this receipt shape.',
    'inventory_catalog_match_weak' =>
      'Review material aliases and catalog terms for this trade pack before expanding catalog volume.',
    'receipt_lines_need_review' =>
      'Inspect low-confidence line classification and add parser fixtures for the repeated receipt pattern.',
    'receipt_parser_low_confidence' =>
      'Review parser confidence reasons and add focused fixtures before trusting automatic fill for this receipt shape.',
    _ => '',
  };
  if (causeAction.isNotEmpty) return causeAction;
  return switch (workflowStep) {
    'receiptAttachment' =>
      'Review receipt proof capture, file access, and photo/PDF storage for this step.',
    'receiptOcr' =>
      'Review receipt image quality, OCR source limits, and whether the user should retake or add another section.',
    'receiptParser' =>
      'Add or adjust parser tests for this receipt shape before changing user-facing behavior.',
    'lineReview' =>
      'Check the receipt review flow and whether the user had enough guidance to finish.',
    'saveExpense' =>
      'Inspect local ledger save, Hive state, duplicate handling, and receipt proof promotion.',
    'export' =>
      'Inspect export limits, file creation, and handoff/share behavior.',
    'sync' || 'cloudBackup' || 'materialsBridge' =>
      'Inspect local queue state, retry behavior, and hosted sync handoff.',
    _ =>
      'Review the workflow step and add a more specific diagnostic if needed.',
  };
}

String _privacySafeFailurePhrase(String value) {
  final withoutAmounts = value
      .replaceAll(RegExp(r'\$+\s*\d+(?:[._\s]\d+)?'), ' amount ')
      .replaceAll(RegExp(r'\d+[._]\d{2,}'), ' amount ')
      .replaceAll(RegExp(r'\b\d+\s+\d{2,}\b'), ' amount ')
      .replaceAll(RegExp(r'(?<![A-Za-z0-9])\d{3,}(?![A-Za-z0-9])'), ' number ')
      .replaceAll(RegExp(r'[_\-.]+'), ' ');
  final generic = withoutAmounts
      .replaceAll(_privateReceiptNotePattern, ' private reference ')
      .replaceAll(_knownReceiptMerchantPattern, ' merchant ')
      .replaceAll(_knownReceiptLocationPattern, ' location ')
      .replaceAll(
        RegExp(r'\breceipt\s+number\b', caseSensitive: false),
        ' private reference ',
      )
      .replaceAll(_privateReceiptIdentifierPattern, ' private reference ')
      .replaceAll(
        RegExp(
          r'\b[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}\b',
          caseSensitive: false,
        ),
        ' email ',
      )
      .replaceAll(
        RegExp(r'\b(?:\+?1[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}\b'),
        ' phone ',
      )
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final humanized = _humanizeToken(generic).toLowerCase();
  return humanized.isEmpty ? 'diagnostic context' : humanized;
}

String _compactReadableText(String value, int maxChars) {
  final clean = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (clean.length <= maxChars) return clean;
  final hardCut = clean.substring(0, maxChars).trimRight();
  final lastSpace = hardCut.lastIndexOf(' ');
  if (lastSpace >= (maxChars * 0.65).floor()) {
    return hardCut.substring(0, lastSpace).trimRight();
  }
  return hardCut;
}

String _displayKnownAcronyms(String value) {
  final clean = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (clean.isEmpty) return 'Unknown';
  final words = clean.split(' ');
  return words
      .asMap()
      .entries
      .map((entry) {
        final word = entry.value.toLowerCase();
        if (word == 'ocr') return 'OCR';
        if (word == 'pdf') return 'PDF';
        if (word == 'hive') return 'Hive';
        if (entry.key == 0) return word[0].toUpperCase() + word.substring(1);
        return word;
      })
      .join(' ');
}

String _savedPhotoWarningAction(String warningCode, String severity) {
  if (warningCode.isEmpty && severity.isEmpty) return '';
  return switch (warningCode) {
    'saved_photo_darker_than_preview' =>
      'Review native camera exposure. Ask the user to retake with more light or raise Brightness before continuing.',
    'saved_photo_soft_blur_risk' =>
      'Review native continuous-focus and shutter stability. Ask the user to hold steady, wait for sharp readable text, and retake if prices look fuzzy.',
    'saved_photo_dimmer_than_preview' =>
      'Review lighting guidance. Let the user continue if text is readable, but suggest torch or more light when the bottom looks dim.',
    'saved_photo_glare_risk' =>
      'Review glare guidance. Ask the user to tilt the receipt or light source and retake if totals are washed out.',
    _ =>
      severity == 'critical'
          ? 'Review critical native camera saved-photo diagnostics before trusting receipt OCR results.'
          : 'Review native camera saved-photo diagnostics and tune guidance if this warning repeats.',
  };
}

String _nativeRecoveryAction({
  required Map<String, int> freshnessCounts,
  required Map<String, int> storageStatusCounts,
}) {
  if ((storageStatusCounts['photos_missing'] ?? 0) > 0) {
    return 'Recover or discard the interrupted receipt before OCR. Saved photos are missing, so do not trust automatic receipt fill until the user retakes or manually confirms the receipt.';
  }
  if ((storageStatusCounts['partial_photos_available'] ?? 0) > 0) {
    return 'Review the interrupted receipt recovery before OCR. Some saved sections are available, but the user may need to add the missing receipt photos or retake the full receipt.';
  }
  if ((freshnessCounts['very_stale'] ?? 0) > 0) {
    return 'Clear very old interrupted receipt recoveries. Ask the user to confirm, discard, or retake before allowing automatic receipt fill.';
  }
  if ((freshnessCounts['stale'] ?? 0) > 0) {
    return 'Prompt the user to finish or discard the stale interrupted receipt so OCR starts from a known current receipt source.';
  }
  return '';
}
