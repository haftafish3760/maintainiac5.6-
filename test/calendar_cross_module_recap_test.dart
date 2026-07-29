import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_store.dart';
import 'package:maintaniac/screens/invoices/data/invoice_ledger_models.dart';
import 'package:maintaniac/screens/invoices/data/invoice_record.dart';
import 'package:maintaniac/shared/calendar/calendar_cross_module_recap.dart';
import 'package:maintaniac/shared/calendar/calendar_projection_contract.dart';
import 'package:maintaniac/shared/calendar/calendar_recap_period_contract.dart';
import 'package:maintaniac/shared/profiles/employee_work_time_contract.dart';

void main() {
  test(
    'cross-module recap recomputes scoped cash flow and work time',
    () async {
      final ledger = ExpenseLedgerController.memory();
      await ledger.saveReceipt(_receipt('expense-van', 50, 'van', 'delivery'));
      await ledger.saveReceipt(
        _receipt('expense-truck', 75, 'truck', 'repair'),
      );
      final recap = CalendarCrossModuleRecap.fromSources(
        range: CalendarRecapDateRange(
          start: DateTime(2026, 7, 1),
          end: DateTime(2026, 7, 31),
        ),
        events: [_event('confirmed', CalendarProjectionState.confirmed, 'van')],
        expenses: ledger,
        invoices: [_invoice()],
        workTime: [_workTime()],
        scope: const CalendarRecapScope(
          vehicleId: 'van',
          workProfileId: 'delivery',
        ),
      );

      expect(recap.eventCount, 1);
      expect(recap.confirmedCount, 1);
      expect(recap.businessExpense, 50);
      expect(recap.invoiceBilled, 200);
      expect(recap.paymentReceived, 120);
      expect(recap.netCashFlow, 70);
      expect(recap.approvedWorkMinutes, 120);
      expect(recap.pendingWorkMinutes, 0);
    },
  );

  test(
    'voided documents and rejected time are not reported as cash or pay',
    () {
      final recap = CalendarCrossModuleRecap.fromSources(
        range: CalendarRecapDateRange(
          start: DateTime(2026, 7, 1),
          end: DateTime(2026, 7, 31),
        ),
        events: [_event('review', CalendarProjectionState.needsReview, 'van')],
        invoices: [_invoice(status: InvoiceRecordStatus.voided)],
        workTime: [_workTime(status: EmployeeWorkTimeStatus.rejected)],
        scope: const CalendarRecapScope(vehicleId: 'van'),
      );

      expect(recap.needsReviewCount, 1);
      expect(recap.invoiceBilled, 0);
      expect(recap.paymentReceived, 0);
      expect(recap.approvedWorkMinutes, 0);
      expect(recap.pendingWorkMinutes, 0);
    },
  );

  test(
    'late-entered expense updates the recap for its business date',
    () async {
      final ledger = ExpenseLedgerController.memory();
      await ledger.saveReceipt(
        _receipt(
          'fuel',
          200,
          'van',
          'delivery',
          receiptDate: DateTime(2026, 7, 14),
        ),
      );
      final range = CalendarRecapDateRange(
        start: DateTime(2026, 7, 14),
        end: DateTime(2026, 7, 20),
      );
      final before = CalendarCrossModuleRecap.fromSources(
        range: range,
        events: const [],
        expenses: ledger,
        scope: const CalendarRecapScope(
          vehicleId: 'van',
          workProfileId: 'delivery',
        ),
      );

      await ledger.saveReceipt(
        _receipt(
          'late-receipt',
          50,
          'van',
          'delivery',
          receiptDate: DateTime(2026, 7, 16),
          createdAt: DateTime(2026, 7, 29, 9),
        ),
      );
      final after = CalendarCrossModuleRecap.fromSources(
        range: range,
        events: const [],
        expenses: ledger,
        scope: const CalendarRecapScope(
          vehicleId: 'van',
          workProfileId: 'delivery',
        ),
      );

      expect(before.businessExpense, 200);
      expect(after.businessExpense, 250);
      expect(after.netCashFlow, before.netCashFlow - 50);
    },
  );
}

ExpenseReceiptRecord _receipt(
  String id,
  double amount,
  String vehicle,
  String profile, {
  DateTime? receiptDate,
  DateTime? createdAt,
}) => ExpenseReceiptRecord(
  id: id,
  receiptDate: receiptDate ?? DateTime(2026, 7, 15),
  vehicleId: vehicle,
  workProfileId: profile,
  createdAt: createdAt,
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

InvoiceRecord _invoice({
  InvoiceRecordStatus status = InvoiceRecordStatus.sent,
}) => InvoiceRecord(
  id: 'invoice-1',
  documentType: InvoiceDocumentType.invoice,
  invoiceNumber: 'INV-1',
  numberMode: InvoiceNumberMode.automatic,
  status: status,
  issueDate: DateTime(2026, 7, 15),
  vehicleId: 'van',
  profileId: 'delivery',
  lines: const [
    InvoiceLineItemRecord(id: 'line-1', name: 'Route', unitPrice: 200),
  ],
  payments: [
    InvoicePaymentRecord(
      id: 'payment-1',
      amount: 120,
      paidAt: DateTime(2026, 7, 20),
    ),
  ],
  meta: InvoiceSyncMetadata(
    createdAt: DateTime(2026, 7, 15),
    updatedAt: DateTime(2026, 7, 15),
  ),
);

EmployeeWorkTimeRecord _workTime({
  EmployeeWorkTimeStatus status = EmployeeWorkTimeStatus.approved,
}) => EmployeeWorkTimeRecord(
  id: 'time-1',
  employeeId: 'employee-1',
  workDate: DateTime(2026, 7, 15),
  recordedAt: DateTime(2026, 7, 15),
  status: status,
  revision: 1,
  manualPaidMinutes: 120,
  vehicleIds: const ['van'],
  workProfileId: 'delivery',
);

CalendarProjectionEvent _event(
  String id,
  CalendarProjectionState state,
  String vehicle,
) => CalendarProjectionEvent(
  eventId: id,
  source: CalendarProjectionSource.job,
  sourceRecordId: id,
  timing: CalendarProjectionTiming(
    eventDate: DateTime(2026, 7, 15),
    recordedAt: DateTime(2026, 7, 15),
    timeSource: CalendarTimeSource.unknown,
  ),
  title: id,
  conciseDetail: id,
  state: state,
  sourceRecordStatus: state.name,
  revision: 1,
  vehicleIds: [vehicle],
  workProfileId: 'delivery',
  evidence: const CalendarProjectionEvidence(),
  deepLink: CalendarProjectionDeepLink(
    target: CalendarDeepLinkTarget.jobDetail,
    sourceRecordId: id,
  ),
);
