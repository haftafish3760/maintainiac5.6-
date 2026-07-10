part of 'receipt_line_models.dart';

extension ReceiptLineDraftSerialization on ReceiptLineDraft {
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
    String? proofLineReferenceLabel,
    String? clientProofDefaultVisibility,
    String? sourceReceiptSectionLabel,
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
      proofLineReferenceLabel:
          proofLineReferenceLabel ?? this.proofLineReferenceLabel,
      clientProofDefaultVisibility:
          clientProofDefaultVisibility ?? this.clientProofDefaultVisibility,
      sourceReceiptSectionLabel:
          sourceReceiptSectionLabel ?? this.sourceReceiptSectionLabel,
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
      'proofLineReferenceLabel': proofLineReferenceLabel,
      'clientProofDefaultVisibility': clientProofDefaultVisibility,
      'sourceReceiptSectionLabel': sourceReceiptSectionLabel,
      'canStageForJobOrEstimate': canStageForJobOrEstimate,
      'suggestedMaterialActions': suggestedMaterialActions,
      'privacySafeProofReference': privacySafeProofReference,
    };
  }
}
