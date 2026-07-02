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

Future<File> writeTempReceiptStitchingImage(
  img.Image image,
  String name,
) async {
  final file = File(
    '${Directory.systemTemp.path}/maintainiac_receipt_stitch_$name.jpg',
  );
  await file.writeAsBytes(img.encodeJpg(image, quality: 94), flush: true);
  return file;
}
