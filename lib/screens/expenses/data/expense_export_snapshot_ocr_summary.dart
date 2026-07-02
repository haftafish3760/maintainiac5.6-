part of 'expense_export_models.dart';

extension ExpenseExportSnapshotOcrSummary on ExpenseExportSnapshot {
  int get receiptsWithOcrReview {
    return receipts.where((receipt) => receipt.ocrReview.hasData).length;
  }

  int get receiptsNeedingOcrReview {
    return receipts.where((receipt) => receipt.ocrReview.needsReview).length;
  }

  int get ocrReadsSaved {
    return receipts.where((receipt) => receipt.ocrReview.hasData).length;
  }

  int get ocrCleanReadCount {
    return receipts.where((receipt) {
      final review = receipt.ocrReview;
      return review.hasData && !review.needsReview;
    }).length;
  }

  String get ocrReadStatus {
    if (receiptCount == 0) return 'No receipts exported';
    if (ocrReadsSaved == 0) return 'No receipt reads exported';
    if (receiptsNeedingOcrReview > 0) {
      return '$receiptsNeedingOcrReview need review';
    }
    return 'All reads saved';
  }

  String get ocrReadSummary {
    if (receiptCount == 0) return 'No receipts in this export.';
    if (ocrReadsSaved == 0) {
      return '$receiptCount ${receiptCount == 1 ? 'receipt' : 'receipts'} exported without receipt assistance.';
    }
    final parts = [
      '$ocrReadsSaved ${ocrReadsSaved == 1 ? 'read' : 'reads'} saved',
      if (receiptsNeedingOcrReview > 0) '$receiptsNeedingOcrReview need review',
      if (ocrCleanReadCount > 0) '$ocrCleanReadCount saved clean',
      if (ocrTopCheck.isNotEmpty) 'Top check: $ocrTopCheck',
    ];
    return parts.join(' | ');
  }

  String get ocrTopCheck {
    final topKind = _topCountKey(ocrPrimaryWarningKindCounts);
    if (topKind.isEmpty) return '';
    for (final receipt in receipts) {
      if (receipt.ocrReview.primaryWarningKind == topKind) {
        return receipt.ocrReview.commandCenterPrimaryIssue;
      }
    }
    return '';
  }

  int get totalOcrWarningCount {
    return receipts.fold(
      0,
      (sum, receipt) => sum + receipt.ocrReview.warningCount,
    );
  }

  int get totalOcrBlockingWarningCount {
    return receipts.fold(
      0,
      (sum, receipt) => sum + receipt.ocrReview.blockingWarningCount,
    );
  }

  int get totalOcrPartialWarningCount {
    return receipts.fold(
      0,
      (sum, receipt) => sum + receipt.ocrReview.partialWarningCount,
    );
  }

  int get totalOcrReviewWarningCount {
    return receipts.fold(
      0,
      (sum, receipt) => sum + receipt.ocrReview.reviewWarningCount,
    );
  }

  Map<String, int> get ocrPrimaryWarningKindCounts {
    final counts = <String, int>{};
    for (final receipt in receipts) {
      final kind = receipt.ocrReview.primaryWarningKind.trim();
      if (kind.isEmpty) continue;
      counts.update(kind, (count) => count + 1, ifAbsent: () => 1);
    }
    return Map.unmodifiable(counts);
  }

  Map<String, int> get ocrSourceCounts {
    final counts = <String, int>{};
    for (final receipt in receipts) {
      final source = receipt.ocrReview.source.trim();
      if (source.isEmpty) continue;
      counts.update(source, (count) => count + 1, ifAbsent: () => 1);
    }
    return Map.unmodifiable(counts);
  }

  String get ocrTopSource {
    return _topCountKey(ocrSourceCounts);
  }

  Map<String, int> get ocrRecoveryActionCounts {
    final counts = <String, int>{};
    for (final receipt in receipts) {
      final action =
          '${receipt.ocrReview.commandCenterSummary['recoveryAction']}'.trim();
      if (action.isEmpty) continue;
      counts.update(action, (count) => count + 1, ifAbsent: () => 1);
    }
    return Map.unmodifiable(counts);
  }

  Map<String, int> get ocrRecoveryTargetCounts {
    final counts = <String, int>{};
    for (final receipt in receipts) {
      final target =
          '${receipt.ocrReview.commandCenterSummary['recoveryTarget']}'.trim();
      if (target.isEmpty) continue;
      counts.update(target, (count) => count + 1, ifAbsent: () => 1);
    }
    return Map.unmodifiable(counts);
  }

  String get ocrTopRecoveryAction {
    return _topCountKey(ocrRecoveryActionCounts);
  }

  String get ocrTopRecoveryTarget {
    return _topCountKey(ocrRecoveryTargetCounts);
  }

  String get ocrTopPrimaryIssue {
    final topKind = _topCountKey(ocrPrimaryWarningKindCounts);
    if (topKind.isEmpty) return '';
    for (final receipt in receipts) {
      if (receipt.ocrReview.primaryWarningKind == topKind) {
        return receipt.ocrReview.commandCenterPrimaryIssue;
      }
    }
    return topKind;
  }

  String get ocrTopPrimaryAction {
    final topKind = _topCountKey(ocrPrimaryWarningKindCounts);
    if (topKind.isEmpty) return '';
    for (final receipt in receipts) {
      if (receipt.ocrReview.primaryWarningKind == topKind) {
        return receipt.ocrReview.commandCenterPrimaryAction;
      }
    }
    return '';
  }
}
