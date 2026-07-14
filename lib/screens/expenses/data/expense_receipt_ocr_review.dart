part of 'expense_ledger_models.dart';

class ExpenseReceiptOcrReview {
  const ExpenseReceiptOcrReview({
    this.severity = '',
    this.source = '',
    this.warningKinds = const [],
    this.warningLabels = const [],
    this.warningKindCounts = const {},
    this.primaryWarningKind = '',
    this.primaryWarningLabelOverride = '',
    this.primaryWarningTargetLabel = '',
    this.primaryWarningTargetInstruction = '',
    this.recoveryAction = '',
    this.recoveryTarget = '',
    this.recoverySummary = '',
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
      primaryWarningKind: diagnostics.primaryWarningKind,
      primaryWarningLabelOverride: diagnostics.primaryWarningLabel,
      primaryWarningTargetLabel: diagnostics.primaryWarningTargetLabel,
      primaryWarningTargetInstruction:
          diagnostics.primaryWarningTargetInstruction,
      recoveryAction: _receiptOcrRecoveryActionFor(
        diagnostics.primaryWarningKind,
        diagnostics.source.name,
      ),
      recoveryTarget: _receiptOcrRecoveryTargetFor(
        diagnostics.primaryWarningKind,
        diagnostics.source.name,
      ),
      recoverySummary: _receiptOcrRecoverySummaryFor(
        diagnostics.primaryWarningKind,
        diagnostics.source.name,
      ),
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
    final primaryWarningKind = _expenseString(map['primaryWarningKind']);
    final source = _expenseString(map['source']);
    final severity = _expenseString(map['severity']);
    final warningCount = _expenseInt(map['warningCount']) ?? 0;
    final shouldBackfillRecovery =
        primaryWarningKind.trim().isNotEmpty ||
        warningCount > 0 ||
        severity == ReceiptOcrReviewSeverity.review.name ||
        severity == ReceiptOcrReviewSeverity.partial.name ||
        severity == ReceiptOcrReviewSeverity.blocked.name;
    return ExpenseReceiptOcrReview(
      severity: severity,
      source: source,
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
      primaryWarningKind: primaryWarningKind,
      primaryWarningLabelOverride: _expenseString(map['primaryWarningLabel']),
      primaryWarningTargetLabel: _expenseString(
        map['primaryWarningTargetLabel'],
      ),
      primaryWarningTargetInstruction: _expenseString(
        map['primaryWarningTargetInstruction'],
      ),
      recoveryAction: _expenseString(map['recoveryAction']).isNotEmpty
          ? _expenseString(map['recoveryAction'])
          : shouldBackfillRecovery
          ? _receiptOcrRecoveryActionFor(primaryWarningKind, source)
          : '',
      recoveryTarget: _expenseString(map['recoveryTarget']).isNotEmpty
          ? _expenseString(map['recoveryTarget'])
          : shouldBackfillRecovery
          ? _receiptOcrRecoveryTargetFor(primaryWarningKind, source)
          : '',
      recoverySummary: _expenseString(map['recoverySummary']).isNotEmpty
          ? _expenseString(map['recoverySummary'])
          : shouldBackfillRecovery
          ? _receiptOcrRecoverySummaryFor(primaryWarningKind, source)
          : '',
      warningCount: warningCount,
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
  final String primaryWarningKind;
  final String primaryWarningLabelOverride;
  final String primaryWarningTargetLabel;
  final String primaryWarningTargetInstruction;
  final String recoveryAction;
  final String recoveryTarget;
  final String recoverySummary;
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
    if (primaryWarningLabelOverride.isNotEmpty) {
      return primaryWarningLabelOverride;
    }
    if (warningLabels.isNotEmpty) return warningLabels.first;
    if (warningKinds.isNotEmpty) return warningKinds.first;
    return '';
  }

  String get commandCenterPrimaryIssue {
    final targetLabel = _receiptOcrCommandCenterTextOrEmpty(
      primaryWarningTargetLabel,
    );
    if (targetLabel.isNotEmpty) return targetLabel;
    final kindLabel = _receiptOcrIssueForWarningKind(primaryWarningKind);
    if (kindLabel.isNotEmpty) return kindLabel;
    final warningLabel = _receiptOcrCommandCenterTextOrEmpty(
      primaryWarningLabel,
    );
    if (warningLabel.isNotEmpty) return warningLabel;
    if (!hasData) return 'No receipt-read review data';
    if (!needsReview) return 'Receipt read looks good';
    return 'Receipt read needs review';
  }

  String get commandCenterPrimaryAction {
    final safeInstruction = _receiptOcrCommandCenterTextOrEmpty(
      primaryWarningTargetInstruction,
    );
    if (safeInstruction.isNotEmpty) {
      return safeInstruction;
    }
    final safeRecoverySummary = _receiptOcrCommandCenterTextOrEmpty(
      recoverySummary,
    );
    if (safeRecoverySummary.isNotEmpty) {
      return safeRecoverySummary;
    }
    final kindAction = _receiptOcrActionForWarningKind(primaryWarningKind);
    if (kindAction.isNotEmpty) {
      return kindAction;
    }
    if (!hasData) return 'No receipt-reading action is available yet.';
    if (!needsReview) return 'No receipt-reading action needed.';
    return 'Review the receipt proof and filled receipt fields before saving.';
  }

  Map<String, Object?> get commandCenterSummary {
    return {
      'severity': severity,
      'source': source,
      'needsReview': needsReview,
      'warningCount': warningCount,
      'blockingWarningCount': blockingWarningCount,
      'partialWarningCount': partialWarningCount,
      'reviewWarningCount': reviewWarningCount,
      'attachmentsRead': attachmentsRead,
      'attachmentsSkipped': attachmentsSkipped,
      'parserLineCount': parserLineCount,
      'primaryWarningKind': primaryWarningKind,
      'recoveryAction': _receiptOcrCommandCenterTokenOrEmpty(recoveryAction),
      'recoveryTarget': _receiptOcrCommandCenterTokenOrEmpty(recoveryTarget),
      'primaryIssue': commandCenterPrimaryIssue,
      'primaryAction': commandCenterPrimaryAction,
      'privacyScope': 'summary_only_no_receipt_content',
    };
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
      'primaryWarningKind': primaryWarningKind,
      'primaryWarningLabel': primaryWarningLabel,
      'primaryWarningTargetLabel': primaryWarningTargetLabel,
      'primaryWarningTargetInstruction': primaryWarningTargetInstruction,
      'recoveryAction': recoveryAction,
      'recoveryTarget': recoveryTarget,
      'recoverySummary': recoverySummary,
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
