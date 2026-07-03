import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../pdf/app_generated_pdf_models.dart';
import '../storage/app_storage_guard.dart';
import '../widgets/receipt_capture/receipt_capture_models.dart';
import 'app_document_models.dart';
import 'app_document_store.dart';

class AppGeneratedPdfArchiveService {
  const AppGeneratedPdfArchiveService({this.store});

  final AppDocumentStore? store;

  Future<AppDocumentArchiveResult> archive(
    AppGeneratedPdfDocument document, {
    AppDocumentKind? kind,
    String title = '',
    String notes = '',
  }) async {
    final documentKind = kind ?? _kindForGeneratedPdf(document.kind);
    final savedFile = await _writePermanentPdf(document, documentKind);
    final byteSize = await _safeLength(savedFile);
    var fileHash = await _safeHash(savedFile);
    if (fileHash.isEmpty) {
      fileHash = sha256.convert(document.bytes).toString();
    }
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
      linkedModule: document.sourceModule.trim().isEmpty
          ? documentKind.storageModule
          : document.sourceModule.trim(),
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
    final savedRecord = await documentStore.saveRecord(record);
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
    final destination = await _availableDestination(
      directory,
      _safeFileName(document.safeFileName),
    );
    final partial = File('${destination.path}.partial');
    try {
      await partial.writeAsBytes(document.bytes, flush: true);
      final writtenBytes = await _safeLength(partial);
      if (writtenBytes == null || writtenBytes != document.byteSize) {
        throw const FileSystemException('Generated PDF write was incomplete.');
      }
      await _deleteIfExists(destination);
      await partial.rename(destination.path);
      return destination;
    } catch (_) {
      await _deleteIfExists(partial);
      await _deleteIfExists(destination);
      throw const AppGeneratedPdfArchiveException(
        'Maintaniac could not save that generated PDF into permanent document storage.',
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
      AppGeneratedPdfKind.expenseExport ||
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

  static String _safeFileName(String fileName) {
    return AppGeneratedPdfFileName.clean(fileName);
  }

  static void _ensureArchivablePdf(AppGeneratedPdfDocument document) {
    final validation = document.validation;
    if (validation.isValid) return;
    throw AppGeneratedPdfArchiveException(validation.userMessage);
  }

  static Future<void> _createDirectory(Directory directory) async {
    try {
      await directory.create(recursive: true);
    } catch (_) {
      throw const AppGeneratedPdfArchiveException(
        'Maintaniac could not prepare permanent document storage.',
      );
    }
  }

  static Future<File> _availableDestination(
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
    throw const AppGeneratedPdfArchiveException(
      'Maintaniac could not create a safe permanent PDF file name.',
    );
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
      if (await file.exists()) await file.delete();
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
