part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptLineComputedFields on _ExpenseReceiptLine {
  String get quantityText => quantity == quantity.roundToDouble()
      ? quantity.toInt().toString()
      : '$quantity';
  String get unitsPerPackageText =>
      unitsPerPackage == unitsPerPackage.roundToDouble()
      ? unitsPerPackage.toInt().toString()
      : '$unitsPerPackage';
  String get subtotalText => subtotal == 0 ? '' : subtotal.toStringAsFixed(2);
  String get businessPercentText {
    if (use != _ExpenseLineUse.split) return '50';
    final percent = (businessPercent ?? .5) * 100;
    return percent == percent.roundToDouble()
        ? percent.toInt().toString()
        : percent.toStringAsFixed(2);
  }

  double get totalUnits => quantity * unitsPerPackage;

  String get displayDescription {
    final clean = description.trim();
    if (clean.isNotEmpty && clean.toLowerCase() != 'receipt item') {
      return clean;
    }
    return switch (use) {
      _ExpenseLineUse.business => 'Business receipt items',
      _ExpenseLineUse.personal => 'Personal receipt items',
      _ExpenseLineUse.split => 'Split receipt items',
    };
  }

  double get effectiveBusinessPercent {
    return switch (use) {
      _ExpenseLineUse.business => 1,
      _ExpenseLineUse.personal => 0,
      _ExpenseLineUse.split => businessPercent ?? .5,
    };
  }

  double get effectivePersonalPercent => 1 - effectiveBusinessPercent;

  String get allocationSummary {
    if (use != _ExpenseLineUse.split) return use.label;
    return 'Split ${_percent(effectiveBusinessPercent)} business';
  }

  String get allocationDetail {
    return switch (use) {
      _ExpenseLineUse.business => 'Business ${_money(subtotal)}',
      _ExpenseLineUse.personal => 'Personal ${_money(subtotal)}',
      _ExpenseLineUse.split =>
        'Business ${_money(businessAmount)} | Personal ${_money(personalAmount)}',
    };
  }

  bool get hasParserReview {
    return parserConfidence != null ||
        (parserReviewLabel ?? '').trim().isNotEmpty ||
        (parserReviewReason ?? '').trim().isNotEmpty ||
        parserNeedsReview;
  }

  bool get cameFromAppAssistedReceiptRead {
    return rawReceiptText.trim().isNotEmpty || hasParserReview;
  }

  String get parserReviewSummary {
    final label = (parserReviewLabel ?? '').trim().isEmpty
        ? (parserNeedsReview ? 'Review' : 'App Fill')
        : parserReviewLabel!.trim();
    final confidence = parserConfidence;
    if (confidence == null) return label;
    return '$label ${(confidence * 100).round()}%';
  }

  String get receiptEvidenceText {
    final raw = rawReceiptText.trim();
    if (raw.isNotEmpty) return raw;
    return description.trim();
  }

  String get ocrSourceLineLabel {
    final sectionLine = ocrSourceSectionLineNumber;
    final section = ocrSourceSectionNumber;
    if (sectionLine != null && sectionLine > 0) {
      if (section != null && section > 1) {
        return 'OCR section $section line $sectionLine';
      }
      return 'OCR source line $sectionLine';
    }
    final lineNumber = ocrSourceLineNumber;
    if (lineNumber != null && lineNumber > 0) return 'OCR line $lineNumber';
    final sourceId = (ocrSourceLineId ?? '').trim();
    if (sourceId.isNotEmpty) return sourceId;
    return '';
  }

  bool get hasOcrSourceLine => ocrSourceLineLabel.isNotEmpty;

  double get businessAmount {
    return switch (use) {
      _ExpenseLineUse.business => subtotal,
      _ExpenseLineUse.personal => 0,
      _ExpenseLineUse.split => subtotal * effectiveBusinessPercent,
    };
  }

  double get personalAmount {
    return switch (use) {
      _ExpenseLineUse.business => 0,
      _ExpenseLineUse.personal => subtotal,
      _ExpenseLineUse.split => subtotal * effectivePersonalPercent,
    };
  }
}
