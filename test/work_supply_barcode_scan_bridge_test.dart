import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_barcode_scan_bridge.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

void main() {
  test('barcode scan bridge creates inventory alias suggestions', () {
    const bridge = WorkSupplyBarcodeScanBridge();
    const result = ReceiptBarcodeScanResult(
      imagePath: '/tmp/code.jpg',
      purpose: ReceiptBarcodeScanPurpose.inventory,
      codes: [
        ReceiptScannedCode(
          format: ReceiptBarcodeFormat.upca,
          valueType: 'product',
          rawValue: '0 12345-67890 5',
        ),
        ReceiptScannedCode(
          format: ReceiptBarcodeFormat.qrCode,
          valueType: 'text',
          rawValue: 'QR WORK 14 2 NMB',
        ),
      ],
    );

    final suggestions = bridge.suggestionsFromScanResult(result);

    expect(suggestions, hasLength(2));
    expect(suggestions.first.barcodeValue, '012345678905');
    expect(suggestions.first.barcodeFormat, 'upcA');
    expect(suggestions.first.barcodeNormalized, '012345678905');
    expect(suggestions.last.barcodeFormat, 'qr');
    expect(suggestions.last.barcodeNormalized, 'QRWORK142NMB');
  });

  test('barcode scan bridge ignores sensitive or duplicate scan values', () {
    const bridge = WorkSupplyBarcodeScanBridge();
    const result = ReceiptBarcodeScanResult(
      imagePath: '/tmp/code.jpg',
      purpose: ReceiptBarcodeScanPurpose.inventory,
      codes: [
        ReceiptScannedCode(
          format: ReceiptBarcodeFormat.qrCode,
          valueType: 'wifi',
          rawValue: 'WIFI:T:WPA;S:Private;P:secret;;',
        ),
        ReceiptScannedCode(
          format: ReceiptBarcodeFormat.ean13,
          valueType: 'PRODUCT',
          rawValue: '1234567890123',
        ),
        ReceiptScannedCode(
          format: ReceiptBarcodeFormat.ean13,
          valueType: 'product',
          rawValue: '123 4567-890123',
        ),
      ],
    );

    final suggestions = bridge.suggestionsFromScanResult(result);

    expect(suggestions, hasLength(1));
    expect(suggestions.single.barcodeValue, '1234567890123');
    expect(suggestions.single.barcodeFormat, 'ean13');
    expect(suggestions.single.sourceValueType, 'product');
    expect(
      suggestions.single.privacySafeSummaryMap.toString(),
      isNot(contains('123456')),
    );
    expect(suggestions.single.privacySafeSummaryMap['normalizedLength'], 13);
  });

  test('barcode scan bridge guesses unknown product formats safely', () {
    const suggestion = WorkSupplyBarcodeScanSuggestion(
      barcodeValue: '012345678905',
      barcodeFormat: 'upcA',
      sourceFormat: ReceiptBarcodeFormat.unknown,
      sourceValueType: 'product',
    );
    const unknownCode = ReceiptScannedCode(
      format: ReceiptBarcodeFormat.unknown,
      valueType: 'product',
      rawValue: 'ABC-123-LONG-PACKAGE-CODE',
    );

    expect(suggestion.privacySafeSummaryMap['barcodeFormat'], 'upcA');
    expect(workSupplyBarcodeFormatForScannedCode(unknownCode), 'qrOrCode128');
  });

  test('barcode scan bridge blocks sensitive malformed value types', () {
    const bridge = WorkSupplyBarcodeScanBridge();
    const result = ReceiptBarcodeScanResult(
      imagePath: '/tmp/code.jpg',
      purpose: ReceiptBarcodeScanPurpose.inventory,
      codes: [
        ReceiptScannedCode(
          format: ReceiptBarcodeFormat.qrCode,
          valueType: 'private_customer_payload',
          rawValue: 'QR WORK 14 2 NMB',
        ),
      ],
    );

    final suggestions = bridge.suggestionsFromScanResult(result);

    expect(suggestions, isEmpty);
    expect(result.codes.single.privacySafeValueType, 'sensitiveOther');
    expect(result.codes.single.inventoryLookupValue, isNull);
    expect(
      result.privacySafeSummaryMap.toString(),
      isNot(contains('private_customer_payload')),
    );
    expect(result.privacySafeSummaryMap.toString(), isNot(contains('QRWORK')));
  });
}
