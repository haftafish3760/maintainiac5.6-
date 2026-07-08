import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

void main(List<String> args) {
  if (args.length != 2) {
    stderr.writeln(
      'Usage: dart run tool/receipt_stitch_duplicate_probe.dart <a> <b>',
    );
    exitCode = 64;
    return;
  }
  final a = img.decodeImage(File(args[0]).readAsBytesSync());
  final b = img.decodeImage(File(args[1]).readAsBytesSync());
  if (a == null || b == null) {
    stderr.writeln('Could not decode one input image.');
    exitCode = 65;
    return;
  }
  const sampleWidth = 96;
  final sampleA = img.copyResize(a, width: sampleWidth);
  final sampleB = img.copyResize(b, width: sampleWidth);
  final sampleHeight = math.min(sampleA.height, sampleB.height);
  var meanA = 0.0;
  var meanB = 0.0;
  var samples = 0;
  for (var y = 8; y < sampleHeight - 8; y += 8) {
    for (var x = 8; x < sampleWidth - 8; x += 8) {
      meanA += _luma(sampleA.getPixel(x, y));
      meanB += _luma(sampleB.getPixel(x, y));
      samples++;
    }
  }
  meanA /= math.max(1, samples);
  meanB /= math.max(1, samples);

  var lumaTotal = 0.0;
  var normalizedTotal = 0.0;
  var inkProfileTotal = 0.0;
  var rowCount = 0;
  for (var y = 8; y < sampleHeight - 8; y += 8) {
    var inkA = 0;
    var inkB = 0;
    var rowSamples = 0;
    for (var x = 8; x < sampleWidth - 8; x += 8) {
      final lumaA = _luma(sampleA.getPixel(x, y));
      final lumaB = _luma(sampleB.getPixel(x, y));
      lumaTotal += (lumaA - lumaB).abs();
      normalizedTotal += ((lumaA - meanA) - (lumaB - meanB)).abs();
      if (lumaA < 165) inkA++;
      if (lumaB < 165) inkB++;
      rowSamples++;
    }
    inkProfileTotal += (inkA - inkB).abs() / math.max(1, rowSamples);
    rowCount++;
  }
  stdout.writeln({
    'sampleHeight': sampleHeight,
    'samples': samples,
    'meanA': meanA,
    'meanB': meanB,
    'lumaAverage': lumaTotal / math.max(1, samples),
    'normalizedAverage': normalizedTotal / math.max(1, samples),
    'inkProfileAverage': inkProfileTotal / math.max(1, rowCount),
    'topBandDifference': _bandDifference(
      sampleA,
      sampleB,
      startFraction: .05,
      endFraction: .22,
    ),
    'bottomBandDifference': _bandDifference(
      sampleA,
      sampleB,
      startFraction: .78,
      endFraction: .95,
    ),
    'averageHashDistance': _averageHashDistance(a, b),
  });
}

double _luma(img.Pixel pixel) =>
    (pixel.r * .299) + (pixel.g * .587) + (pixel.b * .114);

double _bandDifference(
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
  return total / math.max(1, samples);
}

int _averageHashDistance(img.Image a, img.Image b) {
  final hashA = _averageHash(a);
  final hashB = _averageHash(b);
  var distance = 0;
  for (var index = 0; index < hashA.length; index++) {
    if (hashA[index] != hashB[index]) distance++;
  }
  return distance;
}

List<bool> _averageHash(img.Image source) {
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
