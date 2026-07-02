part of 'expense_ledger_store.dart';

String _topOcrRecoveryToken(Map<String, int> counts) {
  if (counts.isEmpty) return '';
  final entries = counts.entries.toList()
    ..sort((left, right) {
      final byCount = right.value.compareTo(left.value);
      if (byCount != 0) return byCount;
      return left.key.compareTo(right.key);
    });
  return entries.first.key;
}

int _compareReceiptsForCalendarDay(
  ExpenseReceiptRecord left,
  ExpenseReceiptRecord right,
) {
  final leftMinutes = left.receiptTimeMinutes;
  final rightMinutes = right.receiptTimeMinutes;
  if (leftMinutes != null && rightMinutes != null) {
    final byEnteredTime = leftMinutes.compareTo(rightMinutes);
    if (byEnteredTime != 0) return byEnteredTime;
    return _compareCreatedOrder(left, right);
  }
  if (leftMinutes != null) return -1;
  if (rightMinutes != null) return 1;
  return _compareCreatedOrder(left, right);
}

int _compareCreatedOrder(
  ExpenseReceiptRecord left,
  ExpenseReceiptRecord right,
) {
  final leftCreated = left.createdAt;
  final rightCreated = right.createdAt;
  if (leftCreated != null && rightCreated != null) {
    final byCreated = leftCreated.compareTo(rightCreated);
    if (byCreated != 0) return byCreated;
  } else if (leftCreated != null) {
    return -1;
  } else if (rightCreated != null) {
    return 1;
  }
  return left.id.compareTo(right.id);
}

String _normalizeReceiptFingerprintText(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
}

ExpenseReceiptDuplicateCandidate? _probableDuplicateCandidate(
  ExpenseReceiptRecord incoming,
  ExpenseReceiptRecord existing,
) {
  final incomingMerchant = _normalizeReceiptFingerprintText(
    incoming.merchantName,
  );
  final existingMerchant = _normalizeReceiptFingerprintText(
    existing.merchantName,
  );
  if (incomingMerchant.isEmpty || incomingMerchant != existingMerchant) {
    return null;
  }

  final sameDate = _sameReceiptDay(incoming.receiptDate, existing.receiptDate);
  final closeDate = _closeReceiptDay(
    incoming.receiptDate,
    existing.receiptDate,
  );
  final sameAmount = _sameMoney(incoming.total, existing.total);
  final similarAmount = _similarMoney(incoming.total, existing.total);
  final sameReceiptNumber = _sameRequiredText(
    incoming.receiptNumber,
    existing.receiptNumber,
  );
  final sameTax = _sameOptionalMoney(incoming.receiptTax, existing.receiptTax);
  final compatibleCategory = _compatibleOptionalText(
    incoming.primaryCategoryLabel,
    existing.primaryCategoryLabel,
  );
  final compatibleVehicle = _compatibleOptionalText(
    incoming.vehicleId ?? '',
    existing.vehicleId ?? '',
  );
  final samePaymentMethod = _sameOptionalText(
    incoming.paymentMethod,
    existing.paymentMethod,
  );

  if (sameDate && sameAmount && sameReceiptNumber) {
    return ExpenseReceiptDuplicateCandidate.fromReceipt(
      receipt: existing,
      confidence: ExpenseDuplicateConfidence.veryHigh,
      reason: 'Same store, date, total, and receipt number',
    );
  }
  if (sameDate &&
      sameAmount &&
      sameTax &&
      compatibleCategory &&
      compatibleVehicle &&
      samePaymentMethod) {
    return ExpenseReceiptDuplicateCandidate.fromReceipt(
      receipt: existing,
      confidence: ExpenseDuplicateConfidence.high,
      reason: 'Same store, date, amount, category, and vehicle',
    );
  }
  if (closeDate && (sameAmount || similarAmount)) {
    return ExpenseReceiptDuplicateCandidate.fromReceipt(
      receipt: existing,
      confidence: ExpenseDuplicateConfidence.possible,
      reason: 'Same store with a similar amount near this date',
    );
  }
  return null;
}

Set<String> _receiptHashes(ExpenseReceiptRecord receipt) {
  return {
    if (receipt.fileHashSha256.trim().isNotEmpty) receipt.fileHashSha256.trim(),
    for (final attachment in receipt.attachments)
      if (attachment.fileHash.trim().isNotEmpty) attachment.fileHash.trim(),
  };
}

String _primaryFileHash(ExpenseReceiptRecord receipt) {
  final hashes = _receiptHashes(receipt);
  return hashes.isEmpty ? '' : hashes.first;
}

bool _sameReceiptDay(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

bool _closeReceiptDay(DateTime first, DateTime second) {
  return first.difference(second).inDays.abs() <= 3;
}

bool _sameMoney(double first, double second) {
  return ((first * 100).round() - (second * 100).round()).abs() <= 1;
}

bool _similarMoney(double first, double second) {
  final delta = (first - second).abs();
  if (delta <= 1) return true;
  final larger = first.abs() > second.abs() ? first.abs() : second.abs();
  if (larger <= 0) return false;
  return delta / larger <= .02;
}

bool _sameOptionalMoney(double first, double second) {
  if (first == 0 || second == 0) return true;
  return _sameMoney(first, second);
}

bool _sameOptionalText(String first, String second) {
  final left = _normalizeReceiptFingerprintText(first);
  final right = _normalizeReceiptFingerprintText(second);
  if (left.isEmpty || right.isEmpty) return true;
  return left == right;
}

bool _sameRequiredText(String first, String second) {
  final left = _normalizeReceiptFingerprintText(first);
  final right = _normalizeReceiptFingerprintText(second);
  if (left.isEmpty || right.isEmpty) return false;
  return left == right;
}

bool _compatibleOptionalText(String first, String second) {
  final left = _normalizeReceiptFingerprintText(first);
  final right = _normalizeReceiptFingerprintText(second);
  if (left.isEmpty || right.isEmpty) return true;
  if (left == 'mixed' || right == 'mixed') return true;
  return left == right;
}
