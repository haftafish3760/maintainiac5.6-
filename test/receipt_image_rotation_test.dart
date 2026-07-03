import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_image_processor.dart';

import 'helpers/receipt_image_test_fixtures.dart';

void main() {
  test('receipt image processor creates straightened copies', () async {
    final dir = await Directory.systemTemp.createTemp('receipt_straighten_');
    addTearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    final source = File('${dir.path}/crooked_receipt.jpg');
    await source.writeAsBytes(
      img.encodeJpg(receiptLikeImage(), quality: 96),
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

  test(
    'receipt image processor rejects unreadable rotate source family',
    () async {
      final dir = await Directory.systemTemp.createTemp(
        'receipt_rotate_guard_',
      );
      addTearDown(() async {
        if (await dir.exists()) await dir.delete(recursive: true);
      });

      final missing = '${dir.path}/missing.jpg';
      final empty = File('${dir.path}/empty.jpg')..createSync();
      final corrupt = File('${dir.path}/corrupt.jpg')
        ..writeAsBytesSync([0, 1, 2, 3, 4, 5]);
      final wrongType = File('${dir.path}/not_an_image.txt')
        ..writeAsStringSync('receipt text without pixels');

      for (final sourcePath in [
        missing,
        empty.path,
        corrupt.path,
        wrongType.path,
      ]) {
        await expectLater(
          ReceiptImageProcessor.rotateFile(path: sourcePath, degrees: 90),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              'Image could not be decoded.',
            ),
          ),
        );
      }
    },
  );

  test('receipt image processor rejects unusable crop bounds', () async {
    final bytes = img.encodeJpg(receiptLikeImage(), quality: 96);

    for (final rects in [
      (display: Rect.zero, crop: const Rect.fromLTWH(0, 0, 120, 120)),
      (
        display: const Rect.fromLTWH(0, 0, 120, 120),
        crop: const Rect.fromLTWH(double.nan, 0, 80, 80),
      ),
      (
        display: const Rect.fromLTWH(0, 0, double.infinity, 120),
        crop: const Rect.fromLTWH(0, 0, 80, 80),
      ),
    ]) {
      await expectLater(
        ReceiptImageProcessor.cropFile(
          bytes: bytes,
          displayImageRect: rects.display,
          cropRect: rects.crop,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Crop bounds are not usable.',
          ),
        ),
      );
    }
  });
}
