import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

void main() {
  test('stitch result labels explain stitched and fallback OCR handoff', () {
    const stitched = ReceiptStitchResult(
      status: ReceiptStitchStatus.stitched,
      inputPaths: ['/tmp/a.jpg', '/tmp/b.jpg', '/tmp/c.jpg'],
      ocrSourcePaths: ['/tmp/stitched.jpg'],
      stitchedPath: '/tmp/stitched.jpg',
      confidence: .86,
      overlapPixels: [240, 260],
      stitchedWidth: 1200,
      stitchedHeight: 4200,
      pairs: [
        ReceiptStitchPairResult(
          pairIndex: 0,
          overlapPixels: 240,
          confidence: .86,
        ),
        ReceiptStitchPairResult(
          pairIndex: 1,
          overlapPixels: 260,
          confidence: .9,
          rotationCorrectionDegrees: .8,
        ),
      ],
    );
    const fallback = ReceiptStitchResult.fallback(
      inputPaths: ['/tmp/a.jpg', '/tmp/b.jpg'],
      warning: 'Overlap was not clear enough.',
      confidence: .34,
      failedPairIndex: 0,
    );

    expect(stitched.summaryLabel, contains('combined'));
    expect(stitched.detailLabel, contains('3 photos became 1 receipt image'));
    expect(stitched.detailLabel, contains('1200 x 4200'));
    expect(stitched.detailLabel, contains('86%'));
    expect(stitched.stitchedPixelCount, 5040000);
    expect(stitched.pairs.first.summaryLabel, contains('Photo 1 to 2'));
    expect(stitched.pairs.last.summaryLabel, contains('straighten 0.8 deg'));
    expect(fallback.summaryLabel, contains('reviewed separately'));
    expect(fallback.ocrSourcePaths, ['/tmp/a.jpg', '/tmp/b.jpg']);
    expect(fallback.failedPairLabel, 'Photo 1 to 2');
    expect(fallback.detailLabel, 'Photo 1 to 2: Overlap was not clear enough.');
  });

  test('stitch result can be rebound to final OCR artifact paths', () {
    const preview = ReceiptStitchResult(
      status: ReceiptStitchStatus.stitched,
      inputPaths: ['/tmp/raw_a.jpg', '/tmp/raw_b.jpg'],
      ocrSourcePaths: ['/tmp/preview_stitched.jpg'],
      stitchedPath: '/tmp/preview_stitched.jpg',
      confidence: .91,
      overlapPixels: [244],
      stitchedWidth: 900,
      stitchedHeight: 2100,
      pairs: [
        ReceiptStitchPairResult(
          pairIndex: 0,
          overlapPixels: 244,
          confidence: .91,
        ),
      ],
    );

    final finalResult = preview.copyForFinalOcr(
      inputPaths: const ['/tmp/prepared_a.jpg', '/tmp/prepared_b.jpg'],
      ocrSourcePaths: const ['/tmp/final_stitched.jpg'],
      stitchedPath: '/tmp/final_stitched.jpg',
    );

    expect(finalResult.didStitch, isTrue);
    expect(finalResult.inputPaths, [
      '/tmp/prepared_a.jpg',
      '/tmp/prepared_b.jpg',
    ]);
    expect(finalResult.ocrSourcePaths, ['/tmp/final_stitched.jpg']);
    expect(finalResult.stitchedPath, '/tmp/final_stitched.jpg');
    expect(finalResult.stitchedSizeLabel, '900 x 2100');
    expect(finalResult.pairs.single.summaryLabel, contains('91%'));
  });

  test(
    'copies a verified stitch preview into a durable OCR artifact',
    () async {
      final source = await _writeTempReceiptImage(
        _receiptSection(seed: 22, topTextOffset: 0),
        'copy_source',
      );

      final copy = await ReceiptImageProcessor.copyReceiptOcrArtifact(
        path: source.path,
        prefix: 'copy_test',
      );

      expect(copy, isNot(source.path));
      expect(await File(copy).exists(), isTrue);
      expect(await File(copy).length(), await source.length());
      await File(copy).delete();
    },
  );

  test(
    'manual overlap can stitch when automatic matching is uncertain',
    () async {
      final first = await _writeTempReceiptImage(
        _receiptSection(seed: 4, topTextOffset: 0),
        'manual_a',
      );
      final second = await _writeTempReceiptImage(
        _receiptSection(seed: 12, topTextOffset: 37),
        'manual_b',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
        manualOverlapPixels: const [260],
      );

      expect(result.didStitch, isTrue);
      expect(result.usedManualAdjustment, isTrue);
      expect(result.overlapPixels, [260]);
      expect(result.pairs.single.usedManualAdjustment, isTrue);
      expect(result.pairs.single.summaryLabel, contains('manual match'));
      expect(result.ocrSourcePaths, hasLength(1));
      expect(result.detailLabel, contains('Manual match was used'));
    },
  );

  test('manual overlap fraction can drive stitching from review UI', () async {
    final first = await _writeTempReceiptImage(
      _receiptSection(seed: 7, topTextOffset: 0),
      'manual_fraction_a',
    );
    final second = await _writeTempReceiptImage(
      _receiptSection(seed: 9, topTextOffset: 28),
      'manual_fraction_b',
    );

    final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
      paths: [first.path, second.path],
      manualOverlapFractions: const [.22],
    );

    expect(result.didStitch, isTrue);
    expect(result.usedManualAdjustment, isTrue);
    expect(result.overlapPixels.single, greaterThan(40));
    expect(result.ocrSourcePaths, hasLength(1));
  });

  test(
    'manual overlap falls back when the requested overlap is unsafe',
    () async {
      final first = await _writeTempReceiptImage(
        _receiptSection(seed: 5, topTextOffset: 0),
        'manual_bad_a',
      );
      final second = await _writeTempReceiptImage(
        _receiptSection(seed: 6, topTextOffset: 0),
        'manual_bad_b',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
        manualOverlapPixels: const [999999],
      );

      expect(result.usedFallback, isTrue);
      expect(result.warning, contains('outside the safe range'));
      expect(result.failedPairIndex, 0);
      expect(result.ocrSourcePaths, [first.path, second.path]);
    },
  );

  test('stitches overlapping receipt photo sections for OCR', () async {
    final sectionA = _receiptSection(seed: 0, topTextOffset: 0);
    final sectionB = _receiptSection(seed: 1, topTextOffset: 14);
    _copyOverlap(from: sectionA, to: sectionB, pixels: 320);

    final first = await _writeTempReceiptImage(sectionA, 'a');
    final second = await _writeTempReceiptImage(sectionB, 'b');

    final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
      paths: [first.path, second.path],
    );

    expect(result.didStitch, isTrue, reason: 'confidence ${result.confidence}');
    expect(result.ocrSourcePaths, hasLength(1));
    expect(result.overlapPixels.single, greaterThan(100));
    expect(result.pairs.single.pairIndex, 0);
    expect(result.pairs.single.confidence, greaterThanOrEqualTo(.50));
    expect(result.stitchedWidth, greaterThan(0));
    expect(result.stitchedHeight, greaterThan(0));
    expect(result.stitchedPixelCount, greaterThan(0));
    expect(result.confidence, greaterThanOrEqualTo(.50));
    expect(await File(result.ocrSourcePaths.single).exists(), isTrue);
  });

  test('stitches receipt sections when the next photo is closer', () async {
    final sectionA = _receiptSection(seed: 40, topTextOffset: 0);
    final sectionB = _receiptSection(seed: 41, topTextOffset: 18);
    _copyOverlap(from: sectionA, to: sectionB, pixels: 340);
    final closerSecond = _scaleShot(sectionB, scale: 1.12);

    final first = await _writeTempReceiptImage(sectionA, 'scale_close_a');
    final second = await _writeTempReceiptImage(closerSecond, 'scale_close_b');

    final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
      paths: [first.path, second.path],
    );

    expect(result.didStitch, isTrue, reason: result.detailLabel);
    expect(result.pairs.single.confidence, greaterThanOrEqualTo(.50));
    expect(result.ocrSourcePaths, hasLength(1));
  });

  test(
    'stitches receipt sections when the next photo is farther away',
    () async {
      final sectionA = _receiptSection(seed: 50, topTextOffset: 0);
      final sectionB = _receiptSection(seed: 51, topTextOffset: 18);
      _copyOverlap(from: sectionA, to: sectionB, pixels: 340);
      final fartherSecond = _scaleShot(sectionB, scale: .90);

      final first = await _writeTempReceiptImage(sectionA, 'scale_far_a');
      final second = await _writeTempReceiptImage(fartherSecond, 'scale_far_b');

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.pairs.single.confidence, greaterThanOrEqualTo(.50));
      expect(result.ocrSourcePaths, hasLength(1));
    },
  );

  test('stitches receipt sections with slight handheld rotation', () async {
    final sectionA = _receiptSection(seed: 60, topTextOffset: 0);
    final sectionB = _receiptSection(seed: 61, topTextOffset: 18);
    _copyOverlap(from: sectionA, to: sectionB, pixels: 340);
    final rotatedSecond = _rotateShot(sectionB, degrees: 1.2);

    final first = await _writeTempReceiptImage(sectionA, 'rotate_a');
    final second = await _writeTempReceiptImage(rotatedSecond, 'rotate_b');

    final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
      paths: [first.path, second.path],
    );

    expect(result.didStitch, isTrue, reason: result.detailLabel);
    expect(result.pairs.single.confidence, greaterThanOrEqualTo(.50));
    expect(result.pairs.single.summaryLabel, contains('%'));
    expect(result.ocrSourcePaths, hasLength(1));
  });

  test(
    'falls back with output dimensions when receipt would be too large',
    () async {
      final sectionA = _receiptSection(seed: 30, topTextOffset: 0);
      final sectionB = _receiptSection(seed: 31, topTextOffset: 14);
      _copyOverlap(from: sectionA, to: sectionB, pixels: 320);

      final first = await _writeTempReceiptImage(sectionA, 'too_large_a');
      final second = await _writeTempReceiptImage(sectionB, 'too_large_b');

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
        maxOutputHeight: 100,
      );

      expect(result.usedFallback, isTrue);
      expect(result.warning, contains('too long'));
      expect(result.stitchedWidth, greaterThan(0));
      expect(result.stitchedHeight, greaterThan(100));
      expect(result.pairs.single.confidence, greaterThanOrEqualTo(.50));
    },
  );

  test(
    'falls back to separate OCR photos when overlap confidence is low',
    () async {
      final first = await _writeTempReceiptImage(
        _receiptSection(seed: 4, topTextOffset: 0),
        'fallback_a',
      );
      final second = await _writeTempReceiptImage(
        _blankDarkPhotoSection(),
        'fallback_b',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
      );

      expect(
        result.usedFallback,
        isTrue,
        reason: 'confidence ${result.confidence}',
      );
      expect(result.ocrSourcePaths, [first.path, second.path]);
      expect(result.failedPairIndex, 0);
      expect(result.warning, isNotEmpty);
      expect(result.pairs, hasLength(1));
      expect(result.pairs.single.confidence, lessThan(.50));
      expect(result.pairs.single.summaryLabel, contains('Photo 1 to 2'));
    },
  );
}

