import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

import 'helpers/receipt_stitching_image_helpers.dart';

const _phoneWindowTimeout = Timeout(Duration(minutes: 2));

void main() {
  test(
    'keeps skipped phone-window middle section review-required',
    () async {
      final files = await _writeSkippedPhoneWindowStack(
        'skipped_phone_window_middle',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [for (final file in files) file.path],
      );

      expectSkippedWindowRequiresReview(result, files);
    },
    timeout: _phoneWindowTimeout,
  );

  test(
    'keeps out-of-order phone-window sections review-required',
    () async {
      final files = await _writeOutOfOrderPhoneWindowStack(
        'out_of_order_phone_window',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [for (final file in files) file.path],
      );

      expectSkippedWindowRequiresReview(result, files);
    },
    timeout: _phoneWindowTimeout,
  );

  test(
    'preflights eleven-section phone window stacks at compact width',
    () async {
      final files = await _writeElevenSectionPhoneWindowStack(
        'eleven_section_compact_width',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [for (final file in files) file.path],
        maxOutputPixels: 500000,
      );

      expect(result.usedFallback, isTrue, reason: result.detailLabel);
      expect(result.fallbackReasonCode, 'output_too_large');
      expect(result.stitchedWidth, 820);
      expect(result.pairs, isEmpty);
      expect(result.stitchedPath, isNull);
      expect(result.ocrSourcePaths, [for (final file in files) file.path]);
    },
    timeout: _phoneWindowTimeout,
  );

  test(
    'stitches ugly seven-section phone-window receipt stack',
    () async {
      final files = await _writeUglySevenSectionPhoneWindowStack(
        'ugly_seven_phone_window',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [for (final file in files) file.path],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.pairs, hasLength(6));
      expect(result.overlapPixels, hasLength(6));
      expect(
        result.pairs.map((pair) => pair.confidence),
        everyElement(greaterThanOrEqualTo(.50)),
      );
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
      expect(result.ocrSourcePaths, [result.stitchedPath]);
      expect(result.stitchedPixelCount, lessThan(16000000));
    },
    timeout: _phoneWindowTimeout,
  );

  test(
    'stitches ragged phone-window captures from uneven scroll positions',
    () async {
      final files = await _writeRaggedPhoneWindowStack(
        'ragged_phone_window_overlap',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [for (final file in files) file.path],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.pairs, hasLength(4));
      expect(result.overlapPixels, hasLength(4));
      expect(
        result.pairs.map((pair) => pair.confidence),
        everyElement(greaterThanOrEqualTo(.50)),
      );
      expect(result.overlapPixelTotal, greaterThan(1200));
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
      expect(result.ocrSourcePaths, [result.stitchedPath]);
    },
    timeout: _phoneWindowTimeout,
  );

  test(
    'stitches tight-overlap phone-window captures without dropping lines',
    () async {
      final files = await _writeTightOverlapPhoneWindowStack(
        'tight_overlap_phone_window',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [for (final file in files) file.path],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.pairs, hasLength(4));
      expect(result.overlapPixels, hasLength(4));
      expect(
        result.pairs.map((pair) => pair.confidence),
        everyElement(greaterThanOrEqualTo(.50)),
      );
      expect(result.overlapPixelTotal, greaterThan(780));
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
      expect(result.ocrSourcePaths, [result.stitchedPath]);
    },
    timeout: _phoneWindowTimeout,
  );

  test(
    'stitches phone-screen receipt windows with dark display borders',
    () async {
      final files = await _writeDarkBorderPhoneWindowStack(
        'dark_border_phone_window',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [for (final file in files) file.path],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.pairs, hasLength(3));
      expect(result.overlapPixels, hasLength(3));
      expect(
        result.pairs.map((pair) => pair.confidence),
        everyElement(greaterThanOrEqualTo(.50)),
      );
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
      expect(result.ocrSourcePaths, [result.stitchedPath]);
    },
    timeout: _phoneWindowTimeout,
  );

  test(
    'stitches uploaded phone screenshots with status and nav bars',
    () async {
      final files = await _writePhoneScreenshotWindowStack(
        'phone_screenshot_window',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [for (final file in files) file.path],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.pairs, hasLength(3));
      expect(result.overlapPixels, hasLength(3));
      expect(
        result.pairs.map((pair) => pair.confidence),
        everyElement(greaterThanOrEqualTo(.50)),
      );
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
      expect(result.ocrSourcePaths, [result.stitchedPath]);
    },
    timeout: _phoneWindowTimeout,
  );
}

