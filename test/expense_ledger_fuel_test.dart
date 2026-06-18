import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_store.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'expense_ledger_fuel_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  test('fuel receipt lines preserve odometer and fill metadata', () async {
    final ledger = await ExpenseLedgerController.create();
    await ledger.saveReceipt(
      ExpenseReceiptRecord(
        id: 'EXP-fuel',
        receiptDate: DateTime(2026, 6, 12),
        lines: const [
          ExpenseReceiptLineRecord(
            id: 'LINE-fuel',
            description: 'Diesel fuel',
            category: 'Fuel',
            use: ExpenseLineUse.business,
            quantity: 12.5,
            unitsPerPackage: 1,
            unit: 'gallon',
            subtotal: 48.75,
            odometerReading: 298225,
            fuelType: 'Diesel',
            fillType: 'Partial fill',
            unitPrice: 3.90,
          ),
        ],
      ),
    );

    final loaded = ledger.receiptById('EXP-fuel')!.lines.single;

    expect(loaded.odometerReading, 298225);
    expect(loaded.fuelType, 'Diesel');
    expect(loaded.fillType, 'Partial fill');
    expect(loaded.unitPrice, 3.90);
  });
}
