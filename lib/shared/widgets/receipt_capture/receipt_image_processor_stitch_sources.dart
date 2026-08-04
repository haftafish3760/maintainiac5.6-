part of 'receipt_image_processor.dart';

class _ReceiptStitchSourcePreparation {
  const _ReceiptStitchSourcePreparation({
    required this.prepared,
    required this.comparisonPrepared,
    required this.comparisonHasReadableDetail,
    required this.comparisonLooksLikeReceiptPhoto,
  }) : failure = null;

  const _ReceiptStitchSourcePreparation.failed(this.failure)
    : prepared = const [],
      comparisonPrepared = const [],
      comparisonHasReadableDetail = const [],
      comparisonLooksLikeReceiptPhoto = const [];

  final List<img.Image> prepared;
  final List<img.Image> comparisonPrepared;
  final List<bool> comparisonHasReadableDetail;
  final List<bool> comparisonLooksLikeReceiptPhoto;
  final ReceiptStitchResult? failure;
}

Future<_ReceiptStitchSourcePreparation> _prepareReceiptStitchSources({
  required List<String> inputPaths,
  required int targetWidth,
}) async {
  final decoded = <img.Image>[];
  final comparisonSources = <img.Image>[];
  final sourceHashes = <String>[];
  final detailFlags = <bool>[];
  final receiptFlags = <bool>[];
  final workingWidth = _stitchWorkingWidth(targetWidth);

  for (final sourcePath in inputPaths) {
    final bytes = await ReceiptImageProcessor._readFileBytes(sourcePath);
    final sourceHash = bytes == null ? null : sha256.convert(bytes).toString();
    if (sourceHash != null &&
        _findDuplicateReceiptSourceHashIndex(sourceHashes, sourceHash) >= 0) {
      return _ReceiptStitchSourcePreparation.failed(
        _duplicateReceiptSectionFallback(inputPaths, decoded.length - 1),
      );
    }
    final decodedImage = bytes == null
        ? null
        : ReceiptImageProcessor._decodeImage(bytes);
    if (decodedImage == null) {
      return _ReceiptStitchSourcePreparation.failed(
        ReceiptStitchResult.fallback(
          inputPaths: inputPaths,
          warning: 'One receipt photo could not be read.',
          fallbackReasonCode: 'decode_failed',
        ),
      );
    }
    // EXIF orientation is baked only into private working copies. User source
    // photos remain unchanged and available to OCR/fallback review.
    final upright = img.bakeOrientation(decodedImage);
    final working = _resizeForStitchWorkingWidth(upright, workingWidth);
    final proof = _stripVerifiedTopCaptureArtifact(working);
    if (_findDuplicateReceiptDecodedImageIndex(decoded, proof) >= 0) {
      return _ReceiptStitchSourcePreparation.failed(
        _duplicateReceiptSectionFallback(inputPaths, decoded.length - 1),
      );
    }
    final comparisonBase = _resizeToMaxSide(
      _maskStitchComparisonHorizontalFrame(proof),
      720,
    );

    sourceHashes.add(sourceHash!);
    decoded.add(proof);
    detailFlags.add(_receiptImageHasReadableDetail(comparisonBase));
    receiptFlags.add(_receiptImageLooksLikeReceiptPhoto(comparisonBase));
    comparisonSources.add(
      img.contrast(
        img.normalize(img.grayscale(comparisonBase), min: 12, max: 244),
        contrast: 100,
      ),
    );
  }

  return _ReceiptStitchSourcePreparation(
    prepared: decoded
        .map((image) => _resizeToWidth(image, targetWidth))
        .toList(growable: false),
    comparisonPrepared: comparisonSources
        .map((image) => _resizeToWidth(image, targetWidth))
        .toList(growable: false),
    comparisonHasReadableDetail: List.unmodifiable(detailFlags),
    comparisonLooksLikeReceiptPhoto: List.unmodifiable(receiptFlags),
  );
}

img.Image _maskStitchComparisonHorizontalFrame(img.Image source) {
  if (source.width < 480 || source.height < 480) return source;
  final sample = _resizeToMaxSide(source, 420);
  final bounds = _scanReceiptBounds(sample, paperOnly: false);
  if (bounds == null || bounds.hitCount < 120 || bounds.width <= 0) {
    return source;
  }
  final widthRatio = bounds.width / sample.width;
  final heightRatio = bounds.height / sample.height;
  if (widthRatio < .42 || widthRatio > .90 || heightRatio < .42) {
    return source;
  }
  final pad = (bounds.width * .12).clamp(12, sample.width * .08);
  final left = (bounds.left - pad).clamp(0, sample.width - 1);
  final right = (bounds.right + pad).clamp(left + 1, sample.width);
  final scaleX = source.width / sample.width;
  final cropX = (left * scaleX).round().clamp(0, source.width - 1);
  final cropRight = (right * scaleX).round().clamp(cropX + 1, source.width);
  if ((cropRight - cropX) / source.width > .94) return source;
  // Matching and proof composition must use the same coordinate system.
  // Cropping this private copy and stretching it back to targetWidth changes
  // its Y scale and erases the receipt's real X position. A match found there
  // cannot safely drive the uncropped proof. Mask the background instead so
  // the receipt remains isolated without changing dimensions or coordinates.
  final masked = img.Image(
    width: source.width,
    height: source.height,
    numChannels: 3,
  );
  img.fill(masked, color: img.ColorRgb8(255, 255, 255));
  final receiptFrame = img.copyCrop(
    source,
    x: cropX,
    y: 0,
    width: cropRight - cropX,
    height: source.height,
  );
  img.compositeImage(masked, receiptFrame, dstX: cropX, dstY: 0);
  return masked;
}

ReceiptStitchResult _duplicateReceiptSectionFallback(
  List<String> inputPaths,
  int pairIndex,
) {
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
