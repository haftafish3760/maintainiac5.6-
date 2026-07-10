import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

import 'helpers/receipt_stitching_image_helpers.dart';

const _orientationMismatchTimeout = Timeout(Duration(minutes: 2));

void main() {
  test(
    'sideways middle section cannot bypass OCR source review',
    () => _expectOrientationMismatchReview(
      degrees: 90,
      prefix: 'sideways_middle',
    ),
    timeout: _orientationMismatchTimeout,
  );

  test(
    'upside-down middle section cannot bypass OCR source review',
    () => _expectOrientationMismatchReview(
      degrees: 180,
      prefix: 'upside_down_middle',
    ),
    timeout: _orientationMismatchTimeout,
  );
}

Future<void> _expectOrientationMismatchReview({
  required double degrees,
  required String prefix,
}) async {
  final top = receiptStitchingSection(seed: 610, topTextOffset: 0);
  final middle = receiptStitchingSection(seed: 611, topTextOffset: 18);
  final bottom = receiptStitchingSection(seed: 612, topTextOffset: 36);
  copyReceiptStitchingOverlap(from: top, to: middle, pixels: 340);
  copyReceiptStitchingOverlap(from: middle, to: bottom, pixels: 340);

  final rotatedMiddle = rotateReceiptStitchingShot(middle, degrees: degrees);
  final topFile = await writeTempReceiptStitchingImage(top, '${prefix}_top');
  final middleFile = await writeTempReceiptStitchingImage(
    rotatedMiddle,
    '${prefix}_middle',
  );
  final bottomFile = await writeTempReceiptStitchingImage(
    bottom,
    '${prefix}_bottom',
  );
  final sourcePaths = [topFile.path, middleFile.path, bottomFile.path];

  final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
    paths: sourcePaths,
  );

  expect(result.requiresOcrSourceReviewBeforeAssistedRead, isTrue);
  if (result.didStitch) {
    expect(result.hasLowConfidenceAutomaticOverlap, isTrue);
    expect(result.assistedReadinessCode, 'stitched_overlap_review_required');
    expect(
      result.sourcePreservationCode,
      'original_sections_preserved_derived_stitched_ocr_artifact',
    );
  } else {
    expect(result.usedFallback, isTrue, reason: result.detailLabel);
    expect(result.ocrSourcePaths, sourcePaths);
    expect(
      result.sourcePreservationCode,
      'original_sections_preserved_ordered_ocr_sources',
    );
    expect(result.assistedReadinessCode, 'stitch_contract_review_required');
  }
}