void expectSkippedWindowRequiresReview(
  ReceiptStitchResult result,
  List<File> files,
) {
  expect(
    result.requiresOcrSourceReviewBeforeAssistedRead,
    isTrue,
    reason: result.detailLabel,
  );
  expect(
    result.assistedReadinessCode,
    isNot('stitched_overlap_verified_ready'),
  );
  if (result.didStitch) {
    expect(result.hasLowConfidenceAutomaticOverlap, isTrue);
    expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
  } else {
    expect(result.usedFallback, isTrue, reason: result.detailLabel);
    expect(result.fallbackReasonCode, 'overlap_confidence_low');
    expect(result.ocrSourcePaths, [for (final file in files) file.path]);
  }
}

Future<List<File>> _writeSkippedPhoneWindowStack(String prefix) async {
  final tallReceipt = tallReceiptStitchingCanvas(sectionCount: 5);
  final starts = <int>[0, 1120, 3360, 4480];
  final captures = <img.Image>[];
  for (var index = 0; index < starts.length; index++) {
    final window = img.copyCrop(
      tallReceipt,
      x: 0,
      y: starts[index],
      width: tallReceipt.width,
      height: 1500,
    );
    final clipped = index.isEven
        ? clipReceiptStitchingSide(window, right: 38)
        : clipReceiptStitchingSide(window, left: 34);
    captures.add(
      shiftReceiptStitchingShot(clipped, dx: index.isEven ? 14 : -16, dy: 0),
    );
  }
  final files = <File>[];
  for (var index = 0; index < captures.length; index++) {
    files.add(
      await writeTempReceiptStitchingImage(captures[index], '${prefix}_$index'),
    );
  }
  return files;
}

Future<List<File>> _writeOutOfOrderPhoneWindowStack(String prefix) async {
  final tallReceipt = tallReceiptStitchingCanvas(sectionCount: 4);
  final starts = <int>[0, 2240, 1120, 3360];
  final files = <File>[];
  for (var index = 0; index < starts.length; index++) {
    var capture = img.copyCrop(
      tallReceipt,
      x: 0,
      y: starts[index],
      width: tallReceipt.width,
      height: 1500,
    );
    capture = shiftReceiptStitchingShot(
      capture,
      dx: index.isEven ? 18 : -16,
      dy: 0,
    );
    files.add(
      await writeTempReceiptStitchingImage(capture, '${prefix}_$index'),
    );
  }
  return files;
}

Future<List<File>> _writeElevenSectionPhoneWindowStack(String prefix) async {
  final files = <File>[];
  for (var index = 0; index < 11; index++) {
    final section = receiptStitchingSection(
      seed: 520 + index,
      topTextOffset: index * 7,
    );
    files.add(
      await writeTempReceiptStitchingImage(section, '${prefix}_$index'),
    );
  }
  return files;
}

Future<List<File>> _writeUglySevenSectionPhoneWindowStack(String prefix) async {
  final tallReceipt = tallReceiptStitchingCanvas(sectionCount: 7);
  final starts = <int>[0, 1120, 2240, 3360, 4480, 5600, 6720];
  final files = <File>[];
  for (var index = 0; index < starts.length; index++) {
    final window = img.copyCrop(
      tallReceipt,
      x: 0,
      y: starts[index],
      width: tallReceipt.width,
      height: 1500,
    );
    var capture = index.isEven
        ? clipReceiptStitchingSide(window, right: 36 + index * 2)
        : clipReceiptStitchingSide(window, left: 34 + index * 2);
    if (index == 2 || index == 5) {
      capture = fadeReceiptStitchingInk(capture, amount: .24);
    }
    if (index == 3) {
      capture = addReceiptStitchingWear(
        capture,
        seed: 730,
        wrinkleCount: 8,
        smudgeCount: 5,
      );
    }
    if (index == 4) {
      capture = adjustReceiptStitchingBrightness(capture, delta: -18);
    }
    capture = shiftReceiptStitchingShot(
      capture,
      dx: index.isEven ? 18 : -20,
      dy: 0,
    );
    files.add(
      await writeTempReceiptStitchingImage(capture, '${prefix}_$index'),
    );
  }
  return files;
}

