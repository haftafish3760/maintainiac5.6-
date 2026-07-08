import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import 'receipt_capture_models.dart';
import 'receipt_photo_path_identity.dart';

part 'receipt_image_processor_models.dart';
part 'receipt_image_processor_source_prep.dart';
part 'receipt_image_processor_resize_helpers.dart';
part 'receipt_image_processor_stitch_helpers.dart';
part 'receipt_image_processor_stitch_scoring_helpers.dart';
part 'receipt_image_processor_stitch_api.dart';
part 'receipt_image_processor_scan_helpers.dart';
part 'receipt_image_processor_enhancement_helpers.dart';
part 'receipt_image_processor_exposure_helpers.dart';
part 'receipt_image_processor_quality_helpers.dart';
part 'receipt_image_processor_storage_helpers.dart';

class ReceiptImageProcessor {
  ReceiptImageProcessor._();

  static Future<String> prepareReceiptSourceFile({
    required String path,
    ReceiptImageCleanupSettings cleanupSettings =
        const ReceiptImageCleanupSettings(),
  }) async {
    return (await prepareReceiptSourceWithReport(
      path: path,
      cleanupSettings: cleanupSettings,
    )).ocrSourcePath;
  }

  static Future<ReceiptImagePreparationReport> prepareReceiptSourceWithReport({
    required String path,
    ReceiptImageCleanupSettings cleanupSettings =
        const ReceiptImageCleanupSettings(),
  }) async {
    return _prepareReceiptSourceWithReport(
      path: path,
      cleanupSettings: cleanupSettings,
    );
  }

  static Future<ReceiptPreparedImage> prepareForOcrAndBackup({
    required String path,
    required ReceiptDataSaverLevel level,
    ReceiptImageCleanupSettings cleanupSettings =
        const ReceiptImageCleanupSettings(),
  }) async {
    return _prepareForOcrAndBackup(
      path: path,
      level: level,
      cleanupSettings: cleanupSettings,
    );
  }

  static Future<ReceiptImageStoragePreview> previewPreparedBackupFile({
    required String path,
    required ReceiptDataSaverLevel level,
    ReceiptImageCleanupSettings cleanupSettings =
        const ReceiptImageCleanupSettings(),
  }) async {
    return _previewPreparedBackupFile(
      path: path,
      level: level,
      cleanupSettings: cleanupSettings,
    );
  }

  static Future<String> optimizePreparedBackupFile({
    required String path,
    required ReceiptDataSaverLevel level,
    ReceiptImageCleanupSettings cleanupSettings =
        const ReceiptImageCleanupSettings(),
  }) async {
    return _optimizePreparedBackupFile(
      path: path,
      level: level,
      cleanupSettings: cleanupSettings,
    );
  }

  static Future<String> cropFile({
    required Uint8List bytes,
    required Rect displayImageRect,
    required Rect cropRect,
  }) async {
    final decoded = _decodeImage(bytes);
    if (decoded == null) throw StateError('Image could not be decoded.');
    if (!_isUsableCropRect(displayImageRect) || !_isUsableCropRect(cropRect)) {
      throw StateError('Crop bounds are not usable.');
    }
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

  static bool _isUsableCropRect(Rect rect) {
    return rect.left.isFinite &&
        rect.top.isFinite &&
        rect.right.isFinite &&
        rect.bottom.isFinite &&
        rect.width > 0 &&
        rect.height > 0;
  }

  static Future<String> rotateFile({
    required String path,
    required num degrees,
  }) async {
    if (!degrees.isFinite) {
      throw StateError('Rotation angle is not usable.');
    }
    final bytes = await _readFileBytes(path);
    final decoded = bytes == null ? null : _decodeImage(bytes);
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
    return _copyReceiptOcrArtifact(path: path, prefix: prefix);
  }

  static Future<void> _deleteFileQuietly(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Temporary receipt preview artifacts are best-effort cleanup.
    }
  }

  static const _unreadableReceiptQuality = ReceiptPhotoQualityCheck(
    width: 0,
    height: 0,
    focusScore: 0,
    isLikelyReadable: false,
  );

  static Future<Uint8List?> _readFileBytes(String path) async {
    try {
      return await File(path).readAsBytes();
    } on FileSystemException {
      return null;
    }
  }

  static img.Image? _decodeImage(Uint8List bytes) {
    try {
      return bytes.isEmpty ? null : img.decodeImage(bytes);
    } on FormatException {
      return null;
    } on RangeError {
      return null;
    }
  }

  static ReceiptImagePreparationReport _unreadableReceiptSourceReport({
    required String path,
    required String action,
    required String code,
  }) {
    return ReceiptImagePreparationReport(
      sourcePath: path,
      ocrSourcePath: path,
      originalQuality: _unreadableReceiptQuality,
      ocrQuality: _unreadableReceiptQuality,
      cleanupActions: [action],
      usedEnhancedOcrSource: false,
      scannerDecisionCodes: [code],
    );
  }

  static Future<String> optimizeFile({
    required String path,
    required ReceiptDataSaverLevel level,
  }) async {
    return _optimizeFile(path: path, level: level);
  }

  static Future<ReceiptImageStoragePreview> previewFile({
    required String path,
    required ReceiptDataSaverLevel level,
  }) async {
    return _previewFile(path: path, level: level);
  }

  static Future<ReceiptPhotoQualityCheck> qualityCheckFile(String path) async {
    return _qualityCheckFile(path);
  }

  static img.Image? decodeReceiptImageBytes(Uint8List bytes) {
    return _decodeImage(bytes);
  }

  static Future<ReceiptStitchResult> stitchReceiptPhotosForOcr({
    required List<String> paths,
    List<int>? manualOverlapPixels,
    List<double>? manualOverlapFractions,
    int maxOutputPixels = 16000000,
    int maxOutputHeight = 20000,
  }) async {
    return _stitchReceiptPhotosForOcr(
      paths: paths,
      manualOverlapPixels: manualOverlapPixels,
      manualOverlapFractions: manualOverlapFractions,
      maxOutputPixels: maxOutputPixels,
      maxOutputHeight: maxOutputHeight,
    );
  }
}
