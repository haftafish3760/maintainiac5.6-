part of 'expense_receipt_entry_screen.dart';

class _ReceiptOcrReviewRow extends StatelessWidget {
  const _ReceiptOcrReviewRow({
    required this.diagnostics,
    required this.parseDiagnostics,
    required this.warnings,
    required this.actionCallbacks,
  });

  final ReceiptOcrDiagnostics diagnostics;
  final ExpenseReceiptParseDiagnostics? parseDiagnostics;
  final List<ReceiptOcrWarning> warnings;
  final Map<String, VoidCallback> actionCallbacks;

  @override
  Widget build(BuildContext context) {
    final color = switch (diagnostics.severity) {
      ReceiptOcrReviewSeverity.good => const Color(0xFF8EF6A4),
      ReceiptOcrReviewSeverity.review => const Color(0xFFFFD166),
      ReceiptOcrReviewSeverity.partial => const Color(0xFFFFD166),
      ReceiptOcrReviewSeverity.blocked => const Color(0xFFFF8FA3),
    };
    final prioritizedWarnings = warnings.toList(growable: false)
      ..sort(ReceiptOcrWarning.compareByPriority);
    final warning = prioritizedWarnings.isEmpty
        ? null
        : prioritizedWarnings.first;
    final secondaryTargets = prioritizedWarnings
        .skip(1)
        .take(2)
        .map((warning) => warning.reviewTargetLabel)
        .toList(growable: false);
    final hiddenWarningCount = prioritizedWarnings.length > 1
        ? prioritizedWarnings.length - 1
        : 0;
    final recoverySummary = _ocrRecoverySummaryFor(warning, diagnostics.source);
    final readinessSummary = _ocrParserReadinessSummaryFor(diagnostics);
    final structureSummary = _ocrStructureSummaryFor(diagnostics);
    final acceptedPhotoCue = _ocrAcceptedPhotoCueFor(diagnostics);
    final footprintCue = _receiptFootprintReviewCueFor(
      context,
      parseDiagnostics,
    );
    final parserOverlapEvidenceSummary =
        parseDiagnostics?.parserDuplicateOverlapEvidenceSummaryLabel ?? '';
    final actionLabels = _orderedUniqueActionLabels([
      ..._parserMathActionLabelsFor(parseDiagnostics),
      ..._parserFuelActionLabelsFor(parseDiagnostics),
      ..._parserCategoryActionLabelsFor(parseDiagnostics),
      ..._parserDuplicateOverlapActionLabelsFor(parseDiagnostics),
      ..._receiptFootprintActionLabelsFor(context, parseDiagnostics),
      ..._ocrParserTaskActionLabelsFor(diagnostics),
      ..._ocrParserReadinessActionLabelsFor(diagnostics),
      ..._ocrStructureActionLabelsFor(diagnostics),
      ..._ocrAcceptedPhotoActionLabelsFor(diagnostics),
    ]);
    final detail = [
      diagnostics.readSummaryLabel,
      if (diagnostics.hasText) diagnostics.textSummaryLabel,
      if (diagnostics.parserSignalSummaryLabel.isNotEmpty)
        diagnostics.parserSignalSummaryLabel,
      if (parserOverlapEvidenceSummary.isNotEmpty)
        'Overlap evidence: $parserOverlapEvidenceSummary.',
      if (readinessSummary.isNotEmpty) readinessSummary,
      if (structureSummary.isNotEmpty) structureSummary,
      if (acceptedPhotoCue.isNotEmpty) acceptedPhotoCue,
      if (footprintCue.isNotEmpty) footprintCue,
      if (warning != null) '${warning.reviewTargetLabel}.',
      if (warning != null) warning.reviewMessage,
      if (recoverySummary.isNotEmpty) 'Next step: $recoverySummary',
      if (warning != null && warning.reviewInstruction.isNotEmpty)
        warning.reviewInstruction,
      if (warning != null) warning.reviewTargetInstruction,
      if (secondaryTargets.isNotEmpty)
        'Next checks: ${secondaryTargets.join('; ')}.',
      if (hiddenWarningCount > 0)
        '$hiddenWarningCount more OCR ${hiddenWarningCount == 1 ? 'warning needs' : 'warnings need'} review.',
    ].where((part) => part.trim().isNotEmpty).join(' ');
    return _ReceiptParseReviewBox(
      icon: switch (diagnostics.severity) {
        ReceiptOcrReviewSeverity.good => Icons.document_scanner_rounded,
        ReceiptOcrReviewSeverity.review => Icons.manage_search_rounded,
        ReceiptOcrReviewSeverity.partial => Icons.warning_amber_rounded,
        ReceiptOcrReviewSeverity.blocked => Icons.error_outline_rounded,
      },
      color: color,
      title: warnings.isEmpty
          ? 'OCR read: ${diagnostics.severity.label}'
          : 'OCR read: ${diagnostics.severity.label} - ${warnings.length} ${warnings.length == 1 ? 'warning' : 'warnings'}',
      detail: detail,
      actionLabels: actionLabels,
      actionCallbacks: actionCallbacks,
    );
  }
}
