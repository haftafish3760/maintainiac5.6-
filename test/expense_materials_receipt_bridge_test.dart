import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_materials_receipt_bridge.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_inventory_receipt_store.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'expense_materials_receipt_bridge_test_',
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
    'tracked materials expense receipt creates a materials review receipt',
    () async {
      final bridge = await ExpenseMaterialsReceiptBridge.create();
      final saved = await bridge.syncReceipt(
        ExpenseReceiptRecord(
          id: 'EXP-materials',
          receiptDate: DateTime(2026, 6, 12),
          receiptTimeMinutes: 10 * 60,
          merchantName: 'Lowes',
          phone: '555-0101',
          street: '100 Main St',
          city: 'Charlotte',
          state: 'NC',
          zip: '28202',
          sourceScreen: 'materials_expense_receipt',
          trackMaterialsInInventory: true,
          enteredSubtotal: 100,
          enteredTax: 7,
          attachments: [
            ReceiptAttachmentRecord(
              id: 'proof-1',
              path: '/receipts/lowes.jpg',
              kind: ReceiptAttachmentKind.photo,
              dataSaverLevel: ReceiptDataSaverLevel.balanced,
              createdAt: DateTime(2026, 6, 12, 10),
            ),
          ],
          lines: const [
            ExpenseReceiptLineRecord(
              id: 'LINE-material',
              description: '1/2 in copper 90 elbow',
              category: 'Materials',
              use: ExpenseLineUse.business,
              quantity: 2,
              unitsPerPackage: 10,
              unit: 'each',
              subtotal: 100,
            ),
            ExpenseReceiptLineRecord(
              id: 'LINE-snack',
              description: 'Candy bar',
              category: 'Meals',
              use: ExpenseLineUse.personal,
              quantity: 1,
              unitsPerPackage: 1,
              unit: 'each',
              subtotal: 3,
            ),
          ],
        ),
      );

      expect(saved, isNotNull);
      expect(saved!.id, 'WRS-FROM-EXP-materials');
      expect(saved.merchantName, 'Lowes');
      expect(saved.merchantAddress, '100 Main St, Charlotte, NC, 28202');
      expect(saved.proofs.single.uri, '/receipts/lowes.jpg');
      expect(saved.lines, hasLength(1));
      expect(saved.lines.single.displayName, '1/2 in copper 90 elbow');
      expect(saved.lines.single.totalUnits, 20);
      expect(saved.lines.single.taxRate, .07);
      expect(saved.lines.single.needsReview, isTrue);
      expect(saved.lines.single.item.trade, 'Needs Review');
    },
  );

  test(
    'materials receipt without inventory tracking stays expense-only',
    () async {
      final bridge = await ExpenseMaterialsReceiptBridge.create();
      final result = await bridge.syncReceipt(
        ExpenseReceiptRecord(
          id: 'EXP-expense-only',
          receiptDate: DateTime(2026, 6, 12),
          sourceScreen: 'materials_expense_receipt',
          trackMaterialsInInventory: false,
          lines: const [
            ExpenseReceiptLineRecord(
              id: 'LINE-material',
              description: 'Drywall screws',
              category: 'Materials',
              use: ExpenseLineUse.business,
              quantity: 1,
              unitsPerPackage: 100,
              unit: 'each',
              subtotal: 12,
            ),
          ],
        ),
      );
      final store = await WorkSupplyInventoryReceiptStore.create();

      expect(result, isNull);
      expect(store.loadReceipts(), isEmpty);
    },
  );
}
