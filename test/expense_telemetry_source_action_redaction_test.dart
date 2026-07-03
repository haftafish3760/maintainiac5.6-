import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_screen_telemetry.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_documents.dart';

import 'helpers/expense_telemetry_redaction_guard_helpers.dart';

void main() {
  test('stress protects source actions against edge source evidence', () {
    const cases = {
      'photo_camera_alias': (
        source: 'photo',
        evidence: 'warning_shadow_source_camera_lowes_auth_998877_total_3_24',
        actionHint: 'receipt_camera_focus',
      ),
      'photo_image_alias': (
        source: 'photo',
        evidence: 'warning_blurry_source_image_walmart_receipt_123456',
        actionHint: 'receipt_camera_focus',
      ),
      'pdf_document_alias': (
        source: 'pdf',
        evidence: 'warning_pdf_source_document_home_depot_invoice_333444555',
        actionHint: 'pdf_safety_checks',
      ),
      'imported_pasted_alias': (
        source: 'importedtext',
        evidence: 'warning_text_source_pasted_text_caseys_total_11_22',
        actionHint: 'pasted_imported_receipt_text_cleanup',
      ),
      'mixed_combined_alias': (
        source: 'mixed',
        evidence: 'warning_mixed_source_combined_shell_barcode_036000291452',
        actionHint: 'mixed_receipt_sources',
      ),
      'none_missing_alias': (
        source: 'none',
        evidence: 'warning_missing_source_missing_private_note_123456789',
        actionHint: 'without_a_usable_receipt_photo',
      ),
      'unknown_malformed_private': (
        source: 'unknown',
        evidence:
            'warning_bad_source_lowes_terminal_2513_auth_18854480_total_3_24',
        actionHint: 'source_tagging',
      ),
      'unknown_user_note': (
        source: 'unknown',
        evidence:
            'warning_private_source_user_notes_receipt_123456789_total_12_34',
        actionHint: 'source_tagging',
      ),
    };

    final records = <ExpenseTelemetryRecord>[
      for (final entry in cases.entries)
        ExpenseTelemetryRecord(
          id: 'evt-source-action-edge-${entry.key}',
          queuedAtUtc: DateTime.utc(2026, 6, 28, 22),
          payload: Map.unmodifiable({
            'event': 'ocrFailed',
            'workflowStep': 'receiptOcr',
            'failedAt': 'during_${entry.key}_ocr_read_lowes_total_3_24',
            'confirmedCause': 'receipt_photo_read_failed_lowes_auth_998877',
            'causeStatus': 'confirmed',
            'evidence': entry.value.evidence,
            'missingEvidence': 'terminal_2513',
            'retryCount': 1,
            'platform': 'android',
            'deviceTier': 'high',
            'appVersion': '5.6.0',
          }),
        ),
      ExpenseTelemetryRecord(
        id: 'evt-source-action-edge-non-ocr',
        queuedAtUtc: DateTime.utc(2026, 6, 28, 22, 1),
        payload: Map.unmodifiable({
          'event': 'parserFailed',
          'workflowStep': 'receiptParser',
          'failedAt': 'parser_after_ocr_lowes_total_3_24_auth_998877',
          'confirmedCause': 'parser_failed_lowes_receipt_123456789012',
          'causeStatus': 'confirmed',
          'evidence': 'source_photo_lowes_auth_998877_total_3_24',
          'missingEvidence': 'line_item_positions_123456',
          'retryCount': 1,
          'platform': 'android',
          'deviceTier': 'high',
          'appVersion': '5.6.0',
        }),
      ),
    ];
    final snapshot = ExpenseTelemetryHealthSnapshot.fromRecords(
      records,
      generatedAtUtc: DateTime.utc(2026, 6, 28, 22, 5),
    );
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

    for (final entry in cases.entries) {
      final matchingBreakdowns = breakdowns.where(
        (failure) => failure['ocrFailureSource'] == entry.value.source,
      );
      expect(matchingBreakdowns, isNotEmpty);
      expect(
        matchingBreakdowns
            .map((failure) => failure['ocrFailureSourceAction'])
            .join(' '),
        contains(entry.value.actionHint),
      );
    }
    expect(
      breakdowns
          .where((failure) => failure['ocrFailureSource'] == 'not_ocr')
          .map((failure) => failure['ocrFailureSourceAction'])
          .join(' '),
      contains('use_the_failure_workflow'),
    );
    for (final action in [
      ...breakdowns.map((failure) => failure['ocrFailureSourceAction']),
      ...recent.map((failure) => failure['ocrFailureSourceAction']),
      doc.data['topOcrFailureSourceAction'],
    ]) {
      expect(action.toString(), isNotEmpty);
      expect(action.toString().length, lessThanOrEqualTo(64));
    }
    for (final summary in [
      ...breakdowns.map((failure) => failure['actionSummary']),
      ...recent.map((failure) => failure['actionSummary']),
    ]) {
      expect(summary.toString(), isNotEmpty);
      expect(summary.toString(), contains('failed'));
      expect(summary.toString().length, lessThanOrEqualTo(180));
      expect(summary.toString(), isNot(contains('_')));
    }
    for (final rawPrivateHint in const [
      'lowes',
      'walmart',
      'home_depot',
      'caseys',
      'shell',
      'user_notes',
      '3_24',
      '11_22',
      '12_34',
      '998877',
      '18854480',
      '123456789012',
      '036000291452',
    ]) {
      expect(serialized, isNot(contains(rawPrivateHint)));
    }
    expect(serialized, contains('source_unknown'));
    expect(serialized, contains('not_ocr'));
  });

  test('keeps OCR source actions on Firestore failure drill-down rows', () {
    final snapshot = ExpenseTelemetryHealthSnapshot.fromRecords([
      ExpenseTelemetryRecord(
        id: 'evt-drilldown-source-action',
        queuedAtUtc: DateTime.utc(2026, 6, 28, 18),
        payload: Map.unmodifiable({
          'event': 'ocrFailed',
          'workflowStep': 'receiptOcr',
          'failedAt': 'during_photo_ocr_read',
          'confirmedCause': 'receipt_photo_read_failed',
          'causeStatus': 'confirmed',
          'evidence': 'source_lowes_total_3_24_auth_998877',
          'missingEvidence': 'none',
          'retryCount': 2,
          'platform': 'android',
          'deviceTier': 'high',
          'appVersion': '5.6.0',
        }),
      ),
    ], generatedAtUtc: DateTime.utc(2026, 6, 28, 18, 1));
    final doc =
        MaintainiacFirestoreDocumentBuilder.expenseTelemetrySummaryDocument(
          orgId: 'ORG-1',
          summaryId: 'latest',
          snapshot: snapshot,
          maxFailureBreakdowns: 20,
          maxRecentFailureDetails: 20,
        );
    final failureBreakdown =
        (doc.data['failureBreakdowns'] as List).single as Map<String, Object?>;
    final recentFailure =
        (doc.data['recentFailureDetails'] as List).single
            as Map<String, Object?>;
    final serialized = serializedTelemetryValues(doc.data).toLowerCase();

    expect(failureBreakdown['ocrFailureSource'], 'unknown');
    expect(
      failureBreakdown['ocrFailureSourceAction'],
      contains('source_tagging'),
    );
    expect(recentFailure['ocrFailureSource'], 'unknown');
    expect(recentFailure['ocrFailureSourceAction'], contains('source_tagging'));
    expect(serialized, isNot(contains('lowes')));
    expect(serialized, isNot(contains('3_24')));
    expect(serialized, isNot(contains('998877')));
    expect(serialized, contains('source_unknown'));
  });

  test('keeps action summaries readable after Firestore sanitization', () {
    final snapshot = ExpenseTelemetryHealthSnapshot.fromRecords([
      ExpenseTelemetryRecord(
        id: 'evt-action-summary-ocr',
        queuedAtUtc: DateTime.utc(2026, 6, 28, 22, 30),
        payload: Map.unmodifiable({
          'event': 'ocrFailed',
          'workflowStep': 'receiptOcr',
          'failedAt': 'during_photo_ocr_read_lowes_total_3_24',
          'confirmedCause': 'receipt_photo_read_failed_lowes_auth_998877',
          'causeStatus': 'confirmed',
          'evidence': 'source_photo_lowes_total_3_24_auth_998877',
          'missingEvidence': 'none',
          'retryCount': 2,
          'platform': 'android',
          'deviceTier': 'high',
          'appVersion': '5.6.0',
        }),
      ),
      ExpenseTelemetryRecord(
        id: 'evt-action-summary-unconfirmed',
        queuedAtUtc: DateTime.utc(2026, 6, 28, 22, 31),
        payload: Map.unmodifiable({
          'event': 'saveFailure',
          'workflowStep': 'saveExpense',
          'failedAt': 'ledger_save_lowes_total_3_24',
          'confirmedCause': 'cause_not_confirmed_ledger_save_failed',
          'causeStatus': 'notConfirmed',
          'evidence': 'source_photo_lowes_total_3_24_auth_998877',
          'missingEvidence': 'exception_type_and_hive_box_state',
          'retryCount': 1,
          'platform': 'android',
          'deviceTier': 'high',
          'appVersion': '5.6.0',
        }),
      ),
    ], generatedAtUtc: DateTime.utc(2026, 6, 28, 22, 35));
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
    final summaries = [
      ...breakdowns.map((failure) => failure['actionSummary'].toString()),
      ...recent.map((failure) => failure['actionSummary'].toString()),
    ];
    final serialized = serializedTelemetryValues(doc.data).toLowerCase();

    expect(summaries, everyElement(contains('failed')));
    expect(
      summaries.join(' '),
      contains('Check photo capture or image readability'),
    );
    expect(summaries.join(' '), contains('cause is not confirmed yet'));
    expect(summaries.join(' '), contains('exception type and hive box state'));
    expect(
      summaries.join(' '),
      isNot(contains('receipt_photo_read_failed_lowes')),
    );
    expect(summaries.join(' '), isNot(contains('source_photo')));
    expect(summaries.join(' '), isNot(contains('_')));
    expect(serialized, isNot(contains('lowes')));
    expect(serialized, isNot(contains('3_24')));
    expect(serialized, isNot(contains('998877')));
  });
}
