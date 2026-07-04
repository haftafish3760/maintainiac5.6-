part 'receipt_line_models_serialization.dart';

enum ReceiptLineKind { inventory, expense }

enum ReceiptLineReviewState {
  manual,
  parsed,
  needsReview,
  confirmed,
  corrected,
}

class ReceiptLineClientProofVisibility {
  const ReceiptLineClientProofVisibility._();

  static const reviewForClientProof = 'review_for_client_proof';
  static const reviewBeforeClientShare = 'review_before_client_share';
  static const redactByDefault = 'redact_by_default';
}

class ReceiptLineDraft {
  const ReceiptLineDraft({
    required this.kind,
    required this.description,
    this.receiptLineId = '',
    this.inventoryItemId = '',
    this.inventoryPath = '',
    this.expenseCategory = '',
    this.quantity = 1,
    this.unitsPerPackage = 1,
    this.purchaseType = 'each',
    this.unit = 'each',
    this.subtotal = 0,
    this.taxRate = 0,
    this.storageArea = '',
    this.storageDetail = '',
    this.businessUse = 'business',
    this.businessPercent = 1,
    this.note = '',
    this.rawReceiptText = '',
    this.catalogMatchConfidence,
    this.catalogMatchedTerms = const [],
    this.parserConfidence,
    this.parserReviewLabel,
    this.parserReviewReason,
    this.parserNeedsReview = false,
    this.originalParsedDescription = '',
    this.originalParsedInventoryItemId = '',
    this.originalParsedInventoryPath = '',
    this.reviewAction = 'manual',
    this.proofLineReferenceLabel = '',
    this.clientProofDefaultVisibility =
        ReceiptLineClientProofVisibility.reviewForClientProof,
    this.sourceReceiptSectionLabel = '',
  });

  final ReceiptLineKind kind;
  final String description;
  final String receiptLineId;
  final String inventoryItemId;
  final String inventoryPath;
  final String expenseCategory;
  final double quantity;
  final double unitsPerPackage;
  final String purchaseType;
  final String unit;
  final double subtotal;
  final double taxRate;
  final String storageArea;
  final String storageDetail;
  final String businessUse;
  final double businessPercent;
  final String note;
  final String rawReceiptText;
  final double? catalogMatchConfidence;
  final List<String> catalogMatchedTerms;
  final double? parserConfidence;
  final String? parserReviewLabel;
  final String? parserReviewReason;
  final bool parserNeedsReview;
  final String originalParsedDescription;
  final String originalParsedInventoryItemId;
  final String originalParsedInventoryPath;
  final String reviewAction;
  final String proofLineReferenceLabel;
  final String clientProofDefaultVisibility;
  final String sourceReceiptSectionLabel;

  bool get isInventory => kind == ReceiptLineKind.inventory;
  bool get isExpense => kind == ReceiptLineKind.expense;
  String get effectiveBusinessUse {
    final normalized = businessUse.trim().toLowerCase();
    return switch (normalized) {
      'personal' => 'personal',
      'split' => 'split',
      _ => 'business',
    };
  }

  double get effectiveBusinessPercent {
    if (isPersonalUse) return 0;
    if (isBusinessUse) return 1;
    if (!businessPercent.isFinite) return .5;
    return businessPercent.clamp(0, 1).toDouble();
  }

  double get effectivePersonalPercent => 1 - effectiveBusinessPercent;

  bool get isPersonalUse => effectiveBusinessUse == 'personal';
  bool get isSplitUse => effectiveBusinessUse == 'split';
  bool get isBusinessUse => !isPersonalUse && !isSplitUse;
  double get totalUnits => quantity * unitsPerPackage;
  double get taxAmount => subtotal * taxRate;
  double get totalWithTax => subtotal + taxAmount;
  double get unitCostWithTax => totalUnits <= 0 ? 0 : totalWithTax / totalUnits;

  String get displayDescription {
    final value = description.trim();
    if (value.isNotEmpty) return value;
    if (isInventory) return 'Inventory material';
    if (isPersonalUse) return 'Personal receipt item';
    if (isSplitUse) return 'Split business/personal item';
    return 'Business receipt item';
  }

  String get receiptLaneLabel {
    if (isInventory) return 'Inventory';
    if (isPersonalUse) return 'Personal';
    if (isSplitUse) return 'Split business/personal';
    return 'Business expense only';
  }

  String get businessUseLabel {
    if (isPersonalUse) return 'Personal';
    if (isSplitUse) {
      return 'Split ${(effectiveBusinessPercent * 100).round()}% business';
    }
    return 'Business';
  }

  bool get hasAssistedReview {
    return parserConfidence != null ||
        parserReviewLabel != null ||
        parserReviewReason != null ||
        catalogMatchConfidence != null ||
        catalogMatchedTerms.isNotEmpty;
  }

  String get assistedReviewLabel {
    final label = parserReviewLabel?.trim();
    if (label != null && label.isNotEmpty) return label;
    final confidence = parserConfidence;
    if (confidence == null) return parserNeedsReview ? 'Review' : 'Parsed';
    if (confidence >= .84 && !parserNeedsReview) return 'Good';
    if (confidence >= .58) return 'Review';
    return 'Poor';
  }

