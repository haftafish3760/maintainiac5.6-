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
  if (inputPaths.isEmpty) {
    return ReceiptStitchResult.fallback(
      inputPaths: [],
      warning: 'No receipt photos were available for stitching.',
      fallbackReasonCode: 'no_input_paths',
    );
  }
  if (inputPaths.length <= 1) {
    return ReceiptStitchResult.notNeeded(inputPaths);
  }
  if (!receiptPhotoPathsAreUniqueAndNormalized(inputPaths)) {
    final duplicateOrAlias = _stitchInputPathsHaveDuplicateAliases(inputPaths);
    return ReceiptStitchResult.fallback(
      inputPaths: inputPaths,
      warning:
          'Receipt photos included invalid or repeated section paths. Receipt details will use the photos separately.',
      fallbackReasonCode: duplicateOrAlias
          ? 'duplicate_input_paths'
          : 'invalid_input_paths',
    );
  }
  if (!_stitchInputPathsAreUnique(inputPaths)) {
    return ReceiptStitchResult.fallback(
      inputPaths: inputPaths,
      warning:
          'Receipt photos included the same section more than once. Receipt details will use the photos separately.',
      fallbackReasonCode: 'duplicate_input_paths',
    );
  }

  final decoded = <img.Image>[];
  final decodedBytes = <List<int>>[];
  final decodedSources = <img.Image>[];
  try {
    for (final path in inputPaths) {
      final bytes = await ReceiptImageProcessor._readFileBytes(path);
      final duplicateSourceIndex = bytes == null
          ? -1
          : _findDuplicateReceiptImageIndex(decodedBytes, bytes);
      if (duplicateSourceIndex >= 0) {
        final pairIndex = decodedBytes.length - 1;
        return ReceiptStitchResult.fallback(
          inputPaths: inputPaths,
          warning:
              'Two receipt photos appear to show the same section. Receipt details will use the photos separately.',
          fallbackReasonCode: 'duplicate_section_image',
          failedPairIndex: pairIndex,
          pairs: [
            ReceiptStitchPairResult(
              pairIndex: pairIndex,
              overlapPixels: 0,
              confidence: 1,
            ),
          ],
        );
      }
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
      final duplicateDecodedIndex = _findDuplicateReceiptDecodedImageIndex(
        decodedSources,
        image,
      );
      if (duplicateDecodedIndex >= 0) {
        final pairIndex = decodedSources.length - 1;
        return ReceiptStitchResult.fallback(
          inputPaths: inputPaths,
          warning:
              'Two receipt photos appear to show the same section. Receipt details will use the photos separately.',
          fallbackReasonCode: 'duplicate_section_image',
          failedPairIndex: pairIndex,
          pairs: [
            ReceiptStitchPairResult(
              pairIndex: pairIndex,
              overlapPixels: 0,
              confidence: 1,
            ),
          ],
        );
      }
      decodedBytes.add(bytes!);
      decodedSources.add(image);
      final receiptFramed = _autoCropReceipt(image);
      decoded.add(
        _enhanceReceiptForReading(_autoStraightenReceipt(receiptFramed)),
      );
    }

    final targetWidth = _stitchTargetWidth(decoded.length);
    final prepared = decoded
        .map((image) => _resizeToWidth(_autoCropReceipt(image), targetWidth))
        .toList(growable: false);
    if (manualOverlapPixels == null && manualOverlapFractions == null) {
      final minimumAutoHeight = _minimumAutoStitchHeight(prepared);
      final minimumAutoPixels = targetWidth * minimumAutoHeight;
      if (minimumAutoHeight > maxOutputHeight ||
          minimumAutoPixels > maxOutputPixels) {
        return _oversizedStitchFallback(
          inputPaths: inputPaths,
          targetWidth: targetWidth,
          expectedHeight: minimumAutoHeight,
          maxOutputPixels: maxOutputPixels,
          maxOutputHeight: maxOutputHeight,
          confidences: const [],
          pairResults: const [],
        )!;
      }
    }
    final normalized = <img.Image>[prepared.first];
    var expectedHeight = normalized.first.height;
    final overlaps = <int>[];
    final horizontalOffsets = <int>[];
    final confidences = <double>[];
    final pairResults = <ReceiptStitchPairResult>[];
    ReceiptStitchResult? oversizedFallback() => _oversizedStitchFallback(
      inputPaths: inputPaths,
      targetWidth: targetWidth,
      expectedHeight: expectedHeight,
      maxOutputPixels: maxOutputPixels,
      maxOutputHeight: maxOutputHeight,
      confidences: confidences,
      pairResults: pairResults,
    );
    final initialOversizedFallback = oversizedFallback();
    if (initialOversizedFallback != null) return initialOversizedFallback;

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
        horizontalOffsets.add(0);
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
        final fallback = oversizedFallback();
        if (fallback != null) return fallback;
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
        overlaps.add(match.nextSkipPixels);
        horizontalOffsets.add(match.nextXOffsetPixels);
        confidences.add(match.confidence);
        normalized.add(match.nextImage);
        pairResults.add(
          ReceiptStitchPairResult(
            pairIndex: pairIndex,
            overlapPixels: match.pixels,
            confidence: match.confidence,
            scaleCorrection: match.scaleCorrection,
            rotationCorrectionDegrees: match.rotationCorrectionDegrees,
            horizontalOffsetPixels: match.nextXOffsetPixels,
            verticalOffsetPixels: match.nextTopOffsetPixels,
          ),
        );
        expectedHeight += match.nextImage.height - match.nextSkipPixels;
        final fallback = oversizedFallback();
        if (fallback != null) return fallback;
      }
    }

    final horizontalPlacements = _stitchHorizontalPlacements(horizontalOffsets);
    final minPlacementX = horizontalPlacements.reduce(math.min);
    final maxPlacementX = horizontalPlacements
        .map((x) => x + targetWidth)
        .reduce(math.max);
    final canvasWidth = maxPlacementX - minPlacementX;
    final expandedPixels = canvasWidth * expectedHeight;
    if (expectedHeight > maxOutputHeight || expandedPixels > maxOutputPixels) {
      return _oversizedStitchFallback(
        inputPaths: inputPaths,
        targetWidth: canvasWidth,
        expectedHeight: expectedHeight,
        maxOutputPixels: maxOutputPixels,
        maxOutputHeight: maxOutputHeight,
        confidences: confidences,
        pairResults: pairResults,
      )!;
    }
    final placementShiftX = -minPlacementX;
    final canvas = img.Image(
      width: canvasWidth,
      height: expectedHeight,
      numChannels: 3,
    );
    img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
    var y = 0;
    img.compositeImage(
      canvas,
      normalized.first,
      dstX: horizontalPlacements.first + placementShiftX,
      dstY: y,
    );
    y += normalized.first.height;
    for (var index = 1; index < normalized.length; index++) {
      y -= overlaps[index - 1];
      img.compositeImage(
        canvas,
        normalized[index],
        dstX: horizontalPlacements[index] + placementShiftX,
        dstY: y,
      );
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
      stitchedWidth: canvasWidth,
      stitchedHeight: expectedHeight,
      usedManualAdjustment: pairResults.any(
        (pair) => pair.usedManualAdjustment,
      ),
    );
  } catch (_) {
    return ReceiptStitchResult.fallback(
      inputPaths: inputPaths,
      warning:
          'Receipt photos could not be stitched safely. Receipt details will use them separately.',
      fallbackReasonCode: 'stitch_exception',
    );
  }
}

