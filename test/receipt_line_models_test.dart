import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/receipts/receipt_line_models.dart';

void main() {
  test('inventory receipt line calculates units, tax, and unit cost', () {
    const line = ReceiptLineDraft(
      kind: ReceiptLineKind.inventory,
      description: 'Fence screws',
      inventoryItemId: 'MI-123',
      inventoryPath: 'Fencing / Fasteners and Accessories / Fasteners',
      quantity: 2,
      unitsPerPackage: 50,
      purchaseType: 'box',
      unit: 'each',
      subtotal: 20,
      taxRate: .05,
      storageArea: 'Work Truck 1 inventory',
      storageDetail: 'Left drawer 2',
      businessUse: 'split',
      businessPercent: .6,
    );

    expect(line.isInventory, isTrue);
    expect(line.totalUnits, 100);
    expect(line.taxAmount, 1);
    expect(line.totalWithTax, 21);
    expect(line.unitCostWithTax, .21);
    expect(line.toMap()['inventoryPath'], contains('Fencing'));
    expect(line.toMap()['storageDetail'], 'Left drawer 2');
    expect(line.toMap()['businessUse'], 'split');
    expect(line.toMap()['businessPercent'], .6);
  });

  test('expense receipt line carries expense category', () {
    const line = ReceiptLineDraft(
      kind: ReceiptLineKind.expense,
      description: 'Delivery fee',
      expenseCategory: 'Postage',
      subtotal: 9.5,
    );

    expect(line.isExpense, isTrue);
    expect(line.inventoryItemId, isEmpty);
    expect(line.toMap()['expenseCategory'], 'Postage');
  });
}
