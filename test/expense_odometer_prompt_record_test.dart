import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';

void main() {
  test(
    'optional receipt odometer reading survives draft and record recovery',
    () {
      final draft = ExpenseReceiptDraftRecord(
        id: 'draft-odometer',
        receiptDate: DateTime.utc(2026, 7, 15),
        updatedAt: DateTime.utc(2026, 7, 15),
        odometerReading: 123456,
      );
      final receipt = ExpenseReceiptRecord(
        id: 'receipt-odometer',
        receiptDate: DateTime.utc(2026, 7, 15),
        odometerReading: 123456,
        lines: const [],
      );

      expect(
        ExpenseReceiptDraftRecord.fromMap(draft.toMap()).odometerReading,
        123456,
      );
      expect(
        ExpenseReceiptRecord.fromMap(receipt.toMap()).odometerReading,
        123456,
      );
    },
  );
}
