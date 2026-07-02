part of 'receipt_processing_contract.dart';

class ReceiptSelectedLineReference {
  const ReceiptSelectedLineReference({
    required this.receiptId,
    required this.receiptLineId,
    required this.proofLineReferenceLabel,
    required this.clientProofDefaultVisibility,
    required this.kind,
    required this.businessUse,
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
      businessUse: line.businessUse,
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
  final String sourceReceiptSectionLabel;
  final double lineSubtotal;
  final double lineTaxAmount;
  final double lineTotal;
  final bool needsParserReview;
  final bool needsClientProofReview;

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
      'receiptLineId': receiptLineId,
      'proofLineReferenceLabel': proofLineReferenceLabel,
      'clientProofDefaultVisibility': clientProofDefaultVisibility,
      'kind': kind,
      'businessUse': businessUse,
      if (sourceReceiptSectionLabel.trim().isNotEmpty)
        'sourceReceiptSectionLabel': sourceReceiptSectionLabel.trim(),
      'lineSubtotal': lineSubtotal,
      'lineTaxAmount': lineTaxAmount,
      'lineTotal': lineTotal,
      'needsParserReview': needsParserReview,
      'needsClientProofReview': needsClientProofReview,
    };
  }

  Map<String, Object?> toPrivacySafeMap() {
    return {
      'receiptId': receiptId,
      'receiptLineId': receiptLineId,
      'proofLineReferenceLabel': proofLineReferenceLabel,
      'clientProofDefaultVisibility': clientProofDefaultVisibility,
      'kind': kind,
      'businessUse': businessUse,
      if (sourceReceiptSectionLabel.trim().isNotEmpty)
        'sourceReceiptSectionLabel': sourceReceiptSectionLabel.trim(),
      'hasAmount': lineTotal > 0 || lineSubtotal > 0,
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
    this.totalSourceLineCount = 0,
  });

  factory ReceiptLineSelectionBundle.fromDrafts({
    required String receiptId,
    required ReceiptLineSelectionPurpose purpose,
    required Iterable<ReceiptLineDraft> sourceLines,
    bool Function(ReceiptLineDraft line)? includeLine,
  }) {
    final source = sourceLines.toList(growable: false);
    final selected = source
        .where(includeLine ?? (line) => !line.redactsFromClientProofByDefault)
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
      totalSourceLineCount: source.length,
    );
  }

  final String receiptId;
  final ReceiptLineSelectionPurpose purpose;
  final List<ReceiptSelectedLineReference> selectedLines;
  final int totalSourceLineCount;

  int get selectedLineCount => selectedLines.length;
  int get excludedLineCount {
    final excluded = totalSourceLineCount - selectedLineCount;
    return excluded < 0 ? 0 : excluded;
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
      'selectedLines': selectedLines
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
      'selectedLineReferences': selectedLines
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
      'needsClientProofReview': needsClientProofReview,
      'hasHiddenClientProofLines': hasHiddenClientProofLines,
      'receiptBundles': receiptBundles
          .map((bundle) => bundle.toPrivacySafeMap())
          .toList(growable: false),
    };
  }
}
