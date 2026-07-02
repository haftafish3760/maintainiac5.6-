import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_screen_telemetry.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_documents.dart';

import 'helpers/expense_telemetry_redaction_guard_helpers.dart';

void main() {
  test('keeps machine tokens out of visible Firestore drill-down text', () {
    final snapshot = ExpenseTelemetryHealthSnapshot.fromRecords([
      ExpenseTelemetryRecord(
        id: 'evt-token-boundary-ocr',
        queuedAtUtc: DateTime.utc(2026, 6, 29, 1),
        payload: Map.unmodifiable({
          'event': 'ocrFailed',
          'workflowStep': 'receiptOcr',
          'failedAt': 'lowes_austin_auth_998877_receipt_18854480_total_3_24',
          'confirmedCause':
              'receipt_photo_read_failed_lowes_auth_998877_total_3_24',
          'causeStatus': 'confirmed',
          'evidence':
              'source_photo_lowes_barcode_036000291452_customer_john_total_3_24',
          'missingEvidence': 'receipt_18854480_user_note_john_555_123_4567',
          'retryCount': 3,
          'platform': 'android',
          'deviceTier': 'high',
          'appVersion': '5.6.0',
        }),
      ),
      ExpenseTelemetryRecord(
        id: 'evt-token-boundary-parser',
        queuedAtUtc: DateTime.utc(2026, 6, 29, 1, 1),
        payload: Map.unmodifiable({
          'event': 'parserFailed',
          'workflowStep': 'receiptParser',
          'failedAt': 'walmart_terminal_321654_total_12_34',
          'confirmedCause':
              'receipt_parser_no_usable_fields_walmart_order_777888',
          'causeStatus': 'confirmed',
          'evidence':
              'source_photo_walmart_customer_jane_order_777888_total_12_34',
          'missingEvidence': 'line_positions_receipt_777888',
          'retryCount': 1,
          'platform': 'ios',
          'deviceTier': 'mid',
          'appVersion': '5.6.1',
        }),
      ),
    ], generatedAtUtc: DateTime.utc(2026, 6, 29, 1, 5));
    final doc =
        MaintainiacFirestoreDocumentBuilder.expenseTelemetrySummaryDocument(
          orgId: 'ORG-1',
          summaryId: 'latest',
          snapshot: snapshot,
          maxFailureBreakdowns: 20,
          maxRecentFailureDetails: 20,
        );
    final rows = [
      ...(doc.data['failureBreakdowns'] as List).cast<Map<String, Object?>>(),
      ...(doc.data['recentFailureDetails'] as List)
          .cast<Map<String, Object?>>(),
    ];

    const machineTokenKeys = {
      'failedAt',
      'confirmedCause',
      'evidence',
      'missingEvidence',
      'ocrFailureSourceAction',
    };
    const visibleTextKeys = {
      'failedAtLabel',
      'causeLabel',
      'evidenceLabel',
      'missingEvidenceLabel',
      'recommendedAction',
      'actionSummary',
    };
    for (final row in rows) {
      for (final key in machineTokenKeys) {
        final token = row[key].toString();
        expect(token, isNotEmpty);
        expect(token, matches(RegExp(r'^[a-z0-9_]+$')));
      }
      for (final key in visibleTextKeys) {
        final text = row[key].toString();
        expect(text, isNotEmpty);
        expect(text, isNot(contains('_')), reason: '$key leaked raw token');
      }
    }

    final visibleText = [
      for (final row in rows)
        for (final key in visibleTextKeys) row[key].toString(),
      doc.data['topOcrFailureStageLabel'].toString(),
    ].join(' ').toLowerCase();
    final machineText = [
      for (final row in rows)
        for (final key in machineTokenKeys) row[key].toString(),
      doc.data['topOcrFailureCause'].toString(),
      doc.data['topOcrFailureStage'].toString(),
    ].join(' ').toLowerCase();

    expect(visibleText, contains('merchant'));
    expect(visibleText, contains('amount'));
    expect(machineText, contains('_'));
    expect(machineText, contains('merchant'));
    expect(machineText, contains('amount'));
    for (final privateHint in const [
      'lowes',
      'walmart',
      'austin',
      'john',
      'jane',
      '3_24',
      '12_34',
      '998877',
      '18854480',
      '777888',
      '036000291452',
      '555',
    ]) {
      expect(visibleText, isNot(contains(privateHint)));
      expect(machineText, isNot(contains(privateHint)));
    }
  });

  test('stress protects drill-down source actions across mixed failures', () {
    final records = <ExpenseTelemetryRecord>[
      ExpenseTelemetryRecord(
        id: 'evt-stress-photo',
        queuedAtUtc: DateTime.utc(2026, 6, 28, 19),
        payload: Map.unmodifiable({
          'event': 'ocrFailed',
          'workflowStep': 'receiptOcr',
          'failedAt': 'during_photo_ocr_read_shell_total_45_67',
          'confirmedCause': 'receipt_photo_read_failed_shell_auth_998877',
          'causeStatus': 'confirmed',
          'evidence': 'source_photo_shell_barcode_036000291452_total_45_67',
          'missingEvidence': 'auth_998877',
          'retryCount': 2,
          'platform': 'android',
          'deviceTier': 'high',
          'appVersion': '5.6.0',
        }),
      ),
      ExpenseTelemetryRecord(
        id: 'evt-stress-pdf',
        queuedAtUtc: DateTime.utc(2026, 6, 28, 19, 1),
        payload: Map.unmodifiable({
          'event': 'ocrFailed',
          'workflowStep': 'receiptOcr',
          'failedAt': 'during_pdf_ocr_read_invoice_333444555',
          'confirmedCause': 'pdf_read_failed_home_depot_total_109_23',
          'causeStatus': 'confirmed',
          'evidence': 'source_pdf_home_depot_receipt_555666777_total_109_23',
          'missingEvidence': 'invoice_333444555',
          'retryCount': 1,
          'platform': 'android',
          'deviceTier': 'mid',
          'appVersion': '5.6.1',
        }),
      ),
      ExpenseTelemetryRecord(
        id: 'evt-stress-poisoned-source',
        queuedAtUtc: DateTime.utc(2026, 6, 28, 19, 2),
        payload: Map.unmodifiable({
          'event': 'ocrFailed',
          'workflowStep': 'receiptOcr',
          'failedAt': 'during_photo_ocr_read_lowes_total_3_24',
          'confirmedCause': 'receipt_photo_read_failed_lowes_auth_18854480',
          'causeStatus': 'confirmed',
          'evidence': 'source_private_store_lowes_total_3_24_auth_18854480',
          'missingEvidence': 'terminal_2513',
          'retryCount': 3,
          'platform': 'android',
          'deviceTier': 'high',
          'appVersion': '5.6.2',
        }),
      ),
      ExpenseTelemetryRecord(
        id: 'evt-stress-user-note-source',
        queuedAtUtc: DateTime.utc(2026, 6, 28, 19, 3),
        payload: Map.unmodifiable({
          'event': 'ocrFailed',
          'workflowStep': 'receiptOcr',
          'failedAt': 'during_photo_ocr_read_user_note_total_12_34',
          'confirmedCause': 'receipt_photo_read_failed_private_note',
          'causeStatus': 'confirmed',
          'evidence': 'source_user_notes_total_12_34_receipt_123456789',
          'missingEvidence': 'transaction_777888999',
          'retryCount': 4,
          'platform': 'ios',
          'deviceTier': 'high',
          'appVersion': '5.6.3',
        }),
      ),
      ExpenseTelemetryRecord(
        id: 'evt-stress-parser',
        queuedAtUtc: DateTime.utc(2026, 6, 28, 19, 4),
        payload: Map.unmodifiable({
          'event': 'parserFailed',
          'workflowStep': 'receiptParser',
          'failedAt': 'parser_after_ocr_walmart_total_12_34',
          'confirmedCause': 'parser_failed_walmart_receipt_123456789012',
          'causeStatus': 'confirmed',
          'evidence': 'source_photo_walmart_upc_123456789012_total_12_34',
          'missingEvidence': 'line_item_positions_123456',
          'retryCount': 1,
          'platform': 'android',
          'deviceTier': 'low',
          'appVersion': '5.6.4',
        }),
      ),
      ExpenseTelemetryRecord(
        id: 'evt-stress-save',
        queuedAtUtc: DateTime.utc(2026, 6, 28, 19, 5),
        payload: Map.unmodifiable({
          'event': 'saveFailure',
          'workflowStep': 'saveExpense',
          'failedAt': 'ledger_save_caseys_total_11_22',
          'confirmedCause': 'save_failed_caseys_invoice_444333',
          'causeStatus': 'confirmed',
          'evidence': 'source_camera_caseys_receipt_444333_total_11_22',
          'missingEvidence': 'hive_box_state_112233',
          'retryCount': 1,
          'platform': 'android',
          'deviceTier': 'mid',
          'appVersion': '5.6.5',
        }),
      ),
    ];

    final snapshot = ExpenseTelemetryHealthSnapshot.fromRecords(
      records,
      generatedAtUtc: DateTime.utc(2026, 6, 28, 20),
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

    expect(breakdowns, hasLength(records.length));
    expect(recent, hasLength(records.length));
    expect(
      breakdowns.map((failure) => failure['ocrFailureSource']).toSet(),
      containsAll({'photo', 'pdf', 'unknown', 'not_ocr'}),
    );
    expect(
      breakdowns
          .where((failure) => failure['workflowStep'] != 'receiptocr')
          .map((failure) => failure['ocrFailureSource'])
          .toSet(),
      {'not_ocr'},
    );
    expect(
      breakdowns
          .where((failure) => failure['ocrFailureSource'] == 'unknown')
          .map((failure) => failure['ocrFailureSourceAction'])
          .join(' '),
      contains('source_tagging'),
    );
    expect(
      breakdowns
          .where((failure) => failure['ocrFailureSource'] == 'not_ocr')
          .map((failure) => failure['ocrFailureSourceAction'])
          .join(' '),
      contains('use_the_failure_workflow'),
    );

    for (final rawPrivateHint in const [
      'shell',
      'home_depot',
      'lowes',
      'private_store',
      'user_notes',
      'walmart',
      'caseys',
      '45_67',
      '109_23',
      '3_24',
      '12_34',
      '11_22',
      '998877',
      '036000291452',
      '333444555',
      '555666777',
      '18854480',
      '2513',
      '123456789',
      '777888999',
      '123456789012',
      '444333',
      '112233',
    ]) {
      expect(serialized, isNot(contains(rawPrivateHint)));
    }
    expect(serialized, contains('source_unknown'));
    expect(serialized, contains('merchant'));
    expect(serialized, contains('amount'));
    expect(serialized, contains('number'));
  });
}
