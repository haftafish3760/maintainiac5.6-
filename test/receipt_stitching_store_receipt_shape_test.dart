import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

import 'helpers/receipt_stitching_image_helpers.dart';

void main() {
  test(
    'stitches tall store receipt windows with header totals barcode and wear',
    () async {
      final receipt = _storeReceiptShape();
      final starts = <int>[0, 1200, 2400, 3600];
      final files = <File>[];
      for (var index = 0; index < starts.length; index++) {
        var window = cropReceiptStitchingPhoneWindow(
          receipt,
          y: starts[index],
          height: 1500,
        );
        window = shiftReceiptStitchingShot(
          adjustReceiptStitchingBrightness(
            window,
            delta: index.isEven ? -10 : 16,
          ),
          dx: index.isEven ? 18 : -22,
          dy: 0,
        );
        window = frameReceiptStitchingShotOnDarkSurface(
          window,
          left: index.isEven ? 70 : 92,
          top: index.isEven ? 48 : 60,
          right: index.isEven ? 96 : 74,
          bottom: index.isEven ? 72 : 84,
        );
        files.add(
          await writeTempReceiptStitchingImage(
            window,
            'store_receipt_shape_$index',
          ),
        );
      }

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: files.map((file) => file.path).toList(growable: false),
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.pairs, hasLength(3));
      expect(result.overlapPixels, hasLength(3));
      expect(result.overlapPixelTotal, greaterThan(850));
      expect(result.ocrSourcePaths, [result.stitchedPath]);
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
      expect(result.stitchedPixelCount, lessThan(16000000));

      final stitchedPath = result.stitchedPath;
      expect(stitchedPath, isNotNull);
      final decoded = img.decodeImage(await File(stitchedPath!).readAsBytes());
      expect(decoded, isNotNull);
      expect(decoded!.width, result.stitchedWidth);
      expect(decoded.height, result.stitchedHeight);
      expect(decoded.height, greaterThan(4200));
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

img.Image _storeReceiptShape() {
  final receipt = img.Image(width: 900, height: 5100, numChannels: 3);
  img.fill(receipt, color: img.ColorRgb8(248, 248, 244));
  _drawHeader(receipt);
  _drawItemRows(receipt, startY: 760, rowCount: 58);
  _drawTotals(receipt, y: 3860);
  _drawBarcode(receipt, y: 4300);
  _drawFooter(receipt, y: 4650);
  return addReceiptStitchingWear(
    fadeReceiptStitchingInk(receipt, amount: .17),
    seed: 903,
    wrinkleCount: 18,
    smudgeCount: 11,
  );
}

void _drawHeader(img.Image receipt) {
  img.fillRect(
    receipt,
    x1: 160,
    y1: 130,
    x2: 740,
    y2: 260,
    color: img.ColorRgb8(24, 24, 24),
  );
  for (var row = 0; row < 6; row++) {
    final y = 335 + row * 58;
    final indent = 180 + (row % 3) * 36;
    img.fillRect(
      receipt,
      x1: indent,
      y1: y,
      x2: receipt.width - indent,
      y2: y + 12,
      color: img.ColorRgb8(28, 28, 28),
    );
  }
}

void _drawItemRows(
  img.Image receipt, {
  required int startY,
  required int rowCount,
}) {
  for (var row = 0; row < rowCount; row++) {
    final y = startY + row * 50;
    final leftWidth = 380 + ((row * 47) % 210);
    img.fillRect(
      receipt,
      x1: 80,
      y1: y,
      x2: 80 + leftWidth,
      y2: y + 10,
      color: img.ColorRgb8(32, 32, 32),
    );
    if (row % 4 == 0) {
      img.fillRect(
        receipt,
        x1: 96,
        y1: y + 20,
        x2: 350,
        y2: y + 28,
        color: img.ColorRgb8(74, 74, 74),
      );
    }
    img.fillRect(
      receipt,
      x1: 655,
      y1: y,
      x2: 790,
      y2: y + 10,
      color: img.ColorRgb8(24, 24, 24),
    );
  }
}

void _drawTotals(img.Image receipt, {required int y}) {
  img.drawLine(
    receipt,
    x1: 80,
    y1: y - 48,
    x2: 815,
    y2: y - 48,
    color: img.ColorRgb8(34, 34, 34),
    thickness: 4,
  );
  for (var row = 0; row < 5; row++) {
    final rowY = y + row * 62;
    img.fillRect(
      receipt,
      x1: 360,
      y1: rowY,
      x2: 560,
      y2: rowY + 13,
      color: img.ColorRgb8(28, 28, 28),
    );
    img.fillRect(
      receipt,
      x1: 650,
      y1: rowY,
      x2: 790,
      y2: rowY + 13,
      color: img.ColorRgb8(22, 22, 22),
    );
  }
}

void _drawBarcode(img.Image receipt, {required int y}) {
  for (var index = 0; index < 74; index++) {
    final width = 2 + ((index * 17) % 5);
    final x = 95 + index * 9;
    img.fillRect(
      receipt,
      x1: x,
      y1: y,
      x2: x + width,
      y2: y + 230,
      color: img.ColorRgb8(20, 20, 20),
    );
  }
}

void _drawFooter(img.Image receipt, {required int y}) {
  for (var row = 0; row < 7; row++) {
    final rowY = y + row * 62;
    final indent = 120 + (row % 3) * 44;
    img.fillRect(
      receipt,
      x1: indent,
      y1: rowY,
      x2: receipt.width - indent,
      y2: rowY + 12,
      color: img.ColorRgb8(38, 38, 38),
    );
  }
}
