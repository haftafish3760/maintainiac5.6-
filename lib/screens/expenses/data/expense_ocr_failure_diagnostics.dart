import '../../../shared/receipts/receipt_processing_contract.dart';
import '../../../shared/widgets/receipt_capture/receipt_capture.dart';
import 'expense_screen_telemetry.dart';

class ExpenseOcrFailureDiagnostics {
  const ExpenseOcrFailureDiagnostics._();

  static ExpenseFailureDiagnostic fromOcrResult(ReceiptOcrResult result) {
    final selected = result.prioritizedWarnings.isEmpty
        ? null
        : result.prioritizedWarnings.first;
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
    final recoveryAction = _recoveryActionFor(selected?.kind, result.source);
    final recoveryTarget = _recoveryTargetFor(selected?.kind, result.source);
    final sourceFirst = _sourceFirstEvidenceFor(diagnostics);
    return [
      'warning_$warningKind',
      'severity_${diagnostics.severity.name}',
      'source_${result.source.name}',
      'sourceFirst_$sourceFirst',
      'read_${diagnostics.attachmentsRead}',
      'skipped_${diagnostics.attachmentsSkipped}',
      'recovery_$recoveryAction',
      'target_$recoveryTarget',
    ].join('_');
  }

  static String _sourceFirstEvidenceFor(ReceiptOcrDiagnostics diagnostics) {
    final contract = diagnostics.ocrSourceHandoffContract;
    final rawDecision = contract['sourceFirstDecisionStatus'];
    final rawOutcome = contract['sourceFirstOutcomeStatus'];
    final decision = rawDecision is String ? rawDecision.trim() : '';
    if (decision.isNotEmpty) return decision;
    final outcome = rawOutcome is String ? rawOutcome.trim() : '';
    if (outcome.isNotEmpty) return outcome;
    return diagnostics.ocrSourceHandoffStatus;
  }

  static String _recoveryActionFor(
    ReceiptOcrWarningKind? kind,
    ReceiptProcessingSource source,
  ) {
    return switch (kind) {
      ReceiptOcrWarningKind.noSource => 'attach_proof',
      ReceiptOcrWarningKind.noReadableText => _sourceRecoveryAction(source),
      ReceiptOcrWarningKind.sourceSkipped => 'review_saved_proof',
      ReceiptOcrWarningKind.duplicateText => 'review_overlap',
      ReceiptOcrWarningKind.probableOverlap => 'review_overlap',
      ReceiptOcrWarningKind.sectionGap => 'add_missing_section',
      ReceiptOcrWarningKind.pdfSafety => 'attach_safe_pdf',
      ReceiptOcrWarningKind.pdfTooLarge => 'use_smaller_pdf_or_photos',
      ReceiptOcrWarningKind.pdfUnreadable => 'replace_pdf_or_add_photo',
      ReceiptOcrWarningKind.pluginUnavailable => 'manual_entry',
      ReceiptOcrWarningKind.photoQuality => 'retake_or_review_photo',
      ReceiptOcrWarningKind.photoReadFailure => 'retake_photo',
      ReceiptOcrWarningKind.pdfReadFailure => 'scan_receipt_with_photos',
      ReceiptOcrWarningKind.unknown => 'review_receipt_manually',
      null => _sourceRecoveryAction(source),
    };
  }

  static String _sourceRecoveryAction(ReceiptProcessingSource source) {
    return switch (source) {
      ReceiptProcessingSource.photo => 'retake_photo_or_add_section',
      ReceiptProcessingSource.pdf => 'scan_receipt_with_photos',
      ReceiptProcessingSource.importedText => 'paste_cleaner_text',
      ReceiptProcessingSource.mixed => 'choose_clearest_source',
      ReceiptProcessingSource.none => 'attach_proof',
    };
  }

  static String _recoveryTargetFor(
    ReceiptOcrWarningKind? kind,
    ReceiptProcessingSource source,
  ) {
    return switch (kind) {
      ReceiptOcrWarningKind.noSource => 'receipt_attachment',
      ReceiptOcrWarningKind.duplicateText ||
      ReceiptOcrWarningKind.probableOverlap => 'receipt_overlap',
      ReceiptOcrWarningKind.sectionGap => 'receipt_sections',
      ReceiptOcrWarningKind.pdfSafety ||
      ReceiptOcrWarningKind.pdfTooLarge ||
      ReceiptOcrWarningKind.pdfUnreadable ||
      ReceiptOcrWarningKind.pdfReadFailure => 'receipt_pdf',
      ReceiptOcrWarningKind.pluginUnavailable => 'manual_receipt_entry',
      ReceiptOcrWarningKind.photoQuality ||
      ReceiptOcrWarningKind.photoReadFailure => 'receipt_photo',
      ReceiptOcrWarningKind.sourceSkipped ||
      ReceiptOcrWarningKind.noReadableText ||
      ReceiptOcrWarningKind.unknown ||
      null => _sourceRecoveryTarget(source),
    };
  }

  static String _sourceRecoveryTarget(ReceiptProcessingSource source) {
    return switch (source) {
      ReceiptProcessingSource.photo => 'receipt_photo',
      ReceiptProcessingSource.pdf => 'receipt_pdf',
      ReceiptProcessingSource.importedText => 'receipt_text',
      ReceiptProcessingSource.mixed => 'receipt_sources',
      ReceiptProcessingSource.none => 'receipt_attachment',
    };
  }
}
