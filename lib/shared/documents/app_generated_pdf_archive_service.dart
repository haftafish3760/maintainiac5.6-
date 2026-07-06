import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../pdf/app_generated_pdf_models.dart';
import '../pdf/app_generated_pdf_storage.dart';
import '../pdf/app_pdf_privacy_policy.dart';
import '../storage/app_storage_guard.dart';
import '../widgets/receipt_capture/receipt_capture_models.dart';
import 'app_document_models.dart';
import 'app_document_store.dart';

class AppGeneratedPdfArchiveService {
  const AppGeneratedPdfArchiveService({this.store});

  static const stalePartialAge = Duration(hours: 12);

  final AppDocumentStore? store;

  Future<AppDocumentArchiveResult> archive(
    AppGeneratedPdfDocument document, {
    AppDocumentKind? kind,
    String title = '',
    String notes = '',
  }) async {
    final documentKind = kind ?? _kindForGeneratedPdf(document.kind);
    _ensureSafeArchiveMetadata(title: title, notes: notes);
    final savedFile = await _writePermanentPdf(document, documentKind);
    final metadata = await _verifiedPermanentPdfMetadata(savedFile, document);
    final byteSize = metadata.byteSize;
    final fileHash = metadata.sha256;
    final now = DateTime.now();
    final recordId = _documentId(document, now);
    final attachment = ReceiptAttachmentRecord(
      id: '$recordId-pdf',
      path: savedFile.path,
      kind: ReceiptAttachmentKind.pdf,
      dataSaverLevel: ReceiptDataSaverLevel.original,
      createdAt: now,
      displayName: path.basename(savedFile.path),
      originalFileName: document.safeFileName,
      mimeType: 'application/pdf',
      byteSize: byteSize,
      fileHash: fileHash,
      linkedModule: _safeLinkedModule(document, documentKind),
      linkedRecordId: document.sourceRecordId,
      storageState: ReceiptAttachmentStorageState.permanent,
      promotedAt: now,
      readState: ReceiptAttachmentReadState.notRead,
    );
    final record = AppDocumentRecord(
      id: recordId,
      kind: documentKind,
      title: title.trim().isEmpty ? document.title : title.trim(),
      notes: notes,
      sourceLabel: 'Generated PDF',
      createdAt: now,
      updatedAt: now,
      attachments: [attachment],
    );
    final documentStore = store ?? await AppDocumentStore.create();
    final existingRecord = documentStore.recordById(recordId);
    late final AppDocumentRecord savedRecord;
    try {
      savedRecord = await documentStore.saveRecord(record);
    } catch (_) {
      await _deleteIfExists(savedFile);
      throw const AppGeneratedPdfArchiveException(
        'Maintainiac could not save the generated PDF record, so the PDF file was not kept.',
      );
    }
    if (existingRecord != null) {
      await documentStore.deleteAppOwnedAttachmentFiles(
        existingRecord.attachments,
        keepPaths: {savedFile.path},
      );
    }
    return AppDocumentArchiveResult(
      document: savedRecord,
      attachment: attachment,
      fileHashSha256: fileHash,
    );
  }

