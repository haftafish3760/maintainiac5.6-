import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_screen_telemetry.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_documents.dart';

void main() {
  test(
    'protects action summaries from private fixture hints locally and in Firestore',
    () {
      final snapshot = ExpenseTelemetryHealthSnapshot.fromRecords([
        ExpenseTelemetryRecord(
          id: 'evt-private-summary-confirmed',
          queuedAtUtc: DateTime.utc(2026, 6, 29),
          payload: Map.unmodifiable({
            'event': 'ocrFailed',
            'workflowStep': 'receiptOcr',
            'failedAt': 'lowes_austin_auth_998877_receipt_18854480_total_3_24',
            'confirmedCause':
                'receipt_photo_read_failed_lowes_auth_998877_total_3_24',
            'causeStatus': 'confirmed',
            'evidence':
                'source_photo_lowes_barcode_036000291452_customer_john_total_3_24',
            'missingEvidence':
                'user_note_call_john_555_123_4567_receipt_18854480',
            'retryCount': 2,
            'platform': 'android',
            'deviceTier': 'high',
            'appVersion': '5.6.0',
          }),
        ),
        ExpenseTelemetryRecord(
          id: 'evt-private-summary-unconfirmed',
          queuedAtUtc: DateTime.utc(2026, 6, 29, 0, 1),
          payload: Map.unmodifiable({
            'event': 'saveFailure',
            'workflowStep': 'saveExpense',
            'failedAt': 'walmart_customer_jane_total_12_34_receipt_777888',
            'confirmedCause':
                'cause_not_confirmed_walmart_order_777888_total_12_34',
            'causeStatus': 'notConfirmed',
            'evidence':
                'ledger_save_exception_walmart_customer_jane_total_12_34',
            'missingEvidence':
                'exception_type_hive_box_state_user_note_jane_555_222_3333',
            'retryCount': 1,
            'platform': 'ios',
            'deviceTier': 'mid',
            'appVersion': '5.6.1',
          }),
        ),
      ], generatedAtUtc: DateTime.utc(2026, 6, 29, 0, 5));
      final doc =
          MaintainiacFirestoreDocumentBuilder.expenseTelemetrySummaryDocument(
            orgId: 'ORG-1',
            summaryId: 'latest',
            snapshot: snapshot,
            maxFailureBreakdowns: 20,
            maxRecentFailureDetails: 20,
          );
      final firestoreBreakdowns = (doc.data['failureBreakdowns'] as List)
          .cast<Map<String, Object?>>();
      final firestoreRecent = (doc.data['recentFailureDetails'] as List)
          .cast<Map<String, Object?>>();
      final summaries = [
        ...snapshot.failureBreakdowns.map((failure) => failure.actionSummary),
        ...snapshot.recentFailureDetails.map(
          (failure) => failure.actionSummary,
        ),
        ...firestoreBreakdowns.map(
          (failure) => failure['actionSummary'].toString(),
        ),
        ...firestoreRecent.map(
          (failure) => failure['actionSummary'].toString(),
        ),
      ];
      final recommendations = [
        ...snapshot.failureBreakdowns.map(
          (failure) => failure.recommendedAction,
        ),
        ...snapshot.recentFailureDetails.map(
          (failure) => failure.recommendedAction,
        ),
        ...firestoreBreakdowns.map(
          (failure) => failure['recommendedAction'].toString(),
        ),
        ...firestoreRecent.map(
          (failure) => failure['recommendedAction'].toString(),
        ),
      ];
      final evidenceLabels = [
        ...snapshot.failureBreakdowns.map((failure) => failure.evidenceLabel),
        ...snapshot.failureBreakdowns.map(
          (failure) => failure.missingEvidenceLabel,
        ),
        ...snapshot.recentFailureDetails.map(
          (failure) => failure.evidenceLabel,
        ),
        ...snapshot.recentFailureDetails.map(
          (failure) => failure.missingEvidenceLabel,
        ),
        ...firestoreBreakdowns.map(
          (failure) => failure['evidenceLabel'].toString(),
        ),
        ...firestoreBreakdowns.map(
          (failure) => failure['missingEvidenceLabel'].toString(),
        ),
        ...firestoreRecent.map(
          (failure) => failure['evidenceLabel'].toString(),
        ),
        ...firestoreRecent.map(
          (failure) => failure['missingEvidenceLabel'].toString(),
        ),
      ];
      final diagnosticLabels = [
        ...snapshot.failureBreakdowns.map((failure) => failure.failedAtLabel),
        ...snapshot.failureBreakdowns.map((failure) => failure.causeLabel),
        ...snapshot.recentFailureDetails.map(
          (failure) => failure.failedAtLabel,
        ),
        ...snapshot.recentFailureDetails.map((failure) => failure.causeLabel),
        ...firestoreBreakdowns.map(
          (failure) => failure['failedAtLabel'].toString(),
        ),
        ...firestoreBreakdowns.map(
          (failure) => failure['causeLabel'].toString(),
        ),
        ...firestoreRecent.map(
          (failure) => failure['failedAtLabel'].toString(),
        ),
        ...firestoreRecent.map((failure) => failure['causeLabel'].toString()),
        doc.data['topOcrFailureStageLabel'].toString(),
      ];
      final visibleText = [
        ...summaries,
        ...recommendations,
        ...evidenceLabels,
        ...diagnosticLabels,
      ].join(' ').toLowerCase();

      expect(summaries, everyElement(contains('failed')));
      expect(evidenceLabels, everyElement(isNot(isEmpty)));
      expect(evidenceLabels, everyElement(isNot(contains('_'))));
      expect(diagnosticLabels, everyElement(isNot(isEmpty)));
      expect(diagnosticLabels, everyElement(isNot(contains('_'))));
      for (final label in evidenceLabels) {
        expect(label.length, lessThanOrEqualTo(120));
      }
      for (final label in diagnosticLabels) {
        expect(label.length, lessThanOrEqualTo(120));
      }
      expect(visibleText, contains('merchant'));
      expect(visibleText, contains('amount'));
      expect(visibleText, contains('private reference'));
      expect(visibleText, contains('exception type hive box state'));
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
        'source_photo',
        'user_note',
      ]) {
        expect(visibleText, isNot(contains(privateHint)));
      }
    },
  );
}
