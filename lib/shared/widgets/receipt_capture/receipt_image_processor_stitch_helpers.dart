part of 'receipt_image_processor.dart';

_ReceiptOverlapMatch _bestScaleTolerantVerticalOverlap({
  required img.Image previous,
  required img.Image next,
  required int targetWidth,
}) {
  const comparisonWidth = 420;
  final sampleWidth = math.min(
    comparisonWidth,
    math.min(previous.width, next.width),
  );
  final previousSample = previous.width == sampleWidth
      ? previous
      : img.copyResize(previous, width: sampleWidth);
  final nextSample = next.width == sampleWidth
      ? next
      : img.copyResize(next, width: sampleWidth);
  final candidates = <_ReceiptStitchCandidate>[];
  for (final scale in const [1.0, .94, 1.06, .88, 1.12, .82, 1.18]) {
    final candidateImage = _transformForStitchComparison(
      nextSample,
      targetWidth: sampleWidth,
      scale: scale,
      rotationDegrees: 0,
    );
    final match = _bestVerticalOverlap(
      previous: previousSample,
      next: candidateImage,
    );
    final scalePenalty = (scale - 1).abs() * .16;
    candidates.add(
      _ReceiptStitchCandidate(
        pixels: match.pixels,
        nextSkipPixels: match.nextSkipPixels,
        nextXOffsetPixels: match.nextXOffsetPixels,
        confidence: (match.confidence - scalePenalty).clamp(0.0, 1.0),
        scaleCorrection: scale,
        sampleHeight: candidateImage.height,
        sampleWidth: candidateImage.width,
      ),
    );
  }
  candidates.sort((a, b) => b.confidence.compareTo(a.confidence));
  if (candidates.first.confidence >= .62) {
    return _materializeStitchCandidate(
      candidate: candidates.first,
      previousHeight: previous.height,
      next: next,
      targetWidth: targetWidth,
    );
  }

  final rotationCandidates = candidates.take(3).toList(growable: false);
  for (final base in rotationCandidates) {
    for (final rotationDegrees in const [-.8, .8, -1.4, 1.4]) {
      final candidateImage = _transformForStitchComparison(
        nextSample,
        targetWidth: sampleWidth,
        scale: base.scaleCorrection,
        rotationDegrees: rotationDegrees,
      );
      final match = _bestVerticalOverlap(
        previous: previousSample,
        next: candidateImage,
      );
      final scalePenalty = (base.scaleCorrection - 1).abs() * .16;
      final rotationPenalty = rotationDegrees.abs() * .025;
      candidates.add(
        _ReceiptStitchCandidate(
          pixels: match.pixels,
          nextSkipPixels: match.nextSkipPixels,
          nextXOffsetPixels: match.nextXOffsetPixels,
          confidence: (match.confidence - scalePenalty - rotationPenalty).clamp(
            0.0,
            1.0,
          ),
          scaleCorrection: base.scaleCorrection,
          rotationCorrectionDegrees: rotationDegrees,
          sampleHeight: candidateImage.height,
          sampleWidth: candidateImage.width,
        ),
      );
    }
  }
  candidates.sort((a, b) => b.confidence.compareTo(a.confidence));
  return _materializeStitchCandidate(
    candidate: candidates.first,
    previousHeight: previous.height,
    next: next,
    targetWidth: targetWidth,
  );
}

