import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('expense entry exposes explicit downstream OCR handoff hooks', () {
    final root = Directory.current.path;
    final screen = File(
      '$root/lib/screens/expenses/entry/expense_receipt_entry_screen.dart',
    ).readAsStringSync();
    final actions = File(
      '$root/lib/screens/expenses/entry/expense_receipt_entry_ocr_actions.dart',
    ).readAsStringSync();

    expect(screen, contains('this.fuelOcrHandoff'));
    expect(screen, contains('this.inventoryOcrHandoff'));
    expect(actions, contains('fuel: widget.fuelOcrHandoff'));
    expect(actions, contains('inventory: widget.inventoryOcrHandoff'));
  });
}
