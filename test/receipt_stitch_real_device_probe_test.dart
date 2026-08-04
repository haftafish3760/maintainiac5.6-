import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

/// An opt-in diagnostic harness for a real, caller-supplied receipt-photo set.
///
/// It deliberately keeps device images out of source control. Set
/// `MAINTAINIAC_RECEIPT_STITCH_PATHS` to paths separated by `|` when running
/// this test. The harness exercises the production stitcher and prints only
/// stitch metadata, never receipt text.
void main() {
  final paths = (Platform.environment['MAINTAINIAC_RECEIPT_STITCH_PATHS'] ?? '')
      .split('|')
      .where((path) => path.trim().isNotEmpty)
      .toList(growable: false);
  final maxTargetWidth = int.tryParse(
    Platform.environment['MAINTAINIAC_RECEIPT_STITCH_MAX_TARGET_WIDTH'] ?? '',
  );
  final comparisonWidth = int.tryParse(
    Platform.environment['MAINTAINIAC_RECEIPT_STITCH_COMPARISON_WIDTH'] ?? '',
  );
  final retryComparisonWidth = int.tryParse(
    Platform.environment['MAINTAINIAC_RECEIPT_STITCH_RETRY_WIDTH'] ?? '',
  );
  final expectedOutcome =
      Platform.environment['MAINTAINIAC_RECEIPT_STITCH_EXPECT'] ?? 'stitched';

  test(
    'reports production stitch metadata for supplied device photos',
    () async {
      expect(paths, hasLength(greaterThanOrEqualTo(2)));
      for (final path in paths) {
        expect(await File(path).exists(), isTrue, reason: 'Missing: $path');
      }
      final sourceBytes = await File(paths.first).readAsBytes();
      final source = img.decodeImage(sourceBytes);
      expect(source, isNotNull);
      final baked = img.bakeOrientation(source!);
      final rotated = img.copyRotate(baked, angle: .8);
      // ignore: avoid_print
      print(
        jsonEncode({
          'sourceSize': [source.width, source.height],
          'sourceRange': _sampledLumaRange(source),
          'bakedSize': [baked.width, baked.height],
          'bakedRange': _sampledLumaRange(baked),
          'rotatedRange': _sampledLumaRange(rotated),
        }),
      );

      final stopwatch = Stopwatch()..start();
      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: paths,
        maxTargetWidth: maxTargetWidth ?? 1400,
        comparisonWidth: comparisonWidth ?? 400,
        retryComparisonWidth: retryComparisonWidth ?? 320,
      );
      stopwatch.stop();
      // ignore: avoid_print
      print(
        jsonEncode({
          'status': result.status.name,
          'elapsedMs': stopwatch.elapsedMilliseconds,
          'maxTargetWidth': maxTargetWidth ?? 1400,
          'comparisonWidth': comparisonWidth ?? 400,
          'retryComparisonWidth': retryComparisonWidth ?? 320,
          'didStitch': result.didStitch,
          'fallbackReason': result.fallbackReasonCode,
          'confidence': result.confidence,
          'failedPair': result.failedPairIndex,
          'overlapPixels': result.overlapPixels,
          'stitchedPath': result.stitchedPath,
          'stitchedSize': [result.stitchedWidth, result.stitchedHeight],
          'pairs': [
            for (final pair in result.pairs)
              {
                'pair': pair.pairIndex + 1,
                'confidence': pair.confidence,
                'overlapPixels': pair.overlapPixels,
                'scale': pair.scaleCorrection,
                'rotation': pair.rotationCorrectionDegrees,
                'horizontalOffset': pair.horizontalOffsetPixels,
                'verticalOffset': pair.verticalOffsetPixels,
              },
          ],
        }),
      );
      if (expectedOutcome == 'stitched') {
        expect(result.didStitch, isTrue);
      } else if (expectedOutcome == 'fallback') {
        expect(result.usedFallback, isTrue);
      }
      final stitchedPath = result.stitchedPath;
      if (result.didStitch && stitchedPath != null) {
        final stitchedBytes = await File(stitchedPath).readAsBytes();
        final stitched = img.decodeImage(stitchedBytes);
        expect(stitched, isNotNull);
        expect(
          _sampledLumaRange(stitched!),
          greaterThan(8),
          reason: 'A stitched preview must contain visible receipt detail.',
        );
      }
      expect(result.status, isNot(ReceiptStitchStatus.notNeeded));
    },
    skip: paths.length < 2
        ? 'Set MAINTAINIAC_RECEIPT_STITCH_PATHS to two local receipt images.'
        : false,
  );
}

int _sampledLumaRange(img.Image image) {
  var minLuma = 255;
  var maxLuma = 0;
  final stepX = (image.width / 48).ceil().clamp(1, image.width);
  final stepY = (image.height / 96).ceil().clamp(1, image.height);
  for (var y = 0; y < image.height; y += stepY) {
    for (var x = 0; x < image.width; x += stepX) {
      final pixel = image.getPixel(x, y);
      final luma = (pixel.r * .299 + pixel.g * .587 + pixel.b * .114).round();
      minLuma = minLuma < luma ? minLuma : luma;
      maxLuma = maxLuma > luma ? maxLuma : luma;
    }
  }
  return maxLuma - minLuma;
}
