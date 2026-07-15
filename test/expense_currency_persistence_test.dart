import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_store.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_scope_filter.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_store.dart';

void main() {
  const line = ExpenseReceiptLineRecord(
    id: 'line-1',
    description: 'Receipt line',
    category: 'Tools',
    use: ExpenseLineUse.business,
    quantity: 1,
    unitsPerPackage: 1,
    unit: 'each',
    subtotal: 12.34,
    unitPrice: 12.34,
  );

  test('receipt persistence writes integer cents alongside legacy amounts', () {
    final receipt = ExpenseReceiptRecord(
      id: 'receipt-1',
      receiptDate: DateTime(2026, 7, 14),
      enteredSubtotal: 12.34,
      enteredTax: 0.99,
      enteredTotal: 13.33,
      lines: const [line],
    );

    final map = receipt.toMap();

    expect(map['enteredSubtotalCents'], 1234);
    expect(map['enteredTaxCents'], 99);
    expect(map['enteredTotalCents'], 1333);
    expect((map['lines'] as List).single['subtotalCents'], 1234);
    expect((map['lines'] as List).single['unitPriceCents'], 1234);
  });

  test('integer cents take priority when reading a receipt record', () {
    final restored = ExpenseReceiptRecord.fromMap({
      'id': 'receipt-2',
      'receiptDate': '2026-07-14T00:00:00.000',
      'enteredSubtotal': 12.35,
      'enteredSubtotalCents': 1234,
      'enteredTax': 1.01,
      'enteredTaxCents': 99,
      'enteredTotal': 13.36,
      'enteredTotalCents': 1333,
      'lines': [
        {
          'id': 'line-2',
          'description': 'Receipt line',
          'category': 'Tools',
          'use': 'business',
          'quantity': 1,
          'unitsPerPackage': 1,
          'unit': 'each',
          'subtotal': 12.35,
          'subtotalCents': 1234,
        },
      ],
    });

    expect(restored.enteredSubtotalCents, 1234);
    expect(restored.enteredTaxCents, 99);
    expect(restored.enteredTotalCents, 1333);
    expect(restored.lines.single.subtotalCents, 1234);
  });

  test('draft persistence uses the same integer cents contract', () {
    final draft = ExpenseReceiptDraftRecord(
      id: 'draft-1',
      receiptDate: DateTime(2026, 7, 14),
      enteredTotal: 12.34,
      updatedAt: DateTime(2026, 7, 14),
      lines: const [line],
    );

    final restored = ExpenseReceiptDraftRecord.fromMap(draft.toMap());

    expect(restored.enteredTotalCents, 1234);
    expect(restored.lines.single.subtotalCents, 1234);
  });

  test('ledger recap aggregates cents without decimal drift', () async {
    final ledger = ExpenseLedgerController.memory();
    for (var index = 0; index < 10; index++) {
      await ledger.saveReceipt(
        ExpenseReceiptRecord(
          id: 'receipt-$index',
          receiptDate: DateTime(2026, 7, 14),
          enteredTotal: 0.10,
          lines: const [
            ExpenseReceiptLineRecord(
              id: 'line',
              description: 'Small charge',
              category: 'Tools',
              use: ExpenseLineUse.business,
              quantity: 1,
              unitsPerPackage: 1,
              unit: 'each',
              subtotal: 0.10,
            ),
          ],
        ),
      );
    }

    final summary = ledger.summaryForDay(DateTime(2026, 7, 14));

    expect(summary.totalCents, 100);
    expect(summary.businessCents, 100);
    expect(summary.personalCents, 0);
    expect(summary.total, 1);
  });

  test('receipt and draft preserve their historical operating context', () {
    const context = ExpenseReceiptContextSnapshot(
      workProfileId: 'delivery',
      workProfileName: 'Evening Delivery',
      vehicleId: 'van-7',
      vehicleLabel: 'Cargo Van',
      jobId: 'job-42',
      jobLabel: 'Kitchen repair',
    );
    final receipt = ExpenseReceiptRecord.fromMap(
      ExpenseReceiptRecord(
        id: 'EXP-context',
        receiptDate: DateTime(2026, 7, 14),
        contextSnapshot: context,
        lines: const [],
      ).toMap(),
    );
    final draft = ExpenseReceiptDraftRecord.fromMap(
      ExpenseReceiptDraftRecord(
        id: 'DRAFT-context',
        receiptDate: DateTime(2026, 7, 14),
        updatedAt: DateTime(2026, 7, 14),
        contextSnapshot: context,
      ).toMap(),
    );

    expect(receipt.contextSnapshot.workProfileName, 'Evening Delivery');
    expect(receipt.contextSnapshot.vehicleId, 'van-7');
    expect(receipt.contextSnapshot.jobId, 'job-42');
    expect(draft.contextSnapshot.jobLabel, 'Kitchen repair');
  });

  test(
    'recaps respect work, vehicle, and job scope without changing dates',
    () async {
      final ledger = ExpenseLedgerController.memory();
      final day = DateTime(2026, 7, 14);
      Future<void> save({
        required String id,
        required int cents,
        required ExpenseReceiptContextSnapshot context,
      }) => ledger.saveReceipt(
        ExpenseReceiptRecord(
          id: id,
          receiptDate: day,
          contextSnapshot: context,
          lines: [
            ExpenseReceiptLineRecord(
              id: '$id-line',
              description: 'Receipt total',
              category: 'Tools',
              use: ExpenseLineUse.business,
              quantity: 1,
              unitsPerPackage: 1,
              unit: 'each',
              subtotal: cents / 100,
            ),
          ],
        ),
      );
      await save(
        id: 'delivery-van',
        cents: 1250,
        context: const ExpenseReceiptContextSnapshot(
          workProfileId: 'delivery',
          vehicleId: 'van',
          jobId: 'job-a',
        ),
      );
      await save(
        id: 'repair-truck',
        cents: 800,
        context: const ExpenseReceiptContextSnapshot(
          workProfileId: 'repair',
          vehicleId: 'truck',
          jobId: 'job-b',
        ),
      );
      final range = ExpenseDateRange(start: day, end: day);

      expect(ledger.summaryForRange(range).totalCents, 2050);
      expect(
        ledger
            .summaryForRange(
              range,
              scope: const ExpenseLedgerScopeFilter(workProfileId: 'delivery'),
            )
            .totalCents,
        1250,
      );
      expect(
        ledger
            .summaryForRange(
              range,
              scope: const ExpenseLedgerScopeFilter(vehicleId: 'truck'),
            )
            .totalCents,
        800,
      );
      expect(
        ledger
            .summaryForRange(
              range,
              scope: const ExpenseLedgerScopeFilter(jobId: 'job-a'),
            )
            .totalCents,
        1250,
      );
    },
  );
}
