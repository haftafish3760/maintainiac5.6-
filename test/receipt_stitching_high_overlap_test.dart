import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

import 'helpers/receipt_stitching_image_helpers.dart';

void main() {
  test(
    'stitches a high-overlap final long-receipt section',
    () async {
      final receipt = tallReceiptStitchingCanvas(sectionCount: 4);
      final sections = [
        cropReceiptStitchingPhoneWindow(receipt, y: 0),
        cropReceiptStitchingPhoneWindow(receipt, y: 1120),
        cropReceiptStitchingPhoneWindow(receipt, y: 2240),
        cropReceiptStitchingPhoneWindow(receipt, y: 2800),
        cropReceiptStitchingPhoneWindow(receipt, y: 3360),
      ];
      final files = await Future.wait([
        for (var index = 0; index < sections.length; index++)
          writeTempReceiptStitchingImage(
            sections[index],
            'high_overlap_final_$index',
          ),
      ]);

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [for (final file in files) file.path],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.pairs, hasLength(4));
      expect(result.pairs.last.overlapPixels, greaterThan(800));
      expect(result.pairs.last.confidence, greaterThanOrEqualTo(.50));
      expect(result.ocrSourcePaths, [result.stitchedPath]);
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
