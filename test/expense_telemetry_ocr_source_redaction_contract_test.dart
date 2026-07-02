import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_screen_telemetry.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_documents.dart';

import 'helpers/expense_telemetry_redaction_guard_helpers.dart';
import 'helpers/expense_telemetry_source_bucket_expectations.dart';

void main() {
  test(
    'OCR source bucket contract stays aligned across docs and Firestore',
    () {
      final telemetrySource = readDartLibraryWithParts(
        'lib/screens/expenses/data/expense_screen_telemetry.dart',
      );
      final ocrContract = File(
        'docs/expense_command_center_ocr_contract.md',
      ).readAsStringSync();
      final syncSpec = [
        'docs/firebase_sync_schema_spec.md',
        'docs/firebase_sync_receipt_expense_schema_spec.md',
      ].map((path) => File(path).readAsStringSync()).join('\n');

      expect(
        expectedExpenseTelemetryDrilldownOcrFailureSourceBuckets,
        containsAll(expectedExpenseTelemetryOcrFailureSourceBuckets),
      );
      expect(
        expectedExpenseTelemetryDrilldownOcrFailureSourceBuckets,
        contains('not_ocr'),
      );
      for (final bucket in expectedExpenseTelemetryOcrFailureSourceBuckets) {
        expect(telemetrySource, contains("'$bucket'"));
        expect(ocrContract, contains('`$bucket`'));
        expect(syncSpec, contains('`$bucket`'));
      }
      expect(telemetrySource, contains("'not_ocr'"));
      expect(ocrContract, contains('`not_ocr`'));
      expect(syncSpec, contains('`not_ocr`'));

      const sourceCases = {
        'photo': 'warning_blurry_source_photo_total_3_24',
        'pdf': 'warning_pdf_source_pdf_total_4_25',
        'importedtext': 'warning_text_source_imported_text_total_5_26',
        'mixed': 'warning_mixed_source_combined_total_6_27',
        'none': 'warning_missing_source_none_total_7_28',
        'unknown': 'warning_private_source_lowes_total_8_29',
      };
      expect(
        sourceCases.keys.toSet(),
        expectedExpenseTelemetryOcrFailureSourceBuckets,
      );

      final records = <ExpenseTelemetryRecord>[
        for (final entry in sourceCases.entries)
          ExpenseTelemetryRecord(
            id: 'evt-source-drift-${entry.key}',
            queuedAtUtc: DateTime.utc(2026, 6, 28, 21),
            payload: Map.unmodifiable({
              'event': 'ocrFailed',
              'workflowStep': 'receiptOcr',
              'failedAt': 'during_ocr_read_${entry.key}',
              'confirmedCause': 'receipt_photo_read_failed_${entry.key}',
              'causeStatus': 'confirmed',
              'evidence': entry.value,
              'missingEvidence': 'none',
              'platform': 'android',
              'deviceTier': 'high',
              'appVersion': '5.6.0',
            }),
          ),
        ExpenseTelemetryRecord(
          id: 'evt-source-drift-save',
          queuedAtUtc: DateTime.utc(2026, 6, 28, 21, 1),
          payload: Map.unmodifiable({
            'event': 'saveFailure',
            'workflowStep': 'saveExpense',
            'failedAt': 'ledger_save_receipt',
            'confirmedCause': 'ledger_save_failed',
            'causeStatus': 'confirmed',
            'evidence': 'source_camera_lowes_receipt_123456_total_3_24',
            'missingEvidence': 'hive_box_state',
            'platform': 'android',
            'deviceTier': 'high',
            'appVersion': '5.6.0',
          }),
        ),
      ];
      final snapshot = ExpenseTelemetryHealthSnapshot.fromRecords(
        records,
        generatedAtUtc: DateTime.utc(2026, 6, 28, 21, 5),
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

      expect(
        snapshot.ocrFailureSourceCounts.keys.toSet(),
        expectedExpenseTelemetryOcrFailureSourceBuckets,
      );
      expect(
        (doc.data['ocrFailureSourceCounts'] as Map).keys.toSet(),
        expectedExpenseTelemetryOcrFailureSourceBuckets,
      );
      expect(
        breakdowns.map((failure) => failure['ocrFailureSource']).toSet(),
        expectedExpenseTelemetryDrilldownOcrFailureSourceBuckets,
      );
      expect(
        recent.map((failure) => failure['ocrFailureSource']).toSet(),
        expectedExpenseTelemetryDrilldownOcrFailureSourceBuckets,
      );
      final values = serializedTelemetryValues(doc.data).toLowerCase();
      expect(values, isNot(contains('lowes')));
      expect(values, isNot(contains('3_24')));
    },
  );

  test('isolates OCR source labels from private evidence strings', () {
    final records = <ExpenseTelemetryRecord>[];
    final poisonedSources = [
      'source_lowes_total_3_24_auth_998877',
      'source_private_store_total_4_25_receipt_123456',
      'source_user_notes_total_5_26_invoice_654321',
    ];

    for (var index = 0; index < poisonedSources.length; index += 1) {
      records.add(
        ExpenseTelemetryRecord(
          id: 'evt-source-isolation-$index',
          queuedAtUtc: DateTime.utc(2026, 6, 28, 15, index),
          payload: Map.unmodifiable({
            'event': 'ocrFailed',
            'workflowStep': 'receiptOcr',
            'failedAt': 'during_photo_ocr_read',
            'confirmedCause': 'receipt_photo_read_failed',
            'causeStatus': 'confirmed',
            'evidence': poisonedSources[index],
            'missingEvidence': 'none',
            'retryCount': index + 1,
            'platform': 'android',
            'deviceTier': 'high',
            'appVersion': '5.6.$index',
          }),
        ),
      );
    }

    final snapshot = ExpenseTelemetryHealthSnapshot.fromRecords(
      records,
      generatedAtUtc: DateTime.utc(2026, 6, 28, 16),
    );
    final doc =
        MaintainiacFirestoreDocumentBuilder.expenseTelemetrySummaryDocument(
          orgId: 'ORG-1',
          summaryId: 'latest',
          snapshot: snapshot,
          maxFailureBreakdowns: 20,
          maxRecentFailureDetails: 20,
        );
    final serialized = serializedTelemetryValues(doc.data).toLowerCase();

    expect(doc.data['ocrFailureSourceCounts'], {'unknown': 3});
    expect(doc.data['topOcrFailureSource'], 'unknown');
    expect(serialized, isNot(contains('lowes')));
    expect(serialized, isNot(contains('private_store')));
    expect(serialized, isNot(contains('user_notes')));
    expect(serialized, isNot(contains('998877')));
    expect(serialized, isNot(contains('123456')));
    expect(serialized, isNot(contains('654321')));
    expect(serialized, contains('unknown'));
    expect(serialized, contains('amount'));
    expect(serialized, contains('private_reference'));
  });

  test('keeps OCR source actions useful after Firestore sanitization', () {
    const cases = {
      'photo': (
        evidence: 'warning_blurry_source_photo_total_3_24',
        actionHint: 'receipt_camera_focus',
      ),
      'pdf': (
        evidence: 'warning_pdf_source_pdf_total_4_25',
        actionHint: 'pdf_safety_checks',
      ),
      'importedtext': (
        evidence: 'warning_text_source_imported_text_total_5_26',
        actionHint: 'pasted_imported_receipt_text_cleanup',
      ),
      'mixed': (
        evidence: 'warning_mixed_source_mixed_total_6_27',
        actionHint: 'mixed_receipt_sources',
      ),
      'none': (
        evidence: 'warning_missing_source_none_total_7_28',
        actionHint: 'without_a_usable_receipt_photo',
      ),
      'unknown': (
        evidence: 'warning_private_source_lowes_total_8_29',
        actionHint: 'source_tagging',
      ),
    };

    for (final entry in cases.entries) {
      final snapshot = ExpenseTelemetryHealthSnapshot.fromRecords([
        ExpenseTelemetryRecord(
          id: 'evt-source-action-firestore-${entry.key}',
          queuedAtUtc: DateTime.utc(2026, 6, 28, 17),
          payload: Map.unmodifiable({
            'event': 'ocrFailed',
            'workflowStep': 'receiptOcr',
            'failedAt': 'during_ocr_read',
            'confirmedCause': 'receipt_photo_read_failed',
            'causeStatus': 'confirmed',
            'evidence': entry.value.evidence,
            'missingEvidence': 'none',
            'retryCount': 1,
            'platform': 'android',
            'deviceTier': 'high',
            'appVersion': '5.6.0',
          }),
        ),
      ], generatedAtUtc: DateTime.utc(2026, 6, 28, 17, 1));
      final doc =
          MaintainiacFirestoreDocumentBuilder.expenseTelemetrySummaryDocument(
            orgId: 'ORG-1',
            summaryId: 'latest',
            snapshot: snapshot,
            maxFailureBreakdowns: 20,
            maxRecentFailureDetails: 20,
          );
      final action = doc.data['topOcrFailureSourceAction'].toString();
      final serialized = serializedTelemetryValues(doc.data).toLowerCase();

      expect(doc.data['topOcrFailureSource'], entry.key);
      expect(action, contains(entry.value.actionHint));
      expect(action.length, lessThanOrEqualTo(64));
      expect(serialized, isNot(contains('lowes')));
      expect(serialized, isNot(contains('3_24')));
      expect(serialized, isNot(contains('4_25')));
      expect(serialized, isNot(contains('5_26')));
      expect(serialized, isNot(contains('6_27')));
      expect(serialized, isNot(contains('7_28')));
      expect(serialized, isNot(contains('8_29')));
    }
  });
}
