part of 'receipt_image_processor.dart';

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
    perspectiveCorrection: candidate.perspectiveCorrection,
  );
  final scaleY = nextImage.height / math.max(1, candidate.sampleHeight);
  final scaleX = nextImage.width / math.max(1, candidate.sampleWidth);
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
  final maxTopOffset = math.max(0, nextImage.height - fullPixels - 24);
  final fullTopOffset =
      (math.max(0, candidate.nextSkipPixels - candidate.pixels) * scaleY)
          .round()
          .clamp(0, maxTopOffset);
  return _ReceiptOverlapMatch(
    pixels: fullPixels,
    // The match begins below the next image's top edge. Keep those leading
    // rows in the final proof and place the full image earlier by this offset;
    // cropping them here loses receipt content on delayed-overlap captures.
    nextSkipPixels: fullPixels + fullTopOffset,
    nextXOffsetPixels: (candidate.nextXOffsetPixels * scaleX).round(),
    nextTopOffsetPixels: fullTopOffset,
    confidence: candidate.confidence,
    nextImage: nextImage,
    scaleCorrection: candidate.scaleCorrection,
    rotationCorrectionDegrees: candidate.rotationCorrectionDegrees,
    perspectiveCorrection: candidate.perspectiveCorrection,
  );
}

img.Image _materializeRawStitchImage(
  img.Image source, {
  required _ReceiptOverlapMatch match,
  required int targetWidth,
}) {
  // A stitched image is proof and OCR input. Never silently crop a leading
  // band from it: a dark, faded, or shadowed receipt header can look like
  // background but still contain the only merchant or date evidence.
  final transformed = _transformForStitchComparison(
    source,
    targetWidth: targetWidth,
    scale: match.scaleCorrection,
    rotationDegrees: match.rotationCorrectionDegrees,
    perspectiveCorrection: match.perspectiveCorrection,
  );
  return transformed;
}

img.Image _stripVerifiedTopCaptureArtifact(img.Image source) {
  // This deliberately accepts an extremely narrow case: a sustained,
  // full-width, almost-black band flush with the top edge. That is a capture
  // artifact, not receipt content. Faded paper, shadows, dark logos, and
  // ordinary printed rules do not meet this threshold and are preserved.
  if (source.width < 48 || source.height < 80) return source;
  final maximumBandHeight = math.min(240, (source.height * .12).round());
  final minimumBandHeight = math.max(12, (source.height * .01).round());
  final stepX = math.max(4, (source.width / 72).round());
  var artifactRows = 0;
  for (var y = 0; y < maximumBandHeight; y += 2) {
    var samples = 0;
    var nearBlackSamples = 0;
    for (var x = source.width ~/ 20; x < source.width * 19 ~/ 20; x += stepX) {
      final pixel = source.getPixel(x, y);
      final luma = (pixel.r + pixel.g + pixel.b) / 3;
      samples++;
      if (luma <= 12) nearBlackSamples++;
    }
    if (samples == 0 || nearBlackSamples / samples < .98) break;
    artifactRows = y + 2;
  }
  if (artifactRows < minimumBandHeight || artifactRows >= source.height - 24) {
    return source;
  }
  return img.copyCrop(
    source,
    x: 0,
    y: artifactRows,
    width: source.width,
    height: source.height - artifactRows,
  );
}

img.Image _transformForStitchComparison(
  img.Image source, {
  required int targetWidth,
  required double scale,
  required double rotationDegrees,
  double perspectiveCorrection = 0,
}) {
  if ((scale - 1).abs() < .001 &&
      rotationDegrees.abs() < .001 &&
      perspectiveCorrection.abs() < .001 &&
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
  transformed = _centerFitToWidth(transformed, targetWidth);
  return _rectifyStitchPerspective(
    transformed,
    correction: perspectiveCorrection,
  );
}

img.Image _rectifyStitchPerspective(
  img.Image source, {
  required double correction,
}) {
  if (correction.abs() < .001 || source.width < 80 || source.height < 80) {
    return source;
  }
  final inset = (source.width * correction.abs()).round().clamp(
    1,
    source.width ~/ 8,
  );
  final topInset = correction > 0 ? inset : 0;
  final bottomInset = correction < 0 ? inset : 0;
  return img.copyRectify(
    source,
    topLeft: img.Point(topInset, 0),
    topRight: img.Point(source.width - 1 - topInset, 0),
    bottomLeft: img.Point(bottomInset, source.height - 1),
    bottomRight: img.Point(source.width - 1 - bottomInset, source.height - 1),
    interpolation: img.Interpolation.linear,
  );
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

int _selectReceiptStitchSeamCropY({
  required img.Image previous,
  required img.Image next,
  required int overlapPixels,
  required int nextTopOffset,
  required int horizontalOffset,
}) {
  if (overlapPixels < 24 || next.height < 48 || previous.height < 48) {
    return 0;
  }
  final safeTop = nextTopOffset.clamp(0, next.height - 1);
  final safeOverlap = math.min(
    overlapPixels,
    math.min(previous.height, next.height - safeTop),
  );
  if (safeOverlap < 24) return safeTop;
  final searchStart = safeTop + (safeOverlap * .30).round();
  final searchEnd = safeTop + (safeOverlap * .72).round();
  final bandRadius = math.max(4, (safeOverlap * .025).round());
  var bestY = safeTop + safeOverlap ~/ 2;
  var bestScore = double.infinity;
  final stepY = math.max(3, safeOverlap ~/ 48);
  for (
    var candidateY = searchStart;
    candidateY <= searchEnd;
    candidateY += stepY
  ) {
    final score = _receiptStitchSeamRowScore(
      previous: previous,
      next: next,
      previousY: previous.height - safeOverlap + (candidateY - safeTop),
      nextY: candidateY,
      horizontalOffset: horizontalOffset,
      bandRadius: bandRadius,
    );
    if (score < bestScore) {
      bestScore = score;
      bestY = candidateY;
    }
  }
  return bestY.clamp(1, next.height - 1);
}

double _receiptStitchSeamRowScore({
  required img.Image previous,
  required img.Image next,
  required int previousY,
  required int nextY,
  required int horizontalOffset,
  required int bandRadius,
}) {
  final sampleWidth = math.min(previous.width, next.width);
  final xStep = math.max(8, sampleWidth ~/ 72);
  final yStep = math.max(2, bandRadius ~/ 5);
  var difference = 0.0;
  var ink = 0.0;
  var samples = 0;
  for (var dy = -bandRadius; dy <= bandRadius; dy += yStep) {
    final previousSampleY = (previousY + dy).clamp(0, previous.height - 1);
    final nextSampleY = (nextY + dy).clamp(0, next.height - 1);
    for (var x = sampleWidth ~/ 10; x < sampleWidth * 9 ~/ 10; x += xStep) {
      final nextX = x + horizontalOffset;
      if (nextX < 0 || nextX >= next.width) continue;
      final a = _luma(previous.getPixel(x, previousSampleY));
      final b = _luma(next.getPixel(nextX, nextSampleY));
      difference += (a - b).abs();
      if (a < 175) ink += (175 - a) / 175;
      if (b < 175) ink += (175 - b) / 175;
      samples++;
    }
  }
  if (samples == 0) return double.infinity;
  // Prefer a visually agreeing, low-ink gap so the join does not cut through
  // printed receipt text, a barcode, or a handwritten annotation.
  return (difference / samples) + ((ink / samples) * 42);
}
