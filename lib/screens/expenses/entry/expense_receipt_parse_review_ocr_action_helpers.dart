part of 'expense_receipt_entry_screen.dart';

extension _ReceiptOcrReviewActionHelpers on _ReceiptOcrReviewRow {
  List<String> _ocrParserTaskActionLabelsFor(
    ReceiptOcrDiagnostics diagnostics,
  ) {
    final tasks = diagnostics.parserTaskCounts;
    final labels = <String>[];
    final possibleLowerSection =
        (tasks['receipt_possible_lower_section_missing'] ?? 0) > 0;
    if ((tasks['receipt_user_confirmed_complete_review'] ?? 0) > 0) {
      labels.addAll(['Review user-confirmed receipt', 'Check receipt total']);
      if ((tasks['receipt_user_confirmed_missing_bottom_review'] ?? 0) > 0 ||
          possibleLowerSection) {
        labels.add('Check lower receipt lines');
      }
    } else if ((tasks['receipt_bottom_section_continuation_needed'] ?? 0) > 0 ||
        (tasks['receipt_missing_bottom_edge_and_totals'] ?? 0) > 0) {
      labels.addAll([
        'Add bottom receipt section',
        'Use top ghost slice',
        'Review totals after OCR',
      ]);
    } else if ((tasks['receipt_missing_totals_manual_review'] ?? 0) > 0 ||
        (tasks['receipt_totals_text_missing_review'] ?? 0) > 0 ||
        (tasks['receipt_final_total_missing_review'] ?? 0) > 0) {
      labels.addAll([
        if (possibleLowerSection) 'Check lower receipt section',
        if ((tasks['receipt_final_total_missing_review'] ?? 0) > 0)
          'Check final receipt total',
        'Check totals section',
        'Enter total manually',
      ]);
    }
    if ((tasks['receipt_total_only_ready'] ?? 0) > 0) {
      labels.add('Use receipt total only');
    }
    if ((tasks['receipt_total_only_line_math_review'] ?? 0) > 0) {
      labels.addAll(['Review total-only math', 'Use receipt total only']);
    }
    if ((tasks['fuel_detail_needs_review'] ?? 0) > 0) {
      labels.add('Check fuel details');
    }
    if ((tasks['fuel_quantity_needs_review'] ?? 0) > 0) {
      labels.add('Check fuel gallons');
    }
    if ((tasks['fuel_unit_price_needs_review'] ?? 0) > 0) {
      labels.add('Check fuel unit price');
    }
    if ((tasks['fuel_detail_ready'] ?? 0) > 0 &&
        (tasks['fuel_detail_needs_review'] ?? 0) == 0 &&
        (tasks['fuel_quantity_needs_review'] ?? 0) == 0 &&
        (tasks['fuel_unit_price_needs_review'] ?? 0) == 0) {
      labels.addAll(['Review fuel gallons/price', 'Classify fuel expense']);
    }
    if ((tasks['vendor_missing'] ?? 0) > 0) {
      labels.addAll(['Check store name', 'Edit if wrong']);
    }
    if ((tasks['date_missing'] ?? 0) > 0) {
      labels.addAll(['Check receipt date', 'Edit date']);
    }
    if ((tasks['total_missing'] ?? 0) > 0) {
      labels.addAll(['Check receipt total', 'Edit total']);
    }
    if ((tasks['summary_missing'] ?? 0) > 0) {
      labels.addAll(['Check totals section', 'Add missing bottom section']);
    }
    if ((tasks['tax_missing'] ?? 0) > 0) {
      labels.addAll(['Check tax line', 'Edit tax']);
    }
    if ((tasks['item_price_missing'] ?? 0) > 0) {
      labels.addAll([
        'Use receipt total',
        'Add line manually',
        'Retake/add photo',
      ]);
    }
    if ((tasks['item_price_ready_missing'] ?? 0) > 0 ||
        (tasks['item_price_review_required'] ?? 0) > 0) {
      labels.addAll(['Review line prices', 'Edit item lines']);
    }
    if ((tasks['line_sequence_needs_review'] ?? 0) > 0) {
      labels.addAll(['Check photo order', 'Add missing section']);
    }
    if ((tasks['long_receipt_duplicate_text'] ?? 0) > 0 ||
        (tasks['long_receipt_near_duplicate_text'] ?? 0) > 0) {
      labels.addAll(['Check removed overlap', 'Confirm no duplicate charges']);
    }
    if ((tasks['long_receipt_probable_overlap'] ?? 0) > 0) {
      labels.addAll([
        'Review overlap area',
        'Check missing or repeated charges',
      ]);
    }
    if ((tasks['long_receipt_section_gap'] ?? 0) > 0) {
      labels.addAll([
        'Add missing middle section',
        'Check receipt photo order',
      ]);
    }
    if ((tasks['summary_math_needs_review'] ?? 0) > 0) {
      labels.addAll(['Check subtotal', 'Check tax', 'Check total']);
    }
    return labels;
  }

