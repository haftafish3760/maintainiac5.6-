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

  test('separatorless OCR money rows are inferred only with safe context', () {
    const result = ReceiptOcrResult(
      rawText: '''
SUPPLY STOP
06/30/2026
SHOP TOWELS 1698
UPC 012345678905
SKU 1234
TAX 140
TOTAL 1838
''',
      parserText: '''
SUPPLY STOP
06/30/2026
SHOP TOWELS 1698
UPC 012345678905
SKU 1234
TAX 140
TOTAL 1838
''',
      textByAttachmentId: {'photo-1': 'private receipt text omitted'},
      source: ReceiptProcessingSource.photo,
    );

    final handoff = result.parserHandoff;

    expect(result.itemCandidateLines, ['SHOP TOWELS 1698']);
    expect(result.priceCandidateLines, contains('SHOP TOWELS 1698'));
    expect(result.taxCandidateLines, ['TAX 140']);
    expect(result.totalCandidateLines, ['TOTAL 1838']);
    expect(result.priceCandidateLines, isNot(contains('UPC 012345678905')));
    expect(result.priceCandidateLines, isNot(contains('SKU 1234')));
    expect(handoff.itemLines, hasLength(1));
    expect(handoff.itemLines.single.amountCandidates, [16.98]);
    expect(handoff.itemLines.single.safeExpenseAmount, 16.98);
    expect(handoff.parserReadyLineCount, 1);
    expect(handoff.primaryTaxAmount, 1.40);
    expect(handoff.primaryTotalAmount, 18.38);
    expect(handoff.lineSequenceStatus, 'expected_order');
    expect(handoff.mixedClassificationReadinessStatus, 'ready');
    expect(handoff.separatorlessMoneyInferenceLineIds, [
      'ocr_line_002_item',
      'ocr_line_005_tax',
      'ocr_line_006_total',
    ]);
    expect(handoff.parserTaskCounts['separatorless_money_inferred'], 3);
    expect(
      (handoff.privacySafeParserHandoffContract['parserTaskLineIds']
          as Map)['separatorless_money_inferred'],
      ['ocr_line_002_item', 'ocr_line_005_tax', 'ocr_line_006_total'],
    );
    expect(
      result.diagnostics.parserSignalSummaryLabel,
      contains('3 OCR amounts were inferred from missing cents separator'),
    );
    expect(
      handoff.privacySafeParserHandoffContract.toString(),
      isNot(contains('1838')),
    );
    expect(
      handoff.privacySafeParserHandoffContract.toString(),
      isNot(contains('1234')),
    );
  });

  test('separatorless SKU item totals allow tax-code suffixes safely', () {
    const result = ReceiptOcrResult(
      rawText: '''
ACE HARDWARE
06/30/2026
SKU 123456 PVC GLUE 799T
UPC 012345678905
TOTAL 799
''',
      parserText: '''
ACE HARDWARE
06/30/2026
SKU 123456 PVC GLUE 799T
UPC 012345678905
TOTAL 799
''',
      textByAttachmentId: {'photo-1': 'private receipt text omitted'},
      source: ReceiptProcessingSource.photo,
    );

    final handoff = result.parserHandoff;
    final item = handoff.itemLines.single;

    expect(result.itemCandidateLines, ['SKU 123456 PVC GLUE 799T']);
    expect(result.priceCandidateLines, contains('SKU 123456 PVC GLUE 799T'));
    expect(result.priceCandidateLines, isNot(contains('UPC 012345678905')));
    expect(result.totalCandidateLines, ['TOTAL 799']);
    expect(item.amountCandidates, [7.99]);
    expect(item.safeExpenseAmount, 7.99);
    expect(item.expenseFamily, ReceiptOcrParserExpenseFamily.materials);
    expect(item.hasSeparatorlessMoneyInference, isTrue);
    expect(handoff.parserReadyLineCount, 1);
    expect(handoff.primaryTotalAmount, 7.99);
    expect(handoff.separatorlessMoneyInferenceLineIds, [
      'ocr_line_002_item',
      'ocr_line_004_total',
    ]);
    expect(handoff.parserTaskCounts['separatorless_money_inferred'], 2);
    expect(handoff.mixedClassificationReadinessStatus, 'ready');
    expect(
      handoff.privacySafeParserHandoffContract.toString(),
      isNot(contains('PVC GLUE')),
    );
    expect(
      handoff.privacySafeParserHandoffContract.toString(),
      isNot(contains('799')),
    );
  });

  test('ocr summary word swaps still expose subtotal tax and total', () {
    const result = ReceiptOcrResult(
      rawText: '''
SUPPLY STOP
06/30/2026
SHOP TOWELS 1698
SUBT0TAL 1698
T4X 140
T0TAL 1838
''',
      parserText: '''
SUPPLY STOP
06/30/2026
SHOP TOWELS 1698
SUBT0TAL 1698
T4X 140
T0TAL 1838
''',
      textByAttachmentId: {'photo-1': 'private receipt text omitted'},
      source: ReceiptProcessingSource.photo,
    );

    final handoff = result.parserHandoff;

    expect(result.subtotalCandidateLines, ['SUBT0TAL 1698']);
    expect(result.taxCandidateLines, ['T4X 140']);
    expect(result.totalCandidateLines, ['T0TAL 1838']);
    expect(handoff.primarySubtotalAmount, 16.98);
    expect(handoff.primaryTaxAmount, 1.40);
    expect(handoff.primaryTotalAmount, 18.38);
    expect(handoff.summaryMathStatus, 'matched');
    expect(handoff.mixedClassificationReadinessStatus, 'ready');
    expect(handoff.separatorlessMoneyInferenceLineIds, [
      'ocr_line_002_item',
      'ocr_line_003_subtotal',
      'ocr_line_004_tax',
      'ocr_line_005_total',
    ]);
    expect(handoff.parserTaskCounts['separatorless_money_inferred'], 4);
    expect(
      result.diagnostics.parserSignalSummaryLabel,
      contains('4 OCR amounts were inferred from missing cents separator'),
    );
  });

  test('split OCR cents rows are inferred without accepting UPC numbers', () {
    const result = ReceiptOcrResult(
      rawText: '''
SUPPLY STOP
06/30/2026
SHOP TOWELS 16 98
UPC 012345678905 18 38
SUBTOTAL 16 98
TAX 1 40
TOTAL 18 38
''',
      parserText: '''
SUPPLY STOP
06/30/2026
SHOP TOWELS 16 98
UPC 012345678905 18 38
SUBTOTAL 16 98
TAX 1 40
TOTAL 18 38
''',
      textByAttachmentId: {'photo-1': 'private receipt text omitted'},
      source: ReceiptProcessingSource.photo,
    );

    final handoff = result.parserHandoff;

    expect(result.itemCandidateLines, ['SHOP TOWELS 16 98']);
    expect(result.priceCandidateLines, contains('SHOP TOWELS 16 98'));
    expect(
      result.priceCandidateLines,
      isNot(contains('UPC 012345678905 18 38')),
    );
    expect(result.subtotalCandidateLines, ['SUBTOTAL 16 98']);
    expect(result.taxCandidateLines, ['TAX 1 40']);
    expect(result.totalCandidateLines, ['TOTAL 18 38']);
    expect(handoff.itemLines.single.amountCandidates, [16.98]);
    expect(handoff.itemLines.single.safeExpenseAmount, 16.98);
    expect(handoff.primarySubtotalAmount, 16.98);
    expect(handoff.primaryTaxAmount, 1.40);
    expect(handoff.primaryTotalAmount, 18.38);
    expect(handoff.summaryMathStatus, 'matched');
    expect(handoff.mixedClassificationReadinessStatus, 'ready');
    expect(handoff.separatorlessMoneyInferenceLineIds, isEmpty);
    expect(handoff.splitCentsMoneyInferenceLineIds, [
      'ocr_line_002_item',
      'ocr_line_004_subtotal',
      'ocr_line_005_tax',
      'ocr_line_006_total',
    ]);
    expect(
      handoff.parserTaskCounts.containsKey('separatorless_money_inferred'),
      isFalse,
    );
    expect(handoff.parserTaskCounts['split_cents_money_inferred'], 4);
    expect(
      (handoff.privacySafeParserHandoffContract['parserTaskLineIds']
          as Map)['split_cents_money_inferred'],
      [
        'ocr_line_002_item',
        'ocr_line_004_subtotal',
        'ocr_line_005_tax',
        'ocr_line_006_total',
      ],
    );
    expect(
      result.diagnostics.parserSignalSummaryLabel,
      contains('4 OCR amounts were inferred from spaced cents'),
    );
    expect(
      handoff.privacySafeParserHandoffContract.toString(),
      isNot(contains('18 38')),
    );
  });
}
