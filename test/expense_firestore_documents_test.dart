import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/expenses/data/expense_firestore_documents.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_job_store.dart';
import 'package:maintaniac/screens/expenses/data/expense_reminder_store.dart';
import 'package:maintaniac/screens/expenses/data/expense_work_profile_store.dart';
import 'package:maintaniac/screens/expenses/data/expense_vehicle_profile_store.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_deletion_store.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_schema.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_upload_queue.dart';
import 'package:maintaniac/shared/state/expense_settings_store.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'expense_firestore_documents_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  test('builds expense receipt backup without raw OCR or local proof paths', () {
    final receipt = ExpenseReceiptRecord(
      id: 'receipt 1',
      receiptDate: DateTime.utc(2026, 6, 24),
      receiptTimeMinutes: 9 * 60 + 30,
      merchantName: 'Local Hardware',
      rawOcrText: 'RAW PRIVATE OCR TEXT SHOULD NOT SYNC',
      enteredTotal: 42.25,
      vehicleId: 'truck-1',
      contextSnapshot: const ExpenseReceiptContextSnapshot(
        workProfileId: 'contractor',
        workProfileName: 'Home repairs',
        vehicleId: 'truck-1',
        vehicleLabel: 'Work Truck',
        jobId: 'job-1',
        jobLabel: 'Kitchen repair',
      ),
      odometerReading: 150125,
      hasReceiptProof: true,
      ocrReview: const ExpenseReceiptOcrReview(
        severity: 'review',
        source: 'photo',
        warningKinds: ['sectionGap'],
        warningKindCounts: {'sectionGap': 1},
        primaryWarningKind: 'sectionGap',
        primaryWarningLabelOverride: 'Possible missing receipt section',
        primaryWarningTargetLabel: 'Check missing receipt section',
        primaryWarningTargetInstruction:
            'Check the receipt photos from top to bottom and add the missing middle section if needed.',
        recoveryAction: 'add_missing_section',
        recoveryTarget: 'receipt_sections',
        recoverySummary:
            'Add the missing receipt section or confirm the photos are in order.',
        warningCount: 1,
        reviewWarningCount: 1,
        attachmentsRead: 2,
        rawLineCount: 12,
        parserLineCount: 12,
        hadDuplicateOrOverlapText: true,
      ),
      attachments: [
        ReceiptAttachmentRecord(
          id: 'proof 1',
          path: '/private/local/receipt.jpg',
          kind: ReceiptAttachmentKind.photo,
          dataSaverLevel: ReceiptDataSaverLevel.balanced,
          createdAt: DateTime.utc(2026, 6, 24, 10),
          importedText: 'PRIVATE IMPORTED TEXT',
          byteSize: 12345,
          fileHash: 'ABCDEF123456',
        ),
      ],
      lines: const [
        ExpenseReceiptLineRecord(
          id: 'line 1',
          description: 'Hammer',
          category: 'Tools',
          use: ExpenseLineUse.business,
          quantity: 1,
          unitsPerPackage: 1,
          unit: 'each',
          subtotal: 42.25,
          rawReceiptText: 'RAW LINE TEXT',
          parserConfidence: .91,
        ),
      ],
    );

    final doc = ExpenseFirestoreDocumentBuilder.expenseReceiptDocument(
      orgId: 'ORG-1',
      uid: 'USER-1',
      deviceId: 'DEVICE-1',
      receipt: receipt,
      nowUtc: DateTime.utc(2026, 6, 24, 12),
    );

    expect(
      doc.path,
      'orgs/ORG-1/${MaintainiacFirestoreSchema.orgExpenses}/receipt_1',
    );
    expect(doc.data['schema'], 'expense_receipt_backup_v1');
    expect(doc.data['merchantName'], 'Local Hardware');
    expect(doc.data['enteredTotalCents'], 4225);
    expect(doc.data['vehicleId'], 'truck-1');
    expect(doc.data['context'], {
      'workProfileId': 'contractor',
      'workProfileName': 'Home repairs',
      'vehicleId': 'truck-1',
      'vehicleLabel': 'Work Truck',
      'jobId': 'job-1',
      'jobLabel': 'Kitchen repair',
    });
    expect(doc.data['odometerReading'], 150125);
    expect((doc.data['lines'] as List).single.toString(), contains('Hammer'));
    final line = (doc.data['lines'] as List).single as Map<String, Object?>;
    expect(line['splitAllocationMethod'], 'percentage');
    expect(line['splitConfirmed'], isTrue);
    expect(doc.data['rawOcrStored'], isFalse);
    final ocrReview = doc.data['ocrReview'] as Map<String, Object?>;
    expect(ocrReview['warningKindCounts'], {'sectionGap': 1});
    expect(ocrReview['primaryWarningKind'], 'sectionGap');
    expect(ocrReview['recoveryAction'], 'add_missing_section');
    expect(ocrReview['recoveryTarget'], 'receipt_sections');
    expect(
      ocrReview['recoverySummary'],
      contains('receipt photos from top to bottom'),
    );
    expect(
      ocrReview['primaryWarningTargetLabel'],
      'Check missing receipt section',
    );
    final commandSummary =
        ocrReview['commandCenterSummary'] as Map<String, Object?>;
    expect(commandSummary['source'], 'photo');
    expect(commandSummary['primaryWarningKind'], 'sectionGap');
    expect(commandSummary['recoveryAction'], 'add_missing_section');
    expect(commandSummary['recoveryTarget'], 'receipt_sections');
    expect(commandSummary['primaryIssue'], 'Check missing receipt section');
    expect(
      commandSummary['primaryAction'],
      contains('receipt photos from top to bottom'),
    );
    expect(ocrReview['hadDuplicateOrOverlapText'], isTrue);
    final proof = (doc.data['proofs'] as List).single as Map<String, Object?>;
    expect(proof.toString(), contains('proofs'));
    expect(proof['byteSize'], 12345);
    expect(proof['backupByteSize'], 12345);
    expect(proof['backupSizeBucket'], 'tiny_under_100kb');
    expect(proof['dataSaverLevel'], 'balanced');
    expect(proof['localPathStored'], isFalse);

    final encoded = doc.data.toString();
    expect(encoded, isNot(contains('RAW PRIVATE OCR TEXT')));
    expect(encoded, isNot(contains('/private/local')));
    expect(encoded, isNot(contains('PRIVATE IMPORTED TEXT')));
    expect(encoded, isNot(contains('RAW LINE TEXT')));
    MaintainiacFirestoreUploadPolicy.validateDraft(doc);
  });

  test('builds one recap/settings backup document for the member', () async {
    final settings = await ExpenseSettingsController.create();
    await settings.setRecapTileVisible('fuelSpend', false);
    await settings.setRecapTileVisible('materialsSpend', false);

    final doc = ExpenseFirestoreDocumentBuilder.expenseSettingsDocument(
      orgId: 'ORG-1',
      uid: 'USER-1',
      deviceId: 'DEVICE-1',
      settings: settings,
      nowUtc: DateTime.utc(2026, 6, 24, 12),
    );

    expect(
      doc.path,
      'orgs/ORG-1/${MaintainiacFirestoreSchema.orgSettings}/expenses_USER-1',
    );
    expect(doc.data['schema'], 'expense_settings_v1');
    expect(doc.data['module'], 'expenses');
    expect(doc.data['uploadShape'], 'single_settings_document');
    expect(doc.data['hiddenRecapTiles'], ['fuelSpend', 'materialsSpend']);
    MaintainiacFirestoreUploadPolicy.validateDraft(doc);
  });

  test('backs up reminders in their own member-scoped document', () async {
    final reminders = ExpenseReminderController.memory();
    final now = DateTime.utc(2026, 6, 24, 12);
    await reminders.save(
      ExpenseReminderRecord(
        id: 'REM-1',
        title: 'Insurance renewal',
        category: 'Insurance',
        dueAt: DateTime.utc(2026, 7, 1),
        frequency: ExpenseReminderFrequency.yearly,
        channel: ExpenseReminderChannel.inApp,
        createdAt: now,
        updatedAt: now,
      ),
    );
    final doc = ExpenseFirestoreDocumentBuilder.expenseRemindersDocument(
      orgId: 'ORG-1',
      uid: 'USER-1',
      deviceId: 'DEVICE-1',
      reminders: reminders,
      nowUtc: now,
    );
    expect(doc.data['schema'], 'expense_reminders_v1');
    expect(doc.data['uploadShape'], 'single_reminders_document');
    expect(
      (doc.data['reminders'] as List).single.toString(),
      contains('Insurance renewal'),
    );
    MaintainiacFirestoreUploadPolicy.validateDraft(doc);
  });

  test(
    'backs up jobs and work profiles as separate member documents',
    () async {
      final now = DateTime.utc(2026, 6, 24, 12);
      final jobs = ExpenseJobController.memory();
      final profiles = ExpenseWorkProfileController.memory();
      final vehicles = ExpenseVehicleProfileController.memory();
      await jobs.save(
        ExpenseJobRecord(
          id: 'JOB-1',
          name: 'Kitchen repair',
          workProfileId: 'contractor',
          vehicleId: 'truck-1',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await profiles.save(
        ExpenseWorkProfileRecord(
          id: 'contractor',
          name: 'Contractor',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await vehicles.ensureProfile(id: 'truck-1', nickname: 'Work Truck');
      final jobsDoc = ExpenseFirestoreDocumentBuilder.expenseJobsDocument(
        orgId: 'ORG-1',
        uid: 'USER-1',
        deviceId: 'DEVICE-1',
        jobs: jobs,
        nowUtc: now,
      );
      final profilesDoc =
          ExpenseFirestoreDocumentBuilder.expenseWorkProfilesDocument(
            orgId: 'ORG-1',
            uid: 'USER-1',
            deviceId: 'DEVICE-1',
            profiles: profiles,
            nowUtc: now,
          );
      final vehiclesDoc =
          ExpenseFirestoreDocumentBuilder.expenseVehicleProfilesDocument(
            orgId: 'ORG-1',
            uid: 'USER-1',
            deviceId: 'DEVICE-1',
            profiles: vehicles,
            nowUtc: now,
          );
      expect(jobsDoc.data['schema'], 'expense_jobs_v1');
      expect(jobsDoc.data['uploadShape'], 'single_jobs_document');
      expect(
        (jobsDoc.data['jobs'] as List).single.toString(),
        contains('Kitchen repair'),
      );
      expect(profilesDoc.data['schema'], 'expense_work_profiles_v1');
      expect(profilesDoc.data['uploadShape'], 'single_work_profiles_document');
      expect(
        (profilesDoc.data['profiles'] as List).single.toString(),
        contains('Contractor'),
      );
      expect(vehiclesDoc.data['schema'], 'expense_vehicle_profiles_v1');
      expect(
        vehiclesDoc.data['uploadShape'],
        'single_vehicle_profiles_document',
      );
      expect(
        (vehiclesDoc.data['profiles'] as List).single.toString(),
        contains('Work Truck'),
      );
      MaintainiacFirestoreUploadPolicy.validateDraft(jobsDoc);
      MaintainiacFirestoreUploadPolicy.validateDraft(profilesDoc);
      MaintainiacFirestoreUploadPolicy.validateDraft(vehiclesDoc);
    },
  );

  test('builds a constrained receipt tombstone for a local deletion', () {
    final doc = ExpenseFirestoreDocumentBuilder.expenseReceiptTombstoneDocument(
      orgId: 'ORG-1',
      uid: 'USER-1',
      deviceId: 'DEVICE-1',
      deletion: ExpenseReceiptDeletionRecord(
        receiptId: 'EXP-1',
        deletedAt: DateTime.utc(2026, 7, 15, 3),
      ),
    );
    expect(doc.path, 'orgs/ORG-1/expenses/EXP-1');
    expect(doc.data['tombstone'], isTrue);
    expect(doc.data['rawOcrStored'], isFalse);
    expect(doc.data['cloudRevision'], 0);
    expect(doc.data['deletedAt'], '2026-07-15T03:00:00.000Z');
    MaintainiacFirestoreUploadPolicy.validateDraft(doc);
  });
}
