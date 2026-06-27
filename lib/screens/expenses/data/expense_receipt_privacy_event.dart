part of 'expense_receipt_parser.dart';

enum PrivacySafeReceiptEventType {
  receiptCaptureStarted,
  receiptCaptureCompleted,
  receiptCaptureAbandoned,
  receiptCaptureFailed,
  receiptOcrGood,
  receiptOcrReview,
  receiptOcrPartial,
  receiptOcrBlocked,
  receiptParserGood,
  receiptParserReview,
  receiptParserPoor,
  inventoryCatalogMatchWeak,
  receiptTotalsMismatch,
}

class PrivacySafeReceiptEvent {
  const PrivacySafeReceiptEvent({
    required this.type,
    required this.featureArea,
    this.capabilityTier,
    this.parserDepth,
    this.ocrSeverity,
    this.parseQuality,
    this.parserTrust,
    this.parserReviewCause,
    this.totalsMathStatus,
    this.fieldReviewKeys = const [],
    this.captureMode,
    this.captureOutcome,
    this.focusBucket,
    this.readabilityBucket,
    this.errorKind,
    this.warningKinds = const [],
    this.photoSectionCount = 0,
    this.retakeCount = 0,
    this.captureDurationMs = 0,
    this.attachmentsRead = 0,
    this.attachmentsSkipped = 0,
    this.rawLineCount = 0,
    this.parserLineCount = 0,
    this.detectedLineCount = 0,
    this.reviewLineCount = 0,
    this.materialLineCount = 0,
    this.catalogMatchedLineCount = 0,
    this.unmatchedMaterialLineCount = 0,
    this.negativeLineCount = 0,
    this.adjustmentLineCount = 0,
    this.pdfPagesRequested = 0,
    this.reconciled = false,
    this.taxMathReconciled = false,
    this.explicitTotalsComplete = false,
    this.needsHeavyReview = false,
    this.usedLocalOcr = false,
    this.hadDuplicateOrOverlapText = false,
  });

  factory PrivacySafeReceiptEvent.fromCapture({
    required PrivacySafeReceiptEventType type,
    String featureArea = 'receipts',
    ReceiptDeviceCapability? capability,
    String captureMode = 'manual',
    String captureOutcome = 'unknown',
    ReceiptPhotoQualityCheck? quality,
    int photoSectionCount = 0,
    int retakeCount = 0,
    int captureDurationMs = 0,
    String? errorKind,
  }) {
    return PrivacySafeReceiptEvent(
      type: type,
      featureArea: _safeToken(featureArea),
      capabilityTier: capability?.tier.name,
      parserDepth: capability?.parserDepth.name,
      captureMode: _safeToken(captureMode),
      captureOutcome: _safeToken(captureOutcome),
      focusBucket: quality == null ? null : _focusBucket(quality.focusScore),
      readabilityBucket: quality == null
          ? null
          : _readabilityBucket(quality.reviewScore),
      photoSectionCount: photoSectionCount,
      retakeCount: retakeCount,
      captureDurationMs: captureDurationMs,
      errorKind: errorKind == null ? null : _safeToken(errorKind),
    );
  }

  factory PrivacySafeReceiptEvent.fromOcrResult({
    required ReceiptOcrResult result,
    String featureArea = 'receipts',
    ReceiptDeviceCapability? capability,
  }) {
    final diagnostics = result.diagnostics;
    return PrivacySafeReceiptEvent(
      type: _typeForOcrSeverity(diagnostics.severity),
      featureArea: _safeToken(featureArea),
      capabilityTier: capability?.tier.name,
      parserDepth: capability?.parserDepth.name,
      ocrSeverity: diagnostics.severity.name,
      warningKinds: [
        for (final warning in result.structuredWarnings) warning.kind.name,
      ],
      attachmentsRead: diagnostics.attachmentsRead,
      attachmentsSkipped: diagnostics.attachmentsSkipped,
      rawLineCount: diagnostics.rawLineCount,
      parserLineCount: diagnostics.parserLineCount,
      pdfPagesRequested: diagnostics.pdfPagesRequested,
      usedLocalOcr: diagnostics.usedLocalOcr,
      hadDuplicateOrOverlapText: diagnostics.hadDuplicateOrOverlapText,
    );
  }

