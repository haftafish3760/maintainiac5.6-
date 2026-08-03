part of '../../receipts/receipt_ocr_contract.dart';

extension ReceiptOcrDiagnosticsLabels on ReceiptOcrDiagnostics {
  bool get hasBlockingWarnings => blockingWarningCount > 0;
  bool get hasPartialWarnings => partialWarningCount > 0;
  bool get hasReviewWarnings => reviewWarningCount > 0;

  int countForWarningKind(ReceiptOcrWarningKind kind) {
    return warningKindCounts[kind] ?? 0;
  }

  String get sourceLabel {
    return switch (source) {
      ReceiptProcessingSource.none => 'No receipt source',
      ReceiptProcessingSource.photo => 'Receipt photo',
      ReceiptProcessingSource.pdf => 'Receipt PDF',
      ReceiptProcessingSource.importedText => 'Imported text',
      ReceiptProcessingSource.mixed => 'Multiple receipt sources',
    };
  }

  String get readSummaryLabel {
    if (attachmentsRead == 0 && attachmentsSkipped == 0) {
      return 'Nothing read';
    }
    final read = attachmentsRead == 1
        ? '1 source read'
        : '$attachmentsRead sources read';
    if (attachmentsSkipped == 0) return read;
    final skipped = attachmentsSkipped == 1
        ? '1 saved as proof only'
        : '$attachmentsSkipped saved as proof only';
    return '$read, $skipped';
  }

  String get textSummaryLabel {
    if (!hasText) return 'No readable text';
    final readyLineCount = parserLineCount > 0 ? parserLineCount : rawLineCount;
    if (readyLineCount <= 0) return 'No readable text';
    final lineLabel = readyLineCount == 1 ? 'line' : 'lines';
    if (rawLineCount == parserLineCount || rawLineCount <= readyLineCount) {
      return '$readyLineCount receipt $lineLabel ready for review';
    }
    return '$readyLineCount receipt $lineLabel ready for review; repeated text was ignored';
  }

