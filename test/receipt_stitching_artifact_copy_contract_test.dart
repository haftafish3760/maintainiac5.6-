import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

import 'helpers/receipt_stitching_image_helpers.dart';

void main() {
  test(
    'copies a verified stitch preview into a durable OCR artifact',
    () async {
      final source = await writeTempReceiptStitchingImage(
        receiptStitchingSection(seed: 22, topTextOffset: 0),
        'copy_source',
      );

      final copy = await ReceiptImageProcessor.copyReceiptOcrArtifact(
        path: source.path,
        prefix: 'copy_test',
      );

      expect(copy, isNot(source.path));
      expect(await File(copy).exists(), isTrue);
      expect(await File(copy).length(), await source.length());
      await File(copy).delete();
    },
  );
}
