import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_store.dart';
import 'package:maintaniac/screens/expenses/reports/expense_recap_models.dart';

void main() {
  test('expense recap excludes DEF from propulsion cost per mile', () async {
    final ledger = ExpenseLedgerController.memory();
    await ledger.saveReceipt(
      _dieselReceipt(
        'start',
        DateTime(2026, 7, 1),
        10000,
        dieselAmount: 40,
        includeDef: true,
      ),
    );
    await ledger.saveReceipt(
      _dieselReceipt('end', DateTime(2026, 7, 4), 10200, dieselAmount: 50),
    );

    final report = ExpenseRecapReport.fromLedger(
      ledger,
      ExpenseDateRange(start: DateTime(2026, 7, 1), end: DateTime(2026, 7, 31)),
      vehicleId: 'truck_1',
    );

    expect(report.fuelExpense, 110);
    expect(report.propulsionFuelExpense, 90);
    expect(report.fuelCostPerMile, .45);
  });

  test('expense recap withholds MPG for fuel with no usable volume', () async {
    final ledger = ExpenseLedgerController.memory();
    await ledger.saveReceipt(
      _unmeasuredFuelReceipt('first', DateTime(2026, 7, 1), 10000),
    );
    await ledger.saveReceipt(
      _unmeasuredFuelReceipt('second', DateTime(2026, 7, 4), 10200),
    );

    final report = ExpenseRecapReport.fromLedger(
      ledger,
      ExpenseDateRange(start: DateTime(2026, 7, 1), end: DateTime(2026, 7, 31)),
      vehicleId: 'truck_1',
    );

    expect(report.hasUnmeasuredLiquidFuel, isTrue);
    expect(report.averageMpg, isNull);
    expect(report.averageFuelPrice, isNull);
    expect(report.fuelCostPerMile, .255);
  });
}

ExpenseReceiptRecord _dieselReceipt(
  String id,
  DateTime date,
  int odometer, {
  required double dieselAmount,
  bool includeDef = false,
}) {
  return ExpenseReceiptRecord(
    id: id,
    receiptDate: date,
    merchantName: 'Truck Stop',
    vehicleId: 'truck_1',
    lines: [
      ExpenseReceiptLineRecord(
        id: '$id-diesel',
        description: 'Diesel',
        category: 'Fuel',
        use: ExpenseLineUse.business,
        quantity: 10,
        unitsPerPackage: 1,
        unit: 'gallon',
        subtotal: dieselAmount,
        odometerReading: odometer,
        fuelType: 'Diesel',
        fillType: 'Full fill-up',
      ),
      if (includeDef)
        const ExpenseReceiptLineRecord(
          id: 'start-def',
          description: 'DEF',
          category: 'Fuel',
          use: ExpenseLineUse.business,
          quantity: 2.5,
          unitsPerPackage: 1,
          unit: 'gallon',
          subtotal: 20,
          fuelType: 'DEF',
        ),
    ],
  );
}

ExpenseReceiptRecord _unmeasuredFuelReceipt(
  String id,
  DateTime date,
  int odometer,
) {
  return ExpenseReceiptRecord(
    id: id,
    receiptDate: date,
    merchantName: 'CNG Station',
    vehicleId: 'truck_1',
    lines: [
      ExpenseReceiptLineRecord(
        id: '$id-cng',
        description: 'CNG',
        category: 'Fuel',
        use: ExpenseLineUse.business,
        quantity: id == 'first' ? 8 : 9,
        unitsPerPackage: 1,
        unit: 'kg',
        subtotal: id == 'first' ? 24 : 27,
        odometerReading: odometer,
        fuelType: 'CNG',
      ),
    ],
  );
}
