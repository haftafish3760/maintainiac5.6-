part of '../../receipts/receipt_ocr_contract.dart';

extension ReceiptOcrWarningLabels on ReceiptOcrWarning {
  String get label {
    return switch (kind) {
      ReceiptOcrWarningKind.noSource => 'No receipt attached',
      ReceiptOcrWarningKind.noReadableText => 'No readable text',
      ReceiptOcrWarningKind.sourceSkipped =>
        isBlocking ? 'Receipt assistance off' : 'Receipt source skipped',
      ReceiptOcrWarningKind.duplicateText => 'Duplicate lines ignored',
      ReceiptOcrWarningKind.probableOverlap => 'Possible receipt overlap',
      ReceiptOcrWarningKind.sectionGap => 'Possible missing receipt section',
      ReceiptOcrWarningKind.pdfSafety => 'PDF safety warning',
      ReceiptOcrWarningKind.pdfTooLarge => 'PDF too large',
      ReceiptOcrWarningKind.pdfUnreadable => 'PDF unreadable',
      ReceiptOcrWarningKind.pluginUnavailable => 'OCR unavailable',
      ReceiptOcrWarningKind.photoQuality => 'Photo quality warning',
      ReceiptOcrWarningKind.photoReadFailure => 'Photo read failed',
      ReceiptOcrWarningKind.pdfReadFailure => 'PDF read failed',
      ReceiptOcrWarningKind.unknown => 'OCR warning',
    };
  }

  String get actionLabel {
    return switch (kind) {
      ReceiptOcrWarningKind.noSource =>
        'Attach a receipt photo, PDF, or pasted text.',
      ReceiptOcrWarningKind.noReadableText =>
        'Retake the photo, attach another page, or enter the receipt manually.',
      ReceiptOcrWarningKind.sourceSkipped =>
        isBlocking
            ? 'Turn on receipt assistance or enter the receipt manually.'
            : 'Review the saved proof if any line is missing.',
      ReceiptOcrWarningKind.duplicateText =>
        'Check the removed overlap before saving.',
      ReceiptOcrWarningKind.probableOverlap =>
        'Review nearby line items for duplicate or missing charges.',
      ReceiptOcrWarningKind.sectionGap =>
        'Check the receipt photos for a skipped middle section.',
      ReceiptOcrWarningKind.pdfSafety =>
        'Use the PDF as proof only or attach a safe copy.',
      ReceiptOcrWarningKind.pdfTooLarge =>
        'Attach a smaller PDF or scan the receipt with photos.',
      ReceiptOcrWarningKind.pdfUnreadable =>
        'Attach a valid PDF, photo, or pasted receipt text.',
      ReceiptOcrWarningKind.pluginUnavailable =>
        'Enter the receipt manually in this build.',
      ReceiptOcrWarningKind.photoQuality =>
        'Review the receipt photo or retake it before trusting the parsed lines.',
      ReceiptOcrWarningKind.photoReadFailure =>
        'Retake the photo or enter the receipt manually.',
      ReceiptOcrWarningKind.pdfReadFailure =>
        'Attach a clearer PDF/photo or enter the receipt manually.',
      ReceiptOcrWarningKind.unknown => 'Review this receipt before saving.',
    };
  }

  String get reviewMessage => '$label. $actionLabel';

  String get reviewInstruction {
    return switch (severity) {
      ReceiptOcrReviewSeverity.blocked =>
        'Do not save until this is fixed or the receipt is entered manually.',
      ReceiptOcrReviewSeverity.partial =>
        'Some receipt content may be missing. Compare the filled form with the receipt proof before saving.',
      ReceiptOcrReviewSeverity.review =>
        'Compare the filled form with the receipt proof before saving.',
      ReceiptOcrReviewSeverity.good => '',
    };
  }

  String get reviewTargetLabel {
    return switch (kind) {
      ReceiptOcrWarningKind.noSource => 'Check receipt attachment',
      ReceiptOcrWarningKind.noReadableText => 'Check receipt photo/PDF clarity',
      ReceiptOcrWarningKind.sourceSkipped => 'Check saved proof',
      ReceiptOcrWarningKind.duplicateText => 'Check long receipt overlap',
      ReceiptOcrWarningKind.probableOverlap => 'Check overlapping line items',
      ReceiptOcrWarningKind.sectionGap => 'Check missing receipt section',
      ReceiptOcrWarningKind.pdfSafety => 'Check PDF proof safety',
      ReceiptOcrWarningKind.pdfTooLarge => 'Check PDF size',
      ReceiptOcrWarningKind.pdfUnreadable => 'Check PDF readability',
      ReceiptOcrWarningKind.pluginUnavailable => 'Check manual entry',
      ReceiptOcrWarningKind.photoQuality => 'Check photo proof',
      ReceiptOcrWarningKind.photoReadFailure => 'Check receipt photo',
      ReceiptOcrWarningKind.pdfReadFailure => 'Check receipt PDF',
      ReceiptOcrWarningKind.unknown => 'Check receipt details',
    };
  }

  String get reviewTargetInstruction {
    return switch (kind) {
      ReceiptOcrWarningKind.noSource =>
        'Attach proof before trusting any filled receipt fields.',
      ReceiptOcrWarningKind.noReadableText =>
        'Look at the proof first; if the text is blurry or tiny, retake it or use Add Another Photo.',
      ReceiptOcrWarningKind.sourceSkipped =>
        'Open the saved proof and make sure any skipped pages are not needed for totals or line items.',
      ReceiptOcrWarningKind.duplicateText =>
        'Check the stitch/overlap area and make sure the same charge was not counted twice.',
      ReceiptOcrWarningKind.probableOverlap =>
        'Check the nearby line items around the overlap and confirm duplicates or missing charges.',
      ReceiptOcrWarningKind.sectionGap =>
        'Check the receipt photos from top to bottom and add the missing middle section if needed.',
      ReceiptOcrWarningKind.pdfSafety =>
        'Keep unsafe PDFs as proof only unless the user attaches a safe copy.',
      ReceiptOcrWarningKind.pdfTooLarge =>
        'Use photos or a smaller PDF before app-assisted filling.',
      ReceiptOcrWarningKind.pdfUnreadable =>
        'Replace the PDF with a valid PDF, photo, or pasted receipt text.',
      ReceiptOcrWarningKind.pluginUnavailable =>
        'Use manual entry for this build and keep the receipt proof attached.',
      ReceiptOcrWarningKind.photoQuality =>
        'Zoom into the proof and check store, date, total, tax, and item prices.',
      ReceiptOcrWarningKind.photoReadFailure =>
        'Retake the photo or attach another clear receipt photo.',
      ReceiptOcrWarningKind.pdfReadFailure =>
        'Attach a clearer PDF or scan the receipt with photos.',
      ReceiptOcrWarningKind.unknown =>
        'Review the filled receipt fields against the proof before saving.',
    };
  }
}