_ReceiptOverlapMatch _bestVerticalOverlap({
  required img.Image previous,
  required img.Image next,
}) {
  final maxOverlap = math.min(previous.height, next.height) * .46;
  final minOverlap = math.min(previous.height, next.height) * .08;
  final minPixels = minOverlap.round().clamp(48, 320);
  final maxPixels = maxOverlap.round().clamp(minPixels + 1, 1400);
  var bestPixels = 0;
  var bestScore = double.infinity;
  var secondBestScore = double.infinity;
  var bestHorizontalOffset = 0;
  var bestNextYOffset = 0;
  final horizontalOffsets = _stitchHorizontalOffsets(previous.width);
  for (var pixels = minPixels; pixels <= maxPixels; pixels += 24) {
    final nextTopOffsets = _stitchNextTopOffsets(next.height, pixels);
    for (final horizontalOffset in horizontalOffsets) {
      for (final nextYOffset in nextTopOffsets) {
        final score = _overlapDifference(
          previous: previous,
          next: next,
          pixels: pixels,
          horizontalOffset: horizontalOffset,
          nextYOffset: nextYOffset,
        );
        if (_stitchCandidateBeatsCurrent(
          score: score,
          pixels: pixels,
          bestScore: bestScore,
          bestPixels: bestPixels,
        )) {
          secondBestScore = bestScore;
          bestScore = score;
          bestPixels = pixels;
          bestHorizontalOffset = horizontalOffset;
          bestNextYOffset = nextYOffset;
        } else if ((pixels - bestPixels).abs() > 36 &&
            score < secondBestScore) {
          secondBestScore = score;
        }
      }
    }
  }
  final refinedStart = (bestPixels - 24).clamp(minPixels, maxPixels);
  final refinedEnd = (bestPixels + 24).clamp(minPixels, maxPixels);
  for (var pixels = refinedStart; pixels <= refinedEnd; pixels += 6) {
    final nextTopOffsets = _stitchNextTopOffsets(next.height, pixels);
    for (final horizontalOffset in horizontalOffsets) {
      for (final nextYOffset in nextTopOffsets) {
        final score = _overlapDifference(
          previous: previous,
          next: next,
          pixels: pixels,
          horizontalOffset: horizontalOffset,
          nextYOffset: nextYOffset,
        );
        if (_stitchCandidateBeatsCurrent(
          score: score,
          pixels: pixels,
          bestScore: bestScore,
          bestPixels: bestPixels,
        )) {
          secondBestScore = bestScore;
          bestScore = score;
          bestPixels = pixels;
          bestHorizontalOffset = horizontalOffset;
          bestNextYOffset = nextYOffset;
        } else if ((pixels - bestPixels).abs() > 36 &&
            score < secondBestScore) {
          secondBestScore = score;
        }
      }
    }
  }
  final visualConfidence = (1 - (bestScore / 64)).clamp(0.0, 1.0);
  final distinctiveness = secondBestScore.isFinite
      ? ((secondBestScore - bestScore) / 32).clamp(0.0, 1.0)
      : 1.0;
  final horizontalDriftPenalty = _overlapHorizontalDriftPenalty(
    previous: previous,
    next: next,
    pixels: bestPixels,
    horizontalOffset: bestHorizontalOffset,
    nextYOffset: bestNextYOffset,
  );
  final offsetPenalty = _stitchHorizontalOffsetPenalty(
    width: previous.width,
    offset: bestHorizontalOffset,
  );
  final texturePenalty = _overlapFlatTexturePenalty(
    previous: previous,
    next: next,
    pixels: bestPixels,
    horizontalOffset: bestHorizontalOffset,
    nextYOffset: bestNextYOffset,
  );
  final confidence =
      (visualConfidence * (.55 + (.45 * distinctiveness)) -
              horizontalDriftPenalty -
              offsetPenalty -
              texturePenalty)
          .clamp(0.0, 1.0);
  return _ReceiptOverlapMatch(
    pixels: bestPixels,
    nextSkipPixels: bestPixels + bestNextYOffset,
    nextXOffsetPixels: bestHorizontalOffset,
    nextTopOffsetPixels: bestNextYOffset,
    confidence: confidence,
    nextImage: next,
  );
}

bool _stitchCandidateBeatsCurrent({
  required double score,
  required int pixels,
  required double bestScore,
  required int bestPixels,
}) {
  if (score < bestScore) return true;
  if (!bestScore.isFinite) return true;
  final closeEnough = score <= bestScore + 1.75;
  final materiallyLonger = pixels >= bestPixels + 48;
  return closeEnough && materiallyLonger;
}

List<int> _stitchHorizontalOffsets(int width) {
  final unit = math.max(12, (width * .035).round());
  final offsets = <int>[0];
  for (final multiple in const [1, 2, 3]) {
    final offset = unit * multiple;
    offsets.addAll([-offset, offset]);
  }
  final maxOffset = math.max(unit * 2, (width * .14).round());
  offsets.addAll([-maxOffset, maxOffset]);
  return offsets
      .where((offset) => offset.abs() <= maxOffset)
      .toSet()
      .toList();
}

List<int> _stitchNextTopOffsets(int height, int pixels) {
  final maxOffset = math.min(
    320,
    math.max(0, math.min((height * .26).round(), height - pixels - 24)),
  );
  if (maxOffset <= 0) return const [0];
  final offsets = <int>{0, 12, 24, 36, 48, 72, 96, 132, 168, 220, 260, 320};
  return offsets.where((offset) => offset <= maxOffset).toList(growable: false);
}

int? _manualOverlapFor({
  required img.Image previous,
  required img.Image next,
  required int pairIndex,
  required List<int>? manualOverlapPixels,
  required List<double>? manualOverlapFractions,
}) {
  if (manualOverlapPixels != null && pairIndex < manualOverlapPixels.length) {
    final pixels = manualOverlapPixels[pairIndex];
    if (pixels <= 0) return null;
    return pixels;
  }
  if (manualOverlapFractions != null &&
      pairIndex < manualOverlapFractions.length) {
    final fraction = manualOverlapFractions[pairIndex];
    if (!fraction.isFinite) return -1;
    if (fraction <= 0) return null;
    final shortest = math.min(previous.height, next.height);
    return (shortest * fraction).round();
  }
  return null;
}

