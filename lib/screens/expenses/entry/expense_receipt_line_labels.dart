part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptLineLabels on _ExpenseReceiptLine {
  String get receiptProofLineReferenceLabel {
    final sectionLine = ocrSourceSectionLineNumber;
    final section = ocrSourceSectionNumber;
    if (sectionLine != null && sectionLine > 0) {
      if (section != null && section > 1) {
        return 'Section $section line $sectionLine';
      }
      return 'Source line $sectionLine';
    }
    final lineNumber = ocrSourceLineNumber;
    if (lineNumber != null && lineNumber > 0) return 'Line $lineNumber';
    final sourceId = (ocrSourceLineId ?? '').trim();
    if (sourceId.isNotEmpty) return sourceId;
    final fallbackId = id?.trim() ?? '';
    return fallbackId.isEmpty ? 'Receipt line' : fallbackId;
  }

  String get clientProofDefaultVisibility {
    if (use == _ExpenseLineUse.personal) return 'redact_by_default';
    if (parserNeedsReview ||
        category.trim().toLowerCase() == 'uncategorized' ||
        parserReviewSummary.toLowerCase().startsWith('poor')) {
      return 'review_before_client_share';
    }
    return 'review_for_client_proof';
  }

  bool get redactsFromClientProofByDefault =>
      clientProofDefaultVisibility == 'redact_by_default';

  String get clientProofReviewLabel {
    if (redactsFromClientProofByDefault) return 'Hidden from client proof';
    if (clientProofDefaultVisibility == 'review_before_client_share') {
      return 'Review before sharing';
    }
    return 'Review for client proof';
  }

  String get parserReviewActionText {
    if (parserNeedsReview) return 'Review before saving';
    final label = (parserReviewLabel ?? '').trim().toLowerCase();
    if (label == 'good') return 'Looks matched';
    if (label == 'poor') return 'Needs correction';
    if (hasParserReview) return 'Check line';
    return 'Manual line';
  }

  Color get parserBadgeColor {
    final label = (parserReviewLabel ?? '').trim().toLowerCase();
    if (parserNeedsReview || label == 'review') return const Color(0xFF8A5D00);
    if (label == 'poor') return const Color(0xFFA33A2C);
    return const Color(0xFF1E7A3D);
  }

  String get packageSummary {
    if (category == 'Fuel') {
      final unitLabel = stockUnit == 'kWh' ? 'kWh' : 'gal';
      final odometer = odometerReading == null ? '' : ' | odo $odometerReading';
      final fill = fillType == null ? '' : ' | $fillType';
      return '${fuelType ?? 'Fuel'} | ${_formatNumber(quantity)} $unitLabel$fill$odometer';
    }
    if (!expenseCategoryUsesQuantityFields(category)) {
      return 'Receipt amount only';
    }
    if (unitsPerPackage <= 1) {
      return 'Qty ${_formatNumber(quantity)} $stockUnit';
    }
    final eachCost = totalUnits <= 0 ? 0.0 : subtotal / totalUnits;
    return '${_formatNumber(quantity)} pkg x ${_formatNumber(unitsPerPackage)} $stockUnit | ${_money(eachCost)} each';
  }
}
