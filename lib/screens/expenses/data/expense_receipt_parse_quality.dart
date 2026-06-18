part of 'expense_receipt_parser.dart';

ExpenseReceiptParseQuality _parseQualityFor({
  required String? merchantName,
  required DateTime? receiptDate,
  required _ReceiptTotals totals,
  required List<ExpenseReceiptLineRecord> lines,
  required List<ExpenseReceiptLineReview> lineReviews,
  required List<String> warnings,
}) {
  var confidence = .35;
  final reasons = <String>[];

  if ((merchantName ?? '').trim().isNotEmpty) {
    confidence += .12;
  } else {
    reasons.add('Merchant needs review.');
  }
  if (receiptDate != null) {
    confidence += .1;
  } else {
    reasons.add('Receipt date needs review.');
  }
  if (totals.total != null || totals.subtotal != null) {
    confidence += .14;
  } else {
    reasons.add('Receipt total needs review.');
  }
  if (lines.isNotEmpty) {
    confidence += .14;
  } else {
    reasons.add('No receipt lines were detected.');
  }

  final reviewCount = lineReviews.where((review) => review.needsReview).length;
  if (lineReviews.isNotEmpty) {
    final averageLineConfidence =
        lineReviews.fold<double>(0, (sum, review) => sum + review.confidence) /
        lineReviews.length;
    confidence += averageLineConfidence * .22;
  }
  if (reviewCount > 0) {
    confidence -= (reviewCount / lineReviews.length.clamp(1, 999)) * .18;
    reasons.add(
      '$reviewCount receipt line${reviewCount == 1 ? '' : 's'} need review.',
    );
  }
  if (warnings.isNotEmpty) {
    confidence -= (warnings.length * .06).clamp(0, .18).toDouble();
    reasons.addAll(warnings.take(2));
  }

  confidence = confidence.clamp(0, 1).toDouble();
  if (reasons.isEmpty) reasons.add('Receipt parse looks consistent.');
  return ExpenseReceiptParseQuality(
    confidence: confidence,
    needsReview: confidence < .84 || reviewCount > 0 || warnings.isNotEmpty,
    reasons: List.unmodifiable(reasons),
  );
}
