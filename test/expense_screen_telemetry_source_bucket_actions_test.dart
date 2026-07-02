import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_screen_telemetry.dart';

import 'helpers/expense_screen_telemetry_harness.dart';
import 'helpers/expense_telemetry_source_bucket_expectations.dart';

void main() {
  installExpenseTelemetryHiveLifecycle('expense_screen_telemetry_test_');

  test('keeps OCR failure source buckets allowlisted', () async {
    final store = await ExpenseTelemetryStore.create();
    final context = expenseTelemetryContextFixture();

    final evidenceCases = [
      'warning_blurry_source_photo_total_3_24',
      'warning_pdf_source_document_total_4_25',
      'warning_text_source_pasted_text_total_5_26',
      'warning_mixed_source_combined_total_6_27',
      'warning_missing_source_missing_total_7_28',
      'warning_private_source_lowes_total_8_29',
      'warning_private_source_private_store_total_9_30',
      'warning_private_source_users_notes_total_10_31',
    ];
    for (var index = 0; index < evidenceCases.length; index += 1) {
      final evidence = evidenceCases[index];
      await store.enqueue(
        ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.ocrFailed,
          context: context,
          failureKind: 'receipt_photo_read_failed_$index',
          diagnostic: ExpenseFailureDiagnostic(
            workflowStep: ExpenseWorkflowStep.receiptOcr,
            failedAt: 'during_ocr_read_$index',
            confirmedCause: 'receipt_photo_read_failed_$index',
            causeStatus: ExpenseFailureCauseStatus.confirmed,
            evidence: evidence,
          ),
        ),
      );
    }

    final snapshot = store.buildHealthSnapshot(
      nowUtc: DateTime.utc(2026, 6, 28, 14),
    );

    expect(snapshot.ocrFailureSourceCounts, {
      'photo': 1,
      'pdf': 1,
      'importedtext': 1,
      'mixed': 1,
      'none': 1,
      'unknown': 3,
    });
    expect(
      snapshot.ocrFailureSourceCounts.keys.toSet(),
      expectedExpenseTelemetryOcrFailureSourceBuckets,
    );
    expect(snapshot.ocrFailureSourceCounts, isNot(contains('lowes')));
    expect(snapshot.ocrFailureSourceCounts, isNot(contains('private_store')));
    expect(snapshot.ocrFailureSourceCounts, isNot(contains('users_notes')));
    expect(
      snapshot.toCommandCenterMap()['topOcrFailureSourceAction'],
      contains('source tagging'),
    );
  });

  test('gives every OCR failure source bucket a clear action', () async {
    const cases = {
      'photo': (
        evidence: 'warning_blurry_source_photo_total_3_24',
        actionHint: 'camera focus',
      ),
      'pdf': (
        evidence: 'warning_pdf_source_pdf_total_4_25',
        actionHint: 'PDF safety checks',
      ),
      'importedtext': (
        evidence: 'warning_text_source_imported_text_total_5_26',
        actionHint: 'pasted/imported receipt text cleanup',
      ),
      'mixed': (
        evidence: 'warning_mixed_source_mixed_total_6_27',
        actionHint: 'mixed receipt sources',
      ),
      'none': (
        evidence: 'warning_missing_source_none_total_7_28',
        actionHint: 'without a usable receipt photo',
      ),
      'unknown': (
        evidence: 'warning_private_source_lowes_total_8_29',
        actionHint: 'source tagging',
      ),
    };
    expect(cases.keys.toSet(), expectedExpenseTelemetryOcrFailureSourceBuckets);

    for (final entry in cases.entries) {
      final snapshot = ExpenseTelemetryHealthSnapshot.fromRecords([
        ExpenseTelemetryRecord(
          id: 'evt-source-action-${entry.key}',
          queuedAtUtc: DateTime.utc(2026, 6, 28, 17),
          payload: Map.unmodifiable({
            'event': ExpenseTelemetryEventType.ocrFailed.name,
            'workflowStep': ExpenseWorkflowStep.receiptOcr.name,
            'failedAt': 'during_ocr_read',
            'confirmedCause': 'receipt_photo_read_failed',
            'causeStatus': ExpenseFailureCauseStatus.confirmed.name,
            'evidence': entry.value.evidence,
            'platform': 'android',
            'deviceTier': 'high',
            'appVersion': '5.6.0',
          }),
        ),
      ], generatedAtUtc: DateTime.utc(2026, 6, 28, 17, 1));
      final map = snapshot.toCommandCenterMap();

      expect(map['topOcrFailureSource'], entry.key);
      expect(
        map['topOcrFailureSourceAction'],
        contains(entry.value.actionHint),
      );
      expect(
        map['topOcrFailureSourceAction'].toString().toLowerCase(),
        isNot(contains('lowes')),
      );
    }
  });

  test('covers every OCR failure cause with specific Command 1 action', () {
    const ocrCauses = <String, String>{
      'pdf_safety_blocked': 'safe copy',
      'pdf_too_large': 'smaller file',
      'pdf_unreadable': 'file validity',
      'pdf_read_failed': 'PDF rendering',
      'ocr_plugin_unavailable': 'OCR plugin',
      'receipt_photo_read_failed': 'image decoding',
      'receipt_photo_quality_needs_review': 'better focus',
      'missing_receipt_attachment': 'attach',
      'receipt_source_skipped': 'skipped attachment',
      'possible_missing_receipt_section': 'missing middle receipt section',
      'receipt_photo_overlap': 'stitch overlap area',
      'duplicate_receipt_text': 'duplicate suppression',
      'no_readable_text': 'blank',
      'ocr_unknown_failure': 'warning diagnostics',
    };

    for (final entry in ocrCauses.entries) {
      final action = ExpenseTelemetryHealthSnapshot.fromRecords([
        ExpenseTelemetryRecord(
          id: 'evt_${entry.key}',
          queuedAtUtc: DateTime.utc(2026, 6, 24, 12),
          payload: ExpenseTelemetryPolicy.sanitize(
            ExpenseTelemetryEvent(
              type: ExpenseTelemetryEventType.ocrFailed,
              context: expenseTelemetryContextFixture(),
              failureKind: entry.key,
              diagnostic: ExpenseFailureDiagnostic(
                workflowStep: ExpenseWorkflowStep.receiptOcr,
                failedAt: 'during_receipt_ocr',
                confirmedCause: entry.key,
                causeStatus: ExpenseFailureCauseStatus.confirmed,
                evidence: 'warning_${entry.key}',
              ),
            ),
          ),
        ),
      ]).failureBreakdowns.single.recommendedAction;

      expect(
        action,
        contains(entry.value),
        reason: '${entry.key} should have a specific Command 1 action.',
      );
      expect(
        action,
        isNot(contains('Review receipt image quality, OCR source limits')),
        reason: '${entry.key} should not fall back to generic OCR guidance.',
      );
    }
  });

  test('covers action summaries across major failure workflows', () {
    const cases = [
      (
        id: 'ocr',
        event: 'ocrFailed',
        workflowStep: 'receiptOcr',
        confirmedCause: 'receipt_photo_read_failed',
        causeStatus: 'confirmed',
        evidence: 'source_photo_warning',
        missingEvidence: 'none',
        expectedWorkflow: 'Receipt OCR failed',
        expectedContext: 'photo capture or image readability',
        expectedNextStep: 'image decoding',
      ),
      (
        id: 'parser',
        event: 'parserFailed',
        workflowStep: 'receiptParser',
        confirmedCause: 'receipt_parser_no_usable_fields',
        causeStatus: 'confirmed',
        evidence: 'source_photo_parser_empty',
        missingEvidence: 'none',
        expectedWorkflow: 'Receipt parser failed',
        expectedContext: 'the failed workflow',
        expectedNextStep: 'parser rules',
      ),
      (
        id: 'attachment',
        event: 'imageAttachFailure',
        workflowStep: 'receiptAttachment',
        confirmedCause: 'receipt_attachment_copy_failed',
        causeStatus: 'confirmed',
        evidence: 'attachment_temp_file_missing',
        missingEvidence: 'none',
        expectedWorkflow: 'Receipt attachment failed',
        expectedContext: 'the failed workflow',
        expectedNextStep: 'receipt proof capture',
      ),
      (
        id: 'save',
        event: 'saveFailure',
        workflowStep: 'saveExpense',
        confirmedCause: 'ledger_save_failed',
        causeStatus: 'confirmed',
        evidence: 'ledger_save_exception',
        missingEvidence: 'none',
        expectedWorkflow: 'Save expense failed',
        expectedContext: 'the failed workflow',
        expectedNextStep: 'Hive state',
      ),
      (
        id: 'sync',
        event: 'syncFailed',
        workflowStep: 'sync',
        confirmedCause: 'hosted_sync_queue_failed',
        causeStatus: 'confirmed',
        evidence: 'sync_retry_limit',
        missingEvidence: 'none',
        expectedWorkflow: 'Sync failed',
        expectedContext: 'the failed workflow',
        expectedNextStep: 'hosted sync handoff',
      ),
      (
        id: 'cloud',
        event: 'cloudBackupFailure',
        workflowStep: 'cloudBackup',
        confirmedCause: 'cloud_backup_upload_failed',
        causeStatus: 'confirmed',
        evidence: 'cloud_upload_retry_limit',
        missingEvidence: 'none',
        expectedWorkflow: 'Cloud backup failed',
        expectedContext: 'the failed workflow',
        expectedNextStep: 'local queue state',
      ),
      (
        id: 'export',
        event: 'exportFailed',
        workflowStep: 'export',
        confirmedCause: 'expense_export_file_write_failed',
        causeStatus: 'confirmed',
        evidence: 'export_file_write_failed',
        missingEvidence: 'none',
        expectedWorkflow: 'Export failed',
        expectedContext: 'the failed workflow',
        expectedNextStep: 'file creation',
      ),
      (
        id: 'line_review',
        event: 'validationError',
        workflowStep: 'lineReview',
        confirmedCause: 'receipt_lines_need_review',
        causeStatus: 'confirmed',
        evidence: 'line_review_required',
        missingEvidence: 'none',
        expectedWorkflow: 'Line review failed',
        expectedContext: 'the failed workflow',
        expectedNextStep: 'low-confidence line classification',
      ),
      (
        id: 'unconfirmed',
        event: 'saveFailure',
        workflowStep: 'saveExpense',
        confirmedCause: 'cause_not_confirmed_ledger_save_failed',
        causeStatus: 'notConfirmed',
        evidence: 'ledger_save_exception',
        missingEvidence: 'exception_type_and_hive_box_state',
        expectedWorkflow: 'Save expense failed',
        expectedContext: 'cause is not confirmed yet',
        expectedNextStep: 'exception type and hive box state',
      ),
    ];

    final snapshot = ExpenseTelemetryHealthSnapshot.fromRecords([
      for (final entry in cases)
        ExpenseTelemetryRecord(
          id: 'evt_action_summary_${entry.id}',
          queuedAtUtc: DateTime.utc(2026, 6, 28, 23),
          payload: Map.unmodifiable({
            'event': entry.event,
            'workflowStep': entry.workflowStep,
            'failedAt': 'during_${entry.id}',
            'confirmedCause': entry.confirmedCause,
            'causeStatus': entry.causeStatus,
            'evidence': entry.evidence,
            'missingEvidence': entry.missingEvidence,
            'retryCount': 1,
            'platform': 'android',
            'deviceTier': 'high',
            'appVersion': '5.6.0',
          }),
        ),
    ], generatedAtUtc: DateTime.utc(2026, 6, 28, 23, 5));

    expect(snapshot.failureBreakdowns, hasLength(cases.length));
    for (final entry in cases) {
      final failure = snapshot.failureBreakdowns.singleWhere(
        (failure) => failure.confirmedCause == entry.confirmedCause,
      );
      expect(failure.actionSummary, contains(entry.expectedWorkflow));
      expect(failure.actionSummary, contains(entry.expectedContext));
      expect(failure.actionSummary, contains(entry.expectedNextStep));
      expect(failure.actionSummary, isNot(contains('_')));
      expect(failure.actionSummary.length, lessThanOrEqualTo(180));
    }
  });

}
