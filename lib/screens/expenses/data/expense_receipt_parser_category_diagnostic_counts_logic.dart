part of 'expense_receipt_parser.dart';

Map<String, int> _categoryCounts(List<ExpenseReceiptLineRecord> lines) {
  final counts = <String, int>{};
  for (final line in lines) {
    counts[line.category] = (counts[line.category] ?? 0) + 1;
  }
  return counts;
}

Map<String, int> _parserCategoryCountsFor(
  List<ExpenseReceiptLineRecord> lines,
) {
  final counts = <String, int>{};
  for (final line in lines) {
    final category = _safeParserToken(line.category);
    counts[category] = (counts[category] ?? 0) + 1;
  }
  return Map.unmodifiable(counts);
}

Map<String, int> _parserItemExpenseFamilyCountsFor(
  List<ExpenseReceiptLineRecord> lines,
) {
  final counts = <String, int>{};
  for (final line in lines) {
    final explicitFamily = (line.parserExpenseFamily ?? '').trim();
    final family = explicitFamily.isNotEmpty
        ? _safeParserToken(explicitFamily)
        : _parserCategoryFamilyFor(line.category);
    if (family.isEmpty || family == 'unknown') continue;
    counts[family] = (counts[family] ?? 0) + 1;
  }
  return Map.unmodifiable(counts);
}

String _parserItemExpenseFamilyStatusFor(Map<String, int> counts) {
  if (counts.isEmpty) return 'no_item_families';
  if (counts.length == 1) return 'single_${counts.keys.single}_family';
  return 'mixed_item_families';
}

String _parserItemExpenseFamilySummaryLabelFor(Map<String, int> counts) {
  if (counts.isEmpty) return '';
  final labels = counts.keys.map(_parserExpenseFamilyDisplayLabel).toList()
    ..sort();
  if (labels.length == 1) return 'Parser family: ${labels.single}';
  return 'Parser mixed families: ${labels.join(', ')}';
}

String _parserExpenseFamilyDisplayLabel(String token) {
  return switch (_safeParserToken(token)) {
    'food_or_grocery' => 'food/grocery',
    'vehicle_supplies' => 'vehicle supplies',
    'business_expense' => 'business expense',
    'receipt_adjustment' => 'receipt adjustment',
    final value =>
      value
          .replaceAll(RegExp(r'[_\-]+'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim(),
  };
}

Map<String, int> _parserCategoryHealthCountsFor({
  required List<ExpenseReceiptLineRecord> lines,
  required List<ExpenseReceiptLineReview> lineReviews,
  required ReceiptParserDepth parserDepth,
}) {
  final reviewByLineId = {
    for (final review in lineReviews) review.lineId: review.needsReview,
  };
  final counts = <String, int>{};
  void add(String bucket) {
    counts[bucket] = (counts[bucket] ?? 0) + 1;
  }

  for (final line in lines) {
    final category = _safeParserToken(line.category);
    final family = _parserCategoryFamilyFor(line.category);
    final needsReview =
        line.parserNeedsReview || (reviewByLineId[line.id] ?? false);
    final status = needsReview ? 'needs_review' : 'ready';
    final confidence = line.parserConfidence ?? (needsReview ? .5 : .84);
    final confidenceStatus = _parserCategoryConfidenceStatusFor(
      confidence: confidence,
      needsReview: needsReview,
    );

    add('category_${category}_$status');
    add('category_${status}_total');
    add('category_family_${family}_$status');
    add('category_family_${family}_total');
    add('category_${category}_confidence_$confidenceStatus');
    add('category_family_${family}_confidence_$confidenceStatus');
    add('category_confidence_${confidenceStatus}_total');

    if (line.subtotal == 0) {
      add('category_${category}_zero_price');
      add('category_zero_price_total');
    }
    if (line.subtotal < 0) {
      add('category_${category}_negative_price');
      add('category_negative_price_total');
    }
    if (category == 'materials') {
      add(
        line.hasCatalogMatch
            ? 'category_materials_catalog_matched'
            : 'category_materials_catalog_missing',
      );
    }
    if (_parserCategoryPackLimitedFor(
      categoryFamily: family,
      parserDepth: parserDepth,
    )) {
      add('category_${category}_pack_limited');
      add('category_family_${family}_pack_limited');
      add('category_pack_limited_total');
    }
  }

  return Map.unmodifiable(counts);
}

String _parserCategoryConfidenceStatusFor({
  required double confidence,
  required bool needsReview,
}) {
  if (!needsReview && confidence >= .9) return 'strong';
  if (!needsReview && confidence >= .84) return 'ready';
  if (confidence >= .58) return 'weak';
  return 'poor';
}

bool _parserCategoryPackLimitedFor({
  required String categoryFamily,
  required ReceiptParserDepth parserDepth,
}) {
  if (categoryFamily == 'materials') {
    return parserDepth != ReceiptParserDepth.inventoryMatching;
  }
  if (categoryFamily == 'general') {
    return parserDepth == ReceiptParserDepth.proofTotalsOnly;
  }
  return false;
}
