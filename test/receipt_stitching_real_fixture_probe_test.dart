import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

void main() {
  test(
    'real receipt probe stitches provided local receipt sections safely',
    () async {
      final paths = _realReceiptProbePaths();
      if (paths.length < 2) {
        markTestSkipped(
          'Set RECEIPT_STITCH_REAL_PATHS to two or more receipt image paths '
          'separated by | to run the local real-receipt stitch probe.',
        );
        return;
      }

      for (final path in paths) {
        expect(File(path).existsSync(), isTrue, reason: 'Missing $path');
      }

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: paths,
      );

      _expectRealProbeOutcome(result, paths);
      await _copyRealProbeOutputWhenRequested(result);
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );

  test(
    'real tall receipt probe crops local receipt windows before stitching',
    () async {
      final sourcePath = Platform.environment['RECEIPT_STITCH_REAL_TALL_IMAGE']
          ?.trim();
      if (sourcePath == null || sourcePath.isEmpty) {
        markTestSkipped(
          'Set RECEIPT_STITCH_REAL_TALL_IMAGE to a tall receipt image path '
          'to run the local tall-receipt window probe.',
        );
        return;
      }
      expect(File(sourcePath).existsSync(), isTrue, reason: sourcePath);
      final bytes = await File(sourcePath).readAsBytes();
      final source = img.decodeImage(bytes);
      expect(source, isNotNull, reason: sourcePath);

      final windowHeight = _intEnv('RECEIPT_STITCH_REAL_WINDOW_HEIGHT', 1500);
      final stride = _intEnv('RECEIPT_STITCH_REAL_WINDOW_STRIDE', 1120);
      final sectionPaths = await _writeTallReceiptWindows(
        source!,
        sourcePath: sourcePath,
        windowHeight: windowHeight,
        stride: stride,
      );
      expect(sectionPaths.length, greaterThanOrEqualTo(2));

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: sectionPaths,
      );

      _expectRealProbeOutcome(result, sectionPaths);
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );

  test(
    'real tall receipt matrix probes multiple crop windows in one run',
    () async {
      final sourcePath = Platform.environment['RECEIPT_STITCH_REAL_TALL_IMAGE']
          ?.trim();
      final configs = _realWindowMatrixConfigs();
      if (sourcePath == null || sourcePath.isEmpty || configs.isEmpty) {
        markTestSkipped(
          'Set RECEIPT_STITCH_REAL_TALL_IMAGE and '
          'RECEIPT_STITCH_REAL_WINDOW_MATRIX to run the local matrix probe.',
        );
        return;
      }
      expect(File(sourcePath).existsSync(), isTrue, reason: sourcePath);
      final bytes = await File(sourcePath).readAsBytes();
      final source = img.decodeImage(bytes);
      expect(source, isNotNull, reason: sourcePath);

      for (final config in configs) {
        final sectionPaths = await _writeTallReceiptWindows(
          source!,
          sourcePath: sourcePath,
          windowHeight: config.height,
          stride: config.stride,
        );
        expect(sectionPaths.length, greaterThanOrEqualTo(2));
        final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
          paths: sectionPaths,
        );
        _expectRealProbeOutcome(result, sectionPaths);
      }
    },
    timeout: const Timeout(Duration(minutes: 8)),
  );
}

Future<void> _copyRealProbeOutputWhenRequested(
  ReceiptStitchResult result,
) async {
  final outputPath = Platform.environment['RECEIPT_STITCH_REAL_OUTPUT_PATH']
      ?.trim();
  final stitchedPath = result.stitchedPath;
  if (outputPath == null || outputPath.isEmpty) return;
  if (stitchedPath != null && stitchedPath.isNotEmpty) {
    await File(stitchedPath).copy(outputPath);
  }
  await File('$outputPath.txt').writeAsString('''
status=${result.status.name}
fallbackReason=${result.fallbackReasonCode}
failedPair=${result.failedPairIndex}
confidence=${result.confidence}
overlapPixels=${result.overlapPixels.join(',')}
requiresReview=${result.requiresOcrSourceReviewBeforeAssistedRead}
${[
    for (final pair in result.pairs)
      'pair=${pair.pairIndex + 1} overlap=${pair.overlapPixels} '
          'confidence=${pair.confidence} scale=${pair.scaleCorrection} '
          'rotation=${pair.rotationCorrectionDegrees} '
          'perspective=${pair.perspectiveCorrection} '
          'x=${pair.horizontalOffsetPixels} y=${pair.verticalOffsetPixels} '
          'continuity=${pair.continuityCorrelation} '
          'bands=${pair.continuityMatchingBands}/${pair.continuityDetailedBands} '
          'text=${pair.textOverlapConfidence} lines=${pair.matchedTextLineCount}',
  ].join('\n')}
''');
}

