import 'dart:io';

import 'package:image/image.dart' as img;

Future<File> writeReceiptFixtureImage(
  Directory dir,
  String name,
  img.Image image,
) async {
  final file = File('${dir.path}/$name');
  await file.writeAsBytes(img.encodeJpg(image, quality: 96), flush: true);
  return file;
}

Set<String> tempReceiptArtifactPaths(String prefix) {
  final needle = 'maintaniac_receipt_${prefix}_';
  return Directory.systemTemp
      .listSync()
      .whereType<File>()
      .map((file) => file.path)
      .where((path) => path.contains(needle))
      .toSet();
}

img.Image receiptLikeImage() {
  final image = img.Image(width: 1200, height: 1800);
  img.fill(image, color: img.ColorRgb8(246, 245, 238));
  for (var y = 80; y < 1700; y += 44) {
    img.drawLine(
      image,
      x1: 70,
      y1: y,
      x2: 1120,
      y2: y + (y % 3),
      color: img.ColorRgb8(20, 20, 20),
      thickness: 2,
    );
    for (var x = 90; x < 1080; x += 46) {
      if ((x + y) % 5 == 0) continue;
      img.fillRect(
        image,
        x1: x,
        y1: y + 9,
        x2: x + 22,
        y2: y + 20,
        color: img.ColorRgb8(35 + ((x + y) % 50), 35, 35),
      );
    }
  }
  return image;
}

img.Image receiptOnCounterImage() {
  final image = img.Image(width: 1800, height: 2400);
  img.fill(image, color: img.ColorRgb8(76, 72, 68));
  final receipt = receiptLikeImage();
  img.compositeImage(image, receipt, dstX: 300, dstY: 280);
  return image;
}

img.Image tinyCornerReceiptLikeImage() {
  final image = img.Image(width: 1800, height: 2400);
  img.fill(image, color: img.ColorRgb8(64, 61, 58));
  final receipt = img.copyResize(receiptLikeImage(), width: 360);
  img.compositeImage(image, receipt, dstX: 60, dstY: 90);
  return image;
}

img.Image leftEdgeReceiptLikeImage() {
  final image = img.Image(width: 1800, height: 2400);
  img.fill(image, color: img.ColorRgb8(64, 61, 58));
  final receipt = img.copyResize(receiptLikeImage(), width: 760);
  img.compositeImage(image, receipt, dstX: 0, dstY: 320);
  return image;
}

img.Image darkReceiptLikeImage() {
  final image = receiptLikeImage();
  for (final pixel in image) {
    pixel
      ..r = (pixel.r * .18).round()
      ..g = (pixel.g * .18).round()
      ..b = (pixel.b * .18).round();
  }
  return image;
}

img.Image glareReceiptLikeImage() {
  final image = receiptLikeImage();
  img.fillRect(
    image,
    x1: 0,
    y1: 0,
    x2: image.width,
    y2: image.height,
    color: img.ColorRgb8(250, 250, 246),
  );
  for (var y = 120; y < 1680; y += 64) {
    img.drawLine(
      image,
      x1: 80,
      y1: y,
      x2: 1120,
      y2: y,
      color: img.ColorRgb8(248, 248, 248),
      thickness: 1,
    );
  }
  return image;
}

img.Image fadedReceiptLikeImage() {
  final image = receiptLikeImage();
  for (final pixel in image) {
    final luma = pixel.r * .299 + pixel.g * .587 + pixel.b * .114;
    final faded = (210 + (luma - 128) * .22).round().clamp(0, 255);
    pixel
      ..r = faded
      ..g = faded
      ..b = faded;
  }
  return image;
}

img.Image thermalReceiptLikeImage() {
  final image = receiptLikeImage();
  for (final pixel in image) {
    final luma = pixel.r * .299 + pixel.g * .587 + pixel.b * .114;
    final warm = (190 + (luma - 128) * .34).round().clamp(0, 255);
    pixel
      ..r = (warm + 18).clamp(0, 255)
      ..g = (warm + 6).clamp(0, 255)
      ..b = (warm - 12).clamp(0, 255);
  }
  return image;
}

img.Image shadowedReceiptLikeImage() {
  final image = receiptLikeImage();
  for (final pixel in image) {
    final vertical = pixel.y / image.height;
    final horizontal = pixel.x / image.width;
    final shadow = (.42 + vertical * .42 + horizontal * .18).clamp(.38, 1.05);
    pixel
      ..r = (pixel.r * shadow).round().clamp(0, 255)
      ..g = (pixel.g * shadow).round().clamp(0, 255)
      ..b = (pixel.b * shadow).round().clamp(0, 255);
  }
  return image;
}

img.Image blankReceiptImage() {
  final image = img.Image(width: 1200, height: 1800);
  img.fill(image, color: img.ColorRgb8(244, 244, 240));
  return image;
}
