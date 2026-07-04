import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

void main() {
  test('barcode handoff scans OCR source photos before saved proof', () async {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/proof-1.jpg', '/tmp/proof-2.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/ocr-1.jpg', '/tmp/ocr-2.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: const ReceiptStitchResult.notNeeded([
        '/tmp/ocr-1.jpg',
        '/tmp/ocr-2.jpg',
      ]),
    );
    final decoder = _RecordingBarcodeDecoder();

    final scan = await ReceiptCaptureFlow.scanBarcodesFromReviewResult(
      result,
      barcodeScanner: ReceiptBarcodeScannerService(decoder: decoder),
      purpose: ReceiptBarcodeScanPurpose.inventory,
    );

    expect(decoder.paths, const ['/tmp/ocr-1.jpg', '/tmp/ocr-2.jpg']);
    expect(scan.imageCount, 2);
    expect(scan.privacySafeSummaryMap['purpose'], 'inventory');
    expect(scan.privacySafeSummaryMap['formatCounts'], {
      'upca': 2,
      'qrCode': 1,
    });
    expect(scan.privacySafeSummaryMap['valueTypeCounts'], {
      'product': 2,
      'text': 1,
    });
    expect(scan.privacySafeSummaryMap.toString(), isNot(contains('012345')));
    expect(scan.privacySafeSummaryMap.toString(), isNot(contains('QRWORK')));
  });

  test(
    'barcode handoff falls back to saved proof only when OCR source falls back',
    () async {
      final result = ReceiptPhotoReviewResult(
        photoPaths: const ['/tmp/proof-only.jpg'],
        ocrSourcePhotoPaths: const [],
        dataSaverLevel: ReceiptDataSaverLevel.maximum,
        stitchResult: const ReceiptStitchResult.notNeeded([
          '/tmp/proof-only.jpg',
        ]),
      );
      final decoder = _RecordingBarcodeDecoder();

      final scan = await ReceiptCaptureFlow.scanBarcodesFromReviewResult(
        result,
        barcodeScanner: ReceiptBarcodeScannerService(decoder: decoder),
        purpose: ReceiptBarcodeScanPurpose.maintenance,
      );

      expect(decoder.paths, const ['/tmp/proof-only.jpg']);
      expect(scan.imageCount, 1);
      expect(scan.privacySafeSummaryMap['purpose'], 'maintenance');
    },
  );
}

class _RecordingBarcodeDecoder implements ReceiptBarcodeImageDecoder {
  final paths = <String>[];

  @override
  Future<List<ReceiptScannedCode>> scanImageFile(
    String imagePath, {
    required List<ReceiptBarcodeFormat> formats,
  }) async {
    paths.add(imagePath);
    if (imagePath.endsWith('ocr-1.jpg')) {
      return const [
        ReceiptScannedCode(
          format: ReceiptBarcodeFormat.upca,
          valueType: 'product',
          rawValue: '0 12345-67890 5',
        ),
      ];
    }
    if (imagePath.endsWith('ocr-2.jpg')) {
      return const [
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
      ];
    }
    return const [];
  }
}
