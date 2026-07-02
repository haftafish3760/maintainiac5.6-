import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_screen_telemetry.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_documents.dart';

import 'helpers/expense_telemetry_redaction_guard_helpers.dart';

void main() {
  test(
    'keeps action summaries useful across Firestore failure cause matrix',
    () {
      const cases = [
        (
          id: 'ocr',
          event: 'ocrFailed',
          workflowStep: 'receiptOcr',
          confirmedCause: 'receipt_photo_read_failed',
          causeStatus: 'confirmed',
          evidence: 'source_photo_lowes_auth_998877_total_3_24',
          missingEvidence: 'receipt_18854480',
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
          evidence: 'source_photo_lowes_barcode_036000291452',
          missingEvidence: 'receipt_line_positions_18854480',
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
          evidence: 'attachment_temp_file_missing_lowes_receipt_18854480',
          missingEvidence: 'source_photo_lowes_auth_998877',
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
          evidence: 'ledger_save_exception_lowes_receipt_18854480',
          missingEvidence: 'hive_box_state_auth_998877',
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
          evidence: 'sync_retry_limit_lowes_receipt_18854480',
          missingEvidence: 'source_photo_lowes_total_3_24',
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
          evidence: 'cloud_upload_retry_limit_lowes_auth_998877',
          missingEvidence: 'source_photo_lowes_total_3_24',
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
          evidence: 'export_file_write_failed_lowes_receipt_18854480',
          missingEvidence: 'source_photo_lowes_auth_998877',
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
          evidence: 'line_review_required_lowes_receipt_18854480',
          missingEvidence: 'source_photo_lowes_auth_998877',
          expectedWorkflow: 'Line review failed',
          expectedContext: 'the failed workflow',
          expectedNextStep: 'low confidence line classification',
        ),
        (
          id: 'unconfirmed',
          event: 'saveFailure',
          workflowStep: 'saveExpense',
          confirmedCause: 'cause_not_confirmed_ledger_save_failed',
          causeStatus: 'notConfirmed',
          evidence: 'ledger_save_exception_lowes_total_3_24',
          missingEvidence: 'exception_type_and_hive_box_state_auth_998877',
          expectedWorkflow: 'Save expense failed',
          expectedContext: 'cause is not confirmed yet',
          expectedNextStep: 'exception type and hive box state',
        ),
      ];

      final snapshot = ExpenseTelemetryHealthSnapshot.fromRecords([
        for (var index = 0; index < cases.length; index += 1)
          ExpenseTelemetryRecord(
            id: 'evt-firestore-action-summary-${cases[index].id}',
            queuedAtUtc: DateTime.utc(2026, 6, 28, 23, index),
            payload: Map.unmodifiable({
              'event': cases[index].event,
              'workflowStep': cases[index].workflowStep,
              'failedAt': 'during_${cases[index].id}_lowes_total_3_24',
              'confirmedCause': cases[index].confirmedCause,
              'causeStatus': cases[index].causeStatus,
              'evidence': cases[index].evidence,
              'missingEvidence': cases[index].missingEvidence,
              'retryCount': index + 1,
              'platform': index.isEven ? 'android' : 'ios',
              'deviceTier': index.isEven ? 'high' : 'mid',
              'appVersion': '5.6.$index',
            }),
          ),
      ], generatedAtUtc: DateTime.utc(2026, 6, 28, 23, 10));
      final doc =
          MaintainiacFirestoreDocumentBuilder.expenseTelemetrySummaryDocument(
            orgId: 'ORG-1',
            summaryId: 'latest',
            snapshot: snapshot,
            maxFailureBreakdowns: 20,
            maxRecentFailureDetails: 20,
          );
      final breakdowns = (doc.data['failureBreakdowns'] as List)
          .cast<Map<String, Object?>>();
      final recent = (doc.data['recentFailureDetails'] as List)
          .cast<Map<String, Object?>>();
      final serialized = serializedTelemetryValues(doc.data).toLowerCase();

      expect(breakdowns, hasLength(cases.length));
      expect(recent, hasLength(cases.length));
      final breakdownSummaries = breakdowns
          .map((failure) => failure['actionSummary'].toString())
          .toList(growable: false);
      final recentSummaries = recent
          .map((failure) => failure['actionSummary'].toString())
          .toList(growable: false);
      final allSummaries = [
        ...breakdownSummaries,
        ...recentSummaries,
      ].join(' ');
      for (final entry in cases) {
        final matchingBreakdownSummaries = breakdownSummaries.where(
          (summary) =>
              summary.contains(entry.expectedWorkflow) &&
              summary.contains(entry.expectedContext) &&
              summary.contains(entry.expectedNextStep),
        );
        final matchingRecentSummaries = recentSummaries.where(
          (summary) =>
              summary.contains(entry.expectedWorkflow) &&
              summary.contains(entry.expectedContext) &&
              summary.contains(entry.expectedNextStep),
        );
        expect(
          matchingBreakdownSummaries,
          isNotEmpty,
          reason: '${entry.id} breakdown missing from $breakdownSummaries',
        );
        expect(
          matchingRecentSummaries,
          isNotEmpty,
          reason: '${entry.id} recent missing from $recentSummaries',
        );
        for (final summary in [
          ...matchingBreakdownSummaries,
          ...matchingRecentSummaries,
        ]) {
          expect(summary, contains(entry.expectedWorkflow));
          expect(summary, contains(entry.expectedContext));
          expect(summary, contains(entry.expectedNextStep));
          expect(summary, contains('failed'));
          expect(summary, isNot(contains('_')));
          expect(summary.length, lessThanOrEqualTo(180));
        }
      }
      for (final rawPrivateHint in const [
        'lowes',
        '3_24',
        '998877',
        '18854480',
        '036000291452',
        'receipt_photo_read_failed_lowes',
        'cause_not_confirmed_lowes',
      ]) {
        expect(serialized, isNot(contains(rawPrivateHint)));
      }
      expect(allSummaries, isNot(contains('source_photo')));
      expect(allSummaries, isNot(contains('receipt_photo_read_failed')));
    },
  );
}
