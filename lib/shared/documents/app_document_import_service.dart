import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../widgets/receipt_capture/receipt_capture_models.dart';
import '../widgets/receipt_capture/receipt_proof_storage.dart';
import 'app_document_export_manifest.dart';
import 'app_document_export_package_writer.dart';
import 'app_document_models.dart';
import 'app_document_store.dart';

class AppDocumentImportService {
  const AppDocumentImportService({
    this.store,
    this.proofStorage = ReceiptProofStorage.instance,
  });

  static const Duration stalePackageImportAge = Duration(hours: 12);

  final AppDocumentStore? store;
  final ReceiptProofStorage proofStorage;

  Future<AppDocumentRecord> saveDocumentExportPackage({
    required File packageFile,
    Directory? extractionParentDirectory,
    DateTime? now,
    DateTime? cleanupNow,
  }) async {
    final preview =
        await AppDocumentExportPackageWriter.previewZipPackageImport(
          packageFile,
        );
    final extractionParent =
        extractionParentDirectory ?? await _defaultPackageImportDirectory();
    AppDocumentExportPackageExtractResult? extraction;
    try {
      await cleanupStaleDocumentPackageImports(
        extractionParent,
        now: cleanupNow,
      );
      extraction = await AppDocumentExportPackageWriter.extractZipPackage(
        packageFile,
        outputDirectory: extractionParent,
      );
      final extractionDirectory = Directory(
        path.join(extractionParent.path, extraction.directoryName),
      );
      final attachments = _attachmentsForPackageImport(
        preview,
        extractionDirectory,
        now: now,
      );
      return await saveReadOnlyDocument(
        kind: AppDocumentKind.fromName(preview.kindName),
        attachments: attachments,
        title: preview.title,
        sourceLabel: 'Maintainiac document export package',
        now: now,
      );
    } finally {
      final directoryName = extraction?.directoryName;
      if (directoryName != null && directoryName.isNotEmpty) {
        await _deleteDirectoryQuietly(
          Directory(path.join(extractionParent.path, directoryName)),
        );
      }
    }
  }

  static Future<List<String>> cleanupStaleDocumentPackageImports(
    Directory importDirectory, {
    DateTime? now,
  }) async {
    if (!await importDirectory.exists()) return const [];
    final cutoff = (now ?? DateTime.now()).subtract(stalePackageImportAge);
    final deleted = <String>[];
    await for (final entity in importDirectory.list(followLinks: false)) {
      if (entity is! Directory) continue;
      final directoryName = path.basename(entity.path);
      if (!_isAppOwnedPackageImportDirectory(directoryName)) continue;
      FileStat stat;
      try {
        stat = await entity.stat();
      } catch (_) {
        continue;
      }
      if (stat.type != FileSystemEntityType.directory) continue;
      if (!stat.modified.isBefore(cutoff)) continue;
      try {
        await entity.delete(recursive: true);
        deleted.add(directoryName);
      } catch (_) {
        throw const AppDocumentExportPackageException(
          'Maintainiac could not clean up a stale document package import.',
        );
      }
    }
    deleted.sort();
    return List.unmodifiable(deleted);
  }

  Future<AppDocumentRecord> saveReadOnlyDocument({
    required AppDocumentKind kind,
    required List<ReceiptAttachmentRecord> attachments,
    String title = '',
    String importedText = '',
    String notes = '',
    String sourceLabel = 'Shared import',
    DateTime? now,
  }) async {
    final savedAt = now ?? DateTime.now();
    final id = 'DOC-${savedAt.microsecondsSinceEpoch}';
    final linkedAttachments = attachments
        .map(
          (attachment) => attachment.copyWith(
            linkedModule: kind.storageModule,
            linkedRecordId: id,
          ),
        )
        .toList(growable: false);
    var promoted = const <ReceiptAttachmentRecord>[];
    try {
      promoted = await proofStorage.persistAttachments(linkedAttachments);
      final documentStore = store ?? await AppDocumentStore.create();
      return documentStore.saveRecord(
        AppDocumentRecord(
          id: id,
          kind: kind,
          title: title.trim(),
          importedText: importedText.trim(),
          notes: notes.trim(),
          sourceLabel: sourceLabel.trim(),
          createdAt: savedAt,
          updatedAt: savedAt,
          attachments: List.unmodifiable(promoted),
        ),
      );
    } catch (_) {
      await proofStorage.rollbackPersistedAttachments(
        promoted,
        linkedAttachments,
      );
      rethrow;
    }
  }

  static Future<Directory> _defaultPackageImportDirectory() async {
    final root = await getApplicationDocumentsDirectory();
    return Directory(path.join(root.path, 'document_package_imports'));
  }

  static bool _isAppOwnedPackageImportDirectory(String directoryName) {
    final normalized = directoryName.trim();
    if (normalized.isEmpty ||
        normalized.contains('..') ||
        normalized.contains('/') ||
        normalized.contains('\\') ||
        normalized.contains(RegExp(r'[\x00-\x1F\x7F]'))) {
      return false;
    }
    final completeName = RegExp(
      r'^maintainiac-document-export-[a-f0-9]{12}(-copy-[0-9]+)?$',
    );
    final partialName = RegExp(
      r'^maintainiac-document-export-[a-f0-9]{12}(-copy-[0-9]+)?\.partial$',
    );
    return completeName.hasMatch(normalized) ||
        partialName.hasMatch(normalized);
  }

  static List<ReceiptAttachmentRecord> _attachmentsForPackageImport(
    AppDocumentExportPackageImportPreview preview,
    Directory extractionDirectory, {
    DateTime? now,
  }) {
    final createdAt = now ?? DateTime.now();
    return [
      for (final attachment in preview.attachments)
        ReceiptAttachmentRecord(
          id:
              'package-${preview.manifestSha256.substring(0, 12)}-'
              '${attachment.sha256.substring(0, 12)}',
          path: path.join(
            extractionDirectory.path,
            attachment.packageEntryName,
          ),
          kind: ReceiptAttachmentKind.fromName(attachment.kindName),
          dataSaverLevel: ReceiptDataSaverLevel.original,
          createdAt: createdAt,
          displayName: attachment.displayName,
          originalFileName: attachment.displayName,
          mimeType: attachment.mimeType,
          byteSize: attachment.byteSize,
          fileHash: attachment.sha256,
          documentSignals: const ['document-export-package'],
          sourceLabel: preview.fileName,
          isOriginalImmutable: true,
          storageState: ReceiptAttachmentStorageState.permanent,
          readState: ReceiptAttachmentReadState.notRead,
        ),
    ];
  }

  static Future<void> _deleteDirectoryQuietly(Directory directory) async {
    try {
      if (await directory.exists()) await directory.delete(recursive: true);
    } catch (_) {}
    try {
      final partial = Directory('${directory.path}.partial');
      if (await partial.exists()) await partial.delete(recursive: true);
    } catch (_) {}
  }
}
