import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_service.dart';

import 'helpers/receipt_ocr_parser_ready_fixture.dart';

void main() {
  test('ocr result exposes parser-ready ordered receipt line signals', () {
    final result = parserReadyLowesReceiptResult();

    expect(result.orderedParserLines.first, "LOWE'S HOME CENTERS, LLC");
    expect(
      result.orderedParserLines.indexOf(
        '23536 OATEY 14-OZ PLUMBERS PUTT        2.99',
      ),
      lessThan(
        result.orderedParserLines.indexOf(
          'SUBTOTAL:                              2.99',
        ),
      ),
    );
    expect(result.vendorCandidateLines, contains("LOWE'S HOME CENTERS, LLC"));
    expect(result.dateCandidateLines, contains('07/09/21 13:14:57'));
    expect(
      result.itemCandidateLines,
      contains('23536 OATEY 14-OZ PLUMBERS PUTT        2.99'),
    );
    expect(
      result.priceCandidateLines,
      contains('23536 OATEY 14-OZ PLUMBERS PUTT        2.99'),
    );
    expect(
      result.subtotalCandidateLines,
      contains('SUBTOTAL:                              2.99'),
    );
    expect(
      result.taxCandidateLines,
      contains('TAX:                                   0.25'),
    );
    expect(
      result.totalCandidateLines,
      contains('INVOICE 18934 TOTAL:                   3.24'),
    );
    expect(
      result.tenderCandidateLines,
      contains('MERCH/GIFT CARDS :                     3.24'),
    );
    expect(
      result.tenderCandidateLines,
      contains('MERCH/GIFT CARD 5715 AUTHCODE 370'),
    );
    expect(result.metadataCandidateLines, contains('6400 BRODIE LANE'));
    expect(result.metadataCandidateLines, contains('AUSTIN, TX 78745'));
    expect(result.parserSignalCounts['orderedParserLineCount'], 11);
    expect(
      result.parserSignalCounts['vendorCandidateLineCount'],
      greaterThan(0),
    );
    expect(result.parserSignalCounts['dateCandidateLineCount'], 1);
    expect(result.parserSignalCounts['itemCandidateLineCount'], 1);
    expect(
      result.parserSignalCounts['priceCandidateLineCount'],
      greaterThan(0),
    );
    expect(result.parserSignalCounts['subtotalCandidateLineCount'], 1);
    expect(result.parserSignalCounts['totalCandidateLineCount'], 1);
    expect(result.parserSignalCounts['taxCandidateLineCount'], 1);
    expect(result.parserSignalCounts['tenderCandidateLineCount'], 2);
    expect(result.parserSignalCounts['metadataCandidateLineCount'], 3);
    expect(result.parserSignalCounts['itemRoleLineCount'], 1);
    expect(result.parserSignalCounts['summaryRoleLineCount'], 3);
    expect(result.parserSignalCounts['metadataRoleLineCount'], 3);
    expect(result.diagnostics.vendorCandidateLineCount, greaterThan(0));
    expect(result.diagnostics.dateCandidateLineCount, 1);
    expect(result.diagnostics.itemCandidateLineCount, 1);
    expect(result.diagnostics.priceCandidateLineCount, greaterThan(0));
    expect(result.diagnostics.subtotalCandidateLineCount, 1);
    expect(result.diagnostics.totalCandidateLineCount, 1);
    expect(result.diagnostics.taxCandidateLineCount, 1);
    expect(result.diagnostics.ocrSummaryMathStatus, 'matched');
    expect(result.diagnostics.ocrSummaryMathReconciled, isTrue);
    expect(result.diagnostics.tenderCandidateLineCount, 2);
    expect(result.diagnostics.metadataCandidateLineCount, 3);
    expect(result.diagnostics.parserLineRoleCounts['item'], 1);
    expect(result.diagnostics.parserLineRoleCounts['summary'], 3);
    expect(result.diagnostics.dominantParserLineRole, isNotEmpty);
    final itemSignal = result.parserLineSignals.singleWhere(
      (signal) => signal.text == '23536 OATEY 14-OZ PLUMBERS PUTT        2.99',
    );
    expect(itemSignal.index, 4);
    expect(itemSignal.kind, ReceiptOcrParserLineKind.itemCandidate);
    expect(itemSignal.amountCandidates, [2.99]);
    expect(itemSignal.traits, contains('candidate_expense_item'));
    expect(itemSignal.traits, contains('price_present'));
    expect(itemSignal.traits, contains('safe_terminal_line_amount'));
    expect(itemSignal.traits, isNot(contains('embedded_amount_review')));
    expect(itemSignal.traits, contains('quantity_or_unit'));
    expect(itemSignal.traits, contains('sku_like'));
    expect(itemSignal.traits, contains('expense_family_materials'));
    expect(itemSignal.expenseFamily, ReceiptOcrParserExpenseFamily.materials);
    expect(itemSignal.expenseFamilyToken, 'materials');
    expect(itemSignal.parserHint, 'materials_item_price');
    expect(itemSignal.isMaterialCandidate, isTrue);
    expect(itemSignal.hasQuantityOrUnitSignal, isTrue);
    expect(itemSignal.hasSkuLikeSignal, isTrue);
    expect(itemSignal.hasGenericDescription, isFalse);
    expect(itemSignal.hasSafeTerminalLineAmount, isTrue);
    expect(itemSignal.hasEmbeddedAmountReviewRisk, isFalse);
    expect(itemSignal.primaryAmount, 2.99);
    expect(itemSignal.roleLabel, 'item');
    expect(itemSignal.stableLineId, 'ocr_line_004_item');
    expect(itemSignal.parserBucketId, 'item_ready');
    expect(itemSignal.normalizedText, '23536 oatey 14-oz plumbers putt 2.99');
    expect(itemSignal.confidence, greaterThanOrEqualTo(.84));
    expect(itemSignal.needsReview, isFalse);
    expect(
      itemSignal.reviewReason,
      'Line has receipt item text and one price candidate.',
    );
  });
}
