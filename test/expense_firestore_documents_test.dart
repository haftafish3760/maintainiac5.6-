import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/expenses/data/expense_firestore_documents.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
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

  test(
    'builds expense receipt backup without raw OCR or local proof paths',
    () {
      final receipt = ExpenseReceiptRecord(
        id: 'receipt 1',
        receiptDate: DateTime.utc(2026, 6, 24),
        receiptTimeMinutes: 9 * 60 + 30,
        merchantName: 'Local Hardware',
        rawOcrText: 'RAW PRIVATE OCR TEXT SHOULD NOT SYNC',
        enteredTotal: 42.25,
        vehicleId: 'truck-1',
        odometerReading: 150125,
        hasReceiptProof: true,
        ocrReview: const ExpenseReceiptOcrReview(
          severity: 'review',
          source: 'photo',
          warningKinds: ['sectionGap'],
          warningKindCounts: {'sectionGap': 1},
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
      expect(doc.data['odometerReading'], 150125);
      expect((doc.data['lines'] as List).single.toString(), contains('Hammer'));
      expect(doc.data['rawOcrStored'], isFalse);
      final ocrReview = doc.data['ocrReview'] as Map<String, Object?>;
      expect(ocrReview['warningKindCounts'], {'sectionGap': 1});
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
    },
  );

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
}