  factory PrivacySafeReceiptEvent.fromParseResult({
    required ExpenseReceiptParseResult result,
    String featureArea = 'receipts',
  }) {
    final diagnostics = result.diagnostics;
    return PrivacySafeReceiptEvent(
      type: _typeForParseResult(result),
      featureArea: _safeToken(featureArea),
      parserDepth: diagnostics.parserDepth.name,
      parseQuality: _qualityBucket(result.quality.confidence),
      parserTrust: _safeToken(diagnostics.trustLabel),
      parserReviewCause: _parserReviewCause(result),
      totalsMathStatus: _totalsMathStatus(diagnostics),
      fieldReviewKeys: _fieldReviewKeys(result),
      detectedLineCount: diagnostics.detectedLineCount,
      reviewLineCount: diagnostics.reviewLineCount,
      materialLineCount: diagnostics.materialLineCount,
      catalogMatchedLineCount: diagnostics.catalogMatchedLineCount,
      unmatchedMaterialLineCount: diagnostics.unmatchedMaterialLineCount,
      negativeLineCount: diagnostics.negativeLineCount,
      adjustmentLineCount: diagnostics.adjustmentLineCount,
      reconciled: diagnostics.reconciled,
      taxMathReconciled: diagnostics.taxMathReconciled,
      explicitTotalsComplete: diagnostics.hasCompleteExplicitTotals,
      needsHeavyReview: diagnostics.needsHeavyReview,
    );
  }

  final PrivacySafeReceiptEventType type;
  final String featureArea;
  final String? capabilityTier;
  final String? parserDepth;
  final String? ocrSeverity;
  final String? parseQuality;
  final String? parserTrust;
  final String? parserReviewCause;
  final String? totalsMathStatus;
  final List<String> fieldReviewKeys;
  final String? captureMode;
  final String? captureOutcome;
  final String? focusBucket;
  final String? readabilityBucket;
  final String? errorKind;
  final List<String> warningKinds;
  final int photoSectionCount;
  final int retakeCount;
  final int captureDurationMs;
  final int attachmentsRead;
  final int attachmentsSkipped;
  final int rawLineCount;
  final int parserLineCount;
  final int detectedLineCount;
  final int reviewLineCount;
  final int materialLineCount;
  final int catalogMatchedLineCount;
  final int unmatchedMaterialLineCount;
  final int negativeLineCount;
  final int adjustmentLineCount;
  final int pdfPagesRequested;
  final bool reconciled;
  final bool taxMathReconciled;
  final bool explicitTotalsComplete;
  final bool needsHeavyReview;
  final bool usedLocalOcr;
  final bool hadDuplicateOrOverlapText;

  Map<String, Object?> toMap() {
    return {
      'event': type.name,
      'featureArea': featureArea,
      if (capabilityTier != null) 'capabilityTier': capabilityTier,
      if (parserDepth != null) 'parserDepth': parserDepth,
      if (ocrSeverity != null) 'ocrSeverity': ocrSeverity,
      if (parseQuality != null) 'parseQuality': parseQuality,
      if (parserTrust != null) 'parserTrust': parserTrust,
      if (parserReviewCause != null) 'parserReviewCause': parserReviewCause,
      if (totalsMathStatus != null) 'totalsMathStatus': totalsMathStatus,
      if (fieldReviewKeys.isNotEmpty) 'fieldReviewKeys': fieldReviewKeys,
      if (captureMode != null) 'captureMode': captureMode,
      if (captureOutcome != null) 'captureOutcome': captureOutcome,
      if (focusBucket != null) 'focusBucket': focusBucket,
      if (readabilityBucket != null) 'readabilityBucket': readabilityBucket,
      if (errorKind != null) 'errorKind': errorKind,
      if (warningKinds.isNotEmpty) 'warningKinds': warningKinds,
      'photoSectionCount': photoSectionCount,
      'retakeCount': retakeCount,
      'captureDurationMs': captureDurationMs,
      'attachmentsRead': attachmentsRead,
      'attachmentsSkipped': attachmentsSkipped,
      'rawLineCount': rawLineCount,
      'parserLineCount': parserLineCount,
      'detectedLineCount': detectedLineCount,
      'reviewLineCount': reviewLineCount,
      'materialLineCount': materialLineCount,
      'catalogMatchedLineCount': catalogMatchedLineCount,
      'unmatchedMaterialLineCount': unmatchedMaterialLineCount,
      'negativeLineCount': negativeLineCount,
      'adjustmentLineCount': adjustmentLineCount,
      'pdfPagesRequested': pdfPagesRequested,
      'reconciled': reconciled,
      'taxMathReconciled': taxMathReconciled,
      'explicitTotalsComplete': explicitTotalsComplete,
      'needsHeavyReview': needsHeavyReview,
      'usedLocalOcr': usedLocalOcr,
      'hadDuplicateOrOverlapText': hadDuplicateOrOverlapText,
    };
  }

  static PrivacySafeReceiptEventType _typeForOcrSeverity(
    ReceiptOcrReviewSeverity severity,
  ) {
    return switch (severity) {
      ReceiptOcrReviewSeverity.good =>
        PrivacySafeReceiptEventType.receiptOcrGood,
      ReceiptOcrReviewSeverity.review =>
        PrivacySafeReceiptEventType.receiptOcrReview,
      ReceiptOcrReviewSeverity.partial =>
        PrivacySafeReceiptEventType.receiptOcrPartial,
      ReceiptOcrReviewSeverity.blocked =>
        PrivacySafeReceiptEventType.receiptOcrBlocked,
    };
  }

