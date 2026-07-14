import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_store.dart';
import 'package:maintaniac/screens/expenses/reports/expense_recap_models.dart';

void main() {
  test(
    'expense recap calculates vehicle contractor and review metrics',
    () async {
      final ledger = ExpenseLedgerController.memory();
      await ledger.saveReceipt(
        ExpenseReceiptRecord(
          id: 'fuel-1',
          receiptDate: DateTime(2026, 6, 1),
          merchantName: 'Fuel Stop',
          hasReceiptProof: true,
          vehicleId: 'truck_1',
          lines: const [
            ExpenseReceiptLineRecord(
              id: 'fuel-line',
              description: 'Diesel',
              category: 'Fuel',
              use: ExpenseLineUse.business,
              quantity: 10,
              unitsPerPackage: 1,
              unit: 'gallon',
              subtotal: 40,
              odometerReading: 1000,
            ),
          ],
        ),
      );
      await ledger.saveReceipt(
        ExpenseReceiptRecord(
          id: 'materials-1',
          receiptDate: DateTime(2026, 6, 2),
          merchantName: 'Supply House',
          vehicleId: 'truck_2',
          lines: const [
            ExpenseReceiptLineRecord(
              id: 'materials-line',
              description: 'Pipe',
              category: 'Materials',
              use: ExpenseLineUse.business,
              quantity: 1,
              unitsPerPackage: 1,
              unit: 'each',
              subtotal: 120,
            ),
            ExpenseReceiptLineRecord(
              id: 'split-line',
              description: 'Shared phone',
              category: 'Cell Phone',
              use: ExpenseLineUse.split,
              businessPercent: .5,
              quantity: 1,
              unitsPerPackage: 1,
              unit: 'each',
              subtotal: 80,
            ),
          ],
        ),
      );
      await ledger.saveReceipt(
        ExpenseReceiptRecord(
          id: 'fuel-2',
          receiptDate: DateTime(2026, 6, 3),
          merchantName: 'Fuel Stop',
          hasReceiptProof: true,
          vehicleId: 'truck_1',
          lines: const [
            ExpenseReceiptLineRecord(
              id: 'fuel-line-2',
              description: 'Diesel',
              category: 'Fuel',
              use: ExpenseLineUse.business,
              quantity: 10,
              unitsPerPackage: 1,
              unit: 'gallon',
              subtotal: 60,
              odometerReading: 1200,
            ),
          ],
        ),
      );

      final report = ExpenseRecapReport.fromLedger(
        ledger,
        ExpenseDateRange(
          start: DateTime(2026, 6, 1),
          end: DateTime(2026, 6, 30),
        ),
      );

      expect(report.totalExpenses, 300);
      expect(report.businessExpenses, 260);
      expect(report.personalExpenses, 40);
      expect(report.fuelExpense, 100);
      expect(report.materialsExpense, 120);
      expect(report.contractorCoreExpense, 120);
      expect(report.receiptCount, 3);
      expect(report.lineCount, 4);
      expect(report.receiptsMissingProof, 1);
      expect(report.splitReceiptCount, 1);
      expect(report.odometerMiles, 200);
      expect(report.vehicleCostPerMile, .5);
      expect(report.fuelCostPerMile, .5);
      expect(report.totalCostPerMile, 1.5);
      expect(report.averageFuelPrice, 5);
      expect(report.averageMpg, 10);

      final truckOneReport = ExpenseRecapReport.fromLedger(
        ledger,
        ExpenseDateRange(
          start: DateTime(2026, 6, 1),
          end: DateTime(2026, 6, 30),
        ),
        vehicleId: 'truck_1',
      );

      expect(truckOneReport.totalExpenses, 100);
      expect(truckOneReport.receiptCount, 2);
      expect(truckOneReport.materialsExpense, 0);
      expect(truckOneReport.fuelExpense, 100);
    },
  );

  test('expense recap uses completed full-to-full fuel cycles for MPG', () async {
    final ledger = ExpenseLedgerController.memory();
    for (final receipt in [
      _fuelCycleReceipt(
        id: 'full-start',
        date: DateTime(2026, 6, 1),
        odometer: 1000,
        gallons: 10,
        fillType: 'Full fill-up',
      ),
      _fuelCycleReceipt(
        id: 'partial-middle',
        date: DateTime(2026, 6, 5),
        odometer: 1100,
        gallons: 5,
        fillType: 'Partial fill',
      ),
      _fuelCycleReceipt(
        id: 'full-end',
        date: DateTime(2026, 6, 10),
        odometer: 1200,
        gallons: 7,
        fillType: 'Full fill-up',
      ),
    ]) {
      await ledger.saveReceipt(receipt);
    }

    final report = ExpenseRecapReport.fromLedger(
      ledger,
      ExpenseDateRange(
        start: DateTime(2026, 6, 1),
        end: DateTime(2026, 6, 30),
      ),
      vehicleId: 'truck_1',
    );

    expect(report.odometerMiles, 200);
    expect(report.fuelUnits, 22);
    expect(report.completedLiquidFillMiles, 200);
    expect(report.completedLiquidFillGallons, 12);
    expect(report.averageMpg, closeTo(16.667, .001));
  });

  test('all-vehicle recap keeps fuel metrics isolated by vehicle', () async {
    final ledger = ExpenseLedgerController.memory();
    await ledger.saveReceipt(
      _fuelCycleReceipt(
        id: 'truck-fuel',
        date: DateTime(2026, 6, 1),
        odometer: 1000,
        gallons: 10,
        fillType: 'Full fill-up',
      ),
    );
    await ledger.saveReceipt(
      _fuelCycleReceipt(
        id: 'van-fuel',
        date: DateTime(2026, 6, 2),
        odometer: 80000,
        gallons: 8,
        fillType: 'Full fill-up',
        vehicleId: 'van_1',
      ),
    );

    final report = ExpenseRecapReport.fromLedger(
      ledger,
      ExpenseDateRange(
        start: DateTime(2026, 6, 1),
        end: DateTime(2026, 6, 30),
      ),
    );

    expect(report.fuelUnits, 18);
    expect(report.liquidFuelExpense, 72);
    expect(report.odometerMiles, isNull);
    expect(report.averageMpg, isNull);
    expect(report.fuelCostPerMile, isNull);
  });

  test(
    'mixed-use vehicle expenses follow business and personal mileage share',
    () async {
      final ledger = ExpenseLedgerController.memory();
      await ledger.saveReceipt(
        ExpenseReceiptRecord(
          id: 'mixed-maintenance',
          receiptDate: DateTime(2026, 6, 10),
          merchantName: 'Quick Lube',
          vehicleId: 'truck_mixed',
          lines: const [
            ExpenseReceiptLineRecord(
              id: 'oil-change',
              description: 'Oil change',
              category: 'Maintenance',
              use: ExpenseLineUse.business,
              quantity: 1,
              unitsPerPackage: 1,
              unit: 'service',
              subtotal: 100,
            ),
            ExpenseReceiptLineRecord(
              id: 'explicit-split',
              description: 'Cabin cleaner',
              category: 'Vehicle Supplies',
              use: ExpenseLineUse.split,
              businessPercent: .25,
              quantity: 1,
              unitsPerPackage: 1,
              unit: 'each',
              subtotal: 40,
            ),
          ],
        ),
      );

      final report = ExpenseRecapReport.fromLedger(
        ledger,
        ExpenseDateRange(
          start: DateTime(2026, 6, 1),
          end: DateTime(2026, 6, 30),
        ),
        vehicleUsage: const {
          'truck_mixed': ExpenseVehicleUsageSnapshot(
            vehicleId: 'truck_mixed',
            businessMiles: 700,
            personalMiles: 300,
          ),
        },
      );

      expect(report.totalExpenses, 140);
      expect(report.businessExpenses, 80);
      expect(report.personalExpenses, 60);
      expect(report.businessVehicleMiles, 700);
      expect(report.personalVehicleMiles, 300);
      expect(report.vehicleBusinessUsePercent, .7);
      expect(report.vehiclePersonalUsePercent, .3);
    },
  );

  test(
    'expense recap counts EV charging fees in electric cost per mile',
    () async {
      final ledger = ExpenseLedgerController.memory();
      await ledger.saveReceipt(
        ExpenseReceiptRecord(
          id: 'ev-charge-1',
          receiptDate: DateTime(2026, 6, 5),
          merchantName: 'EVgo',
          vehicleId: 'van_ev',
          odometerReading: 40000,
          lines: const [
            ExpenseReceiptLineRecord(
              id: 'ev-energy-1',
              description: 'Charging session',
              category: 'Fuel',
              use: ExpenseLineUse.business,
              quantity: 40,
              unitsPerPackage: 1,
              unit: 'kWh',
              subtotal: 16,
              fuelType: 'Electric',
            ),
            ExpenseReceiptLineRecord(
              id: 'ev-session-fee',
              description: 'Session fee',
              category: 'Charging Fees',
              use: ExpenseLineUse.business,
              quantity: 1,
              unitsPerPackage: 1,
              unit: 'each',
              subtotal: 1.25,
            ),
          ],
        ),
      );
      await ledger.saveReceipt(
        ExpenseReceiptRecord(
          id: 'ev-charge-2',
          receiptDate: DateTime(2026, 6, 6),
          merchantName: 'EVgo',
          vehicleId: 'van_ev',
          odometerReading: 40120,
          lines: const [
            ExpenseReceiptLineRecord(
              id: 'ev-energy-2',
              description: 'Charging session',
              category: 'Fuel',
              use: ExpenseLineUse.business,
              quantity: 30,
              unitsPerPackage: 1,
              unit: 'kWh',
              subtotal: 12,
              fuelType: 'Electric',
            ),
            ExpenseReceiptLineRecord(
              id: 'ev-idle-fee',
              description: 'Idle fee',
              category: 'Charging Fees',
              use: ExpenseLineUse.business,
              quantity: 1,
              unitsPerPackage: 1,
              unit: 'each',
              subtotal: 2.75,
            ),
          ],
        ),
      );

      final report = ExpenseRecapReport.fromLedger(
        ledger,
        ExpenseDateRange(
          start: DateTime(2026, 6, 1),
          end: DateTime(2026, 6, 30),
        ),
      );

      expect(report.fuelExpense, 32);
      expect(report.liquidFuelExpense, 0);
      expect(report.electricFuelExpense, 32);
      expect(report.fuelUnits, 0);
      expect(report.electricKwh, 70);
      expect(report.odometerMiles, 120);
      expect(report.averageMpg, isNull);
      expect(report.milesPerKwh, closeTo(1.714, .001));
      expect(report.averageElectricKwhPrice, closeTo(.4571, .0001));
      expect(report.electricFuelCostPerMile, closeTo(.2667, .0001));
    },
  );

  test(
    'business-only vehicle usage leaves vehicle expenses business',
    () async {
      final ledger = ExpenseLedgerController.memory();
      await ledger.saveReceipt(
        ExpenseReceiptRecord(
          id: 'business-repair',
          receiptDate: DateTime(2026, 6, 10),
          merchantName: 'Repair Shop',
          vehicleId: 'truck_business',
          lines: const [
            ExpenseReceiptLineRecord(
              id: 'brakes',
              description: 'Brake repair',
              category: 'Repair',
              use: ExpenseLineUse.business,
              quantity: 1,
              unitsPerPackage: 1,
              unit: 'service',
              subtotal: 250,
            ),
          ],
        ),
      );

      final report = ExpenseRecapReport.fromLedger(
        ledger,
        ExpenseDateRange(
          start: DateTime(2026, 6, 1),
          end: DateTime(2026, 6, 30),
        ),
        vehicleUsage: const {
          'truck_business': ExpenseVehicleUsageSnapshot(
            vehicleId: 'truck_business',
            businessMiles: 900,
            personalMiles: 0,
          ),
        },
      );

      expect(report.businessExpenses, 250);
      expect(report.personalExpenses, 0);
      expect(report.vehicleBusinessUsePercent, 1);
      expect(report.vehiclePersonalUsePercent, 0);
    },
  );
}

ExpenseReceiptRecord _fuelCycleReceipt({
  required String id,
  required DateTime date,
  required int odometer,
  required double gallons,
  required String fillType,
  String vehicleId = 'truck_1',
}) {
  return ExpenseReceiptRecord(
    id: id,
    receiptDate: date,
    merchantName: 'Fuel Stop',
    vehicleId: vehicleId,
    lines: [
      ExpenseReceiptLineRecord(
        id: '$id-line',
        description: 'Gasoline',
        category: 'Fuel',
        use: ExpenseLineUse.business,
        quantity: gallons,
        unitsPerPackage: 1,
        unit: 'gallon',
        subtotal: gallons * 4,
        odometerReading: odometer,
        fuelType: 'Gasoline',
        fillType: fillType,
      ),
    ],
  );
}
