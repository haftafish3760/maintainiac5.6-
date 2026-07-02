import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/receipts/receipt_processing_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'hybrid travel mart OCR handoff keeps families and tenders separated',
    () {
      const result = ReceiptOcrResult(
        rawText: '''
COUNTY LINE TRAVEL MART
07/01/2026 06:42 AM
PUMP 07
DIESEL
QTY 18.250 GAL
PRICE/G 3.899
FUEL AMT 71.16
COFFEE 2.19
BOTTLED WATER 1.49
PVC ADAPTER 3/4IN 4.29
MERCH TOTAL 79.13
LOCAL TAX 0.48
TOTAL DUE 79.61
VISA 79.61
AUTH 998877
REF 123456
''',
        parserText: '''
COUNTY LINE TRAVEL MART
07/01/2026 06:42 AM
PUMP 07
DIESEL
QTY 18.250 GAL
PRICE/G 3.899
FUEL AMT 71.16
COFFEE 2.19
BOTTLED WATER 1.49
PVC ADAPTER 3/4IN 4.29
MERCH TOTAL 79.13
LOCAL TAX 0.48
TOTAL DUE 79.61
VISA 79.61
AUTH 998877
REF 123456
''',
        textByAttachmentId: {'photo-1': 'private receipt text omitted'},
        source: ReceiptProcessingSource.photo,
      );

      expect(result.vendorCandidateLines, ['COUNTY LINE TRAVEL MART']);
      expect(result.itemCandidateLines, contains('FUEL AMT 71.16'));
      expect(result.itemCandidateLines, contains('COFFEE 2.19'));
      expect(result.itemCandidateLines, contains('BOTTLED WATER 1.49'));
      expect(result.itemCandidateLines, contains('PVC ADAPTER 3/4IN 4.29'));
      expect(result.subtotalCandidateLines, ['MERCH TOTAL 79.13']);
      expect(result.taxCandidateLines, ['LOCAL TAX 0.48']);
      expect(result.totalCandidateLines, ['TOTAL DUE 79.61']);
      expect(result.tenderCandidateLines, contains('VISA 79.61'));
      expect(result.tenderCandidateLines, contains('AUTH 998877'));
      expect(result.tenderCandidateLines, contains('REF 123456'));
      expect(
        result.parserLineSignals
            .singleWhere((signal) => signal.text == 'AUTH 998877')
            .primaryAmount,
        isNull,
      );
      expect(
        result.parserLineSignals
            .singleWhere((signal) => signal.text == 'REF 123456')
            .primaryAmount,
        isNull,
      );
      final itemTexts = result.parserHandoff.itemLines
          .map((line) => line.text)
          .toList();
      expect(itemTexts, isNot(contains('VISA 79.61')));
      expect(itemTexts, isNot(contains('AUTH 998877')));
      expect(itemTexts, isNot(contains('REF 123456')));
      expect(result.parserHandoff.itemLines.length, greaterThanOrEqualTo(4));
      expect(
        result.parserHandoff.itemLines
            .singleWhere((line) => line.text == 'FUEL AMT 71.16')
            .expenseFamily,
        ReceiptOcrParserExpenseFamily.fuel,
      );
      expect(
        result.parserHandoff.itemLines
            .singleWhere((line) => line.text == 'BOTTLED WATER 1.49')
            .expenseFamily,
        ReceiptOcrParserExpenseFamily.foodOrGrocery,
      );
      expect(
        result.parserHandoff.itemLines
            .singleWhere((line) => line.text == 'PVC ADAPTER 3/4IN 4.29')
            .expenseFamily,
        ReceiptOcrParserExpenseFamily.materials,
      );
      expect(
        result.parserHandoff.itemExpenseFamilyStatus,
        'mixed_item_families',
      );
      expect(
        result.parserHandoff.parserTaskCounts['expense_family_fuel_item'],
        greaterThanOrEqualTo(1),
      );
      expect(
        result
            .parserHandoff
            .parserTaskCounts['expense_family_food_or_grocery_item'],
        2,
      );
      expect(
        result.parserHandoff.parserTaskCounts['expense_family_materials_item'],
        1,
      );
      expect(
        result.parserHandoff.parserTaskCounts['expense_family_mixed_receipt'],
        result.parserHandoff.itemLines.length,
      );
      expect(result.parserHandoff.summaryMathStatus, 'matched');
    },
  );
}
