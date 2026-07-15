part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptLineReviewActions on _ExpenseReceiptLine {
  _ExpenseReceiptLine confirmParserReview() {
    return _ExpenseReceiptLine(
      id: id,
      description: description,
      category: category,
      use: use,
      quantity: quantity,
      unitsPerPackage: unitsPerPackage,
      stockUnit: stockUnit,
      subtotal: subtotal,
      businessPercent: businessPercent,
      odometerReading: odometerReading,
      fuelType: fuelType,
      fillType: fillType,
      unitPrice: unitPrice,
      rawReceiptText: rawReceiptText,
      catalogItemId: catalogItemId,
      catalogItemName: catalogItemName,
      catalogItemPath: catalogItemPath,
      catalogMatchConfidence: catalogMatchConfidence,
      catalogMatchedTerms: catalogMatchedTerms,
      parserConfidence: parserConfidence ?? catalogMatchConfidence ?? .9,
      parserReviewLabel: use == _ExpenseLineUse.unclassified
          ? 'Needs classification'
          : 'Good',
      parserReviewReason: use == _ExpenseLineUse.unclassified
          ? 'The receipt text was confirmed, but ownership still requires the user to choose business, personal, or split.'
          : 'User confirmed this parsed receipt line.',
      parserNeedsReview: use == _ExpenseLineUse.unclassified,
      ocrSourceLineId: ocrSourceLineId,
      ocrSourceLineNumber: ocrSourceLineNumber,
      ocrSourceSectionNumber: ocrSourceSectionNumber,
      ocrSourceSectionLineNumber: ocrSourceSectionLineNumber,
      parserExpenseFamily: parserExpenseFamily,
      parserHint: parserHint,
    );
  }

  _ExpenseReceiptLine markExpenseOnly() {
    final nextCategory = category == 'Materials' ? 'Supplies' : category;
    return _ExpenseReceiptLine(
      id: id,
      description: description,
      category: nextCategory,
      use: use == _ExpenseLineUse.personal ? use : _ExpenseLineUse.business,
      quantity: quantity,
      unitsPerPackage: unitsPerPackage,
      stockUnit: stockUnit,
      subtotal: subtotal,
      businessPercent: null,
      odometerReading: odometerReading,
      fuelType: fuelType,
      fillType: fillType,
      unitPrice: unitPrice,
      rawReceiptText: rawReceiptText,
      parserConfidence: parserConfidence,
      parserReviewLabel: 'Good',
      parserReviewReason: 'Marked as expense-only from receipt review.',
      parserNeedsReview: false,
      ocrSourceLineId: ocrSourceLineId,
      ocrSourceLineNumber: ocrSourceLineNumber,
      ocrSourceSectionNumber: ocrSourceSectionNumber,
      ocrSourceSectionLineNumber: ocrSourceSectionLineNumber,
      parserExpenseFamily: parserExpenseFamily,
      parserHint: parserHint,
    );
  }
}
