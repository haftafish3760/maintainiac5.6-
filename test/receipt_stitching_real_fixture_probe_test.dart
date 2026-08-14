import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_stitch_acceptance.dart';

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

      final workload = _realProbeWorkload();
      final textEvidence = _realProbeTextEvidence(paths);
      final stopwatch = Stopwatch()..start();
      final result = await _runRealProbe(paths, workload, textEvidence);
      stopwatch.stop();

      final evidence = _realProbeEvidence(
        result,
        workload: workload,
        textEvidence: textEvidence,
        elapsed: stopwatch.elapsed,
      );
      // Stable, privacy-safe output for local QA automation. It deliberately
      // excludes paths, receipt text, merchant names, and financial values.
      // ignore: avoid_print
      print('RECEIPT_STITCH_PROBE_RESULT=${jsonEncode(evidence)}');
      _expectRealProbeOutcome(result, paths);
      for (final pair in result.pairs) {
        final hasHighTrustPositionedText = hasHighTrustPositionedReceiptOverlap(
          visualConfidence: pair.visualConfidence,
          textConfidence: pair.textOverlapConfidence,
          matchedTextLineCount: pair.matchedTextLineCount,
          hasTextPositionEvidence: pair.hasTextPositionEvidence,
          textPositionalConfidence: pair.textPositionalConfidence,
        );
        if (hasHighTrustPositionedText) {
          if (pair.selectedSeamCropPixels < pair.seamSkipPixels) {
            expect(pair.nextContinuationTextStart, greaterThan(0));
            expect(
              pair.nextContinuationTextEnd,
              greaterThan(pair.nextContinuationTextStart),
              reason:
                  'An earlier seam is safe only when positioned OCR proves a complete continuation band to preserve.',
            );
          }
        }
      }
      await _copyRealProbeOutputWhenRequested(result, evidence);
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

Future<ReceiptStitchResult> _runRealProbe(
  List<String> paths,
  _RealProbeWorkload workload,
  List<ReceiptStitchTextEvidence>? textEvidence,
) {
  return ReceiptImageProcessor.stitchReceiptPhotosForOcr(
    paths: paths,
    textEvidence: textEvidence,
    maxOutputPixels: workload.maxOutputPixels,
    maxOutputHeight: workload.maxOutputHeight,
    maxTargetWidth: workload.maxTargetWidth,
    comparisonWidth: workload.comparisonWidth,
    retryComparisonWidth: workload.retryComparisonWidth,
    processingTimeout: workload.processingTimeout,
  );
}

Future<void> _copyRealProbeOutputWhenRequested(
  ReceiptStitchResult result,
  Map<String, Object?> evidence,
) async {
  final outputPath = Platform.environment['RECEIPT_STITCH_REAL_OUTPUT_PATH']
      ?.trim();
  final stitchedPath = result.stitchedPath;
  if (outputPath == null || outputPath.isEmpty) return;
  final outputFile = File(outputPath);
  await outputFile.parent.create(recursive: true);
  if (stitchedPath != null && stitchedPath.isNotEmpty) {
    await File(stitchedPath).copy(outputFile.path);
  }
  await File(
    '$outputPath.json',
  ).writeAsString(const JsonEncoder.withIndent('  ').convert(evidence));
}

Map<String, Object?> _realProbeEvidence(
  ReceiptStitchResult result, {
  required _RealProbeWorkload workload,
  required List<ReceiptStitchTextEvidence>? textEvidence,
  required Duration elapsed,
}) {
  return <String, Object?>{
    'schema': 1,
    'status': result.status.name,
    'elapsedMs': elapsed.inMilliseconds,
    'inputCount': result.inputPaths.length,
    'didStitch': result.didStitch,
    'fallbackReason': result.fallbackReasonCode,
    'failedPair': result.failedPairIndex == null
        ? null
        : result.failedPairIndex! + 1,
    'confidence': result.confidence,
    'stitchedWidth': result.stitchedWidth,
    'stitchedHeight': result.stitchedHeight,
    'requiresReview': result.requiresOcrSourceReviewBeforeAssistedRead,
    'ocrSourceContract': result.ocrSourceContractCode,
    'workload': workload.toJson(),
    'textEvidence': <String, Object>{
      'source': textEvidence == null ? 'none' : 'local_sidecar',
      'nonEmptySections':
          textEvidence?.where((item) => item.lines.isNotEmpty).length ?? 0,
      'lineCounts': <int>[
        for (final item in textEvidence ?? const <ReceiptStitchTextEvidence>[])
          item.lines.length,
      ],
    },
    'pairs': <Map<String, Object?>>[
      for (final pair in result.pairs)
        <String, Object?>{
          'pair': pair.pairIndex + 1,
          'overlapPixels': pair.overlapPixels,
          'seamSkipPixels': pair.seamSkipPixels,
          'selectedSeamCropPixels': pair.selectedSeamCropPixels,
          'confidence': pair.confidence,
          'scale': pair.scaleCorrection,
          'rotationDegrees': pair.rotationCorrectionDegrees,
          'perspective': pair.perspectiveCorrection,
          'horizontalOffsetPixels': pair.horizontalOffsetPixels,
          'verticalOffsetPixels': pair.verticalOffsetPixels,
          'visualConfidence': pair.visualConfidence,
          'continuityCorrelation': pair.continuityCorrelation,
          'continuityBands': pair.continuityMatchingBands,
          'continuityDetailedBands': pair.continuityDetailedBands,
          'geometryCorrelation': pair.geometryCorrelation,
          'geometryCells': pair.geometryMatchingCells,
          'geometryDetailedCells': pair.geometryDetailedCells,
          'textOverlapConfidence': pair.textOverlapConfidence,
          'matchedTextLineCount': pair.matchedTextLineCount,
          'textPositionalConfidence': pair.textPositionalConfidence,
          'hasTextPositionEvidence': pair.hasTextPositionEvidence,
          'previousTextOverlapStart': pair.previousTextOverlapStart,
          'nextTextOverlapEnd': pair.nextTextOverlapEnd,
          'nextContinuationTextStart': pair.nextContinuationTextStart,
          'nextContinuationTextEnd': pair.nextContinuationTextEnd,
          'diagnosticCode': pair.diagnosticCode,
        },
    ],
  };
}

