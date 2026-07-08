part of 'receipt_image_processor.dart';

bool _receiptShiftedImageContentMatches(img.Image a, img.Image b) {
  final aspectA = a.width / math.max(1, a.height);
  final aspectB = b.width / math.max(1, b.height);
  if ((aspectA - aspectB).abs() > .03) return false;

  const sampleWidth = 96;
  final sampleA = img.copyResize(a, width: sampleWidth);
  final sampleB = img.copyResize(b, width: sampleWidth);
  final sampleHeight = math.min(sampleA.height, sampleB.height);
  if (sampleHeight < 96) return false;

  for (final offset in const [-10, -8, -6, -4, -2, 0, 2, 4, 6, 8, 10]) {
    if (_receiptImageOffsetContentMatches(
      sampleA: sampleA,
      sampleB: sampleB,
      sampleHeight: sampleHeight,
      offset: offset,
    )) {
      return true;
    }
  }
  return _receiptImageInkProfileMatches(sampleA, sampleB, sampleHeight);
}

bool _receiptImageOffsetContentMatches({
  required img.Image sampleA,
  required img.Image sampleB,
  required int sampleHeight,
  required int offset,
}) {
  var meanA = 0.0;
  var meanB = 0.0;
  var meanSamples = 0;
  for (var y = 8; y < sampleHeight - 8; y += 8) {
    for (var x = 12; x < 84; x += 8) {
      final xB = x + offset;
      if (xB < 8 || xB >= 88) continue;
      meanA += _luma(sampleA.getPixel(x, y));
      meanB += _luma(sampleB.getPixel(xB, y));
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
  var rowCount = 0;
  for (var y = 8; y < sampleHeight - 8; y += 8) {
    var inkA = 0;
    var inkB = 0;
    var rowSamples = 0;
    for (var x = 12; x < 84; x += 8) {
      final xB = x + offset;
      if (xB < 8 || xB >= 88) continue;
      final lumaA = _luma(sampleA.getPixel(x, y));
      final lumaB = _luma(sampleB.getPixel(xB, y));
      lumaTotal += (lumaA - lumaB).abs();
      normalizedLumaTotal += ((lumaA - meanA) - (lumaB - meanB)).abs();
      if (lumaA < 165) inkA++;
      if (lumaB < 165) inkB++;
      rowSamples++;
      samples++;
    }
    if (rowSamples > 0) {
      inkProfileTotal += (inkA - inkB).abs() / rowSamples;
      rowCount++;
    }
  }
  if (samples == 0 || rowCount == 0) return false;
  return lumaTotal / samples <= 48 &&
      normalizedLumaTotal / samples <= 30 &&
      inkProfileTotal / rowCount <= .14;
}

bool _receiptImageInkProfileMatches(
  img.Image sampleA,
  img.Image sampleB,
  int sampleHeight,
) {
  final rowA = <double>[];
  final rowB = <double>[];
  var meanA = 0.0;
  var meanB = 0.0;
  var meanSamples = 0;
  for (var y = 8; y < sampleHeight - 8; y += 6) {
    var inkA = 0;
    var inkB = 0;
    var rowSamples = 0;
    for (var x = 8; x < 88; x += 4) {
      final lumaA = _luma(sampleA.getPixel(x, y));
      final lumaB = _luma(sampleB.getPixel(x, y));
      meanA += lumaA;
      meanB += lumaB;
      meanSamples++;
      if (lumaA < 165) inkA++;
      if (lumaB < 165) inkB++;
      rowSamples++;
    }
    if (rowSamples > 0) {
      rowA.add(inkA / rowSamples);
      rowB.add(inkB / rowSamples);
    }
  }
  if (meanSamples == 0 || rowA.isEmpty || rowA.length != rowB.length) {
    return false;
  }
  meanA /= meanSamples;
  meanB /= meanSamples;
  if ((meanA - meanB).abs() > 32) return false;

  var rowDiff = 0.0;
  for (var index = 0; index < rowA.length; index++) {
    rowDiff += (rowA[index] - rowB[index]).abs();
  }
  rowDiff /= rowA.length;
  if (rowDiff > .16) return false;

  final columnsA = _receiptImageColumnInkProfile(sampleA, sampleHeight);
  final columnsB = _receiptImageColumnInkProfile(sampleB, sampleHeight);
  var bestColumnDiff = double.infinity;
  for (final offset in const [-8, -6, -4, -2, 0, 2, 4, 6, 8]) {
    bestColumnDiff = math.min(
      bestColumnDiff,
      _receiptImageColumnProfileDifference(columnsA, columnsB, offset),
    );
  }
  return bestColumnDiff <= .16;
}

List<double> _receiptImageColumnInkProfile(img.Image image, int sampleHeight) {
  final columns = <double>[];
  for (var x = 8; x < 88; x += 4) {
    var ink = 0;
    var samples = 0;
    for (var y = 8; y < sampleHeight - 8; y += 6) {
      if (_luma(image.getPixel(x, y)) < 165) ink++;
      samples++;
    }
    columns.add(samples == 0 ? 0 : ink / samples);
  }
  return columns;
}

double _receiptImageColumnProfileDifference(
  List<double> columnsA,
  List<double> columnsB,
  int offset,
) {
  final shift = (offset / 4).round();
  var total = 0.0;
  var samples = 0;
  for (var index = 0; index < columnsA.length; index++) {
    final bIndex = index + shift;
    if (bIndex < 0 || bIndex >= columnsB.length) continue;
    total += (columnsA[index] - columnsB[bIndex]).abs();
    samples++;
  }
  return samples == 0 ? double.infinity : total / samples;
}
