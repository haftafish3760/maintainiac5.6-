part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptSaveReadinessHelpers
    on _ExpenseReceiptEntryScreenState {
  List<_ReceiptSaveReadinessIssue> _receiptSaveReadinessIssues() {
    final issues = <_ReceiptSaveReadinessIssue>[];
    final unreviewedCount = _unreviewedParsedLineCount;
    if (unreviewedCount > 0) {
      issues.add(
        _ReceiptSaveReadinessIssue(
          kind: 'unreviewed_app_filled_lines',
          title: 'App-filled lines still need review',
          detail: unreviewedCount == 1
              ? 'One receipt line was filled by the app and has not been confirmed or corrected yet.'
              : '$unreviewedCount receipt lines were filled by the app and have not been confirmed or corrected yet.',
        ),
      );
    }

    final splitPercentMissingCount = _splitLinesMissingBusinessPercentCount;
    if (splitPercentMissingCount > 0) {
      issues.add(
        _ReceiptSaveReadinessIssue(
          kind: 'mixed_receipt_split_allocation_missing',
          title: 'Split receipt allocation is required',
          detail: splitPercentMissingCount == 1
              ? 'One split receipt line still needs a confirmed percentage, dollar, or quantity allocation.'
              : '$splitPercentMissingCount split receipt lines still need confirmed allocations.',
        ),
      );
    }

    final ocrDiagnostics = _lastOcrDiagnostics;
    if (ocrDiagnostics != null) {
      if (!ocrDiagnostics.hasText) {
        issues.add(
          const _ReceiptSaveReadinessIssue(
            kind: 'receipt_ocr_no_readable_text',
            title: 'No readable receipt text was found',
            detail:
                'The receipt proof can still be saved, but the app could not fill the receipt from the photo.',
          ),
        );
      } else if (ocrDiagnostics.hasBlockingWarnings) {
        issues.add(
          _ReceiptSaveReadinessIssue(
            kind: 'receipt_ocr_blocking_warnings',
            title: 'Receipt assistance needs attention',
            detail: _primaryOcrWarningMessage(
              fallback:
                  'The receipt was attached, but at least one source could not be read safely.',
            ),
          ),
        );
      } else if (ocrDiagnostics.hasPartialWarnings) {
        issues.add(
          _ReceiptSaveReadinessIssue(
            kind: 'receipt_ocr_partial_read',
            title: 'Only part of the receipt was read',
            detail: _primaryOcrWarningMessage(
              fallback:
                  'Some receipt proof was saved without being used for app-assisted filling.',
            ),
          ),
        );
      } else if (ocrDiagnostics.hasReviewWarnings) {
        issues.add(
          _ReceiptSaveReadinessIssue(
            kind: 'receipt_ocr_review_warnings',
            title: 'Receipt assistance should be checked',
            detail: _primaryOcrWarningMessage(
              fallback:
                  'The app found receipt text, but it flagged something worth reviewing before save.',
            ),
          ),
        );
      }
    }

    final subtotalIssue = _receiptSubtotalReadinessIssue();
    if (subtotalIssue != null) issues.add(subtotalIssue);

    return issues;
  }

  int get _splitLinesMissingBusinessPercentCount {
    return _lines
        .where(
          (line) =>
              line.use == _ExpenseLineUse.split &&
              ((line.splitAllocation == null &&
                      (line.businessPercent == null ||
                          !line.businessPercent!.isFinite ||
                          line.businessPercent! < 0 ||
                          line.businessPercent! > 1)) ||
                  !line.hasValidSplitAllocation),
        )
        .length;
  }

  _ReceiptSaveReadinessIssue? _receiptSubtotalReadinessIssue() {
    final enteredSubtotal = _enteredReceiptSubtotal;
    if (enteredSubtotal == null || _lines.isEmpty) return null;
    final delta = enteredSubtotal - _lineSubtotal;
    if (delta.abs() < .02) return null;
    return _ReceiptSaveReadinessIssue(
      kind: 'receipt_subtotal_line_mismatch',
      title: 'Receipt subtotal does not match the lines',
      detail:
          'Line subtotal is ${_money(_lineSubtotal)}, but the receipt subtotal is ${_money(enteredSubtotal)}. Check for missing items, discounts, fees, or returns.',
    );
  }

  String _primaryOcrWarningMessage({required String fallback}) {
    if (_lastOcrWarnings.isEmpty) return fallback;
    final prioritizedWarnings = _lastOcrWarnings.toList(growable: false)
      ..sort(ReceiptOcrWarning.compareByPriority);
    final warning = prioritizedWarnings.first;
    final extraWarningCount = prioritizedWarnings.length - 1;
    final parts = <String>[
      warning.reviewMessage,
      if (warning.reviewInstruction.isNotEmpty) warning.reviewInstruction,
      '${warning.reviewTargetLabel}.',
      warning.reviewTargetInstruction,
      if (extraWarningCount > 0)
        '$extraWarningCount more receipt-reading ${extraWarningCount == 1 ? 'warning also needs' : 'warnings also need'} review.',
    ];
    return parts.where((part) => part.trim().isNotEmpty).join(' ');
  }
}
