import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../storage/app_storage_guard.dart';
import 'app_generated_pdf_models.dart';
import 'app_generated_pdf_storage.dart';

class AppGeneratedPdfException implements Exception {
  const AppGeneratedPdfException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AppGeneratedPdfService {
  const AppGeneratedPdfService();

  static const stalePartialAge = Duration(hours: 12);

  Future<AppGeneratedPdfFile> writeTemporary(
    AppGeneratedPdfDocument document,
  ) async {
    _ensureSendablePdf(document);
    await _ensureStorage(document);
    final directory = await _generatedPdfDirectory();
    await _createDirectory(directory);
    await _deleteStalePartialFiles(directory, now: DateTime.now());
    final destination = await _availableDestination(directory, document);
    final partial = File('${destination.path}.partial');
    try {
      await partial.writeAsBytes(document.bytes, flush: true);
      final writtenBytes = await partial.length();
      if (writtenBytes != document.byteSize) {
        throw const FileSystemException('Generated PDF write was incomplete.');
      }
      final expectedHash = sha256.convert(document.bytes).toString();
      final writtenHash = await sha256.bind(partial.openRead()).first;
      if (writtenHash.toString() != expectedHash) {
        throw const FileSystemException('Generated PDF write did not verify.');
      }
      if (await destination.exists()) await destination.delete();
      await partial.rename(destination.path);
    } catch (_) {
      await _deleteIfExists(partial);
      await _deleteIfExists(destination);
      throw const AppGeneratedPdfException(
        'Maintainiac could not create that PDF. Please free up storage and try again.',
      );
    }
    return AppGeneratedPdfFile(
      document: document,
      path: destination.path,
      byteSize: document.byteSize,
    );
  }

  Future<bool> print(AppGeneratedPdfDocument document) {
    _ensureSendablePdf(document);
    return Printing.layoutPdf(
      name: document.safeFileName,
      onLayout: (_) async => document.bytes,
    );
  }

  Future<ShareResultStatus> share(AppGeneratedPdfDocument document) async {
    final generated = await writeTemporary(document);
    return shareGeneratedFile(generated);
  }

  Future<ShareResultStatus> shareGeneratedFile(
    AppGeneratedPdfFile generated,
  ) async {
    _ensureSendablePdf(generated.document);
    final file = File(generated.path);
    await _ensureShareableGeneratedPath(file);
    if (file.path.toLowerCase().endsWith('.partial')) {
      throw const AppGeneratedPdfException(
        'Maintainiac stopped this PDF because the prepared file is still being written.',
      );
    }
    if (!await file.exists()) {
      throw const AppGeneratedPdfException(
        'Maintainiac could not find that prepared PDF. Please create it again.',
      );
    }
    final actualBytes = await file.length();
    if (actualBytes != generated.byteSize) {
      throw const AppGeneratedPdfException(
        'Maintainiac stopped this PDF because the prepared file was incomplete.',
      );
    }
    final expectedHash = sha256.convert(generated.document.bytes).toString();
    final actualHash = await sha256.bind(file.openRead()).first;
    if (actualHash.toString() != expectedHash) {
      throw const AppGeneratedPdfException(
        'Maintainiac stopped this PDF because the prepared file did not verify.',
      );
    }
    final result = await SharePlus.instance.share(
      ShareParams(
        title: generated.document.title,
        subject: generated.document.shareSubject.isEmpty
            ? generated.document.title
            : generated.document.shareSubject,
        text: generated.document.shareText.isEmpty
            ? generated.document.title
            : generated.document.shareText,
        files: [XFile(generated.path)],
      ),
    );
    return result.status;
  }

  Future<void> cleanOldGeneratedFiles({
    Duration olderThan = const Duration(days: 7),
    DateTime? now,
  }) async {
    final directory = await _generatedPdfDirectory();
    if (!await directory.exists()) return;
    final cutoff = (now ?? DateTime.now()).subtract(olderThan);
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File) continue;
      if (!_isGeneratedPdfCleanupTarget(entity)) continue;
      try {
        final stat = await entity.stat();
        if (stat.modified.isAfter(cutoff)) continue;
        await entity.delete();
      } catch (_) {
        continue;
      }
    }
  }

  Future<void> _ensureStorage(AppGeneratedPdfDocument document) async {
    final operationBytes = document.byteSize + (1024 * 1024);
    final check = await AppStorageGuard.checkForBytes(
      operationBytes: operationBytes,
      purpose: AppStoragePurpose.exportFile,
    );
    if (!check.hasEnoughSpace) {
      throw AppGeneratedPdfException(check.blockingMessage());
    }
  }

  Future<void> _ensureShareableGeneratedPath(File file) async {
    final directory = await _generatedPdfDirectory();
    final directoryPath = path.normalize(path.absolute(directory.path));
    final filePath = path.normalize(path.absolute(file.path));
    if (!path.isWithin(directoryPath, filePath)) {
      throw const AppGeneratedPdfException(
        'Maintainiac stopped this PDF because the prepared file is outside app-generated PDF storage.',
      );
    }
    final type = await FileSystemEntity.type(file.path, followLinks: false);
    if (type == FileSystemEntityType.link) {
      throw const AppGeneratedPdfException(
        'Maintainiac stopped this PDF because the prepared file could not be verified safely.',
      );
    }
  }

  void _ensureSendablePdf(AppGeneratedPdfDocument document) {
    final validation = document.validation;
    if (validation.isValid) return;
    throw AppGeneratedPdfException(validation.userMessage);
  }

  Future<Directory> _generatedPdfDirectory() async {
    final directory = await getTemporaryDirectory();
    return Directory(path.join(directory.path, 'maintainiac_generated_pdfs'));
  }

  Future<void> _createDirectory(Directory directory) async {
    try {
      await directory.create(recursive: true);
      final type = await FileSystemEntity.type(
        directory.path,
        followLinks: false,
      );
      if (type != FileSystemEntityType.directory) {
        throw const FileSystemException(
          'Generated PDF directory is not a directory.',
        );
      }
    } catch (_) {
      throw const AppGeneratedPdfException(
        'Maintainiac could not prepare PDF storage on this device.',
      );
    }
  }

  Future<File> _availableDestination(
    Directory directory,
    AppGeneratedPdfDocument document,
  ) async {
    final destination = await AppGeneratedPdfStorage.availableDestination(
      directory: directory,
      requestedFileName: document.safeFileName,
    );
    if (destination != null) return destination;
    throw const AppGeneratedPdfException(
      'Maintainiac could not create a safe PDF file name.',
    );
  }

  Future<void> _deleteIfExists(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  bool _isGeneratedPdfCleanupTarget(File file) {
    final name = path.basename(file.path).toLowerCase();
    return name.endsWith('.pdf') || name.endsWith('.pdf.partial');
  }

  Future<int> _deleteStalePartialFiles(
    Directory directory, {
    required DateTime now,
    Duration olderThan = stalePartialAge,
  }) async {
    if (!await directory.exists()) return 0;
    var deleted = 0;
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File) continue;
      if (!entity.path.toLowerCase().endsWith('.pdf.partial')) continue;
      try {
        final modified = await entity.lastModified();
        if (now.difference(modified) < olderThan) continue;
        await entity.delete();
        deleted += 1;
      } catch (_) {
        continue;
      }
    }
    return deleted;
  }
}
