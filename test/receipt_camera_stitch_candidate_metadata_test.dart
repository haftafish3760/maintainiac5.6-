import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  test('stitched OCR handoff exposes privacy-safe candidate dimensions', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/proof-1.jpg', '/tmp/proof-2.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/stitched-ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: ReceiptStitchResult(
        status: ReceiptStitchStatus.stitched,
        inputPaths: const ['/tmp/source-1.jpg', '/tmp/source-2.jpg'],
        ocrSourcePaths: const ['/tmp/stitched-ocr.jpg'],
        stitchedPath: '/tmp/stitched-ocr.jpg',
        confidence: .88,
        overlapPixels: const [320],
        pairs: const [
          ReceiptStitchPairResult(
            pairIndex: 0,
            overlapPixels: 320,
            confidence: .88,
          ),
        ],
        stitchedWidth: 1200,
        stitchedHeight: 2680,
      ),
    );

    final metadata = result.privacySafeReceiptReaderHandoffMetadata;

    expect(metadata, containsPair('stitchCandidateWidth', 1200));
    expect(metadata, containsPair('stitchCandidateHeight', 2680));
    expect(metadata, containsPair('stitchCandidatePixelCount', 3216000));
    expect(metadata.toString(), isNot(contains('/tmp/source-1.jpg')));
    expect(metadata.toString(), isNot(contains('/tmp/source-2.jpg')));
    expect(metadata, containsPair('stitchOcrHandoffUsesCombinedImage', true));
  });
}
