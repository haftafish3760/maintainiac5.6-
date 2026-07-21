import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_store.dart';
import 'package:maintaniac/shared/storage/app_storage_guard.dart';

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
    'does not claim a receipt is saved when device storage is full',
    () async {
      final ledger = ExpenseLedgerController.memory(
        storageCheck: () async => const AppStorageCheck(
          availableBytes: 0,
          operationBytes: AppStorageGuard.smallRecordWriteBytes,
          requiredBytes: AppStorageGuard.smallRecordWriteBytes + 1,
          purpose: AppStoragePurpose.smallRecordWrite,
        ),
      );

      await expectLater(
        () => ledger.saveReceipt(
          ExpenseReceiptRecord(
            id: 'blocked-storage',
            receiptDate: DateTime(2026, 7, 15),
            lines: const [
              ExpenseReceiptLineRecord(
                id: 'blocked-storage-line',
                description: 'Storage test',
                category: 'Other',
                use: ExpenseLineUse.unclassified,
                quantity: 1,
                unitsPerPackage: 1,
                unit: 'each',
                subtotal: 10,
              ),
            ],
          ),
        ),
        throwsA(isA<StateError>()),
      );
      expect(ledger.receiptById('blocked-storage'), isNull);
    },
  );

  test('storage can be checked before receipt proof promotion', () async {
    final ledger = ExpenseLedgerController.memory(
      storageCheck: () async => const AppStorageCheck(
        availableBytes: 0,
        operationBytes: AppStorageGuard.smallRecordWriteBytes,
        requiredBytes: AppStorageGuard.smallRecordWriteBytes + 1,
        purpose: AppStoragePurpose.smallRecordWrite,
      ),
    );

    await expectLater(
      ledger.ensureStorageForLocalSave,
      throwsA(isA<StateError>()),
    );
  });

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

  test('deleted receipts do not block a new duplicate-proof review', () async {
    final ledger = ExpenseLedgerController.memory();
    final deleted = await ledger.saveReceipt(
      ExpenseReceiptRecord(
        id: 'deleted-proof',
        receiptDate: DateTime(2026, 7, 15),
        fileHashSha256: 'same-proof',
        lines: const [],
      ),
    );
    await ledger.deleteReceipt(deleted.id);

    final result = ledger.checkDuplicatesFor(
      ExpenseReceiptRecord(
        id: 'new-proof',
        receiptDate: DateTime(2026, 7, 15),
        fileHashSha256: 'same-proof',
        lines: const [],
      ),
    );

    expect(result.candidates, isEmpty);
  });

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
    'soft deletes and restores a receipt without corrupting its history',
    () async {
      final ledger = await ExpenseLedgerController.create();
      final saved = await ledger.saveReceipt(
        ExpenseReceiptRecord(
          id: 'EXP-lifecycle',
          receiptDate: DateTime(2026, 7, 15),
          ocrReview: const ExpenseReceiptOcrReview(
            severity: 'review',
            recoveryAction: 'review_receipt_manually',
          ),
          lines: const [
            ExpenseReceiptLineRecord(
              id: 'LINE-lifecycle',
              description: 'Receipt proof',
              category: 'Supplies',
              use: ExpenseLineUse.business,
              quantity: 1,
              unitsPerPackage: 1,
              unit: 'each',
              subtotal: 25,
            ),
          ],
        ),
      );

      expect(saved.localRevision, 1);
      expect(saved.isActive, isTrue);
      expect(ledger.ocrRecoveryActionCounts, {'review_receipt_manually': 1});

      final deleted = await ledger.deleteReceipt(saved.id);
      expect(deleted, isNotNull);
      expect(deleted!.isDeleted, isTrue);
      expect(deleted.deletedAt, isNotNull);
      expect(deleted.localRevision, 2);
      expect(ledger.receipts, isEmpty);
      expect(ledger.receiptsNeedingOcrReview, isEmpty);
      expect(ledger.ocrRecoveryActionCounts, isEmpty);
      expect(ledger.summaryForMonth(DateTime(2026, 7)).total, 0);
      expect(ledger.receiptById(saved.id)!.auditEvents, hasLength(2));
      expect(
        ledger.saveReceipt(saved.copyWith(merchantName: 'Stale edit')),
        throwsA(isA<StateError>()),
      );
      expect(
        ledger.replaceLine(receiptId: saved.id, line: saved.lines.single),
        completion(isNull),
      );
      expect(
        ledger.deleteLine(receiptId: saved.id, lineId: saved.lines.single.id),
        completion(isNull),
      );

      final restored = await ledger.restoreReceipt(saved.id);
      expect(restored, isNotNull);
      expect(restored!.isActive, isTrue);
      expect(restored.deletedAt, isNull);
      expect(restored.localRevision, 3);
      expect(ledger.receiptsNeedingOcrReview, hasLength(1));
      expect(ledger.ocrRecoveryActionCounts, {'review_receipt_manually': 1});
      expect(ledger.summaryForMonth(DateTime(2026, 7)).total, 25);
      expect(ledger.receiptById(saved.id)!.auditEvents, hasLength(3));
    },
  );

  test(
    'persists a deleted receipt and its restore across a Hive restart',
    () async {
      final initial = await ExpenseLedgerController.create();
      final saved = await initial.saveReceipt(
        ExpenseReceiptRecord(
          id: 'EXP-restart-lifecycle',
          receiptDate: DateTime(2026, 7, 15),
          lines: const [
            ExpenseReceiptLineRecord(
              id: 'LINE-restart-lifecycle',
              description: 'Saved proof',
              category: 'Supplies',
              use: ExpenseLineUse.business,
              quantity: 1,
              unitsPerPackage: 1,
              unit: 'each',
              subtotal: 18,
            ),
          ],
        ),
      );
      await initial.deleteReceipt(saved.id);

      await Hive.close();
      Hive.init(hiveDirectory.path);
      final afterDelete = await ExpenseLedgerController.create();
      final deleted = afterDelete.receiptById(saved.id)!;

      expect(deleted.isDeleted, isTrue);
      expect(deleted.localRevision, 2);
      expect(deleted.deletedAt, isNotNull);
      expect(afterDelete.receipts, isEmpty);

      await afterDelete.restoreReceipt(saved.id);
      await Hive.close();
      Hive.init(hiveDirectory.path);
      final afterRestore = await ExpenseLedgerController.create();
      final restored = afterRestore.receiptById(saved.id)!;

      expect(restored.isActive, isTrue);
      expect(restored.deletedAt, isNull);
      expect(restored.localRevision, 3);
      expect(afterRestore.summaryForMonth(DateTime(2026, 7)).total, 18);
    },
  );
}
