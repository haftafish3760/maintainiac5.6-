import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

import 'helpers/receipt_stitching_image_helpers.dart';

void main() {
  test(
    'stitches a high-overlap final long-receipt section',
    () async {
      final receipt = img.copyCrop(
        tallReceiptStitchingCanvas(sectionCount: 4),
        x: 0,
        y: 0,
        width: 900,
        height: 4300,
      );
      final sections = [
        cropReceiptStitchingPhoneWindow(receipt, y: 0),
        cropReceiptStitchingPhoneWindow(receipt, y: 1120),
        cropReceiptStitchingPhoneWindow(receipt, y: 2240),
        cropReceiptStitchingPhoneWindow(receipt, y: 2800),
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
        manualOverlapPixels: const [380, 380, 940],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.pairs, hasLength(3));
      expect(result.pairs.last.overlapPixels, greaterThan(800));
      expect(result.pairs.last.usedManualAdjustment, isTrue);
      expect(result.ocrSourcePaths, [result.stitchedPath]);
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
