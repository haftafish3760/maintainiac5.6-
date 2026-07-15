import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';

void main() {
  ExpenseReceiptLineRecord line(ExpenseSplitAllocation allocation) {
    return ExpenseReceiptLineRecord(
      id: 'line-1',
      description: 'Fasteners',
      category: 'Materials',
      use: ExpenseLineUse.split,
      quantity: 10,
      unitsPerPackage: 1,
      unit: 'each',
      subtotal: 25,
      splitAllocation: allocation,
    );
  }

  test(
    'percentage, amount, and quantity allocations reconcile a split line',
    () {
      expect(
        line(
          const ExpenseSplitAllocation(
            method: ExpenseSplitAllocationMethod.percentage,
            businessValue: .6,
          ),
        ).businessAmount,
        15,
      );
      expect(
        line(
          const ExpenseSplitAllocation(
            method: ExpenseSplitAllocationMethod.amount,
            businessValue: 10,
          ),
        ).effectiveBusinessPercent,
        .4,
      );
      expect(
        line(
          const ExpenseSplitAllocation(
            method: ExpenseSplitAllocationMethod.quantity,
            businessValue: 3,
          ),
        ).personalAmount,
        17.5,
      );
    },
  );

  test('invalid split values cannot become a valid record allocation', () {
    expect(
      line(
        const ExpenseSplitAllocation(
          method: ExpenseSplitAllocationMethod.amount,
          businessValue: 30,
        ),
      ).hasValidSplitAllocation,
      isFalse,
    );
    expect(
      line(
        const ExpenseSplitAllocation(
          method: ExpenseSplitAllocationMethod.quantity,
          businessValue: 11,
        ),
      ).hasValidSplitAllocation,
      isFalse,
    );
  });

  test('split allocation evidence survives local record serialization', () {
    final original = line(
      const ExpenseSplitAllocation(
        method: ExpenseSplitAllocationMethod.quantity,
        businessValue: 4,
      ),
    );
    final restored = ExpenseReceiptLineRecord.fromMap(original.toMap());

    expect(
      restored.splitAllocation?.method,
      ExpenseSplitAllocationMethod.quantity,
    );
    expect(restored.splitAllocation?.businessValue, 4);
    expect(restored.hasValidSplitAllocation, isTrue);
  });
}
