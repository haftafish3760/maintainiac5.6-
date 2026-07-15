part of 'expense_receipt_classifier.dart';

enum ExpenseReceiptClassificationKind {
  ambiguous,
  expenseReceipt,
  fuel,
  materials,
  maintenance,
  repair,
  cellPhone,
  jobDocument,
  otherDocument,
}

class ExpenseReceiptClassification {
  const ExpenseReceiptClassification({
    required this.kind,
    required this.title,
    required this.category,
    required this.detail,
    required this.confidence,
    required this.score,
  });

  final ExpenseReceiptClassificationKind kind;
  final String title;
  final String? category;
  final String detail;
  final double confidence;
  final int score;

  String get confidencePercentLabel => '${(confidence * 100).round()}%';

  String get confidenceLabel {
    if (confidence >= .84) return 'High';
    if (confidence >= .58) return 'Review';
    return 'Low';
  }

  bool get isExpenseCategory => category != null;
}

class _ReceiptClassScore {
  const _ReceiptClassScore(this.kind, this.score);

  final ExpenseReceiptClassificationKind kind;
  final int score;
}
