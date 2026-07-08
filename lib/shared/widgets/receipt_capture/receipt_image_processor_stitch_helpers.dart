part of 'receipt_image_processor.dart';

_ReceiptOverlapMatch _bestScaleTolerantVerticalOverlap({
  required img.Image previous,
  required img.Image next,
  required int targetWidth,
}) {
  const comparisonWidth = 620;
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
        confidence: (match.confidence - scalePenalty).clamp(0.0, 1.0),
        scaleCorrection: scale,
        sampleHeight: candidateImage.height,
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
          confidence: (match.confidence - scalePenalty - rotationPenalty).clamp(
            0.0,
            1.0,
          ),
          scaleCorrection: base.scaleCorrection,
          rotationCorrectionDegrees: rotationDegrees,
          sampleHeight: candidateImage.height,
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

_ReceiptOverlapMatch _materializeStitchCandidate({
  required _ReceiptStitchCandidate candidate,
  required int previousHeight,
  required img.Image next,
  required int targetWidth,
}) {
  final nextImage = _transformForStitchComparison(
    next,
    targetWidth: targetWidth,
    scale: candidate.scaleCorrection,
    rotationDegrees: candidate.rotationCorrectionDegrees,
  );
  final scaleY = nextImage.height / math.max(1, candidate.sampleHeight);
  final maxSafeOverlap = math.max(
    24,
    math.min(previousHeight, nextImage.height) - 1,
  );
  final fullPixels =
      (candidate.pixels * scaleY).round().clamp(
            24,
            math.min(maxSafeOverlap, 2400),
          )
          as int;
  final fullSkipPixels =
      (candidate.nextSkipPixels * scaleY).round().clamp(
            fullPixels,
            math.min(maxSafeOverlap, 2400),
          )
          as int;
  return _ReceiptOverlapMatch(
    pixels: fullPixels,
    nextSkipPixels: fullSkipPixels,
    confidence: candidate.confidence,
    nextImage: nextImage,
    scaleCorrection: candidate.scaleCorrection,
    rotationCorrectionDegrees: candidate.rotationCorrectionDegrees,
  );
}

img.Image _transformForStitchComparison(
  img.Image source, {
  required int targetWidth,
  required double scale,
  required double rotationDegrees,
}) {
  if ((scale - 1).abs() < .001 &&
      rotationDegrees.abs() < .001 &&
      source.width == targetWidth) {
    return source;
  }
  final scaledWidth = (targetWidth * scale).round().clamp(320, 3200);
  var transformed = img.copyResize(source, width: scaledWidth);
  if (rotationDegrees.abs() >= .001) {
    transformed = img.copyRotate(
      transformed,
      angle: rotationDegrees,
      interpolation: img.Interpolation.linear,
    );
  }
  return _centerFitToWidth(transformed, targetWidth);
}

img.Image _centerFitToWidth(img.Image source, int targetWidth) {
  if (source.width == targetWidth) return source;
  if (source.width > targetWidth) {
    final cropX = ((source.width - targetWidth) / 2).round();
    return img.copyCrop(
      source,
      x: cropX,
      y: 0,
      width: targetWidth,
      height: source.height,
    );
  }
  final canvas = img.Image(
    width: targetWidth,
    height: source.height,
    numChannels: 3,
  );
  img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
  final dstX = ((targetWidth - source.width) / 2).round();
  img.compositeImage(canvas, source, dstX: dstX, dstY: 0);
  return canvas;
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
  for (var pixels = minPixels; pixels <= maxPixels; pixels += 12) {
    for (final horizontalOffset in _stitchHorizontalOffsets(previous.width)) {
      for (final nextYOffset in _stitchNextTopOffsets(next.height, pixels)) {
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
  final refinedStart = (bestPixels - 18).clamp(minPixels, maxPixels);
  final refinedEnd = (bestPixels + 18).clamp(minPixels, maxPixels);
  for (var pixels = refinedStart; pixels <= refinedEnd; pixels += 3) {
    for (final horizontalOffset in _stitchHorizontalOffsets(previous.width)) {
      for (final nextYOffset in _stitchNextTopOffsets(next.height, pixels)) {
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
  );
  final offsetPenalty = _stitchHorizontalOffsetPenalty(
    width: previous.width,
    offset: bestHorizontalOffset,
  );
  final confidence =
      (visualConfidence * (.55 + (.45 * distinctiveness)) -
              horizontalDriftPenalty -
              offsetPenalty)
          .clamp(0.0, 1.0);
  return _ReceiptOverlapMatch(
    pixels: bestPixels,
    nextSkipPixels: bestPixels + bestNextYOffset,
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
  return [0, -unit, unit, -unit * 2, unit * 2];
}

List<int> _stitchNextTopOffsets(int height, int pixels) {
  final maxOffset = math.min(96, math.max(0, height - pixels - 24));
  if (maxOffset <= 0) return const [0];
  final offsets = <int>{0, 12, 24, 36, 48, 72, 96};
  return offsets.where((offset) => offset <= maxOffset).toList(growable: false);
}

double _stitchHorizontalOffsetPenalty({
  required int width,
  required int offset,
}) {
  final unit = math.max(12, (width * .035).round());
  final magnitude = offset.abs();
  if (magnitude < unit * 2.5) return 0;
  return .14;
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

double _overlapDifference({
  required img.Image previous,
  required img.Image next,
  required int pixels,
  int horizontalOffset = 0,
  int nextYOffset = 0,
}) {
  final sampleWidth = math.min(previous.width, next.width);
  final stepX = math.max(8, (sampleWidth / 64).round());
  final stepY = math.max(4, (pixels / 36).round());
  var lumaTotal = 0.0;
  var lumaSamples = 0;
  var rowProfileTotal = 0.0;
  var rowProfileSamples = 0;
  var columnProfileTotal = 0.0;
  var columnProfileSamples = 0;
  var previousWeightedX = 0.0;
  var nextWeightedX = 0.0;
  var previousInkTotal = 0;
  var nextInkTotal = 0;
  final previousStartY = previous.height - pixels;
  for (var y = 0; y < pixels; y += stepY) {
    var previousInk = 0;
    var nextInk = 0;
    var rowSamples = 0;
    for (var x = sampleWidth ~/ 10; x < sampleWidth * 9 ~/ 10; x += stepX) {
      final nextX = x + horizontalOffset;
      if (nextX < 0 || nextX >= sampleWidth) continue;
      final a = _luma(previous.getPixel(x, previousStartY + y));
      final b = _luma(next.getPixel(nextX, nextYOffset + y));
      lumaTotal += (a - b).abs();
      lumaSamples++;
      if (a < 160) previousInk++;
      if (b < 160) nextInk++;
      rowSamples++;
    }
    if (rowSamples > 0) {
      final previousRatio = previousInk / rowSamples;
      final nextRatio = nextInk / rowSamples;
      rowProfileTotal += (previousRatio - nextRatio).abs() * 74;
      rowProfileSamples++;
    }
  }
  for (var x = sampleWidth ~/ 12; x < sampleWidth * 11 ~/ 12; x += stepX) {
    final nextX = x + horizontalOffset;
    if (nextX < 0 || nextX >= sampleWidth) continue;
    var previousInk = 0;
    var nextInk = 0;
    var columnSamples = 0;
    for (var y = 0; y < pixels; y += stepY) {
      final a = _luma(previous.getPixel(x, previousStartY + y));
      final b = _luma(next.getPixel(nextX, nextYOffset + y));
      if (a < 170) {
        previousInk++;
        previousWeightedX += x;
        previousInkTotal++;
      }
      if (b < 170) {
        nextInk++;
        nextWeightedX += x;
        nextInkTotal++;
      }
      columnSamples++;
    }
    if (columnSamples > 0) {
      final previousRatio = previousInk / columnSamples;
      final nextRatio = nextInk / columnSamples;
      columnProfileTotal += (previousRatio - nextRatio).abs() * 96;
      columnProfileSamples++;
    }
  }
  if (lumaSamples == 0) return double.infinity;
  final lumaAverage = lumaTotal / lumaSamples;
  final rowProfileAverage = rowProfileSamples == 0
      ? double.infinity
      : rowProfileTotal / rowProfileSamples;
  final columnProfileAverage = columnProfileSamples == 0
      ? double.infinity
      : columnProfileTotal / columnProfileSamples;
  final centerPenalty = previousInkTotal == 0 || nextInkTotal == 0
      ? 0.0
      : ((previousWeightedX / previousInkTotal) -
                    (nextWeightedX / nextInkTotal))
                .abs() /
            sampleWidth *
            150;
  return (lumaAverage * .50) +
      (rowProfileAverage * .22) +
      (columnProfileAverage * .20) +
      (centerPenalty * .08);
}

double _overlapHorizontalDriftPenalty({
  required img.Image previous,
  required img.Image next,
  required int pixels,
}) {
  final sampleWidth = math.min(previous.width, next.width);
  final stepX = math.max(6, (sampleWidth / 100).round());
  final stepY = math.max(4, (pixels / 40).round());
  final previousStartY = previous.height - pixels;
  var previousWeightedX = 0.0;
  var nextWeightedX = 0.0;
  var previousInkTotal = 0;
  var nextInkTotal = 0;
  for (var y = 0; y < pixels; y += stepY) {
    for (var x = sampleWidth ~/ 14; x < sampleWidth * 13 ~/ 14; x += stepX) {
      final previousLuma = _luma(previous.getPixel(x, previousStartY + y));
      final nextLuma = _luma(next.getPixel(x, y));
      if (previousLuma < 170) {
        previousWeightedX += x;
        previousInkTotal++;
      }
      if (nextLuma < 170) {
        nextWeightedX += x;
        nextInkTotal++;
      }
    }
  }
  if (previousInkTotal < 12 || nextInkTotal < 12) return 0;
  final delta =
      ((previousWeightedX / previousInkTotal) - (nextWeightedX / nextInkTotal))
          .abs();
  final safeDrift = sampleWidth * .075;
  final unsafeDrift = sampleWidth * .16;
  if (delta <= safeDrift) return 0;
  return ((delta - safeDrift) / math.max(1, unsafeDrift - safeDrift) * .35)
      .clamp(0.0, .35);
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

double _receiptImageBandDifference(
  img.Image a,
  img.Image b, {
  required double startFraction,
  required double endFraction,
}) {
  final sampleWidth = math.min(a.width, b.width);
  final sampleHeight = math.min(a.height, b.height);
  final startY = (sampleHeight * startFraction).round();
  final endY = (sampleHeight * endFraction).round().clamp(
    startY + 1,
    sampleHeight,
  );
  var total = 0.0;
  var samples = 0;
  for (var y = startY; y < endY; y += 6) {
    for (var x = 8; x < sampleWidth - 8; x += 8) {
      total += (_luma(a.getPixel(x, y)) - _luma(b.getPixel(x, y))).abs();
      samples++;
    }
  }
  if (samples == 0) return double.infinity;
  return total / samples;
}
