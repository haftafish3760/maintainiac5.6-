import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../storage/app_storage_guard.dart';
import 'app_media_asset.dart';

class AppMediaAssetStore {
  const AppMediaAssetStore._();

  static const instance = AppMediaAssetStore._();

  Future<AppMediaAsset> importCompanyLogo({
    required String sourcePath,
    required String originalFileName,
  }) {
    return importImageAsset(
      sourcePath: sourcePath,
      originalFileName: originalFileName,
      purpose: AppMediaAssetPurpose.companyLogo,
      backupPolicy: AppMediaAssetBackupPolicy.cloudEligible,
      folderName: 'company_logos',
      fallbackBaseName: 'company-logo',
    );
  }

  Future<AppMediaAsset> importImageAsset({
    required String sourcePath,
    required String originalFileName,
    required AppMediaAssetPurpose purpose,
    required AppMediaAssetBackupPolicy backupPolicy,
    required String folderName,
    required String fallbackBaseName,
  }) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw const AppMediaAssetException(
        'That image could not be found. Please choose it again.',
      );
    }
    final extension = path.extension(sourcePath).toLowerCase();
    if (!_isSupportedImageExtension(extension)) {
      throw const AppMediaAssetException(
        'That image type is not supported here. Please choose a PNG or JPG file.',
      );
    }
    final byteSize = await _safeLength(source);
    final storageCheck = await AppStorageGuard.checkForBytes(
      operationBytes: byteSize ?? AppStorageGuard.receiptProofSaveBytes,
      purpose: AppStoragePurpose.receiptPhotoSave,
    );
    if (!storageCheck.hasEnoughSpace) {
      throw AppMediaAssetException(storageCheck.blockingMessage());
    }
    final root = await getApplicationDocumentsDirectory();
    final destinationDir = Directory(
      path.join(root.path, 'maintainiac_media', folderName),
    );
    await _createDirectory(destinationDir);
    final now = DateTime.now();
    final id = 'MEDIA-${now.microsecondsSinceEpoch}';
    final destination = await _availableDestinationFile(
      destinationDir,
      _storageFileName(
        originalFileName: originalFileName,
        fallbackBaseName: fallbackBaseName,
        id: id,
        extension: extension,
      ),
    );
    await _copyVerified(source, destination);
    final savedFile = File(destination.path);
    final savedBytes = await _safeLength(savedFile);
    final savedHash = await _safeHash(savedFile);
    return AppMediaAsset(
      id: id,
      path: destination.path,
      purpose: purpose,
      createdAt: now,
      displayName: originalFileName.trim().isEmpty
          ? path.basename(destination.path)
          : originalFileName.trim(),
      originalFileName: originalFileName.trim().isEmpty
          ? path.basename(sourcePath)
          : originalFileName.trim(),
      mimeType: _mimeTypeForExtension(extension),
      byteSize: savedBytes,
      fileHash: savedHash,
      backupPolicy: backupPolicy,
    );
  }

  static bool _isSupportedImageExtension(String extension) {
    return extension == '.png' || extension == '.jpg' || extension == '.jpeg';
  }

  static String _mimeTypeForExtension(String extension) {
    return extension == '.png' ? 'image/png' : 'image/jpeg';
  }

  static String _storageFileName({
    required String originalFileName,
    required String fallbackBaseName,
    required String id,
    required String extension,
  }) {
    final safeOriginal = _safeFileName(originalFileName);
    final baseName = _safeFileName(
      safeOriginal.isEmpty
          ? fallbackBaseName
          : path.basenameWithoutExtension(safeOriginal),
    );
    final safeBase = baseName.isEmpty ? fallbackBaseName : baseName;
    return '${safeBase}_${_safeFileName(id)}$extension';
  }

  static String _safeFileName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    final sanitized = trimmed
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^[._-]+|[._-]+$'), '');
    if (sanitized.isEmpty) return '';
    return sanitized.length <= 90 ? sanitized : sanitized.substring(0, 90);
  }

  static Future<int?> _safeLength(File file) async {
    try {
      return await file.length();
    } catch (_) {
      return null;
    }
  }

  static Future<String> _safeHash(File file) async {
    try {
      return (await sha256.bind(file.openRead()).first).toString();
    } catch (_) {
      return '';
    }
  }

  static Future<void> _createDirectory(Directory directory) async {
    try {
      await directory.create(recursive: true);
    } catch (_) {
      throw const AppMediaAssetException(
        'That image could not be saved into Maintaniac storage.',
      );
    }
  }

  static Future<File> _availableDestinationFile(
    Directory directory,
    String fileName,
  ) async {
    final first = File(path.join(directory.path, fileName));
    if (!await first.exists() &&
        !await File('${first.path}.partial').exists()) {
      return first;
    }
    final extension = path.extension(fileName);
    final baseName = path.basenameWithoutExtension(fileName);
    for (var index = 2; index < 1000; index += 1) {
      final candidate = File(
        path.join(directory.path, '$baseName-copy-$index$extension'),
      );
      if (!await candidate.exists() &&
          !await File('${candidate.path}.partial').exists()) {
        return candidate;
      }
    }
    throw const AppMediaAssetException(
      'That image could not be saved because Maintaniac could not create a safe file name.',
    );
  }

  static Future<void> _copyVerified(File source, File destination) async {
    final temp = File('${destination.path}.partial');
    try {
      await _deleteIfExists(temp);
      await source.copy(temp.path);
      final copiedBytes = await _safeLength(temp);
      final sourceBytes = await _safeLength(source);
      if (copiedBytes == null ||
          sourceBytes == null ||
          copiedBytes != sourceBytes) {
        throw const FileSystemException('Media asset copy was incomplete.');
      }
      final sourceHash = await _safeHash(source);
      final copiedHash = await _safeHash(temp);
      if (sourceHash.isEmpty ||
          copiedHash.isEmpty ||
          sourceHash != copiedHash) {
        throw const FileSystemException('Media asset copy did not verify.');
      }
      await _deleteIfExists(destination);
      await temp.rename(destination.path);
    } catch (_) {
      await _deleteIfExists(temp);
      await _deleteIfExists(destination);
      throw const AppMediaAssetException(
        'That image could not be copied into Maintaniac storage.',
      );
    }
  }

  static Future<void> _deleteIfExists(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}

class AppMediaAssetException implements Exception {
  const AppMediaAssetException(this.message);

  final String message;

  @override
  String toString() => message;
}
