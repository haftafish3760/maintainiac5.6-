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
        textEvidence: _transformedPhoneWindowTextEvidence(files),
      );

      expect(result.didStitch, isTrue, reason: _stitchFailureDetails(result));
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

List<ReceiptStitchTextEvidence> _transformedPhoneWindowTextEvidence(
  List<File> files,
) {
  const angles = [0.0, .6, -.6, 0.0];
  const centers = [.50, .48, .52, .50];
  const widths = [.54, .56, .52, .54];
  final evidence = <ReceiptStitchTextEvidence>[];
  for (var index = 0; index < files.length; index++) {
    final lines = <ReceiptStitchTextLineEvidence>[];
    if (index > 0) {
      lines.addAll(
        _sharedTextBlock(
          pairIndex: index - 1,
          top: .07,
          center: centers[index],
          width: widths[index],
          angle: angles[index],
        ),
      );
    }
    if (index < files.length - 1) {
      lines.addAll(
        _sharedTextBlock(
          pairIndex: index,
          // The source windows advance 1120 rows through a 1500-row receipt,
          // so the genuine 380-row overlap begins near 75% of the prior
          // frame. Keep synthetic OCR anchors on that physical overlap; an
          // earlier anchor fabricates a much larger join than the pixels.
          top: .78,
          center: centers[index],
          width: widths[index],
          angle: angles[index],
        ),
      );
    }
    evidence.add(
      ReceiptStitchTextEvidence(
        path: files[index].path,
        lines: [for (final line in lines) line.text],
        positionedLines: lines,
      ),
    );
  }
  return evidence;
}

List<ReceiptStitchTextLineEvidence> _sharedTextBlock({
  required int pairIndex,
  required double top,
  required double center,
  required double width,
  required double angle,
}) {
  return [
    ReceiptStitchTextLineEvidence(
      text: 'Shared item $pairIndex copper elbow 2.49',
      left: center - width / 2,
      top: top,
      right: center + width / 2,
      bottom: top + .03,
      angleDegrees: angle,
    ),
    ReceiptStitchTextLineEvidence(
      text: 'Shared item $pairIndex exterior screws 12.40',
      left: center - width * .46,
      top: top + .065,
      right: center + width * .46,
      bottom: top + .095,
      angleDegrees: angle,
    ),
  ];
}

String _stitchFailureDetails(ReceiptStitchResult result) {
  final pairs = result.pairs
      .map(
        (pair) =>
            'pair=${pair.pairIndex} confidence=${pair.confidence} '
            'visual=${pair.visualConfidence} overlap=${pair.overlapPixels} '
            'x=${pair.horizontalOffsetPixels} y=${pair.verticalOffsetPixels} '
            'scale=${pair.scaleCorrection} '
            'rotation=${pair.rotationCorrectionDegrees} '
            'text=${pair.textOverlapConfidence} '
            '${pair.matchedTextLineCount} '
            'position=${pair.textPositionalConfidence} '
            '${pair.hasTextPositionEvidence} '
            'continuity=${pair.continuityCorrelation} '
            '${pair.continuityMatchingBands}/${pair.continuityDetailedBands} '
            'geometry=${pair.geometryCorrelation} '
            '${pair.geometryMatchingCells}/${pair.geometryDetailedCells}',
      )
      .join(' | ');
  return '${result.detailLabel}${pairs.isEmpty ? '' : ' $pairs'}';
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
