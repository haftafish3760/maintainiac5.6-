import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

import 'helpers/receipt_stitching_image_helpers.dart';

const _extremeAspectRatioTimeout = Timeout(Duration(minutes: 2));

void main() {
  test(
    'preserves ordered sources when a 300 by 10000 receipt exceeds stitch limits',
    () async {
      final files = await _writeNarrowTenThousandPixelReceipt(
        'narrow_300_by_10000',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [for (final file in files) file.path],
        maxOutputHeight: 9000,
      );

      expect(result.didStitch, isFalse, reason: result.detailLabel);
      expect(result.usedFallback, isTrue);
      expect(result.fallbackReasonCode, 'output_too_large');
      expect(result.stitchedPath, isNull);
      expect(result.pairs, hasLength(files.length - 1));
      expect(result.ocrSourcePaths, [for (final file in files) file.path]);
      expect(
        result.sourcePreservationCode,
        'original_sections_preserved_ordered_ocr_sources',
      );
      expect(result.ocrSourceContractCode, 'fallback_ordered_sources_ready');
      expect(result.hasValidOcrSourceContract, isTrue);
      expect(result.requiresOcrSourceReviewBeforeAssistedRead, isFalse);
      expect(result.stitchedHeight, greaterThan(9000));
    },
    timeout: _extremeAspectRatioTimeout,
  );
}

Future<List<File>> _writeNarrowTenThousandPixelReceipt(String prefix) async {
  const sectionWidth = 300;
  const overlap = 400;
  const sectionHeights = [2000, 1990, 2010, 1980, 2020, 2000];
  final sections = [
    for (var index = 0; index < 6; index++)
      _narrowReceiptSection(
        width: sectionWidth,
        height: sectionHeights[index],
        seed: 900 + index,
      ),
  ];
  for (var index = 1; index < sections.length; index++) {
    copyReceiptStitchingOverlap(
      from: sections[index - 1],
      to: sections[index],
      pixels: overlap,
    );
  }
  final files = <File>[];
  for (var index = 0; index < sections.length; index++) {
    files.add(
      await writeTempReceiptStitchingImage(sections[index], '${prefix}_$index'),
    );
  }
  return files;
}

img.Image _narrowReceiptSection({
  required int width,
  required int height,
  required int seed,
}) {
  final image = img.Image(width: width, height: height, numChannels: 3);
  img.fill(image, color: img.ColorRgb8(248, 248, 244));
  for (var y = 36; y < height - 30; y += 64) {
    final xStart = 18 + ((seed + y) % 20);
    final lineWidth = 120 + ((seed * 7 + y * 3) % 140);
    img.fillRect(
      image,
      x1: xStart,
      y1: y,
      x2: (xStart + lineWidth).clamp(0, width - 1),
      y2: y + 7,
      color: img.ColorRgb8(30, 30, 30),
    );
    final amountX = 222 + ((seed + y) % 24);
    img.fillRect(
      image,
      x1: amountX,
      y1: y + 15,
      x2: width - 18,
      y2: y + 21,
      color: img.ColorRgb8(55, 55, 55),
    );
  }
  final markerX = 24 + ((seed * 17) % 180);
  final bandShade = 170 + (seed % 60);
  img.fillRect(
    image,
    x1: 0,
    y1: height - 620,
    x2: width - 1,
    y2: height - 500,
    color: img.ColorRgb8(bandShade, bandShade, bandShade),
  );
  img.fillRect(
    image,
    x1: markerX,
    y1: height - 180,
    x2: markerX + 18,
    y2: height - 150,
    color: img.ColorRgb8(12 + (seed % 40), 12, 12),
  );
  return image;
}