void _expectRealProbeOutcome(ReceiptStitchResult result, List<String> paths) {
  if (_strictRealProbeStitchExpected()) {
    expect(result.didStitch, isTrue, reason: result.detailLabel);
    expect(result.requiresOcrSourceReviewBeforeAssistedRead, isFalse);
  }
  expect(result.inputPaths, paths);
  expect(result.ocrSourcePaths, isNotEmpty);
  expect(
    result.didStitch || result.requiresOcrSourceReviewBeforeAssistedRead,
    isTrue,
    reason: result.detailLabel,
  );
  if (result.didStitch) {
    expect(result.stitchedPath, isNotNull);
    expect(File(result.stitchedPath!).existsSync(), isTrue);
    expect(result.ocrSourcePaths, [result.stitchedPath]);
    expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
  } else {
    expect(result.usedFallback, isTrue, reason: result.detailLabel);
    expect(result.ocrSourcePaths, paths);
  }
}

bool _strictRealProbeStitchExpected() {
  final raw = Platform.environment['RECEIPT_STITCH_REAL_EXPECT'] ?? '';
  final normalized = raw.trim().toLowerCase();
  return normalized == 'stitched' ||
      normalized == 'stitch' ||
      normalized == 'true';
}

List<String> _realReceiptProbePaths() {
  final raw = Platform.environment['RECEIPT_STITCH_REAL_PATHS'];
  if (raw == null || raw.trim().isEmpty) return const [];
  return raw
      .split('|')
      .map((path) => path.trim())
      .where((path) => path.isNotEmpty)
      .toList(growable: false);
}

int _intEnv(String key, int fallback) {
  final raw = Platform.environment[key];
  final parsed = raw == null ? null : int.tryParse(raw.trim());
  return parsed == null || parsed <= 0 ? fallback : parsed;
}

List<_RealWindowMatrixConfig> _realWindowMatrixConfigs() {
  final raw = Platform.environment['RECEIPT_STITCH_REAL_WINDOW_MATRIX'];
  if (raw == null || raw.trim().isEmpty) return const [];
  return raw
      .split('|')
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty)
      .map(_RealWindowMatrixConfig.parse)
      .whereType<_RealWindowMatrixConfig>()
      .toList(growable: false);
}

class _RealWindowMatrixConfig {
  const _RealWindowMatrixConfig({required this.height, required this.stride});

  final int height;
  final int stride;

  static _RealWindowMatrixConfig? parse(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final height = int.tryParse(parts[0].trim());
    final stride = int.tryParse(parts[1].trim());
    if (height == null || stride == null || height <= 0 || stride <= 0) {
      return null;
    }
    return _RealWindowMatrixConfig(height: height, stride: stride);
  }
}

Future<List<String>> _writeTallReceiptWindows(
  img.Image source, {
  required String sourcePath,
  required int windowHeight,
  required int stride,
}) async {
  final safeHeight = windowHeight.clamp(320, source.height);
  final safeStride = stride.clamp(160, safeHeight - 24);
  final starts = <int>{0};
  for (var y = safeStride; y < source.height - safeHeight; y += safeStride) {
    starts.add(y);
  }
  starts.add((source.height - safeHeight).clamp(0, source.height));
  final baseName = sourcePath
      .split(Platform.pathSeparator)
      .last
      .replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
  final paths = <String>[];
  for (final entry in starts.toList()..sort()) {
    final window = img.copyCrop(
      source,
      x: 0,
      y: entry,
      width: source.width,
      height: safeHeight,
    );
    final file = File(
      '${Directory.systemTemp.path}/maintainiac_real_receipt_${baseName}_$entry.jpg',
    );
    await file.writeAsBytes(img.encodeJpg(window, quality: 94), flush: true);

    paths.add(file.path);
  }
  return paths;
}