List<int> _stitchHorizontalPlacements(List<int> pairOffsets) {
  final placements = <int>[0];
  for (final offset in pairOffsets) {
    placements.add(placements.last - offset);
  }
  return placements;
}

bool _stitchInputPathsAreUnique(List<String> inputPaths) {
  final seen = <String>{};
  for (final path in inputPaths) {
    final normalized = normalizedReceiptPhotoPath(path);
    if (normalized == null) return false;
    if (!seen.add(normalized)) return false;
  }
  return true;
}

bool _stitchInputPathsHaveDuplicateAliases(List<String> inputPaths) {
  final seen = <String>{};
  for (final inputPath in inputPaths) {
    final normalized = normalizedReceiptPhotoPath(inputPath);
    final alias = normalized ?? path.normalize(inputPath);
    if (alias.isEmpty || alias != inputPath && normalized == null) {
      if (!inputPath.startsWith('/')) continue;
    }
    if (!seen.add(alias)) return true;
  }
  return false;
}

ReceiptStitchResult? _oversizedStitchFallback({
  required List<String> inputPaths,
  required int targetWidth,
  required int expectedHeight,
  required int maxOutputPixels,
  required int maxOutputHeight,
  required List<double> confidences,
  required List<ReceiptStitchPairResult> pairResults,
}) {
  final expectedPixels = targetWidth * expectedHeight;
  if (expectedHeight <= maxOutputHeight && expectedPixels <= maxOutputPixels) {
    return null;
  }
  return ReceiptStitchResult.fallback(
    inputPaths: inputPaths,
    warning:
        'Receipt is too long to stitch safely on this device. Receipt details will use the photos separately.',
    fallbackReasonCode: 'output_too_large',
    confidence: confidences.isEmpty ? 0 : confidences.reduce(math.min),
    pairs: pairResults,
    stitchedWidth: targetWidth,
    stitchedHeight: expectedHeight,
  );
}

int _minimumAutoStitchHeight(List<img.Image> prepared) {
  var height = prepared.first.height;
  for (var index = 1; index < prepared.length; index++) {
    height +=
        prepared[index].height -
        _maxAutoNextSkipBound(
          previous: prepared[index - 1],
          next: prepared[index],
        );
  }
  return math.max(1, height);
}

int _maxAutoNextSkipBound({
  required img.Image previous,
  required img.Image next,
}) {
  final shortest = math.min(previous.height, next.height);
  final maxPixels = math.min(
    shortest - 1,
    math.max(48, (shortest * .46).round()),
  );
  final maxNextTopOffset = math.min(
    320,
    math.max(
      0,
      math.min((next.height * .26).round(), next.height - maxPixels - 24),
    ),
  );
  return math.min(next.height - 1, maxPixels + maxNextTopOffset);
}

int _findDuplicateReceiptImageIndex(
  List<List<int>> decodedBytes,
  List<int> candidate,
) {
  for (var index = 0; index < decodedBytes.length; index++) {
    if (_receiptImageBytesMatch(decodedBytes[index], candidate)) {
      return index;
    }
  }
  return -1;
}

int _findDuplicateReceiptDecodedImageIndex(
  List<img.Image> decoded,
  img.Image candidate,
) {
  for (var index = 0; index < decoded.length; index++) {
    final isImmediateNeighbor = index == decoded.length - 1;
    final contentMatches = isImmediateNeighbor
        ? _receiptImageImmediateDuplicateContentMatches(
            decoded[index],
            candidate,
          )
        : _receiptImageContentMatches(decoded[index], candidate);
    if (contentMatches ||
        (!isImmediateNeighbor &&
            _receiptImageAverageHashDistance(decoded[index], candidate) <=
                12)) {
      return index;
    }
  }
  return -1;
}
