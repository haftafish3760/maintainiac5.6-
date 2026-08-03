part of 'receipt_image_processor.dart';

img.Image _resizeToMaxSide(img.Image source, int maxLongSide) {
  final longSide = math.max(source.width, source.height);
  if (longSide <= maxLongSide) return source;
  if (source.width >= source.height) {
    return img.copyResize(source, width: maxLongSide);
  }
  return img.copyResize(source, height: maxLongSide);
}

int _stitchTargetWidth(int photoCount) {
  if (photoCount <= 2) return 1400;
  if (photoCount <= 5) return 1200;
  if (photoCount <= 10) return 1000;
  return 820;
}

/// The stitcher only needs a modest framing margin above the eventual combined
/// proof width. Keeping its private working copy bounded prevents a pair of
/// full-resolution phone images from turning a simple two-photo receipt into
/// a long device stall. This never changes the original photos on disk.
int _stitchWorkingWidth(int targetWidth) => targetWidth + 400;

img.Image _resizeForStitchWorkingWidth(img.Image source, int workingWidth) {
  if (source.width <= workingWidth) return source;
  return img.copyResize(source, width: workingWidth);
}

img.Image _resizeToWidth(img.Image source, int width) {
  if (source.width == width) return source;
  return img.copyResize(source, width: width);
}
