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

  test(
    'damaged logo-style merchant headers are recovered as vendor candidates',
    () {
      const result = ReceiptOcrResult(
        rawText: '''
L 0 W E S
06/30/2026
SHOP TOWELS 5.00
TOTAL 5.00
''',
        parserText: '''
L 0 W E S
06/30/2026
SHOP TOWELS 5.00
TOTAL 5.00
''',
        textByAttachmentId: {'photo-1': 'private receipt text omitted'},
        source: ReceiptProcessingSource.photo,
      );

      final handoff = result.parserHandoff;
      final contract = handoff.privacySafeParserHandoffContract;

      expect(result.vendorCandidateLines, ['L 0 W E S']);
      expect(handoff.primaryVendorLine?.stableLineId, 'ocr_line_000_vendor');
      expect(handoff.knownMerchantHeaderCandidateLineIds, [
        'ocr_line_000_vendor',
      ]);
      expect(
        handoff
            .vendorReviewDiagnostics['knownMerchantHeaderCandidateLineCount'],
        1,
      );
      expect(handoff.counts['knownMerchantHeaderCandidateLineCount'], 1);
      expect(handoff.headerRecoveryStatus, 'vendor_ready');
      expect(handoff.vendorReviewStatus, 'vendor_candidate_needs_review');
      expect(handoff.itemLines, hasLength(1));
      expect(handoff.primaryTotalAmount, 5.00);
      expect(handoff.totalOnlyLineMathReconciled, isTrue);
      expect(contract['knownMerchantHeaderCandidateLineIds'], [
        'ocr_line_000_vendor',
      ]);
      expect(
        (contract['parserTaskCounts']
            as Map)['known_merchant_header_candidate'],
        1,
      );
      expect(contract.toString(), isNot(contains('L 0 W E S')));
      expect(contract.toString(), isNot(contains('5.00')));
    },
  );

  test('unknown local merchant headers are ranked without metadata rows', () {
    const result = ReceiptOcrResult(
      rawText: '''
RIVER ROAD MART 418
CASHIER JANE
TRANS 123456
06/30/2026
SHOP TOWELS 5.00
TOTAL 5.00
''',
      parserText: '''
RIVER ROAD MART 418
CASHIER JANE
TRANS 123456
06/30/2026
SHOP TOWELS 5.00
TOTAL 5.00
''',
      textByAttachmentId: {'photo-1': 'private receipt text omitted'},
      source: ReceiptProcessingSource.photo,
    );

    final handoff = result.parserHandoff;
    final contract = handoff.privacySafeParserHandoffContract;

    expect(result.vendorCandidateLines, ['RIVER ROAD MART 418']);
    expect(result.metadataCandidateLines, contains('CASHIER JANE'));
    expect(result.metadataCandidateLines, contains('TRANS 123456'));
    expect(handoff.unknownMerchantHeaderCandidateLineIds, [
      'ocr_line_000_vendor',
    ]);
    expect(handoff.knownMerchantHeaderCandidateLineIds, isEmpty);
    expect(
      handoff
          .vendorReviewDiagnostics['unknownMerchantHeaderCandidateLineCount'],
      1,
    );
    expect(handoff.counts['unknownMerchantHeaderCandidateLineCount'], 1);
    expect(contract['unknownMerchantHeaderCandidateLineIds'], [
      'ocr_line_000_vendor',
    ]);
    expect(
      (contract['parserTaskCounts']
          as Map)['unknown_merchant_header_candidate'],
      1,
    );
    expect(handoff.primaryVendorLine?.stableLineId, 'ocr_line_000_vendor');
    expect(handoff.primaryDateLine?.stableLineId, 'ocr_line_003_date');
    expect(handoff.itemLines, hasLength(1));
    expect(handoff.primaryTotalAmount, 5.00);
    expect(handoff.totalOnlyLineMathReconciled, isTrue);
    expect(contract.toString(), isNot(contains('RIVER ROAD MART')));
    expect(contract.toString(), isNot(contains('CASHIER')));
    expect(contract.toString(), isNot(contains('5.00')));
  });

  test(
    'ocr damaged receipt dates are recovered without numeric id false positives',
    () {
      const result = ReceiptOcrResult(
        rawText: '''
RIVER ROAD MART 418
O7.O9.2I 13:14
TRANS 123456
SHOP TOWELS 5.00
AUTH 87654321
TOTAL 5.00
''',
        parserText: '''
RIVER ROAD MART 418
O7.O9.2I 13:14
TRANS 123456
SHOP TOWELS 5.00
AUTH 87654321
TOTAL 5.00
''',
        textByAttachmentId: {'photo-1': 'private receipt text omitted'},
        source: ReceiptProcessingSource.photo,
      );

      final handoff = result.parserHandoff;
      final contract = handoff.privacySafeParserHandoffContract;

      expect(result.dateCandidateLines, ['O7.O9.2I 13:14']);
      expect(result.metadataCandidateLines, contains('TRANS 123456'));
      expect(result.tenderCandidateLines, contains('AUTH 87654321'));
      expect(result.dateCandidateLines, isNot(contains('TRANS 123456')));
      expect(result.dateCandidateLines, isNot(contains('AUTH 87654321')));
      final authSignal = result.parserLineSignals.singleWhere(
        (signal) => signal.text == 'AUTH 87654321',
      );
      expect(authSignal.kind, ReceiptOcrParserLineKind.tenderCandidate);
      expect(authSignal.primaryAmount, isNull);
      expect(handoff.primaryDateLine?.stableLineId, 'ocr_line_001_date');
      expect(handoff.primaryDateLine?.traits, contains('date_present'));
      expect(handoff.primaryVendorLine?.stableLineId, 'ocr_line_000_vendor');
      expect(handoff.itemLines, hasLength(1));
      expect(handoff.primaryTotalAmount, 5.00);
      expect(handoff.totalOnlyLineMathReconciled, isTrue);
      expect((contract['parserTaskCounts'] as Map)['date_candidate'], 1);
      expect(contract.toString(), isNot(contains('O7.O9.2I')));
      expect(contract.toString(), isNot(contains('5.00')));
    },
  );

  test(
    'ocr damaged receipt times are tracked without transaction id false positives',
    () {
      const result = ReceiptOcrResult(
        rawText: '''
RIVER ROAD MART 418
O7.O9.2I 13.I4
TRANS 13:14
SHOP TOWELS 5.00
AUTH 1314
TOTAL 5.00
''',
        parserText: '''
RIVER ROAD MART 418
O7.O9.2I 13.I4
TRANS 13:14
SHOP TOWELS 5.00
AUTH 1314
TOTAL 5.00
''',
        textByAttachmentId: {'photo-1': 'private receipt text omitted'},
        source: ReceiptProcessingSource.photo,
      );

      final handoff = result.parserHandoff;
      final contract = handoff.privacySafeParserHandoffContract;

      expect(result.dateCandidateLines, ['O7.O9.2I 13.I4']);
      expect(result.timeCandidateLines, ['O7.O9.2I 13.I4']);
      expect(result.metadataCandidateLines, contains('TRANS 13:14'));
      expect(result.tenderCandidateLines, contains('AUTH 1314'));
      expect(result.timeCandidateLines, isNot(contains('TRANS 13:14')));
      expect(result.timeCandidateLines, isNot(contains('AUTH 1314')));
      final authSignal = result.parserLineSignals.singleWhere(
        (signal) => signal.text == 'AUTH 1314',
      );
      expect(authSignal.kind, ReceiptOcrParserLineKind.tenderCandidate);
      expect(authSignal.primaryAmount, isNull);
      expect(handoff.timeCandidateLineIds, ['ocr_line_001_date']);
      expect(handoff.primaryDateLine?.traits, contains('time_present'));
      expect(contract['timeCandidateLineIds'], ['ocr_line_001_date']);
      expect((contract['parserTaskCounts'] as Map)['time_candidate'], 1);
      expect(result.parserSignalCounts['timeCandidateLineCount'], 1);
      expect(contract.toString(), isNot(contains('13.I4')));
      expect(contract.toString(), isNot(contains('13:14')));
    },
  );

  test('total-only receipt is ready when parser item lines reconcile', () {
    const result = ReceiptOcrResult(
      rawText: '''
AUTO SUPPLY EXPRESS
06/30/2026
SHOP TOWELS 10.00
MICROFIBER TOWELS 5.00
TOTAL 15.00
''',
      parserText: '''
AUTO SUPPLY EXPRESS
06/30/2026
SHOP TOWELS 10.00
MICROFIBER TOWELS 5.00
TOTAL 15.00
''',
      textByAttachmentId: {'photo-1': 'private receipt text omitted'},
      source: ReceiptProcessingSource.photo,
    );

    final handoff = result.parserHandoff;
    final contract = handoff.privacySafeParserHandoffContract;

    expect(handoff.hasTotalOnlySummary, isTrue);
    expect(handoff.totalOnlyLineMathReconciled, isTrue);
    expect(handoff.totalOnlyLineMathNeedsReview, isFalse);
    expect(handoff.itemLines, hasLength(2));
    expect(handoff.parserReadyLineCount, 2);
    expect(handoff.itemAmountSubtotal, 15.00);
    expect(handoff.primaryTotalAmount, 15.00);
    expect(handoff.mixedClassificationReadinessStatus, 'ready');
    expect(handoff.downstreamReadinessStatus, 'vehicle_cost_ready');
    expect(handoff.leanLocalOcrReadinessStatus, 'line_items_ready');
    expect(handoff.parserTaskCounts['total_only_line_math_reconciled'], 1);
    expect(handoff.vehicleSupplyCandidateLineCount, 2);
    expect(
      (contract['parserTaskCounts'] as Map)['total_only_line_math_reconciled'],
      1,
    );
    expect(contract.toString(), isNot(contains('AUTO SUPPLY EXPRESS')));
    expect(contract.toString(), isNot(contains('15.00')));
  });
}
