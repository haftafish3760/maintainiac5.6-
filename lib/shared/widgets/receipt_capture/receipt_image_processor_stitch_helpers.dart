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
  return _ReceiptOverlapMatch(
    pixels: fullPixels,
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
  for (var pixels = minPixels; pixels <= maxPixels; pixels += 12) {
    final score = _overlapDifference(
      previous: previous,
      next: next,
      pixels: pixels,
    );
    if (score < bestScore) {
      secondBestScore = bestScore;
      bestScore = score;
      bestPixels = pixels;
    } else if ((pixels - bestPixels).abs() > 36 && score < secondBestScore) {
      secondBestScore = score;
    }
  }
  final refinedStart = (bestPixels - 18).clamp(minPixels, maxPixels);
  final refinedEnd = (bestPixels + 18).clamp(minPixels, maxPixels);
  for (var pixels = refinedStart; pixels <= refinedEnd; pixels += 3) {
    final score = _overlapDifference(
      previous: previous,
      next: next,
      pixels: pixels,
    );
    if (score < bestScore) {
      secondBestScore = bestScore;
      bestScore = score;
      bestPixels = pixels;
    } else if ((pixels - bestPixels).abs() > 36 && score < secondBestScore) {
      secondBestScore = score;
    }
  }
  final visualConfidence = (1 - (bestScore / 64)).clamp(0.0, 1.0);
  final distinctiveness = secondBestScore.isFinite
      ? ((secondBestScore - bestScore) / 32).clamp(0.0, 1.0)
      : 1.0;
  final confidence = visualConfidence * (.55 + (.45 * distinctiveness));
  return _ReceiptOverlapMatch(
    pixels: bestPixels,
    confidence: confidence,
    nextImage: next,
  );
}

int? _manualOverlapFor({
  required img.Image previous,
  required img.Image next,
  required int pairIndex,
  required List<int>? manualOverlapPixels,
  required List<double>? manualOverlapFractions,
}) {
  if (manualOverlapPixels != null && pairIndex < manualOverlapPixels.length) {
    return manualOverlapPixels[pairIndex];
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
}) {
  final sampleWidth = math.min(previous.width, next.width);
  final stepX = math.max(8, (sampleWidth / 64).round());
  final stepY = math.max(4, (pixels / 36).round());
  var lumaTotal = 0.0;
  var lumaSamples = 0;
  var rowProfileTotal = 0.0;
  var rowProfileSamples = 0;
  final previousStartY = previous.height - pixels;
  for (var y = 0; y < pixels; y += stepY) {
    var previousInk = 0;
    var nextInk = 0;
    var rowSamples = 0;
    for (var x = sampleWidth ~/ 10; x < sampleWidth * 9 ~/ 10; x += stepX) {
      final a = _luma(previous.getPixel(x, previousStartY + y));
      final b = _luma(next.getPixel(x, y));
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
  if (lumaSamples == 0) return double.infinity;
  final lumaAverage = lumaTotal / lumaSamples;
  final rowProfileAverage = rowProfileSamples == 0
      ? double.infinity
      : rowProfileTotal / rowProfileSamples;
  return (lumaAverage * .62) + (rowProfileAverage * .38);
}
