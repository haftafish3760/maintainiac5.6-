import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

void main() {
  test('barcode handoff scans OCR source photos before saved proof', () async {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/proof-1.jpg', '/tmp/proof-2.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/ocr-1.jpg', '/tmp/ocr-2.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: ReceiptStitchResult.notNeeded([
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

    final handoff = ReceiptCaptureFlow.barcodeCameraHandoffSummary(
      result,
      scan,
    );
    expect(
      handoff,
      containsPair('schema', 'receipt_barcode_camera_handoff_v1'),
    );
    expect(
      handoff,
      containsPair('privacyScope', 'summary_only_no_barcode_values'),
    );
    expect(
      handoff,
      containsPair('sourcePolicy', result.ocrSourceFirstDecisionCode),
    );
    expect(handoff, containsPair('usedOcrSources', true));
    expect(handoff, containsPair('usedSavedProofFallback', false));
    expect(handoff, containsPair('sourceImageCount', 2));
    expect(handoff, containsPair('codeCount', 3));
    expect(handoff, containsPair('qrCodeCount', 1));
    expect(handoff.toString(), isNot(contains('012345')));
    expect(handoff.toString(), isNot(contains('QRWORK')));
  });

  test(
    'barcode handoff falls back to saved proof only when OCR source falls back',
    () async {
      final result = ReceiptPhotoReviewResult(
        photoPaths: const ['/tmp/proof-only.jpg'],
        ocrSourcePhotoPaths: const [],
        dataSaverLevel: ReceiptDataSaverLevel.maximum,
        stitchResult: ReceiptStitchResult.notNeeded(['/tmp/proof-only.jpg']),
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
      expect(
        ReceiptCaptureFlow.barcodeCameraHandoffSummary(result, scan),
        containsPair('usedSavedProofFallback', true),
      );
    },
  );

  test(
    'barcode handoff carries stitch fallback safety without values',
    () async {
      final result = ReceiptPhotoReviewResult(
        photoPaths: const ['/tmp/top-proof.jpg', '/tmp/bottom-proof.jpg'],
        ocrSourcePhotoPaths: const ['/tmp/top-ocr.jpg', '/tmp/bottom-ocr.jpg'],
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
        stitchResult: ReceiptStitchResult.fallback(
          inputPaths: ['/tmp/top-ocr.jpg', '/tmp/bottom-ocr.jpg'],
          warning: 'Overlap confidence low.',
          fallbackReasonCode: 'overlap_confidence_low',
        ),
      );
      final decoder = _RecordingBarcodeDecoder();

      final scan = await ReceiptCaptureFlow.scanBarcodesFromReviewResult(
        result,
        barcodeScanner: ReceiptBarcodeScannerService(decoder: decoder),
        purpose: ReceiptBarcodeScanPurpose.shared,
      );
      final handoff = ReceiptCaptureFlow.barcodeCameraHandoffSummary(
        result,
        scan,
      );

      expect(
        handoff['stitchOcrHandoffSafetyCode'],
        {'ordered_sections_after_overlap_confidence_low_fallback'}.single,
      );
      expect(
        handoff,
        containsPair('stitchOcrHandoffUsesOrderedSections', true),
      );
      expect(handoff, containsPair('stitchOcrHandoffUsesCombinedImage', false));
      expect(handoff.toString(), isNot(contains('/tmp/top-ocr.jpg')));
      expect(handoff.toString(), isNot(contains('QRWORK')));
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
