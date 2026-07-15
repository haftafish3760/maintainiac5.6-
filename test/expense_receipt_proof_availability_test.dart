import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  test(
    'a missing stored proof does not appear available to an Expense record',
    () {
      final receipt = ExpenseReceiptRecord(
        id: 'missing-proof',
        receiptDate: DateTime(2026, 7, 15),
        hasReceiptProof: true,
        attachments: [
          ReceiptAttachmentRecord(
            id: 'proof-1',
            path: '/app/receipt_proofs/photos/missing.jpg',
            kind: ReceiptAttachmentKind.photo,
            dataSaverLevel: ReceiptDataSaverLevel.balanced,
            createdAt: DateTime(2026, 7, 15),
            storageState: ReceiptAttachmentStorageState.missing,
          ),
        ],
        lines: const [],
      );

      expect(receipt.hasMissingReceiptProof, isTrue);
      expect(receipt.hasReceiptAttachment, isFalse);
    },
  );

  test('one retained proof keeps a multi-proof record available', () {
    final receipt = ExpenseReceiptRecord(
      id: 'one-proof-retained',
      receiptDate: DateTime(2026, 7, 15),
      attachments: [
        ReceiptAttachmentRecord(
          id: 'missing-proof',
          path: '/app/receipt_proofs/photos/missing.jpg',
          kind: ReceiptAttachmentKind.photo,
          dataSaverLevel: ReceiptDataSaverLevel.balanced,
          createdAt: DateTime(2026, 7, 15),
          storageState: ReceiptAttachmentStorageState.missing,
        ),
        ReceiptAttachmentRecord(
          id: 'retained-proof',
          path: '/app/receipt_proofs/photos/retained.jpg',
          kind: ReceiptAttachmentKind.photo,
          dataSaverLevel: ReceiptDataSaverLevel.balanced,
          createdAt: DateTime(2026, 7, 15),
        ),
      ],
      lines: const [],
    );

    expect(receipt.hasMissingReceiptProof, isTrue);
    expect(receipt.hasReceiptAttachment, isTrue);
  });
}
