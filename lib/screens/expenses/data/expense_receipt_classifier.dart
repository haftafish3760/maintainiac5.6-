import '../../../shared/widgets/receipt_capture/receipt_capture_models.dart';

enum ExpenseReceiptClassificationKind {
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

class ExpenseReceiptClassifier {
  const ExpenseReceiptClassifier._();

  static ExpenseReceiptClassification classifySharedReceipt({
    required List<ReceiptAttachmentRecord> attachments,
    required String importedText,
    required List<String> messages,
  }) {
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
    final scored = <_ReceiptClassScore>[
      _score(
        ExpenseReceiptClassificationKind.fuel,
        haystack,
        weightedTerms: const {
          'pump': 4,
          'gallon': 4,
          'gallons': 4,
          'gal ': 4,
          'price/gal': 5,
          'diesel': 4,
          'unleaded': 4,
          'octane': 3,
          'fuel center': 5,
          'travel stop': 3,
          'shell': 3,
          'exxon': 3,
          'bp': 2,
          'pilot': 3,
          'flying j': 4,
          'loves': 3,
          "love's": 3,
          'sheetz': 3,
        },
      ),
      _score(
        ExpenseReceiptClassificationKind.repair,
        haystack,
        weightedTerms: const {
          'repair': 5,
          'brake': 5,
          'brakes': 5,
          'caliper': 5,
          'rotor': 4,
          'alternator': 5,
          'starter': 5,
          'battery': 4,
          'sensor': 3,
          'compressor': 4,
          'diagnostic': 4,
          'labor': 3,
          'core charge': 3,
          'auto parts': 3,
          'autozone': 3,
          'advance auto': 4,
          'oreilly': 3,
          "o'reilly": 3,
          'napa': 3,
        },
      ),
      _score(
        ExpenseReceiptClassificationKind.maintenance,
        haystack,
        weightedTerms: const {
          'maintenance': 5,
          'oil change': 7,
          'motor oil': 5,
          'oil filter': 5,
          'air filter': 4,
          'cabin filter': 4,
          'tire rotation': 5,
          'rotation': 3,
          'alignment': 4,
          'coolant': 4,
          'transmission fluid': 5,
          'wiper': 3,
          'jiffy lube': 6,
          'take 5 oil': 6,
          'valvoline': 5,
          'quick lube': 5,
        },
      ),
      _score(
        ExpenseReceiptClassificationKind.materials,
        haystack,
        weightedTerms: const {
          'materials': 5,
          'supplies': 3,
          'inventory': 3,
          'lowes': 4,
          "lowe's": 4,
          'home depot': 5,
          'ace hardware': 5,
          'ferguson': 5,
          'plumbing': 4,
          'electrical': 4,
          'lumber': 4,
          'pipe': 3,
          'fitting': 4,
          'coupling': 4,
          'conduit': 4,
          'romex': 4,
          'drywall': 4,
          'paint': 3,
        },
      ),
      _score(
        ExpenseReceiptClassificationKind.cellPhone,
        haystack,
        weightedTerms: const {
          'cell phone': 6,
          'phone service': 5,
          'wireless': 4,
          'mobile': 3,
          'verizon': 6,
          'at&t': 6,
          'att ': 4,
          't-mobile': 6,
          'tmobile': 6,
          'spectrum mobile': 6,
          'xfinity mobile': 6,
          'monthly service': 3,
          'data plan': 4,
        },
      ),
      _score(
        ExpenseReceiptClassificationKind.jobDocument,
        haystack,
        weightedTerms: const {
          'invoice': 9,
          'invoice #': 8,
          'invoice no': 8,
          'estimate': 9,
          'estimate #': 8,
          'proposal': 8,
          'quote': 6,
          'contract': 7,
          'work order': 8,
          'statement of work': 8,
          'scope of work': 8,
          'change order': 7,
          'job': 3,
          'job number': 6,
          'customer': 3,
          'client': 4,
          'bill to': 7,
          'ship to': 4,
          'remit to': 5,
          'balance due': 7,
          'amount due': 7,
          'payment terms': 7,
        },
      ),
      _score(
        ExpenseReceiptClassificationKind.otherDocument,
        haystack,
        weightedTerms: const {
          'manual': 5,
          'warranty': 5,
          'policy': 5,
          'statement': 5,
          'certificate': 5,
          'report': 4,
          'terms': 4,
        },
      ),
      _score(
        ExpenseReceiptClassificationKind.expenseReceipt,
        haystack,
        weightedTerms: const {
          'receipt': 3,
          'subtotal': 4,
          'tax': 3,
          'total': 3,
          'paid': 3,
          'payment': 3,
          'transaction': 3,
          'merchant': 2,
          'visa': 2,
          'mastercard': 2,
          'amex': 2,
          'discover': 2,
        },
      ),
    ]..sort((a, b) => b.score.compareTo(a.score));

    final best = scored.first;
    if (best.score <= 0) {
      return _classificationFor(
        hasPdfAttachment
            ? ExpenseReceiptClassificationKind.expenseReceipt
            : ExpenseReceiptClassificationKind.otherDocument,
        score: hasPdfAttachment ? 1 : 0,
        secondScore: 0,
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

class _ReceiptClassScore {
  const _ReceiptClassScore(this.kind, this.score);

  final ExpenseReceiptClassificationKind kind;
  final int score;
}
