import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import 'receipt_capture_models.dart';

class ReceiptImageProcessor {
  ReceiptImageProcessor._();

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
      quality: _qualityCheck(decoded),
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

  static img.Image _resizeToMaxSide(img.Image source, int maxLongSide) {
    final longSide = math.max(source.width, source.height);
    if (longSide <= maxLongSide) return source;
    if (source.width >= source.height) {
      return img.copyResize(source, width: maxLongSide);
    }
    return img.copyResize(source, height: maxLongSide);
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
        maxLongSide: 2400,
        quality: 90,
        grayscale: false,
        contrast: 100,
      ),
      ReceiptDataSaverLevel.balanced => const _DataSaverProfile(
        maxLongSide: 1800,
        quality: 76,
        grayscale: true,
        contrast: 110,
      ),
      ReceiptDataSaverLevel.strong => const _DataSaverProfile(
        maxLongSide: 1400,
        quality: 68,
        grayscale: true,
        contrast: 115,
      ),
      ReceiptDataSaverLevel.maximum => const _DataSaverProfile(
        maxLongSide: 1000,
        quality: 56,
        grayscale: true,
        contrast: 125,
      ),
    };
  }

  static ReceiptPhotoQualityCheck _qualityCheck(img.Image source) {
    final sample = _resizeToMaxSide(source, 320);
    var totalDelta = 0.0;
    var count = 0;
    for (var y = 1; y < sample.height; y += 2) {
      for (var x = 1; x < sample.width; x += 2) {
        final current = sample.getPixel(x, y);
        final left = sample.getPixel(x - 1, y);
        final up = sample.getPixel(x, y - 1);
        final currentLuma = _luma(current);
        totalDelta += (currentLuma - _luma(left)).abs();
        totalDelta += (currentLuma - _luma(up)).abs();
        count += 2;
      }
    }
    final focusScore = count == 0 ? 0.0 : totalDelta / count;
    final enoughResolution = source.width >= 900 && source.height >= 900;
    return ReceiptPhotoQualityCheck(
      width: source.width,
      height: source.height,
      focusScore: focusScore,
      isLikelyReadable: enoughResolution && focusScore >= 8,
    );
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
