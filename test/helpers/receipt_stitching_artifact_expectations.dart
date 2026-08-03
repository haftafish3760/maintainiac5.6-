import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

import 'receipt_stitching_image_helpers.dart';

Future<List<File>> writeReceiptStitchSections(
  List<img.Image> sections,
  String prefix,
) {
  return Future.wait([
    for (var index = 0; index < sections.length; index++)
      writeTempReceiptStitchingImage(sections[index], '${prefix}_$index'),
  ]);
}

Future<void> expectReadableStitchedArtifact(
  ReceiptStitchResult result, {
  int minHeight = 3600,
}) async {
  final stitchedPath = result.stitchedPath;
  expect(stitchedPath, isNotNull);
  final decoded = img.decodeImage(await File(stitchedPath!).readAsBytes());
  expect(decoded, isNotNull);
  expect(decoded!.width, result.stitchedWidth);
  expect(decoded.height, result.stitchedHeight);
  expect(decoded.height, greaterThan(minHeight));
}

int expectedStitchedHeightForUniformSections({
  required int sectionWidth,
  required int sectionHeight,
  required ReceiptStitchResult result,
}) {
  final firstHeight = (sectionHeight * result.stitchedWidth / sectionWidth)
      .round();
  var expectedHeight = firstHeight;
  for (var index = 0; index < result.pairs.length; index++) {
    final pair = result.pairs[index];
    final transformedWidth = (result.stitchedWidth * pair.scaleCorrection)
        .round()
        .clamp(320, 3200);
    final transformedHeight = (sectionHeight * transformedWidth / sectionWidth)
        .round();
    expectedHeight += transformedHeight - result.overlapPixels[index];
  }
  return expectedHeight;
}

img.Image keystoneReceiptStitchingShot(
  img.Image source, {
  required double narrowEdgeWidthFraction,
  required bool narrowTop,
}) {
  final minimumFraction = narrowEdgeWidthFraction.clamp(.72, .98);
  final output = img.Image(
    width: source.width,
    height: source.height,
    numChannels: source.numChannels,
  );
  img.fill(output, color: img.ColorRgb8(232, 232, 228));
  for (var y = 0; y < source.height; y++) {
    final progress = y / (source.height - 1);
    final edgeProgress = narrowTop ? progress : 1 - progress;
    final widthFraction =
        minimumFraction + (1 - minimumFraction) * edgeProgress;
    final rowWidth = (source.width * widthFraction).round().clamp(
      2,
      source.width,
    );
    final left = (source.width - rowWidth) ~/ 2;
    for (var x = 0; x < rowWidth; x++) {
      final sourceX = (x * (source.width - 1) / (rowWidth - 1)).round();
      output.setPixel(left + x, y, source.getPixel(sourceX, y));
    }
  }
  return output;
}
