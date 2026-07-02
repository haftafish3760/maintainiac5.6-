part of 'expense_ledger_models.dart';

extension ExpenseReceiptLineRecordSerialization on ExpenseReceiptLineRecord {
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'category': category,
      'use': use.name,
      'quantity': quantity,
      'unitsPerPackage': unitsPerPackage,
      'unit': unit,
      'subtotal': subtotal,
      'businessPercent': businessPercent,
      'odometerReading': odometerReading,
      'fuelType': fuelType,
      'fillType': fillType,
      'unitPrice': unitPrice,
      'rawReceiptText': rawReceiptText,
      'catalogItemId': catalogItemId,
      'catalogItemName': catalogItemName,
      'catalogItemPath': catalogItemPath,
      'catalogMatchConfidence': catalogMatchConfidence,
      'catalogMatchedTerms': catalogMatchedTerms,
      'parserConfidence': parserConfidence,
      'parserReviewLabel': parserReviewLabel,
      'parserReviewReason': parserReviewReason,
      'parserNeedsReview': parserNeedsReview,
      'ocrSourceLineId': ocrSourceLineId,
      'ocrSourceLineNumber': ocrSourceLineNumber,
      'ocrSourceSectionNumber': ocrSourceSectionNumber,
      'ocrSourceSectionLineNumber': ocrSourceSectionLineNumber,
      'parserExpenseFamily': parserExpenseFamily,
      'parserHint': parserHint,
      'receiptProofLineReferenceLabel': receiptProofLineReferenceLabel,
      'receiptProofRedactionAnchorCode': receiptProofRedactionAnchorCode,
      'clientProofDefaultVisibility': clientProofDefaultVisibility,
      'clientProofReviewLabel': clientProofReviewLabel,
      'privacySafeProofReference': privacySafeProofReference,
    };
  }
}
