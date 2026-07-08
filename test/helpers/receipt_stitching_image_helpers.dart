import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

img.Image receiptStitchingSection({
  required int seed,
  required int topTextOffset,
}) {
  final image = img.Image(width: 900, height: 1500, numChannels: 3);
  img.fill(image, color: img.ColorRgb8(248, 248, 244));
  for (var y = 80 + topTextOffset; y < 1420; y += 54) {
    final lineWidth = 540 + ((y + seed * 31) % 260);
    final xStart = 72 + ((y + seed * 17) % 36);
    img.fillRect(
      image,
      x1: xStart,
      y1: y,
      x2: (xStart + lineWidth).clamp(0, image.width - 1),
      y2: y + 8,
      color: img.ColorRgb8(25, 25, 25),
    );
    if (y % 3 == 0) {
      img.fillRect(
        image,
        x1: 680,
        y1: y,
        x2: 815,
        y2: y + 8,
        color: img.ColorRgb8(25, 25, 25),
      );
    }
    for (var index = 0; index < 12; index++) {
      final x = 96 + ((index * 57 + y * 3 + seed * 41) % 680);
      final width = 10 + ((index * 11 + y + seed * 13) % 34);
      final height = 10 + ((index * 7 + seed) % 16);
      final shade = 20 + ((index * 19 + seed * 29 + y) % 70);
      img.fillRect(
        image,
        x1: x,
        y1: (y + 14 + (index % 4) * 8).clamp(0, image.height - 1),
        x2: (x + width).clamp(0, image.width - 1),
        y2: (y + 14 + (index % 4) * 8 + height).clamp(0, image.height - 1),
        color: img.ColorRgb8(shade, shade, shade),
      );
    }
  }
  _drawReceiptStitchingContinuityMarkers(image, seed: seed);
  return image;
}

void _drawReceiptStitchingContinuityMarkers(
  img.Image image, {
  required int seed,
}) {
  for (var index = 0; index < 14; index++) {
    final y = 170 + index * 86;
    final x = 64 + ((seed * 43 + index * 71) % 720);
    final height = 34 + ((seed + index * 13) % 44);
    final shade = 45 + ((seed * 7 + index * 19) % 80);
    img.fillRect(
      image,
      x1: x,
      y1: y.clamp(0, image.height - 1),
      x2: (x + 12).clamp(0, image.width - 1),
      y2: (y + height).clamp(0, image.height - 1),
      color: img.ColorRgb8(shade, shade, shade),
    );
  }
}

img.Image blankDarkReceiptPhotoSection() {
  final image = img.Image(width: 900, height: 1500, numChannels: 3);
  img.fill(image, color: img.ColorRgb8(36, 38, 40));
  return image;
}

img.Image receiptStitchingBoilerplateSection({
  required int seed,
  required String label,
}) {
  final image = receiptStitchingSection(seed: seed, topTextOffset: 0);
  final topBand = label.codeUnits.fold<int>(0, (sum, code) => sum + code) % 90;
  final yStart = image.height - 360;
  img.fillRect(
    image,
    x1: 42,
    y1: yStart,
    x2: image.width - 42,
    y2: image.height - 64,
    color: img.ColorRgb8(248, 248, 244),
  );
  for (var row = 0; row < 7; row++) {
    final y = yStart + 26 + row * 42;
    final indent = 90 + ((row * 31 + topBand) % 64);
    img.fillRect(
      image,
      x1: indent,
      y1: y,
      x2: image.width - indent,
      y2: y + 7,
      color: img.ColorRgb8(36, 36, 36),
    );
    if (row.isOdd) {
      img.fillRect(
        image,
        x1: 300,
        y1: y + 17,
        x2: 600,
        y2: y + 23,
        color: img.ColorRgb8(58, 58, 58),
      );
    }
  }
  return image;
}

void copyReceiptStitchingOverlap({
  required img.Image from,
  required img.Image to,
  required int pixels,
  int dstX = 0,
  int dstY = 0,
}) {
  final overlap = img.copyCrop(
    from,
    x: 0,
    y: from.height - pixels,
    width: from.width,
    height: pixels,
  );
  img.compositeImage(to, overlap, dstX: dstX, dstY: dstY);
}

