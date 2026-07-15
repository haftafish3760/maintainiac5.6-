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
    expect(
      restored.proofPointers.single.storagePath,
      'receipt-proofs/optimized/proof-1',
    );
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
}
