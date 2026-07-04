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
      valueType: 'WIFI',
      rawValue: 'WIFI:T:WPA;S:PrivateNetwork;P:secret;;',
    );
    const driverLicense = ReceiptScannedCode(
      format: ReceiptBarcodeFormat.pdf417,
      valueType: 'driver_license',
      rawValue: 'private-license-payload',
    );
    const malformedType = ReceiptScannedCode(
      format: ReceiptBarcodeFormat.qrCode,
      valueType: 'customer_email_private_payload',
      rawValue: 'QR WORK 14 2 NMB',
    );
    const url = ReceiptScannedCode(
      format: ReceiptBarcodeFormat.qrCode,
      valueType: 'url',
      rawValue: 'https://receipt.example/order/customer/123',
    );
    const textUrl = ReceiptScannedCode(
      format: ReceiptBarcodeFormat.qrCode,
      valueType: 'text',
      rawValue: 'https://receipt.example/session/abc123',
    );
    const textWifi = ReceiptScannedCode(
      format: ReceiptBarcodeFormat.qrCode,
      valueType: 'text',
      rawValue: 'WIFI:T:WPA;S:PrivateNetwork;P:secret;;',
    );

    expect(wifi.inventoryLookupValue, isNull);
    expect(driverLicense.inventoryLookupValue, isNull);
    expect(url.inventoryLookupValue, isNull);
    expect(textUrl.inventoryLookupValue, isNull);
    expect(textWifi.inventoryLookupValue, isNull);
    expect(wifi.privacySafeSummaryMap['isSensitivePayloadType'], isTrue);
    expect(url.privacySafeSummaryMap['isSensitivePayloadType'], isTrue);
    expect(textUrl.privacySafeSummaryMap['isSensitivePayloadType'], isTrue);
    expect(textWifi.privacySafeSummaryMap['isSensitivePayloadType'], isTrue);
    expect(textUrl.privacySafeSummaryMap['valueTypeBucket'], 'text');
    expect(textWifi.privacySafeSummaryMap['valueTypeBucket'], 'text');
    expect(url.privacySafeSummaryMap['valueTypeBucket'], 'url');
    expect(wifi.privacySafeSummaryMap['valueTypeBucket'], 'wifi');
    expect(
      driverLicense.privacySafeSummaryMap['valueTypeBucket'],
      'driverLicense',
    );
    expect(malformedType.inventoryLookupValue, isNull);
    expect(
      malformedType.privacySafeSummaryMap['isSensitivePayloadType'],
      isTrue,
    );
    expect(
      malformedType.privacySafeSummaryMap['valueTypeBucket'],
      'sensitiveOther',
    );
    expect(
      malformedType.privacySafeSummaryMap.toString(),
      isNot(contains('customer_email_private_payload')),
    );
    expect(
      malformedType.privacySafeSummaryMap.toString(),
      isNot(contains('QRWORK')),
    );
    expect(
      driverLicense.privacySafeSummaryMap.toString(),
      isNot(contains('private')),
    );
    expect(url.privacySafeSummaryMap.toString(), isNot(contains('customer')));
    expect(textUrl.privacySafeSummaryMap.toString(), isNot(contains('abc123')));
    expect(
      textWifi.privacySafeSummaryMap.toString(),
      isNot(contains('PrivateNetwork')),
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

  test('barcode scanner converts generic decoder failures safely', () async {
    final service = ReceiptBarcodeScannerService(
      decoder: _ThrowingBarcodeDecoder(
        StateError('private corrupted receipt barcode 036000291452'),
      ),
    );

    final result = await service.scanImageFile('/tmp/wrong-file.txt');

    expect(result.codes, isEmpty);
    expect(result.warnings, const ['barcode_scan_failed']);
    expect(result.privacySafeSummaryMap['warningBuckets'], [
      'barcode_scan_failed',
    ]);
    expect(
      result.privacySafeSummaryMap.toString(),
      isNot(contains('036000291452')),
    );
    expect(result.privacySafeSummaryMap.toString(), isNot(contains('private')));
  });

  test('barcode scan summary buckets raw warning text', () {
    const result = ReceiptBarcodeScanResult(
      imagePath: '/tmp/code.jpg',
      purpose: ReceiptBarcodeScanPurpose.shared,
      codes: [],
      warnings: [
        'barcode_scan_failed',
        'private customer barcode warning 036000291452',
      ],
    );

    expect(result.privacySafeSummaryMap['warningBuckets'], [
      'barcode_scan_failed',
      'barcode_scan_warning',
    ]);
    expect(
      result.privacySafeSummaryMap.toString(),
      isNot(contains('036000291452')),
    );
    expect(
      result.privacySafeSummaryMap.toString(),
      isNot(contains('private customer')),
    );
  });

  test(
    'barcode batch scanner dedupes lookup values across receipt segments',
    () async {
      final service = ReceiptBarcodeScannerService(
        decoder: _PathAwareBarcodeDecoder({
          '/tmp/segment-1.jpg': const [
            ReceiptScannedCode(
              format: ReceiptBarcodeFormat.upca,
              valueType: 'product',
              rawValue: '0 12345-67890 5',
            ),
          ],
          '/tmp/segment-2.jpg': const [
            ReceiptScannedCode(
              format: ReceiptBarcodeFormat.upca,
              valueType: 'product',
              rawValue: '012345678905',
            ),
            ReceiptScannedCode(
              format: ReceiptBarcodeFormat.qrCode,
              valueType: 'text',
              rawValue: 'QR WORK 14 2 NMB',
            ),
          ],
        }),
      );

      final result = await service.scanImageFiles([
        '/tmp/segment-1.jpg',
        '/tmp/segment-2.jpg',
      ], purpose: ReceiptBarcodeScanPurpose.inventory);

      expect(result.imageCount, 2);
      expect(result.codeCount, 3);
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

  test('barcode batch scanner bounds multi-photo receipt work', () async {
    final decoder = _CountingBarcodeDecoder();
    final service = ReceiptBarcodeScannerService(decoder: decoder);

    final result = await service.scanImageFiles([
      '/tmp/one.jpg',
      '/tmp/two.jpg',
      '/tmp/three.jpg',
    ], maxImageCount: 2);

    expect(decoder.calls, 2);
    expect(result.imageCount, 2);
    expect(result.warnings, const ['barcode_scan_batch_image_limit']);
    expect(result.privacySafeSummaryMap['batchWarningBuckets'], [
      'barcode_scan_batch_image_limit',
    ]);
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

class _PathAwareBarcodeDecoder implements ReceiptBarcodeImageDecoder {
  const _PathAwareBarcodeDecoder(this.codesByPath);

  final Map<String, List<ReceiptScannedCode>> codesByPath;

  @override
  Future<List<ReceiptScannedCode>> scanImageFile(
    String imagePath, {
    required List<ReceiptBarcodeFormat> formats,
  }) async {
    return codesByPath[imagePath] ?? const [];
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
