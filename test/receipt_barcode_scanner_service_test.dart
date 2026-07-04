import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

void main() {
  test(
    'barcode scanner normalizes and deduplicates inventory and QR codes',
    () async {
      final service = ReceiptBarcodeScannerService(
        decoder: _FakeBarcodeDecoder(const [
          ReceiptScannedCode(
            format: ReceiptBarcodeFormat.upca,
            valueType: 'product',
            rawValue: '0 12345-67890 5',
          ),
          ReceiptScannedCode(
            format: ReceiptBarcodeFormat.upca,
            valueType: 'product',
            rawValue: '012345678905',
          ),
          ReceiptScannedCode(
            format: ReceiptBarcodeFormat.qrCode,
            valueType: 'text',
            rawValue: ' QR WORK 14 2 nmb ',
          ),
        ]),
      );

      final result = await service.scanImageFile(
        '/tmp/receipt-code.jpg',
        purpose: ReceiptBarcodeScanPurpose.inventory,
      );

      expect(result.hasCodes, isTrue);
      expect(result.codes.length, 2);
      expect(result.qrCodeCount, 1);
      expect(result.inventoryLookupValues, const [
        '012345678905',
        'QRWORK142NMB',
      ]);
      expect(result.privacySafeSummaryMap['purpose'], 'inventory');
      expect(
        result.privacySafeSummaryMap.toString(),
        isNot(contains('012345')),
      );
      expect(
        result.privacySafeSummaryMap.toString(),
        isNot(contains('QRWORK')),
      );
    },
  );

  test('barcode scanner blocks malformed source paths before ML Kit', () async {
    final decoder = _CountingBarcodeDecoder();
    final service = ReceiptBarcodeScannerService(decoder: decoder);

    final result = await service.scanImageFile(' /tmp/code.jpg ');

    expect(result.codes, isEmpty);
    expect(result.warnings, contains('barcode_scan_invalid_source_path'));
    expect(decoder.calls, 0);
  });

  test('barcode scanner does not expose sensitive QR payloads for lookup', () {
    const wifi = ReceiptScannedCode(
      format: ReceiptBarcodeFormat.qrCode,
      valueType: 'wifi',
      rawValue: 'WIFI:T:WPA;S:PrivateNetwork;P:secret;;',
    );
    const driverLicense = ReceiptScannedCode(
      format: ReceiptBarcodeFormat.pdf417,
      valueType: 'driverLicense',
      rawValue: 'private-license-payload',
    );

    expect(wifi.inventoryLookupValue, isNull);
    expect(driverLicense.inventoryLookupValue, isNull);
    expect(wifi.privacySafeSummaryMap['isSensitivePayloadType'], isTrue);
    expect(
      driverLicense.privacySafeSummaryMap.toString(),
      isNot(contains('private')),
    );
  });

  test('barcode scanner converts platform failures into warnings', () async {
    final service = ReceiptBarcodeScannerService(
      decoder: _ThrowingBarcodeDecoder(
        PlatformException(code: 'barcode_failed'),
      ),
    );

    final result = await service.scanImageFile('/tmp/receipt-code.jpg');

    expect(result.codes, isEmpty);
    expect(result.warnings, const ['barcode_scan_platform_failed']);
  });
}

class _FakeBarcodeDecoder implements ReceiptBarcodeImageDecoder {
  const _FakeBarcodeDecoder(this.codes);

  final List<ReceiptScannedCode> codes;

  @override
  Future<List<ReceiptScannedCode>> scanImageFile(
    String imagePath, {
    required List<ReceiptBarcodeFormat> formats,
  }) async {
    return codes;
  }
}

class _CountingBarcodeDecoder implements ReceiptBarcodeImageDecoder {
  int calls = 0;

  @override
  Future<List<ReceiptScannedCode>> scanImageFile(
    String imagePath, {
    required List<ReceiptBarcodeFormat> formats,
  }) async {
    calls += 1;
    return const [];
  }
}

class _ThrowingBarcodeDecoder implements ReceiptBarcodeImageDecoder {
  const _ThrowingBarcodeDecoder(this.error);

  final Object error;

  @override
  Future<List<ReceiptScannedCode>> scanImageFile(
    String imagePath, {
    required List<ReceiptBarcodeFormat> formats,
  }) async {
    throw error;
  }
}
