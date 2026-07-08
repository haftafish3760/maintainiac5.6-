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
  return image;
}

img.Image blankDarkReceiptPhotoSection() {
  final image = img.Image(width: 900, height: 1500, numChannels: 3);
  img.fill(image, color: img.ColorRgb8(36, 38, 40));
  return image;
}

void copyReceiptStitchingOverlap({
  required img.Image from,
  required img.Image to,
  required int pixels,
}) {
  final overlap = img.copyCrop(
    from,
    x: 0,
    y: from.height - pixels,
    width: from.width,
    height: pixels,
  );
  img.compositeImage(to, overlap, dstX: 0, dstY: 0);
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