List<ReceiptStitchTextEvidence>? _realProbeTextEvidence(List<String> paths) {
  final evidencePath = Platform
      .environment['RECEIPT_STITCH_REAL_TEXT_EVIDENCE_PATH']
      ?.trim();
  if (evidencePath == null || evidencePath.isEmpty) return null;
  final file = File(evidencePath);
  if (!file.existsSync()) {
    throw StateError('Missing local stitch text-evidence sidecar.');
  }
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! List || decoded.length != paths.length) {
    throw const FormatException(
      'Stitch text-evidence sidecar must contain one line array per photo.',
    );
  }
  return <ReceiptStitchTextEvidence>[
    for (var index = 0; index < paths.length; index++)
      _decodeRealProbeTextEvidence(paths[index], decoded[index]),
  ];
}

ReceiptStitchTextEvidence _decodeRealProbeTextEvidence(
  String path,
  Object? value,
) {
  if (value is List) {
    return ReceiptStitchTextEvidence(
      path: path,
      lines: <String>[
        for (final line in value)
          if (line is String && line.trim().isNotEmpty) line.trim(),
      ],
    );
  }
  if (value is! Map<String, dynamic>) {
    throw const FormatException(
      'Every stitch text-evidence entry must be a line array or positioned '
      'evidence object.',
    );
  }
  final positioned = <ReceiptStitchTextLineEvidence>[
    for (final raw in value['positionedLines'] as List? ?? const [])
      if (raw is Map<String, dynamic>)
        ReceiptStitchTextLineEvidence(
          text: (raw['text'] as String? ?? '').trim(),
          left: (raw['left'] as num?)?.toDouble() ?? 0,
          top: (raw['top'] as num?)?.toDouble() ?? 0,
          right: (raw['right'] as num?)?.toDouble() ?? 1,
          bottom: (raw['bottom'] as num?)?.toDouble() ?? 0,
          angleDegrees: (raw['angleDegrees'] as num?)?.toDouble() ?? 0,
        ),
  ]..removeWhere((line) => line.text.isEmpty);
  return ReceiptStitchTextEvidence(
    path: path,
    lines: positioned.map((line) => line.text).toList(growable: false),
    positionedLines: positioned,
  );
}

_RealProbeWorkload _realProbeWorkload() {
  final requestedTier =
      (Platform.environment['RECEIPT_STITCH_REAL_TIER'] ?? 'medium')
          .trim()
          .toLowerCase();
  final capability = switch (requestedTier) {
    'light' || 'older' || 'low' => ReceiptDeviceCapability.olderPhone(),
    'heavy' ||
    'high' ||
    'flagship' => const ReceiptDeviceCapability.highCapacity(),
    _ => const ReceiptDeviceCapability.standard(),
  };
  final limits = capability.stitchLimits;
  return _RealProbeWorkload(
    tier: capability.tier.name,
    maxOutputPixels: _intEnv(
      'RECEIPT_STITCH_REAL_MAX_OUTPUT_PIXELS',
      limits.maxOutputPixels,
    ),
    maxOutputHeight: _intEnv(
      'RECEIPT_STITCH_REAL_MAX_OUTPUT_HEIGHT',
      limits.maxOutputHeight,
    ),
    maxTargetWidth: _intEnv(
      'RECEIPT_STITCH_REAL_MAX_TARGET_WIDTH',
      limits.maxTargetWidth,
    ),
    comparisonWidth: _intEnv(
      'RECEIPT_STITCH_REAL_COMPARISON_WIDTH',
      limits.comparisonWidth,
    ),
    retryComparisonWidth: _intEnv(
      'RECEIPT_STITCH_REAL_RETRY_WIDTH',
      limits.retryComparisonWidth,
    ),
    processingTimeout: Duration(
      milliseconds: _intEnv(
        'RECEIPT_STITCH_REAL_TIMEOUT_MS',
        limits.processingTimeout.inMilliseconds,
      ),
    ),
  );
}

class _RealProbeWorkload {
  const _RealProbeWorkload({
    required this.tier,
    required this.maxOutputPixels,
    required this.maxOutputHeight,
    required this.maxTargetWidth,
    required this.comparisonWidth,
    required this.retryComparisonWidth,
    required this.processingTimeout,
  });

  final String tier;
  final int maxOutputPixels;
  final int maxOutputHeight;
  final int maxTargetWidth;
  final int comparisonWidth;
  final int retryComparisonWidth;
  final Duration processingTimeout;

  Map<String, Object> toJson() => <String, Object>{
    'tier': tier,
    'maxOutputPixels': maxOutputPixels,
    'maxOutputHeight': maxOutputHeight,
    'maxTargetWidth': maxTargetWidth,
    'comparisonWidth': comparisonWidth,
    'retryComparisonWidth': retryComparisonWidth,
    'processingTimeoutMs': processingTimeout.inMilliseconds,
  };
}

void _expectRealProbeOutcome(ReceiptStitchResult result, List<String> paths) {
  if (_strictRealProbeStitchExpected()) {
    expect(result.didStitch, isTrue, reason: result.detailLabel);
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
