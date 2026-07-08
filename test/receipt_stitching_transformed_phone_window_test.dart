import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

import 'helpers/receipt_stitching_image_helpers.dart';

void main() {
  test(
    'stitches transformed phone-window receipt sections with dark screen chrome',
    () async {
      final files = await _writeTransformedPhoneWindows(
        'transformed_phone_window',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [for (final file in files) file.path],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.pairs, hasLength(3));
      expect(result.overlapPixels, hasLength(3));
      expect(result.overlapPixelTotal, greaterThan(820));
      expect(
        result.pairs.map((pair) => pair.confidence),
        everyElement(greaterThanOrEqualTo(.50)),
      );
      expect(result.ocrSourcePaths, [result.stitchedPath]);
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
      expect(result.stitchedPixelCount, lessThan(16000000));

      final stitched = img.decodeImage(
        await File(result.stitchedPath!).readAsBytes(),
      );
      expect(stitched, isNotNull);
      expect(stitched!.width, result.stitchedWidth);
      expect(stitched.height, result.stitchedHeight);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

Future<List<File>> _writeTransformedPhoneWindows(String prefix) async {
  final tallReceipt = addReceiptStitchingWear(
    fadeReceiptStitchingInk(
      tallReceiptStitchingCanvas(sectionCount: 4),
      amount: .18,
    ),
    seed: 1190,
    wrinkleCount: 13,
    smudgeCount: 8,
  );
  final starts = <int>[0, 1120, 2240, 3360];
  final files = <File>[];
  for (var index = 0; index < starts.length; index++) {
    var receiptWindow = cropReceiptStitchingPhoneWindow(
      tallReceipt,
      y: starts[index],
      height: 1500,
    );
    receiptWindow = shiftReceiptStitchingShot(
      receiptWindow,
      dx: index.isEven ? 18 : -20,
      dy: 0,
    );
    if (index == 1) {
      receiptWindow = rotateReceiptStitchingShot(
        scaleReceiptStitchingShot(receiptWindow, scale: 1.04),
        degrees: .6,
      );
    }
    if (index == 2) {
      receiptWindow = rotateReceiptStitchingShot(
        scaleReceiptStitchingShot(receiptWindow, scale: .96),
        degrees: -.6,
      );
      receiptWindow = adjustReceiptStitchingBrightness(
        receiptWindow,
        delta: -18,
      );
    }
    if (index == 3) {
      receiptWindow = adjustReceiptStitchingBrightness(
        receiptWindow,
        delta: 22,
      );
    }

    final capture = _phoneScreenshotFrame(
      receiptWindow,
      left: index.isEven ? 72 : 58,
      top: index.isEven ? 76 : 88,
      bottomBarHeight: index.isEven ? 82 : 74,
    );
    files.add(
      await writeTempReceiptStitchingImage(capture, '${prefix}_$index'),
    );
  }
  return files;
}

img.Image _phoneScreenshotFrame(
  img.Image receiptWindow, {
  required int left,
  required int top,
  required int bottomBarHeight,
}) {
  final canvas = img.Image(width: 1080, height: 1760, numChannels: 3);
  img.fill(canvas, color: img.ColorRgb8(12, 12, 14));
  img.fillRect(
    canvas,
    x1: 0,
    y1: 0,
    x2: canvas.width,
    y2: 56,
    color: img.ColorRgb8(24, 24, 26),
  );
  img.fillRect(
    canvas,
    x1: 0,
    y1: canvas.height - bottomBarHeight,
    x2: canvas.width,
    y2: canvas.height,
    color: img.ColorRgb8(18, 18, 20),
  );
  img.compositeImage(canvas, receiptWindow, dstX: left, dstY: top);
  return canvas;
}
