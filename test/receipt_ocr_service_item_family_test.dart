import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/receipts/receipt_processing_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory documentsDirectory;

  setUp(() async {
    documentsDirectory = await Directory.systemTemp.createTemp(
      'receipt_proof_storage_test_',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => switch (call.method) {
            'getApplicationDocumentsDirectory' => documentsDirectory.path,
            _ => null,
          },
        );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    if (await documentsDirectory.exists()) {
      await documentsDirectory.delete(recursive: true);
    }
  });

  test('ocr parser line signals flag generic priced lines for review', () {
    const result = ReceiptOcrResult(
      rawText: '''
WALMART
06/12/2026
GENERAL MDSE 17.48
TOTAL 17.48
''',
      parserText: '''
WALMART
06/12/2026
GENERAL MDSE 17.48
TOTAL 17.48
''',
      textByAttachmentId: {'photo-1': 'WALMART'},
      source: ReceiptProcessingSource.photo,
    );

    final itemSignal = result.parserHandoff.itemLines.single;

    expect(itemSignal.text, 'GENERAL MDSE 17.48');
    expect(itemSignal.primaryAmount, 17.48);
    expect(itemSignal.confidence, lessThan(.84));
    expect(itemSignal.needsReview, isTrue);
    expect(itemSignal.hasGenericDescription, isTrue);
    expect(itemSignal.hasQuantityOrUnitSignal, isFalse);
    expect(itemSignal.hasSkuLikeSignal, isFalse);
    expect(itemSignal.stableLineId, 'ocr_line_002_item');
    expect(itemSignal.parserBucketId, 'item_needs_review');
    expect(
      itemSignal.reviewReason,
      'Line is generic; review category and description.',
    );
    expect(result.parserHandoff.highConfidenceItemLineCount, 0);
    expect(result.parserHandoff.pricedLineCount, 2);
    expect(result.parserHandoff.parserReadyLineCount, 0);
    expect(result.parserHandoff.parserReviewSignalCount, 1);
    expect(result.parserHandoff.parserReadinessStatus, 'no_parser_ready_items');
    expect(
      result.parserHandoff.mixedClassificationReadinessStatus,
      'needs_safe_item_prices',
    );
    expect(result.parserHandoff.mixedClassificationReady, isFalse);
    expect(
      result.parserHandoff.mixedClassificationEvidenceLabel,
      contains('mixed_classification_needs_safe_prices'),
    );
    expect(result.parserHandoff.downstreamReadinessStatus, 'proof_total_only');
    expect(
      result.parserHandoff.downstreamReadinessLabel,
      'Receipt total is usable, but line items need manual review.',
    );
    expect(
      result
          .parserHandoff
          .downstreamReadinessCounts['downstreamReadiness_proof_total_only'],
      1,
    );
    expect(result.parserHandoff.receiptStructureStatus, 'line_item_review');
    expect(result.parserHandoff.reviewItemLineCount, 1);
    expect(result.parserHandoff.parserReadyItemLineIds, isEmpty);
    expect(result.parserHandoff.reviewItemLineIds, ['ocr_line_002_item']);
    expect(result.parserHandoff.roleByLineId['ocr_line_002_item'], 'item');
    expect(
      result.parserHandoff.parserBucketByLineId['ocr_line_002_item'],
      'item_needs_review',
    );
    expect(
      result.parserHandoff.orderedParserReviewLineIds,
      contains('ocr_line_002_item'),
    );
    expect(result.parserHandoff.parserBucketCounts['item_needs_review'], 1);
    expect(result.parserHandoff.parserMissingFieldCounts, isEmpty);
    expect(result.parserHandoff.parserReviewTaskCounts, {
      'item_price_review_required': 1,
      'item_price_ready_missing': 1,
    });
    expect(
      result.parserHandoff.parserTaskCounts['item_price_review_required'],
      1,
    );
    expect(
      result.parserHandoff.parserTaskCounts['item_price_ready_missing'],
      1,
    );
    expect(
      result.parserHandoff.fieldReadinessCounts['item_price_review_required'],
      1,
    );
    expect(
      result.parserHandoff.fieldReadinessCounts['item_price_ready_missing'],
      1,
    );
    expect(result.parserHandoff.quantitySignalItemLineCount, 0);
    expect(result.parserHandoff.skuSignalItemLineCount, 0);
    expect(result.parserHandoff.genericItemLineCount, 1);
    expect(result.parserHandoff.hasCompleteSummaryAmounts, isFalse);
    expect(result.parserHandoff.summaryMathStatus, 'incomplete');
    expect(result.parserHandoff.lineSequenceStatus, 'expected_order');
    expect(result.diagnostics.highConfidenceItemCandidateLineCount, 0);
    expect(result.diagnostics.reviewItemCandidateLineCount, 1);
    expect(result.diagnostics.quantitySignalItemCandidateLineCount, 0);
    expect(result.diagnostics.skuSignalItemCandidateLineCount, 0);
    expect(result.diagnostics.genericItemCandidateLineCount, 1);
    expect(result.diagnostics.ocrSummaryMathStatus, 'incomplete');
    expect(result.diagnostics.ocrSummaryMathReconciled, isFalse);
    expect(result.diagnostics.ocrLineSequenceStatus, 'expected_order');
    expect(result.diagnostics.ocrReceiptStructureStatus, 'line_item_review');
    expect(result.diagnostics.parserReadinessStatus, 'no_parser_ready_items');
    expect(
      result.diagnostics.mixedClassificationReadinessStatus,
      'needs_safe_item_prices',
    );
    expect(
      result.diagnostics.mixedClassificationEvidenceLabel,
      contains('mixed_classification_needs_safe_prices'),
    );
    expect(
      result.diagnostics.parserSignalSummaryLabel,
      contains('1 item line needs review'),
    );
  });

  test('ocr parser line signals require terminal item amount before ready', () {
    const result = ReceiptOcrResult(
      rawText: '''
HARVEY SUPPLY
06/12/2026
WIDGET 12.99 SKU 12345
SUBTOTAL 12.99
TAX 1.07
TOTAL 14.06
''',
      parserText: '''
HARVEY SUPPLY
06/12/2026
WIDGET 12.99 SKU 12345
SUBTOTAL 12.99
TAX 1.07
TOTAL 14.06
''',
      textByAttachmentId: {'photo-1': 'private receipt text omitted'},
      source: ReceiptProcessingSource.photo,
    );

    final itemSignal = result.parserLineSignals.firstWhere(
      (signal) =>
          signal.kind == ReceiptOcrParserLineKind.itemCandidate &&
          signal.text.contains('WIDGET'),
    );
    expect(itemSignal.amountCandidates, [12.99]);
    expect(itemSignal.primaryAmount, 12.99);
    expect(itemSignal.traits, contains('price_present'));
    expect(itemSignal.traits, contains('embedded_amount_review'));
    expect(itemSignal.traits, isNot(contains('safe_terminal_line_amount')));
    expect(itemSignal.hasSafeTerminalLineAmount, isFalse);
    expect(itemSignal.hasEmbeddedAmountReviewRisk, isTrue);
    expect(itemSignal.confidence, lessThan(.84));
    expect(itemSignal.needsReview, isTrue);
    expect(
      itemSignal.reviewReason,
      'Item-like line has a price that is not at the line total position; review before trusting it.',
    );
    expect(result.parserHandoff.parserReadyLineCount, 0);
    expect(result.parserHandoff.reviewItemLineCount, 1);
    expect(result.parserHandoff.parserReadinessStatus, 'no_parser_ready_items');
    expect(
      result.parserHandoff.mixedClassificationReadinessStatus,
      'needs_safe_item_prices',
    );
    expect(result.parserHandoff.mixedClassificationReady, isFalse);
    expect(result.parserHandoff.parserReadyItemLineIds, isEmpty);
    expect(result.parserHandoff.reviewItemLineIds, ['ocr_line_002_item']);
    expect(
      result.parserHandoff.parserTaskCounts['item_price_review_required'],
      1,
    );
    expect(
      result.diagnostics.mixedClassificationReadinessStatus,
      'needs_safe_item_prices',
    );
    expect(
      result.diagnostics.parserSignalSummaryLabel,
      contains('mixed_classification_needs_safe_prices'),
    );
  });

  test('ocr parser line signals use terminal amount for quantity rows', () {
    const result = ReceiptOcrResult(
      rawText: '''
FUEL STOP
06/12/2026
UNLEADED 10.000 GAL 3.49 35.00
SUBTOTAL 35.00
TAX 0.00
TOTAL 35.00
''',
      parserText: '''
FUEL STOP
06/12/2026
UNLEADED 10.000 GAL 3.49 35.00
SUBTOTAL 35.00
TAX 0.00
TOTAL 35.00
''',
      textByAttachmentId: {'photo-1': 'private receipt text omitted'},
      source: ReceiptProcessingSource.photo,
    );

    final itemSignal = result.parserLineSignals.firstWhere(
      (signal) =>
          signal.kind == ReceiptOcrParserLineKind.itemCandidate &&
          signal.text.contains('UNLEADED'),
    );

    expect(itemSignal.amountCandidates, [3.49, 35.00]);
    expect(itemSignal.terminalLineAmount, 35.00);
    expect(itemSignal.safeExpenseAmount, 35.00);
    expect(itemSignal.primaryAmount, 35.00);
    expect(itemSignal.traits, contains('quantity_or_unit'));
    expect(itemSignal.traits, contains('safe_terminal_line_amount'));
    expect(itemSignal.traits, contains('terminal_line_amount_selected'));
    expect(itemSignal.traits, contains('unit_or_quantity_amounts_present'));
    expect(itemSignal.traits, isNot(contains('multiple_amounts_review')));
    expect(itemSignal.traits, isNot(contains('embedded_amount_review')));
    expect(itemSignal.hasQuantityOrUnitSignal, isTrue);
    expect(itemSignal.hasSafeTerminalLineAmount, isTrue);
    expect(itemSignal.hasUnitPriceOrQuantityAmountSignal, isTrue);
    expect(itemSignal.expenseFamily, ReceiptOcrParserExpenseFamily.fuel);
    expect(itemSignal.needsReview, isFalse);
    expect(
      itemSignal.reviewReason,
      'Line has quantity/unit amounts and a terminal line total.',
    );
    expect(result.parserHandoff.itemAmountSubtotal, 35.00);
    expect(result.parserHandoff.parserReadyLineCount, 1);
    expect(result.parserHandoff.mixedClassificationReadinessStatus, 'ready');
  });
}
