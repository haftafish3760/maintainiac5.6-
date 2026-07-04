part of 'receipt_processing_contract.dart';

class ReceiptSelectedLineReference {
  const ReceiptSelectedLineReference({
    required this.receiptId,
    required this.receiptLineId,
    required this.proofLineReferenceLabel,
    required this.clientProofDefaultVisibility,
    required this.kind,
    required this.businessUse,
    this.businessPercent = 1,
    this.personalPercent = 0,
    this.sourceReceiptSectionLabel = '',
    this.lineSubtotal = 0,
    this.lineTaxAmount = 0,
    this.lineTotal = 0,
    this.needsParserReview = false,
    this.needsClientProofReview = true,
  });

  factory ReceiptSelectedLineReference.fromDraft({
    required String receiptId,
    required ReceiptLineDraft line,
  }) {
    return ReceiptSelectedLineReference(
      receiptId: receiptId,
      receiptLineId: line.receiptLineId,
      proofLineReferenceLabel: line.proofReferenceLabel,
      clientProofDefaultVisibility: line.clientProofDefaultVisibility,
      kind: line.kind.name,
      businessUse: line.effectiveBusinessUse,
      businessPercent: line.effectiveBusinessPercent,
      personalPercent: line.effectivePersonalPercent,
      sourceReceiptSectionLabel: line.sourceReceiptSectionLabel,
      lineSubtotal: line.subtotal,
      lineTaxAmount: line.taxAmount,
      lineTotal: line.totalWithTax,
      needsParserReview: line.parserNeedsReview,
      needsClientProofReview: line.needsClientProofReview,
    );
  }

  final String receiptId;
  final String receiptLineId;
  final String proofLineReferenceLabel;
  final String clientProofDefaultVisibility;
  final String kind;
  final String businessUse;
  final double businessPercent;
  final double personalPercent;
  final String sourceReceiptSectionLabel;
  final double lineSubtotal;
  final double lineTaxAmount;
  final double lineTotal;
  final bool needsParserReview;
  final bool needsClientProofReview;

  double get safeBusinessPercent {
    final normalizedUse = businessUse.trim().toLowerCase();
    if (normalizedUse == 'personal') return 0;
    if (normalizedUse != 'split') return 1;
    if (!businessPercent.isFinite) return .5;
    return businessPercent.clamp(0, 1).toDouble();
  }

  double get safePersonalPercent => 1 - safeBusinessPercent;

  double get lineBusinessSubtotal => lineSubtotal * safeBusinessPercent;
  double get lineBusinessTaxAmount => lineTaxAmount * safeBusinessPercent;
  double get lineBusinessTotal => lineTotal * safeBusinessPercent;
  double get linePersonalSubtotal => lineSubtotal * safePersonalPercent;
  double get linePersonalTaxAmount => lineTaxAmount * safePersonalPercent;
  double get linePersonalTotal => lineTotal * safePersonalPercent;

  bool get redactsFromClientProofByDefault {
    return clientProofDefaultVisibility ==
        ReceiptLineClientProofVisibility.redactByDefault;
  }

  bool get canShareWithoutClientReview {
    return !redactsFromClientProofByDefault && !needsClientProofReview;
  }

  Map<String, Object?> toLocalMap() {
    return {
      'receiptId': receiptId,
      'receiptLineId': privacySafeReceiptLineId(receiptLineId),
      'proofLineReferenceLabel': privacySafeReceiptProofLineReferenceLabel(
        proofLineReferenceLabel,
      ),
      'clientProofDefaultVisibility': clientProofDefaultVisibility,
      'kind': kind,
      'businessUse': businessUse,
      'businessPercent': safeBusinessPercent,
      'personalPercent': safePersonalPercent,
      if (sourceReceiptSectionLabel.trim().isNotEmpty)
        'sourceReceiptSectionLabel': sourceReceiptSectionLabel.trim(),
      'lineSubtotal': lineSubtotal,
      'lineTaxAmount': lineTaxAmount,
      'lineTotal': lineTotal,
      'lineBusinessSubtotal': lineBusinessSubtotal,
      'lineBusinessTaxAmount': lineBusinessTaxAmount,
      'lineBusinessTotal': lineBusinessTotal,
      'linePersonalSubtotal': linePersonalSubtotal,
      'linePersonalTaxAmount': linePersonalTaxAmount,
      'linePersonalTotal': linePersonalTotal,
      'needsParserReview': needsParserReview,
      'needsClientProofReview': needsClientProofReview,
    };
  }