  String get assistedReviewDetail {
    final detail = parserReviewReason?.trim();
    if (detail != null && detail.isNotEmpty) return detail;
    if (isInventory && catalogMatchConfidence != null) {
      return 'Matched inventory catalog at ${(catalogMatchConfidence! * 100).round()}%.';
    }
    if (isInventory) return 'Matched inventory catalog.';
    return 'No inventory catalog match; saved as ${receiptLaneLabel.toLowerCase()}.';
  }

  String get catalogMatchLabel {
    final confidence = catalogMatchConfidence;
    if (confidence == null) return '';
    return 'Catalog ${(confidence * 100).round()}%';
  }

  bool get canConfirmAssistedReview =>
      hasAssistedReview &&
      reviewState != ReceiptLineReviewState.confirmed &&
      reviewState != ReceiptLineReviewState.corrected;
  ReceiptLineReviewState get reviewState {
    if (reviewAction == 'edited') return ReceiptLineReviewState.corrected;
    if (reviewAction == 'confirmed') return ReceiptLineReviewState.confirmed;
    if (parserNeedsReview) return ReceiptLineReviewState.needsReview;
    if (hasAssistedReview || reviewAction == 'parsed') {
      return ReceiptLineReviewState.parsed;
    }
    return ReceiptLineReviewState.manual;
  }

  bool get hasCorrectionAudit =>
      originalParsedDescription.trim().isNotEmpty ||
      originalParsedInventoryItemId.trim().isNotEmpty ||
      reviewAction != 'manual';
  bool get wasChangedFromParsedGuess {
    if (!hasCorrectionAudit) return false;
    final originalDescription = originalParsedDescription.trim();
    final originalItemId = originalParsedInventoryItemId.trim();
    final descriptionChanged =
        originalDescription.isNotEmpty &&
        originalDescription != description.trim();
    final itemChanged =
        originalItemId.isNotEmpty && originalItemId != inventoryItemId.trim();
    return reviewAction == 'edited' || descriptionChanged || itemChanged;
  }

  String get reviewActionLabel {
    return switch (reviewAction) {
      'confirmed' => 'Confirmed',
      'edited' => 'Corrected',
      'parsed' => 'Parsed',
      _ => 'Manual',
    };
  }

  String get proofReferenceLabel {
    final label = proofLineReferenceLabel.trim();
    if (label.isNotEmpty) return label;
    final lineId = receiptLineId.trim();
    return lineId.isEmpty ? 'Receipt line' : lineId;
  }

  bool get redactsFromClientProofByDefault {
    return clientProofDefaultVisibility ==
        ReceiptLineClientProofVisibility.redactByDefault;
  }

  bool get needsClientProofReview {
    return clientProofDefaultVisibility ==
            ReceiptLineClientProofVisibility.reviewForClientProof ||
        clientProofDefaultVisibility ==
            ReceiptLineClientProofVisibility.reviewBeforeClientShare;
  }

  String get clientProofReviewLabel {
    if (redactsFromClientProofByDefault) return 'Hidden from client proof';
    if (clientProofDefaultVisibility ==
        ReceiptLineClientProofVisibility.reviewBeforeClientShare) {
      return 'Review before sharing';
    }
    return 'Review for client proof';
  }

  Map<String, Object?> get privacySafeProofReference {
    return {
      'receiptLineId': receiptLineId,
      'proofLineReferenceLabel': proofReferenceLabel,
      'clientProofDefaultVisibility': clientProofDefaultVisibility,
      'clientProofReviewLabel': clientProofReviewLabel,
      if (sourceReceiptSectionLabel.trim().isNotEmpty)
        'sourceReceiptSectionLabel': sourceReceiptSectionLabel.trim(),
      'kind': kind.name,
      'businessUse': effectiveBusinessUse,
      'businessPercent': effectiveBusinessPercent,
      'personalPercent': effectivePersonalPercent,
      'hasAmount': subtotal > 0,
      'needsParserReview': parserNeedsReview,
    };
  }

  bool get requiresInventoryConfirmation {
    return isInventory && hasAssistedReview && canConfirmAssistedReview;
  }

  String get reviewStatusLabel {
    if (requiresInventoryConfirmation) return 'Needs confirmation';
    return switch (reviewState) {
      ReceiptLineReviewState.corrected => 'Corrected',
      ReceiptLineReviewState.confirmed => 'Confirmed',
      ReceiptLineReviewState.needsReview => 'Needs review',
      ReceiptLineReviewState.parsed => 'Parsed',
      ReceiptLineReviewState.manual => 'Manual',
    };
  }

  String get receiptReviewSummary {
    if (requiresInventoryConfirmation) {
      return 'Inventory match must be confirmed before stock updates.';
    }
    if (isInventory && reviewState == ReceiptLineReviewState.confirmed) {
      return 'Inventory match confirmed for stock update.';
    }
    if (isInventory && reviewState == ReceiptLineReviewState.corrected) {
      return 'Corrected inventory match will update stock.';
    }
    if (isInventory) {
      return 'Manual inventory line will update stock.';
    }
    if (isPersonalUse) {
      return 'Saved on the receipt as personal, not inventory.';
    }
    if (isSplitUse) {
      return 'Saved on the receipt as split business/personal.';
    }
    return 'Saved on the receipt as business-only, not inventory.';
  }
}
