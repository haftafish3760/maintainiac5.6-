import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_stitch_acceptance.dart';

void main() {
  test('rejects a near-maximum overlap that needs unsupported zoom', () {
    expect(
      isLargeReceiptOverlapTransformAmbiguous(
        overlapPixels: 1376,
        overlapReferenceHeight: 3032,
        scaleCorrection: 1.12,
        rotationCorrectionDegrees: 0,
        perspectiveCorrection: 0,
        continuityCorrelation: .583289896,
        continuityDetailedBands: 7,
        continuityMatchingBands: 7,
      ),
      isTrue,
    );
  });

  test('allows a transformed overlap backed by exceptional continuity', () {
    expect(
      isLargeReceiptOverlapTransformAmbiguous(
        overlapPixels: 159,
        overlapReferenceHeight: 360,
        scaleCorrection: 1.18,
        rotationCorrectionDegrees: -.8,
        perspectiveCorrection: 0,
        continuityCorrelation: .8269922107,
        continuityDetailedBands: 3,
        continuityMatchingBands: 3,
      ),
      isFalse,
    );
  });

  test('does not reject ordinary overlap without a large transform', () {
    expect(
      isLargeReceiptOverlapTransformAmbiguous(
        overlapPixels: 1217,
        overlapReferenceHeight: 3032,
        scaleCorrection: 1.06,
        rotationCorrectionDegrees: 0,
        perspectiveCorrection: 0,
        continuityCorrelation: .318835413,
        continuityDetailedBands: 7,
        continuityMatchingBands: 4,
      ),
      isFalse,
    );
  });
}
