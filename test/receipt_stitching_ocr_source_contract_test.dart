import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

void main() {
  test('final OCR handoff preserves stitch pair evidence path-free', () {
    final preview = ReceiptStitchResult(
      status: ReceiptStitchStatus.stitched,
      inputPaths: const ['/tmp/raw-top.jpg', '/tmp/raw-bottom.jpg'],
      ocrSourcePaths: const ['/tmp/preview-stitch.jpg'],
      stitchedPath: '/tmp/preview-stitch.jpg',
      confidence: .81,
      overlapPixels: const [276],
      pairs: const [
        ReceiptStitchPairResult(
          pairIndex: 0,
          overlapPixels: 276,
          confidence: .81,
          horizontalOffsetPixels: 28,
        ),
      ],
      stitchedWidth: 900,
      stitchedHeight: 2724,
    );

    final finalResult = preview.copyForFinalOcr(
      inputPaths: const [
        '/private/original-top.jpg',
        '/private/original-bottom.jpg',
      ],
      ocrSourcePaths: const ['/private/final-stitch.jpg'],
      stitchedPath: '/private/final-stitch.jpg',
    );
    final review = ReceiptPhotoReviewResult(
      photoPaths: const ['/private/proof-top.jpg', '/private/proof-bottom.jpg'],
      ocrSourcePhotoPaths: finalResult.ocrSourcePaths,
      stitchResult: finalResult,
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
    );

    expect(finalResult.ocrSourceContractCode, 'stitched_ocr_source_ready');
    expect(finalResult.sourcePreservationCode, contains('preserved'));
    expect(finalResult.pairs.single.diagnosticCode, 'drift_adjusted');
    expect(finalResult.overlapPixels, [276]);
    expect(
      review.privacySafeReceiptReaderHandoffMetadata,
      containsPair('stitchPairSafetySummaries', [
        {
          'startSectionNumber': 1,
          'endSectionNumber': 2,
          'overlapPixels': 276,
          'confidencePercent': 81,
          'usedManualAdjustment': false,
          'diagnosticCode': 'drift_adjusted',
        },
      ]),
    );
    expect(
      review.privacySafeReceiptReaderHandoffMetadata.toString(),
      isNot(contains('/private/')),
    );
  });
}
