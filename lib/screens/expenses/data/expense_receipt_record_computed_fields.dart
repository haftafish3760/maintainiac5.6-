part of 'expense_ledger_models.dart';

extension ExpenseReceiptRecordComputedFields on ExpenseReceiptRecord {
  int get lineSubtotalCents =>
      lines.fold(0, (sum, line) => sum + line.subtotalCents);
  int get receiptSubtotalCents => enteredSubtotalCents ?? lineSubtotalCents;
  int get receiptTaxCents {
    final entered = enteredTaxCents;
    if (entered != null) return entered;
    final total = enteredTotalCents;
    final subtotal = enteredSubtotalCents;
    if (total != null && subtotal != null) return total - subtotal;
    return 0;
  }

  int get totalCents =>
      enteredTotalCents ?? receiptSubtotalCents + receiptTaxCents;
  int get receiptAdjustmentCents => totalCents - lineSubtotalCents;

  double get lineSubtotal => lineSubtotalCents / 100;
  double get receiptSubtotal => receiptSubtotalCents / 100;
  double get receiptTax {
    return receiptTaxCents / 100;
  }

  double get total => totalCents / 100;
  double get receiptAdjustment => receiptAdjustmentCents / 100;
  double? get effectiveTaxRate {
    final subtotal = receiptSubtotal;
    if (subtotal <= 0 || receiptTax == 0) return null;
    return receiptTax / subtotal;
  }

  int get businessLineSubtotalCents =>
      lines.fold(0, (sum, line) => sum + line.businessCents);
  int get personalLineSubtotalCents =>
      lines.fold(0, (sum, line) => sum + line.personalCents);
  int get unclassifiedLineSubtotalCents => lines
      .where((line) => line.use == ExpenseLineUse.unclassified)
      .fold(0, (sum, line) => sum + line.subtotalCents);
  double get businessLineSubtotal => businessLineSubtotalCents / 100;
  double get personalLineSubtotal => personalLineSubtotalCents / 100;
  double get unclassifiedLineSubtotal => unclassifiedLineSubtotalCents / 100;
  int get businessTotalCents =>
      businessLineSubtotalCents +
      _allocatedReceiptAdjustmentCents(businessLineSubtotalCents);
  int get personalTotalCents =>
      personalLineSubtotalCents +
      _allocatedReceiptAdjustmentCents(personalLineSubtotalCents);
  int get unclassifiedTotalCents =>
      totalCents - businessTotalCents - personalTotalCents;
  double get businessTotal => businessTotalCents / 100;
  double get personalTotal => personalTotalCents / 100;
  double get unclassifiedTotal => unclassifiedTotalCents / 100;
  bool get hasReceiptAttachment => hasReceiptProof || attachments.isNotEmpty;
  String get title => merchantName.trim().isEmpty ? 'Receipt' : merchantName;

  String get primaryFileHashSha256 {
    final savedHash = fileHashSha256.trim();
    if (savedHash.isNotEmpty) return savedHash;
    for (final attachment in attachments) {
      final hash = attachment.fileHash.trim();
      if (hash.isNotEmpty) return hash;
    }
    return '';
  }

  String get primaryCategoryLabel {
    final categories = lines
        .map((line) => line.category.trim())
        .where((category) => category.isNotEmpty)
        .toSet();
    if (categories.isEmpty) return 'Uncategorized';
    if (categories.length == 1) return categories.single;
    return 'Mixed';
  }

  double totalForLine(ExpenseReceiptLineRecord line) {
    return line.subtotal + _allocatedReceiptAdjustment(line.subtotal);
  }

  double businessTotalForLine(ExpenseReceiptLineRecord line) {
    return line.businessAmount +
        _allocatedReceiptAdjustment(line.businessAmount);
  }

  double personalTotalForLine(ExpenseReceiptLineRecord line) {
    return line.personalAmount +
        _allocatedReceiptAdjustment(line.personalAmount);
  }

  double unclassifiedTotalForLine(ExpenseReceiptLineRecord line) {
    if (line.use != ExpenseLineUse.unclassified) return 0;
    return line.subtotal + _allocatedReceiptAdjustment(line.subtotal);
  }

  DateTime get sortDate {
    final minutes = receiptTimeMinutes;
    if (minutes == null) {
      return DateTime(
        receiptDate.year,
        receiptDate.month,
        receiptDate.day,
        23,
        59,
      );
    }
    return DateTime(
      receiptDate.year,
      receiptDate.month,
      receiptDate.day,
      minutes ~/ 60,
      minutes % 60,
    );
  }

  double _allocatedReceiptAdjustment(double lineAmount) {
    final subtotal = lineSubtotal;
    if (subtotal <= 0 || receiptAdjustment == 0) return 0;
    return receiptAdjustment * (lineAmount / subtotal);
  }

  int _allocatedReceiptAdjustmentCents(int lineAmountCents) {
    if (lineSubtotalCents <= 0 || receiptAdjustmentCents == 0) return 0;
    return (receiptAdjustmentCents * lineAmountCents / lineSubtotalCents)
        .round();
  }
}
