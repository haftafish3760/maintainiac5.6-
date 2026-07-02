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
    'fuel-named merchant stays vendor while fuel line stays parser-ready',
    () {
      const result = ReceiptOcrResult(
        rawText: '''
FUEL STOP
06/12/2026
UNLEADED 10.000 GAL 3.49 35.00
FUEL SALE 35.00
CARD 35.00
''',
        parserText: '''
FUEL STOP
06/12/2026
UNLEADED 10.000 GAL 3.49 35.00
FUEL SALE 35.00
CARD 35.00
''',
        textByAttachmentId: {'photo-1': 'private receipt text omitted'},
        source: ReceiptProcessingSource.photo,
      );

      final handoff = result.parserHandoff;
      final contract = handoff.privacySafeParserHandoffContract;

      expect(result.vendorCandidateLines, ['FUEL STOP']);
      expect(handoff.primaryVendorLine?.text, 'FUEL STOP');
      expect(handoff.itemLines, hasLength(1));
      expect(handoff.itemLines.single.text, contains('UNLEADED'));
      expect(handoff.parserReadyLineCount, 1);
      expect(handoff.fuelCandidateLineCount, 1);
      expect(handoff.lineSequenceStatus, 'expected_order');
      expect(handoff.mixedClassificationReadinessStatus, 'ready');
      expect(
        handoff.merchantIndependentStructureStatus,
        'generic_fuel_receipt_ready',
      );
      expect((contract['fuelReadyLineIds'] as List), ['ocr_line_002_item']);
      expect((contract['parserTaskLineIds'] as Map)['vendor_candidate'], [
        'ocr_line_000_vendor',
      ]);
      expect(contract.toString(), isNot(contains('FUEL STOP')));
      expect(contract.toString(), isNot(contains('35.00')));
    },
  );

  test('noisy fuel header keeps license address and terminal as metadata', () {
    const result = ReceiptOcrResult(
      rawText: '''
CITY FUEL MARKET
BUSINESS LICENSE 48-12345
123 MAIN ST
AUSTIN TX 78745
(555) 222-3333
TERMINAL 03
06/30/2026
REGULAR 8.000 GAL 3.25 26.00
FUEL SALE 26.00
CARD 26.00
''',
      parserText: '''
CITY FUEL MARKET
BUSINESS LICENSE 48-12345
123 MAIN ST
AUSTIN TX 78745
(555) 222-3333
TERMINAL 03
06/30/2026
REGULAR 8.000 GAL 3.25 26.00
FUEL SALE 26.00
CARD 26.00
''',
      textByAttachmentId: {'photo-1': 'private receipt text omitted'},
      source: ReceiptProcessingSource.photo,
    );

    final handoff = result.parserHandoff;
    final contract = handoff.privacySafeParserHandoffContract;

    expect(result.vendorCandidateLines, ['CITY FUEL MARKET']);
    expect(
      result.metadataCandidateLines,
      contains('BUSINESS LICENSE 48-12345'),
    );
    expect(result.metadataCandidateLines, contains('123 MAIN ST'));
    expect(result.metadataCandidateLines, contains('AUSTIN TX 78745'));
    expect(result.metadataCandidateLines, contains('(555) 222-3333'));
    expect(result.metadataCandidateLines, contains('TERMINAL 03'));
    expect(handoff.primaryVendorLine?.text, 'CITY FUEL MARKET');
    expect(handoff.metadataLines, hasLength(5));
    expect(handoff.itemLines, hasLength(1));
    expect(handoff.itemLines.single.text, contains('REGULAR'));
    expect(handoff.parserReadyLineCount, 1);
    expect(handoff.lineSequenceStatus, 'expected_order');
    expect(handoff.mixedClassificationReadinessStatus, 'ready');
    expect(
      handoff.merchantIndependentStructureStatus,
      'generic_fuel_receipt_ready',
    );
    expect(handoff.parserTaskCounts['fuel_detail_ready'], 1);
    expect((contract['parserTaskLineIds'] as Map)['vendor_candidate'], [
      'ocr_line_000_vendor',
    ]);
    expect(contract.toString(), isNot(contains('CITY FUEL MARKET')));
    expect(contract.toString(), isNot(contains('48-12345')));
    expect(contract.toString(), isNot(contains('222-3333')));
    expect(contract.toString(), isNot(contains('26.00')));
  });

  test('unknown fuel merchant routes mismatched total-only math to review', () {
    const result = ReceiptOcrResult(
      rawText: '''
CORNER MART #42
06/12/2026
PUMP 07
UNLEADED 12.345 GAL 3.19 39.38
TOTAL 44.38
CARD 44.38
''',
      parserText: '''
CORNER MART #42
06/12/2026
PUMP 07
UNLEADED 12.345 GAL 3.19 39.38
TOTAL 44.38
CARD 44.38
''',
      textByAttachmentId: {'photo-1': 'private receipt text omitted'},
      source: ReceiptProcessingSource.photo,
    );

    final handoff = result.parserHandoff;
    final diagnostics = result.diagnostics;

    expect(handoff.primaryVendorLine?.text, 'CORNER MART #42');
    expect(handoff.fuelCandidateLineCount, 1);
    expect(handoff.primaryTotalLine?.text, 'TOTAL 44.38');
    expect(handoff.parserReadyLineCount, 1);
    expect(handoff.downstreamReadinessStatus, 'expense_lines_need_review');
    expect(handoff.parserTaskCounts['receipt_total_only_line_math_review'], 1);
    expect(
      handoff.parserTaskCounts.containsKey('receipt_total_only_ready'),
      isFalse,
    );
    expect(
      diagnostics.parserTaskCounts['receipt_total_only_line_math_review'],
      1,
    );
    expect(
      handoff.downstreamReadinessLabel,
      'Expense lines were found, but some need review before saving.',
    );
  });

  test('unknown material merchant exposes merchant-independent structure', () {
    const result = ReceiptOcrResult(
      rawText: '''
LOCAL SUPPLY DEPOT
06/12/2026
PVC ELBOW 1/2 IN 2.49
TAX 0.20
TOTAL 2.69
''',
      parserText: '''
LOCAL SUPPLY DEPOT
06/12/2026
PVC ELBOW 1/2 IN 2.49
TAX 0.20
TOTAL 2.69
''',
      textByAttachmentId: {'photo-1': 'private receipt text omitted'},
      source: ReceiptProcessingSource.photo,
    );

    final handoff = result.parserHandoff;

    expect(handoff.materialCandidateLineCount, 1);
    expect(handoff.primaryTotalAmount, 2.69);
    expect(handoff.hasMerchantIndependentReceiptStructure, isTrue);
    expect(
      handoff.merchantIndependentStructureStatus,
      'generic_material_receipt_ready',
    );
    expect(
      handoff.parserTaskCounts['generic_material_receipt_ready'],
      greaterThan(0),
    );
    expect(
      handoff.privacySafeParserHandoffContract.toString(),
      isNot(contains('LOCAL SUPPLY')),
    );
    expect(
      result.diagnostics.parserSignalSummaryLabel,
      contains('merchant-independent generic_material_receipt_ready'),
    );
  });
}