  Map<String, Object?> toPrivacySafeMap() {
    return {
      'receiptId': receiptId,
      'receiptLineId': privacySafeReceiptLineId(receiptLineId),
      'proofLineReferenceLabel': privacySafeReceiptProofLineReferenceLabel(
        proofLineReferenceLabel,
      ),
      'clientProofDefaultVisibility': clientProofDefaultVisibility,
      'kind': kind,
      'businessUse': businessUse,
      'businessPercent': safeBusinessPercent,
      'personalPercent': safePersonalPercent,
      if (sourceReceiptSectionLabel.trim().isNotEmpty)
        'sourceReceiptSectionLabel': privacySafeReceiptSourceSectionLabel(
          sourceReceiptSectionLabel,
        ),
      'hasAmount': lineTotal > 0 || lineSubtotal > 0,
      'hasBusinessAmount': lineBusinessTotal > 0 || lineBusinessSubtotal > 0,
      'hasPersonalAmount': linePersonalTotal > 0 || linePersonalSubtotal > 0,
      'needsParserReview': needsParserReview,
      'needsClientProofReview': needsClientProofReview,
    };
  }
}

class ReceiptLineSelectionBundle {
  const ReceiptLineSelectionBundle({
    required this.receiptId,
    required this.purpose,
    required this.selectedLines,
    this.excludedLines = const [],
    this.totalSourceLineCount = 0,
  });

  factory ReceiptLineSelectionBundle.fromDrafts({
    required String receiptId,
    required ReceiptLineSelectionPurpose purpose,
    required Iterable<ReceiptLineDraft> sourceLines,
    bool Function(ReceiptLineDraft line)? includeLine,
  }) {
    final source = sourceLines.toList(growable: false);
    final shouldInclude =
        includeLine ?? (line) => !line.redactsFromClientProofByDefault;
    final selected = source
        .where(shouldInclude)
        .map(
          (line) => ReceiptSelectedLineReference.fromDraft(
            receiptId: receiptId,
            line: line,
          ),
        )
        .toList(growable: false);
    final excluded = source
        .where((line) => !shouldInclude(line))
        .map(
          (line) => ReceiptSelectedLineReference.fromDraft(
            receiptId: receiptId,
            line: line,
          ),
        )
        .toList(growable: false);
    return ReceiptLineSelectionBundle(
      receiptId: receiptId,
      purpose: purpose,
      selectedLines: selected,
      excludedLines: excluded,
      totalSourceLineCount: source.length,
    );
  }

  final String receiptId;
  final ReceiptLineSelectionPurpose purpose;
  final List<ReceiptSelectedLineReference> selectedLines;
  final List<ReceiptSelectedLineReference> excludedLines;
  final int totalSourceLineCount;

  int get selectedLineCount => selectedLines.length;
  int get excludedLineCount {
    if (excludedLines.isNotEmpty) return excludedLines.length;
    final count = totalSourceLineCount - selectedLineCount;
    return count < 0 ? 0 : count;
  }

  int get redactedByDefaultCount {
    return selectedLines
        .where((line) => line.redactsFromClientProofByDefault)
        .length;
  }

  int get reviewBeforeShareCount {
    return selectedLines.where((line) => line.needsClientProofReview).length;
  }

  double get selectedSubtotal {
    return selectedLines.fold<double>(
      0,
      (total, line) => total + line.lineSubtotal,
    );
  }

  double get selectedTax {
    return selectedLines.fold<double>(
      0,
      (total, line) => total + line.lineTaxAmount,
    );
  }

  double get selectedTotal {
    return selectedLines.fold<double>(
      0,
      (total, line) => total + line.lineTotal,
    );
  }

  double get selectedBusinessSubtotal {
    return selectedLines.fold<double>(
      0,
      (total, line) => total + line.lineBusinessSubtotal,
    );
  }

  double get selectedBusinessTax {
    return selectedLines.fold<double>(
      0,
      (total, line) => total + line.lineBusinessTaxAmount,
    );
  }

  double get selectedBusinessTotal {
    return selectedLines.fold<double>(
      0,
      (total, line) => total + line.lineBusinessTotal,
    );
  }

  double get selectedPersonalSubtotal {
    return selectedLines.fold<double>(
      0,
      (total, line) => total + line.linePersonalSubtotal,
    );
  }

  double get selectedPersonalTax {
    return selectedLines.fold<double>(
      0,
      (total, line) => total + line.linePersonalTaxAmount,
    );
  }

  double get selectedPersonalTotal {
    return selectedLines.fold<double>(
      0,
      (total, line) => total + line.linePersonalTotal,
    );
  }

  bool get hasSelectedLines => selectedLines.isNotEmpty;
  bool get needsClientProofReview => reviewBeforeShareCount > 0;

  Map<String, Object?> toLocalMap() {
    return {
      'receiptId': receiptId,
      'purpose': purpose.name,
      'selectedLineCount': selectedLineCount,
      'totalSourceLineCount': totalSourceLineCount,
      'excludedLineCount': excludedLineCount,
      'redactedByDefaultCount': redactedByDefaultCount,
      'reviewBeforeShareCount': reviewBeforeShareCount,
      'selectedSubtotal': selectedSubtotal,
      'selectedTax': selectedTax,
      'selectedTotal': selectedTotal,
      'selectedBusinessSubtotal': selectedBusinessSubtotal,
      'selectedBusinessTax': selectedBusinessTax,
      'selectedBusinessTotal': selectedBusinessTotal,
      'selectedPersonalSubtotal': selectedPersonalSubtotal,
      'selectedPersonalTax': selectedPersonalTax,
      'selectedPersonalTotal': selectedPersonalTotal,
      'selectedLines': selectedLines
          .map((line) => line.toLocalMap())
          .toList(growable: false),
      'excludedLines': excludedLines
          .map((line) => line.toLocalMap())
          .toList(growable: false),
    };
  }

