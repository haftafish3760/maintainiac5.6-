part of 'receipt_image_processor.dart';

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

double _overlapFlatTexturePenalty({
  required img.Image previous,
  required img.Image next,
  required int pixels,
  required int horizontalOffset,
  required int nextYOffset,
}) {
  final sampleWidth = math.min(previous.width, next.width);
  final stepX = math.max(8, (sampleWidth / 72).round());
  final stepY = math.max(4, (pixels / 42).round());
  final previousStartY = previous.height - pixels;
  final previousRatios = <double>[];
  final nextRatios = <double>[];
  final nextLumas = <double>[];
  for (var y = 0; y < pixels; y += stepY) {
    var previousInk = 0;
    var nextInk = 0;
    var samples = 0;
    for (var x = sampleWidth ~/ 10; x < sampleWidth * 9 ~/ 10; x += stepX) {
      final nextX = x + horizontalOffset;
      if (nextX < 0 || nextX >= sampleWidth) continue;
      if (_luma(previous.getPixel(x, previousStartY + y)) < 170) {
        previousInk++;
      }
      final nextLuma = _luma(next.getPixel(nextX, nextYOffset + y));
      nextLumas.add(nextLuma);
      if (nextLuma < 170) {
        nextInk++;
      }
      samples++;
    }
    if (samples == 0) continue;
    previousRatios.add(previousInk / samples);
    nextRatios.add(nextInk / samples);
  }
  if (previousRatios.length < 6 || nextRatios.length < 6) return .35;
  final previousStats = _overlapInkProfileStats(previousRatios);
  final nextStats = _overlapInkProfileStats(nextRatios);
  final nextLumaStats = _overlapValueStats(nextLumas);
  final nextLooksFlatDark = nextStats.mean > .70 && nextStats.variance < .0018;
  final previousLooksReceiptLike = previousStats.variance > .004;
  if (nextLooksFlatDark && previousLooksReceiptLike) return .48;
  if (previousLooksReceiptLike && nextLumaStats.variance < 18) return .48;
  return 0;
}

({double mean, double variance}) _overlapInkProfileStats(List<double> values) {
  return _overlapValueStats(values);
}

({double mean, double variance}) _overlapValueStats(List<double> values) {
  final mean = values.reduce((a, b) => a + b) / values.length;
  var variance = 0.0;
  for (final value in values) {
    final delta = value - mean;
    variance += delta * delta;
  }
  return (mean: mean, variance: variance / values.length);
}

double _overlapHorizontalDriftPenalty({
  required img.Image previous,
  required img.Image next,
  required int pixels,
  int nextYOffset = 0,
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
      final nextLuma = _luma(next.getPixel(x, nextYOffset + y));
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
  return samples == 0 ? double.infinity : total / samples;
}
