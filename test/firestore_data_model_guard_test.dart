import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'helpers/expense_telemetry_schema_expectations.dart';

void main() {
  group('Firestore data model guard', () {
    test('Firebase config includes Firestore rules and indexes', () {
      final config =
          jsonDecode(File('firebase.json').readAsStringSync())
              as Map<String, Object?>;
      final firestore = config['firestore'] as Map<String, Object?>;

      expect(firestore['rules'], 'firestore.rules');
      expect(firestore['indexes'], 'firestore.indexes.json');
      expect(File('firestore.indexes.json').existsSync(), isTrue);
    });

    test('index file covers first-release collection groups', () {
      final indexesJson =
          jsonDecode(File('firestore.indexes.json').readAsStringSync())
              as Map<String, Object?>;
      final indexes = indexesJson['indexes'] as List<Object?>;
      final groups = indexes
          .whereType<Map<String, Object?>>()
          .map((index) => index['collectionGroup'])
          .whereType<String>()
          .toSet();

      expect(
        groups,
        containsAll({
          'expenses',
          'mileageRecords',
          'jobs',
          'estimates',
          'invoices',
          'inventoryItems',
          'inventoryTransactions',
          'maintenanceRecords',
          'auditEvents',
          'invites',
          'manifests',
          'receiptDiagnostics',
          'expenseTelemetrySummaries',
        }),
      );
    });

    test('docs lock NAM7 and production safety rules', () {
      final model = File('docs/firestore_data_model.md').readAsStringSync();
      final checklist = File(
        'docs/firebase_production_deploy_checklist.md',
      ).readAsStringSync();

      expect(model, contains('NAM7'));
      expect(checklist, contains('NAM7'));
      expect(checklist, contains('Do not seed production'));
      expect(checklist, contains('Do not enable Firestore test mode'));
      expect(checklist, contains('explicit owner approval'));
    });

    test('Firestore rules forbid high-risk sensitive fields', () {
      final rules = File('firestore.rules').readAsStringSync();

      for (final field in _forbiddenFields) {
        expect(rules, contains("'$field'"));
      }
      expect(rules, contains('noForbiddenSensitiveFields'));
    });

    test('Firestore rules expose hosted catalog manifests read-only', () {
      final rules = File('firestore.rules').readAsStringSync();

      expect(rules, contains('match /catalogPacks/{packId}'));
      expect(rules, contains('match /manifests/{versionId}'));
      expect(rules, contains('match /vendorRegistry/{vendorId}'));
      expect(rules, contains('match /parserHealth/{parserVersion}'));
      expect(rules, contains('match /expenseTelemetrySummaries/{summaryId}'));
      expect(rules, contains('match /catalogHealth/{healthId}'));
      expect(
        rules,
        contains('match /sharedCorrectionCandidates/{candidateId}'),
      );
      expect(rules, isNot(contains('match /tradePacks/{packId}')));
    });

    test('AI abuse security collections stay server-only', () {
      final rules = File('firestore.rules').readAsStringSync();
      final contract = File(
        'docs/account_creation_gate_contract.md',
      ).readAsStringSync();
      final model = File('docs/firestore_data_model.md').readAsStringSync();

      for (final collection in [
        'aiAbuseSecurityEvents',
        'aiEnforcementActions',
      ]) {
        expect(rules, contains('match /$collection/'));
        expect(contract, contains('$collection/{'));
        expect(model, contains('$collection/{'));
      }
      expect(model, contains('raw prompts'));
      expect(model, contains('AI abuse/security collections'));
    });

    test('docs keep OCR Command Center health on one summary document', () {
      final syncSpec = File(
        'docs/firebase_sync_schema_spec.md',
      ).readAsStringSync();
      final expenseSpec = File(
        'docs/expense_screen_full_design.md',
      ).readAsStringSync();
      final ocrContract = File(
        'docs/expense_command_center_ocr_contract.md',
      ).readAsStringSync();

      for (final doc in [syncSpec, expenseSpec, ocrContract]) {
        expect(
          doc,
          contains('orgs/{orgId}/expenseTelemetrySummaries/{summaryId}'),
        );
        expect(doc, contains('commandCenterOcrContract'));
        expect(doc, contains('single_summary_document'));
      }

      expect(syncSpec, contains('rawEventUploadCount'));
      expect(syncSpec, contains('commandCenterOcrContractFindingsFor'));
      expect(
        syncSpec,
        contains('ExpenseTelemetryHealthSnapshot.toCommandCenterMap'),
      );
      expect(
        syncSpec,
        contains(
          'keeps every Command Center telemetry field in Firestore summary',
        ),
      );
      expect(syncSpec, contains('must not be moved into per-event'));
      expect(syncSpec, contains('local-first telemetry'));
      expect(syncSpec, contains('15-minute scheduler interval'));
      expect(
        syncSpec,
        contains(
          '96 scheduled expense telemetry summary writes per org per day',
        ),
      );
      expect(syncSpec, contains('20,000 Firestore writes per day'));
      expect(
        syncSpec,
        contains(
          'per-capture, per-failure, per-retry, per-line, or per-receipt writes',
        ),
      );
      expect(syncSpec, contains('replace the pending'));
      expect(syncSpec, contains('one bounded Firestore summary'));
      expect(syncSpec, contains('expense telemetry schema change checklist'));
      expect(syncSpec, contains('_sanitizeExpenseTelemetryMap'));
      expect(
        syncSpec,
        contains('test/helpers/expense_telemetry_schema_expectations.dart'),
      );
      expect(syncSpec, contains('Firestore wrapper metadata'));
      expect(syncSpec, contains('summaryId'));
      expect(syncSpec, contains('summaryScope'));
      expect(
        syncSpec,
        contains('must stay out of the local Command Center telemetry schema'),
      );
      expect(syncSpec, contains('nonnegative counts'));
      expect(syncSpec, contains('finite nonnegative'));
      expect(syncSpec, contains('reject negative scalar counts'));
      expect(syncSpec, contains('infinite rates'));
      expect(syncSpec, contains('failureBreakdowns'));
      expect(syncSpec, contains('hard cap of 50'));
      expect(syncSpec, contains('recentFailureDetails'));
      expect(syncSpec, contains('hard cap of 100'));
      expect(syncSpec, contains('not raw event history'));
      expect(syncSpec, contains('Expense Failure Drill-Down Object Schemas'));
      expect(syncSpec, contains('missingEvidence` as `none`'));
      expect(syncSpec, contains('raw private receipt content'));
      expect(syncSpec, contains('Nested OCR failure objects'));
      expect(syncSpec, contains('ocrFailureSource'));
      expect(syncSpec, contains('ocrFailureSourceAction'));
      expect(syncSpec, contains('Non-OCR failures'));
      expect(syncSpec, contains('poisoned source labels'));
      expect(syncSpec, contains('barcode-like values'));
      expect(syncSpec, contains('Failure diagnostic machine-token fields'));
      expect(syncSpec, contains('grouping, filtering, and action routing'));
      expect(syncSpec, contains('Known merchant names become `merchant`'));
      expect(syncSpec, contains('common receipt locations become `location`'));
      expect(syncSpec, contains('money-like values become `amount`'));
      expect(
        syncSpec,
        contains('receipt/auth/transaction-length numbers can become `number`'),
      );
      expect(syncSpec, contains('private_reference'));
      expect(syncSpec, contains('Visible drill-down fields'));
      expect(syncSpec, contains('failedAtLabel'));
      expect(syncSpec, contains('causeLabel'));
      expect(syncSpec, contains('evidenceLabel'));
      expect(syncSpec, contains('missingEvidenceLabel'));
      expect(syncSpec, contains('raw snake-case tokens'));
      expect(syncSpec, contains('map machine tokens to UI copy'));
      expect(
        syncSpec,
        contains('fuel, retail, and auto-service stress examples'),
      );
      expect(syncSpec, contains('Shell, Walmart, Home Depot, Jiffy Lube'));
      expect(syncSpec, contains('Pilot/Flying J, Love\'s, Casey\'s'));
      expect(syncSpec, contains('Kwik Trip'));
      expect(syncSpec, contains('Tractor Supply'));
      expect(syncSpec, contains('Harbor Freight'));
      expect(syncSpec, contains('Valvoline'));
      expect(syncSpec, contains('Take 5'));
      expect(syncSpec, contains('Firestone'));
      expect(syncSpec, contains('UPC/barcode-like numbers'));
      expect(syncSpec, contains('underscore-separated totals'));
      expect(syncSpec, contains('_ExpenseTelemetryFirestoreRedactor'));
      expect(syncSpec, contains('failure token fields'));
      expect(syncSpec, contains('failure count-map fields'));
      expect(syncSpec, contains('source-isolated'));
      expect(syncSpec, contains('ocrFailureSourceCounts'));
      expect(syncSpec, contains('topOcrFailureSource'));
      expect(syncSpec, contains('photo'));
      expect(syncSpec, contains('importedtext'));
      expect(syncSpec, contains('Unknown `source_*` labels'));
      expect(syncSpec, contains('topOcrFailureSourceAction'));
      expect(syncSpec, contains('camera focus/exposure/crop/order'));
      expect(syncSpec, contains('safety/size/render/page extraction'));
      expect(syncSpec, contains('imported text cleanup'));
      expect(
        syncSpec,
        contains('source selection/order/duplicate suppression'),
      );
      expect(syncSpec, contains('safe source tagging'));
      expect(syncSpec, contains('final Firestore sanitizer'));
      expect(syncSpec, contains('bounded'));
      expect(syncSpec, contains('actionSummary'));
      expect(syncSpec, contains('readable after'));
      expect(syncSpec, contains('lowercase token'));
      expect(syncSpec, contains('auth numbers'));
      expect(syncSpec, contains('receipt numbers'));
      expect(syncSpec, contains('source tokens'));
      expect(syncSpec, contains('actionable without preserving'));
      expect(syncSpec, contains('source_camera'));
      expect(syncSpec, contains('source_image'));
      expect(syncSpec, contains('source_document'));
      expect(syncSpec, contains('source_pasted_text'));
      expect(syncSpec, contains('source_combined'));
      expect(syncSpec, contains('source_missing'));
      expect(syncSpec, contains('malformed private source labels'));
      expect(syncSpec, contains('non-OCR drill-down rows'));
      expect(syncSpec, contains('tokenization'));
      expect(syncSpec, contains('store names, exact totals'));
      for (final field in expectedExpenseTelemetryRedactedTokenFields) {
        expect(syncSpec, contains(field));
      }
      for (final field in expectedExpenseTelemetryRedactedMapFields) {
        expect(syncSpec, contains(field));
      }
      expect(syncSpec, contains('topOcrFailureSource'));
      expect(syncSpec, contains('appVersionCounts'));
      expect(syncSpec, contains('ExpenseTelemetrySummaryScheduler.queueIfDue'));
      expect(syncSpec, contains('includeLedgerOcrContract'));
      expect(syncSpec, contains('ExpenseScreenTelemetryRecorder'));
      expect(syncSpec, contains('expense_summary_queued'));
      expect(syncSpec, contains('ocrContractQueued'));
      expect(syncSpec, contains('ocrContractSource'));
      expect(syncSpec, contains('expenseSummaryQueuedCount'));
      expect(syncSpec, contains('expenseSummaryOcrContractQueuedCount'));
      expect(syncSpec, contains('expenseSummaryOcrContractSkippedCount'));
      expect(syncSpec, contains('expenseSummaryOcrContractSourceCounts'));
      expect(syncSpec, contains('topExpenseSummaryOcrContractSource'));
      expect(
        syncSpec,
        contains('expenseSummaryOcrContractSkippedReasonCounts'),
      );
      expect(syncSpec, contains('topExpenseSummaryOcrContractSkippedReason'));
      expect(syncSpec, contains('must not create a separate scheduler trace'));
      expect(syncSpec, contains('Throttled scheduler checks'));
      expect(expenseSpec, contains('no per-receipt admin health writes'));
      expect(ocrContract, contains('no per-receipt Command 1 documents'));
      expect(ocrContract, contains('no Firestore read per receipt'));
    });
  });
}

const _forbiddenFields = [
  'vin',
  'VIN',
  'vehicleIdentificationNumber',
  'licensePlate',
  'plate',
  'plateNumber',
  'tagNumber',
  'passengerName',
  'passengerPhone',
  'passengerAddress',
  'patientName',
  'patientPhone',
  'patientAddress',
  'medicalRecordNumber',
  'diagnosis',
  'dateOfBirth',
  'dob',
];
