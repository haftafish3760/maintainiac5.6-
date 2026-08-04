import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

import 'helpers/receipt_stitching_image_helpers.dart';

const _timeout = Timeout(Duration(minutes: 2));

void main() {
  test(
    'keeps off-center receipt matching in full proof coordinates',
    () async {
      final firstSection = receiptStitchingSection(seed: 901, topTextOffset: 0);
      final nextSection = receiptStitchingSection(seed: 902, topTextOffset: 16);
      copyReceiptStitchingOverlap(
        from: firstSection,
        to: nextSection,
        pixels: 380,
        dstY: 36,
      );
      final firstCapture = _offCenterCapture(firstSection, receiptLeft: 90);
      final nextCapture = _offCenterCapture(nextSection, receiptLeft: 210);
      final first = await writeTempReceiptStitchingImage(
        firstCapture,
        'coordinate_space_first',
      );
      final next = await writeTempReceiptStitchingImage(
        nextCapture,
        'coordinate_space_next',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, next.path],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.pairs.single.confidence, greaterThanOrEqualTo(.49));
      expect(
        result.pairs.single.horizontalOffsetPixels.abs(),
        greaterThanOrEqualTo(60),
        reason:
            'The 120px receipt movement must survive comparison preparation instead of being erased by a crop-and-stretch operation.',
      );
      expect(result.stitchedWidth, greaterThan(1080));
      final stitched = await _decode(result.stitchedPath!);
      expect(stitched.width, result.stitchedWidth);
      expect(stitched.height, result.stitchedHeight);
    },
    timeout: _timeout,
  );
}

img.Image _offCenterCapture(img.Image receipt, {required int receiptLeft}) {
  final canvas = img.Image(width: 1200, height: 1660, numChannels: 3);
  img.fill(canvas, color: img.ColorRgb8(28, 30, 32));
  final scaled = img.copyResize(receipt, width: 820, height: 1540);
  img.compositeImage(canvas, scaled, dstX: receiptLeft, dstY: 60);
  return canvas;
}

Future<img.Image> _decode(String path) async {
  final bytes = await File(path).readAsBytes();
  final decoded = img.decodeImage(bytes);
  expect(decoded, isNotNull);
  return decoded!;
}