bool _receiptImageBytesMatch(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var index = 0; index < a.length; index++) {
    if (a[index] != b[index]) return false;
  }
  return true;
}

int _receiptImageAverageHashDistance(img.Image a, img.Image b) {
  return _receiptImageAverageHashHammingDistance(
    _receiptImageAverageHash(a),
    _receiptImageAverageHash(b),
  );
}

int _receiptImageAverageHashHammingDistance(
  List<bool> hashA,
  List<bool> hashB,
) {
  var distance = 0;
  final length = math.min(hashA.length, hashB.length);
  for (var index = 0; index < length; index++) {
    if (hashA[index] != hashB[index]) distance++;
  }
  return distance + (hashA.length - hashB.length).abs();
}

List<bool> _receiptImageAverageHash(img.Image source) {
  final sample = img.copyResize(source, width: 32, height: 32);
  final values = <double>[];
  var total = 0.0;
  for (var y = 0; y < sample.height; y++) {
    for (var x = 0; x < sample.width; x++) {
      final value = _luma(sample.getPixel(x, y));
      values.add(value);
      total += value;
    }
  }
  final mean = total / math.max(1, values.length);
  return [for (final value in values) value >= mean];
}

bool _receiptImageContentMatches(img.Image a, img.Image b) {
  return _receiptImageContentMatchScore(
    a,
    b,
    maxLumaAverage: 40,
    maxNormalizedLumaAverage: 20,
    maxInkProfileAverage: .12,
    maxBandDifference: 16,
  );
}

bool _receiptImageImmediateDuplicateContentMatches(img.Image a, img.Image b) {
  return _receiptImageContentMatchScore(
    a,
    b,
    maxLumaAverage: 32,
    maxNormalizedLumaAverage: 8,
    maxInkProfileAverage: .04,
    maxBandDifference: 32,
  );
}

bool _receiptImageContentMatchScore(
  img.Image a,
  img.Image b, {
  required double maxLumaAverage,
  required double maxNormalizedLumaAverage,
  required double maxInkProfileAverage,
  required double maxBandDifference,
}) {
  final aspectA = a.width / math.max(1, a.height);
  final aspectB = b.width / math.max(1, b.height);
  if ((aspectA - aspectB).abs() > .03) return false;

  const sampleWidth = 96;
  final sampleA = img.copyResize(a, width: sampleWidth);
  final sampleB = img.copyResize(b, width: sampleWidth);
  final sampleHeight = math.min(sampleA.height, sampleB.height);
  if (sampleHeight < 96) return false;

  var meanA = 0.0;
  var meanB = 0.0;
  var meanSamples = 0;
  for (var y = 8; y < sampleHeight - 8; y += 8) {
    for (var x = 8; x < sampleWidth - 8; x += 8) {
      meanA += _luma(sampleA.getPixel(x, y));
      meanB += _luma(sampleB.getPixel(x, y));
      meanSamples++;
    }
  }
  if (meanSamples == 0) return false;
  meanA /= meanSamples;
  meanB /= meanSamples;

  var lumaTotal = 0.0;
  var normalizedLumaTotal = 0.0;
  var inkProfileTotal = 0.0;
  var samples = 0;
  for (var y = 8; y < sampleHeight - 8; y += 8) {
    var inkA = 0;
    var inkB = 0;
    var rowSamples = 0;
    for (var x = 8; x < sampleWidth - 8; x += 8) {
      final lumaA = _luma(sampleA.getPixel(x, y));
      final lumaB = _luma(sampleB.getPixel(x, y));
      lumaTotal += (lumaA - lumaB).abs();
      normalizedLumaTotal += ((lumaA - meanA) - (lumaB - meanB)).abs();
      if (lumaA < 165) inkA++;
      if (lumaB < 165) inkB++;
      rowSamples++;
      samples++;
    }
    if (rowSamples > 0) {
      inkProfileTotal += (inkA - inkB).abs() / rowSamples;
    }
  }
  if (samples == 0) return false;
  final lumaAverage = lumaTotal / samples;
  final normalizedLumaAverage = normalizedLumaTotal / samples;
  final rowCount = (sampleHeight / 8).floor().clamp(1, 10000);
  final inkProfileAverage = inkProfileTotal / rowCount;
  final topBandDifference = _receiptImageBandDifference(
    sampleA,
    sampleB,
    startFraction: .05,
    endFraction: .22,
  );
  final bottomBandDifference = _receiptImageBandDifference(
    sampleA,
    sampleB,
    startFraction: .78,
    endFraction: .95,
  );
  return lumaAverage <= maxLumaAverage &&
      normalizedLumaAverage <= maxNormalizedLumaAverage &&
      inkProfileAverage <= maxInkProfileAverage &&
      topBandDifference <= maxBandDifference &&
      bottomBandDifference <= maxBandDifference;
}