  Map<String, Object?> toPrivacySafeMap() {
    return {
      'receiptId': receiptId,
      'purpose': purpose.name,
      'selectedLineCount': selectedLineCount,
      'totalSourceLineCount': totalSourceLineCount,
      'excludedLineCount': excludedLineCount,
      'redactedByDefaultCount': redactedByDefaultCount,
      'reviewBeforeShareCount': reviewBeforeShareCount,
      'hasSelectedSubtotal': selectedSubtotal > 0,
      'hasSelectedTax': selectedTax > 0,
      'hasSelectedTotal': selectedTotal > 0,
      'hasSelectedBusinessTotal': selectedBusinessTotal > 0,
      'hasSelectedPersonalTotal': selectedPersonalTotal > 0,
      'selectedLineReferences': selectedLines
          .map((line) => line.toPrivacySafeMap())
          .toList(growable: false),
      'excludedLineReferences': excludedLines
          .map((line) => line.toPrivacySafeMap())
          .toList(growable: false),
    };
  }
}

class ReceiptMultiReceiptSelectionBundle {
  const ReceiptMultiReceiptSelectionBundle({
    required this.purpose,
    required this.receiptBundles,
  });

  final ReceiptLineSelectionPurpose purpose;
  final List<ReceiptLineSelectionBundle> receiptBundles;

  int get receiptCount => receiptBundles.length;
  bool get hasMultipleReceipts => receiptCount > 1;
  List<String> get receiptIds => List.unmodifiable(
    receiptBundles
        .map((bundle) => bundle.receiptId)
        .where((id) => id.isNotEmpty),
  );
  int get selectedLineCount => receiptBundles.fold<int>(
    0,
    (total, bundle) => total + bundle.selectedLineCount,
  );
  int get totalSourceLineCount => receiptBundles.fold<int>(
    0,
    (total, bundle) => total + bundle.totalSourceLineCount,
  );
  int get excludedLineCount => receiptBundles.fold<int>(
    0,
    (total, bundle) => total + bundle.excludedLineCount,
  );
  int get redactedByDefaultCount => receiptBundles.fold<int>(
    0,
    (total, bundle) => total + bundle.redactedByDefaultCount,
  );
  int get reviewBeforeShareCount => receiptBundles.fold<int>(
    0,
    (total, bundle) => total + bundle.reviewBeforeShareCount,
  );
  double get selectedSubtotal => receiptBundles.fold<double>(
    0,
    (total, bundle) => total + bundle.selectedSubtotal,
  );
  double get selectedTax => receiptBundles.fold<double>(
    0,
    (total, bundle) => total + bundle.selectedTax,
  );
  double get selectedTotal => receiptBundles.fold<double>(
    0,
    (total, bundle) => total + bundle.selectedTotal,
  );
  double get selectedBusinessTotal => receiptBundles.fold<double>(
    0,
    (total, bundle) => total + bundle.selectedBusinessTotal,
  );
  double get selectedPersonalTotal => receiptBundles.fold<double>(
    0,
    (total, bundle) => total + bundle.selectedPersonalTotal,
  );
  bool get hasSelectedLines => selectedLineCount > 0;
  bool get needsClientProofReview => reviewBeforeShareCount > 0;
  bool get hasHiddenClientProofLines =>
      redactedByDefaultCount > 0 || excludedLineCount > 0;

  Map<String, Object?> toPrivacySafeMap() {
    return {
      'schema': 'receipt_multi_receipt_selection_v1',
      'purpose': purpose.name,
      'receiptCount': receiptCount,
      'receiptIds': receiptIds,
      'hasMultipleReceipts': hasMultipleReceipts,
      'selectedLineCount': selectedLineCount,
      'totalSourceLineCount': totalSourceLineCount,
      'excludedLineCount': excludedLineCount,
      'redactedByDefaultCount': redactedByDefaultCount,
      'reviewBeforeShareCount': reviewBeforeShareCount,
      'hasSelectedSubtotal': selectedSubtotal > 0,
      'hasSelectedTax': selectedTax > 0,
      'hasSelectedTotal': selectedTotal > 0,
      'hasSelectedBusinessTotal': selectedBusinessTotal > 0,
      'hasSelectedPersonalTotal': selectedPersonalTotal > 0,
      'needsClientProofReview': needsClientProofReview,
      'hasHiddenClientProofLines': hasHiddenClientProofLines,
      'receiptBundles': receiptBundles
          .map((bundle) => bundle.toPrivacySafeMap())
          .toList(growable: false),
    };
  }
}
