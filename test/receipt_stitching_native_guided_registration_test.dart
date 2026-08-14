import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

import 'helpers/receipt_stitching_image_helpers.dart';

void main() {
  test(
    'native anchors propose overlap but geometry remains authoritative',
    () async {
      final top = receiptStitchingSection(seed: 510, topTextOffset: 0);
      final bottom = receiptStitchingSection(seed: 511, topTextOffset: 18);
      copyReceiptStitchingOverlap(from: top, to: bottom, pixels: 320);
      final topFile = await writeTempReceiptStitchingImage(top, 'native_top');
      final bottomFile = await writeTempReceiptStitchingImage(
        bottom,
        'native_bottom',
      );
      final anchors = <ReceiptNativeRegistrationAnchor>[
        for (var index = 0; index < 8; index++)
          ReceiptNativeRegistrationAnchor(
            previousX: .16 + index * .09,
            previousY: (1180 + index * 38) / 1500,
            nextX: .16 + index * .09,
            nextY: index * 38 / 1500,
          ),
      ];

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [topFile.path, bottomFile.path],
        nativeRegistrationProposals: [
          ReceiptNativeRegistrationProposal(
            pairIndex: 0,
            scale: 1,
            rotationDegrees: 0,
            confidence: .86,
            inlierCount: 8,
            reprojectionError: 1.1,
            anchors: anchors,
          ),
        ],
      );

      expect(result.didStitch, isTrue, reason: result.pairDiagnosticsLabel);
      expect(result.pairs.single.usedNativeRegistration, isTrue);
      expect(
        result.pairs.single.geometryMatchingCells,
        greaterThanOrEqualTo(5),
      );
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'native anchors remain aligned after private phone-frame cropping',
    () async {
      final top = receiptStitchingSection(seed: 610, topTextOffset: 0);
      final bottom = receiptStitchingSection(seed: 611, topTextOffset: 18);
      copyReceiptStitchingOverlap(from: top, to: bottom, pixels: 320);
      final framedTop = _darkPhoneFrame(top, left: 70, top: 80);
      final framedBottom = _darkPhoneFrame(bottom, left: 62, top: 88);
      final topFile = await writeTempReceiptStitchingImage(
        framedTop,
        'native_framed_top',
      );
      final bottomFile = await writeTempReceiptStitchingImage(
        framedBottom,
        'native_framed_bottom',
      );
      final anchors = <ReceiptNativeRegistrationAnchor>[
        for (var index = 0; index < 8; index++)
          ReceiptNativeRegistrationAnchor(
            previousX: (70 + 150 + index * 72) / 1080,
            previousY: (80 + 1180 + index * 38) / 1760,
            nextX: (62 + 150 + index * 72) / 1080,
            nextY: (88 + index * 38) / 1760,
          ),
      ];

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [topFile.path, bottomFile.path],
        nativeRegistrationProposals: [
          ReceiptNativeRegistrationProposal(
            pairIndex: 0,
            scale: 1,
            rotationDegrees: 0,
            confidence: .88,
            inlierCount: 8,
            reprojectionError: 1.0,
            anchors: anchors,
          ),
        ],
      );

      expect(result.didStitch, isTrue, reason: result.pairDiagnosticsLabel);
      expect(result.pairs.single.usedNativeRegistration, isTrue);
      expect(
        result.pairs.single.geometryMatchingCells,
        greaterThanOrEqualTo(5),
      );
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'private phone-frame crop rejects native anchors from discarded borders',
    () async {
      final top = receiptStitchingSection(seed: 710, topTextOffset: 0);
      final bottom = receiptStitchingSection(seed: 711, topTextOffset: 18);
      copyReceiptStitchingOverlap(from: top, to: bottom, pixels: 320);
      final topFile = await writeTempReceiptStitchingImage(
        _darkPhoneFrame(top, left: 70, top: 80),
        'native_border_top',
      );
      final bottomFile = await writeTempReceiptStitchingImage(
        _darkPhoneFrame(bottom, left: 62, top: 88),
        'native_border_bottom',
      );
      final borderAnchors = <ReceiptNativeRegistrationAnchor>[
        for (var index = 0; index < 8; index++)
          ReceiptNativeRegistrationAnchor(
            previousX: .1 + index * .1,
            previousY: .01,
            nextX: .1 + index * .1,
            nextY: .02,
          ),
      ];

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [topFile.path, bottomFile.path],
        nativeRegistrationProposals: [
          ReceiptNativeRegistrationProposal(
            pairIndex: 0,
            scale: 1,
            rotationDegrees: 0,
            confidence: .9,
            inlierCount: 8,
            reprojectionError: 1,
            anchors: borderAnchors,
          ),
        ],
      );

      expect(result.pairs, hasLength(1));
      expect(result.pairs.single.usedNativeRegistration, isFalse);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

img.Image _darkPhoneFrame(
  img.Image receipt, {
  required int left,
  required int top,
}) {
  final canvas = img.Image(width: 1080, height: 1760, numChannels: 3);
  img.fill(canvas, color: img.ColorRgb8(12, 12, 14));
  img.compositeImage(canvas, receipt, dstX: left, dstY: top);
  return canvas;
}
