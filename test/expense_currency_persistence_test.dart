import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
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

  test('integer cents take priority over legacy floating point values', () {
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
    expect(summary.unclassifiedCents, 0);
    expect(summary.total, 1);
  });

  test(
    'cent allocation preserves exact receipt total across classifications',
    () {
      final receipt = ExpenseReceiptRecord(
        id: 'receipt-rounding',
        receiptDate: DateTime(2026, 7, 14),
        enteredTotal: 0.04,
        lines: const [
          ExpenseReceiptLineRecord(
            id: 'business',
            description: 'Business',
            category: 'Tools',
            use: ExpenseLineUse.business,
            quantity: 1,
            unitsPerPackage: 1,
            unit: 'each',
            subtotal: 0.01,
          ),
          ExpenseReceiptLineRecord(
            id: 'personal',
            description: 'Personal',
            category: 'Other',
            use: ExpenseLineUse.personal,
            quantity: 1,
            unitsPerPackage: 1,
            unit: 'each',
            subtotal: 0.01,
          ),
          ExpenseReceiptLineRecord(
            id: 'unknown',
            description: 'Unknown',
            category: 'Uncategorized',
            use: ExpenseLineUse.unclassified,
            quantity: 1,
            unitsPerPackage: 1,
            unit: 'each',
            subtotal: 0.01,
          ),
        ],
      );

      expect(
        receipt.businessTotalCents +
            receipt.personalTotalCents +
            receipt.unclassifiedTotalCents,
        receipt.totalCents,
      );
    },
  );
}