img.Image _receiptSection({required int seed, required int topTextOffset}) {
  final image = img.Image(width: 900, height: 1500, numChannels: 3);
  img.fill(image, color: img.ColorRgb8(248, 248, 244));
  for (var y = 80 + topTextOffset; y < 1420; y += 54) {
    final lineWidth = 540 + ((y + seed * 31) % 260);
    final xStart = 72 + ((y + seed * 17) % 36);
    img.fillRect(
      image,
      x1: xStart,
      y1: y,
      x2: (xStart + lineWidth).clamp(0, image.width - 1),
      y2: y + 8,
      color: img.ColorRgb8(25, 25, 25),
    );
    if (y % 3 == 0) {
      img.fillRect(
        image,
        x1: 680,
        y1: y,
        x2: 815,
        y2: y + 8,
        color: img.ColorRgb8(25, 25, 25),
      );
    }
    for (var index = 0; index < 12; index++) {
      final x = 96 + ((index * 57 + y * 3 + seed * 41) % 680);
      final width = 10 + ((index * 11 + y + seed * 13) % 34);
      final height = 10 + ((index * 7 + seed) % 16);
      final shade = 20 + ((index * 19 + seed * 29 + y) % 70);
      img.fillRect(
        image,
        x1: x,
        y1: (y + 14 + (index % 4) * 8).clamp(0, image.height - 1),
        x2: (x + width).clamp(0, image.width - 1),
        y2: (y + 14 + (index % 4) * 8 + height).clamp(0, image.height - 1),
        color: img.ColorRgb8(shade, shade, shade),
      );
    }
  }
  return image;
}

