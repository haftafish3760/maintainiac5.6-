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