  Future<File> _writePermanentPdf(
    AppGeneratedPdfDocument document,
    AppDocumentKind kind,
  ) async {
    _ensureArchivablePdf(document);
    final check = await AppStorageGuard.checkForBytes(
      operationBytes: document.byteSize + (1024 * 1024),
      purpose: AppStoragePurpose.exportFile,
    );
    if (!check.hasEnoughSpace) {
      throw AppGeneratedPdfArchiveException(check.blockingMessage());
    }
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory(
      path.join(
        root.path,
        'app_documents',
        kind.storageModule,
        'generated_pdfs',
      ),
    );
    await _createDirectory(directory);
    await _deleteStalePartialFiles(directory, now: DateTime.now());
    final destination = await _availableDestination(directory, document);
    final partial = File('${destination.path}.partial');
    try {
      await partial.writeAsBytes(document.bytes, flush: true);
      final writtenBytes = await _safeLength(partial);
      if (writtenBytes == null || writtenBytes != document.byteSize) {
        throw const FileSystemException('Generated PDF write was incomplete.');
      }
      final writtenHash = await _safeHash(partial);
      final expectedHash = sha256.convert(document.bytes).toString();
      if (writtenHash.isEmpty || writtenHash != expectedHash) {
        throw const FileSystemException('Generated PDF write did not verify.');
      }
      await _deleteIfExists(destination);
      await partial.rename(destination.path);
      await _verifyPermanentWrite(destination, document);
      return destination;
    } catch (_) {
      await _deleteIfExists(partial);
      await _deleteIfExists(destination);
      throw const AppGeneratedPdfArchiveException(
        'Maintainiac could not save that generated PDF into permanent document storage.',
      );
    }
  }

  static AppDocumentKind _kindForGeneratedPdf(AppGeneratedPdfKind kind) {
    return switch (kind) {
      AppGeneratedPdfKind.invoice ||
      AppGeneratedPdfKind.estimate ||
      AppGeneratedPdfKind.customerStatement => AppDocumentKind.invoiceDocument,
      AppGeneratedPdfKind.maintenanceReport =>
        AppDocumentKind.maintenanceRecord,
      AppGeneratedPdfKind.jobPacket => AppDocumentKind.jobContractorDocument,
      AppGeneratedPdfKind.receipt ||
      AppGeneratedPdfKind.expenseExport ||
      AppGeneratedPdfKind.expenseReport ||
      AppGeneratedPdfKind.dailyRecap ||
      AppGeneratedPdfKind.weeklyRecap ||
      AppGeneratedPdfKind.monthlyRecap ||
      AppGeneratedPdfKind.extendedRecap ||
      AppGeneratedPdfKind.inventoryReport => AppDocumentKind.otherDocument,
    };
  }

  static String _documentId(AppGeneratedPdfDocument document, DateTime now) {
    final sourceId = _safeId(document.sourceRecordId);
    if (sourceId.isNotEmpty) return 'DOC-${document.kind.name}-$sourceId';
    return 'DOC-${document.kind.name}-${now.microsecondsSinceEpoch}';
  }

