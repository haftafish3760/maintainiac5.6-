// Gig dashboard record-review routing regression coverage.
//
// Owns the no-odometer-blocker contract for dashboard review destinations.
// It does not test receipt persistence or payment-entry implementation.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/dashboard/active_workday_financial_summary_panel.dart';
import 'package:maintaniac/screens/dashboard/data/active_workday_store.dart';
import 'package:maintaniac/screens/dashboard/gig_dashboard_record_review_screens.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_store.dart';
import 'package:maintaniac/screens/invoices/data/invoice_ledger_store.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';

void main() {
  testWidgets('fuel review opens records before any odometer prompt', (
    tester,
  ) async {
    final ledger = ExpenseLedgerController.memory();
    final odometer = GlobalOdometerController(initialReading: 12000);
    addTearDown(ledger.dispose);
    addTearDown(odometer.dispose);

    await tester.pumpWidget(
      GlobalOdometerScope(
        controller: odometer,
        child: ExpenseLedgerScope(
          controller: ledger,
          child: const MaterialApp(
            home: GigExpenseCategoryBreakdownScreen(category: 'Fuel'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fuel Review'), findsOneWidget);
    expect(find.text('No expenses recorded yet'), findsOneWidget);
    expect(find.text('Add expense'), findsOneWidget);
    expect(find.text('Enter Current Odometer'), findsNothing);
  });

  testWidgets('Active Day fuel total opens its review before expense entry', (
    tester,
  ) async {
    final expenses = ExpenseLedgerController.memory();
    final invoices = InvoiceLedgerStore.memory();
    addTearDown(expenses.dispose);
    addTearDown(invoices.dispose);

    final session = ActiveWorkdaySessionRecord(
      id: 'workday_financial_review',
      vehicleId: 'truck_1',
      vehicleLabel: 'Work Truck',
      workProfileId: 'delivery',
      startedAt: DateTime(2026, 7, 28, 8),
      startOdometer: 12000,
      status: ActiveWorkdayStatus.active,
      events: const [],
    );

    await tester.pumpWidget(
      ExpenseLedgerScope(
        controller: expenses,
        child: InvoiceLedgerScope(
          controller: invoices,
          child: MaterialApp(
            home: ActiveWorkdayFinancialSummaryPanel(
              session: session,
              day: DateTime(2026, 7, 28),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Fuel'));
    await tester.pumpAndSettle();

    expect(find.text('Fuel Review'), findsOneWidget);
    expect(find.text('Enter Current Odometer'), findsNothing);
  });
}
