import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_scope_filter.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_store.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'expense_ledger_store_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  test(
    'saves receipts and derives calendar/day summaries from source records',
    () async {
      final ledger = await ExpenseLedgerController.create();
      await ledger.saveReceipt(
        ExpenseReceiptRecord(
          id: 'EXP-1',
          receiptDate: DateTime(2026, 6, 8),
          receiptTimeMinutes: (9 * 60) + 15,
          merchantName: 'Lowes',
          lines: const [
            ExpenseReceiptLineRecord(
              id: 'LINE-1',
              description: 'Materials',
              category: 'Materials',
              use: ExpenseLineUse.business,
              quantity: 1,
              unitsPerPackage: 1,
              unit: 'each',
              subtotal: 100,
            ),
          ],
        ),
      );
      await ledger.saveReceipt(
        ExpenseReceiptRecord(
          id: 'EXP-2',
          receiptDate: DateTime(2026, 6, 8),
          merchantName: 'Coffee',
          lines: const [
            ExpenseReceiptLineRecord(
              id: 'LINE-2',
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

      final dayRecords = ledger.receiptsForDay(DateTime(2026, 6, 8));
      final day = ledger.summaryForDay(DateTime(2026, 6, 8));
      final week = ledger.summaryForWeek(DateTime(2026, 6, 11));

      expect(dayRecords.map((record) => record.id), ['EXP-1', 'EXP-2']);
      expect(day.total, 112);
      expect(day.business, 100);
      expect(day.personal, 12);
      expect(week.total, 112);
    },
  );

  test(
    'loads around malformed local receipt values without crashing',
    () async {
      final box = await Hive.openBox<dynamic>(ExpenseLedgerController.boxName);
      await box.put('bad-type', 'not a receipt map');
      await box.put('malformed-map', {
        'id': 42,
        'receiptDate': 20260608,
        'receiptTimeMinutes': '615',
        'merchantName': 12345,
        'hasReceiptProof': 'true',
        'enteredTotal': '18.75',
        'lines': [
          {
            'id': 1,
            'description': 99,
            'category': true,
            'use': 'personal',
            'quantity': '2',
            'unitsPerPackage': '1',
            'subtotal': '9.25',
            'parserNeedsReview': 'yes',
          },
        ],
      });

      final ledger = await ExpenseLedgerController.create();
      final receipts = ledger.storedReceipts;

      expect(receipts, hasLength(1));
      expect(receipts.single.id, '42');
      expect(receipts.single.receiptTimeMinutes, 615);
      expect(receipts.single.hasReceiptProof, isTrue);
      expect(receipts.single.enteredTotal, 18.75);
      expect(receipts.single.lines.single.description, '99');
      expect(receipts.single.lines.single.parserNeedsReview, isTrue);
    },
  );

  test(
    'backdated line edits update later summaries without cached totals',
    () async {
      final ledger = await ExpenseLedgerController.create();
      const originalLine = ExpenseReceiptLineRecord(
        id: 'LINE-1',
        description: 'Fuel',
        category: 'Fuel',
        use: ExpenseLineUse.business,
        quantity: 10,
        unitsPerPackage: 1,
        unit: 'gallon',
        subtotal: 40,
      );
      await ledger.saveReceipt(
        ExpenseReceiptRecord(
          id: 'EXP-edit',
          receiptDate: DateTime(2026, 6, 1),
          lines: const [originalLine],
        ),
      );

      expect(ledger.summaryForMonth(DateTime(2026, 6, 20)).total, 40);

      await ledger.replaceLine(
        receiptId: 'EXP-edit',
        line: const ExpenseReceiptLineRecord(
          id: 'LINE-1',
          description: 'Fuel',
          category: 'Fuel',
          use: ExpenseLineUse.business,
          quantity: 10,
          unitsPerPackage: 1,
          unit: 'gallon',
          subtotal: 55,
        ),
      );

      final month = ledger.summaryForMonth(DateTime(2026, 6, 20));
      final loaded = ledger.receiptById('EXP-edit')!;

      expect(month.total, 55);
      expect(month.business, 55);
      expect(loaded.auditEvents, isNotEmpty);
    },
  );

  test(
    'calendar day uses receipt date and entered time before entry order',
    () async {
      final ledger = await ExpenseLedgerController.create();
      const line = ExpenseReceiptLineRecord(
        id: 'LINE',
        description: 'Expense',
        category: 'Fuel',
        use: ExpenseLineUse.business,
        quantity: 1,
        unitsPerPackage: 1,
        unit: 'each',
        subtotal: 10,
      );

      await ledger.saveReceipt(
        ExpenseReceiptRecord(
          id: 'EXP-friday-entry-tuesday-9am',
          receiptDate: DateTime(2026, 6, 9),
          receiptTimeMinutes: 9 * 60,
          merchantName: 'Tuesday 9 AM',
          createdAt: DateTime(2026, 6, 12, 18),
          lines: const [line],
        ),
      );
      await ledger.saveReceipt(
        ExpenseReceiptRecord(
          id: 'EXP-friday-entry-tuesday-8am',
          receiptDate: DateTime(2026, 6, 9),
          receiptTimeMinutes: 8 * 60,
          merchantName: 'Tuesday 8 AM',
          createdAt: DateTime(2026, 6, 12, 19),
          lines: const [line],
        ),
      );
      await ledger.saveReceipt(
        ExpenseReceiptRecord(
          id: 'EXP-friday-entry-tuesday-no-time-first',
          receiptDate: DateTime(2026, 6, 9),
          merchantName: 'No Time First',
          createdAt: DateTime(2026, 6, 12, 20),
          lines: const [line],
        ),
      );
      await ledger.saveReceipt(
        ExpenseReceiptRecord(
          id: 'EXP-friday-entry-tuesday-no-time-second',
          receiptDate: DateTime(2026, 6, 9),
          merchantName: 'No Time Second',
          createdAt: DateTime(2026, 6, 12, 21),
          lines: const [line],
        ),
      );
      await ledger.saveReceipt(
        ExpenseReceiptRecord(
          id: 'EXP-actual-friday',
          receiptDate: DateTime(2026, 6, 12),
          receiptTimeMinutes: 7 * 60,
          merchantName: 'Friday',
          createdAt: DateTime(2026, 6, 12, 7),
          lines: const [line],
        ),
      );

      final tuesday = ledger.receiptsForDay(DateTime(2026, 6, 9));
      final friday = ledger.receiptsForDay(DateTime(2026, 6, 12));

      expect(tuesday.map((receipt) => receipt.id), [
        'EXP-friday-entry-tuesday-8am',
        'EXP-friday-entry-tuesday-9am',
        'EXP-friday-entry-tuesday-no-time-first',
        'EXP-friday-entry-tuesday-no-time-second',
      ]);
      expect(friday.map((receipt) => receipt.id), ['EXP-actual-friday']);
    },
  );

  test(
    'backdated receipt edits update day week month and year recaps',
    () async {
      final ledger = await ExpenseLedgerController.create();
      const originalLine = ExpenseReceiptLineRecord(
        id: 'LINE-backdated',
        description: 'Backdated expense',
        category: 'Materials',
        use: ExpenseLineUse.business,
        quantity: 1,
        unitsPerPackage: 1,
        unit: 'each',
        subtotal: 80,
      );
      await ledger.saveReceipt(
        ExpenseReceiptRecord(
          id: 'EXP-backdated',
          receiptDate: DateTime(2026, 5, 12),
          receiptTimeMinutes: 10 * 60,
          createdAt: DateTime(2026, 6, 12, 18),
          lines: const [originalLine],
        ),
      );

      ExpenseLedgerSummary yearToDate() => ledger.summaryForRange(
        ExpenseDateRange(start: DateTime(2026), end: DateTime(2026, 6, 24)),
      );

      expect(ledger.summaryForDay(DateTime(2026, 5, 12)).total, 80);
      expect(ledger.summaryForWeek(DateTime(2026, 5, 12)).total, 80);
      expect(ledger.summaryForMonth(DateTime(2026, 5, 20)).total, 80);
      expect(yearToDate().total, 80);

      await ledger.replaceLine(
        receiptId: 'EXP-backdated',
        line: const ExpenseReceiptLineRecord(
          id: 'LINE-backdated',
          description: 'Backdated expense',
          category: 'Materials',
          use: ExpenseLineUse.business,
          quantity: 1,
          unitsPerPackage: 1,
          unit: 'each',
          subtotal: 125,
        ),
      );

      expect(ledger.summaryForDay(DateTime(2026, 5, 12)).total, 125);
      expect(ledger.summaryForWeek(DateTime(2026, 5, 12)).total, 125);
      expect(ledger.summaryForMonth(DateTime(2026, 5, 20)).total, 125);
      expect(yearToDate().total, 125);
    },
  );

  test(
    'scope filters keep all-profile, vehicle, and job recaps exact',
    () async {
      final ledger = await ExpenseLedgerController.create();
      Future<void> save({
        required String id,
        required int total,
        required ExpenseReceiptContextSnapshot context,
      }) => ledger.saveReceipt(
        ExpenseReceiptRecord(
          id: id,
          receiptDate: DateTime(2026, 6, 8),
          contextSnapshot: context,
          lines: [
            ExpenseReceiptLineRecord(
              id: 'LINE-$id',
              description: 'Expense',
              category: 'Materials',
              use: ExpenseLineUse.business,
              quantity: 1,
              unitsPerPackage: 1,
              unit: 'each',
              subtotal: total.toDouble(),
            ),
          ],
        ),
      );

      await save(
        id: 'EXP-job-a',
        total: 25,
        context: const ExpenseReceiptContextSnapshot(
          workProfileId: 'work-a',
          vehicleId: 'vehicle-a',
          jobId: 'job-a',
        ),
      );
      await save(
        id: 'EXP-job-b',
        total: 40,
        context: const ExpenseReceiptContextSnapshot(
          workProfileId: 'work-a',
          vehicleId: 'vehicle-b',
          jobId: 'job-b',
        ),
      );
      await save(
        id: 'EXP-work-b',
        total: 65,
        context: const ExpenseReceiptContextSnapshot(
          workProfileId: 'work-b',
          vehicleId: 'vehicle-a',
        ),
      );

      final range = ExpenseDateRange(
        start: DateTime(2026, 6, 1),
        end: DateTime(2026, 6, 30),
      );
      expect(ledger.summaryForRange(range).total, 130);
      expect(
        ledger
            .summaryForRange(
              range,
              scope: const ExpenseLedgerScopeFilter(
                workProfileId: 'work-a',
                vehicleId: 'vehicle-a',
              ),
            )
            .total,
        25,
      );
      expect(
        ledger
            .summaryForRange(
              range,
              scope: const ExpenseLedgerScopeFilter(jobId: 'job-b'),
            )
            .total,
        40,
      );
    },
  );

  test(
    'backdated creates, edits, and deletes immediately recalculate every affected recap',
    () async {
      final ledger = await ExpenseLedgerController.create();
      const currentLine = ExpenseReceiptLineRecord(
        id: 'LINE-current',
        description: 'Current expense',
        category: 'Tools',
        use: ExpenseLineUse.business,
        quantity: 1,
        unitsPerPackage: 1,
        unit: 'each',
        subtotal: 10,
      );
      const historicalLine = ExpenseReceiptLineRecord(
        id: 'LINE-history',
        description: 'Historical expense',
        category: 'Materials',
        use: ExpenseLineUse.business,
        quantity: 1,
        unitsPerPackage: 1,
        unit: 'each',
        subtotal: 30,
      );
      final yearRange = ExpenseDateRange(
        start: DateTime(2026),
        end: DateTime(2026, 12, 31),
      );

      await ledger.saveReceipt(
        ExpenseReceiptRecord(
          id: 'EXP-current',
          receiptDate: DateTime(2026, 7, 15),
          lines: const [currentLine],
        ),
      );
      expect(ledger.summaryForRange(yearRange).total, 10);

      await ledger.saveReceipt(
        ExpenseReceiptRecord(
          id: 'EXP-historical',
          receiptDate: DateTime(2026, 1, 4),
          lines: const [historicalLine],
        ),
      );
      expect(ledger.summaryForDay(DateTime(2026, 1, 4)).total, 30);
      expect(ledger.summaryForWeek(DateTime(2026, 1, 4)).total, 30);
      expect(ledger.summaryForMonth(DateTime(2026, 1, 20)).total, 30);
      expect(ledger.summaryForRange(yearRange).total, 40);

      await ledger.saveReceipt(
        ExpenseReceiptRecord(
          id: 'EXP-historical',
          receiptDate: DateTime(2026, 1, 4),
          lines: const [
            ExpenseReceiptLineRecord(
              id: 'LINE-history',
              description: 'Historical expense corrected',
              category: 'Materials',
              use: ExpenseLineUse.business,
              quantity: 1,
              unitsPerPackage: 1,
              unit: 'each',
              subtotal: 55,
            ),
          ],
        ),
      );
      expect(ledger.summaryForDay(DateTime(2026, 1, 4)).total, 55);
      expect(ledger.summaryForRange(yearRange).total, 65);

      await ledger.deleteReceipt('EXP-historical');
      expect(ledger.summaryForDay(DateTime(2026, 1, 4)).total, 0);
      expect(ledger.summaryForWeek(DateTime(2026, 1, 4)).total, 0);
      expect(ledger.summaryForMonth(DateTime(2026, 1, 20)).total, 0);
      expect(ledger.summaryForRange(yearRange).total, 10);
    },
  );

  test('dollar and quantity splits reconcile in ledger recaps', () async {
    final ledger = await ExpenseLedgerController.create();
    await ledger.saveReceipt(
      ExpenseReceiptRecord(
        id: 'EXP-split-methods',
        receiptDate: DateTime(2026, 7, 15),
        lines: const [
          ExpenseReceiptLineRecord(
            id: 'LINE-dollar',
            description: 'Shared purchase',
            category: 'Materials',
            use: ExpenseLineUse.split,
            quantity: 1,
            unitsPerPackage: 1,
            unit: 'each',
            subtotal: 40,
            splitAllocationMethod: ExpenseSplitAllocationMethod.dollar,
            businessSplitValue: 24,
          ),
          ExpenseReceiptLineRecord(
            id: 'LINE-quantity',
            description: 'Shared supplies',
            category: 'Materials',
            use: ExpenseLineUse.split,
            quantity: 10,
            unitsPerPackage: 1,
            unit: 'each',
            subtotal: 50,
            splitAllocationMethod: ExpenseSplitAllocationMethod.quantity,
            businessSplitValue: 6,
          ),
        ],
      ),
    );

    final recap = ledger.summaryForDay(DateTime(2026, 7, 15));
    expect(recap.total, 90);
    expect(recap.business, 54);
    expect(recap.personal, 36);
  });
}
