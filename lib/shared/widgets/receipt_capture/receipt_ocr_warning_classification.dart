part of '../../receipts/receipt_ocr_contract.dart';

extension ReceiptOcrWarningClassification on ReceiptOcrWarning {
  static ReceiptOcrWarningKind kindFor(String lower) {
    if (lower.contains('attach at least one receipt')) {
      return ReceiptOcrWarningKind.noSource;
    }
    if (lower.contains('no readable receipt text') ||
        lower.contains('no text was found') ||
        lower.contains('could not render readable pages')) {
      return ReceiptOcrWarningKind.noReadableText;
    }
    if (lower.contains('saved as proof only') ||
        lower.contains('identical to an earlier receipt photo') ||
        lower.contains('assistance is turned off') ||
        lower.contains('reading is turned off') ||
        lower.contains('only the first')) {
      return ReceiptOcrWarningKind.sourceSkipped;
    }
    if (lower.contains('no repeated receipt text between sections') ||
        lower.contains('possible missing receipt section')) {
      return ReceiptOcrWarningKind.sectionGap;
    }
    if (lower.contains('repeated receipt')) {
      return ReceiptOcrWarningKind.duplicateText;
    }
    if (lower.contains('overlapping receipt')) {
      return ReceiptOcrWarningKind.probableOverlap;
    }
    if (lower.contains('encrypted') ||
        lower.contains('protected') ||
        lower.contains('active content') ||
        lower.contains('scripts') ||
        lower.contains('embedded javascript')) {
      return ReceiptOcrWarningKind.pdfSafety;
    }
    if (lower.contains('too large') || lower.contains('smaller file')) {
      return ReceiptOcrWarningKind.pdfTooLarge;
    }
    if (lower.contains('could not be found') ||
        lower.contains('valid pdf') ||
        lower.contains('empty pdf') ||
        lower.contains('cannot be read safely')) {
      return ReceiptOcrWarningKind.pdfUnreadable;
    }
    if (lower.contains('not available in this build') ||
        lower.contains('missingplugin')) {
      return ReceiptOcrWarningKind.pluginUnavailable;
    }
    if (lower.contains('receipt photo quality needs review') ||
        lower.contains('receipt photo quality warning') ||
        lower.contains('photo quality warning') ||
        lower.contains('image cleanup needs review') ||
        lower.contains('proof copy is small')) {
      return ReceiptOcrWarningKind.photoQuality;
    }
    if (lower.contains('receipt photo assistance could not find text') ||
        lower.contains('receipt photo assistance failed') ||
        lower.contains('receipt photo took too long') ||
        lower.contains('receipt photo reading could not read') ||
        lower.contains('receipt photo reading failed') ||
        lower.contains('photo reading failed')) {
      return ReceiptOcrWarningKind.photoReadFailure;
    }
    if (lower.contains('pdf receipt assistance could not find text') ||
        lower.contains('pdf receipt assistance failed') ||
        lower.contains('pdf receipt reading could not read') ||
        lower.contains('pdf receipt reading failed') ||
        lower.contains('pdf reading failed')) {
      return ReceiptOcrWarningKind.pdfReadFailure;
    }
    return ReceiptOcrWarningKind.unknown;
  }

  static ReceiptOcrReviewSeverity severityFor(
    ReceiptOcrWarningKind kind,
    String lower,
  ) {
    return switch (kind) {
      ReceiptOcrWarningKind.noSource ||
      ReceiptOcrWarningKind.noReadableText ||
      ReceiptOcrWarningKind.pdfSafety ||
      ReceiptOcrWarningKind.pdfTooLarge ||
      ReceiptOcrWarningKind.pdfUnreadable ||
      ReceiptOcrWarningKind.pluginUnavailable ||
      ReceiptOcrWarningKind.photoReadFailure ||
      ReceiptOcrWarningKind.pdfReadFailure => ReceiptOcrReviewSeverity.blocked,
      ReceiptOcrWarningKind.photoQuality => ReceiptOcrReviewSeverity.review,
      ReceiptOcrWarningKind.sourceSkipped =>
        lower.contains('turned off')
            ? ReceiptOcrReviewSeverity.blocked
            : ReceiptOcrReviewSeverity.partial,
      ReceiptOcrWarningKind.duplicateText ||
      ReceiptOcrWarningKind.sectionGap ||
      ReceiptOcrWarningKind.probableOverlap ||
      ReceiptOcrWarningKind.unknown => ReceiptOcrReviewSeverity.review,
    };
  }
}
