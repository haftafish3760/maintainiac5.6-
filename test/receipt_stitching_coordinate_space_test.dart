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
        textEvidence: [
          ReceiptStitchTextEvidence(
            path: first.path,
            lines: const [
              'Independent hardware item 18.49',
              'Galvanized coupling 5.20',
              'Exterior screws 12.99',
            ],
          ),
          ReceiptStitchTextEvidence(
            path: next.path,
            lines: const [
              'Galvanized coupling 5.20',
              'Exterior screws 12.99',
              'Independent sealant 7.25',
            ],
          ),
        ],
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

  test(
    'maps delayed overlap and seam rows back into proof coordinates',
    () async {
      final firstSection = receiptStitchingSection(seed: 911, topTextOffset: 0);
      final nextSection = receiptStitchingSection(seed: 912, topTextOffset: 16);
      copyReceiptStitchingOverlap(
        from: firstSection,
        to: nextSection,
        pixels: 360,
        dstX: 54,
        dstY: 112,
      );
      final first = await writeTempReceiptStitchingImage(
        firstSection,
        'coordinate_delayed_first',
      );
      final next = await writeTempReceiptStitchingImage(
        nextSection,
        'coordinate_delayed_next',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, next.path],
        textEvidence: _overlapTextEvidence(first.path, next.path),
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      final pair = result.pairs.single;
      expect(
        pair.seamSkipPixels,
        greaterThan(400),
        reason:
            'The mapped seam must account for both the copied overlap and its leading continuation band.',
      );
      expect(
        pair.seamSkipPixels,
        pair.overlapPixels + pair.verticalOffsetPixels,
        reason:
            'The continuation seam must use full-proof rows, including the leading band before delayed overlap.',
      );
      expect(pair.selectedSeamCropPixels, greaterThan(0));
      expect(pair.selectedSeamCropPixels, lessThan(pair.seamSkipPixels));
      expect(result.stitchedHeight, greaterThan(0));
      final stitched = await _decode(result.stitchedPath!);
      expect(stitched.width, result.stitchedWidth);
      expect(stitched.height, result.stitchedHeight);
    },
    timeout: _timeout,
  );

  test('discarded capture-border OCR cannot guide a receipt join', () async {
    final firstSection = receiptStitchingSection(seed: 921, topTextOffset: 0);
    final nextSection = receiptStitchingSection(seed: 922, topTextOffset: 16);
    copyReceiptStitchingOverlap(
      from: firstSection,
      to: nextSection,
      pixels: 380,
      dstY: 36,
    );
    final first = await writeTempReceiptStitchingImage(
      _offCenterCapture(firstSection, receiptLeft: 190),
      'coordinate_border_ocr_first',
    );
    final next = await writeTempReceiptStitchingImage(
      _offCenterCapture(nextSection, receiptLeft: 190),
      'coordinate_border_ocr_next',
    );

    ReceiptStitchTextLineEvidence borderLine(String text, double top) {
      return ReceiptStitchTextLineEvidence(
        text: text,
        left: .005,
        top: top,
        right: .035,
        bottom: top + .025,
      );
    }

    final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
      paths: [first.path, next.path],
      textEvidence: [
        ReceiptStitchTextEvidence(
          path: first.path,
          lines: const [],
          positionedLines: [
            borderLine('Outside frame marker alpha 17.40', .78),
            borderLine('Outside frame marker beta 22.19', .84),
          ],
        ),
        ReceiptStitchTextEvidence(
          path: next.path,
          lines: const [],
          positionedLines: [
            borderLine('Outside frame marker alpha 17.40', .12),
            borderLine('Outside frame marker beta 22.19', .18),
          ],
        ),
      ],
    );

    expect(result.didStitch, isTrue, reason: result.detailLabel);
    expect(result.pairs.single.hasTextPositionEvidence, isFalse);
    expect(result.pairs.single.matchedTextLineCount, 0);
  }, timeout: _timeout);
}

List<ReceiptStitchTextEvidence> _overlapTextEvidence(
  String firstPath,
  String nextPath,
) {
  return [
    ReceiptStitchTextEvidence(
      path: firstPath,
      lines: const [
        'Independent hardware item 18.49',
        'Galvanized coupling 5.20',
        'Exterior screws 12.99',
      ],
    ),
    ReceiptStitchTextEvidence(
      path: nextPath,
      lines: const [
        'Galvanized coupling 5.20',
        'Exterior screws 12.99',
        'Independent sealant 7.25',
      ],
    ),
  ];
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
