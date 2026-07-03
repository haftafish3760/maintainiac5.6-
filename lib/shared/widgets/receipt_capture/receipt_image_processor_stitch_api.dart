part of 'receipt_image_processor.dart';

Future<ReceiptStitchResult> _stitchReceiptPhotosForOcr({
  required List<String> paths,
  List<int>? manualOverlapPixels,
  List<double>? manualOverlapFractions,
  int maxOutputPixels = 16000000,
  int maxOutputHeight = 20000,
}) async {
  final inputPaths = paths
      .map((path) => path.trim())
      .where((path) => path.isNotEmpty)
      .toList(growable: false);
  if (inputPaths.length <= 1) {
    return ReceiptStitchResult.notNeeded(inputPaths);
  }
  if (!_stitchInputPathsAreUnique(inputPaths)) {
    return ReceiptStitchResult.fallback(
      inputPaths: inputPaths,
      warning:
          'Receipt photos included the same section more than once. Next will review the photos separately.',
      fallbackReasonCode: 'duplicate_input_paths',
    );
  }

  final decoded = <img.Image>[];
  try {
    for (final path in inputPaths) {
      final bytes = await ReceiptImageProcessor._readFileBytes(path);
      final image = bytes == null
          ? null
          : ReceiptImageProcessor._decodeImage(bytes);
      if (image == null) {
        return ReceiptStitchResult.fallback(
          inputPaths: inputPaths,
          warning: 'One receipt photo could not be read.',
          fallbackReasonCode: 'decode_failed',
        );
      }
      decoded.add(_enhanceReceiptForReading(_autoStraightenReceipt(image)));
    }

    final targetWidth = _stitchTargetWidth(decoded.length);
    final prepared = decoded
        .map((image) => _resizeToWidth(_autoCropReceipt(image), targetWidth))
        .toList(growable: false);
    final normalized = <img.Image>[prepared.first];
    var expectedHeight = normalized.first.height;
    final overlaps = <int>[];
    final confidences = <double>[];
    final pairResults = <ReceiptStitchPairResult>[];

    for (var index = 1; index < prepared.length; index++) {
      final pairIndex = index - 1;
      final previous = normalized[pairIndex];
      final manualOverlap = _manualOverlapFor(
        previous: previous,
        next: prepared[index],
        pairIndex: pairIndex,
        manualOverlapPixels: manualOverlapPixels,
        manualOverlapFractions: manualOverlapFractions,
      );
      if (manualOverlap != null) {
        final maxManualOverlap =
            math.min(previous.height, prepared[index].height) - 24;
        if (manualOverlap < 24 || manualOverlap > maxManualOverlap) {
          return ReceiptStitchResult.fallback(
            inputPaths: inputPaths,
            warning: 'Manual receipt overlap was outside the safe range.',
            fallbackReasonCode: 'manual_overlap_unsafe',
            failedPairIndex: pairIndex,
            pairs: pairResults,
          );
        }
        overlaps.add(manualOverlap);
        confidences.add(1);
        pairResults.add(
          ReceiptStitchPairResult(
            pairIndex: pairIndex,
            overlapPixels: manualOverlap,
            confidence: 1,
            usedManualAdjustment: true,
          ),
        );
        normalized.add(prepared[index]);
        expectedHeight += prepared[index].height - manualOverlap;
      } else {
        final match = _bestScaleTolerantVerticalOverlap(
          previous: previous,
          next: prepared[index],
          targetWidth: targetWidth,
        );
        if (!match.isConfident) {
          final failedPair = ReceiptStitchPairResult(
            pairIndex: pairIndex,
            overlapPixels: match.pixels,
            confidence: match.confidence,
            scaleCorrection: match.scaleCorrection,
            rotationCorrectionDegrees: match.rotationCorrectionDegrees,
          );
          return ReceiptStitchResult.fallback(
            inputPaths: inputPaths,
            warning:
                'Receipt photos did not match clearly enough to stitch safely.',
            fallbackReasonCode: 'overlap_confidence_low',
            confidence: match.confidence,
            failedPairIndex: pairIndex,
            pairs: List.unmodifiable([...pairResults, failedPair]),
          );
        }
        overlaps.add(match.pixels);
        confidences.add(match.confidence);
        normalized.add(match.nextImage);
        pairResults.add(
          ReceiptStitchPairResult(
            pairIndex: pairIndex,
            overlapPixels: match.pixels,
            confidence: match.confidence,
            scaleCorrection: match.scaleCorrection,
            rotationCorrectionDegrees: match.rotationCorrectionDegrees,
          ),
        );
        expectedHeight += match.nextImage.height - match.pixels;
      }
    }

    final expectedPixels = targetWidth * expectedHeight;
    if (expectedHeight > maxOutputHeight || expectedPixels > maxOutputPixels) {
      return ReceiptStitchResult.fallback(
        inputPaths: inputPaths,
        warning:
            'Receipt is too long to stitch safely on this device. Next will review the photos separately.',
        fallbackReasonCode: 'output_too_large',
        confidence: confidences.isEmpty ? 0 : confidences.reduce(math.min),
        pairs: pairResults,
        stitchedWidth: targetWidth,
        stitchedHeight: expectedHeight,
      );
    }

    final canvas = img.Image(
      width: targetWidth,
      height: expectedHeight,
      numChannels: 3,
    );
    img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
    var y = 0;
    img.compositeImage(canvas, normalized.first, dstX: 0, dstY: y);
    y += normalized.first.height;
    for (var index = 1; index < normalized.length; index++) {
      y -= overlaps[index - 1];
      img.compositeImage(canvas, normalized[index], dstX: 0, dstY: y);
      y += normalized[index].height;
    }

    final path = await _writeJpg(canvas, prefix: 'stitched', quality: 88);
    final confidence = confidences.isEmpty ? 1.0 : confidences.reduce(math.min);
    return ReceiptStitchResult(
      status: ReceiptStitchStatus.stitched,
      inputPaths: inputPaths,
      stitchedPath: path,
      ocrSourcePaths: [path],
      confidence: confidence,
      overlapPixels: overlaps,
      pairs: pairResults,
      stitchedWidth: targetWidth,
      stitchedHeight: expectedHeight,
      usedManualAdjustment:
          (manualOverlapPixels != null && manualOverlapPixels.isNotEmpty) ||
          (manualOverlapFractions != null && manualOverlapFractions.isNotEmpty),
    );
  } catch (_) {
    return ReceiptStitchResult.fallback(
      inputPaths: inputPaths,
      warning:
          'Receipt photos could not be stitched safely. Next will review them separately.',
      fallbackReasonCode: 'stitch_exception',
    );
  }
}

bool _stitchInputPathsAreUnique(List<String> inputPaths) {
  final seen = <String>{};
  for (final path in inputPaths) {
    if (!seen.add(path)) return false;
  }
  return true;
}