  static String _safeId(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  static String _safeLinkedModule(
    AppGeneratedPdfDocument document,
    AppDocumentKind documentKind,
  ) {
    final sourceModule = _safeId(document.sourceModule).toLowerCase();
    if (sourceModule.isNotEmpty) return sourceModule;
    return documentKind.storageModule;
  }

  static void _ensureArchivablePdf(AppGeneratedPdfDocument document) {
    final validation = document.validation;
    if (validation.isValid) return;
    throw AppGeneratedPdfArchiveException(validation.userMessage);
  }

  static void _ensureSafeArchiveMetadata({
    required String title,
    required String notes,
  }) {
    final issues = AppPdfPrivacyPolicy.issueCodesForExport(
      bytes: const [],
      metadata: [title, notes],
    );
    if (issues.isEmpty) return;
    throw const AppGeneratedPdfArchiveException(
      'Maintainiac stopped this PDF record because its title or notes may contain private information.',
    );
  }

  static Future<void> _createDirectory(Directory directory) async {
    try {
      await directory.create(recursive: true);
      final type = await FileSystemEntity.type(
        directory.path,
        followLinks: false,
      );
      if (type != FileSystemEntityType.directory) {
        throw const FileSystemException(
          'Generated PDF archive directory is not a directory.',
        );
      }
    } catch (_) {
      throw const AppGeneratedPdfArchiveException(
        'Maintainiac could not prepare permanent document storage.',
      );
    }
  }

  static Future<File> _availableDestination(
    Directory directory,
    AppGeneratedPdfDocument document,
  ) async {
    final destination = await AppGeneratedPdfStorage.availableDestination(
      directory: directory,
      requestedFileName: document.safeFileName,
    );
    if (destination != null) return destination;
    throw const AppGeneratedPdfArchiveException(
      'Maintainiac could not create a safe permanent PDF file name.',
    );
  }

  static Future<int> deleteStalePartialFiles(
    Directory directory, {
    required DateTime now,
    Duration olderThan = stalePartialAge,
  }) {
    return _deleteStalePartialFiles(directory, now: now, olderThan: olderThan);
  }

  static Future<int> _deleteStalePartialFiles(
    Directory directory, {
    required DateTime now,
    Duration olderThan = stalePartialAge,
  }) async {
    if (!await directory.exists()) return 0;
    var deleted = 0;
    await for (final entity in directory.list(
      recursive: false,
      followLinks: false,
    )) {
      if (entity is! File && entity is! Link) continue;
      if (!entity.path.toLowerCase().endsWith('.pdf.partial')) continue;
      try {
        if (entity is Link) {
          await _deleteIfExists(File(entity.path));
          deleted += 1;
          continue;
        }
        final modified = await File(entity.path).lastModified();
        if (now.difference(modified) < olderThan) continue;
        await _deleteIfExists(File(entity.path));
        deleted += 1;
      } catch (_) {
        continue;
      }
    }
    return deleted;
  }

  static Future<void> _verifyPermanentWrite(
    File destination,
    AppGeneratedPdfDocument document,
  ) async {
    await _requireRegularPdfFile(destination);
    final finalBytes = await _safeLength(destination);
    if (finalBytes == null || finalBytes != document.byteSize) {
      throw const FileSystemException(
        'Generated PDF final file was incomplete.',
      );
    }
    await _requireRegularPdfFile(destination);
    final finalHash = await _safeHash(destination);
    final expectedHash = sha256.convert(document.bytes).toString();
    if (finalHash.isEmpty || finalHash != expectedHash) {
      throw const FileSystemException(
        'Generated PDF final file did not verify.',
      );
    }
    await _requireRegularPdfFile(destination);
  }

  static Future<_VerifiedPermanentPdfMetadata> _verifiedPermanentPdfMetadata(
    File file,
    AppGeneratedPdfDocument document,
  ) async {
    try {
      await _verifyPermanentWrite(file, document);
      return _VerifiedPermanentPdfMetadata(
        byteSize: document.byteSize,
        sha256: sha256.convert(document.bytes).toString(),
      );
    } catch (_) {
      throw const AppGeneratedPdfArchiveException(
        'Maintainiac could not verify the generated PDF after it was saved.',
      );
    }
  }

  static Future<void> _requireRegularPdfFile(File file) async {
    final type = await FileSystemEntity.type(file.path, followLinks: false);
    if (type == FileSystemEntityType.file) return;
    throw const FileSystemException('Generated PDF file was not regular.');
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

  static Future<void> _deleteIfExists(File file) async {
    try {
      final type = await FileSystemEntity.type(file.path, followLinks: false);
      if (type == FileSystemEntityType.link) {
        await Link(file.path).delete();
      } else if (type == FileSystemEntityType.file) {
        await file.delete();
      }
    } catch (_) {}
  }
}

class AppDocumentArchiveResult {
  const AppDocumentArchiveResult({
    required this.document,
    required this.attachment,
    required this.fileHashSha256,
  });

  final AppDocumentRecord document;
  final ReceiptAttachmentRecord attachment;
  final String fileHashSha256;
}

class AppGeneratedPdfArchiveException implements Exception {
  const AppGeneratedPdfArchiveException(this.message);

  final String message;

  @override
  String toString() => message;
}

class _VerifiedPermanentPdfMetadata {
  const _VerifiedPermanentPdfMetadata({
    required this.byteSize,
    required this.sha256,
  });

  final int byteSize;
  final String sha256;
}
