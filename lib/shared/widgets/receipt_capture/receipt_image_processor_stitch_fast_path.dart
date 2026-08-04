part of 'receipt_image_processor.dart';

bool _stitchMatchHasVisualCorroboration(
  img.Image previous,
  _ReceiptOverlapMatch match,
) {
  final continuity = _receiptOverlapContinuityEvidence(
    previous: previous,
    match: match,
  );
  return continuity.isProven ||
      (match.confidence >= .35 &&
          continuity.detailedBands >= 3 &&
          continuity.matchingBands >= 3 &&
          continuity.correlation >= .30) ||
      (match.confidence >= .44 &&
          continuity.detailedBands >= 2 &&
          continuity.matchingBands == continuity.detailedBands &&
          continuity.correlation >= .55);
}

_ReceiptOverlapMatch? _uprightReceiptOverlapFastPath({
  required img.Image previous,
  required img.Image next,
  required img.Image previousSample,
  required img.Image nextSample,
  required int targetWidth,
  required int sampleWidth,
}) {
  final baseMatch = _bestVerticalOverlap(
    previous: previousSample,
    next: nextSample,
  );
  final candidate = _ReceiptStitchCandidate(
    pixels: baseMatch.pixels,
    nextSkipPixels: baseMatch.nextSkipPixels,
    nextXOffsetPixels: baseMatch.nextXOffsetPixels,
    confidence: baseMatch.confidence,
    scaleCorrection: 1,
    sampleHeight: nextSample.height,
    sampleWidth: nextSample.width,
  );
  final sampleMatch = _materializeStitchCandidate(
    candidate: candidate,
    previousHeight: previousSample.height,
    next: nextSample,
    targetWidth: sampleWidth,
  );
  final continuity = _receiptOverlapContinuityEvidence(
    previous: previousSample,
    match: sampleMatch,
  );
  final continuityConfidence = continuity.isProven
      ? (.42 + continuity.correlation * .30).clamp(0.0, .72)
      : 0.0;
  if (!continuity.isProven ||
      math.max(candidate.confidence, continuityConfidence) < .49) {
    return null;
  }
  return _materializeStitchCandidate(
    candidate: candidate,
    previousHeight: previous.height,
    next: next,
    targetWidth: targetWidth,
  );
}
