import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

import 'helpers/receipt_stitching_image_helpers.dart';
import 'helpers/receipt_stitching_result_reason.dart';

const _timeout = Timeout(Duration(minutes: 2));

void main() {
  test(
    'stitches long receipt photos taken on a dark passenger-seat surface',
    () async {
      final files = await _writePassengerSeatStack(
        'passenger_seat_dark_surface',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [for (final file in files) file.path],
      );

      expect(
        result.didStitch,
        isTrue,
        reason: receiptStitchingResultReason(result),
      );
      expect(result.pairs, hasLength(2));
      expect(result.overlapPixels, hasLength(2));
      expect(result.overlapPixelTotal, greaterThan(640));
      expect(
        result.pairs.map((pair) => pair.confidence),
        everyElement(greaterThanOrEqualTo(.50)),
      );
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
      expect(result.ocrSourcePaths, [result.stitchedPath]);
      expect(result.requiresOcrSourceReviewBeforeAssistedRead, isTrue);
      expect(result.assistedReadinessCode, 'stitched_overlap_review_required');
      expect(result.stitchedPixelCount, lessThan(12000000));
    },
    timeout: _timeout,
  );
}

Future<List<File>> _writePassengerSeatStack(String prefix) async {
  final first = receiptStitchingSection(seed: 601, topTextOffset: 0);
  final second = receiptStitchingSection(seed: 602, topTextOffset: 18);
  final third = receiptStitchingSection(seed: 603, topTextOffset: -14);

  copyReceiptStitchingOverlap(from: first, to: second, pixels: 380);
  copyReceiptStitchingOverlap(from: second, to: third, pixels: 360);

  final sections = [
    _passengerSeatCapture(first, seed: 611, glareY: 260, quality: 88),
    _passengerSeatCapture(second, seed: 612, glareY: 520, quality: 84),
    _passengerSeatCapture(third, seed: 613, glareY: 700, quality: 86),
  ];

  final files = <File>[];
  for (var index = 0; index < sections.length; index++) {
    files.add(
      await writeTempReceiptStitchingImageWithQuality(
        sections[index],
        '${prefix}_${index + 1}',
        quality: 86,
      ),
    );
  }
  return files;
}

img.Image _passengerSeatCapture(
  img.Image source, {
  required int seed,
  required int glareY,
  required int quality,
}) {
  final worn = addReceiptStitchingWear(
    source,
    seed: seed,
    wrinkleCount: 7,
    smudgeCount: 4,
  );
  final glared = addReceiptStitchingGlareBand(
    worn,
    y: glareY,
    height: 70,
    alpha: 64,
  );
  final framed = frameReceiptStitchingShotOnDarkSurface(
    glared,
    left: 64,
    top: 42,
    right: 72,
    bottom: 58,
    surfaceShade: 16,
  );
  return img.copyResize(framed, width: quality.isEven ? 860 : 840);
}
