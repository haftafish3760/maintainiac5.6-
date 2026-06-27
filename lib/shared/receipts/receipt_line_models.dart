enum ReceiptLineKind { inventory, expense }

enum ReceiptLineReviewState {
  manual,
  parsed,
  needsReview,
  confirmed,
  corrected,
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

  bool get isInventory => kind == ReceiptLineKind.inventory;
  bool get isExpense => kind == ReceiptLineKind.expense;
  bool get isPersonalUse => businessUse == 'personal';
  bool get isSplitUse => businessUse == 'split';
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
    if (isSplitUse) return 'Split ${(businessPercent * 100).round()}% business';
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

  ReceiptLineDraft copyWith({
    ReceiptLineKind? kind,
    String? description,
    String? receiptLineId,
    String? inventoryItemId,
    String? inventoryPath,
    String? expenseCategory,
    double? quantity,
    double? unitsPerPackage,
    String? purchaseType,
    String? unit,
    double? subtotal,
    double? taxRate,
    String? storageArea,
    String? storageDetail,
    String? businessUse,
    double? businessPercent,
    String? note,
    String? rawReceiptText,
    double? catalogMatchConfidence,
    List<String>? catalogMatchedTerms,
    double? parserConfidence,
    String? parserReviewLabel,
    String? parserReviewReason,
    bool? parserNeedsReview,
    String? originalParsedDescription,
    String? originalParsedInventoryItemId,
    String? originalParsedInventoryPath,
    String? reviewAction,
  }) {
    return ReceiptLineDraft(
      kind: kind ?? this.kind,
      description: description ?? this.description,
      receiptLineId: receiptLineId ?? this.receiptLineId,
      inventoryItemId: inventoryItemId ?? this.inventoryItemId,
      inventoryPath: inventoryPath ?? this.inventoryPath,
      expenseCategory: expenseCategory ?? this.expenseCategory,
      quantity: quantity ?? this.quantity,
      unitsPerPackage: unitsPerPackage ?? this.unitsPerPackage,
      purchaseType: purchaseType ?? this.purchaseType,
      unit: unit ?? this.unit,
      subtotal: subtotal ?? this.subtotal,
      taxRate: taxRate ?? this.taxRate,
      storageArea: storageArea ?? this.storageArea,
      storageDetail: storageDetail ?? this.storageDetail,
      businessUse: businessUse ?? this.businessUse,
      businessPercent: businessPercent ?? this.businessPercent,
      note: note ?? this.note,
      rawReceiptText: rawReceiptText ?? this.rawReceiptText,
      catalogMatchConfidence:
          catalogMatchConfidence ?? this.catalogMatchConfidence,
      catalogMatchedTerms: catalogMatchedTerms ?? this.catalogMatchedTerms,
      parserConfidence: parserConfidence ?? this.parserConfidence,
      parserReviewLabel: parserReviewLabel ?? this.parserReviewLabel,
      parserReviewReason: parserReviewReason ?? this.parserReviewReason,
      parserNeedsReview: parserNeedsReview ?? this.parserNeedsReview,
      originalParsedDescription:
          originalParsedDescription ?? this.originalParsedDescription,
      originalParsedInventoryItemId:
          originalParsedInventoryItemId ?? this.originalParsedInventoryItemId,
      originalParsedInventoryPath:
          originalParsedInventoryPath ?? this.originalParsedInventoryPath,
      reviewAction: reviewAction ?? this.reviewAction,
    );
  }

  ReceiptLineDraft confirmedAssistedReview() {
    return copyWith(
      parserConfidence: parserConfidence == null
          ? .98
          : parserConfidence!.clamp(.84, 1).toDouble(),
      parserReviewLabel: 'Good',
      parserReviewReason: 'User confirmed this parsed receipt line.',
      parserNeedsReview: false,
      reviewAction: 'confirmed',
    );
  }

  Map<String, Object?> toMap() {
    return {
      'kind': kind.name,
      'description': description,
      'receiptLineId': receiptLineId,
      'inventoryItemId': inventoryItemId,
      'inventoryPath': inventoryPath,
      'expenseCategory': expenseCategory,
      'quantity': quantity,
      'unitsPerPackage': unitsPerPackage,
      'purchaseType': purchaseType,
      'unit': unit,
      'subtotal': subtotal,
      'taxRate': taxRate,
      'storageArea': storageArea,
      'storageDetail': storageDetail,
      'businessUse': businessUse,
      'businessPercent': businessPercent,
      'note': note,
      'rawReceiptText': rawReceiptText,
      'catalogMatchConfidence': catalogMatchConfidence,
      'catalogMatchedTerms': catalogMatchedTerms,
      'parserConfidence': parserConfidence,
      'parserReviewLabel': parserReviewLabel,
      'parserReviewReason': parserReviewReason,
      'parserNeedsReview': parserNeedsReview,
      'originalParsedDescription': originalParsedDescription,
      'originalParsedInventoryItemId': originalParsedInventoryItemId,
      'originalParsedInventoryPath': originalParsedInventoryPath,
      'reviewAction': reviewAction,
    };
  }
}
