import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_service.dart';

import 'helpers/receipt_ocr_parser_ready_fixture.dart';

void main() {
  test('ocr parser diagnostics summarize required fields and task buckets', () {
    final result = parserReadyLowesReceiptResult();
    final handoff = result.parserHandoff;

    expect(handoff.parserBucketCounts['item_ready'], 1);
    expect(handoff.parserBucketCounts['summary_ready'], 3);
    expect(handoff.expenseFamilyCounts['materials'], 1);
    expect(handoff.parserHintCounts['materials_item_price'], 1);
    expect(handoff.fieldReadinessCounts['vendor_needs_review'], 1);
    expect(handoff.fieldReadinessCounts['date_ready'], 1);
    expect(handoff.fieldReadinessCounts['item_price_ready'], 1);
    expect(handoff.fieldReadinessCounts['inventory_material_candidate'], 1);
    expect(handoff.fieldReadinessCounts['material_line_candidate'], 1);
    expect(
      handoff
          .downstreamReadinessCounts['downstreamReadiness_inventory_material_ready'],
      1,
    );
    expect(
      handoff.downstreamReadinessCounts['downstreamReadyItemLineCount'],
      1,
    );
    expect(
      handoff.downstreamReadinessCounts['downstreamInventoryPrepLineCount'],
      1,
    );
    expect(handoff.requiredParserFieldStatusCounts['vendor_needs_review'], 1);
    expect(handoff.requiredParserFieldStatusCounts['date_ready'], 1);
    expect(handoff.requiredParserFieldStatusCounts['subtotal_ready'], 1);
    expect(handoff.requiredParserFieldStatusCounts['tax_ready'], 1);
    expect(handoff.requiredParserFieldStatusCounts['total_ready'], 1);
    expect(handoff.requiredParserFieldStatusCounts['item_price_ready'], 1);
    expect(handoff.requiredParserFieldStatusCounts['required_ready_total'], 5);
    expect(
      handoff.requiredParserFieldStatusCounts['required_needs_review_total'],
      1,
    );
    expect(
      handoff.requiredParserFieldStatusCounts['required_missing_total'],
      isNull,
    );
    expect(
      handoff.requiredParserFieldStatusLabel,
      'required_receipt_fields:ready=5;review=1;missing=0;structure=ready_for_parser;parser=inventory_ready',
    );
    expect(handoff.counts['itemLineCount'], 1);
    expect(handoff.counts['pricedLineCount'], greaterThanOrEqualTo(5));
    expect(handoff.counts['parserReadyLineCount'], 1);
    expect(handoff.counts['downstreamReadiness_inventory_material_ready'], 1);
    expect(handoff.counts['downstreamReadyItemLineCount'], 1);
    expect(handoff.counts['parserReviewSignalCount'], 0);
    expect(handoff.counts['highConfidenceItemLineCount'], 1);
    expect(handoff.counts['reviewItemLineCount'], 0);
    expect(handoff.counts['quantitySignalItemLineCount'], 1);
    expect(handoff.counts['skuSignalItemLineCount'], 1);
    expect(handoff.counts['genericItemLineCount'], 0);
    expect(handoff.counts['inventoryPrepLineCount'], 1);
    expect(handoff.counts['materialCandidateLineCount'], 1);
    expect(handoff.counts['fuelCandidateLineCount'], 0);
    expect(handoff.counts['vehicleSupplyCandidateLineCount'], 0);
    expect(handoff.counts['parserReadyFieldCount'], greaterThanOrEqualTo(5));
    expect(handoff.counts['parserReviewFieldCount'], greaterThanOrEqualTo(1));
    expect(handoff.counts['parserReadyItemLineIdCount'], 1);
    expect(handoff.counts['reviewItemLineIdCount'], 0);
    expect(handoff.counts['inventoryPrepLineIdCount'], 1);
    expect(handoff.counts['materialCandidateLineIdCount'], 1);
    expect(handoff.counts['fuelCandidateLineIdCount'], 0);
    expect(handoff.counts['vehicleSupplyCandidateLineIdCount'], 0);
    expect(
      handoff.counts['vendor_candidateLineIdCount'],
      greaterThanOrEqualTo(1),
    );
    expect(handoff.counts['date_candidateLineIdCount'], 1);
    expect(handoff.counts['subtotal_candidateLineIdCount'], 1);
    expect(handoff.counts['tax_candidateLineIdCount'], 1);
    expect(handoff.counts['total_candidateLineIdCount'], 1);
    expect(handoff.counts['item_price_readyLineIdCount'], 1);
    expect(handoff.counts['inventory_material_candidateLineIdCount'], 1);
    expect(handoff.counts['material_line_candidateLineIdCount'], 1);
    expect(handoff.counts['parser_ready_fieldLineIdCount'], greaterThan(1));
    expect(
      handoff.counts['parser_review_fieldLineIdCount'],
      greaterThanOrEqualTo(1),
    );
    expect(handoff.counts['item_ready'], 1);
    expect(handoff.counts['summary_ready'], 3);
    expect(handoff.counts['expenseFamily_materials'], 1);
    expect(handoff.counts['parserHint_materials_item_price'], 1);
    expect(handoff.counts['total_ready'], 1);
    expect(handoff.counts['required_ready_total'], 5);
    expect(handoff.counts['required_needs_review_total'], 1);
    expect(handoff.counts['vendor_missing'], isNull);
    expect(handoff.counts['item_price_missing'], isNull);
    expect(handoff.counts['itemRoleLineCount'], 1);
    expect(handoff.counts['summaryRoleLineCount'], 3);
    expect(handoff.counts['metadataRoleLineCount'], 3);
    expect(handoff.counts['summaryLineCount'], 3);
    expect(handoff.counts['completeSummaryAmountCount'], 1);
    expect(handoff.counts['summaryMathMatchedCount'], 1);
    expect(handoff.counts['mixedClassificationReadyCount'], 1);
    expect(handoff.counts['mixedClassification_ready'], 1);
    expect(handoff.counts['expectedLineSequenceCount'], 1);
    expect(handoff.counts['lineSequenceReviewCount'], 0);
    expect(handoff.counts['tenderLineCount'], 2);
    expect(handoff.counts['metadataLineCount'], 3);
    expect(
      result.diagnostics.parserSignalSummaryLabel,
      contains('Parser signals'),
    );
    expect(
      result.diagnostics.parserSignalSummaryLabel,
      contains('item candidate'),
    );
    expect(
      result.diagnostics.parserSignalSummaryLabel,
      contains('ready item line'),
    );
    expect(
      result.diagnostics.parserSignalSummaryLabel,
      contains('quantity/unit signals'),
    );
    expect(
      result.diagnostics.parserSignalSummaryLabel,
      contains('required_receipt_fields:ready=5;review=1;missing=0'),
    );
    expect(
      result
          .diagnostics
          .requiredParserFieldStatusCounts['required_ready_total'],
      5,
    );
    expect(
      result
          .diagnostics
          .requiredParserFieldStatusCounts['required_needs_review_total'],
      1,
    );
    expect(
      result.diagnostics.requiredParserFieldStatusLabel,
      handoff.requiredParserFieldStatusLabel,
    );
    expect(
      result.diagnostics.parserSignalSummaryLabel,
      contains('SKU-like signals'),
    );
    expect(
      result.diagnostics.parserSignalSummaryLabel,
      contains('price candidates'),
    );
    expect(
      result.diagnostics.parserSignalSummaryLabel,
      contains('subtotal found'),
    );
    expect(
      result.diagnostics.parserSignalSummaryLabel,
      contains('total found'),
    );
    expect(result.diagnostics.parserSignalSummaryLabel, contains('tax found'));
    expect(
      result.diagnostics.parserTaskCounts['vendor_candidate'],
      greaterThanOrEqualTo(1),
    );
    expect(result.diagnostics.parserTaskCounts['item_price_ready'], 1);
    expect(
      result.diagnostics.parserTaskCounts['inventory_material_candidate'],
      1,
    );
    expect(
      result.diagnostics.parserSignalSummaryLabel,
      contains('parser task buckets ready'),
    );
    expect(
      result.diagnostics.parserSignalSummaryLabel,
      contains('OCR summary math matched'),
    );
    expect(
      result.diagnostics.parserSignalSummaryLabel,
      contains('line order expected_order'),
    );
    expect(
      result.diagnostics.parserSignalSummaryLabel,
      contains('receipt structure ready_for_parser'),
    );
    expect(
      result.diagnostics.parserSignalSummaryLabel,
      contains('tender line'),
    );
    expect(
      result.diagnostics.parserSignalSummaryLabel,
      contains('metadata lines'),
    );
    expect(result.diagnostics.parserSignalSummaryLabel, contains('date found'));
    expect(result.structuredParserHandoffWarnings, isEmpty);
  });
}
