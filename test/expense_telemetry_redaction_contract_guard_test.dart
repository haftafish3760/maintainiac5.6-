import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_screen_telemetry.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_documents.dart';

import 'helpers/expense_telemetry_schema_expectations.dart';
import 'helpers/expense_telemetry_redaction_guard_helpers.dart';

void main() {
  test('Firestore redaction helper matches documented field contract', () {
    final source = readDartLibraryWithParts(
      'lib/shared/firebase/maintainiac_firestore_documents.dart',
    );
    final ocrContract = File(
      'docs/expense_command_center_ocr_contract.md',
    ).readAsStringSync();
    final syncSpec = [
      'docs/firebase_sync_schema_spec.md',
      'docs/firebase_sync_receipt_expense_schema_spec.md',
    ].map((path) => File(path).readAsStringSync()).join('\n');

    expect(source, contains('class _ExpenseTelemetryFirestoreRedactor'));
    expect(source, contains('privateReceiptHintTokenFields'));
    expect(source, contains('privateReceiptHintMapFields'));
    expect(source, contains("key == 'actionSummary'"));
    expect(ocrContract, contains('_ExpenseTelemetryFirestoreRedactor'));
    expect(ocrContract, contains('`actionSummary`'));
    expect(syncSpec, contains('_ExpenseTelemetryFirestoreRedactor'));
    expect(syncSpec, contains('`actionSummary`'));

    for (final field in expectedExpenseTelemetryRedactedTokenFields) {
      expect(source, contains("'$field'"));
      expect(ocrContract, contains('`$field`'));
      expect(syncSpec, contains('`$field`'));
    }
    for (final field in expectedExpenseTelemetryRedactedMapFields) {
      expect(source, contains("'$field'"));
      expect(ocrContract, contains('`$field`'));
      expect(syncSpec, contains('`$field`'));
    }

    for (final operationalField in const {
      'platform',
      'deviceTier',
      'appVersion',
      'topOcrFailureSource',
      'appVersionCounts',
    }) {
      expect(
        expectedExpenseTelemetryRedactedTokenFields,
        isNot(contains(operationalField)),
      );
      expect(
        expectedExpenseTelemetryRedactedMapFields,
        isNot(contains(operationalField)),
      );
    }
  });

  test('scrubs regional vendor hints from Firestore failure diagnostics', () {
    final records = <ExpenseTelemetryRecord>[];
    final cases = [
      (
        event: 'ocrFailed',
        failedAt: 'pilot_flying_j_total_67_89_receipt_123456789',
        cause: 'pilot_flying_j_auth_765432_ocr_failed',
        evidence: 'source_photo_pilot_flying_j_barcode_036000291452',
        missing: 'terminal_222333',
      ),
      (
        event: 'parserFailed',
        failedAt: 'loves_travel_stop_invoice_998877_total_54_32',
        cause: 'love_s_travel_stop_receipt_total_54_32',
        evidence: 'source_photo_love_s_receipt_998877',
        missing: 'transaction_333444555',
      ),
      (
        event: 'imageAttachFailure',
        failedAt: 'caseys_general_store_total_11_22',
        cause: 'casey_s_receipt_444333_decode_failed',
        evidence: 'source_photo_caseys_general_store_upc_123456789012',
        missing: 'authcode_112233',
      ),
      (
        event: 'saveFailure',
        failedAt: 'kwik_trip_invoice_888777_total_22_10',
        cause: 'kwik_trip_order_888777_save_failed',
        evidence: 'source_photo_kwik_trip_receipt_888777_total_22_10',
        missing: 'invoice_444555666',
      ),
      (
        event: 'ocrFailed',
        failedAt: 'tractor_supply_receipt_444333_total_98_76',
        cause: 'tractor_supply_order_444333_ocr_failed',
        evidence: 'source_photo_tractor_supply_sku_123123123',
        missing: 'terminal_565656',
      ),
      (
        event: 'parserFailed',
        failedAt: 'harbor_freight_order_111222_total_42_00',
        cause: 'harbor_freight_receipt_111222_parse_failed',
        evidence: 'source_photo_harbor_freight_receipt_111222',
        missing: 'transaction_121212',
      ),
      (
        event: 'imageAttachFailure',
        failedAt: 'valvoline_service_total_59_99',
        cause: 'take_5_oil_change_invoice_123123',
        evidence: 'source_photo_firestone_invoice_998877',
        missing: 'auth_778899',
      ),
    ];

    for (var index = 0; index < cases.length; index += 1) {
      final testCase = cases[index];
      records.add(
        ExpenseTelemetryRecord(
          id: 'evt-regional-redaction-$index',
          queuedAtUtc: DateTime.utc(2026, 6, 28, 12, index),
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
            'deviceTier': index.isEven ? 'high' : 'mid',
            'appVersion': '5.6.$index',
          }),
        ),
      );
    }

    final snapshot = ExpenseTelemetryHealthSnapshot.fromRecords(
      records,
      generatedAtUtc: DateTime.utc(2026, 6, 28, 13),
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

    for (final rawPrivateHint in const [
      'pilot',
      'flying',
      'loves',
      'love_s',
      'caseys',
      'casey_s',
      'kwik',
      'tractor',
      'harbor',
      'freight',
      'valvoline',
      'firestone',
      'take_5',
      '67_89',
      '54_32',
      '11_22',
      '22_10',
      '98_76',
      '42_00',
      '59_99',
      '123456789',
      '765432',
      '036000291452',
      '998877',
      '333444555',
      '444333',
      '123456789012',
      '888777',
      '444555666',
      '123123123',
      '111222',
      '121212',
      '123123',
      '778899',
    ]) {
      expect(serialized, isNot(contains(rawPrivateHint)));
    }
    expect(serialized, contains('merchant'));
    expect(serialized, contains('amount'));
    expect(serialized, contains('number'));
    expect((doc.data['failureBreakdowns'] as List), hasLength(cases.length));
    expect((doc.data['recentFailureDetails'] as List), hasLength(cases.length));
  });
}
