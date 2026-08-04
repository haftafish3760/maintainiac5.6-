part of 'receipt_image_processor.dart';

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

bool _receiptImageSmallShiftDuplicateContentMatches(img.Image a, img.Image b) {
  final shortestHeight = math.min(a.height, b.height);
  if (shortestHeight < 160) return false;
  for (final fraction in const [.02, .025, .028, .03, .04, .05, .06]) {
    final shift = (shortestHeight * fraction).round();
    final commonHeight = shortestHeight - shift;
    if (commonHeight < 120) continue;
    final aTop = img.copyCrop(
      a,
      x: 0,
      y: 0,
      width: a.width,
      height: commonHeight,
    );
    final aBottom = img.copyCrop(
      a,
      x: 0,
      y: shift,
      width: a.width,
      height: commonHeight,
    );
    final bTop = img.copyCrop(
      b,
      x: 0,
      y: 0,
      width: b.width,
      height: commonHeight,
    );
    final bBottom = img.copyCrop(
      b,
      x: 0,
      y: shift,
      width: b.width,
      height: commonHeight,
    );
    if (_receiptImageImmediateDuplicateContentMatches(aTop, bBottom) ||
        _receiptImageImmediateDuplicateContentMatches(aBottom, bTop)) {
      return true;
    }
  }
  return false;
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
