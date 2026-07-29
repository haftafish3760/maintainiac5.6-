import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_store.dart';
import 'package:maintaniac/shared/calendar/calendar_expense_day_projection.dart';
import 'package:maintaniac/shared/calendar/calendar_projection_contract.dart';
import 'package:maintaniac/screens/expenses/reports/expense_recap_models.dart';

void main() {
  test(
    'expense day recap and timeline read the same selected receipt date',
    () async {
      final ledger = ExpenseLedgerController.memory();
      await ledger.saveReceipt(
        _receipt(
          id: 'late-entry',
          date: DateTime(2026, 7, 22),
          createdAt: DateTime(2026, 7, 28, 9),
          amount: 50,
        ),
      );
      await ledger.saveReceipt(
        _receipt(
          id: 'other-day',
          date: DateTime(2026, 7, 23),
          createdAt: DateTime(2026, 7, 23, 9),
          amount: 75,
        ),
      );

      final day = CalendarExpenseDayProjection.forDay(
        ledger,
        DateTime(2026, 7, 22),
      );

      expect(day.entries, hasLength(1));
      expect(day.entries.single.id, 'expense:late-entry');
      expect(
        day.entries.single.projection!.timing.eventDate,
        DateTime(2026, 7, 22),
      );
      expect(
        day.entries.single.projection!.timing.timeSource,
        CalendarTimeSource.unknown,
      );
      expect(day.entries.single.timeLabel, 'Time?');
      expect(day.recapItems.first.value, r'$50.00');
    },
  );
  test(
    'late receipt recalculates every affected expense recap range',
    () async {
      final ledger = ExpenseLedgerController.memory();
      final weeklyRange = ExpenseDateRange(
        start: DateTime(2026, 7, 20),
        end: DateTime(2026, 7, 26),
      );
      final monthRange = ExpenseDateRange(
        start: DateTime(2026, 7),
        end: DateTime(2026, 7, 31),
      );
      final ytdRange = ExpenseDateRange(
        start: DateTime(2026),
        end: DateTime(2026, 7, 31),
      );
      await ledger.saveReceipt(
        _receipt(
          id: 'known',
          date: DateTime(2026, 7, 24),
          createdAt: DateTime(2026, 7, 24),
          amount: 100,
        ),
      );
      await ledger.saveReceipt(
        _receipt(
          id: 'late',
          date: DateTime(2026, 7, 22),
          createdAt: DateTime(2026, 7, 30),
          amount: 50,
        ),
      );

      for (final range in [weeklyRange, monthRange, ytdRange]) {
        expect(ExpenseRecapReport.fromLedger(ledger, range).totalExpenses, 150);
      }
    },
  );
  test(
    'day recap and events use the same vehicle and work-profile scope',
    () async {
      final ledger = ExpenseLedgerController.memory();
      final day = DateTime(2026, 7, 22);
      await ledger.saveReceipt(
        _receipt(
          id: 'delivery-van',
          date: day,
          createdAt: day,
          amount: 50,
          vehicleId: 'van-7',
          workProfileId: 'delivery',
        ),
      );
      await ledger.saveReceipt(
        _receipt(
          id: 'repair-truck',
          date: day,
          createdAt: day,
          amount: 75,
          vehicleId: 'truck-2',
          workProfileId: 'repair',
        ),
      );

      final projection = CalendarExpenseDayProjection.forDay(
        ledger,
        day,
        vehicleId: 'van-7',
        workProfileId: 'delivery',
      );

      expect(projection.entries, hasLength(1));
      expect(projection.entries.single.id, 'expense:delivery-van');
      expect(projection.recapItems[0].value, r'$50.00');
      expect(projection.recapItems[2].value, '1');
    },
  );
}

ExpenseReceiptRecord _receipt({
  required String id,
  required DateTime date,
  required DateTime createdAt,
  required double amount,
  String? vehicleId,
  String? workProfileId,
}) => ExpenseReceiptRecord(
  id: id,
  receiptDate: date,
  createdAt: createdAt,
  vehicleId: vehicleId,
  workProfileId: workProfileId,
  merchantName: 'Fuel Stop',
  lines: [
    ExpenseReceiptLineRecord(
      id: '$id-line',
      description: 'Fuel',
      category: 'Fuel',
      use: ExpenseLineUse.business,
      quantity: 1,
      unitsPerPackage: 1,
      unit: 'each',
      subtotal: amount,
    ),
  ],
);
