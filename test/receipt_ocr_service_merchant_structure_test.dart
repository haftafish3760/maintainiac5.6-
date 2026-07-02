import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/receipts/receipt_processing_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_service.dart';

void main() {
  test('vehicle supply OCR handoff preserves quantity and terminal amount', () {
    const result = ReceiptOcrResult(
      rawText: '''
AUTO PARTS WAREHOUSE
06/30/2026
SHOP TOWELS 2 @ 8.49 16.98
MICROFIBER TOWELS QTY 3 4.50
TOTAL 21.48
''',
      parserText: '''
AUTO PARTS WAREHOUSE
06/30/2026
SHOP TOWELS 2 @ 8.49 16.98
MICROFIBER TOWELS QTY 3 4.50
TOTAL 21.48
''',
      textByAttachmentId: {'photo-1': 'private receipt text omitted'},
      source: ReceiptProcessingSource.photo,
    );

    final handoff = result.parserHandoff;
    final diagnostics = result.diagnostics;

    expect(handoff.expenseFamilyCounts['vehicle_supplies'], 2);
    expect(handoff.parserHintCounts['vehicle_supplies_item_price'], 2);
    expect(handoff.vehicleSupplyCandidateLineIds, hasLength(2));
    expect(handoff.parserTaskCounts['vehicle_supply_line_candidate'], 2);
    expect(handoff.quantitySignalItemLineCount, greaterThanOrEqualTo(2));
    expect(
      diagnostics.quantitySignalItemCandidateLineCount,
      greaterThanOrEqualTo(2),
    );
    expect(
      diagnostics.parserSignalSummaryLabel,
      contains('quantity/unit signals'),
    );
    expect(
      handoff.privacySafeLineSummaryMaps.toString(),
      isNot(contains('SHOP TOWELS')),
    );
    expect(
      handoff.privacySafeLineSummaryMaps.toString(),
      isNot(contains('16.98')),
    );
  });

  test('unknown fuel merchant exposes merchant-independent structure', () {
    const result = ReceiptOcrResult(
      rawText: '''
CORNER MART #42
06/12/2026
PUMP 07
UNLEADED 12.345 GAL 3.19 39.38
FUEL SALE 39.38
CARD 39.38
''',
      parserText: '''
CORNER MART #42
06/12/2026
PUMP 07
UNLEADED 12.345 GAL 3.19 39.38
FUEL SALE 39.38
CARD 39.38
''',
      textByAttachmentId: {'photo-1': 'private receipt text omitted'},
      source: ReceiptProcessingSource.photo,
    );

    final handoff = result.parserHandoff;
    final diagnostics = result.diagnostics;
    final contract = handoff.privacySafeParserHandoffContract;

    expect(handoff.primaryVendorLine?.text, 'CORNER MART #42');
    expect(handoff.fuelCandidateLineCount, greaterThanOrEqualTo(1));
    expect(handoff.primaryTotalLine?.text, 'FUEL SALE 39.38');
    expect(handoff.hasMerchantIndependentReceiptStructure, isTrue);
    expect(
      handoff.merchantIndependentStructureStatus,
      'generic_fuel_receipt_ready',
    );
    expect(
      handoff.merchantIndependentStructureLabel,
      'Merchant-independent fuel receipt structure is ready.',
    );
    expect(
      handoff.parserTaskCounts['generic_fuel_receipt_ready'],
      greaterThan(0),
    );
    expect(handoff.parserTaskCounts['fuel_line_ready'], 1);
    expect(handoff.parserTaskCounts['fuel_quantity_signal'], 1);
    expect(handoff.parserTaskCounts['fuel_unit_price_signal'], 1);
    expect(handoff.parserTaskCounts['fuel_detail_ready'], 1);
    expect(diagnostics.parserTaskCounts['fuel_line_ready'], 1);
    expect(diagnostics.parserTaskCounts['fuel_detail_ready'], 1);
    expect(
      handoff
          .downstreamReadinessCounts['merchantIndependentStructure_generic_fuel_receipt_ready'],
      1,
    );
    expect(handoff.counts['merchantIndependentStructureReadyCount'], 1);
    expect(
      contract['merchantIndependentStructureStatus'],
      'generic_fuel_receipt_ready',
    );
    expect((contract['fuelReadyLineIds'] as List), ['ocr_line_003_item']);
    expect((contract['fuelQuantitySignalLineIds'] as List), [
      'ocr_line_003_item',
    ]);
    expect((contract['fuelUnitPriceSignalLineIds'] as List), [
      'ocr_line_003_item',
    ]);
    expect((contract['fuelDetailReadyLineIds'] as List), ['ocr_line_003_item']);
    expect(
      (contract['merchantIndependentStructureDiagnostics'] as Map)['ready'],
      isTrue,
    );
    expect(
      diagnostics.merchantIndependentStructureStatus,
      'generic_fuel_receipt_ready',
    );
    expect(
      diagnostics
          .receiptTotalsCoverageEvidenceDiagnostics['merchantIndependentStructureStatus'],
      'generic_fuel_receipt_ready',
    );
    expect(
      diagnostics.parserSignalSummaryLabel,
      contains('merchant-independent generic_fuel_receipt_ready'),
    );
    expect(diagnostics.parserSignalSummaryLabel, contains('fuel line ready'));
    expect(diagnostics.parserSignalSummaryLabel, contains('fuel detail set'));
    expect(
      diagnostics.parserSignalSummaryLabel,
      contains('fuel quantity signal'),
    );
    expect(
      diagnostics.parserSignalSummaryLabel,
      contains('fuel unit price signal'),
    );
    expect(handoff.parserTaskCounts['receipt_total_only_ready'], 1);
    expect(
      handoff.parserTaskCounts.containsKey(
        'receipt_total_only_line_math_review',
      ),
      isFalse,
    );
    expect(diagnostics.parserTaskCounts['receipt_total_only_ready'], 1);
    expect(contract.toString(), isNot(contains('CORNER MART')));
    expect(contract.toString(), isNot(contains('39.38')));
  });
}
