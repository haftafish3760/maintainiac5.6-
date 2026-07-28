/// Active-day financial totals derived from saved local ledger records.
///
/// Owns date, vehicle, and work-profile attribution for the Active Day view.
/// Does not create, edit, estimate, synchronize, or confirm money records.
/// Consumed by ActiveWorkdayFinancialSummaryPanel and its regression tests.
/// Unscoped or mismatched records are deliberately excluded from the totals.
library;

import '../../expenses/data/expense_ledger_models.dart';
import '../../invoices/data/invoice_record.dart';

class ActiveWorkdayFinancialSnapshot {
  const ActiveWorkdayFinancialSnapshot({
    required this.receivedCents,
    required this.spentCents,
    required this.fuelCents,
    required this.expenseReceiptCount,
  });

  final int receivedCents;
  final int spentCents;
  final int fuelCents;
  final int expenseReceiptCount;

  int get netCents => receivedCents - spentCents;

  factory ActiveWorkdayFinancialSnapshot.forSession({
    required DateTime day,
    required String vehicleId,
    required String workProfileId,
    required Iterable<InvoiceRecord> invoices,
    required Iterable<ExpenseReceiptRecord> expenses,
  }) {
    var receivedCents = 0;
    var spentCents = 0;
    var fuelCents = 0;
    var expenseReceiptCount = 0;

    for (final invoice in invoices) {
      if (!invoice.isInvoice ||
          !_matchesSession(
            vehicleId: invoice.vehicleId,
            workProfileId: invoice.profileId,
            sessionVehicleId: vehicleId,
            sessionWorkProfileId: workProfileId,
          )) {
        continue;
      }
      for (final payment in invoice.payments) {
        if (_isSameLocalDay(payment.paidAt, day)) {
          receivedCents += _toCents(payment.amount);
        }
      }
    }

    for (final expense in expenses) {
      if (!expense.isActive ||
          !_isSameLocalDay(expense.receiptDate, day) ||
          !_matchesSession(
            vehicleId: expense.vehicleId ?? '',
            workProfileId: expense.workProfileId ?? '',
            sessionVehicleId: vehicleId,
            sessionWorkProfileId: workProfileId,
          )) {
        continue;
      }
      expenseReceiptCount += 1;
      spentCents += expense.businessTotalCents;
      fuelCents += expense.lines
          .where(_isFuelLine)
          .fold(0, (sum, line) => sum + line.businessCents);
    }

    return ActiveWorkdayFinancialSnapshot(
      receivedCents: receivedCents,
      spentCents: spentCents,
      fuelCents: fuelCents,
      expenseReceiptCount: expenseReceiptCount,
    );
  }

  static bool _matchesSession({
    required String vehicleId,
    required String workProfileId,
    required String sessionVehicleId,
    required String sessionWorkProfileId,
  }) {
    final recordVehicle = vehicleId.trim();
    final recordProfile = workProfileId.trim();
    if (recordVehicle.isEmpty && recordProfile.isEmpty) return false;
    return (recordVehicle.isEmpty || recordVehicle == sessionVehicleId) &&
        (recordProfile.isEmpty || recordProfile == sessionWorkProfileId);
  }

  static bool _isSameLocalDay(DateTime value, DateTime day) =>
      value.year == day.year &&
      value.month == day.month &&
      value.day == day.day;

  static bool _isFuelLine(ExpenseReceiptLineRecord line) =>
      line.fuelType?.trim().isNotEmpty == true ||
      line.category.trim().toLowerCase() == 'fuel';

  static int _toCents(double amount) => (amount * 100).round();
}
