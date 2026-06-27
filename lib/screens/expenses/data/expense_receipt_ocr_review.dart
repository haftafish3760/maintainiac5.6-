part of 'expense_ledger_models.dart';

class ExpenseReceiptOcrReview {
  const ExpenseReceiptOcrReview({
    this.severity = '',
    this.source = '',
    this.warningKinds = const [],
    this.warningLabels = const [],
    this.warningKindCounts = const {},
    this.warningCount = 0,
    this.blockingWarningCount = 0,
    this.partialWarningCount = 0,
    this.reviewWarningCount = 0,
    this.attachmentsRead = 0,
    this.attachmentsSkipped = 0,
    this.rawLineCount = 0,
    this.parserLineCount = 0,
    this.pdfPagesRequested = 0,
    this.usedLocalOcr = false,
    this.hadDuplicateOrOverlapText = false,
  });

  factory ExpenseReceiptOcrReview.fromDiagnostics({
    required ReceiptOcrDiagnostics diagnostics,
    required List<ReceiptOcrWarning> warnings,
  }) {
    return ExpenseReceiptOcrReview(
      severity: diagnostics.severity.name,
      source: diagnostics.source.name,
      warningKinds: [for (final warning in warnings) warning.kind.name],
      warningLabels: [for (final warning in warnings) warning.label],
      warningKindCounts: {
        for (final entry in diagnostics.warningKindCounts.entries)
          entry.key.name: entry.value,
      },
      warningCount: diagnostics.warningCount,
      blockingWarningCount: diagnostics.blockingWarningCount,
      partialWarningCount: diagnostics.partialWarningCount,
      reviewWarningCount: diagnostics.reviewWarningCount,
      attachmentsRead: diagnostics.attachmentsRead,
      attachmentsSkipped: diagnostics.attachmentsSkipped,
      rawLineCount: diagnostics.rawLineCount,
      parserLineCount: diagnostics.parserLineCount,
      pdfPagesRequested: diagnostics.pdfPagesRequested,
      usedLocalOcr: diagnostics.usedLocalOcr,
      hadDuplicateOrOverlapText: diagnostics.hadDuplicateOrOverlapText,
    );
  }

  factory ExpenseReceiptOcrReview.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) return const ExpenseReceiptOcrReview();
    return ExpenseReceiptOcrReview(
      severity: _expenseString(map['severity']),
      source: _expenseString(map['source']),
      warningKinds:
          (map['warningKinds'] as List?)?.whereType<String>().toList(
            growable: false,
          ) ??
          const [],
      warningLabels:
          (map['warningLabels'] as List?)?.whereType<String>().toList(
            growable: false,
          ) ??
          const [],
      warningKindCounts:
          (map['warningKindCounts'] as Map?)?.map(
            (key, value) =>
                MapEntry(_expenseString(key), _expenseInt(value) ?? 0),
          ) ??
          const {},
      warningCount: _expenseInt(map['warningCount']) ?? 0,
      blockingWarningCount: _expenseInt(map['blockingWarningCount']) ?? 0,
      partialWarningCount: _expenseInt(map['partialWarningCount']) ?? 0,
      reviewWarningCount: _expenseInt(map['reviewWarningCount']) ?? 0,
      attachmentsRead: _expenseInt(map['attachmentsRead']) ?? 0,
      attachmentsSkipped: _expenseInt(map['attachmentsSkipped']) ?? 0,
      rawLineCount: _expenseInt(map['rawLineCount']) ?? 0,
      parserLineCount: _expenseInt(map['parserLineCount']) ?? 0,
      pdfPagesRequested: _expenseInt(map['pdfPagesRequested']) ?? 0,
      usedLocalOcr: _expenseBool(map['usedLocalOcr']),
      hadDuplicateOrOverlapText: _expenseBool(map['hadDuplicateOrOverlapText']),
    );
  }

  final String severity;
  final String source;
  final List<String> warningKinds;
  final List<String> warningLabels;
  final Map<String, int> warningKindCounts;
  final int warningCount;
  final int blockingWarningCount;
  final int partialWarningCount;
  final int reviewWarningCount;
  final int attachmentsRead;
  final int attachmentsSkipped;
  final int rawLineCount;
  final int parserLineCount;
  final int pdfPagesRequested;
  final bool usedLocalOcr;
  final bool hadDuplicateOrOverlapText;

  bool get hasData {
    return severity.trim().isNotEmpty ||
        source.trim().isNotEmpty ||
        warningCount > 0 ||
        attachmentsRead > 0 ||
        attachmentsSkipped > 0 ||
        rawLineCount > 0 ||
        parserLineCount > 0;
  }

  bool get needsReview {
    return severity == ReceiptOcrReviewSeverity.review.name ||
        severity == ReceiptOcrReviewSeverity.partial.name ||
        severity == ReceiptOcrReviewSeverity.blocked.name ||
        warningCount > 0;
  }

  String get primaryWarningLabel {
    if (warningLabels.isNotEmpty) return warningLabels.first;
    if (warningKinds.isNotEmpty) return warningKinds.first;
    return '';
  }

  int countForWarningKind(String kind) {
    return warningKindCounts[kind] ?? 0;
  }

  Map<String, dynamic> toMap() {
    return {
      'severity': severity,
      'source': source,
      'warningKinds': warningKinds,
      'warningLabels': warningLabels,
      'warningKindCounts': warningKindCounts,
      'warningCount': warningCount,
      'blockingWarningCount': blockingWarningCount,
      'partialWarningCount': partialWarningCount,
      'reviewWarningCount': reviewWarningCount,
      'attachmentsRead': attachmentsRead,
      'attachmentsSkipped': attachmentsSkipped,
      'rawLineCount': rawLineCount,
      'parserLineCount': parserLineCount,
      'pdfPagesRequested': pdfPagesRequested,
      'usedLocalOcr': usedLocalOcr,
      'hadDuplicateOrOverlapText': hadDuplicateOrOverlapText,
    };
  }
}
