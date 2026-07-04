import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../storage/app_storage_guard.dart';
import 'app_generated_pdf_models.dart';

class AppGeneratedPdfException implements Exception {
  const AppGeneratedPdfException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AppGeneratedPdfService {
  const AppGeneratedPdfService();

  Future<AppGeneratedPdfFile> writeTemporary(
    AppGeneratedPdfDocument document,
  ) async {
    _ensureSendablePdf(document);
    await _ensureStorage(document);
    final directory = await _generatedPdfDirectory();
    await _createDirectory(directory);
    final destination = await _availableDestination(
      directory,
      _safeFileName(document.safeFileName),
    );
    final partial = File('${destination.path}.partial');
    try {
      await partial.writeAsBytes(document.bytes, flush: true);
      final writtenBytes = await partial.length();
      if (writtenBytes != document.byteSize) {
        throw const FileSystemException('Generated PDF write was incomplete.');
      }
      if (await destination.exists()) await destination.delete();
      await partial.rename(destination.path);
    } catch (_) {
      await _deleteIfExists(partial);
      await _deleteIfExists(destination);
      throw const AppGeneratedPdfException(
        'Maintaniac could not create that PDF. Please free up storage and try again.',
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
    if (!await file.exists()) {
      throw const AppGeneratedPdfException(
        'Maintaniac could not find that prepared PDF. Please create it again.',
      );
    }
    final actualBytes = await file.length();
    if (actualBytes != generated.byteSize) {
      throw const AppGeneratedPdfException(
        'Maintaniac stopped this PDF because the prepared file was incomplete.',
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
    await for (final entity in directory.list(recursive: true)) {
      if (entity is! File) continue;
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

  void _ensureSendablePdf(AppGeneratedPdfDocument document) {
    final validation = document.validation;
    if (validation.isValid) return;
    throw AppGeneratedPdfException(validation.userMessage);
  }

  Future<Directory> _generatedPdfDirectory() async {
    final directory = await getTemporaryDirectory();
    return Directory(path.join(directory.path, 'maintaniac_generated_pdfs'));
  }

  Future<void> _createDirectory(Directory directory) async {
    try {
      await directory.create(recursive: true);
    } catch (_) {
      throw const AppGeneratedPdfException(
        'Maintaniac could not prepare PDF storage on this device.',
      );
    }
  }

  Future<File> _availableDestination(
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
    throw const AppGeneratedPdfException(
      'Maintaniac could not create a safe PDF file name.',
    );
  }

  String _safeFileName(String fileName) {
    return AppGeneratedPdfFileName.clean(fileName);
  }

  Future<void> _deleteIfExists(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
