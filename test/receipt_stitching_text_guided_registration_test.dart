import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

import 'helpers/receipt_stitching_image_helpers.dart';

ReceiptStitchTextEvidence _textEvidence({
  required String path,
  required double firstTop,
  required double centerX,
  required double angle,
}) {
  final lines = <ReceiptStitchTextLineEvidence>[
    ReceiptStitchTextLineEvidence(
      text: 'Copper elbow half inch 2.49',
      left: centerX - .26,
      top: firstTop,
      right: centerX + .26,
      bottom: firstTop + .035,
      angleDegrees: angle,
    ),
    ReceiptStitchTextLineEvidence(
      text: 'Exterior screws three inch 12.40',
      left: centerX - .29,
      top: firstTop + .08,
      right: centerX + .29,
      bottom: firstTop + .115,
      angleDegrees: angle,
    ),
  ];
  return ReceiptStitchTextEvidence(
    path: path,
    lines: [for (final line in lines) line.text],
    positionedLines: lines,
  );
}

void main() {
  test(
    'positional OCR guides scale rotation horizontal drift and overlap',
    () async {
      final top = receiptStitchingSection(seed: 240, topTextOffset: 0);
      final bottom = receiptStitchingSection(seed: 241, topTextOffset: 20);
      copyReceiptStitchingOverlap(from: top, to: bottom, pixels: 320, dstY: 18);
      final transformedBottom = shiftReceiptStitchingShot(
        rotateReceiptStitchingShot(bottom, degrees: -.8),
        dx: -18,
        dy: 0,
      );
      final topFile = await writeTempReceiptStitchingImage(
        top,
        'text_guided_top',
      );
      final bottomFile = await writeTempReceiptStitchingImage(
        transformedBottom,
        'text_guided_bottom',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [topFile.path, bottomFile.path],
        textEvidence: [
          _textEvidence(
            path: topFile.path,
            firstTop: .79,
            centerX: .50,
            angle: 0,
          ),
          _textEvidence(
            path: bottomFile.path,
            firstTop: .05,
            centerX: .48,
            angle: -.8,
          ),
        ],
      );

      expect(result.didStitch, isTrue, reason: result.pairDiagnosticsLabel);
      final pair = result.pairs.single;
      expect(pair.matchedTextLineCount, 2);
      expect(pair.hasTextPositionEvidence, isTrue);
      expect(
        pair.selectedSeamCropPixels,
        greaterThanOrEqualTo((pair.overlapPixels * .55).round()),
        reason: 'The seam must clear both OCR-matched lines, not bisect them.',
      );
      expect(pair.rotationCorrectionDegrees, closeTo(.8, .05));
      expect(pair.horizontalOffsetPixels, lessThan(0));
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
