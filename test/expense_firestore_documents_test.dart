import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/records/maintainiac_record_lifecycle.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/expenses/data/expense_firestore_documents.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_work_profile_store.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_schema.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_upload_queue.dart';
import 'package:maintaniac/shared/state/app_state.dart';
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
      workProfileId: 'evening-delivery',
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
    expect(doc.data['workProfileId'], 'evening-delivery');
    expect(doc.data['odometerReading'], 150125);
    expect((doc.data['lines'] as List).single.toString(), contains('Hammer'));
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

  test('persists fuel metrics without storing raw receipt text', () {
    final receipt = ExpenseReceiptRecord(
      id: 'fuel-receipt',
      receiptDate: DateTime(2026, 7, 13),
      merchantName: 'Fuel Stop',
      vehicleId: 'truck-1',
      odometerReading: 120500,
      lines: const [
        ExpenseReceiptLineRecord(
          id: 'fuel-line',
          description: 'Regular 87',
          category: 'Fuel',
          use: ExpenseLineUse.business,
          quantity: 14.25,
          unitsPerPackage: 1,
          unit: 'gallon',
          subtotal: 48.31,
          odometerReading: 120500,
          fuelType: 'Gasoline',
          fillType: 'Partial fill',
          unitPrice: 3.39,
          rawReceiptText: 'PRIVATE FUEL RECEIPT TEXT',
        ),
      ],
    );

    final doc = ExpenseFirestoreDocumentBuilder.expenseReceiptDocument(
      orgId: 'ORG-1',
      uid: 'USER-1',
      deviceId: 'DEVICE-1',
      receipt: receipt,
      nowUtc: DateTime.utc(2026, 7, 13),
    );
    final line = (doc.data['lines'] as List).single as Map<String, Object?>;

    expect(doc.data['vehicleId'], 'truck-1');
    expect(doc.data['odometerReading'], 120500);
    expect(line['fuelType'], 'gasoline');
    expect(line['fillType'], 'partial_fill');
    expect(line['odometerReading'], 120500);
    expect(line['quantity'], 14.25);
    expect(line['unitPriceCents'], 339);
    expect(line['rawReceiptTextStored'], isFalse);
    expect(doc.data.toString(), isNot(contains('PRIVATE FUEL RECEIPT TEXT')));
    MaintainiacFirestoreUploadPolicy.validateDraft(doc);
  });

  test('backs up a deleted receipt as a revisioned tombstone', () {
    final deletedAt = DateTime.utc(2026, 7, 15, 14, 30);
    final receipt = ExpenseReceiptRecord(
      id: 'deleted-receipt',
      receiptDate: DateTime.utc(2026, 7, 15),
      localRevision: 8,
      recordState: MaintainiacRecordState.deleted,
      deletedAt: deletedAt,
      lines: const [],
    );

    final doc = ExpenseFirestoreDocumentBuilder.expenseReceiptDocument(
      orgId: 'ORG-1',
      uid: 'USER-1',
      deviceId: 'DEVICE-1',
      receipt: receipt,
      nowUtc: DateTime.utc(2026, 7, 15, 15),
    );

    expect(doc.data['recordState'], 'deleted');
    expect(doc.data['deletedAt'], deletedAt.toIso8601String());
    expect(doc.data['localRevision'], 8);
    expect(doc.data['syncStatus'], 'pending_delete');
    MaintainiacFirestoreUploadPolicy.validateDraft(doc);
  });

  test('backs up split allocation evidence without source receipt text', () {
    final receipt = ExpenseReceiptRecord(
      id: 'split-evidence',
      receiptDate: DateTime.utc(2026, 7, 15),
      lines: const [
        ExpenseReceiptLineRecord(
          id: 'line-1',
          description: 'Shared supplies',
          category: 'Supplies',
          use: ExpenseLineUse.split,
          quantity: 10,
          unitsPerPackage: 1,
          unit: 'each',
          subtotal: 25,
          splitAllocation: ExpenseSplitAllocation(
            method: ExpenseSplitAllocationMethod.quantity,
            businessValue: 4,
          ),
          rawReceiptText: 'PRIVATE SHARED SUPPLIES',
        ),
      ],
    );
    final doc = ExpenseFirestoreDocumentBuilder.expenseReceiptDocument(
      orgId: 'ORG-1',
      uid: 'USER-1',
      deviceId: 'DEVICE-1',
      receipt: receipt,
    );
    final line = (doc.data['lines'] as List).single as Map<String, Object?>;

    expect(line['splitAllocation'], {
      'method': 'quantity',
      'businessValue': 4.0,
    });
    expect(doc.data.toString(), isNot(contains('PRIVATE SHARED SUPPLIES')));
    MaintainiacFirestoreUploadPolicy.validateDraft(doc);
  });

  test(
    'backs up active and archived vehicle identities without local paths',
    () async {
      final appState = AppStateController();
      final archived = VehicleProfile(
        id: 'archived-vehicle',
        nickname: 'Old van',
      );
      await appState.addVehicle(archived);
      await appState.deleteVehicle(archived.id);
      final doc =
          ExpenseFirestoreDocumentBuilder.expenseVehicleDirectoryDocument(
            orgId: 'ORG-1',
            uid: 'USER-1',
            deviceId: 'DEVICE-1',
            appState: appState,
            nowUtc: DateTime.utc(2026, 7, 15, 12),
          );

      expect(
        doc.path,
        'orgs/ORG-1/${MaintainiacFirestoreSchema.orgSettings}/expense_vehicles_USER-1',
      );
      expect(doc.data['schema'], 'expense_vehicle_directory_backup_v1');
      expect(doc.data['activeVehicleId'], 'vehicle_work_truck_1');
      final vehicles = doc.data['vehicles'] as List;
    expect(vehicles, isNotEmpty);
      expect(
        vehicles.whereType<Map>().singleWhere(
          (vehicle) => vehicle['id'] == 'archived-vehicle',
        )['archivedAt'],
        isNotNull,
      );
      expect(doc.data.toString(), isNot(contains('localPath')));
      MaintainiacFirestoreUploadPolicy.validateDraft(doc);
    },
  );

  test('backs up active and archived work-profile identities', () async {
    final profiles = ExpenseWorkProfileController.memory();
    final archived = await profiles.save(
      ExpenseWorkProfile(
        id: 'archived-profile',
        name: 'Archived contract',
        createdAt: DateTime.utc(2026, 7, 15),
        updatedAt: DateTime.utc(2026, 7, 15),
      ),
    );
    await profiles.delete(archived.id);
    final doc =
        ExpenseFirestoreDocumentBuilder.expenseWorkProfileDirectoryDocument(
          orgId: 'ORG-1',
          uid: 'USER-1',
          deviceId: 'DEVICE-1',
          workProfiles: profiles,
          nowUtc: DateTime.utc(2026, 7, 15, 12),
        );

    expect(
      doc.path,
      'orgs/ORG-1/${MaintainiacFirestoreSchema.orgSettings}/expense_work_profiles_USER-1',
    );
    expect(doc.data['schema'], 'expense_work_profile_directory_backup_v1');
    expect(doc.data['activeWorkProfileId'], 'expense_work_default');
    final exportedProfiles = doc.data['profiles'] as List;
    expect(exportedProfiles, hasLength(2));
    expect(
      exportedProfiles.whereType<Map>().singleWhere(
        (profile) => profile['id'] == 'archived-profile',
      )['archivedAt'],
      isNotNull,
    );
    MaintainiacFirestoreUploadPolicy.validateDraft(doc);
  });
}
