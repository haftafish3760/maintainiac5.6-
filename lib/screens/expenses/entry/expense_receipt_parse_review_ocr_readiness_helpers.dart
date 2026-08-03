part of 'expense_receipt_entry_screen.dart';

extension _ReceiptOcrReviewReadinessHelpers on _ReceiptOcrReviewRow {
  List<String> _ocrParserReadinessActionLabelsFor(
    ReceiptOcrDiagnostics diagnostics,
  ) {
    return switch (diagnostics.parserReadinessStatus) {
      'receipt_ready' => const [
        'Review filled fields',
        'Classify Business/Personal/Split',
      ],
      'inventory_ready' => const [
        'Review item lines',
        'Check material matches',
        'Classify Business/Personal/Split',
      ],
      'missing_vendor' => const ['Check store name', 'Edit if wrong'],
      'missing_total' => const ['Check receipt total', 'Edit total'],
      'no_priced_lines' || 'no_item_lines' || 'no_parser_ready_items' => const [
        'Use receipt total',
        'Add line manually',
        'Retake/add photo',
      ],
      'needs_review' => const ['Review line prices', 'Edit item lines'],
      'no_text' => const [
        'Retake photo',
        'Add clearer photo',
        'Enter manually',
      ],
      _ => const [],
    };
  }

  String _ocrParserReadinessSummaryFor(ReceiptOcrDiagnostics diagnostics) {
    final tasks = diagnostics.parserTaskCounts;
    if ((tasks['receipt_user_confirmed_missing_bottom_review'] ?? 0) > 0) {
      return 'Receipt completeness needs confirmation: the user marked this as the full receipt, but the reader did not find the bottom edge and subtotal/total together.';
    }
    if ((tasks['receipt_user_confirmed_complete_review'] ?? 0) > 0) {
      return 'Receipt completeness needs confirmation: the user marked this as the full receipt, but the reader did not find subtotal or total lines.';
    }
    if ((tasks['receipt_bottom_section_continuation_needed'] ?? 0) > 0 ||
        (tasks['receipt_missing_bottom_edge_and_totals'] ?? 0) > 0) {
      final evidenceLabel = diagnostics
          .receiptTotalsCoverageEvidenceDiagnostics['missingBottomTotalsEvidenceLabel']
          ?.toString()
          .trim();
      final evidencePrefix = evidenceLabel == null || evidenceLabel.isEmpty
          ? ''
          : '$evidenceLabel ';
      return 'The next receipt section is needed: receipt text was found. ${evidencePrefix}Add the bottom receipt section before saving.';
    }
    if ((tasks['receipt_missing_totals_manual_review'] ?? 0) > 0) {
      return 'Totals need review: receipt text was found, but subtotal or total lines were not found.';
    }
    if ((tasks['fuel_detail_ready'] ?? 0) > 0 &&
        (tasks['fuel_detail_needs_review'] ?? 0) == 0) {
      return 'Receipt details are ready: review fuel gallons and unit price.';
    }
    return switch (diagnostics.parserReadinessStatus) {
      'receipt_ready' => 'Receipt details are ready to review.',
      'inventory_ready' =>
        'Receipt details include item quantities or codes that may be useful for inventory review.',
      'missing_vendor' => 'Check the store name before saving.',
      'missing_total' => 'Check the receipt total before saving.',
      'no_priced_lines' =>
        'No reliable item prices were found. Review the receipt before saving.',
      'no_item_lines' =>
        'Prices were found, but item lines need review before saving.',
      'no_parser_ready_items' =>
        'Item lines were found, but they need review before saving.',
      'needs_review' => 'Check item lines before saving.',
      'no_text' => 'No readable receipt text was found.',
      'unknown' || '' => '',
      _ => 'Check the store, total, tax, and item lines before saving.',
    };
  }

