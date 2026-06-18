import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_image_processor.dart';

void main() {
  test('receipt data saver levels are user-facing levels 1 through 5', () {
    expect(ReceiptDataSaverLevel.values.map((level) => level.label), [
      'Level 1',
      'Level 2',
      'Level 3',
      'Level 4',
      'Level 5',
    ]);
    expect(ReceiptDataSaverLevel.original.usesGrayscale, isFalse);
    expect(ReceiptDataSaverLevel.light.usesGrayscale, isFalse);
    expect(ReceiptDataSaverLevel.balanced.usesGrayscale, isTrue);
    expect(ReceiptDataSaverLevel.strong.usesGrayscale, isTrue);
    expect(ReceiptDataSaverLevel.maximum.usesGrayscale, isTrue);
  });

  test(
    'receipt data saver creates progressively smaller receipt copies',
    () async {
      final dir = await Directory.systemTemp.createTemp('receipt_data_saver_');
      addTearDown(() async {
        if (await dir.exists()) await dir.delete(recursive: true);
      });

      final source = File('${dir.path}/receipt.jpg');
      await source.writeAsBytes(
        img.encodeJpg(_receiptLikeImage(), quality: 96),
        flush: true,
      );
      final originalBytes = await source.length();

      final balanced = await ReceiptImageProcessor.optimizeFile(
        path: source.path,
        level: ReceiptDataSaverLevel.balanced,
      );
      final maximum = await ReceiptImageProcessor.optimizeFile(
        path: source.path,
        level: ReceiptDataSaverLevel.maximum,
      );

      expect(balanced, isNot(source.path));
      expect(maximum, isNot(source.path));
      expect(await File(balanced).length(), lessThan(originalBytes));
      expect(
        await File(maximum).length(),
        lessThan(await File(balanced).length()),
      );

      final preview = await ReceiptImageProcessor.previewFile(
        path: source.path,
        level: ReceiptDataSaverLevel.maximum,
      );
      expect(preview.level, ReceiptDataSaverLevel.maximum);
      expect(preview.estimatedBytes, lessThan(originalBytes));
    },
  );

  test('receipt image processor creates straightened copies', () async {
    final dir = await Directory.systemTemp.createTemp('receipt_straighten_');
    addTearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    final source = File('${dir.path}/crooked_receipt.jpg');
    await source.writeAsBytes(
      img.encodeJpg(_receiptLikeImage(), quality: 96),
      flush: true,
    );

    final straightened = await ReceiptImageProcessor.rotateFile(
      path: source.path,
      degrees: 1.5,
    );
    final rotated = await ReceiptImageProcessor.rotateFile(
      path: source.path,
      degrees: 90,
    );

    expect(straightened, isNot(source.path));
    expect(rotated, isNot(source.path));
    expect(File(straightened).existsSync(), isTrue);
    expect(File(rotated).existsSync(), isTrue);
    final rotatedImage = img.decodeImage(await File(rotated).readAsBytes());
    expect(rotatedImage, isNotNull);
    expect(rotatedImage!.width, 1800);
    expect(rotatedImage.height, 1200);
  });
}

img.Image _receiptLikeImage() {
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