  List<String> _parserDuplicateOverlapActionLabelsFor(
    ExpenseReceiptParseDiagnostics? diagnostics,
  ) {
    if (diagnostics == null || !diagnostics.hasParserDuplicateOverlapReview) {
      return const [];
    }
    final sourceLabel = diagnostics.parserDuplicateOverlapSourceSummaryLabel;
    final confidenceLabel =
        diagnostics.parserDuplicateOverlapConfidenceSummaryLabel;
    return [
      if (sourceLabel.isNotEmpty) 'Compare $sourceLabel',
      if (confidenceLabel.isNotEmpty) 'Overlap: $confidenceLabel',
      'Confirm no duplicate charges',
      'Review overlap area',
    ];
  }

  List<String> _orderedUniqueActionLabels(List<String> labels) {
    final unique = <String>[];
    final seen = <String>{};
    for (final label in labels) {
      final clean = label.trim();
      if (clean.isEmpty || seen.contains(clean)) continue;
      seen.add(clean);
      unique.add(clean);
    }
    unique.sort((a, b) {
      final priority = _actionPriority(a).compareTo(_actionPriority(b));
      if (priority != 0) return priority;
      return labels.indexOf(a).compareTo(labels.indexOf(b));
    });
    return unique;
  }

  int _actionPriority(String label) {
    if (label.startsWith('Compare ')) return 1;
    if (label.startsWith('Overlap: high-confidence')) return 2;
    if (label.startsWith('Overlap: probable')) return 3;
    if (label.startsWith('Overlap: review')) return 4;
    return switch (label) {
      'Check missing lines' => 0,
      'Check duplicate lines' => 5,
      'Check subtotal' => 6,
      'Check tax' => 7,
      'Review total-only math' => 7,
      'Check receipt total' || 'Check total' => 8,
      'Use receipt total only' || 'Use receipt total' => 9,
      'Check fuel gallons' => 10,
      'Check fuel unit price' => 11,
      'Check fuel details' => 12,
      'Review fuel gallons/price' => 13,
      'Classify fuel expense' => 14,
      'Review user-confirmed receipt' => 15,
      'Check lower receipt lines' => 16,
      'Check lower receipt section' => 17,
      'Check final receipt total' => 17,
      'Add bottom receipt section' || 'Add next receipt section' => 13,
      'Use top ghost slice' => 13,
      'Add missing section' || 'Add missing bottom section' => 18,
      'Check photo order' || 'Check receipt photo order' => 19,
      'Retake/add photo' || 'Retake section' || 'Retake photo' => 20,
      'Review low-confidence lines' || 'Review flagged lines' => 21,
      'Review category details' => 22,
      _ => 20,
    };
  }

  List<String> _parserMathActionLabelsFor(
    ExpenseReceiptParseDiagnostics? diagnostics,
  ) {
    if (diagnostics == null) return const [];
    if (diagnostics.detectedLineCount > 0 &&
        diagnostics.expectedSubtotalOrTotal != null &&
        !diagnostics.reconciled) {
      return const [
        'Check missing lines',
        'Check duplicate lines',
        'Use receipt total only',
      ];
    }
    if (diagnostics.hasCompleteExplicitTotals &&
        !diagnostics.taxMathReconciled) {
      return const ['Check subtotal', 'Check tax', 'Check receipt total'];
    }
    if (!diagnostics.hasCompleteExplicitTotals &&
        diagnostics.hasMixedReceiptMathBasis) {
      return const ['Check inferred subtotal/tax'];
    }
    return const [];
  }

  List<String> _parserFuelActionLabelsFor(
    ExpenseReceiptParseDiagnostics? diagnostics,
  ) {
    if (diagnostics == null) return const [];
    final labels = <String>[];
    if (diagnostics.parserTaskCount('fuel_quantity_needs_review') > 0) {
      labels.add('Check fuel gallons');
    }
    if (diagnostics.parserTaskCount('fuel_unit_price_needs_review') > 0) {
      labels.add('Check fuel unit price');
    }
    if (diagnostics.parserTaskCount('fuel_detail_needs_review') > 0) {
      labels.add('Check fuel details');
    }
    return labels;
  }

  List<String> _parserCategoryActionLabelsFor(
    ExpenseReceiptParseDiagnostics? diagnostics,
  ) {
    if (diagnostics == null) return const [];
    return switch (diagnostics.parserCategoryReviewActionCode) {
      'review_low_confidence_lines' => const [
        'Review low-confidence lines',
        'Edit item lines',
      ],
      'optional_parser_pack_available' => const [
        'Review category details',
        'Optional parser pack may help',
      ],
      'review_flagged_lines' => const [
        'Review flagged lines',
        'Edit item lines',
      ],
      'no_priced_lines' => const [
        'Use receipt total',
        'Add line manually',
        'Retake/add photo',
      ],
      _ => const [],
    };
  }
}
