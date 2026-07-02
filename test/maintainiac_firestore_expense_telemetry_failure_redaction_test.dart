import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_screen_telemetry.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_documents.dart';

import 'helpers/expense_telemetry_schema_expectations.dart';

void main() {
  test('caps expense telemetry failure drill-downs for Firestore', () {
    final snapshot = _expenseTelemetryFailureSnapshot(60);

    final defaultDoc =
        MaintainiacFirestoreDocumentBuilder.expenseTelemetrySummaryDocument(
          orgId: 'ORG-1',
          summaryId: 'latest',
          snapshot: snapshot,
        );
    final expandedDoc =
        MaintainiacFirestoreDocumentBuilder.expenseTelemetrySummaryDocument(
          orgId: 'ORG-1',
          summaryId: 'expanded',
          snapshot: snapshot,
          maxFailureBreakdowns: 999,
          maxRecentFailureDetails: 999,
        );
    final leanDoc =
        MaintainiacFirestoreDocumentBuilder.expenseTelemetrySummaryDocument(
          orgId: 'ORG-1',
          summaryId: 'lean',
          snapshot: snapshot,
          maxFailureBreakdowns: 0,
          maxRecentFailureDetails: 0,
        );

    expect(defaultDoc.data['failureBreakdowns'], isA<List>());
    expect(defaultDoc.data['recentFailureDetails'], isA<List>());
    expect((defaultDoc.data['failureBreakdowns'] as List), hasLength(20));
    expect((defaultDoc.data['recentFailureDetails'] as List), hasLength(50));
    expect((expandedDoc.data['failureBreakdowns'] as List), hasLength(50));
    expect((expandedDoc.data['recentFailureDetails'] as List), hasLength(60));
    expect((leanDoc.data['failureBreakdowns'] as List), isEmpty);
    expect((leanDoc.data['recentFailureDetails'] as List), isEmpty);
    expect(defaultDoc.data.toString().toLowerCase(), isNot(contains('secret')));
  });

  test('keeps failure drill-down object schemas stable for Firestore', () {
    final snapshot = _expenseTelemetryFailureSnapshot(3);
    final doc =
        MaintainiacFirestoreDocumentBuilder.expenseTelemetrySummaryDocument(
          orgId: 'ORG-1',
          summaryId: 'latest',
          snapshot: snapshot,
        );

    final failureBreakdown =
        (doc.data['failureBreakdowns'] as List).first as Map<String, Object?>;
    final recentFailure =
        (doc.data['recentFailureDetails'] as List).first
            as Map<String, Object?>;
    const privateKeys = {
      'payload',
      'metadata',
      'receiptText',
      'rawOcrText',
      'merchantName',
      'itemDescription',
      'proofPath',
      'orgId',
      'userId',
    };

    expect(
      failureBreakdown.keys.toSet(),
      expectedExpenseTelemetryFailureBreakdownKeys,
    );
    expect(
      recentFailure.keys.toSet(),
      expectedExpenseTelemetryRecentFailureDetailKeys,
    );
    for (final privateKey in privateKeys) {
      expect(failureBreakdown, isNot(contains(privateKey)));
      expect(recentFailure, isNot(contains(privateKey)));
    }
    expect(failureBreakdown['missingEvidence'], 'none');
    expect(recentFailure['missingEvidence'], 'none');
  });

  test('scrubs private receipt hints from failure drill-down text', () {
    final snapshot = ExpenseTelemetryHealthSnapshot.fromRecords([
      ExpenseTelemetryRecord(
        id: 'evt-private-receipt-failure',
        queuedAtUtc: DateTime.utc(2026, 6, 24, 12),
        payload: ExpenseTelemetryPolicy.sanitizeMap({
          'event': 'ocrFailed',
          'workflowStep': 'receiptOcr',
          'failedAt': 'after_lowes_total_3.24_receipt_18854480',
          'confirmedCause': 'lowes_total_3.24_ocr_failed',
          'causeStatus': 'confirmed',
          'evidence': 'source_photo_lowes_receipt_18854480_total_3.24',
          'missingEvidence': 'auth_5715',
          'retryCount': 2,
          'abandoned': true,
          'platform': 'android',
          'deviceTier': 'high',
          'appVersion': '5.6.0',
        }),
      ),
    ], generatedAtUtc: DateTime.utc(2026, 6, 24, 13));

    final doc =
        MaintainiacFirestoreDocumentBuilder.expenseTelemetrySummaryDocument(
          orgId: 'ORG-1',
          summaryId: 'latest',
          snapshot: snapshot,
        );
    final failureBreakdown =
        (doc.data['failureBreakdowns'] as List).single as Map<String, Object?>;
    final recentFailure =
        (doc.data['recentFailureDetails'] as List).single
            as Map<String, Object?>;
    final serialized = _stringifyFirestorePayloadValues(doc.data).toLowerCase();

    expect(serialized, isNot(contains('lowes')));
    expect(serialized, isNot(contains('lowe')));
    expect(serialized, isNot(contains('3.24')));
    expect(serialized, isNot(contains('18854480')));
    expect(serialized, isNot(contains('5715')));
    expect(failureBreakdown['confirmedCause'], contains('merchant'));
    expect(failureBreakdown['confirmedCause'], contains('amount'));
    expect(failureBreakdown['failedAt'], contains('private_reference'));
    expect(failureBreakdown['evidence'], contains('merchant'));
    expect(failureBreakdown['missingEvidence'], 'private_reference');
    expect(
      recentFailure['causeLabel'].toString().toLowerCase(),
      contains('merchant'),
    );
    expect(
      recentFailure['causeLabel'].toString().toLowerCase(),
      contains('amount'),
    );
    expect(
      recentFailure['failedAtLabel'].toString().toLowerCase(),
      contains('private reference'),
    );
    expect(
      recentFailure['missingEvidenceLabel'].toString().toLowerCase(),
      contains('private reference'),
    );
  });

  test('stress scrubs fuel auto barcode and currency failure hints', () {
    final records = <ExpenseTelemetryRecord>[];
    final cases = [
      (
        event: 'ocrFailed',
        failedAt: 'shell_total_45_67_ticket_982334455',
        cause: 'shell_auth_998877_ocr_failed',
        evidence: 'source_photo_shell_barcode_036000291452_total_45_67',
        missing: 'terminal_123456',
      ),
      (
        event: 'parserFailed',
        failedAt: 'jiffy_lube_invoice_123456789_total_89.99',
        cause: 'jiffy_lube_oil_change_receipt_123456789',
        evidence: 'source_photo_jiffy_lube_card_5715_amount_89_99',
        missing: 'transaction_777888999',
      ),
      (
        event: 'imageAttachFailure',
        failedAt: 'walmart_receipt_545454_total_12_34',
        cause: 'walmart_barcode_123456789012_decode_failed',
        evidence: 'source_photo_walmart_upc_123456789012_total_12.34',
        missing: 'authcode_112233',
      ),
      (
        event: 'saveFailure',
        failedAt: 'home_depot_order_555666777_total_109_23',
        cause: 'home_depot_receipt_total_109_23_save_failed',
        evidence: 'source_photo_home_depot_receipt_555666777_total_109_23',
        missing: 'invoice_444555666',
      ),
    ];

    for (var index = 0; index < cases.length; index += 1) {
      final testCase = cases[index];
      records.add(
        ExpenseTelemetryRecord(
          id: 'evt-redaction-stress-$index',
          queuedAtUtc: DateTime.utc(2026, 6, 24, 12, index),
          payload: Map.unmodifiable({
            'event': testCase.event,
            'workflowStep': index.isEven ? 'receiptOcr' : 'receiptParser',
            'failedAt': testCase.failedAt,
            'confirmedCause': testCase.cause,
            'causeStatus': 'confirmed',
            'evidence': testCase.evidence,
            'missingEvidence': testCase.missing,
            'retryCount': index + 1,
            'platform': 'android',
            'deviceTier': index.isEven ? 'high' : 'low',
            'appVersion': '5.6.$index',
          }),
        ),
      );
    }

    final snapshot = ExpenseTelemetryHealthSnapshot.fromRecords(
      records,
      generatedAtUtc: DateTime.utc(2026, 6, 24, 13),
    );
    final doc =
        MaintainiacFirestoreDocumentBuilder.expenseTelemetrySummaryDocument(
          orgId: 'ORG-1',
          summaryId: 'latest',
          snapshot: snapshot,
          maxFailureBreakdowns: 20,
          maxRecentFailureDetails: 20,
        );
    final serialized = _stringifyFirestorePayloadValues(doc.data).toLowerCase();

    for (final rawPrivateHint in const [
      'shell',
      'jiffy',
      'lube',
      'walmart',
      'home',
      'depot',
      '45.67',
      '45_67',
      '89.99',
      '89_99',
      '12.34',
      '12_34',
      '109.23',
      '109_23',
      '982334455',
      '998877',
      '036000291452',
      '123456789',
      '5715',
      '777888999',
      '545454',
      '123456789012',
      '112233',
      '555666777',
      '444555666',
    ]) {
      expect(serialized, isNot(contains(rawPrivateHint)));
    }
    expect(serialized, contains('merchant'));
    expect(serialized, contains('amount'));
    expect(serialized, contains('number'));
    expect((doc.data['failureBreakdowns'] as List), hasLength(cases.length));
    expect((doc.data['recentFailureDetails'] as List), hasLength(cases.length));
  });

  test('keeps redaction scoped to failure detail fields', () {
    final snapshot = ExpenseTelemetryHealthSnapshot.fromRecords([
      ExpenseTelemetryRecord(
        id: 'evt-redaction-boundary',
        queuedAtUtc: DateTime.utc(2026, 6, 24, 12),
        payload: ExpenseTelemetryPolicy.sanitizeMap({
          'event': 'ocrFailed',
          'workflowStep': 'receiptOcr',
          'failedAt': 'shell_total_45_67_ticket_982334455',
          'confirmedCause': 'shell_total_45_67_ocr_failed',
          'causeStatus': 'confirmed',
          'evidence': 'source_photo_shell_receipt_982334455_total_45_67',
          'missingEvidence': 'terminal_123456',
          'platform': 'android',
          'deviceTier': 'high',
          'appVersion': '5.6.0',
        }),
      ),
    ], generatedAtUtc: DateTime.utc(2026, 6, 24, 13));

    final doc =
        MaintainiacFirestoreDocumentBuilder.expenseTelemetrySummaryDocument(
          orgId: 'ORG-1',
          summaryId: 'latest',
          snapshot: snapshot,
        );
    final failureBreakdown =
        (doc.data['failureBreakdowns'] as List).single as Map<String, Object?>;

    expect(doc.data['platformCounts'], {'android': 1});
    expect(doc.data['deviceTierCounts'], {'high': 1});
    expect(doc.data['topOcrFailureSource'], 'photo');
    expect(failureBreakdown['appVersionCounts'], {'5_6_0': 1});
    expect(failureBreakdown['platformCounts'], {'android': 1});
    expect(
      failureBreakdown['confirmedCause'],
      'merchant_total_amount_ocr_failed',
    );
    expect(failureBreakdown['failedAt'], 'merchant_total_amount_ticket_number');
    expect(
      failureBreakdown['evidence'],
      'source_photo_merchant_private_reference_total_amount',
    );
    expect(failureBreakdown['missingEvidence'], 'private_reference');
  });

  test('keeps Firestore redaction helper fields aligned with contract', () {
    final source = [
      'lib/shared/firebase/maintainiac_firestore_documents.dart',
      'lib/shared/firebase/maintainiac_firestore_expense_telemetry_redactor.dart',
    ].map((path) => File(path).readAsStringSync()).join('\n');

    expect(source, contains('class _ExpenseTelemetryFirestoreRedactor'));
    expect(source, contains('privateReceiptHintTokenFields'));
    expect(source, contains('privateReceiptHintMapFields'));
    for (final field in expectedExpenseTelemetryRedactedTokenFields) {
      expect(
        source,
        contains("'$field'"),
        reason: 'Redacted token field `$field` must stay in the helper.',
      );
    }
    for (final field in expectedExpenseTelemetryRedactedMapFields) {
      expect(
        source,
        contains("'$field'"),
        reason: 'Redacted map field `$field` must stay in the helper.',
      );
    }
    for (final unredactedOperationalField in const {
      'platform',
      'deviceTier',
      'appVersion',
      'topOcrFailureSource',
      'appVersionCounts',
    }) {
      expect(
        expectedExpenseTelemetryRedactedTokenFields,
        isNot(contains(unredactedOperationalField)),
        reason: '`$unredactedOperationalField` should not be over-redacted.',
      );
      expect(
        expectedExpenseTelemetryRedactedMapFields,
        isNot(contains(unredactedOperationalField)),
        reason: '`$unredactedOperationalField` should not be over-redacted.',
      );
    }
  });
}