  String get parserSignalSummaryLabel {
    if (!hasText) return '';
    final parts = <String>[
      '$parserLineCount ordered ${parserLineCount == 1 ? 'line' : 'lines'}',
      if (itemCandidateLineCount > 0)
        '$itemCandidateLineCount item ${itemCandidateLineCount == 1 ? 'candidate' : 'candidates'}',
      if (parserReadyLineCount > 0)
        '$parserReadyLineCount parser-ready ${parserReadyLineCount == 1 ? 'line' : 'lines'}',
      if (parserReviewSignalCount > 0)
        '$parserReviewSignalCount parser ${parserReviewSignalCount == 1 ? 'signal needs' : 'signals need'} review',
      if (parserReadinessStatus.isNotEmpty)
        'parser readiness $parserReadinessStatus',
      if (headerRecoveryStatus.isNotEmpty) 'header $headerRecoveryStatus',
      if (vendorReviewStatus.isNotEmpty) 'vendor review $vendorReviewStatus',
      if (merchantIndependentStructureStatus.isNotEmpty)
        'merchant-independent $merchantIndependentStructureStatus',
      if ((parserTaskCounts['fuel_line_ready'] ?? 0) > 0)
        '${parserTaskCounts['fuel_line_ready']} fuel ${parserTaskCounts['fuel_line_ready'] == 1 ? 'line ready' : 'lines ready'}',
      if ((parserTaskCounts['fuel_detail_ready'] ?? 0) > 0)
        '${parserTaskCounts['fuel_detail_ready']} fuel ${parserTaskCounts['fuel_detail_ready'] == 1 ? 'detail set' : 'detail sets'} ready',
      if ((parserTaskCounts['fuel_quantity_signal'] ?? 0) > 0)
        '${parserTaskCounts['fuel_quantity_signal']} fuel ${parserTaskCounts['fuel_quantity_signal'] == 1 ? 'quantity signal' : 'quantity signals'}',
      if ((parserTaskCounts['fuel_unit_price_signal'] ?? 0) > 0)
        '${parserTaskCounts['fuel_unit_price_signal']} fuel ${parserTaskCounts['fuel_unit_price_signal'] == 1 ? 'unit price signal' : 'unit price signals'}',
      if ((parserTaskCounts['separatorless_money_inferred'] ?? 0) > 0)
        '${parserTaskCounts['separatorless_money_inferred']} OCR ${parserTaskCounts['separatorless_money_inferred'] == 1 ? 'amount was' : 'amounts were'} inferred from missing cents separator',
      if ((parserTaskCounts['split_cents_money_inferred'] ?? 0) > 0)
        '${parserTaskCounts['split_cents_money_inferred']} OCR ${parserTaskCounts['split_cents_money_inferred'] == 1 ? 'amount was' : 'amounts were'} inferred from spaced cents',
      if (itemExpenseFamilySummaryLabel.isNotEmpty)
        itemExpenseFamilySummaryLabel,
      mixedClassificationEvidenceLabel,
      requiredParserFieldStatusLabel,
      if (highConfidenceItemCandidateLineCount > 0)
        '$highConfidenceItemCandidateLineCount ready item ${highConfidenceItemCandidateLineCount == 1 ? 'line' : 'lines'}',
      if (reviewItemCandidateLineCount > 0)
        '$reviewItemCandidateLineCount item ${reviewItemCandidateLineCount == 1 ? 'line needs' : 'lines need'} review',
      if (quantitySignalItemCandidateLineCount > 0)
        '$quantitySignalItemCandidateLineCount item ${quantitySignalItemCandidateLineCount == 1 ? 'line has' : 'lines have'} quantity/unit signals',
      if (skuSignalItemCandidateLineCount > 0)
        '$skuSignalItemCandidateLineCount item ${skuSignalItemCandidateLineCount == 1 ? 'line has' : 'lines have'} SKU-like signals',
      if (genericItemCandidateLineCount > 0)
        '$genericItemCandidateLineCount generic item ${genericItemCandidateLineCount == 1 ? 'line' : 'lines'}',
      if (dominantParserLineRole.isNotEmpty)
        'dominant line role $dominantParserLineRole',
      if (ocrSummaryMathStatus != 'incomplete')
        'OCR summary math $ocrSummaryMathStatus',
      if (ocrLineSequenceStatus != 'empty') 'line order $ocrLineSequenceStatus',
      if (ocrSourceSectionContinuityStatus != 'no_text' &&
          ocrSourceSectionContinuityStatus != 'no_source_sections')
        'section order $ocrSourceSectionContinuityStatus',
      'receipt structure $ocrReceiptStructureStatus',
      '$priceCandidateLineCount price ${priceCandidateLineCount == 1 ? 'candidate' : 'candidates'}',
      if (subtotalCandidateLineCount > 0) 'subtotal found',
      if (totalCandidateLineCount > 0) 'total found',
      if (taxCandidateLineCount > 0) 'tax found',
      if (tenderCandidateLineCount > 0)
        '$tenderCandidateLineCount tender ${tenderCandidateLineCount == 1 ? 'line' : 'lines'}',
      if (metadataCandidateLineCount > 0)
        '$metadataCandidateLineCount metadata ${metadataCandidateLineCount == 1 ? 'line' : 'lines'}',
      if (vendorCandidateLineCount > 0) 'header candidate found',
      if (dateCandidateLineCount > 0) 'date found',
      if ((parserTaskCounts['receipt_bottom_section_continuation_needed'] ??
              0) >
          0)
        'bottom section continuation needed',
      if ((parserTaskCounts['receipt_user_confirmed_complete_review'] ?? 0) > 0)
        'user confirmed full receipt',
      if ((parserTaskCounts['receipt_missing_totals_manual_review'] ?? 0) > 0)
        'totals need manual review',
      'post-capture route $receiptPostCaptureRouteStatus',
      if (parserTaskCounts.isNotEmpty)
        '${parserTaskCounts.length} parser task buckets ready',
    ];
    return 'Parser signals: ${parts.join(', ')}.';
  }

  String get warningSummaryLabel {
    if (warningCount == 0) return 'No OCR warnings';
    final parts = <String>[
      if (blockingWarningCount > 0) '$blockingWarningCount blocked',
      if (partialWarningCount > 0) '$partialWarningCount partial',
      if (reviewWarningCount > 0) '$reviewWarningCount review',
    ];
    if (parts.isEmpty) {
      return '$warningCount OCR ${warningCount == 1 ? 'warning' : 'warnings'}';
    }
    return '${parts.join(', ')} OCR ${warningCount == 1 ? 'warning' : 'warnings'}';
  }

  String get pdfWorkLabel {
    if (pdfPagesRequested <= 0) return 'No PDF pages requested';
    return '$pdfPagesRequested PDF ${pdfPagesRequested == 1 ? 'page' : 'pages'} requested';
  }

  String get reviewSummaryLabel {
    return '${severity.label}: $readSummaryLabel. $textSummaryLabel. $warningSummaryLabel.';
  }
}
