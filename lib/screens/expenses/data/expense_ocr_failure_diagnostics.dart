import '../../../shared/widgets/receipt_capture/receipt_capture.dart';
import 'expense_screen_telemetry.dart';

class ExpenseOcrFailureDiagnostics {
  const ExpenseOcrFailureDiagnostics._();

  static ExpenseFailureDiagnostic fromOcrResult(ReceiptOcrResult result) {
    final selected = _selectedFailureWarning(result.structuredWarnings);
    final cause = _confirmedCauseFor(selected?.kind);
    return ExpenseFailureDiagnostic(
      workflowStep: ExpenseWorkflowStep.receiptOcr,
      failedAt: _failedAtFor(selected?.kind),
      confirmedCause: cause,
      causeStatus: ExpenseFailureCauseStatus.confirmed,
      evidence: _evidenceFor(result, selected),
      missingEvidence: 'none',
    );
  }

  static String failureKindFor(ReceiptOcrResult result) {
    return fromOcrResult(result).confirmedCause;
  }

  static ReceiptOcrWarning? _selectedFailureWarning(
    List<ReceiptOcrWarning> warnings,
  ) {
    const priority = <ReceiptOcrWarningKind>[
      ReceiptOcrWarningKind.pdfSafety,
      ReceiptOcrWarningKind.pdfTooLarge,
      ReceiptOcrWarningKind.pdfUnreadable,
      ReceiptOcrWarningKind.pdfReadFailure,
      ReceiptOcrWarningKind.pluginUnavailable,
      ReceiptOcrWarningKind.photoReadFailure,
      ReceiptOcrWarningKind.photoQuality,
      ReceiptOcrWarningKind.noSource,
      ReceiptOcrWarningKind.noReadableText,
      ReceiptOcrWarningKind.sourceSkipped,
      ReceiptOcrWarningKind.sectionGap,
      ReceiptOcrWarningKind.probableOverlap,
      ReceiptOcrWarningKind.duplicateText,
      ReceiptOcrWarningKind.unknown,
    ];
    for (final kind in priority) {
      for (final warning in warnings) {
        if (warning.kind == kind) return warning;
      }
    }
    return warnings.isEmpty ? null : warnings.first;
  }

  static String _confirmedCauseFor(ReceiptOcrWarningKind? kind) {
    return switch (kind) {
      ReceiptOcrWarningKind.pdfSafety => 'pdf_safety_blocked',
      ReceiptOcrWarningKind.pdfTooLarge => 'pdf_too_large',
      ReceiptOcrWarningKind.pdfUnreadable => 'pdf_unreadable',
      ReceiptOcrWarningKind.pdfReadFailure => 'pdf_read_failed',
      ReceiptOcrWarningKind.pluginUnavailable => 'ocr_plugin_unavailable',
      ReceiptOcrWarningKind.photoReadFailure => 'receipt_photo_read_failed',
      ReceiptOcrWarningKind.photoQuality =>
        'receipt_photo_quality_needs_review',
      ReceiptOcrWarningKind.noSource => 'missing_receipt_attachment',
      ReceiptOcrWarningKind.sourceSkipped => 'receipt_source_skipped',
      ReceiptOcrWarningKind.sectionGap => 'possible_missing_receipt_section',
      ReceiptOcrWarningKind.probableOverlap => 'receipt_photo_overlap',
      ReceiptOcrWarningKind.duplicateText => 'duplicate_receipt_text',
      ReceiptOcrWarningKind.noReadableText || null => 'no_readable_text',
      ReceiptOcrWarningKind.unknown => 'ocr_unknown_failure',
    };
  }

  static String _failedAtFor(ReceiptOcrWarningKind? kind) {
    return switch (kind) {
      ReceiptOcrWarningKind.noSource ||
      ReceiptOcrWarningKind.sourceSkipped ||
      ReceiptOcrWarningKind.pluginUnavailable => 'before_local_ocr_read',
      ReceiptOcrWarningKind.pdfSafety ||
      ReceiptOcrWarningKind.pdfTooLarge ||
      ReceiptOcrWarningKind.pdfUnreadable ||
      ReceiptOcrWarningKind.pdfReadFailure => 'during_pdf_ocr_read',
      ReceiptOcrWarningKind.photoReadFailure ||
      ReceiptOcrWarningKind.photoQuality => 'during_photo_ocr_read',
      _ => 'after_attachment_read_before_parser',
    };
  }

  static String _evidenceFor(
    ReceiptOcrResult result,
    ReceiptOcrWarning? selected,
  ) {
    final diagnostics = result.diagnostics;
    final warningKind = selected?.kind.name ?? 'none';
    return [
      'warning_$warningKind',
      'severity_${diagnostics.severity.name}',
      'source_${result.source.name}',
      'read_${diagnostics.attachmentsRead}',
      'skipped_${diagnostics.attachmentsSkipped}',
    ].join('_');
  }
}