String _stringifyFirestorePayloadValues(
  Object? value, {
  bool includeMapKeys = false,
}) {
  if (value is Map) {
    final parts = <String>[];
    for (final entry in value.entries) {
      if (includeMapKeys) {
        parts.add(entry.key.toString());
      }
      parts.add(
        _stringifyFirestorePayloadValues(entry.value, includeMapKeys: true),
      );
    }
    return parts.join(' ');
  }
  if (value is Iterable) {
    return [
      for (final item in value)
        _stringifyFirestorePayloadValues(item, includeMapKeys: true),
    ].join(' ');
  }
  return value?.toString() ?? '';
}

ExpenseTelemetryHealthSnapshot _expenseTelemetryFailureSnapshot(int count) {
  final records = [
    for (var index = 0; index < count; index += 1)
      ExpenseTelemetryRecord(
        id: 'evt_failure_$index',
        queuedAtUtc: DateTime.utc(2026, 6, 24, 12, index),
        payload: ExpenseTelemetryPolicy.sanitize(
          ExpenseTelemetryEvent(
            type: ExpenseTelemetryEventType.ocrFailed,
            failureKind: 'receipt_failure_$index',
            diagnostic: ExpenseFailureDiagnostic(
              workflowStep: ExpenseWorkflowStep.receiptOcr,
              failedAt: 'after_capture_before_parser_$index',
              confirmedCause: 'receipt_failure_$index',
              causeStatus: ExpenseFailureCauseStatus.confirmed,
              evidence: 'ocr_severity_blocked_source_photo_$index',
              missingEvidence: 'none',
              retryCount: index % 3,
              abandoned: index.isOdd,
            ),
          ),
        ),
      ),
  ];
  return ExpenseTelemetryHealthSnapshot.fromRecords(
    records,
    generatedAtUtc: DateTime.utc(2026, 6, 24, 13),
  );
}
