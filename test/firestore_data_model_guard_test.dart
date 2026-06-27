import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

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
