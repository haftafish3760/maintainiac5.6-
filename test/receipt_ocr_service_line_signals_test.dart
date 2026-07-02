import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/receipts/receipt_processing_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('receipt address phone rows stay metadata not item prices', () {
    const result = ReceiptOcrResult(
      rawText: '''
LOWE'S HOME CENTERS, LLC
AUSTIN, TX 78745 (512) 895-5560
23536 OATEY 14-OZ PLUMBERS PUTTY       2.99
SUBTOTAL:                              2.99
TAX:                                   0.25
TOTAL:                                 3.24
''',
      parserText: '''
LOWE'S HOME CENTERS, LLC
AUSTIN, TX 78745 (512) 895-5560
23536 OATEY 14-OZ PLUMBERS PUTTY       2.99
SUBTOTAL:                              2.99
TAX:                                   0.25
TOTAL:                                 3.24
''',
      textByAttachmentId: {'photo-1': 'LOWES'},
      source: ReceiptProcessingSource.photo,
    );

    expect(
      result.metadataCandidateLines,
      contains('AUSTIN, TX 78745 (512) 895-5560'),
    );
    expect(
      result.itemCandidateLines,
      isNot(contains('AUSTIN, TX 78745 (512) 895-5560')),
    );
    expect(result.itemCandidateLines, [
      '23536 OATEY 14-OZ PLUMBERS PUTTY       2.99',
    ]);
    expect(result.parserSignalCounts['itemCandidateLineCount'], 1);
    expect(
      result.parserSignalCounts['metadataCandidateLineCount'],
      greaterThanOrEqualTo(1),
    );
  });

  test(
    'generic fuel grocery and hardware receipts keep local parser roles',
    () {
      const fuel = ReceiptOcrResult(
        rawText: '''
QUICK FUEL 27
PUMP 04
UNLEADED 10.250 GAL 35.86
FUEL SALE 35.86
VISA 35.86
AUTH 123456
''',
        parserText: '''
QUICK FUEL 27
PUMP 04
UNLEADED 10.250 GAL 35.86
FUEL SALE 35.86
VISA 35.86
AUTH 123456
''',
        textByAttachmentId: {'photo-1': 'private receipt text omitted'},
        source: ReceiptProcessingSource.photo,
      );

      const grocery = ReceiptOcrResult(
        rawText: '''
CORNER MARKET 52
BANANAS 4011 1.29
SHOP TOWELS 5.00
SUBTOTAL 6.29
TAX 0.41
TOTAL 6.70
EBT FOOD 1.29
VISA 5.41
''',
        parserText: '''
CORNER MARKET 52
BANANAS 4011 1.29
SHOP TOWELS 5.00
SUBTOTAL 6.29
TAX 0.41
TOTAL 6.70
EBT FOOD 1.29
VISA 5.41
''',
        textByAttachmentId: {'photo-1': 'private receipt text omitted'},
        source: ReceiptProcessingSource.photo,
      );

      const hardware = ReceiptOcrResult(
        rawText: '''
NEIGHBOR HARDWARE 104
PVC ELBOW 1/2IN 2.49
ORDER 456789
SUBTOTAL 2.49
TAX 0.21
TOTAL 2.70
CARD APPROVAL 876543
''',
        parserText: '''
NEIGHBOR HARDWARE 104
PVC ELBOW 1/2IN 2.49
ORDER 456789
SUBTOTAL 2.49
TAX 0.21
TOTAL 2.70
CARD APPROVAL 876543
''',
        textByAttachmentId: {'photo-1': 'private receipt text omitted'},
        source: ReceiptProcessingSource.photo,
      );

      expect(fuel.vendorCandidateLines, ['QUICK FUEL 27']);
      expect(fuel.itemCandidateLines, ['UNLEADED 10.250 GAL 35.86']);
      expect(fuel.totalCandidateLines, ['FUEL SALE 35.86']);
      expect(fuel.tenderCandidateLines, contains('VISA 35.86'));
      expect(fuel.tenderCandidateLines, contains('AUTH 123456'));
      expect(
        fuel.parserLineSignals
            .singleWhere((signal) => signal.text == 'AUTH 123456')
            .primaryAmount,
        isNull,
      );
      expect(fuel.parserHandoff.primaryVendorLine?.text, 'QUICK FUEL 27');
      expect(fuel.parserHandoff.itemLines, hasLength(1));
      expect(
        fuel.parserHandoff.itemLines.single.expenseFamily,
        ReceiptOcrParserExpenseFamily.fuel,
      );
      expect(fuel.parserHandoff.itemExpenseFamilyStatus, 'single_fuel_family');
      expect(
        fuel.parserHandoff.itemExpenseFamilySummaryLabel,
        'Receipt family: fuel',
      );
      expect(
        fuel.parserHandoff.parserTaskCounts['expense_family_fuel_item'],
        1,
      );
      expect(
        fuel.parserHandoff.parserTaskCounts['expense_family_single_receipt'],
        1,
      );
      expect(
        fuel
            .parserHandoff
            .privacySafeParserHandoffContract['itemExpenseFamilyStatus'],
        'single_fuel_family',
      );
      expect(fuel.diagnostics.itemExpenseFamilyStatus, 'single_fuel_family');
      expect(
        fuel.diagnostics.parserSignalSummaryLabel,
        contains('Receipt family: fuel'),
      );
      expect(fuel.parserHandoff.primaryTotalAmount, 35.86);

      expect(grocery.vendorCandidateLines, ['CORNER MARKET 52']);
      expect(grocery.itemCandidateLines, [
        'BANANAS 4011 1.29',
        'SHOP TOWELS 5.00',
      ]);
      expect(grocery.subtotalCandidateLines, ['SUBTOTAL 6.29']);
      expect(grocery.taxCandidateLines, ['TAX 0.41']);
      expect(grocery.totalCandidateLines, ['TOTAL 6.70']);
      expect(grocery.tenderCandidateLines, contains('EBT FOOD 1.29'));
      expect(grocery.tenderCandidateLines, contains('VISA 5.41'));
      expect(grocery.parserHandoff.primaryVendorLine?.text, 'CORNER MARKET 52');
      expect(grocery.parserHandoff.itemLines, hasLength(2));
      expect(
        grocery.parserHandoff.itemLines
            .singleWhere((line) => line.text == 'BANANAS 4011 1.29')
            .expenseFamily,
        ReceiptOcrParserExpenseFamily.foodOrGrocery,
      );
      expect(
        grocery.parserHandoff.itemLines
            .singleWhere((line) => line.text == 'SHOP TOWELS 5.00')
            .expenseFamily,
        ReceiptOcrParserExpenseFamily.vehicleSupplies,
      );
      expect(
        grocery.parserHandoff.itemExpenseFamilyStatus,
        'mixed_item_families',
      );
      expect(
        grocery.parserHandoff.itemExpenseFamilySummaryLabel,
        'Mixed receipt families: food/grocery, vehicle supplies',
      );
      expect(
        grocery
            .parserHandoff
            .parserTaskCounts['expense_family_food_or_grocery_item'],
        1,
      );
      expect(
        grocery
            .parserHandoff
            .parserTaskCounts['expense_family_vehicle_supplies_item'],
        1,
      );
      expect(
        grocery.parserHandoff.parserTaskCounts['expense_family_mixed_receipt'],
        2,
      );
      expect(grocery.diagnostics.itemExpenseFamilyCounts['food_or_grocery'], 1);
      expect(
        grocery.diagnostics.parserSignalSummaryLabel,
        contains('Mixed receipt families: food/grocery, vehicle supplies'),
      );
      expect(grocery.parserHandoff.summaryMathStatus, 'matched');

      expect(hardware.vendorCandidateLines, ['NEIGHBOR HARDWARE 104']);
      expect(hardware.itemCandidateLines, ['PVC ELBOW 1/2IN 2.49']);
      expect(hardware.metadataCandidateLines, contains('ORDER 456789'));
      expect(hardware.tenderCandidateLines, contains('CARD APPROVAL 876543'));
      expect(
        hardware.parserLineSignals
            .singleWhere((signal) => signal.text == 'CARD APPROVAL 876543')
            .primaryAmount,
        isNull,
      );
      expect(
        hardware.parserHandoff.primaryVendorLine?.text,
        'NEIGHBOR HARDWARE 104',
      );
      expect(hardware.parserHandoff.itemLines, hasLength(1));
      expect(
        hardware.parserHandoff.itemLines.single.expenseFamily,
        ReceiptOcrParserExpenseFamily.materials,
      );
      expect(
        hardware.parserHandoff.itemExpenseFamilyStatus,
        'single_materials_family',
      );
      expect(
        hardware.parserHandoff.itemExpenseFamilySummaryLabel,
        'Receipt family: materials',
      );
      expect(
        hardware
            .parserHandoff
            .parserTaskCounts['expense_family_materials_item'],
        1,
      );
      expect(
        hardware.diagnostics.parserSignalSummaryLabel,
        contains('Receipt family: materials'),
      );
      expect(hardware.parserHandoff.summaryMathStatus, 'matched');
    },
  );
}
