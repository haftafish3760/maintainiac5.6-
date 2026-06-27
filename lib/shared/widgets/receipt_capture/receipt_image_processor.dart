import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import 'receipt_capture_models.dart';

class ReceiptPreparedImage {
  const ReceiptPreparedImage({
    required this.ocrSourcePath,
    required this.backupPath,
    required this.dataSaverLevel,
    required this.quality,
  });

  final String ocrSourcePath;
  final String backupPath;
  final ReceiptDataSaverLevel dataSaverLevel;
  final ReceiptPhotoQualityCheck quality;

  bool get usesSeparateBackupCopy => backupPath != ocrSourcePath;
}

class ReceiptImageProcessor {
  ReceiptImageProcessor._();

  static Future<String> prepareReceiptSourceFile({required String path}) async {
    final bytes = await File(path).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return path;
    final baseline = _resizeToMaxSide(decoded, 2600);
    var processed = _autoCropReceipt(decoded);
    processed = _autoStraightenReceipt(processed);
    processed = _enhanceReceiptForReading(processed);
    final safe = _bestReceiptOcrSource([baseline, processed]);
    if (identical(safe, baseline)) {
      final alreadyBounded =
          decoded.width == baseline.width && decoded.height == baseline.height;
      if (alreadyBounded) {
        return copyReceiptOcrArtifact(path: path, prefix: 'ocr_original');
      }
    }
    return _writeJpg(safe, prefix: 'enhanced', quality: 94);
  }

  static Future<ReceiptPreparedImage> prepareForOcrAndBackup({
    required String path,
    required ReceiptDataSaverLevel level,
  }) async {
    final ocrSourcePath = await prepareReceiptSourceFile(path: path);
    final backupPath = await optimizeFile(path: ocrSourcePath, level: level);
    final quality = await qualityCheckFile(ocrSourcePath);
    return ReceiptPreparedImage(
      ocrSourcePath: ocrSourcePath,
      backupPath: backupPath,
      dataSaverLevel: level,
      quality: quality,
    );
  }

  static Future<ReceiptImageStoragePreview> previewPreparedBackupFile({
    required String path,
    required ReceiptDataSaverLevel level,
  }) async {
    final ocrSourcePath = await prepareReceiptSourceFile(path: path);
    try {
      return await previewFile(path: ocrSourcePath, level: level);
    } finally {
      if (ocrSourcePath != path) {
        await _deleteFileQuietly(ocrSourcePath);
      }
    }
  }

  static Future<String> optimizePreparedBackupFile({
    required String path,
    required ReceiptDataSaverLevel level,
  }) async {
    final ocrSourcePath = await prepareReceiptSourceFile(path: path);
    final backupPath = await optimizeFile(path: ocrSourcePath, level: level);
    if (ocrSourcePath != path && backupPath != ocrSourcePath) {
      await _deleteFileQuietly(ocrSourcePath);
    }
    return backupPath;
  }

  static Future<String> cropFile({
    required Uint8List bytes,
    required Rect displayImageRect,
    required Rect cropRect,
  }) async {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw StateError('Image could not be decoded.');
    final relativeCrop = Rect.fromLTRB(
      cropRect.left - displayImageRect.left,
      cropRect.top - displayImageRect.top,
      cropRect.right - displayImageRect.left,
      cropRect.bottom - displayImageRect.top,
    );
    final scaleX = decoded.width / displayImageRect.width;
    final scaleY = decoded.height / displayImageRect.height;
    final x = (relativeCrop.left * scaleX).round().clamp(0, decoded.width - 1);
    final y = (relativeCrop.top * scaleY).round().clamp(0, decoded.height - 1);
    final right = (relativeCrop.right * scaleX).round().clamp(
      x + 1,
      decoded.width,
    );
    final bottom = (relativeCrop.bottom * scaleY).round().clamp(
      y + 1,
      decoded.height,
    );
    final cropped = img.copyCrop(
      decoded,
      x: x,
      y: y,
      width: right - x,
      height: bottom - y,
    );
    return _writeJpg(cropped, prefix: 'crop', quality: 92);
  }

  static Future<String> rotateFile({
    required String path,
    required num degrees,
  }) async {
    final bytes = await File(path).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw StateError('Image could not be decoded.');
    final rotated = img.copyRotate(
      decoded,
      angle: degrees,
      interpolation: img.Interpolation.linear,
    );
    return _writeJpg(rotated, prefix: 'straightened', quality: 92);
  }

  static Future<String> copyReceiptOcrArtifact({
    required String path,
    String prefix = 'stitched_final',
  }) async {
    final source = File(path);
    final target = File(
      '${Directory.systemTemp.path}/maintaniac_receipt_${prefix}_'
      '${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await source.copy(target.path);
    return target.path;
  }

  static Future<void> _deleteFileQuietly(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Temporary receipt preview artifacts are best-effort cleanup.
    }
  }

  static Future<String> optimizeFile({
    required String path,
    required ReceiptDataSaverLevel level,
  }) async {
    if (level == ReceiptDataSaverLevel.original) return path;
    final bytes = await File(path).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return path;
    final profile = _profileFor(level);
    var output = _resizeToMaxSide(decoded, profile.maxLongSide);
    if (profile.grayscale) {
      output = img.grayscale(output);
      output = img.contrast(output, contrast: profile.contrast);
    }
    return _writeJpg(output, prefix: 'optimized', quality: profile.quality);
  }

