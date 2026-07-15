import '../../../shared/widgets/receipt_capture/receipt_capture_models.dart';

part 'expense_receipt_classification_models.dart';
part 'expense_receipt_classification_scores.dart';

class ExpenseReceiptClassifier {
  const ExpenseReceiptClassifier._();

  static ExpenseReceiptClassification classifySharedReceipt({
    required List<ReceiptAttachmentRecord> attachments,
    required String importedText,
    required List<String> messages,
  }) {
    if (attachments.isEmpty &&
        importedText.trim().isEmpty &&
        messages.any((message) => message.trim().isNotEmpty)) {
      return _classificationFor(
        ExpenseReceiptClassificationKind.unsupported,
        score: 0,
        secondScore: 0,
      );
    }
    final haystack = [
      importedText,
      ...messages,
      for (final attachment in attachments) ...[
        attachment.displayName,
        attachment.originalFileName,
        attachment.mimeType,
        attachment.sourceLabel,
        attachment.importedText,
        attachment.label,
        attachment.documentSignals.join(' '),
        attachment.riskFlags.join(' '),
      ],
    ].join(' ').toLowerCase();
    return classifyText(
      haystack,
      hasPdfAttachment: attachments.any((a) => a.isPdf),
    );
  }

  static ExpenseReceiptClassification classifyText(
    String text, {
    bool hasPdfAttachment = false,
  }) {
    final haystack = text.toLowerCase();
    final scored = _scoreReceiptClassificationText(haystack);

    final best = scored.first;
    if (best.score <= 0) {
      return _classificationFor(
        hasPdfAttachment
            ? ExpenseReceiptClassificationKind.expenseReceipt
            : ExpenseReceiptClassificationKind.notReceipt,
        score: hasPdfAttachment ? 1 : 0,
        secondScore: 0,
      );
    }
    final second = scored.length > 1 ? scored[1] : null;
    if (second != null &&
        best.score >= 6 &&
        second.score >= 6 &&
        (best.score - second.score).abs() <= 1) {
      return _classificationFor(
        ExpenseReceiptClassificationKind.ambiguous,
        score: best.score,
        secondScore: second.score,
      );
    }
    return _classificationFor(
      best.kind,
      score: best.score,
      secondScore: scored.length > 1 ? scored[1].score : 0,
    );
  }

  static _ReceiptClassScore _score(
    ExpenseReceiptClassificationKind kind,
    String haystack, {
    required Map<String, int> weightedTerms,
  }) {
    var score = 0;
    for (final entry in weightedTerms.entries) {
      if (_containsPhrase(haystack, entry.key)) score += entry.value;
    }
    return _ReceiptClassScore(kind, score);
  }

  static ExpenseReceiptClassification _classificationFor(
    ExpenseReceiptClassificationKind kind, {
    required int score,
    required int secondScore,
  }) {
    final confidence = _confidence(score, secondScore);
    return switch (kind) {
      ExpenseReceiptClassificationKind.ambiguous => ExpenseReceiptClassification(
        kind: kind,
        title: 'Receipt Needs Category Review',
        category: null,
        detail:
            'This receipt has strong signals for more than one category. Maintainiac left the category unchanged so you can choose.',
        confidence: confidence,
        score: score,
      ),
      ExpenseReceiptClassificationKind.notReceipt => ExpenseReceiptClassification(
        kind: kind,
        title: 'Not Clearly a Receipt',
        category: null,
        detail:
            'Maintainiac could not find enough receipt evidence to suggest a category. You can still choose where it belongs or enter it manually.',
        confidence: confidence,
        score: score,
      ),
      ExpenseReceiptClassificationKind.unsupported =>
        ExpenseReceiptClassification(
          kind: kind,
          title: 'Unsupported Receipt Import',
          category: null,
          detail:
              'Maintainiac could not use the shared item as receipt proof. You can attach a photo, select a supported file, or enter the receipt manually.',
          confidence: confidence,
          score: score,
        ),
      ExpenseReceiptClassificationKind.fuel => ExpenseReceiptClassification(
        kind: kind,
        title: 'Fuel Receipt',
        category: 'Fuel',
        detail:
            'Looks fuel-related. Review gallons, fuel type, odometer, and vehicle before saving.',
        confidence: confidence,
        score: score,
      ),
      ExpenseReceiptClassificationKind.repair => ExpenseReceiptClassification(
        kind: kind,
        title: 'Repair Receipt',
        category: 'Repair',
        detail:
            'Looks repair-related. Repair and maintenance can overlap, so review the category before saving.',
        confidence: confidence,
        score: score,
      ),
      ExpenseReceiptClassificationKind.maintenance =>
        ExpenseReceiptClassification(
          kind: kind,
          title: 'Maintenance Receipt',
          category: 'Maintenance',
          detail:
              'Looks maintenance-related. Review whether it should also update the maintenance log later.',
          confidence: confidence,
          score: score,
        ),
      ExpenseReceiptClassificationKind.materials => ExpenseReceiptClassification(
        kind: kind,
        title: 'Materials / Inventory Receipt',
        category: 'Materials',
        detail:
            'Looks supply-related. Review whether these items should stay expense-only or also become inventory.',
        confidence: confidence,
        score: score,
      ),
      ExpenseReceiptClassificationKind.cellPhone => ExpenseReceiptClassification(
        kind: kind,
        title: 'Cell Phone Receipt',
        category: 'Cell Phone',
        detail:
            'Looks like a phone or wireless bill. Review business and personal split before saving.',
        confidence: confidence,
        score: score,
      ),
      ExpenseReceiptClassificationKind.jobDocument =>
        ExpenseReceiptClassification(
          kind: kind,
          title: 'Job / Contractor Document',
          category: null,
          detail:
              'Looks like invoice, estimate, job, or contractor paperwork. Save it as read-only proof without forcing it into expenses.',
          confidence: confidence,
          score: score,
        ),
      ExpenseReceiptClassificationKind.otherDocument =>
        ExpenseReceiptClassification(
          kind: kind,
          title: 'Other Document',
          category: null,
          detail:
              'Looks more like a document than a receipt. Save it as proof only if it belongs with this record.',
          confidence: confidence,
          score: score,
        ),
      ExpenseReceiptClassificationKind.expenseReceipt =>
        ExpenseReceiptClassification(
          kind: kind,
          title: 'Receipt / Expense',
          category: null,
          detail:
              'Looks like a receipt. Review it as an expense and choose the right category before saving.',
          confidence: confidence,
          score: score,
        ),
    };
  }

  static double _confidence(int score, int secondScore) {
    if (score <= 0) return .25;
    final separation = score - secondScore;
    final raw = .42 + (score * .045) + (separation * .035);
    return raw.clamp(.45, .96);
  }

  static bool _containsPhrase(String text, String phrase) {
    final escaped = RegExp.escape(phrase.toLowerCase().trim());
    return RegExp(r'(^|[^a-z0-9])' + escaped + r'([^a-z0-9]|$)').hasMatch(text);
  }
}
