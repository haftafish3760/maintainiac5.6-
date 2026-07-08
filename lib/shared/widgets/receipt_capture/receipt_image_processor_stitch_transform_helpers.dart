part of 'receipt_image_processor.dart';

_ReceiptOverlapMatch _materializeStitchCandidate({
  required _ReceiptStitchCandidate candidate,
  required int previousHeight,
  required img.Image next,
  required int targetWidth,
}) {
  final nextImage = _transformForStitchComparison(
    next,
    targetWidth: targetWidth,
    scale: candidate.scaleCorrection,
    rotationDegrees: candidate.rotationCorrectionDegrees,
  );
  final scaleY = nextImage.height / math.max(1, candidate.sampleHeight);
  final scaleX = nextImage.width / math.max(1, candidate.sampleWidth);
  final maxSafeOverlap = math.max(
    24,
    math.min(previousHeight, nextImage.height) - 1,
  );
  final fullPixels =
      (candidate.pixels * scaleY).round().clamp(
            24,
            math.min(maxSafeOverlap, 2400),
          )
          as int;
  final maxTopOffset = math.max(0, nextImage.height - fullPixels - 24);
  final fullTopOffset =
      (math.max(0, candidate.nextSkipPixels - candidate.pixels) * scaleY)
          .round()
          .clamp(0, maxTopOffset);
  final stitchedNextImage = fullTopOffset == 0
      ? nextImage
      : img.copyCrop(
          nextImage,
          x: 0,
          y: fullTopOffset,
          width: nextImage.width,
          height: nextImage.height - fullTopOffset,
        );
  return _ReceiptOverlapMatch(
    pixels: fullPixels,
    nextSkipPixels: fullPixels,
    nextXOffsetPixels: (candidate.nextXOffsetPixels * scaleX).round(),
    nextTopOffsetPixels: fullTopOffset,
    confidence: candidate.confidence,
    nextImage: stitchedNextImage,
    scaleCorrection: candidate.scaleCorrection,
    rotationCorrectionDegrees: candidate.rotationCorrectionDegrees,
  );
}

img.Image _transformForStitchComparison(
  img.Image source, {
  required int targetWidth,
  required double scale,
  required double rotationDegrees,
}) {
  if ((scale - 1).abs() < .001 &&
      rotationDegrees.abs() < .001 &&
      source.width == targetWidth) {
    return source;
  }
  final scaledWidth = (targetWidth * scale).round().clamp(320, 3200);
  var transformed = img.copyResize(source, width: scaledWidth);
  if (rotationDegrees.abs() >= .001) {
    transformed = img.copyRotate(
      transformed,
      angle: rotationDegrees,
      interpolation: img.Interpolation.linear,
    );
  }
  return _centerFitToWidth(transformed, targetWidth);
}

img.Image _centerFitToWidth(img.Image source, int targetWidth) {
  if (source.width == targetWidth) return source;
  if (source.width > targetWidth) {
    final cropX = ((source.width - targetWidth) / 2).round();
    return img.copyCrop(
      source,
      x: cropX,
      y: 0,
      width: targetWidth,
      height: source.height,
    );
  }
  final canvas = img.Image(
    width: targetWidth,
    height: source.height,
    numChannels: 3,
  );
  img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
  final dstX = ((targetWidth - source.width) / 2).round();
  img.compositeImage(canvas, source, dstX: dstX, dstY: 0);
  return canvas;
}
