bool hasExceptionalReceiptStitchContinuity({
  required double correlation,
  required int detailedBands,
  required int matchingBands,
}) {
  if (matchingBands != detailedBands) return false;
  return (detailedBands >= 4 && correlation >= .72) ||
      (detailedBands >= 3 && correlation >= .80);
}

bool isLargeReceiptOverlapTransformAmbiguous({
  required int overlapPixels,
  required int overlapReferenceHeight,
  required double scaleCorrection,
  required double rotationCorrectionDegrees,
  required double perspectiveCorrection,
  required double continuityCorrelation,
  required int continuityDetailedBands,
  required int continuityMatchingBands,
}) {
  final safeReferenceHeight = overlapReferenceHeight <= 0
      ? 1
      : overlapReferenceHeight;
  final overlapShare = overlapPixels / safeReferenceHeight;
  final exceptionalContinuity = hasExceptionalReceiptStitchContinuity(
    correlation: continuityCorrelation,
    detailedBands: continuityDetailedBands,
    matchingBands: continuityMatchingBands,
  );
  return overlapShare >= .40 &&
      !exceptionalContinuity &&
      ((scaleCorrection - 1).abs() >= .08 ||
          rotationCorrectionDegrees.abs() >= 2.0 ||
          perspectiveCorrection.abs() >= .05);
}