img.Image _blankDarkPhotoSection() {
  final image = img.Image(width: 900, height: 1500, numChannels: 3);
  img.fill(image, color: img.ColorRgb8(36, 38, 40));
  return image;
}

void _copyOverlap({
  required img.Image from,
  required img.Image to,
  required int pixels,
}) {
  final overlap = img.copyCrop(
    from,
    x: 0,
    y: from.height - pixels,
    width: from.width,
    height: pixels,
  );
  img.compositeImage(to, overlap, dstX: 0, dstY: 0);
}

img.Image _scaleShot(img.Image source, {required double scale}) {
  final scaledWidth = (source.width * scale).round();
  final scaled = img.copyResize(source, width: scaledWidth);
  if (scaled.width > source.width) {
    final cropX = ((scaled.width - source.width) / 2).round();
    return img.copyCrop(
      scaled,
      x: cropX,
      y: 0,
      width: source.width,
      height: math.min(source.height, scaled.height),
    );
  }
  final canvas = img.Image(
    width: source.width,
    height: source.height,
    numChannels: 3,
  );
  img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
  img.compositeImage(
    canvas,
    scaled,
    dstX: ((source.width - scaled.width) / 2).round(),
    dstY: 0,
  );
  return canvas;
}

img.Image _rotateShot(img.Image source, {required double degrees}) {
  final rotated = img.copyRotate(
    source,
    angle: degrees,
    interpolation: img.Interpolation.linear,
  );
  if (rotated.width >= source.width && rotated.height >= source.height) {
    return img.copyCrop(
      rotated,
      x: ((rotated.width - source.width) / 2).round(),
      y: ((rotated.height - source.height) / 2).round(),
      width: source.width,
      height: source.height,
    );
  }
  final canvas = img.Image(
    width: source.width,
    height: source.height,
    numChannels: 3,
  );
  img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
  img.compositeImage(
    canvas,
    rotated,
    dstX: ((source.width - rotated.width) / 2).round(),
    dstY: ((source.height - rotated.height) / 2).round(),
  );
  return canvas;
}

Future<File> _writeTempReceiptImage(img.Image image, String name) async {
  final file = File(
    '${Directory.systemTemp.path}/maintainiac_receipt_stitch_$name.jpg',
  );
  await file.writeAsBytes(img.encodeJpg(image, quality: 94), flush: true);
  return file;
}
