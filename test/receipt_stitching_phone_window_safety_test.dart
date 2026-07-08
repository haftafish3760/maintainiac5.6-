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
