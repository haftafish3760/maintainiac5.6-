import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_item_memory_store.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/shared/receipts/receipt_line_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_assistance_policy.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'expense_receipt_item_memory_store_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

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
      'rawReceiptText': 'DSL FUEL 12.5 GAL',
      'correctedDescription': 'Diesel Fuel',
      'category': 'Fuel',
      'useName': ExpenseLineUse.business.name,
      'unit': 'gal',
      'quantity': 12.5,
      'unitsPerPackage': 1,
      'subtotal': 44.25,
      'unitPrice': 3.54,
      'catalogItemId': 'MI-120',
      'catalogItemName': 'Diesel Exhaust Fluid',
      'catalogItemPath': 'Tools & Safety / Fluids / DEF',
      'catalogMatchConfidence': .91,
      'catalogMatchedTerms': ['diesel', 'fluid'],
      'parserConfidence': .82,
      'parserReviewLabel': 'Review',
      'parserReviewReason': 'User corrected this receipt line.',
      'parserNeedsReview': false,
      'reviewAction': 'edited',
      'seenCount': 4,
      'firstSeenAt': '2026-06-01T08:00:00.000',
      'lastSeenAt': '2026-06-13T08:00:00.000',
    });

    expect(memory.merchantName, 'Sheetz');
    expect(memory.category, 'Fuel');
    expect(memory.unit, 'gal');
    expect(memory.unitPrice, 3.54);
    expect(memory.rawReceiptText, 'DSL FUEL 12.5 GAL');
    expect(memory.correctedDescription, 'Diesel Fuel');
    expect(memory.hasCatalogMatch, isTrue);
    expect(memory.isUserTaughtCatalogMatch, isTrue);
    expect(memory.catalogItemId, 'MI-120');
    expect(memory.catalogItemName, 'Diesel Exhaust Fluid');
    expect(memory.catalogMatchedTerms, ['diesel', 'fluid']);
    expect(memory.seenCount, 4);
    expect(memory.toMap()['catalogItemPath'], contains('Tools & Safety'));
    expect(memory.toMap()['reviewAction'], 'edited');
    expect(memory.toMap()['category'], 'Fuel');
  });

  test(
    'expense receipt memory builds merchant catalog corrections',
    () async {
      final store = await ExpenseReceiptItemMemoryStore.create();
      final correctedItem = searchWorkSupplies('1/2 in copper tee').first;

      await store.rememberReceipt(
        ExpenseReceiptRecord(
          id: 'receipt-1',
          merchantName: "Lowe's",
          receiptDate: DateTime(2026, 6, 12),
          lines: [
            ExpenseReceiptLineRecord(
              id: 'line-1',
              description: 'COPPER THING HALF',
              category: 'Materials',
              use: ExpenseLineUse.business,
              quantity: 1,
              unitsPerPackage: 1,
              unit: 'each',
              subtotal: 7.49,
              catalogItemId: correctedItem.id,
              catalogItemName: correctedItem.name,
              catalogItemPath: correctedItem.path,
              catalogMatchConfidence: .98,
              catalogMatchedTerms: const ['learned'],
            ),
          ],
        ),
      );

      final parsed = parseExpenseReceiptText('''
LOWE'S HOME IMPROVEMENT
06/12/2026
COPPER THING HALF 7.49
TOTAL 7.49
''', materialCatalogMemory: store.catalogLearningMemoryForMerchant("Lowe's"));

      expect(parsed.lines.single.catalogItemId, correctedItem.id);
      expect(parsed.lines.single.catalogItemName, correctedItem.name);
      expect(parsed.lineReviews.single.catalogMatchedTerms, ['learned']);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'materials receipt review lines teach merchant catalog memory',
    () async {
      final store = await ExpenseReceiptItemMemoryStore.create();
      final correctedItem = searchWorkSupplies('1/2 in copper 90').first;

      await store.rememberMaterialsReceiptLines(
        merchantName: 'Home Depot',
        lines: [
          ReceiptLineDraft(
            kind: ReceiptLineKind.inventory,
            description: correctedItem.name,
            inventoryItemId: correctedItem.id,
            inventoryPath: correctedItem.path,
            expenseCategory: 'Materials',
            rawReceiptText: 'HALF COP ELL 90',
            quantity: 3,
            unit: correctedItem.unit,
            subtotal: 12.99,
            catalogMatchConfidence: .97,
            catalogMatchedTerms: const ['half', 'cop', '90'],
            parserConfidence: .76,
            parserReviewLabel: 'Review',
            parserReviewReason: 'User confirmed inventory catalog match.',
            parserNeedsReview: true,
            reviewAction: 'confirmed',
          ),
        ],
      );

      final memory = store.match(
        merchantName: 'Home Depot',
        description: 'HALF COP ELL 90',
      );
      expect(memory, isNotNull);
      expect(memory!.catalogItemId, correctedItem.id);
      expect(memory.catalogItemName, correctedItem.name);
      expect(memory.catalogMatchedTerms, ['half', 'cop', '90']);

      final parsed = parseExpenseReceiptText(
        '''
HOME DEPOT
06/23/2026
HALF COP ELL 90 12.99
TOTAL 12.99
''',
        materialCatalogMemory: store.catalogLearningMemoryForMerchant(
          'Home Depot',
        ),
      );

      expect(parsed.lines.single.catalogItemId, correctedItem.id);
      expect(parsed.lineReviews.single.catalogMatchedTerms, ['learned']);
    },
  );

  test(
    'local memory parser skips catalog learning outside inventory matching depth',
    () async {
      final store = await ExpenseReceiptItemMemoryStore.create();
      final correctedItem = searchWorkSupplies('1/2 in copper 90').first;

      await store.rememberMaterialsReceiptLines(
        merchantName: 'Home Depot',
        lines: [
          ReceiptLineDraft(
            kind: ReceiptLineKind.inventory,
            description: correctedItem.name,
            inventoryItemId: correctedItem.id,
            inventoryPath: correctedItem.path,
            expenseCategory: 'Materials',
            rawReceiptText: 'HALF COP ELL 90',
            quantity: 1,
            unit: correctedItem.unit,
            subtotal: 9.99,
            catalogMatchConfidence: .97,
            catalogMatchedTerms: const ['half', 'cop', '90'],
            reviewAction: 'confirmed',
          ),
        ],
      );

      const text = '''
HOME DEPOT
06/23/2026
HALF COP ELL 90 9.99
TOTAL 9.99
''';
      final medium = await parseExpenseReceiptTextWithLocalMemory(
        text,
        parserDepth: ReceiptParserDepth.lineItems,
      );
      final heavy = await parseExpenseReceiptTextWithLocalMemory(
        text,
        parserDepth: ReceiptParserDepth.inventoryMatching,
      );

      expect(medium.lines.single.catalogItemId, isNull);
      expect(
        medium.lineReviews.single.reason,
        contains('catalog matching was skipped'),
      );
      expect(heavy.lines.single.catalogItemId, correctedItem.id);
      expect(heavy.lineReviews.single.catalogMatchedTerms, ['learned']);
    },
  );

  test(
    'unconfirmed parsed material guesses do not teach catalog memory',
    () async {
      final store = await ExpenseReceiptItemMemoryStore.create();
      final correctedItem = searchWorkSupplies('1/2 in copper tee').first;

      await store.rememberMaterialsReceiptLines(
        merchantName: 'Home Depot',
        lines: [
          ReceiptLineDraft(
            kind: ReceiptLineKind.inventory,
            description: correctedItem.name,
            inventoryItemId: correctedItem.id,
            inventoryPath: correctedItem.path,
            expenseCategory: 'Materials',
            rawReceiptText: 'COPPER THING HALF',
            quantity: 1,
            unit: correctedItem.unit,
            subtotal: 7.49,
            catalogMatchConfidence: .98,
            catalogMatchedTerms: const ['parsed'],
            parserConfidence: .91,
            parserReviewLabel: 'Good',
            parserReviewReason: 'Parser guessed this line.',
            parserNeedsReview: false,
            reviewAction: 'parsed',
          ),
        ],
      );

      final parsed = parseExpenseReceiptText(
        '''
HOME DEPOT
06/23/2026
COPPER THING HALF 7.49
TOTAL 7.49
''',
        materialCatalogMemory: store.catalogLearningMemoryForMerchant(
          'Home Depot',
        ),
      );

      expect(parsed.lines.single.catalogItemId, isNot(correctedItem.id));
    },
  );

  test('local merchant memory helper applies confirmed corrections', () async {
    final store = await ExpenseReceiptItemMemoryStore.create();
    final correctedItem = searchWorkSupplies('1/2 in copper tee').first;

    await store.rememberMaterialsReceiptLines(
      merchantName: 'Home Depot',
      lines: [
        ReceiptLineDraft(
          kind: ReceiptLineKind.inventory,
          description: correctedItem.name,
          inventoryItemId: correctedItem.id,
          inventoryPath: correctedItem.path,
          expenseCategory: 'Materials',
          rawReceiptText: 'COPPER THING HALF',
          quantity: 1,
          unit: correctedItem.unit,
          subtotal: 7.49,
          catalogMatchConfidence: .98,
          catalogMatchedTerms: const ['corrected'],
          parserConfidence: .7,
          parserReviewLabel: 'Review',
          parserReviewReason: 'User corrected this line.',
          parserNeedsReview: false,
          reviewAction: 'edited',
        ),
      ],
    );

    final parsed = await parseExpenseReceiptTextWithLocalMemory('''
HOME DEPOT
06/23/2026
COPPER THING HALF 7.49
TOTAL 7.49
''');

    expect(parsed.lines.single.catalogItemId, correctedItem.id);
    expect(parsed.lineReviews.single.catalogMatchedTerms, ['learned']);
  });
}
