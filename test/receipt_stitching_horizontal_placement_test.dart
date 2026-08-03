import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

import 'helpers/receipt_stitching_image_helpers.dart';

const _stitchingHeavyTimeout = Timeout(Duration(minutes: 2));

void main() {
  test('labels matched horizontal drift correction metadata', () {
    const pair = ReceiptStitchPairResult(
      pairIndex: 0,
      overlapPixels: 340,
      confidence: .82,
      horizontalOffsetPixels: 72,
    );

    expect(pair.diagnosticCode, 'drift_adjusted');
    expect(pair.summaryLabel, contains('shifted 72 px'));
    expect(pair.matchEvidenceLabel, contains('drift fix'));
    expect(pair.userCheckLabel, contains('sideways drift'));
  });

  test('labels delayed-overlap vertical correction metadata', () {
    const pair = ReceiptStitchPairResult(
      pairIndex: 0,
      overlapPixels: 330,
      confidence: .79,
      verticalOffsetPixels: 88,
    );

    expect(pair.diagnosticCode, 'delayed_overlap_adjusted');
    expect(pair.summaryLabel, contains('delayed 88px'));
    expect(pair.matchEvidenceLabel, contains('delayed overlap'));
    expect(pair.userCheckLabel, contains('delayed overlap'));
  });

  test(
    'keeps auto-cropped sideways continuation stitchable',
    () async {
      final sectionA = receiptStitchingSection(seed: 120, topTextOffset: 0);
      final sectionB = receiptStitchingSection(seed: 121, topTextOffset: 18);
      copyReceiptStitchingOverlap(
        from: sectionA,
        to: sectionB,
        pixels: 340,
        dstY: 36,
      );
      final shiftedSecond = shiftReceiptStitchingShot(sectionB, dx: 80, dy: 0);

      final first = await writeTempReceiptStitchingImage(
        sectionA,
        'horizontal_placement_a',
      );
      final second = await writeTempReceiptStitchingImage(
        shiftedSecond,
        'horizontal_placement_b',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
      expect(
        result.pairs.single.confidence,
        greaterThanOrEqualTo(.49),
        reason: _pairEvidence(result),
      );
      expect(result.requiresOcrSourceReviewBeforeAssistedRead, isTrue);
    },
    timeout: _stitchingHeavyTimeout,
  );
}

String _pairEvidence(ReceiptStitchResult result) => result.pairs
    .map(
      (pair) =>
          '${pair.summaryLabel}; continuity ${pair.continuityCorrelation.toStringAsFixed(3)} (${pair.continuityMatchingBands}/${pair.continuityDetailedBands})',
    )
    .join('; ');