  static Future<ReceiptImageStoragePreview> previewFile({
    required String path,
    required ReceiptDataSaverLevel level,
  }) async {
    final file = File(path);
    final originalBytes = await file.length();
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return ReceiptImageStoragePreview(
        originalBytes: originalBytes,
        estimatedBytes: originalBytes,
        level: level,
        quality: const ReceiptPhotoQualityCheck(
          width: 0,
          height: 0,
          focusScore: 0,
          isLikelyReadable: false,
        ),
      );
    }
    final profile = _profileFor(level);
    var output = _resizeToMaxSide(decoded, profile.maxLongSide);
    if (profile.grayscale) {
      output = img.grayscale(output);
      output = img.contrast(output, contrast: profile.contrast);
    }
    final estimatedBytes = level == ReceiptDataSaverLevel.original
        ? originalBytes
        : img.encodeJpg(output, quality: profile.quality).length;
    return ReceiptImageStoragePreview(
      originalBytes: originalBytes,
      estimatedBytes: estimatedBytes,
      level: level,
      quality: _qualityCheck(output),
    );
  }

  static Future<ReceiptPhotoQualityCheck> qualityCheckFile(String path) async {
    final bytes = await File(path).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return const ReceiptPhotoQualityCheck(
        width: 0,
        height: 0,
        focusScore: 0,
        isLikelyReadable: false,
      );
    }
    return _qualityCheck(decoded);
  }

  static Future<ReceiptStitchResult> stitchReceiptPhotosForOcr({
    required List<String> paths,
    List<int>? manualOverlapPixels,
    List<double>? manualOverlapFractions,
    int maxOutputPixels = 16000000,
    int maxOutputHeight = 20000,
  }) async {
    final inputPaths = paths
        .map((path) => path.trim())
        .where((path) => path.isNotEmpty)
        .toList(growable: false);
    if (inputPaths.length <= 1) {
      return ReceiptStitchResult.notNeeded(inputPaths);
    }

    final decoded = <img.Image>[];
    try {
      for (final path in inputPaths) {
        final bytes = await File(path).readAsBytes();
        final image = img.decodeImage(bytes);
        if (image == null) {
          return ReceiptStitchResult.fallback(
            inputPaths: inputPaths,
            warning: 'One receipt photo could not be read.',
          );
        }
        decoded.add(_enhanceReceiptForReading(_autoStraightenReceipt(image)));
      }

      final targetWidth = _stitchTargetWidth(decoded.length);
      final prepared = decoded
          .map((image) => _resizeToWidth(_autoCropReceipt(image), targetWidth))
          .toList(growable: false);
      final normalized = <img.Image>[prepared.first];
      var expectedHeight = normalized.first.height;
      final overlaps = <int>[];
      final confidences = <double>[];
      final pairResults = <ReceiptStitchPairResult>[];

      for (var index = 1; index < prepared.length; index++) {
        final pairIndex = index - 1;
        final previous = normalized[pairIndex];
        final manualOverlap = _manualOverlapFor(
          previous: previous,
          next: prepared[index],
          pairIndex: pairIndex,
          manualOverlapPixels: manualOverlapPixels,
          manualOverlapFractions: manualOverlapFractions,
        );
        if (manualOverlap != null) {
          final maxManualOverlap =
              math.min(previous.height, prepared[index].height) - 24;
          if (manualOverlap < 24 || manualOverlap > maxManualOverlap) {
            return ReceiptStitchResult.fallback(
              inputPaths: inputPaths,
              warning: 'Manual receipt overlap was outside the safe range.',
              failedPairIndex: pairIndex,
              pairs: pairResults,
            );
          }
          overlaps.add(manualOverlap);
          confidences.add(1);
          pairResults.add(
            ReceiptStitchPairResult(
              pairIndex: pairIndex,
              overlapPixels: manualOverlap,
              confidence: 1,
              usedManualAdjustment: true,
            ),
          );
          normalized.add(prepared[index]);
          expectedHeight += prepared[index].height - manualOverlap;
        } else {
          final match = _bestScaleTolerantVerticalOverlap(
            previous: previous,
            next: prepared[index],
            targetWidth: targetWidth,
          );
          if (!match.isConfident) {
            final failedPair = ReceiptStitchPairResult(
              pairIndex: pairIndex,
              overlapPixels: match.pixels,
              confidence: match.confidence,
              scaleCorrection: match.scaleCorrection,
              rotationCorrectionDegrees: match.rotationCorrectionDegrees,
            );
            return ReceiptStitchResult.fallback(
              inputPaths: inputPaths,
              warning:
                  'Receipt photos did not match clearly enough to stitch safely.',
              confidence: match.confidence,
              failedPairIndex: pairIndex,
              pairs: List.unmodifiable([...pairResults, failedPair]),
            );
          }
          overlaps.add(match.pixels);
          confidences.add(match.confidence);
          normalized.add(match.nextImage);
          pairResults.add(
            ReceiptStitchPairResult(
              pairIndex: pairIndex,
              overlapPixels: match.pixels,
              confidence: match.confidence,
              scaleCorrection: match.scaleCorrection,
              rotationCorrectionDegrees: match.rotationCorrectionDegrees,
            ),
          );
          expectedHeight += match.nextImage.height - match.pixels;
        }
      }

      final expectedPixels = targetWidth * expectedHeight;
      if (expectedHeight > maxOutputHeight ||
          expectedPixels > maxOutputPixels) {
        return ReceiptStitchResult.fallback(
          inputPaths: inputPaths,
          warning:
              'Receipt is too long to stitch safely on this device. Next will review the photos separately.',
          confidence: confidences.isEmpty ? 0 : confidences.reduce(math.min),
          pairs: pairResults,
          stitchedWidth: targetWidth,
          stitchedHeight: expectedHeight,
        );
      }

      final canvas = img.Image(
        width: targetWidth,
        height: expectedHeight,
        numChannels: 3,
      );
      img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
      var y = 0;
      img.compositeImage(canvas, normalized.first, dstX: 0, dstY: y);
      y += normalized.first.height;
      for (var index = 1; index < normalized.length; index++) {
        y -= overlaps[index - 1];
        img.compositeImage(canvas, normalized[index], dstX: 0, dstY: y);
        y += normalized[index].height;
      }

      final path = await _writeJpg(canvas, prefix: 'stitched', quality: 88);
      final confidence = confidences.isEmpty
          ? 1.0
          : confidences.reduce(math.min);
      return ReceiptStitchResult(
        status: ReceiptStitchStatus.stitched,
        inputPaths: inputPaths,
        stitchedPath: path,
        ocrSourcePaths: [path],
        confidence: confidence,
        overlapPixels: overlaps,
        pairs: pairResults,
        stitchedWidth: targetWidth,
        stitchedHeight: expectedHeight,
        usedManualAdjustment:
            (manualOverlapPixels != null && manualOverlapPixels.isNotEmpty) ||
            (manualOverlapFractions != null &&
                manualOverlapFractions.isNotEmpty),
      );
    } catch (_) {
      return ReceiptStitchResult.fallback(
        inputPaths: inputPaths,
        warning:
            'Receipt photos could not be stitched safely. Next will review them separately.',
      );
    }
  }

  static img.Image _resizeToMaxSide(img.Image source, int maxLongSide) {
    final longSide = math.max(source.width, source.height);
    if (longSide <= maxLongSide) return source;
    if (source.width >= source.height) {
      return img.copyResize(source, width: maxLongSide);
    }
    return img.copyResize(source, height: maxLongSide);
  }

  static int _stitchTargetWidth(int photoCount) {
    if (photoCount <= 2) return 1400;
    if (photoCount <= 5) return 1200;
    if (photoCount <= 10) return 1000;
    return 820;
  }

  static img.Image _resizeToWidth(img.Image source, int width) {
    if (source.width == width) return source;
    return img.copyResize(source, width: width);
  }

  static _ReceiptOverlapMatch _bestScaleTolerantVerticalOverlap({
    required img.Image previous,
    required img.Image next,
    required int targetWidth,
  }) {
    const comparisonWidth = 620;
    final sampleWidth = math.min(
      comparisonWidth,
      math.min(previous.width, next.width),
    );
    final previousSample = previous.width == sampleWidth
        ? previous
        : img.copyResize(previous, width: sampleWidth);
    final nextSample = next.width == sampleWidth
        ? next
        : img.copyResize(next, width: sampleWidth);
    final candidates = <_ReceiptStitchCandidate>[];
    for (final scale in const [1.0, .94, 1.06, .88, 1.12, .82, 1.18]) {
      final candidateImage = _transformForStitchComparison(
        nextSample,
        targetWidth: sampleWidth,
        scale: scale,
        rotationDegrees: 0,
      );
      final match = _bestVerticalOverlap(
        previous: previousSample,
        next: candidateImage,
      );
      final scalePenalty = (scale - 1).abs() * .16;
      candidates.add(
        _ReceiptStitchCandidate(
          pixels: match.pixels,
          confidence: (match.confidence - scalePenalty).clamp(0.0, 1.0),
          scaleCorrection: scale,
          sampleHeight: candidateImage.height,
        ),
      );
    }
    candidates.sort((a, b) => b.confidence.compareTo(a.confidence));
    if (candidates.first.confidence >= .62) {
      return _materializeStitchCandidate(
        candidate: candidates.first,
        previousHeight: previous.height,
        next: next,
        targetWidth: targetWidth,
      );
    }

    final rotationCandidates = candidates.take(3).toList(growable: false);
    for (final base in rotationCandidates) {
      for (final rotationDegrees in const [-.8, .8, -1.4, 1.4]) {
        final candidateImage = _transformForStitchComparison(
          nextSample,
          targetWidth: sampleWidth,
          scale: base.scaleCorrection,
          rotationDegrees: rotationDegrees,
        );
        final match = _bestVerticalOverlap(
          previous: previousSample,
          next: candidateImage,
        );
        final scalePenalty = (base.scaleCorrection - 1).abs() * .16;
        final rotationPenalty = rotationDegrees.abs() * .025;
        candidates.add(
          _ReceiptStitchCandidate(
            pixels: match.pixels,
            confidence: (match.confidence - scalePenalty - rotationPenalty)
                .clamp(0.0, 1.0),
            scaleCorrection: base.scaleCorrection,
            rotationCorrectionDegrees: rotationDegrees,
            sampleHeight: candidateImage.height,
          ),
        );
      }
    }
    candidates.sort((a, b) => b.confidence.compareTo(a.confidence));
    return _materializeStitchCandidate(
      candidate: candidates.first,
      previousHeight: previous.height,
      next: next,
      targetWidth: targetWidth,
    );
  }

  static _ReceiptOverlapMatch _materializeStitchCandidate({
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
    return _ReceiptOverlapMatch(
      pixels: fullPixels,
      confidence: candidate.confidence,
      nextImage: nextImage,
      scaleCorrection: candidate.scaleCorrection,
      rotationCorrectionDegrees: candidate.rotationCorrectionDegrees,
    );
  }

  static img.Image _transformForStitchComparison(
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

  static img.Image _centerFitToWidth(img.Image source, int targetWidth) {
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

  static _ReceiptOverlapMatch _bestVerticalOverlap({
    required img.Image previous,
    required img.Image next,
  }) {
    final maxOverlap = math.min(previous.height, next.height) * .46;
    final minOverlap = math.min(previous.height, next.height) * .08;
    final minPixels = minOverlap.round().clamp(48, 320);
    final maxPixels = maxOverlap.round().clamp(minPixels + 1, 1400);
    var bestPixels = 0;
    var bestScore = double.infinity;
    var secondBestScore = double.infinity;
    for (var pixels = minPixels; pixels <= maxPixels; pixels += 12) {
      final score = _overlapDifference(
        previous: previous,
        next: next,
        pixels: pixels,
      );
      if (score < bestScore) {
        secondBestScore = bestScore;
        bestScore = score;
        bestPixels = pixels;
      } else if ((pixels - bestPixels).abs() > 36 && score < secondBestScore) {
        secondBestScore = score;
      }
    }
    final refinedStart = (bestPixels - 18).clamp(minPixels, maxPixels);
    final refinedEnd = (bestPixels + 18).clamp(minPixels, maxPixels);
    for (var pixels = refinedStart; pixels <= refinedEnd; pixels += 3) {
      final score = _overlapDifference(
        previous: previous,
        next: next,
        pixels: pixels,
      );
      if (score < bestScore) {
        secondBestScore = bestScore;
        bestScore = score;
        bestPixels = pixels;
      } else if ((pixels - bestPixels).abs() > 36 && score < secondBestScore) {
        secondBestScore = score;
      }
    }
    final visualConfidence = (1 - (bestScore / 64)).clamp(0.0, 1.0);
    final distinctiveness = secondBestScore.isFinite
        ? ((secondBestScore - bestScore) / 32).clamp(0.0, 1.0)
        : 1.0;
    final confidence = visualConfidence * (.55 + (.45 * distinctiveness));
    return _ReceiptOverlapMatch(
      pixels: bestPixels,
      confidence: confidence,
      nextImage: next,
    );
  }

  static int? _manualOverlapFor({
    required img.Image previous,
    required img.Image next,
    required int pairIndex,
    required List<int>? manualOverlapPixels,
    required List<double>? manualOverlapFractions,
  }) {
    if (manualOverlapPixels != null && pairIndex < manualOverlapPixels.length) {
      return manualOverlapPixels[pairIndex];
    }
    if (manualOverlapFractions != null &&
        pairIndex < manualOverlapFractions.length) {
      final fraction = manualOverlapFractions[pairIndex];
      if (fraction <= 0) return null;
      final shortest = math.min(previous.height, next.height);
      return (shortest * fraction).round();
    }
    return null;
  }

  static double _overlapDifference({
    required img.Image previous,
    required img.Image next,
    required int pixels,
  }) {
    final sampleWidth = math.min(previous.width, next.width);
    final stepX = math.max(8, (sampleWidth / 64).round());
    final stepY = math.max(4, (pixels / 36).round());
    var lumaTotal = 0.0;
    var lumaSamples = 0;
    var rowProfileTotal = 0.0;
    var rowProfileSamples = 0;
    final previousStartY = previous.height - pixels;
    for (var y = 0; y < pixels; y += stepY) {
      var previousInk = 0;
      var nextInk = 0;
      var rowSamples = 0;
      for (var x = sampleWidth ~/ 10; x < sampleWidth * 9 ~/ 10; x += stepX) {
        final a = _luma(previous.getPixel(x, previousStartY + y));
        final b = _luma(next.getPixel(x, y));
        lumaTotal += (a - b).abs();
        lumaSamples++;
        if (a < 160) previousInk++;
        if (b < 160) nextInk++;
        rowSamples++;
      }
      if (rowSamples > 0) {
        final previousRatio = previousInk / rowSamples;
        final nextRatio = nextInk / rowSamples;
        rowProfileTotal += (previousRatio - nextRatio).abs() * 74;
        rowProfileSamples++;
      }
    }
    if (lumaSamples == 0) return double.infinity;
    final lumaAverage = lumaTotal / lumaSamples;
    final rowProfileAverage = rowProfileSamples == 0
        ? double.infinity
        : rowProfileTotal / rowProfileSamples;
    return (lumaAverage * .62) + (rowProfileAverage * .38);
  }

  static img.Image _autoCropReceipt(img.Image source) {
    final bounds = _findReceiptContentBounds(source);
    if (bounds == null) return source;
    final minUsefulArea = source.width * source.height * .18;
    if (bounds.width * bounds.height < minUsefulArea) return source;
    if (!_receiptBoundsLookSafe(source, bounds)) return source;
    final padX = (bounds.width * .045).round().clamp(18, 160);
    final padY = (bounds.height * .035).round().clamp(18, 180);
    final x = (bounds.left - padX).round().clamp(0, source.width - 1);
    final y = (bounds.top - padY).round().clamp(0, source.height - 1);
    final right = (bounds.right + padX).round().clamp(x + 1, source.width);
    final bottom = (bounds.bottom + padY).round().clamp(y + 1, source.height);
    final cropped = img.copyCrop(
      source,
      x: x,
      y: y,
      width: right - x,
      height: bottom - y,
    );
    final sourceQuality = _qualityCheck(source);
    final cropQuality = _qualityCheck(cropped);
    final cropKeepsText =
        cropQuality.textBandScore >= sourceQuality.textBandScore * .90 &&
        cropQuality.contrast >= sourceQuality.contrast * .68;
    final cropImprovesFraming =
        cropQuality.cropScore >= sourceQuality.cropScore;
    if (cropQuality.reviewScore + 2 < sourceQuality.reviewScore ||
        !cropKeepsText ||
        !cropImprovesFraming) {
      return source;
    }
    return cropped;
  }

  static bool _receiptBoundsLookSafe(
    img.Image source,
    _ReceiptImageBounds bounds,
  ) {
    final widthRatio = bounds.width / source.width;
    final heightRatio = bounds.height / source.height;
    if (widthRatio < .34 || heightRatio < .34) return false;
    final aspect = bounds.height / math.max(1, bounds.width);
    if (aspect < .55 || aspect > 9.5) return false;
    final centerX = (bounds.left + bounds.right) / 2;
    final centerY = (bounds.top + bounds.bottom) / 2;
    final xOffset = ((centerX / source.width) - .5).abs();
    final yOffset = ((centerY / source.height) - .5).abs();
    if (widthRatio < .72 && xOffset > .28) return false;
    if (heightRatio < .72 && yOffset > .30) return false;
    return true;
  }

  static _ReceiptImageBounds? _findReceiptContentBounds(img.Image source) {
    final sample = _resizeToMaxSide(source, 420);
    final scaleX = source.width / sample.width;
    final scaleY = source.height / sample.height;
    final paperBounds = _scanReceiptBounds(sample, paperOnly: true);
    final bounds = paperBounds?.hitCount != null && paperBounds!.hitCount >= 120
        ? paperBounds
        : _scanReceiptBounds(sample, paperOnly: false);
    if (bounds == null ||
        bounds.hitCount < 120 ||
        bounds.right <= bounds.left ||
        bounds.bottom <= bounds.top) {
      return null;
    }
    return _ReceiptImageBounds(
      left: bounds.left * scaleX,
      top: bounds.top * scaleY,
      right: bounds.right * scaleX,
      bottom: bounds.bottom * scaleY,
      hitCount: bounds.hitCount,
    );
  }

  static _ReceiptImageBounds? _scanReceiptBounds(
    img.Image sample, {
    required bool paperOnly,
  }) {
    var left = sample.width.toDouble();
    var top = sample.height.toDouble();
    var right = 0.0;
    var bottom = 0.0;
    var hits = 0;
    for (var y = 1; y < sample.height - 1; y += 2) {
      for (var x = 1; x < sample.width - 1; x += 2) {
        final luma = _luma(sample.getPixel(x, y));
        final leftDelta = (luma - _luma(sample.getPixel(x - 1, y))).abs();
        final upDelta = (luma - _luma(sample.getPixel(x, y - 1))).abs();
        final darkInk = luma < 170 && leftDelta + upDelta > 18;
        final receiptPaper = luma > 188;
        if (paperOnly) {
          if (!receiptPaper) continue;
        } else if (!darkInk && !(receiptPaper && leftDelta + upDelta > 8)) {
          continue;
        }
        hits++;
        if (x < left) left = x.toDouble();
        if (x > right) right = x.toDouble();
        if (y < top) top = y.toDouble();
        if (y > bottom) bottom = y.toDouble();
      }
    }
    return _ReceiptImageBounds(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      hitCount: hits,
    );
  }

  static img.Image _autoStraightenReceipt(img.Image source) {
    final sourceQuality = _qualityCheck(source);
    var bestDegrees = 0.0;
    var bestScore = sourceQuality.reviewScore;
    final reviewSource = _resizeToMaxSide(source, 760);
    for (final degrees in const [-2.0, -1.25, -.65, .65, 1.25, 2.0]) {
      final candidate = img.copyRotate(
        reviewSource,
        angle: degrees,
        interpolation: img.Interpolation.linear,
      );
      final score = _qualityCheck(candidate).reviewScore;
      if (score > bestScore) {
        bestScore = score;
        bestDegrees = degrees;
      }
    }
    if (bestDegrees.abs() < .5 || bestScore < sourceQuality.reviewScore + 3) {
      return source;
    }
    final rotated = img.copyRotate(
      source,
      angle: bestDegrees,
      interpolation: img.Interpolation.linear,
    );
    final rotatedQuality = _qualityCheck(rotated);
    if (rotatedQuality.reviewScore + 1 < sourceQuality.reviewScore ||
        rotatedQuality.textBandScore < sourceQuality.textBandScore * .92) {
      return source;
    }
    return rotated;
  }

  static img.Image _enhanceReceiptForReading(img.Image source) {
    final base = _resizeToMaxSide(source, 2600);
    final quality = _qualityCheck(base);
    final candidates = <img.Image>[
      _basicReceiptEnhancement(base, quality),
      _adaptiveExposureReceiptEnhancement(base, quality),
      _thermalReceiptEnhancement(base, quality),
      _shadowBalancedEnhancement(base, quality),
    ];
    if (quality.isLowContrast || quality.textBandScore < 8) {
      candidates.add(_fadedReceiptEnhancement(base, quality));
    }
    if (quality.isSoft || quality.focusScore < 11) {
      candidates.add(_mildTextSharpen(candidates.last));
    }

    var best = candidates.first;
    var bestQuality = _qualityCheck(best);
    for (final candidate in candidates.skip(1)) {
      final candidateQuality = _qualityCheck(candidate);
      if (_enhancementScore(candidateQuality) >
          _enhancementScore(bestQuality)) {
        best = candidate;
        bestQuality = candidateQuality;
      }
    }
    final baseScore = _enhancementScore(quality);
    final bestScore = _enhancementScore(bestQuality);
    if (bestQuality.reviewScore < quality.reviewScore ||
        bestQuality.textBandScore < quality.textBandScore ||
        bestQuality.contrast < quality.contrast * .72 ||
        bestScore + 2 < baseScore) {
      return base;
    }
    return best;
  }

  static img.Image _bestReceiptOcrSource(List<img.Image> candidates) {
    var best = candidates.first;
    var bestQuality = _qualityCheck(best);
    for (final candidate in candidates.skip(1)) {
      final quality = _qualityCheck(candidate);
      final preservesText =
          quality.textBandScore >= bestQuality.textBandScore &&
          quality.contrast >= bestQuality.contrast * .72 &&
          quality.reviewScore >= bestQuality.reviewScore * .85;
      final substantiallyImprovesReceiptLines =
          quality.textBandScore >= bestQuality.textBandScore + 4 &&
          quality.contrast >= bestQuality.contrast * .55 &&
          quality.reviewScore >= math.max(50, bestQuality.reviewScore * .55);
      final scoreBeatsCurrent =
          _enhancementScore(quality) >= _enhancementScore(bestQuality);
      if ((preservesText && scoreBeatsCurrent) ||
          substantiallyImprovesReceiptLines) {
        best = candidate;
        bestQuality = quality;
      }
    }
    return best;
  }

  static img.Image _basicReceiptEnhancement(
    img.Image source,
    ReceiptPhotoQualityCheck quality,
  ) {
    var output = source;
    if (quality.isTooDark) {
      output = img.adjustColor(output, brightness: 1.16, gamma: .92);
    } else if (quality.isTooBright) {
      output = img.adjustColor(output, brightness: .90, gamma: 1.06);
    }
    output = img.grayscale(output);
    output = img.normalize(output, min: 8, max: 248);
    return img.contrast(output, contrast: quality.isLowContrast ? 1.35 : 1.18);
  }

  static img.Image _thermalReceiptEnhancement(
    img.Image source,
    ReceiptPhotoQualityCheck quality,
  ) {
    var output = img.grayscale(source);
    output = img.adjustColor(
      output,
      brightness: quality.isTooDark ? 1.18 : .98,
      gamma: quality.isTooBright ? 1.12 : .86,
      contrast: quality.isLowContrast ? 1.42 : 1.24,
    );
    output = img.normalize(output, min: 18, max: 238);
    return _mildTextSharpen(output);
  }

  static img.Image _adaptiveExposureReceiptEnhancement(
    img.Image source,
    ReceiptPhotoQualityCheck quality,
  ) {
    var output = img.grayscale(source);
    final exposure = _receiptExposureCurve(output);
    final targetMid = quality.isTooDark
        ? 158
        : quality.isTooBright
        ? 136
        : 148;
    final currentMid = exposure.midpoint.clamp(1.0, 254.0);
    final brightnessFactor = (targetMid / currentMid).clamp(.72, 1.42);
    final gamma = quality.isTooDark
        ? .78
        : quality.isTooBright
        ? 1.16
        : exposure.isShadowHeavy
        ? .86
        : .94;
    output = img.adjustColor(
      output,
      brightness: brightnessFactor,
      gamma: gamma,
      contrast: quality.isLowContrast ? 1.34 : 1.18,
    );
    output = _balanceReceiptRows(output, targetBrightness: targetMid);
    output = img.normalize(
      output,
      min: exposure.blackPoint.round().clamp(0, 48),
      max: exposure.whitePoint.round().clamp(206, 255),
    );
    return _mildTextSharpen(output);
  }

  static _ReceiptExposureCurve _receiptExposureCurve(img.Image source) {
    final sample = _resizeToMaxSide(source, 520);
    final values = <int>[];
    final stepX = math.max(1, sample.width ~/ 140);
    final stepY = math.max(1, sample.height ~/ 180);
    for (var y = 0; y < sample.height; y += stepY) {
      for (var x = 0; x < sample.width; x += stepX) {
        values.add(_luma(sample.getPixel(x, y)).round().clamp(0, 255));
      }
    }
    if (values.isEmpty) {
      return const _ReceiptExposureCurve(
        blackPoint: 8,
        midpoint: 148,
        whitePoint: 246,
        shadowShare: 0,
        highlightShare: 0,
      );
    }
    values.sort();
    int percentile(double value) {
      final index = (values.length * value).floor().clamp(0, values.length - 1);
      return values[index];
    }

    final shadows = values.where((value) => value < 82).length / values.length;
    final highlights =
        values.where((value) => value > 226).length / values.length;
    return _ReceiptExposureCurve(
      blackPoint: percentile(.03).toDouble(),
      midpoint: percentile(.50).toDouble(),
      whitePoint: percentile(.97).toDouble(),
      shadowShare: shadows,
      highlightShare: highlights,
    );
  }

  static img.Image _balanceReceiptRows(
    img.Image source, {
    required int targetBrightness,
  }) {
    final output = img.Image.from(source);
    final sampleStep = math.max(1, output.width ~/ 54);
    for (var y = 0; y < output.height; y++) {
      var rowTotal = 0.0;
      var rowCount = 0;
      for (var x = 0; x < output.width; x += sampleStep) {
        rowTotal += _luma(output.getPixel(x, y));
        rowCount++;
      }
      if (rowCount == 0) continue;
      final rowBrightness = rowTotal / rowCount;
      final lift = (targetBrightness - rowBrightness).clamp(-38.0, 46.0);
      if (lift.abs() < 5) continue;
      for (var x = 0; x < output.width; x++) {
        final pixel = output.getPixel(x, y);
        final current = _luma(pixel);
        final preserveInk = current < 92 && lift > 0;
        final adjustedLift = preserveInk ? lift * .38 : lift;
        final value = (current + adjustedLift).round().clamp(0, 255);
        pixel
          ..r = value
          ..g = value
          ..b = value;
      }
    }
    return output;
  }

  static img.Image _fadedReceiptEnhancement(
    img.Image source,
    ReceiptPhotoQualityCheck quality,
  ) {
    var output = img.grayscale(source);
    output = img.adjustColor(
      output,
      brightness: quality.brightness < 150 ? 1.10 : .96,
      gamma: .78,
      contrast: 1.55,
    );
    output = img.normalize(output, min: 28, max: 232);
    return _mildTextSharpen(output);
  }

  static img.Image _shadowBalancedEnhancement(
    img.Image source,
    ReceiptPhotoQualityCheck quality,
  ) {
    final output = img.grayscale(source);
    final sampleStep = math.max(1, output.width ~/ 40);
    for (var y = 0; y < output.height; y++) {
      var rowTotal = 0.0;
      var rowCount = 0;
      for (var x = 0; x < output.width; x += sampleStep) {
        rowTotal += _luma(output.getPixel(x, y));
        rowCount++;
      }
      if (rowCount == 0) continue;
      final rowBrightness = rowTotal / rowCount;
      final lift = (quality.brightness - rowBrightness).clamp(-28.0, 34.0);
      if (lift.abs() < 4) continue;
      for (var x = 0; x < output.width; x++) {
        final pixel = output.getPixel(x, y);
        final value = (pixel.r + lift).round().clamp(0, 255);
        pixel
          ..r = value
          ..g = value
          ..b = value;
      }
    }
    final normalized = img.normalize(output, min: 12, max: 244);
    return img.contrast(
      normalized,
      contrast: quality.isLowContrast ? 1.36 : 1.18,
    );
  }

  static img.Image _mildTextSharpen(img.Image source) {
    return img.convolution(
      source,
      filter: const [0, -1, 0, -1, 5, -1, 0, -1, 0],
      amount: .34,
    );
  }

  static double _enhancementScore(ReceiptPhotoQualityCheck quality) {
    final lightPenalty = quality.isTooDark || quality.isTooBright ? 10 : 0;
    return quality.reviewScore +
        (quality.textBandScore * 1.9) +
        (quality.contrast.clamp(0, 42) * .38) +
        (quality.focusScore.clamp(0, 18) * .42) -
        lightPenalty;
  }

  static _DataSaverProfile _profileFor(ReceiptDataSaverLevel level) {
    return switch (level) {
      ReceiptDataSaverLevel.original => const _DataSaverProfile(
        maxLongSide: 4096,
        quality: 96,
        grayscale: false,
        contrast: 100,
      ),
      ReceiptDataSaverLevel.light => const _DataSaverProfile(
        maxLongSide: 2200,
        quality: 82,
        grayscale: false,
        contrast: 100,
      ),
      ReceiptDataSaverLevel.balanced => const _DataSaverProfile(
        maxLongSide: 1600,
        quality: 72,
        grayscale: true,
        contrast: 110,
      ),
      ReceiptDataSaverLevel.strong => const _DataSaverProfile(
        maxLongSide: 1200,
        quality: 62,
        grayscale: true,
        contrast: 115,
      ),
      ReceiptDataSaverLevel.maximum => const _DataSaverProfile(
        maxLongSide: 900,
        quality: 52,
        grayscale: true,
        contrast: 125,
      ),
    };
  }

  static ReceiptPhotoQualityCheck _qualityCheck(img.Image source) {
    final sample = _resizeToMaxSide(source, 320);
    var totalDelta = 0.0;
    var sum = 0.0;
    var sumSquares = 0.0;
    var centerInk = 0;
    var outerInk = 0;
    final rowDarkCounts = <int>[];
    var count = 0;
    for (var y = 1; y < sample.height; y += 2) {
      var rowDark = 0;
      for (var x = 1; x < sample.width; x += 2) {
        final current = sample.getPixel(x, y);
        final left = sample.getPixel(x - 1, y);
        final up = sample.getPixel(x, y - 1);
        final currentLuma = _luma(current);
        sum += currentLuma;
        sumSquares += currentLuma * currentLuma;
        totalDelta += (currentLuma - _luma(left)).abs();
        totalDelta += (currentLuma - _luma(up)).abs();
        if (currentLuma < 148) {
          rowDark++;
          final centered =
              x > sample.width * .12 &&
              x < sample.width * .88 &&
              y > sample.height * .08 &&
              y < sample.height * .92;
          if (centered) {
            centerInk++;
          } else {
            outerInk++;
          }
        }
        count += 2;
      }
      rowDarkCounts.add(rowDark);
    }
    final focusScore = count == 0 ? 0.0 : totalDelta / count;
    final sampleCount = (count / 2).round();
    final brightness = sampleCount == 0 ? 0.0 : sum / sampleCount;
    final variance = sampleCount == 0
        ? 0.0
        : (sumSquares / sampleCount) - brightness * brightness;
    final contrast = variance <= 0 ? 0.0 : math.sqrt(variance);
    final inkTotal = centerInk + outerInk;
    final cropScore = inkTotal == 0 ? 0.0 : centerInk / inkTotal;
    final textBandScore = _textBandScore(rowDarkCounts);
    final enoughResolution = source.width >= 900 && source.height >= 900;
    final readableLight = brightness >= 68 && brightness <= 224;
    final readableContrast = contrast >= 16;
    final readableCrop = cropScore >= .30;
    final readableLines = textBandScore >= 6;
    return ReceiptPhotoQualityCheck(
      width: source.width,
      height: source.height,
      focusScore: focusScore,
      brightness: brightness,
      contrast: contrast,
      cropScore: cropScore,
      textBandScore: textBandScore,
      isLikelyReadable:
          enoughResolution &&
          focusScore >= 8 &&
          readableLight &&
          readableContrast &&
          readableCrop &&
          readableLines,
    );
  }

  static double _textBandScore(List<int> rowDarkCounts) {
    if (rowDarkCounts.isEmpty) return 0;
    final sortedCounts = [...rowDarkCounts]..sort();
    final strongRowSample =
        sortedCounts[(sortedCounts.length * .90).floor().clamp(
          0,
          sortedCounts.length - 1,
        )];
    final threshold = math.max(4, (strongRowSample * .28).round());
    var bands = 0;
    var inBand = false;
    for (final darkCount in rowDarkCounts) {
      final hasText = darkCount >= threshold;
      if (hasText && !inBand) bands++;
      inBand = hasText;
    }
    return bands.toDouble().clamp(0, 18);
  }

  static double _luma(img.Pixel pixel) {
    return pixel.r * .299 + pixel.g * .587 + pixel.b * .114;
  }

  static Future<String> _writeJpg(
    img.Image image, {
    required String prefix,
    required int quality,
  }) async {
    final file = File(
      '${Directory.systemTemp.path}/maintaniac_receipt_${prefix}_'
      '${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await file.writeAsBytes(
      img.encodeJpg(image, quality: quality),
      flush: true,
    );
    return file.path;
  }
}

class _DataSaverProfile {
  const _DataSaverProfile({
    required this.maxLongSide,
    required this.quality,
    required this.grayscale,
    required this.contrast,
  });

  final int maxLongSide;
  final int quality;
  final bool grayscale;
  final num contrast;
}

class _ReceiptImageBounds {
  const _ReceiptImageBounds({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    this.hitCount = 0,
  });

  final double left;
  final double top;
  final double right;
  final double bottom;
  final int hitCount;

  double get width => right - left;
  double get height => bottom - top;
}

class _ReceiptOverlapMatch {
  const _ReceiptOverlapMatch({
    required this.pixels,
    required this.confidence,
    required this.nextImage,
    this.scaleCorrection = 1,
    this.rotationCorrectionDegrees = 0,
  });

  final int pixels;
  final double confidence;
  final img.Image nextImage;
  final double scaleCorrection;
  final double rotationCorrectionDegrees;

  bool get isConfident => pixels > 0 && confidence >= .50;
}

class _ReceiptExposureCurve {
  const _ReceiptExposureCurve({
    required this.blackPoint,
    required this.midpoint,
    required this.whitePoint,
    required this.shadowShare,
    required this.highlightShare,
  });

  final double blackPoint;
  final double midpoint;
  final double whitePoint;
  final double shadowShare;
  final double highlightShare;

  bool get isShadowHeavy => shadowShare > .18 && highlightShare < .20;
}

class _ReceiptStitchCandidate {
  const _ReceiptStitchCandidate({
    required this.pixels,
    required this.confidence,
    required this.scaleCorrection,
    required this.sampleHeight,
    this.rotationCorrectionDegrees = 0,
  });

  final int pixels;
  final double confidence;
  final double scaleCorrection;
  final int sampleHeight;
  final double rotationCorrectionDegrees;
}
