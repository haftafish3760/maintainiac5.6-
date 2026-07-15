import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_cloud_restore_codec.dart';
import 'package:maintaniac/screens/expenses/data/expense_firestore_documents.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  test('decodes cloud metadata without claiming cloud proofs are local', () {
    final receipt = ExpenseReceiptRecord(
      id: 'restore-receipt',
      receiptDate: DateTime.utc(2026, 7, 15),
      merchantName: 'Hardware Store',
      enteredTotal: 42.25,
      vehicleId: 'van-1',
      workProfileId: 'delivery',
      rawOcrText: 'private OCR must remain absent',
      auditEvents: const [
        '2026-07-15T14:00:00.000Z created receipt restore-receipt',
      ],
      attachments: [
        ReceiptAttachmentRecord(
          id: 'proof-1',
          path: '/private/local/proof.jpg',
          kind: ReceiptAttachmentKind.photo,
          dataSaverLevel: ReceiptDataSaverLevel.balanced,
          createdAt: DateTime.utc(2026, 7, 15),
          byteSize: 1234,
          fileHash: 'aabbcc',
        ),
      ],
      lines: const [
        ExpenseReceiptLineRecord(
          id: 'line-1',
          description: 'HDWR',
          category: 'Tools',
          use: ExpenseLineUse.business,
          quantity: 1,
          unitsPerPackage: 1,
          unit: 'each',
          subtotal: 42.25,
          unitPrice: 42.25,
        ),
      ],
    );
    final cloud = ExpenseFirestoreDocumentBuilder.expenseReceiptDocument(
      orgId: 'ORG-1',
      uid: 'USER-1',
      deviceId: 'DEVICE-1',
      receipt: receipt,
      nowUtc: DateTime.utc(2026, 7, 15, 15),
    );

    final restored = ExpenseCloudRestoreCodec.decodeReceipt(cloud.data);

    expect(restored.receipt.id, 'restore-receipt');
    expect(restored.receipt.merchantName, 'Hardware Store');
    expect(restored.receipt.enteredTotal, 42.25);
    expect(restored.receipt.vehicleId, 'van-1');
    expect(restored.receipt.workProfileId, 'delivery');
    expect(restored.receipt.rawOcrText, isEmpty);
    expect(restored.receipt.attachments, isEmpty);
    expect(restored.receipt.hasReceiptProof, isTrue);
    expect(restored.receipt.lines.single.description, 'HDWR');
    expect(restored.receipt.lines.single.subtotal, 42.25);
    expect(restored.receipt.auditEvents, [
      '2026-07-15T14:00:00.000Z created receipt restore-receipt',
    ]);
    expect(restored.proofPointers, hasLength(1));
    expect(restored.proofPointers.single.storagePath, isNull);
    expect(restored.proofPointers.single.isCloudBacked, isFalse);
    expect(restored.proofPointers.single.byteSize, 1234);
  });

  test('rejects an unsupported receipt backup schema', () {
    expect(
      () => ExpenseCloudRestoreCodec.decodeReceipt({
        'schema': 'unknown',
        'id': 'receipt',
      }),
      throwsFormatException,
    );
  });

  test('decodes active and archived work-profile restore metadata', () {
    final restored = ExpenseCloudRestoreCodec.decodeWorkProfileDirectory({
      'schema': 'expense_work_profile_directory_backup_v1',
      'activeWorkProfileId': 'delivery',
      'profiles': [
        {
          'id': 'delivery',
          'name': 'Evening delivery',
          'isDefault': false,
          'createdAt': '2026-07-15T12:00:00.000Z',
          'updatedAt': '2026-07-15T12:00:00.000Z',
          'archivedAt': null,
        },
        {
          'id': 'old-contract',
          'name': 'Old contract',
          'isDefault': false,
          'createdAt': '2026-07-15T12:00:00.000Z',
          'updatedAt': '2026-07-15T12:00:00.000Z',
          'archivedAt': '2026-07-16T12:00:00.000Z',
        },
      ],
    });

    expect(restored.activeProfileId, 'delivery');
    expect(restored.profiles, hasLength(2));
    expect(restored.profiles.last.isArchived, isTrue);
  });

  test('rejects corrupt profile and vehicle directory metadata', () {
    expect(
      () => ExpenseCloudRestoreCodec.decodeWorkProfileDirectory({
        'schema': 'expense_work_profile_directory_backup_v1',
        'profiles': [
          {
            'id': 'profile-1',
            'name': 'Broken profile',
            'createdAt': 'not-a-date',
            'updatedAt': '2026-07-15T12:00:00.000Z',
          },
        ],
      }),
      throwsFormatException,
    );
    expect(
      () => ExpenseCloudRestoreCodec.decodeVehicleDirectory({
        'schema': 'expense_vehicle_directory_backup_v1',
        'vehicles': [
          {'id': 'vehicle-1', 'archivedAt': 'not-a-date'},
        ],
      }),
      throwsFormatException,
    );
  });

  test('rejects malformed directory and proof collection types', () {
    expect(
      () => ExpenseCloudRestoreCodec.decodeWorkProfileDirectory({
        'schema': 'expense_work_profile_directory_backup_v1',
        'profiles': 'not-a-list',
      }),
      throwsFormatException,
    );
    expect(
      () => ExpenseCloudRestoreCodec.decodeVehicleDirectory({
        'schema': 'expense_vehicle_directory_backup_v1',
        'vehicles': {'id': 'not-a-list'},
      }),
      throwsFormatException,
    );
    expect(
      () => ExpenseCloudRestoreCodec.decodeReceipt({
        'schema': 'expense_receipt_backup_v1',
        'id': 'bad-proofs',
        'receiptDate': '2026-07-15T00:00:00.000Z',
        'proofs': {'id': 'not-a-list'},
      }),
      throwsFormatException,
    );
  });

  test('rejects malformed proof entries instead of dropping them', () {
    expect(
      () => ExpenseCloudRestoreCodec.decodeReceipt({
        'schema': 'expense_receipt_backup_v1',
        'id': 'bad-proof-entry',
        'receiptDate': '2026-07-15T00:00:00.000Z',
        'proofs': [
          {'id': 'proof-1'},
          'not-a-proof',
        ],
      }),
      throwsFormatException,
    );
  });

  test('rejects an uploaded proof that has no cloud storage path', () {
    expect(
      () => ExpenseCloudRestoreCodec.decodeReceipt({
        'schema': 'expense_receipt_backup_v1',
        'id': 'missing-cloud-proof-path',
        'receiptDate': '2026-07-15T00:00:00.000Z',
        'proofs': [
          {'id': 'proof-1', 'cloudProofState': 'available'},
        ],
      }),
      throwsFormatException,
    );
  });

  test('rejects malformed receipt lines instead of dropping them', () {
    expect(
      () => ExpenseCloudRestoreCodec.decodeReceipt({
        'schema': 'expense_receipt_backup_v1',
        'id': 'bad-line-entry',
        'receiptDate': '2026-07-15T00:00:00.000Z',
        'lines': [
          {'id': 'line-1', 'subtotalCents': 125},
          'not-a-line',
        ],
      }),
      throwsFormatException,
    );
  });

  test('rejects malformed receipt audit history instead of dropping it', () {
    expect(
      () => ExpenseCloudRestoreCodec.decodeReceipt({
        'schema': 'expense_receipt_backup_v1',
        'id': 'bad-audit-entry',
        'receiptDate': '2026-07-15T00:00:00.000Z',
        'auditEvents': [
          {
            'occurredAt': '2026-07-15T00:00:00.000Z',
            'action': 'created',
            'recordId': 'bad-audit-entry',
          },
          {'action': 'edited'},
        ],
      }),
      throwsFormatException,
    );
  });

  test('rejects corrupt receipt lifecycle metadata instead of reviving it', () {
    const receipt = {
      'schema': 'expense_receipt_backup_v1',
      'id': 'lifecycle-receipt',
      'receiptDate': '2026-07-15T00:00:00.000Z',
    };

    expect(
      () => ExpenseCloudRestoreCodec.decodeReceipt({
        ...receipt,
        'recordState': 'unknown',
      }),
      throwsFormatException,
    );
    expect(
      () => ExpenseCloudRestoreCodec.decodeReceipt({
        ...receipt,
        'localRevision': 0,
      }),
      throwsFormatException,
    );
    expect(
      () => ExpenseCloudRestoreCodec.decodeReceipt({
        ...receipt,
        'localRevision': 1.5,
      }),
      throwsFormatException,
    );
    expect(
      () => ExpenseCloudRestoreCodec.decodeReceipt({
        ...receipt,
        'recordState': 'deleted',
        'deletedAt': 'not-a-date',
      }),
      throwsFormatException,
    );
  });

  test('decodes active and archived vehicle restore metadata', () {
    final restored = ExpenseCloudRestoreCodec.decodeVehicleDirectory({
      'schema': 'expense_vehicle_directory_backup_v1',
      'activeVehicleId': 'van-1',
      'vehicles': [
        {
          'id': 'van-1',
          'nickname': 'Cargo van',
          'year': '2024',
          'make': 'Ford',
          'model': 'Transit',
          'usage': 'businessOnly',
          'archivedAt': null,
        },
        {
          'id': 'old-van',
          'nickname': 'Old van',
          'year': '2016',
          'make': 'Ford',
          'model': 'Transit',
          'usage': 'businessPersonal',
          'archivedAt': '2026-07-16T12:00:00.000Z',
        },
      ],
    });

    expect(restored.activeVehicleId, 'van-1');
    expect(restored.vehicles, hasLength(2));
    expect(restored.vehicles.last.isArchived, isTrue);
  });

  test('decodes a deleted reminder with its lifecycle metadata', () {
    final restored = ExpenseCloudRestoreCodec.decodeReminder({
      'schema': 'expense_reminder_backup_v1',
      'id': 'reminder-1',
      'title': 'Vehicle registration',
      'category': 'Registration',
      'channel': 'in_app',
      'cadence': 'yearly',
      'dueAt': '2026-08-01T12:00:00.000Z',
      'active': false,
      'details': 'Renew before expiration.',
      'createdAt': '2026-07-01T12:00:00.000Z',
      'updatedAt': '2026-07-15T12:00:00.000Z',
      'recordState': 'deleted',
      'localRevision': 4,
      'deletedAt': '2026-07-15T12:00:00.000Z',
    });

    expect(restored.record.id, 'reminder-1');
    expect(restored.record.cadence.name, 'yearly');
    expect(restored.record.isDeleted, isTrue);
    expect(restored.record.lifecycle?.revision, 4);
  });

  test('legacy reminder metadata remains active when active is absent', () {
    final restored = ExpenseCloudRestoreCodec.decodeReminder({
      'schema': 'expense_reminder_backup_v1',
      'id': 'legacy-reminder',
      'title': 'Renew registration',
      'category': 'Registration',
      'dueAt': '2026-08-01T12:00:00.000Z',
      'createdAt': '2026-07-15T12:00:00.000Z',
      'updatedAt': '2026-07-15T12:00:00.000Z',
    });

    expect(restored.record.active, isTrue);
  });

  test('rejects corrupt reminder lifecycle metadata', () {
    const reminder = {
      'schema': 'expense_reminder_backup_v1',
      'id': 'lifecycle-reminder',
      'title': 'Renew registration',
      'category': 'Registration',
      'dueAt': '2026-08-01T12:00:00.000Z',
    };

    expect(
      () => ExpenseCloudRestoreCodec.decodeReminder({
        ...reminder,
        'recordState': 'unknown',
      }),
      throwsFormatException,
    );
    expect(
      () => ExpenseCloudRestoreCodec.decodeReminder({
        ...reminder,
        'localRevision': -1,
      }),
      throwsFormatException,
    );
  });

  test(
    'estimates proof storage separately from structured restore records',
    () {
      final knownProof = ExpenseCloudRestoredReceipt(
        receipt: ExpenseReceiptRecord(
          id: 'known-proof',
          receiptDate: DateTime.utc(2026, 7, 15),
          lines: const [],
        ),
        proofPointers: const [
          ExpenseCloudProofPointer(
            id: 'proof-1',
            storagePath: 'receipt-proofs/optimized/proof-1',
            availability: ExpenseCloudProofAvailability.available,
            kind: ReceiptAttachmentKind.photo,
            mimeType: 'image/jpeg',
            byteSize: 1234,
            fileHashSha256: '',
            dataSaverLevel: ReceiptDataSaverLevel.balanced,
          ),
        ],
      );
      final unknownProof = ExpenseCloudRestoredReceipt(
        receipt: ExpenseReceiptRecord(
          id: 'unknown-proof',
          receiptDate: DateTime.utc(2026, 7, 15),
          lines: const [],
        ),
        proofPointers: const [
          ExpenseCloudProofPointer(
            id: 'proof-2',
            storagePath: 'receipt-proofs/pdf/proof-2',
            availability: ExpenseCloudProofAvailability.available,
            kind: ReceiptAttachmentKind.pdf,
            mimeType: 'application/pdf',
            byteSize: null,
            fileHashSha256: '',
            dataSaverLevel: ReceiptDataSaverLevel.original,
          ),
        ],
      );

      final estimate = ExpenseCloudRestoreEstimate.fromReceipts([
        knownProof,
        unknownProof,
      ]);

      expect(estimate.recordCount, 2);
      expect(estimate.proofCount, 2);
      expect(estimate.cloudProofCount, 2);
      expect(estimate.metadataOnlyProofCount, 0);
      expect(estimate.knownProofBytes, 1234);
      expect(estimate.proofsWithUnknownSize, 1);
      expect(estimate.hasCompleteProofByteEstimate, isFalse);
    },
  );
}
