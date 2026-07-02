import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_assistance_policy.dart';

void main() {
  test(
    'parser privacy event reports counts without merchant items or prices',
    () {
      final parsed = parseExpenseReceiptText('''
LOWE'S HOME IMPROVEMENT
06/12/2026
25PK #8 X 1-1/4 WOOD SCREWS 6.98
COPPER ELBOW 7.48
Subtotal 14.46
Tax 1.01
Total 15.47
''', parserDepth: ReceiptParserDepth.lineItems);

      final event = PrivacySafeReceiptEvent.fromParseResult(
        result: parsed,
        featureArea: 'expenses',
      );
      final map = event.toMap();
      final encoded = map.toString().toLowerCase();

      expect(
        map['event'],
        PrivacySafeReceiptEventType.inventoryCatalogMatchWeak.name,
      );
      expect(map['featureArea'], 'expenses');
      expect(map['parserDepth'], ReceiptParserDepth.lineItems.name);
      expect(map['parseQuality'], isIn(['high', 'medium', 'low']));
      expect(map['parserTrust'], isA<String>());
      expect(map['totalsMathStatus'], 'matched');
      expect(map['explicitTotalsComplete'], isTrue);
      expect(map['taxMathReconciled'], isTrue);
      expect(map['needsHeavyReview'], isTrue);
      expect(
        map['localReceiptParserRoutingCode'],
        'optional_detail_pack_available',
      );
      expect(map['localReceiptParserRoutingCounts'], {
        'optional_detail_pack_available': 1,
      });
      expect(map['localReceiptParserKeptLocalCount'], 0);
      expect(map['localReceiptParserOptionalPackOfferCount'], 1);
      final parserRoleCounts = map['parserLineRoleCounts'] as Map<String, int>;
      expect(parserRoleCounts, containsPair('vendor', 1));
      expect(parserRoleCounts, containsPair('date', 1));
      expect(parserRoleCounts, containsPair('subtotal', 1));
      expect(parserRoleCounts, containsPair('tax', 1));
      expect(parserRoleCounts, containsPair('total', 1));
      expect(parserRoleCounts['item'], greaterThanOrEqualTo(2));
      expect(parserRoleCounts['item_price'], greaterThanOrEqualTo(2));
      final parserTaskCounts = map['parserTaskCounts'] as Map<String, int>;
      expect(parserTaskCounts, containsPair('vendor_detected', 1));
      expect(parserTaskCounts, containsPair('date_detected', 1));
      expect(parserTaskCounts, containsPair('subtotal_detected', 1));
      expect(parserTaskCounts, containsPair('tax_detected', 1));
      expect(parserTaskCounts, containsPair('total_detected', 1));
      expect(parserTaskCounts['item_price_ready'], greaterThanOrEqualTo(1));
      final parserCategoryCounts =
          map['parserCategoryCounts'] as Map<String, int>;
      expect(parserCategoryCounts, containsPair('materials', 2));
      final parserCategoryHealthCounts =
          map['parserCategoryHealthCounts'] as Map<String, int>;
      expect(
        parserCategoryHealthCounts,
        containsPair('category_materials_ready', 2),
      );
      expect(
        parserCategoryHealthCounts,
        containsPair('category_family_materials_ready', 2),
      );
      expect(
        parserCategoryHealthCounts,
        containsPair('category_materials_catalog_missing', 2),
      );
      expect(
        map['parserCategoryReviewActionCode'],
        'optional_parser_pack_available',
      );
      final parserRequiredCounts =
          map['parserRequiredFieldStatusCounts'] as Map<String, int>;
      expect(parserRequiredCounts, containsPair('vendor_ready', 1));
      expect(parserRequiredCounts, containsPair('date_ready', 1));
      expect(parserRequiredCounts, containsPair('time_missing', 1));
      expect(parserRequiredCounts, containsPair('item_price_ready', 2));
      expect(parserRequiredCounts, containsPair('category_ready', 2));
      expect(
        parserRequiredCounts,
        containsPair('parser_required_missing_total', 1),
      );
      expect(
        map['parserRequiredFieldStatusLabel'],
        'parser_required_receipt_fields:ready=9;review=0;missing=1',
      );
      expect(
        map['parserDownstreamReadinessStatus'],
        'inventory_material_ready',
      );
      final parserDownstreamCounts =
          map['parserDownstreamReadinessCounts'] as Map<String, int>;
      expect(
        parserDownstreamCounts,
        containsPair('parser_downstream_inventory_material_ready', 1),
      );
      expect(parserDownstreamCounts, containsPair('vendor_ready', 1));
      expect(
        parserDownstreamCounts,
        containsPair('inventory_material_ready', 2),
      );
      expect(parserDownstreamCounts, containsPair('priced_line_ready', 2));
      expect(map['detectedLineCount'], greaterThanOrEqualTo(2));
      expect(map['parserLineCount'], 0);
      expect(map['ocrItemCandidateLineCount'], 0);
      expect(map['ocrPricedLineCount'], 0);
      expect(map['ocrParserReadyLineCount'], 0);
      expect(map['ocrParserReviewSignalCount'], 0);
      expect(map['ocrParserReadinessStatus'], 'unknown');
      expect(map['ocrDownstreamReadinessStatus'], 'unknown');
      expect(map.containsKey('ocrDownstreamReadinessCounts'), isFalse);
      expect(map['ocrStableLineIdCount'], 0);
      expect(map['ocrParserReadyItemLineIdCount'], 0);
      expect(map['ocrReviewItemLineIdCount'], 0);
      expect(map['ocrInventoryPrepLineIdCount'], 0);
      expect(map['ocrParserReadyFieldCount'], 0);
      expect(map['ocrParserReviewFieldCount'], 0);
      expect(map.containsKey('ocrParserBucketCounts'), isFalse);
      expect(map.containsKey('ocrParserTaskCounts'), isFalse);
      expect(map.containsKey('ocrFieldReadinessCounts'), isFalse);
      expect(map.containsKey('ocrRequiredFieldStatusCounts'), isFalse);
      expect(map.containsKey('ocrRequiredFieldStatusLabel'), isFalse);
      expect(map['ocrHighConfidenceItemLineCount'], 0);
      expect(map['ocrReviewItemLineCount'], 0);
      expect(map['ocrQuantitySignalItemLineCount'], 0);
      expect(map['ocrSkuSignalItemLineCount'], 0);
      expect(map['ocrGenericItemLineCount'], 0);
      expect(map['ocrSummaryMathStatus'], 'incomplete');
      expect(map['ocrSummaryMathReconciled'], isFalse);
      expect(map['ocrLineSequenceStatus'], 'unknown');
      expect(map['ocrReceiptStructureStatus'], 'unknown');
      expect(map['ocrTotalCandidateLineCount'], 0);
      expect(map['ocrTenderCandidateLineCount'], 0);
      expect(map['ocrMetadataCandidateLineCount'], 0);
      expect(map['materialLineCount'], greaterThanOrEqualTo(1));
      expect(map['unmatchedMaterialLineCount'], greaterThanOrEqualTo(1));
      expect(encoded, isNot(contains('lowe')));
      expect(encoded, isNot(contains('wood')));
      expect(encoded, isNot(contains('screws')));
      expect(encoded, isNot(contains('copper')));
      expect(encoded, isNot(contains('15.47')));
      expect(encoded, isNot(contains('ocr_line_')));
    },
  );

  test('parser privacy event reports total mismatch without amounts', () {
    final parsed = parseExpenseReceiptText('''
PRIVATE STORE
06/12/2026
SERVICE ITEM 10.00
Total 99.99
''');

    final event = PrivacySafeReceiptEvent.fromParseResult(result: parsed);
    final encoded = event.toMap().toString().toLowerCase();

    expect(event.type, PrivacySafeReceiptEventType.receiptTotalsMismatch);
    expect(encoded, isNot(contains('private store')));
    expect(encoded, isNot(contains('service item')));
    expect(encoded, isNot(contains('99.99')));
    expect(encoded, isNot(contains('10.00')));
  });

  test('parser privacy event reports tax math review without amounts', () {
    final parsed = parseExpenseReceiptText('''
PRIVATE STORE
06/12/2026
SERVICE ITEM 10.00
Subtotal 10.00
Tax 0.80
Total 12.80
''');

    final event = PrivacySafeReceiptEvent.fromParseResult(result: parsed);
    final map = event.toMap();
    final encoded = map.toString().toLowerCase();

    expect(event.type, PrivacySafeReceiptEventType.receiptTotalsMismatch);
    expect(map['explicitTotalsComplete'], isTrue);
    expect(map['taxMathReconciled'], isFalse);
    expect(map['needsHeavyReview'], isTrue);
    expect(map['parserTrust'], 'needs_receipt_math_review');
    expect(map['totalsMathStatus'], 'mismatch');
    expect(encoded, isNot(contains('private store')));
    expect(encoded, isNot(contains('service item')));
    expect(encoded, isNot(contains('12.80')));
    expect(encoded, isNot(contains('10.00')));
    expect(encoded, isNot(contains('0.80')));
  });

  test(
    'parser privacy event reports duplicate overlap review without receipt text',
    () {
      final parsed = parseExpenseReceiptText('''
LOWE'S HOME IMPROVEMENT
06/20/2026
PVC GLUE 7.99
PVC GLUE 7.99
PAINTERS TAPE 5.99
Subtotal 21.97
Tax 1.54
Total 23.51
''');

      final event = PrivacySafeReceiptEvent.fromParseResult(result: parsed);
      final map = event.toMap();
      final encoded = map.toString().toLowerCase();

      expect(map['parserReviewCause'], 'receipt_possible_duplicate_overlap');
      expect(encoded, isNot(contains('lowe')));
      expect(encoded, isNot(contains('pvc glue')));
      expect(encoded, isNot(contains('painters tape')));
      expect(encoded, isNot(contains('7.99')));
      expect(encoded, isNot(contains('23.51')));
    },
  );
}
