part of 'receipt_image_processor.dart';

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

int _findDuplicateReceiptImageIndex(
  List<List<int>> decodedBytes,
  List<int> candidate,
) {
  for (var index = 0; index < decodedBytes.length; index++) {
    if (_receiptImageBytesMatch(decodedBytes[index], candidate)) return index;
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