  static PrivacySafeReceiptEventType _typeForParseResult(
    ExpenseReceiptParseResult result,
  ) {
    final diagnostics = result.diagnostics;
    if (!diagnostics.reconciled &&
        diagnostics.detectedLineCount > 0 &&
        diagnostics.expectedSubtotalOrTotal != null) {
      return PrivacySafeReceiptEventType.receiptTotalsMismatch;
    }
    if (diagnostics.hasCompleteExplicitTotals &&
        !diagnostics.taxMathReconciled) {
      return PrivacySafeReceiptEventType.receiptTotalsMismatch;
    }
    if (diagnostics.materialLineCount > 0 &&
        diagnostics.hasUnmatchedMaterials) {
      return PrivacySafeReceiptEventType.inventoryCatalogMatchWeak;
    }
    return switch (result.quality.label) {
      'Good' => PrivacySafeReceiptEventType.receiptParserGood,
      'Review' => PrivacySafeReceiptEventType.receiptParserReview,
      _ => PrivacySafeReceiptEventType.receiptParserPoor,
    };
  }

  static String _qualityBucket(double confidence) {
    if (confidence >= .84) return 'high';
    if (confidence >= .58) return 'medium';
    return 'low';
  }

  static String _totalsMathStatus(ExpenseReceiptParseDiagnostics diagnostics) {
    if (!diagnostics.hasCompleteExplicitTotals) return 'incomplete';
    return diagnostics.taxMathReconciled ? 'matched' : 'mismatch';
  }

  static String? _parserReviewCause(ExpenseReceiptParseResult result) {
    final diagnostics = result.diagnostics;
    if (!result.hasUsableData) return 'receipt_parser_no_usable_fields';
    if (diagnostics.detectedLineCount > 0 &&
        diagnostics.expectedSubtotalOrTotal != null &&
        !diagnostics.reconciled) {
      return 'receipt_line_total_mismatch';
    }
    if (diagnostics.hasCompleteExplicitTotals &&
        !diagnostics.taxMathReconciled) {
      return 'receipt_subtotal_tax_total_mismatch';
    }
    if (diagnostics.detectedLineCount == 0) {
      return 'receipt_totals_only_no_line_items';
    }
    if (result.enteredTotal == null && result.enteredSubtotal == null) {
      return 'receipt_total_missing';
    }
    if (_wasFieldInferred(result.fieldConfidences['subtotal'])) {
      return 'receipt_subtotal_inferred';
    }
    if (_wasFieldInferred(result.fieldConfidences['tax'])) {
      return 'receipt_tax_inferred';
    }
    if (_wasFieldInferred(result.fieldConfidences['total'])) {
      return 'receipt_total_inferred';
    }
    if (result.receiptDate == null) return 'receipt_date_missing';
    if (_usedFallbackDate(result)) return 'receipt_date_used_fallback';
    if ((result.merchantName ?? '').trim().isEmpty) {
      return 'receipt_merchant_missing';
    }
    if (diagnostics.hasUnmatchedMaterials) {
      return 'inventory_catalog_match_weak';
    }
    if (diagnostics.reviewRatio > .5) return 'receipt_lines_need_review';
    if (result.quality.needsReview) return 'receipt_parser_low_confidence';
    return null;
  }

  static List<String> _fieldReviewKeys(ExpenseReceiptParseResult result) {
    return List<String>.unmodifiable(
      result.fieldConfidences.values
          .where((field) => field.needsReview)
          .map((field) => _safeToken(field.fieldKey))
          .take(12),
    );
  }

  static bool _wasFieldInferred(ExpenseReceiptFieldConfidence? field) {
    return field != null && field.reason.toLowerCase().contains('inferred');
  }

  static bool _usedFallbackDate(ExpenseReceiptParseResult result) {
    final field = result.fieldConfidences['date'];
    return field != null &&
        field.reason.toLowerCase().contains('selected day as a fallback');
  }

  static String _focusBucket(double focusScore) {
    if (focusScore >= 14) return 'sharp';
    if (focusScore >= 8) return 'usable';
    if (focusScore > 0) return 'soft';
    return 'unknown';
  }

  static String _readabilityBucket(int reviewScore) {
    if (reviewScore >= 82) return 'high';
    if (reviewScore >= 58) return 'review';
    if (reviewScore > 0) return 'poor';
    return 'unknown';
  }

  static String _safeToken(String value) {
    final clean = value.trim().toLowerCase();
    if (clean.isEmpty) return 'receipts';
    return clean.replaceAll(RegExp(r'[^a-z0-9_]+'), '_');
  }
}