  String _ocrStructureSummaryFor(ReceiptOcrDiagnostics diagnostics) {
    if (diagnostics.receiptCompletionUserConfirmedComplete &&
        diagnostics.receiptMissingBottomEdgeAndTotals) {
      return 'Receipt structure needs confirmation: the user marked this as the full receipt, but the bottom edge and subtotal/total lines still need checking.';
    }
    if (diagnostics.receiptCompletionUserConfirmedComplete &&
        diagnostics.receiptMayNeedBottomSection) {
      return 'Receipt structure needs confirmation: the user marked this as the full receipt, but subtotal/total lines still need checking.';
    }
    if (diagnostics.receiptMissingBottomEdgeAndTotals) {
      final evidenceLabel = diagnostics
          .receiptTotalsCoverageEvidenceDiagnostics['missingBottomTotalsEvidenceLabel']
          ?.toString()
          .trim();
      final evidencePrefix = evidenceLabel == null || evidenceLabel.isEmpty
          ? ''
          : '$evidenceLabel ';
      if (diagnostics.hasOcrSourceGhostSliceContinuation) {
        return 'Receipt structure needs review: ${evidencePrefix}Add the bottom receipt section and repeat 3-5 readable lines in the top ghost slice.';
      }
      return 'Receipt structure needs review: ${evidencePrefix}Add the bottom receipt section and repeat 3-5 readable lines in the top ghost slice if the receipt continues.';
    }
    if (diagnostics.receiptMayNeedBottomSection) {
      return 'Receipt structure needs review: subtotal/total lines were not found. Check whether the bottom of the receipt is missing.';
    }
    return switch (diagnostics.ocrReceiptStructureStatus) {
      'ready_for_parser' =>
        'Receipt structure looks ready for app-assisted review.',
      'missing_vendor' =>
        'Receipt structure needs review: check the store name before saving.',
      'no_items' =>
        'Receipt structure needs review: no priced item lines were safe enough to fill automatically.',
      'missing_total' =>
        'Receipt structure needs review: check the receipt total before saving.',
      'line_sequence_review' =>
        'Receipt structure needs review: receipt sections may be out of order or missing.',
      'summary_math_review' =>
        'Receipt structure needs review: subtotal, tax, and total do not line up.',
      'line_item_review' =>
        'Receipt structure needs review: one or more item prices need checking.',
      'no_text' =>
        'Receipt structure needs review: no readable receipt text was found.',
      'unknown' || '' => '',
      _ =>
        'Receipt structure needs review: check store, date, total, tax, and item prices.',
    };
  }

  String _ocrRecoverySummaryFor(
    ReceiptOcrWarning? warning,
    ReceiptProcessingSource source,
  ) {
    if (warning == null) {
      if (diagnostics.hasText) return '';
      return switch (source) {
        ReceiptProcessingSource.photo =>
          'Retake the receipt photo, add the missing long-receipt section, or continue by hand.',
        ReceiptProcessingSource.pdf =>
          'Scan the receipt with photos or continue by hand.',
        ReceiptProcessingSource.importedText =>
          'Paste cleaner receipt text or continue by hand.',
        ReceiptProcessingSource.mixed =>
          'Choose the clearest receipt source, add a clearer photo, or continue by hand.',
        ReceiptProcessingSource.none =>
          'Attach a receipt photo, readable PDF, or pasted receipt text.',
      };
    }
    return switch (warning.kind) {
      ReceiptOcrWarningKind.noSource =>
        'Attach a receipt photo, readable PDF, or pasted receipt text.',
      ReceiptOcrWarningKind.noReadableText => _ocrRecoverySummaryFor(
        null,
        source,
      ),
      ReceiptOcrWarningKind.sourceSkipped =>
        'Review the saved proof or turn receipt assistance back on.',
      ReceiptOcrWarningKind.duplicateText ||
      ReceiptOcrWarningKind.probableOverlap =>
        'Check the long-receipt overlap before saving.',
      ReceiptOcrWarningKind.sectionGap =>
        'Add the missing receipt section or confirm the photos are in order.',
      ReceiptOcrWarningKind.pdfSafety =>
        'Attach a safe PDF copy, scan with photos, or continue by hand.',
      ReceiptOcrWarningKind.pdfTooLarge =>
        'Use a smaller PDF or scan the receipt with photos.',
      ReceiptOcrWarningKind.pdfUnreadable ||
      ReceiptOcrWarningKind.pdfReadFailure =>
        'Scan the receipt with photos, attach a clearer PDF, or continue by hand.',
      ReceiptOcrWarningKind.pluginUnavailable =>
        'Continue with manual entry for this build.',
      ReceiptOcrWarningKind.photoQuality =>
        'Retake the photo if store, date, total, tax, or item prices are not readable.',
      ReceiptOcrWarningKind.photoReadFailure =>
        'Retake the photo, add another clear section, or continue by hand.',
      ReceiptOcrWarningKind.unknown =>
        'Review the receipt proof and filled fields before saving.',
    };
  }
}
