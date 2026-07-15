part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptLineModelConversions on _ExpenseReceiptLine {
  ExpenseReceiptLineRecord toLedgerLine({String? id}) {
    return ExpenseReceiptLineRecord(
      id: id ?? this.id ?? 'EXPL-${DateTime.now().microsecondsSinceEpoch}',
      description: description,
      category: category,
      use: use.ledgerUse,
      quantity: quantity,
      unitsPerPackage: unitsPerPackage,
      unit: stockUnit,
      subtotal: subtotal,
      businessPercent: businessPercent,
      splitAllocation: splitAllocation,
      odometerReading: odometerReading,
      fuelType: fuelType,
      fillType: fillType,
      unitPrice: unitPrice,
      rawReceiptText: rawReceiptText,
      sourceReceiptText: receiptSourceText,
      displayReceiptText: description,
      normalizedReceiptText: normalizedReceiptText,
      receiptInterpretation: receiptInterpretation,
      catalogItemId: catalogItemId,
      catalogItemName: catalogItemName,
      catalogItemPath: catalogItemPath,
      catalogMatchConfidence: catalogMatchConfidence,
      catalogMatchedTerms: catalogMatchedTerms,
      parserConfidence: parserConfidence,
      parserReviewLabel: parserReviewLabel,
      parserReviewReason: parserReviewReason,
      parserNeedsReview: parserNeedsReview,
      ocrSourceLineId: ocrSourceLineId,
      ocrSourceLineNumber: ocrSourceLineNumber,
      ocrSourceSectionNumber: ocrSourceSectionNumber,
      ocrSourceSectionLineNumber: ocrSourceSectionLineNumber,
      parserExpenseFamily: parserExpenseFamily,
      parserHint: parserHint,
    );
  }
}
