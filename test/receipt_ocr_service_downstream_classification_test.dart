import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/receipts/receipt_processing_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_service.dart';

void main() {
  test('ocr parser handoff classifies item families for downstream apps', () {
    const result = ReceiptOcrResult(
      rawText: '''
LOCAL STORE
06/12/2026
PVC COUPLING 2IN 4.99
UNLEADED FUEL 32.10
MOTOR OIL 5W30 8.50
COFFEE 2.25
INK PEN 1.49
SERVICE FEE 3.00
RANDOM CHARGE 6.00
TOTAL 58.33
''',
      parserText: '''
LOCAL STORE
06/12/2026
PVC COUPLING 2IN 4.99
UNLEADED FUEL 32.10
MOTOR OIL 5W30 8.50
COFFEE 2.25
INK PEN 1.49
SERVICE FEE 3.00
RANDOM CHARGE 6.00
TOTAL 58.33
''',
      textByAttachmentId: {'photo-1': 'private receipt text omitted'},
      source: ReceiptProcessingSource.photo,
    );

    final handoff = result.parserHandoff;

    expect(handoff.itemLines, hasLength(7));
    expect(handoff.expenseFamilyCounts['materials'], 1);
    expect(handoff.expenseFamilyCounts['fuel'], 1);
    expect(handoff.expenseFamilyCounts['vehicle_supplies'], 1);
    expect(handoff.expenseFamilyCounts['food_or_grocery'], 1);
    expect(handoff.expenseFamilyCounts['business_supplies'], 1);
    expect(handoff.expenseFamilyCounts['service'], 1);
    expect(handoff.expenseFamilyCounts['general_expense'], 1);
    expect(handoff.parserHintCounts['materials_item_price'], 1);
    expect(handoff.parserHintCounts['fuel_item_price'], 1);
    expect(handoff.parserHintCounts['vehicle_supplies_item_price'], 1);
    expect(handoff.parserHintCounts['food_or_grocery_item_price'], 1);
    expect(handoff.parserHintCounts['business_supplies_item_price'], 1);
    expect(handoff.parserHintCounts['service_item_price'], 1);
    expect(handoff.parserHintCounts['general_expense_item_price'], 1);
    expect(handoff.materialCandidateLineIds, hasLength(1));
    expect(handoff.fuelCandidateLineIds, hasLength(1));
    expect(handoff.vehicleSupplyCandidateLineIds, hasLength(1));
    expect(handoff.parserTaskCounts['material_line_candidate'], 1);
    expect(handoff.parserTaskCounts['fuel_line_candidate'], 1);
    expect(handoff.parserTaskCounts['vehicle_supply_line_candidate'], 1);
    expect(handoff.counts['expenseFamily_materials'], 1);
    expect(handoff.counts['parserHint_fuel_item_price'], 1);
    expect(
      handoff.privacySafeLineSummaryMaps.toString(),
      isNot(contains('UNLEADED')),
    );
    expect(
      handoff.privacySafeLineSummaryMaps.toString(),
      isNot(contains('COUPLING')),
    );
  });

  test('fuel receipt summary labels do not swallow pump item lines', () {
    const result = ReceiptOcrResult(
      rawText: '''
SHELL
PUMP 04
UNLEADED 10.000 GAL 35.00
FUEL SALE 35.00
LOYALTY REWARD 1.00
ENDING BAL 4.00
''',
      parserText: '''
SHELL
PUMP 04
UNLEADED 10.000 GAL 35.00
FUEL SALE 35.00
LOYALTY REWARD 1.00
ENDING BAL 4.00
''',
      textByAttachmentId: {'photo-1': 'private receipt text omitted'},
      source: ReceiptProcessingSource.photo,
    );

    expect(result.itemCandidateLines, contains('UNLEADED 10.000 GAL 35.00'));
    expect(result.totalCandidateLines, contains('FUEL SALE 35.00'));
    expect(result.tenderCandidateLines, contains('ENDING BAL 4.00'));
    expect(result.totalCandidateLines, isNot(contains('ENDING BAL 4.00')));
    expect(result.totalCandidateLines, isNot(contains('LOYALTY REWARD 1.00')));
    expect(result.parserHandoff.fuelCandidateLineIds, hasLength(1));
    expect(result.parserHandoff.primaryTotalLine?.text, 'FUEL SALE 35.00');
    expect(result.diagnostics.receiptTotalsTextEvidenceStatus, 'total_found');
    expect(
      result.diagnostics.receiptBottomTotalsEvidenceLabel,
      'totals_ready_edge_ok',
    );
  });

  test('repeated payment totals do not become extra item lines', () {
    const result = ReceiptOcrResult(
      rawText: '''
SUPPLY STOP
06/30/2026
SHOP TOWELS 2 @ 8.49 16.98
SUBTOTAL 16.98
TAX 1.40
TOTAL 18.38
AMOUNT PAID 18.38
VISA 18.38
CHANGE 0.00
''',
      parserText: '''
SUPPLY STOP
06/30/2026
SHOP TOWELS 2 @ 8.49 16.98
SUBTOTAL 16.98
TAX 1.40
TOTAL 18.38
AMOUNT PAID 18.38
VISA 18.38
CHANGE 0.00
''',
      textByAttachmentId: {'photo-1': 'private receipt text omitted'},
      source: ReceiptProcessingSource.photo,
    );

    final handoff = result.parserHandoff;

    expect(result.itemCandidateLines, ['SHOP TOWELS 2 @ 8.49 16.98']);
    expect(result.totalCandidateLines, contains('TOTAL 18.38'));
    expect(result.totalCandidateLines, contains('AMOUNT PAID 18.38'));
    expect(result.tenderCandidateLines, contains('VISA 18.38'));
    expect(result.tenderCandidateLines, contains('CHANGE 0.00'));
    expect(handoff.itemLines, hasLength(1));
    expect(handoff.parserReadyLineCount, 1);
    expect(handoff.primaryTotalLine?.text, 'TOTAL 18.38');
    expect(handoff.primaryTotalAmount, 18.38);
    expect(handoff.itemAmountSubtotal, 16.98);
    expect(handoff.summaryMathStatus, 'matched');
    expect(handoff.mixedClassificationReadinessStatus, 'ready');
    expect(handoff.lineSequenceStatus, 'expected_order');
    expect(handoff.parserTaskCounts['vehicle_supply_line_candidate'], 1);
    expect(
      handoff.privacySafeParserHandoffContract.toString(),
      isNot(contains('AMOUNT PAID')),
    );
    expect(
      handoff.privacySafeParserHandoffContract.toString(),
      isNot(contains('18.38')),
    );
  });
}
