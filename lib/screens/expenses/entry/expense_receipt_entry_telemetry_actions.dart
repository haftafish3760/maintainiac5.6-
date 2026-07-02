part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptEntryTelemetryActions
    on _ExpenseReceiptEntryScreenState {
  void _recordParserTelemetry(ExpenseReceiptParseResult result) {
    final outcome = ExpenseParserFailureDiagnostics.outcomeFor(result);
    final diagnostic = ExpenseParserFailureDiagnostics.diagnosticFor(result);
    final categoryBuckets = _parserCategoryBuckets(result);
    final reviewCategoryBuckets = _parserReviewCategoryBuckets(result);
    final fieldConfidenceBuckets = _parserFieldConfidenceBuckets(result);
    ExpenseScreenTelemetryRecorder.record(
      context,
      switch (outcome) {
        ExpenseParserTelemetryOutcome.completed =>
          ExpenseTelemetryEventType.parserCompleted,
        ExpenseParserTelemetryOutcome.needsReview =>
          ExpenseTelemetryEventType.parserNeedsReview,
        ExpenseParserTelemetryOutcome.failed =>
          ExpenseTelemetryEventType.parserFailed,
      },
      failureKind: diagnostic?.confirmedCause,
      diagnostic: diagnostic,
      categoryGroup: _dominantParserCategoryToken(categoryBuckets),
      metadata: _parserTelemetryMetadata(
        result,
        categoryBuckets: categoryBuckets,
        reviewCategoryBuckets: reviewCategoryBuckets,
        fieldConfidenceBuckets: fieldConfidenceBuckets,
      ),
    );
  }

  Map<String, int> _parserCategoryBuckets(ExpenseReceiptParseResult result) {
    final counts = <String, int>{};
    for (final line in result.lines) {
      _addTelemetryCategory(counts, line.category);
    }
    if (counts.isEmpty) {
      final category = ExpenseReceiptClassifier.classifyText(
        result.sourceText,
      ).category;
      if (category != null) _addTelemetryCategory(counts, category);
    }
    return Map.unmodifiable(counts);
  }

  Map<String, int> _parserReviewCategoryBuckets(
    ExpenseReceiptParseResult result,
  ) {
    final counts = <String, int>{};
    for (var index = 0; index < result.lines.length; index++) {
      if (index >= result.lineReviews.length) continue;
      if (!result.lineReviews[index].needsReview) continue;
      _addTelemetryCategory(counts, result.lines[index].category);
    }
    return Map.unmodifiable(counts);
  }

  Map<String, int> _parserFieldConfidenceBuckets(
    ExpenseReceiptParseResult result,
  ) {
    final counts = <String, int>{};
    for (final entry in result.fieldConfidences.entries) {
      final field = _telemetryToken(entry.key);
      if (field.isEmpty) continue;
      final label = _telemetryToken(entry.value.label);
      if (label.isEmpty) continue;
      final bucket = '${field}_$label';
      counts[bucket] = (counts[bucket] ?? 0) + 1;
    }
    return Map.unmodifiable(counts);
  }

  String _parserPackPressureStatusFor(ExpenseReceiptParseResult result) {
    final diagnostics = result.diagnostics;
    if (diagnostics.parserCategoryReviewActionCode !=
        'optional_parser_pack_available') {
      return 'no_optional_pack_pressure';
    }
    if (diagnostics.hasParserCategoryPackLimits) {
      return 'optional_pack_would_help';
    }
    return 'optional_pack_review_possible';
  }

  Map<String, String> _ocrSourceQualityReviewMetadata(
    Map<String, Object?> handoffContract,
  ) {
    final status = handoffContract['sourceQualityReviewStatus']
        ?.toString()
        .trim();
    final action = handoffContract['sourceQualityReviewAction']
        ?.toString()
        .trim();
    return {
      if (status != null && status.isNotEmpty)
        'ocrSourceQualityReviewStatus': status,
      if (action != null && action.isNotEmpty)
        'ocrSourceQualityReviewAction': action,
    };
  }

  void _addTelemetryCategory(Map<String, int> counts, String category) {
    final token = _telemetryCategoryToken(category);
    if (token.isEmpty) return;
    counts[token] = (counts[token] ?? 0) + 1;
  }

  String? _dominantParserCategoryToken(Map<String, int> categoryBuckets) {
    if (categoryBuckets.isEmpty) return null;
    final entries = categoryBuckets.entries.toList()
      ..sort((left, right) {
        final byCount = right.value.compareTo(left.value);
        if (byCount != 0) return byCount;
        return left.key.compareTo(right.key);
      });
    return entries.first.key;
  }

  String _telemetryCategoryToken(String category) {
    final token = _telemetryToken(category);
    if (token.isEmpty || token == 'uncategorized' || token == 'no_category') {
      return '';
    }
    return token;
  }

  String _telemetryToken(String value) {
    final safe = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_.-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    if (safe.isEmpty) return '';
    return safe.length > ExpenseTelemetryPolicy.maxStringLength
        ? safe.substring(0, ExpenseTelemetryPolicy.maxStringLength)
        : safe;
  }

  String get _receiptPrivacyFeatureArea {
    return switch (_receiptCaptureArea) {
      ReceiptCaptureArea.expenses => 'expenses',
      ReceiptCaptureArea.materialsInventory => 'materials_inventory',
      ReceiptCaptureArea.maintenanceRepair => 'maintenance_repair',
    };
  }

  void _applySuggestedReceiptCategory(String category) {
    final cleanCategory = category.trim();
    if (cleanCategory.isEmpty || cleanCategory == 'Uncategorized') return;
    var changed = 0;
    _updateReceiptState(() {
      for (var index = 0; index < _lines.length; index++) {
        final line = _lines[index];
        if (line.category != 'Uncategorized') continue;
        _lines[index] = line.copyWith(
          category: cleanCategory,
          fuelType: cleanCategory == 'Fuel'
              ? line.fuelType ?? 'Gasoline'
              : null,
          fillType: cleanCategory == 'Fuel'
              ? line.fillType ?? 'Full fill-up'
              : null,
          stockUnit: defaultExpenseReceiptUnit(cleanCategory),
        );
        changed++;
      }
    });
    _scheduleDraftSave();
    if (changed > 0) {
      ExpenseScreenTelemetryRecorder.record(
        context,
        ExpenseTelemetryEventType.userCorrectedCategory,
        categoryGroup: cleanCategory,
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          changed == 0
              ? 'No uncategorized receipt lines needed that suggestion.'
              : 'Applied $cleanCategory to $changed uncategorized receipt line${changed == 1 ? '' : 's'}.',
        ),
      ),
    );
  }

  ExpenseReceiptParseResult _withReceiptBrainHandoffDiagnostics(
    ExpenseReceiptParseResult parsed,
  ) {
    if (_receiptBrainLowStorageDownloadRiskCounts.isEmpty &&
        _receiptBrainFullOfflineMustStayOptionalCounts.isEmpty &&
        _receiptBrainFullOfflineExceedsBaseGuardrailCounts.isEmpty &&
        _receiptInstallRequiredSegmentCounts.isEmpty &&
        _receiptInstallFullOfflineSegmentCounts.isEmpty &&
        _receiptInstallLowStorageImpactCounts.isEmpty &&
        _receiptInstallRecommendedDistributionCounts.isEmpty &&
        _receiptInstallCameraShellParserFreeCounts.isEmpty &&
        _receiptInstallBaseUsefulOnTinyPhonesCounts.isEmpty &&
        _receiptInstallOptionalPacksRequireConsentCounts.isEmpty) {
      return parsed;
    }
    return parsed.copyWith(
      diagnostics: parsed.diagnostics.copyWith(
        receiptBrainLowStorageDownloadRiskCounts:
            _receiptBrainLowStorageDownloadRiskCounts,
        receiptBrainFullOfflineMustStayOptionalCounts:
            _receiptBrainFullOfflineMustStayOptionalCounts,
        receiptBrainFullOfflineExceedsBaseGuardrailCounts:
            _receiptBrainFullOfflineExceedsBaseGuardrailCounts,
        receiptInstallRequiredSegmentCounts:
            _receiptInstallRequiredSegmentCounts,
        receiptInstallFullOfflineSegmentCounts:
            _receiptInstallFullOfflineSegmentCounts,
        receiptInstallLowStorageImpactCounts:
            _receiptInstallLowStorageImpactCounts,
        receiptInstallRecommendedDistributionCounts:
            _receiptInstallRecommendedDistributionCounts,
        receiptInstallCameraShellParserFreeCounts:
            _receiptInstallCameraShellParserFreeCounts,
        receiptInstallBaseUsefulOnTinyPhonesCounts:
            _receiptInstallBaseUsefulOnTinyPhonesCounts,
        receiptInstallOptionalPacksRequireConsentCounts:
            _receiptInstallOptionalPacksRequireConsentCounts,
      ),
    );
  }
}
