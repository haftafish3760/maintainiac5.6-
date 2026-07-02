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

  test('loyalty reward promo and survey footer amounts stay out of items', () {
    const result = ReceiptOcrResult(
      rawText: '''
MARKET STOP
06/30/2026
SHOP TOWELS 5.00
LOYALTY REWARD 1.00
PROMO DISCOUNT 0.50
SURVEY BONUS 2.00
TOTAL 5.00
''',
      parserText: '''
MARKET STOP
06/30/2026
SHOP TOWELS 5.00
LOYALTY REWARD 1.00
PROMO DISCOUNT 0.50
SURVEY BONUS 2.00
TOTAL 5.00
''',
      textByAttachmentId: {'photo-1': 'private receipt text omitted'},
      source: ReceiptProcessingSource.photo,
    );

    final handoff = result.parserHandoff;

    expect(result.itemCandidateLines, ['SHOP TOWELS 5.00']);
    expect(result.priceCandidateLines, contains('SHOP TOWELS 5.00'));
    expect(result.itemCandidateLines, isNot(contains('LOYALTY REWARD 1.00')));
    expect(result.itemCandidateLines, isNot(contains('PROMO DISCOUNT 0.50')));
    expect(result.itemCandidateLines, isNot(contains('SURVEY BONUS 2.00')));
    expect(result.totalCandidateLines, ['TOTAL 5.00']);
    expect(
      result.parserLineSignals
          .where(
            (signal) =>
                signal.text == 'LOYALTY REWARD 1.00' ||
                signal.text == 'PROMO DISCOUNT 0.50' ||
                signal.text == 'SURVEY BONUS 2.00',
          )
          .map((signal) => signal.kind)
          .toSet(),
      {ReceiptOcrParserLineKind.other},
    );
    expect(handoff.itemLines, hasLength(1));
    expect(handoff.itemAmountSubtotal, 5.00);
    expect(handoff.primaryTotalAmount, 5.00);
    expect(handoff.totalOnlyLineMathReconciled, isTrue);
    expect(handoff.mixedClassificationReadinessStatus, 'ready');
    expect(
      handoff.privacySafeParserHandoffContract.toString(),
      isNot(contains('LOYALTY')),
    );
    expect(
      handoff.privacySafeParserHandoffContract.toString(),
      isNot(contains('5.00')),
    );
  });

  test('return refund and store credit footer amounts stay out of items', () {
    const result = ReceiptOcrResult(
      rawText: '''
MARKET STOP
06/30/2026
SHOP TOWELS 5.00
RETURN CREDIT 2.00
STORE CREDIT BALANCE 10.00
REFUND TOTAL 2.00
TOTAL 5.00
''',
      parserText: '''
MARKET STOP
06/30/2026
SHOP TOWELS 5.00
RETURN CREDIT 2.00
STORE CREDIT BALANCE 10.00
REFUND TOTAL 2.00
TOTAL 5.00
''',
      textByAttachmentId: {'photo-1': 'private receipt text omitted'},
      source: ReceiptProcessingSource.photo,
    );

    final handoff = result.parserHandoff;

    expect(result.itemCandidateLines, ['SHOP TOWELS 5.00']);
    expect(result.itemCandidateLines, isNot(contains('RETURN CREDIT 2.00')));
    expect(
      result.itemCandidateLines,
      isNot(contains('STORE CREDIT BALANCE 10.00')),
    );
    expect(result.itemCandidateLines, isNot(contains('REFUND TOTAL 2.00')));
    expect(result.totalCandidateLines, ['TOTAL 5.00']);
    expect(result.tenderCandidateLines, contains('RETURN CREDIT 2.00'));
    expect(result.tenderCandidateLines, contains('STORE CREDIT BALANCE 10.00'));
    expect(
      result.parserLineSignals
          .where((signal) => signal.text == 'REFUND TOTAL 2.00')
          .map((signal) => signal.kind),
      [ReceiptOcrParserLineKind.other],
    );
    expect(handoff.itemLines, hasLength(1));
    expect(handoff.itemAmountSubtotal, 5.00);
    expect(handoff.primaryTotalAmount, 5.00);
    expect(handoff.totalOnlyLineMathReconciled, isTrue);
    expect(handoff.mixedClassificationReadinessStatus, 'ready');
    expect(
      handoff.privacySafeParserHandoffContract.toString(),
      isNot(contains('REFUND')),
    );
    expect(
      handoff.privacySafeParserHandoffContract.toString(),
      isNot(contains('5.00')),
    );
  });
}
