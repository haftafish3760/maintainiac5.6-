part of 'expense_ledger_models.dart';

extension ExpenseReceiptRecordComputedFields on ExpenseReceiptRecord {
  double get lineSubtotal => lines.fold(0, (sum, line) => sum + line.subtotal);
  double get receiptSubtotal => enteredSubtotal ?? lineSubtotal;
  double get receiptTax {
    if (enteredTax != null) return enteredTax!;
    final total = enteredTotal;
    final subtotal = enteredSubtotal;
    if (total != null && subtotal != null) {
      return total - subtotal;
    }
    return 0;
  }

  double get total => enteredTotal ?? lineSubtotal + receiptAdjustment;
  double get receiptAdjustment =>
      (enteredTotal ?? receiptSubtotal + receiptTax) - lineSubtotal;
  double? get effectiveTaxRate {
    final subtotal = receiptSubtotal;
    if (subtotal <= 0 || receiptTax == 0) return null;
    return receiptTax / subtotal;
  }

  double get businessLineSubtotal =>
      lines.fold(0, (sum, line) => sum + line.businessAmount);
  double get personalLineSubtotal =>
      lines.fold(0, (sum, line) => sum + line.personalAmount);
  double get businessTotal =>
      businessLineSubtotal + _allocatedReceiptAdjustment(businessLineSubtotal);
  double get personalTotal =>
      personalLineSubtotal + _allocatedReceiptAdjustment(personalLineSubtotal);
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
}