img.Image scaleReceiptStitchingShot(img.Image source, {required double scale}) {
  final scaledWidth = (source.width * scale).round();
  final scaled = img.copyResize(source, width: scaledWidth);
  if (scaled.width > source.width) {
    final cropX = ((scaled.width - source.width) / 2).round();
    return img.copyCrop(
      scaled,
      x: cropX,
      y: 0,
      width: source.width,
      height: math.min(source.height, scaled.height),
    );
  }
  final canvas = img.Image(
    width: source.width,
    height: source.height,
    numChannels: 3,
  );
  img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
  img.compositeImage(
    canvas,
    scaled,
    dstX: ((source.width - scaled.width) / 2).round(),
    dstY: 0,
  );
  return canvas;
}

img.Image rotateReceiptStitchingShot(
  img.Image source, {
  required double degrees,
}) {
  final rotated = img.copyRotate(
    source,
    angle: degrees,
    interpolation: img.Interpolation.linear,
  );
  if (rotated.width >= source.width && rotated.height >= source.height) {
    return img.copyCrop(
      rotated,
      x: ((rotated.width - source.width) / 2).round(),
      y: ((rotated.height - source.height) / 2).round(),
      width: source.width,
      height: source.height,
    );
  }
  final canvas = img.Image(
    width: source.width,
    height: source.height,
    numChannels: 3,
  );
  img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
  img.compositeImage(
    canvas,
    rotated,
    dstX: ((source.width - rotated.width) / 2).round(),
    dstY: ((source.height - rotated.height) / 2).round(),
  );
  return canvas;
}

img.Image shiftReceiptStitchingShot(
  img.Image source, {
  required int dx,
  required int dy,
}) {
  final canvas = img.Image(
    width: source.width,
    height: source.height,
    numChannels: 3,
  );
  img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
  img.compositeImage(canvas, source, dstX: dx, dstY: dy);
  return canvas;
}

Future<File> writeTempReceiptStitchingImage(
  img.Image image,
  String name,
) async {
  return writeTempReceiptStitchingImageWithQuality(image, name, quality: 94);
}

Future<File> writeTempReceiptStitchingImageWithQuality(
  img.Image image,
  String name, {
  required int quality,
}) async {
  final file = File(
    '${Directory.systemTemp.path}/maintainiac_receipt_stitch_$name.jpg',
  );
  await file.writeAsBytes(
    img.encodeJpg(image, quality: quality.clamp(30, 100)),
    flush: true,
  );
  return file;
}

img.Image addReceiptStitchingWear(
  img.Image source, {
  required int seed,
  int wrinkleCount = 9,
  int smudgeCount = 5,
}) {
  final worn = img.copyResize(source, width: source.width);
  for (var index = 0; index < wrinkleCount; index++) {
    final x = 40 + ((seed * 37 + index * 113) % (worn.width - 80));
    final yStart = 20 + ((seed * 23 + index * 71) % 180);
    final shade = 188 + ((seed + index * 17) % 44);
    img.drawLine(
      worn,
      x1: x,
      y1: yStart,
      x2: (x + 24 + index * 3).clamp(0, worn.width - 1),
      y2: (worn.height - 40 - index * 19).clamp(0, worn.height - 1),
      color: img.ColorRgb8(shade, shade, shade),
      thickness: index.isEven ? 2 : 1,
    );
  }
  for (var index = 0; index < smudgeCount; index++) {
    final cx = 90 + ((seed * 53 + index * 149) % (worn.width - 180));
    final cy = 160 + ((seed * 47 + index * 127) % (worn.height - 320));
    final radius = 22 + ((seed + index * 11) % 34);
    final shade = 204 + ((seed + index * 13) % 28);
    img.fillCircle(
      worn,
      x: cx,
      y: cy,
      radius: radius,
      color: img.ColorRgba8(shade, shade, shade, 96),
    );
  }
  return worn;
}

img.Image adjustReceiptStitchingBrightness(
  img.Image source, {
  required int delta,
}) {
  final adjusted = img.copyResize(source, width: source.width);
  for (final pixel in adjusted) {
    pixel
      ..r = (pixel.r + delta).clamp(0, 255)
      ..g = (pixel.g + delta).clamp(0, 255)
      ..b = (pixel.b + delta).clamp(0, 255);
  }
  return adjusted;
}

