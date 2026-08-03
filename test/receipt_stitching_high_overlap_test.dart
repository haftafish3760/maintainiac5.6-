import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

import 'helpers/receipt_stitching_image_helpers.dart';

void main() {
  test(
    'stitches a valid high-overlap final receipt section',
    () async {
      final firstSection = receiptStitchingSection(seed: 903, topTextOffset: 0);
      final finalSection = receiptStitchingSection(
        seed: 904,
        topTextOffset: 20,
      );
      copyReceiptStitchingOverlap(
        from: firstSection,
        to: finalSection,
        pixels: 930,
      );
      final first = await writeTempReceiptStitchingImage(
        firstSection,
        'high_overlap_final_a',
      );
      final second = await writeTempReceiptStitchingImage(
        finalSection,
        'high_overlap_final_b',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.overlapPixels.single, greaterThanOrEqualTo(900));
      expect(result.pairs.single.confidence, greaterThanOrEqualTo(.50));
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
