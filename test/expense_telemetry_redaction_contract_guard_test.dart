import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_screen_telemetry.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_documents.dart';

import 'helpers/expense_telemetry_schema_expectations.dart';

void main() {
  test('Firestore redaction helper matches documented field contract', () {
    final source = File(
      'lib/shared/firebase/maintainiac_firestore_documents.dart',
    ).readAsStringSync();
    final ocrContract = File(
      'docs/expense_command_center_ocr_contract.md',
    ).readAsStringSync();
    final syncSpec = File(
      'docs/firebase_sync_schema_spec.md',
    ).readAsStringSync();

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

  test(
    'OCR source bucket contract stays aligned across docs and Firestore',
    () {
      final telemetrySource = File(
        'lib/screens/expenses/data/expense_screen_telemetry.dart',
      ).readAsStringSync();
      final ocrContract = File(
        'docs/expense_command_center_ocr_contract.md',
      ).readAsStringSync();
      final syncSpec = File(
        'docs/firebase_sync_schema_spec.md',
      ).readAsStringSync();

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
      expect(doc.data.toString().toLowerCase(), isNot(contains('lowes')));
      expect(doc.data.toString().toLowerCase(), isNot(contains('3_24')));
    },
  );

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
    final serialized = doc.data.toString().toLowerCase();

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
    final serialized = doc.data.toString().toLowerCase();

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
      final serialized = doc.data.toString().toLowerCase();

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
    final serialized = doc.data.toString().toLowerCase();

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
    final serialized = doc.data.toString().toLowerCase();

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
    final serialized = doc.data.toString().toLowerCase();

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
      final serialized = doc.data.toString().toLowerCase();

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
    final serialized = doc.data.toString().toLowerCase();

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
