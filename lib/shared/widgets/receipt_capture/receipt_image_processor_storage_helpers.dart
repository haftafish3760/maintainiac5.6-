part of 'receipt_image_processor.dart';

Future<ReceiptPreparedImage> _prepareForOcrAndBackup({
  required String path,
  required ReceiptDataSaverLevel level,
  required ReceiptImageCleanupSettings cleanupSettings,
}) async {
  final preparation =
      await ReceiptImageProcessor.prepareReceiptSourceWithReport(
        path: path,
        cleanupSettings: cleanupSettings,
      );
  final ocrSourcePath = preparation.ocrSourcePath;
  final backupPath = await ReceiptImageProcessor.optimizeFile(
    path: ocrSourcePath,
    level: level,
  );
  final quality = await ReceiptImageProcessor.qualityCheckFile(ocrSourcePath);
  return ReceiptPreparedImage(
    ocrSourcePath: ocrSourcePath,
    backupPath: backupPath,
    dataSaverLevel: level,
    quality: quality,
    preparation: preparation,
  );
}

Future<ReceiptImageStoragePreview> _previewPreparedBackupFile({
  required String path,
  required ReceiptDataSaverLevel level,
  required ReceiptImageCleanupSettings cleanupSettings,
}) async {
  final ocrSourcePath = await ReceiptImageProcessor.prepareReceiptSourceFile(
    path: path,
    cleanupSettings: cleanupSettings,
  );
  try {
    return await ReceiptImageProcessor.previewFile(
      path: ocrSourcePath,
      level: level,
    );
  } finally {
    if (ocrSourcePath != path) {
      await ReceiptImageProcessor._deleteFileQuietly(ocrSourcePath);
    }
  }
}

Future<String> _optimizePreparedBackupFile({
  required String path,
  required ReceiptDataSaverLevel level,
  required ReceiptImageCleanupSettings cleanupSettings,
}) async {
  final ocrSourcePath = await ReceiptImageProcessor.prepareReceiptSourceFile(
    path: path,
    cleanupSettings: cleanupSettings,
  );
  final backupPath = await ReceiptImageProcessor.optimizeFile(
    path: ocrSourcePath,
    level: level,
  );
  if (ocrSourcePath != path && backupPath != ocrSourcePath) {
    await ReceiptImageProcessor._deleteFileQuietly(ocrSourcePath);
  }
  return backupPath;
}

Future<String> _copyReceiptOcrArtifact({
  required String path,
  required String prefix,
}) async {
  final source = File(path);
  final target = File(
    '${Directory.systemTemp.path}/maintaniac_receipt_${prefix}_'
    '${DateTime.now().microsecondsSinceEpoch}.jpg',
  );
  await source.copy(target.path);
  return target.path;
}

Future<String> _optimizeFile({
  required String path,
  required ReceiptDataSaverLevel level,
}) async {
  if (level == ReceiptDataSaverLevel.original) return path;
  final decoded = await _readReceiptImageFile(path);
  if (decoded == null) return path;
  final profile = _profileFor(level);
  final output = _applyDataSaverProfile(decoded, profile);
  return _writeProofJpg(output, level: level, quality: profile.quality);
}

Future<String> _writeProofJpg(
  img.Image source, {
  required ReceiptDataSaverLevel level,
  required int quality,
}) async {
  final maximumBytes = level.proofTargetSizePolicy.maxBytes;
  var output = source;
  var encodedQuality = quality;
  var encoded = img.encodeJpg(output, quality: encodedQuality);
  while (maximumBytes > 0 && encoded.length > maximumBytes) {
    if (encodedQuality > 48) {
      encodedQuality -= 6;
    } else {
      final longestSide = output.width > output.height
          ? output.width
          : output.height;
      final nextLongestSide = (longestSide * .85).round();
      if (nextLongestSide < 900) break;
      output = _resizeToMaxSide(output, nextLongestSide);
      encodedQuality = quality > 70 ? 70 : quality;
    }
    encoded = img.encodeJpg(output, quality: encodedQuality);
  }
  final file = File(
    '${Directory.systemTemp.path}/maintaniac_receipt_optimized_'
    '${DateTime.now().microsecondsSinceEpoch}.jpg',
  );
  await file.writeAsBytes(encoded, flush: true);
  return file.path;
}

Future<ReceiptImageStoragePreview> _previewFile({
  required String path,
  required ReceiptDataSaverLevel level,
}) async {
  final file = File(path);
  final originalBytes = await file.exists() ? await file.length() : 0;
  final bytes = await ReceiptImageProcessor._readFileBytes(path);
  if (bytes == null) {
    return ReceiptImageStoragePreview(
      originalBytes: 0,
      estimatedBytes: 0,
      level: level,
      quality: ReceiptImageProcessor._unreadableReceiptQuality,
    );
  }
  final decoded = ReceiptImageProcessor._decodeImage(bytes);
  if (decoded == null) {
    return ReceiptImageStoragePreview(
      originalBytes: originalBytes,
      estimatedBytes: originalBytes,
      level: level,
      quality: ReceiptImageProcessor._unreadableReceiptQuality,
    );
  }
  final profile = _profileFor(level);
  final output = _applyDataSaverProfile(decoded, profile);
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

Future<ReceiptPhotoQualityCheck> _qualityCheckFile(String path) async {
  final decoded = await _readReceiptImageFile(path);
  if (decoded == null) {
    return ReceiptImageProcessor._unreadableReceiptQuality;
  }
  return _qualityCheck(decoded);
}

Future<img.Image?> _readReceiptImageFile(String path) async {
  final bytes = await ReceiptImageProcessor._readFileBytes(path);
  if (bytes == null) return null;
  return ReceiptImageProcessor._decodeImage(bytes);
}

img.Image _applyDataSaverProfile(img.Image source, _DataSaverProfile profile) {
  var output = _resizeToMaxSide(source, profile.maxLongSide);
  if (profile.grayscale) {
    output = img.grayscale(output);
    output = img.contrast(output, contrast: profile.contrast);
  }
  return output;
}