Future<List<File>> _writeRaggedPhoneWindowStack(String prefix) async {
  final tallReceipt = tallReceiptStitchingCanvas(sectionCount: 5);
  final starts = <int>[0, 1040, 2195, 3290, 4485];
  final files = <File>[];
  for (var index = 0; index < starts.length; index++) {
    var capture = img.copyCrop(
      tallReceipt,
      x: 0,
      y: starts[index],
      width: tallReceipt.width,
      height: 1500,
    );
    capture = shiftReceiptStitchingShot(
      capture,
      dx: index.isEven ? 22 : -18,
      dy: 0,
    );
    if (index == 2) {
      capture = rotateReceiptStitchingShot(capture, degrees: .6);
    }
    if (index == 3) {
      capture = scaleReceiptStitchingShot(capture, scale: 1.04);
    }
    files.add(
      await writeTempReceiptStitchingImage(capture, '${prefix}_$index'),
    );
  }
  return files;
}

Future<List<File>> _writeTightOverlapPhoneWindowStack(String prefix) async {
  final tallReceipt = tallReceiptStitchingCanvas(sectionCount: 5);
  final starts = <int>[0, 1270, 2545, 3820, 5090];
  final files = <File>[];
  for (var index = 0; index < starts.length; index++) {
    var capture = img.copyCrop(
      tallReceipt,
      x: 0,
      y: starts[index],
      width: tallReceipt.width,
      height: 1500,
    );
    capture = shiftReceiptStitchingShot(
      capture,
      dx: index.isEven ? 16 : -18,
      dy: 0,
    );
    if (index == 2) {
      capture = fadeReceiptStitchingInk(capture, amount: .18);
    }
    if (index == 3) {
      capture = adjustReceiptStitchingBrightness(capture, delta: 18);
    }
    files.add(
      await writeTempReceiptStitchingImage(capture, '${prefix}_$index'),
    );
  }
  return files;
}

Future<List<File>> _writeDarkBorderPhoneWindowStack(String prefix) async {
  final tallReceipt = tallReceiptStitchingCanvas(sectionCount: 4);
  final starts = <int>[0, 1120, 2240, 3360];
  final files = <File>[];
  for (var index = 0; index < starts.length; index++) {
    var receiptWindow = img.copyCrop(
      tallReceipt,
      x: 0,
      y: starts[index],
      width: tallReceipt.width,
      height: 1500,
    );
    receiptWindow = shiftReceiptStitchingShot(
      receiptWindow,
      dx: index.isEven ? 12 : -14,
      dy: 0,
    );
    final capture = _wrapPhoneWindowWithDarkDisplayBorder(
      receiptWindow,
      left: index.isEven ? 74 : 58,
      top: index.isEven ? 42 : 66,
    );
    files.add(
      await writeTempReceiptStitchingImage(capture, '${prefix}_$index'),
    );
  }
  return files;
}

Future<List<File>> _writePhoneScreenshotWindowStack(String prefix) async {
  final tallReceipt = tallReceiptStitchingCanvas(sectionCount: 4);
  final starts = <int>[0, 1120, 2240, 3360];
  final files = <File>[];
  for (var index = 0; index < starts.length; index++) {
    var receiptWindow = img.copyCrop(
      tallReceipt,
      x: 0,
      y: starts[index],
      width: tallReceipt.width,
      height: 1500,
    );
    receiptWindow = shiftReceiptStitchingShot(
      receiptWindow,
      dx: index.isEven ? 10 : -12,
      dy: 0,
    );
    final capture = _wrapPhoneWindowWithDarkDisplayBorder(
      receiptWindow,
      left: index.isEven ? 70 : 60,
      top: index.isEven ? 76 : 84,
      includeSystemBars: true,
    );
    files.add(
      await writeTempReceiptStitchingImage(capture, '${prefix}_$index'),
    );
  }
  return files;
}

img.Image _wrapPhoneWindowWithDarkDisplayBorder(
  img.Image receiptWindow, {
  required int left,
  required int top,
  bool includeSystemBars = false,
}) {
  final canvas = img.Image(width: 1080, height: 1760, numChannels: 3);
  img.fill(canvas, color: img.ColorRgb8(12, 12, 14));
  if (includeSystemBars) {
    img.fillRect(
      canvas,
      x1: 0,
      y1: 0,
      x2: canvas.width,
      y2: 56,
      color: img.ColorRgb8(22, 22, 24),
    );
    img.fillRect(
      canvas,
      x1: 0,
      y1: canvas.height - 80,
      x2: canvas.width,
      y2: canvas.height,
      color: img.ColorRgb8(18, 18, 20),
    );
  }
  img.compositeImage(canvas, receiptWindow, dstX: left, dstY: top);
  return canvas;
}
