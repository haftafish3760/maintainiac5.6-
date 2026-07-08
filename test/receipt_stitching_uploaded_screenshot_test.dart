import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

import 'helpers/receipt_stitching_image_helpers.dart';

const _uploadedScreenshotTimeout = Timeout(Duration(minutes: 2));

void main() {
  test(
    'stitches uploaded long-receipt screenshots with app chrome margins',
    () async {
      final files = await _writeUploadedScreenshotStack(
        'uploaded_email_screenshot',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [for (final file in files) file.path],
      );
      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.pairs, hasLength(3));
      expect(result.overlapPixels, hasLength(3));
      expect(
        result.pairs.map((pair) => pair.confidence),
        everyElement(greaterThanOrEqualTo(.50)),
      );
      expect(result.overlapPixelTotal, greaterThan(900));
      expect(result.ocrSourcePaths, [result.stitchedPath]);
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
      expect(result.stitchedPixelCount, lessThan(16000000));
    },
    timeout: _uploadedScreenshotTimeout,
  );

  test(
    'stitches uploaded dark-mode screenshots around a long receipt',
    () async {
      final files = await _writeUploadedDarkModeScreenshotStack(
        'uploaded_dark_mode_screenshot',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [for (final file in files) file.path],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.pairs, hasLength(3));
      expect(result.overlapPixels, hasLength(3));
      expect(
        result.pairs.map((pair) => pair.confidence),
        everyElement(greaterThanOrEqualTo(.50)),
      );
      expect(result.overlapPixelTotal, greaterThan(850));
      expect(result.ocrSourcePaths, [result.stitchedPath]);
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
      expect(result.stitchedPixelCount, lessThan(16000000));
    },
    timeout: _uploadedScreenshotTimeout,
  );
}

Future<List<File>> _writeUploadedScreenshotStack(String prefix) async {
  final tallReceipt = tallReceiptStitchingCanvas(sectionCount: 4);
  final starts = <int>[0, 1090, 2180, 3270];
  final files = <File>[];
  for (var index = 0; index < starts.length; index++) {
    var receiptWindow = cropReceiptStitchingPhoneWindow(
      tallReceipt,
      y: starts[index],
      height: 1500,
    );
    receiptWindow = shiftReceiptStitchingShot(
      receiptWindow,
      dx: index.isEven ? 12 : -16,
      dy: 0,
    );
    if (index == 1) {
      receiptWindow = adjustReceiptStitchingBrightness(
        receiptWindow,
        delta: 14,
      );
    }
    if (index == 2) {
      receiptWindow = fadeReceiptStitchingInk(receiptWindow, amount: .12);
    }
    files.add(
      await writeTempReceiptStitchingImage(
        _wrapUploadedScreenshot(
          receiptWindow,
          left: index.isEven ? 86 : 72,
          top: index.isEven ? 118 : 96,
        ),
        '${prefix}_$index',
      ),
    );
  }
  return files;
}

Future<List<File>> _writeUploadedDarkModeScreenshotStack(String prefix) async {
  final tallReceipt = tallReceiptStitchingCanvas(sectionCount: 4);
  final starts = <int>[0, 1090, 2180, 3270];
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
    if (index == 1 || index == 3) {
      receiptWindow = adjustReceiptStitchingBrightness(
        receiptWindow,
        delta: index == 1 ? 18 : -16,
      );
    }
    files.add(
      await writeTempReceiptStitchingImage(
        _wrapUploadedDarkModeScreenshot(
          receiptWindow,
          left: index.isEven ? 116 : 88,
          top: index.isEven ? 132 : 108,
        ),
        '${prefix}_$index',
      ),
    );
  }
  return files;
}

img.Image _wrapUploadedScreenshot(
  img.Image receiptWindow, {
  required int left,
  required int top,
}) {
  final canvas = img.Image(width: 1080, height: 1840, numChannels: 3);
  img.fill(canvas, color: img.ColorRgb8(246, 246, 242));
  img.fillRect(
    canvas,
    x1: 0,
    y1: 0,
    x2: canvas.width,
    y2: 74,
    color: img.ColorRgb8(232, 232, 230),
  );
  img.fillRect(
    canvas,
    x1: 0,
    y1: canvas.height - 92,
    x2: canvas.width,
    y2: canvas.height,
    color: img.ColorRgb8(238, 238, 236),
  );
  img.compositeImage(canvas, receiptWindow, dstX: left, dstY: top);
  return canvas;
}

img.Image _wrapUploadedDarkModeScreenshot(
  img.Image receiptWindow, {
  required int left,
  required int top,
}) {
  final canvas = img.Image(width: 1080, height: 1840, numChannels: 3);
  img.fill(canvas, color: img.ColorRgb8(18, 18, 20));
  img.fillRect(
    canvas,
    x1: 0,
    y1: 0,
    x2: canvas.width,
    y2: 86,
    color: img.ColorRgb8(34, 34, 36),
  );
  img.fillRect(
    canvas,
    x1: 0,
    y1: canvas.height - 104,
    x2: canvas.width,
    y2: canvas.height,
    color: img.ColorRgb8(30, 30, 32),
  );
  img.fillRect(
    canvas,
    x1: left - 10,
    y1: top - 10,
    x2: left + receiptWindow.width + 10,
    y2: top + receiptWindow.height + 10,
    color: img.ColorRgb8(48, 48, 50),
  );
  img.compositeImage(canvas, receiptWindow, dstX: left, dstY: top);
  return canvas;
}
