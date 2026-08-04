part of 'receipt_image_processor.dart';

int? _manualOverlapFor({
  required img.Image previous,
  required img.Image next,
  required int pairIndex,
  required List<int>? manualOverlapPixels,
  required List<double>? manualOverlapFractions,
}) {
  if (manualOverlapPixels != null && pairIndex < manualOverlapPixels.length) {
    final pixels = manualOverlapPixels[pairIndex];
    if (pixels <= 0) return null;
    return pixels;
  }
  if (manualOverlapFractions != null &&
      pairIndex < manualOverlapFractions.length) {
    final fraction = manualOverlapFractions[pairIndex];
    if (!fraction.isFinite) return -1;
    if (fraction <= 0) return null;
    final shortest = math.min(previous.height, next.height);
    return (shortest * fraction).round();
  }
  return null;
}

double _manualStitchValue(
  List<double>? values,
  int pairIndex, {
  required double fallback,
  required double minimum,
  required double maximum,
}) {
  if (values == null || pairIndex < 0 || pairIndex >= values.length) {
    return fallback;
  }
  final value = values[pairIndex];
  if (!value.isFinite) return fallback;
  return value.clamp(minimum, maximum).toDouble();
}

_ReceiptOverlapMatch _strongerCorroboratedStitchMatch({
  required img.Image previous,
  required _ReceiptOverlapMatch primary,
  required _ReceiptOverlapMatch retry,
}) {
  double score(_ReceiptOverlapMatch match) {
    final evidence = _receiptOverlapContinuityEvidence(
      previous: previous,
      match: match,
    );
    final continuityScore = evidence.isProven
        ? (.42 + evidence.correlation * .30).clamp(0.0, .72)
        : 0.0;
    final delayedOverlapPenalty = match.nextTopOffsetPixels > match.pixels
        ? .08
        : 0.0;
    return math.max(match.confidence, continuityScore) - delayedOverlapPenalty;
  }

  final primaryScore = score(primary);
  final retryScore = score(retry);
  return retryScore > primaryScore + .01 ? retry : primary;
}

class _ReceiptStitchRequest {
  const _ReceiptStitchRequest({
    required this.paths,
    required this.textLinesByPath,
    required this.manualZeroOverlapPairs,
    required this.manualOverlapPixels,
    required this.manualOverlapFractions,
    required this.manualScaleCorrections,
    required this.manualRotationCorrectionsDegrees,
    required this.manualHorizontalOffsetFractions,
    required this.maxOutputPixels,
    required this.maxOutputHeight,
    required this.maxTargetWidth,
    required this.comparisonWidth,
    required this.retryComparisonWidth,
    required this.outputPath,
  });

  final List<String> paths;
  final List<List<String>>? textLinesByPath;
  final List<bool>? manualZeroOverlapPairs;
  final List<int>? manualOverlapPixels;
  final List<double>? manualOverlapFractions;
  final List<double>? manualScaleCorrections;
  final List<double>? manualRotationCorrectionsDegrees;
  final List<double>? manualHorizontalOffsetFractions;
  final int maxOutputPixels;
  final int maxOutputHeight;
  final int maxTargetWidth;
  final int comparisonWidth;
  final int retryComparisonWidth;
  final String outputPath;
}

Future<ReceiptStitchResult> _runReceiptStitchInBackground(
  _ReceiptStitchRequest request,
) {
  return _stitchReceiptPhotosForOcr(
    paths: request.paths,
    textLinesByPath: request.textLinesByPath,
    manualZeroOverlapPairs: request.manualZeroOverlapPairs,
    manualOverlapPixels: request.manualOverlapPixels,
    manualOverlapFractions: request.manualOverlapFractions,
    manualScaleCorrections: request.manualScaleCorrections,
    manualRotationCorrectionsDegrees: request.manualRotationCorrectionsDegrees,
    manualHorizontalOffsetFractions: request.manualHorizontalOffsetFractions,
    maxOutputPixels: request.maxOutputPixels,
    maxOutputHeight: request.maxOutputHeight,
    maxTargetWidth: request.maxTargetWidth,
    comparisonWidth: request.comparisonWidth,
    retryComparisonWidth: request.retryComparisonWidth,
    outputPath: request.outputPath,
  );
}

ReceiptStitchTextPairEvidence _receiptStitchTextEvidenceForPair({
  required List<String> inputPaths,
  required List<List<String>>? textLinesByPath,
  required int pairIndex,
}) {
  if (textLinesByPath == null ||
      textLinesByPath.length != inputPaths.length ||
      pairIndex < 0 ||
      pairIndex + 1 >= textLinesByPath.length) {
    return const ReceiptStitchTextPairEvidence.none();
  }
  return matchReceiptStitchTextOverlap(
    ReceiptStitchTextEvidence(
      path: inputPaths[pairIndex],
      lines: textLinesByPath[pairIndex],
    ),
    ReceiptStitchTextEvidence(
      path: inputPaths[pairIndex + 1],
      lines: textLinesByPath[pairIndex + 1],
    ),
  );
}

({ReceiptStitchTextPairEvidence evidence, bool safelyAcceleratesGeometry})
_receiptStitchTextPlanForPair({
  required List<String> inputPaths,
  required List<List<String>>? textLinesByPath,
  required int pairIndex,
}) {
  final evidence = _receiptStitchTextEvidenceForPair(
    inputPaths: inputPaths,
    textLinesByPath: textLinesByPath,
    pairIndex: pairIndex,
  );
  if (textLinesByPath == null ||
      pairIndex < 0 ||
      pairIndex + 1 >= inputPaths.length ||
      pairIndex + 1 >= textLinesByPath.length) {
    return (evidence: evidence, safelyAcceleratesGeometry: false);
  }
  return (
    evidence: evidence,
    safelyAcceleratesGeometry: receiptStitchTextSafelyAcceleratesGeometry(
      ReceiptStitchTextEvidence(
        path: inputPaths[pairIndex],
        lines: textLinesByPath[pairIndex],
      ),
      ReceiptStitchTextEvidence(
        path: inputPaths[pairIndex + 1],
        lines: textLinesByPath[pairIndex + 1],
      ),
      evidence,
    ),
  );
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
  for (final inputPath in inputPaths) {
    final normalized = normalizedReceiptPhotoPath(inputPath);
    if (normalized == null || !seen.add(normalized)) return false;
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
    failedPairIndex: pairResults.isEmpty ? null : pairResults.last.pairIndex,
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

int _findDuplicateReceiptSourceHashIndex(
  List<String> sourceHashes,
  String candidate,
) => sourceHashes.indexOf(candidate);

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
    final shiftedDuplicate = _receiptImageSmallShiftDuplicateContentMatches(
      decoded[index],
      candidate,
    );
    if (contentMatches ||
        shiftedDuplicate ||
        (!isImmediateNeighbor &&
            _receiptImageAverageHashDistance(decoded[index], candidate) <=
                12)) {
      return index;
    }
  }
  return -1;
}
