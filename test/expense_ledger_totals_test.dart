import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_store.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'expense_ledger_totals_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  test('receipt totals include entered sales tax and infer tax rate', () async {
    final ledger = await ExpenseLedgerController.create();
    await ledger.saveReceipt(
      ExpenseReceiptRecord(
        id: 'EXP-tax',
        receiptDate: DateTime(2026, 6, 12),
        enteredSubtotal: 100,
        enteredTax: 7,
        enteredTotal: 107,
        lines: const [
          ExpenseReceiptLineRecord(
            id: 'LINE-tax-business',
            description: 'Materials',
            category: 'Materials',
            use: ExpenseLineUse.business,
            quantity: 1,
            unitsPerPackage: 1,
            unit: 'each',
            subtotal: 75,
          ),
          ExpenseReceiptLineRecord(
            id: 'LINE-tax-personal',
            description: 'Personal supplies',
            category: 'Supplies',
            use: ExpenseLineUse.personal,
            quantity: 1,
            unitsPerPackage: 1,
            unit: 'each',
            subtotal: 25,
          ),
        ],
      ),
    );

    final receipt = ledger.receiptById('EXP-tax')!;
    final day = ledger.summaryForDay(DateTime(2026, 6, 12));

    expect(receipt.lineSubtotal, 100);
    expect(receipt.receiptTax, 7);
    expect(receipt.effectiveTaxRate, closeTo(.07, .0001));
    expect(receipt.total, 107);
    expect(receipt.businessTotal, closeTo(80.25, .001));
    expect(receipt.personalTotal, closeTo(26.75, .001));
    expect(day.total, 107);
    expect(day.business, closeTo(80.25, .001));
    expect(day.personal, closeTo(26.75, .001));
  });

  test('receipt can infer sales tax from subtotal and total', () async {
    final ledger = await ExpenseLedgerController.create();
    await ledger.saveReceipt(
      ExpenseReceiptRecord(
        id: 'EXP-tax-infer',
        receiptDate: DateTime(2026, 6, 12),
        enteredSubtotal: 50,
        enteredTotal: 53.25,
        lines: const [
          ExpenseReceiptLineRecord(
            id: 'LINE-tax-infer',
            description: 'Office supplies',
            category: 'Supplies',
            use: ExpenseLineUse.business,
            quantity: 1,
            unitsPerPackage: 1,
            unit: 'each',
            subtotal: 50,
          ),
        ],
      ),
    );

    final receipt = ledger.receiptById('EXP-tax-infer')!;

    expect(receipt.receiptTax, closeTo(3.25, .001));
    expect(receipt.effectiveTaxRate, closeTo(.065, .0001));
    expect(receipt.total, 53.25);
    expect(ledger.summaryForWeek(DateTime(2026, 6, 12)).business, 53.25);
  });

  test('split lines honor explicit business percentage', () async {
    final ledger = await ExpenseLedgerController.create();
    await ledger.saveReceipt(
      ExpenseReceiptRecord(
        id: 'EXP-split-percent',
        receiptDate: DateTime(2026, 6, 12),
        enteredSubtotal: 100,
        enteredTax: 8,
        enteredTotal: 108,
        lines: const [
          ExpenseReceiptLineRecord(
            id: 'LINE-split',
            description: 'Shared phone bill',
            category: 'Cell Phone',
            use: ExpenseLineUse.split,
            businessPercent: .75,
            quantity: 1,
            unitsPerPackage: 1,
            unit: 'each',
            subtotal: 100,
          ),
        ],
      ),
    );

    final receipt = ledger.receiptById('EXP-split-percent')!;
    final day = ledger.summaryForDay(DateTime(2026, 6, 12));

    expect(receipt.lines.single.businessAmount, 75);
    expect(receipt.lines.single.personalAmount, 25);
    expect(receipt.businessTotal, 81);
    expect(receipt.personalTotal, 27);
    expect(day.business, 81);
    expect(day.personal, 27);
  });

  test('editing a saved split percentage updates derived totals', () async {
    final ledger = await ExpenseLedgerController.create();
    await ledger.saveReceipt(
      ExpenseReceiptRecord(
        id: 'EXP-split-edit',
        receiptDate: DateTime(2026, 6, 12),
        enteredSubtotal: 100,
        enteredTax: 10,
        enteredTotal: 110,
        lines: const [
          ExpenseReceiptLineRecord(
            id: 'LINE-split-edit',
            description: 'Shared internet bill',
            category: 'Internet',
            use: ExpenseLineUse.split,
            businessPercent: .50,
            quantity: 1,
            unitsPerPackage: 1,
            unit: 'each',
            subtotal: 100,
          ),
        ],
      ),
    );

    expect(ledger.summaryForMonth(DateTime(2026, 6, 20)).business, 55);

    await ledger.replaceLine(
      receiptId: 'EXP-split-edit',
      line: const ExpenseReceiptLineRecord(
        id: 'LINE-split-edit',
        description: 'Shared internet bill',
        category: 'Internet',
        use: ExpenseLineUse.split,
        businessPercent: .80,
        quantity: 1,
        unitsPerPackage: 1,
        unit: 'each',
        subtotal: 100,
      ),
    );

    final loaded = ledger.receiptById('EXP-split-edit')!;
    final month = ledger.summaryForMonth(DateTime(2026, 6, 20));

    expect(loaded.lines.single.businessPercent, .80);
    expect(loaded.businessTotal, 88);
    expect(loaded.personalTotal, closeTo(22, .001));
    expect(month.business, 88);
    expect(month.personal, closeTo(22, .001));
    expect(loaded.auditEvents.last, contains('updated receipt EXP-split-edit'));
  });

  test('deleting a saved receipt line updates derived totals', () async {
    final ledger = await ExpenseLedgerController.create();
    await ledger.saveReceipt(
      ExpenseReceiptRecord(
        id: 'EXP-delete-line',
        receiptDate: DateTime(2026, 6, 10),
        lines: const [
          ExpenseReceiptLineRecord(
            id: 'LINE-business',
            description: 'Fuel',
            category: 'Fuel',
            use: ExpenseLineUse.business,
            quantity: 1,
            unitsPerPackage: 1,
            unit: 'each',
            subtotal: 80,
          ),
          ExpenseReceiptLineRecord(
            id: 'LINE-personal',
            description: 'Coffee',
            category: 'Meals',
            use: ExpenseLineUse.personal,
            quantity: 1,
            unitsPerPackage: 1,
            unit: 'each',
            subtotal: 12,
          ),
        ],
      ),
    );

    expect(ledger.summaryForWeek(DateTime(2026, 6, 11)).total, 92);

    await ledger.deleteLine(
      receiptId: 'EXP-delete-line',
      lineId: 'LINE-personal',
    );

    final loaded = ledger.receiptById('EXP-delete-line')!;
    final week = ledger.summaryForWeek(DateTime(2026, 6, 11));

    expect(loaded.lines.map((line) => line.id), ['LINE-business']);
    expect(week.total, 80);
    expect(week.business, 80);
    expect(week.personal, 0);
  });

  test(
    'editing saved receipt info moves derived totals to the new date',
    () async {
      final ledger = await ExpenseLedgerController.create();
      await ledger.saveReceipt(
        ExpenseReceiptRecord(
          id: 'EXP-info-edit',
          receiptDate: DateTime(2026, 6, 10),
          merchantName: 'Original Store',
          lines: const [
            ExpenseReceiptLineRecord(
              id: 'LINE-info-edit',
              description: 'Fuel',
              category: 'Fuel',
              use: ExpenseLineUse.business,
              quantity: 1,
              unitsPerPackage: 1,
              unit: 'gallon',
              subtotal: 60,
            ),
          ],
        ),
      );

      final original = ledger.receiptById('EXP-info-edit')!;
      await ledger.saveReceipt(
        original.copyWith(
          receiptDate: DateTime(2026, 6, 12),
          receiptTimeMinutes: (14 * 60) + 30,
          merchantName: 'Updated Store',
          notes: 'Backdated receipt correction',
          hasReceiptProof: true,
        ),
      );

      final loaded = ledger.receiptById('EXP-info-edit')!;

      expect(ledger.summaryForDay(DateTime(2026, 6, 10)).total, 0);
      expect(ledger.summaryForDay(DateTime(2026, 6, 12)).total, 60);
      expect(loaded.merchantName, 'Updated Store');
      expect(loaded.receiptTimeMinutes, (14 * 60) + 30);
      expect(loaded.notes, 'Backdated receipt correction');
      expect(loaded.hasReceiptProof, isTrue);
      expect(loaded.auditEvents.length, 2);
    },
  );
}
