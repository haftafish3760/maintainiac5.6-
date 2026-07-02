part of '../../receipts/receipt_ocr_contract.dart';

enum ReceiptOcrReviewSeverity {
  good('Good'),
  review('Review'),
  partial('Partial'),
  blocked('Blocked');

  const ReceiptOcrReviewSeverity(this.label);

  final String label;
}

enum ReceiptOcrWarningKind {
  noSource,
  noReadableText,
  sourceSkipped,
  duplicateText,
  probableOverlap,
  sectionGap,
  pdfSafety,
  pdfTooLarge,
  pdfUnreadable,
  pluginUnavailable,
  photoQuality,
  photoReadFailure,
  pdfReadFailure,
  unknown,
}

class ReceiptOcrWarning {
  const ReceiptOcrWarning({
    required this.kind,
    required this.severity,
    required this.message,
  });

  factory ReceiptOcrWarning.fromMessage(String message) {
    final clean = message.trim();
    final lower = clean.toLowerCase();
    final kind = ReceiptOcrWarningClassification.kindFor(lower);
    return ReceiptOcrWarning(
      kind: kind,
      severity: ReceiptOcrWarningClassification.severityFor(kind, lower),
      message: clean,
    );
  }

  final ReceiptOcrWarningKind kind;
  final ReceiptOcrReviewSeverity severity;
  final String message;

  bool get isBlocking => severity == ReceiptOcrReviewSeverity.blocked;
  bool get isPartial => severity == ReceiptOcrReviewSeverity.partial;
  bool get needsReview => severity == ReceiptOcrReviewSeverity.review;

  int get priorityRank => _severityPriority + _kindPriority;

  int get _severityPriority {
    return switch (severity) {
      ReceiptOcrReviewSeverity.blocked => 0,
      ReceiptOcrReviewSeverity.partial => 100,
      ReceiptOcrReviewSeverity.review => 200,
      ReceiptOcrReviewSeverity.good => 300,
    };
  }

  int get _kindPriority {
    return switch (kind) {
      ReceiptOcrWarningKind.noSource => 0,
      ReceiptOcrWarningKind.photoReadFailure => 10,
      ReceiptOcrWarningKind.pdfReadFailure => 12,
      ReceiptOcrWarningKind.pdfSafety => 15,
      ReceiptOcrWarningKind.pdfUnreadable => 20,
      ReceiptOcrWarningKind.pdfTooLarge => 25,
      ReceiptOcrWarningKind.pluginUnavailable => 30,
      ReceiptOcrWarningKind.sectionGap => 35,
      ReceiptOcrWarningKind.probableOverlap => 40,
      ReceiptOcrWarningKind.duplicateText => 45,
      ReceiptOcrWarningKind.sourceSkipped => 50,
      ReceiptOcrWarningKind.photoQuality => 55,
      ReceiptOcrWarningKind.noReadableText => 5,
      ReceiptOcrWarningKind.unknown => 90,
    };
  }

  bool get isConcreteNoTextCause {
    return switch (kind) {
      ReceiptOcrWarningKind.photoQuality ||
      ReceiptOcrWarningKind.photoReadFailure ||
      ReceiptOcrWarningKind.pdfReadFailure ||
      ReceiptOcrWarningKind.pdfSafety ||
      ReceiptOcrWarningKind.pdfUnreadable ||
      ReceiptOcrWarningKind.pdfTooLarge ||
      ReceiptOcrWarningKind.pluginUnavailable => true,
      _ => false,
    };
  }

  static int compareByPriority(
    ReceiptOcrWarning left,
    ReceiptOcrWarning right,
  ) {
    final priority = left.priorityRank.compareTo(right.priorityRank);
    if (priority != 0) return priority;
    return left.label.compareTo(right.label);
  }
}
