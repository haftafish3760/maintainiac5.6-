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

  test('split-row fuel OCR handoff keeps neighboring detail evidence', () {
    const result = ReceiptOcrResult(
      rawText: '''
COUNTY LINE MARKET
06/29/2026
PUMP 04
PRODUCT D1ESEL
GALLONS 12.349
PR1CE / GA1 3.699
FUE1 SALE 45.68
TOTAL 45.68
CARD 45.68
''',
      parserText: '''
COUNTY LINE MARKET
06/29/2026
PUMP 04
PRODUCT D1ESEL
GALLONS 12.349
PR1CE / GA1 3.699
FUE1 SALE 45.68
TOTAL 45.68
CARD 45.68
''',
      textByAttachmentId: {'photo-1': 'private receipt text omitted'},
      source: ReceiptProcessingSource.photo,
    );

    final handoff = result.parserHandoff;
    final diagnostics = result.diagnostics;
    final contract = handoff.privacySafeParserHandoffContract;

    expect(
      handoff.parserTaskCounts['fuel_quantity_signal'],
      greaterThanOrEqualTo(1),
    );
    expect(
      handoff.parserTaskCounts['fuel_unit_price_signal'],
      greaterThanOrEqualTo(1),
    );
    expect(
      handoff.parserTaskCounts['fuel_detail_ready'],
      greaterThanOrEqualTo(1),
    );
    expect(
      diagnostics.parserTaskCounts['fuel_detail_ready'],
      greaterThanOrEqualTo(1),
    );
    expect(
      contract['fuelQuantitySignalLineIds'],
      isA<List>().having((ids) => ids.length, 'line count', greaterThan(0)),
    );
    expect(
      contract['fuelUnitPriceSignalLineIds'],
      isA<List>().having((ids) => ids.length, 'line count', greaterThan(0)),
    );
    expect(
      contract['fuelDetailReadyLineIds'],
      isA<List>().having((ids) => ids.length, 'line count', greaterThan(1)),
    );
    expect(diagnostics.parserSignalSummaryLabel, contains('fuel detail set'));
    expect(
      diagnostics.parserSignalSummaryLabel,
      contains('fuel quantity signal'),
    );
    expect(
      diagnostics.parserSignalSummaryLabel,
      contains('fuel unit price signal'),
    );
    expect(contract.toString(), isNot(contains('COUNTY LINE MARKET')));
    expect(contract.toString(), isNot(contains('45.68')));
  });

  test('abbreviated fuel OCR handoff keeps PPG and QTY detail evidence', () {
    const result = ReceiptOcrResult(
      rawText: '''
RURAL STOP 12
06/30/2026
PUMP 02
PRODUCT UNL
PPG 3.699
QTY 12.349
FUEL 45.68
TOTAL 45.68
VISA 45.68
''',
      parserText: '''
RURAL STOP 12
06/30/2026
PUMP 02
PRODUCT UNL
PPG 3.699
QTY 12.349
FUEL 45.68
TOTAL 45.68
VISA 45.68
''',
      textByAttachmentId: {'photo-1': 'private receipt text omitted'},
      source: ReceiptProcessingSource.photo,
    );

    final handoff = result.parserHandoff;
    final diagnostics = result.diagnostics;
    final contract = handoff.privacySafeParserHandoffContract;

    expect(
      handoff.parserTaskCounts['fuel_quantity_signal'],
      greaterThanOrEqualTo(1),
    );
    expect(
      handoff.parserTaskCounts['fuel_unit_price_signal'],
      greaterThanOrEqualTo(1),
    );
    expect(
      handoff.parserTaskCounts['fuel_detail_ready'],
      greaterThanOrEqualTo(1),
    );
    expect(
      diagnostics.parserTaskCounts['fuel_detail_ready'],
      greaterThanOrEqualTo(1),
    );
    expect(
      contract['fuelQuantitySignalLineIds'],
      isA<List>().having((ids) => ids.length, 'line count', greaterThan(0)),
    );
    expect(
      contract['fuelUnitPriceSignalLineIds'],
      isA<List>().having((ids) => ids.length, 'line count', greaterThan(0)),
    );
    expect(diagnostics.parserSignalSummaryLabel, contains('fuel detail set'));
    expect(contract.toString(), isNot(contains('RURAL STOP')));
    expect(contract.toString(), isNot(contains('45.68')));
  });
}
