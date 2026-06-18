import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_item_memory_store.dart';

void main() {
  test('expense receipt memory normalizes repeated line descriptions', () {
    expect(normalizeExpenseMemoryKey('  Pump 03 DIESEL!!  '), 'pump 03 diesel');
    expect(normalizeExpenseMemoryKey('1/2-in Copper 90'), '1 2 in copper 90');
  });

  test('expense receipt memory model restores saved category details', () {
    final memory = ExpenseReceiptItemMemory.fromMap({
      'id': 'sheetz|diesel',
      'merchantName': 'Sheetz',
      'description': 'Diesel Fuel',
      'normalizedDescription': 'diesel fuel',
      'category': 'Fuel',
      'useName': ExpenseLineUse.business.name,
      'unit': 'gal',
      'quantity': 12.5,
      'unitsPerPackage': 1,
      'subtotal': 44.25,
      'unitPrice': 3.54,
      'seenCount': 4,
      'firstSeenAt': '2026-06-01T08:00:00.000',
      'lastSeenAt': '2026-06-13T08:00:00.000',
    });

    expect(memory.merchantName, 'Sheetz');
    expect(memory.category, 'Fuel');
    expect(memory.unit, 'gal');
    expect(memory.unitPrice, 3.54);
    expect(memory.seenCount, 4);
    expect(memory.toMap()['category'], 'Fuel');
  });
}