img.Image fadeReceiptStitchingInk(img.Image source, {required double amount}) {
  final faded = img.copyResize(source, width: source.width);
  final safeAmount = amount.clamp(0.0, 1.0);
  for (final pixel in faded) {
    final luma = (pixel.r + pixel.g + pixel.b) / 3;
    if (luma < 210) {
      pixel
        ..r = (pixel.r + ((245 - pixel.r) * safeAmount)).clamp(0, 255)
        ..g = (pixel.g + ((245 - pixel.g) * safeAmount)).clamp(0, 255)
        ..b = (pixel.b + ((245 - pixel.b) * safeAmount)).clamp(0, 255);
    }
  }
  return faded;
}

img.Image blurReceiptStitchingShot(img.Image source, {required int radius}) {
  final safeRadius = radius.clamp(1, 12);
  final blurred = img.copyResize(source, width: source.width);
  for (var y = safeRadius; y < source.height - safeRadius; y++) {
    for (var x = safeRadius; x < source.width - safeRadius; x++) {
      var r = 0;
      var g = 0;
      var b = 0;
      var samples = 0;
      for (var dy = -safeRadius; dy <= safeRadius; dy++) {
        for (var dx = -safeRadius; dx <= safeRadius; dx++) {
          final pixel = source.getPixel(x + dx, y + dy);
          r += pixel.r.toInt();
          g += pixel.g.toInt();
          b += pixel.b.toInt();
          samples++;
        }
      }
      blurred.setPixelRgb(x, y, r ~/ samples, g ~/ samples, b ~/ samples);
    }
  }
  return blurred;
}

img.Image clipReceiptStitchingSide(
  img.Image source, {
  int left = 0,
  int right = 0,
}) {
  final safeLeft = left.clamp(0, source.width ~/ 3);
  final safeRight = right.clamp(0, source.width ~/ 3);
  final clippedWidth = (source.width - safeLeft - safeRight).clamp(
    source.width ~/ 3,
    source.width,
  );
  final clipped = img.copyCrop(
    source,
    x: safeLeft,
    y: 0,
    width: clippedWidth,
    height: source.height,
  );
  final canvas = img.Image(
    width: source.width,
    height: source.height,
    numChannels: 3,
  );
  img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
  img.compositeImage(canvas, clipped, dstX: safeLeft);
  return canvas;
}

img.Image clipReceiptStitchingVerticalEdge(
  img.Image source, {
  int top = 0,
  int bottom = 0,
}) {
  final safeTop = top.clamp(0, source.height ~/ 3);
  final safeBottom = bottom.clamp(0, source.height ~/ 3);
  final clippedHeight = (source.height - safeTop - safeBottom).clamp(
    source.height ~/ 3,
    source.height,
  );
  final clipped = img.copyCrop(
    source,
    x: 0,
    y: safeTop,
    width: source.width,
    height: clippedHeight,
  );
  final canvas = img.Image(
    width: source.width,
    height: source.height,
    numChannels: 3,
  );
  img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
  img.compositeImage(canvas, clipped, dstY: safeTop);
  return canvas;
}

img.Image tallReceiptStitchingCanvas({int sectionCount = 4}) {
  const sectionStride = 1120;
  final height = sectionStride * (sectionCount - 1) + 1500;
  final canvas = img.Image(width: 900, height: height, numChannels: 3);
  img.fill(canvas, color: img.ColorRgb8(248, 248, 244));
  for (var index = 0; index < sectionCount; index++) {
    final section = receiptStitchingSection(
      seed: 260 + index,
      topTextOffset: index * 11,
    );
    img.compositeImage(canvas, section, dstX: 0, dstY: index * sectionStride);
  }
  return addReceiptStitchingWear(canvas, seed: 440, wrinkleCount: 11);
}

img.Image cropReceiptStitchingPhoneWindow(
  img.Image tallReceipt, {
  required int y,
  int height = 1500,
}) {
  return img.copyCrop(
    tallReceipt,
    x: 0,
    y: y,
    width: tallReceipt.width,
    height: height,
  );
}
