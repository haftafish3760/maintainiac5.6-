import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

String receiptStitchingResultReason(ReceiptStitchResult result) {
  final pairDetails = result.pairs
      .map((pair) {
        return '${pair.summaryLabel}; '
            'overlap=${pair.overlapPixels}; '
            'scale=${pair.scaleCorrection}; '
            'rotation=${pair.rotationCorrectionDegrees}; '
            'perspective=${pair.perspectiveCorrection}; '
            'x=${pair.horizontalOffsetPixels}; '
            'y=${pair.verticalOffsetPixels}; '
            'continuity=${pair.continuityCorrelation} '
            '(${pair.continuityMatchingBands}/${pair.continuityDetailedBands})';
      })
      .join('; ');
  return '${result.detailLabel}; $pairDetails';
}
