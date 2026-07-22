import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../pdf/app_pdf_privacy_policy.dart';
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
    final importDirectoryType = await FileSystemEntity.type(
      importDirectory.path,
      followLinks: false,
    );
    if (importDirectoryType != FileSystemEntityType.directory) {
      throw const AppDocumentExportPackageException(
        'Maintainiac could not clean up a stale document package import.',
      );
    }
    final cutoff = (now ?? DateTime.now()).subtract(stalePackageImportAge);
    final deleted = <String>[];
    await for (final entity in importDirectory.list(followLinks: false)) {
      final directoryName = path.basename(entity.path);
      if (!_isAppOwnedPackageImportDirectory(directoryName)) continue;
      FileStat stat;
      try {
        final type = await FileSystemEntity.type(
          entity.path,
          followLinks: false,
        );
        if (type == FileSystemEntityType.link) {
          await _deletePackageImportEntity(entity.path);
          deleted.add(directoryName);
          continue;
        }
        if (type != FileSystemEntityType.directory &&
            type != FileSystemEntityType.link) {
          continue;
        }
        stat = await entity.stat();
      } catch (_) {
        continue;
      }
      if (!stat.modified.isBefore(cutoff)) continue;
      try {
        await _deletePackageImportEntity(entity.path);
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
    final cleanImportedText = importedText.trim();
    if (attachments.isEmpty && cleanImportedText.isEmpty) {
      throw const AppDocumentImportException(
        'Maintainiac could not save this document because it has no proof file or imported text.',
      );
    }
    final privacyIssues = _importPrivacyIssues(
      attachments: attachments,
      title: title,
      importedText: cleanImportedText,
      notes: notes,
      sourceLabel: sourceLabel,
    );
    if (privacyIssues.isNotEmpty) {
      throw AppDocumentImportException(_privacyImportMessage(privacyIssues));
    }
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
          importedText: cleanImportedText,
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
          sourceLabel: _packageSourceLabel(preview),
          isOriginalImmutable: true,
          storageState: ReceiptAttachmentStorageState.permanent,
          readState: ReceiptAttachmentReadState.notRead,
        ),
    ];
  }

  static String _packageSourceLabel(
    AppDocumentExportPackageImportPreview preview,
  ) {
    return 'Maintainiac document export ${preview.manifestSha256.substring(0, 12)}';
  }

  static List<String> _importPrivacyIssues({
    required List<ReceiptAttachmentRecord> attachments,
    required String title,
    required String importedText,
    required String notes,
    required String sourceLabel,
  }) {
    final metadata = <String>[
      title,
      importedText,
      notes,
      sourceLabel,
      for (final attachment in attachments) ...[
        attachment.displayName,
        attachment.originalFileName,
        attachment.mimeType,
        attachment.importedText,
        attachment.sourceLabel,
        ...attachment.riskFlags,
        ...attachment.documentSignals,
      ],
    ];
    return AppPdfPrivacyPolicy.issueCodesForExport(
      bytes: const [],
      metadata: metadata,
    );
  }

  static String _privacyImportMessage(List<String> issues) {
    if (issues.contains(AppPdfPrivacyPolicy.unconfirmedOcrSuggestion)) {
      return 'Maintainiac could not save this document because it includes unconfirmed OCR suggestions.';
    }
    if (issues.contains(AppPdfPrivacyPolicy.privateSourcePath)) {
      return 'Maintainiac could not save this document because it includes private device paths.';
    }
    if (issues.contains(AppPdfPrivacyPolicy.internalId)) {
      return 'Maintainiac could not save this document because it includes internal record IDs.';
    }
    return 'Maintainiac could not save this document because it may include private information.';
  }

  static Future<void> _deleteDirectoryQuietly(Directory directory) async {
    try {
      await _deletePackageImportEntity(directory.path);
    } catch (_) {}
    try {
      await _deletePackageImportEntity('${directory.path}.partial');
    } catch (_) {}
  }

  static Future<void> _deletePackageImportEntity(String entityPath) async {
    final type = await FileSystemEntity.type(entityPath, followLinks: false);
    if (type == FileSystemEntityType.directory) {
      await Directory(entityPath).delete(recursive: true);
    } else if (type == FileSystemEntityType.link) {
      await Link(entityPath).delete();
    }
  }
}

class AppDocumentImportException implements Exception {
  const AppDocumentImportException(this.message);

  final String message;

  @override
  String toString() => message;
}
