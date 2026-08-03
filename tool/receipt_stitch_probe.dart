import 'dart:convert';
import 'dart:io';

import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

/// Runs the production stitcher against caller-supplied local receipt images.
///
/// This never changes a receipt record or uploads files. It prints structured
/// evidence so an actual device photo pair can be diagnosed before the UI is
/// changed around a guessed failure.
Future<void> main(List<String> paths) async {
  if (paths.length < 2) {
    stderr.writeln('Usage: dart run tool/receipt_stitch_probe.dart <photo> <photo> [...]');
    exitCode = 64;
    return;
  }
  final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
    paths: paths,
  );
  stdout.writeln(
    const JsonEncoder.withIndent('  ').convert({
      'status': result.status.name,
      'didStitch': result.didStitch,
      'fallbackReason': result.fallbackReasonCode,
      'warning': result.warning,
      'confidence': result.confidence,
      'failedPair': result.failedPairIndex,
      'overlapPixels': result.overlapPixels,
      'stitchedPath': result.stitchedPath,
      'stitchedSize': result.stitchedSizeLabel,
      'pairs': [
        for (final pair in result.pairs)
          {
            'pair': pair.pairIndex + 1,
            'overlapPixels': pair.overlapPixels,
            'confidence': pair.confidence,
            'scale': pair.scaleCorrection,
            'rotation': pair.rotationCorrectionDegrees,
            'horizontalOffset': pair.horizontalOffsetPixels,
            'verticalOffset': pair.verticalOffsetPixels,
          },
      ],
    }),
  );
}
