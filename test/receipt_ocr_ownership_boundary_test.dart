import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('OCR routing remains evidence-only and delegates domain work', () async {
    final root = Directory.current.path;
    final handoff = await File(
      '$root/lib/shared/receipts/receipt_ocr_handoff.dart',
    ).readAsString();
    final entryActions = await File(
      '$root/lib/screens/expenses/entry/expense_receipt_entry_ocr_actions.dart',
    ).readAsString();

    expect(handoff, contains('typedef ReceiptOcrHandoffHandler'));
    expect(handoff, contains('Future<Map<ReceiptOcrHandoffDestination, T>>'));
    expect(handoff, isNot(contains('fuel_parser.dart')));
    expect(handoff, isNot(contains('inventory_parser.dart')));
    expect(handoff, isNot(contains('receipt_stitch')));
    expect(entryActions, contains('fuel: widget.fuelOcrHandoff'));
    expect(entryActions, contains('inventory: widget.inventoryOcrHandoff'));
    expect(entryActions, isNot(contains('saveFuelRecord')));
    expect(entryActions, isNot(contains('saveInventoryRecord')));
  });
}
