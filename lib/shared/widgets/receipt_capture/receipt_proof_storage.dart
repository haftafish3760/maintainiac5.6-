import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'receipt_capture_models.dart';
import 'receipt_pdf_inspector.dart';
import 'receipt_storage_guard.dart';

part 'receipt_proof_storage_exception.dart';
part 'receipt_proof_storage_file_names.dart';
part 'receipt_proof_storage_copy.dart';

class ReceiptProofStorage {
  const ReceiptProofStorage._();

  static const instance = ReceiptProofStorage._();

  Future<List<ReceiptAttachmentRecord>> persistAttachments(
    List<ReceiptAttachmentRecord> attachments,
  ) async {
    final saved = <ReceiptAttachmentRecord>[];
    try {
      for (final attachment in attachments) {
        final persisted = await persistAttachment(attachment);
        saved.add(persisted);
      }
    } catch (_) {
      await _rollbackPersistedBatch(saved, attachments);
      rethrow;
    }
    return saved;
  }

  Future<ReceiptAttachmentRecord> persistAttachment(
    ReceiptAttachmentRecord attachment,
  ) async {
    if (attachment.path.trim().isEmpty || attachment.isImportedText) {
      return attachment;
    }
    final source = File(attachment.path);
    if (!await source.exists()) return attachment;
    await _validatePdfSourceForStorage(attachment, source);

    final proofRoot = await _proofRoot();
    if (attachment.storageState == ReceiptAttachmentStorageState.staged) {
      return promoteStagedAttachment(attachment);
    }
    if (path.isWithin(proofRoot.path, source.path)) {
      final inspection = attachment.isPdf
          ? await ReceiptPdfInspector.inspect(source.path)
          : null;
      return attachment.copyWith(
        byteSize: await _safeLength(source),
        fileHash: await _safeHash(source),
        pageCount: inspection?.pageCount ?? attachment.pageCount,
        pageCountStatus:
            inspection?.pageCountStatus ?? attachment.pageCountStatus,
        validationStatus:
            inspection?.validationStatus ?? attachment.validationStatus,
        riskFlags: inspection?.riskFlags ?? attachment.riskFlags,
        documentSignals:
            inspection?.documentSignals ?? attachment.documentSignals,
        mimeType: attachment.mimeType.trim().isEmpty
            ? _mimeTypeFor(attachment.kind)
            : attachment.mimeType,
        originalFileName: _metadataFileName(attachment, source.path),
        storageState: ReceiptAttachmentStorageState.permanent,
      );
    }

    final folder = switch (attachment.kind) {
      ReceiptAttachmentKind.pdf => 'pdfs',
      ReceiptAttachmentKind.photo => 'photos',
      ReceiptAttachmentKind.emailText ||
      ReceiptAttachmentKind.textMessageText => 'text',
    };
    final destinationDir = Directory(path.join(proofRoot.path, folder));
    await _createProofDirectory(
      destinationDir,
      'That receipt proof could not be saved into Maintainiac storage.',
    );

    final destination = await _availableDestinationFile(
      destinationDir,
      _storageFileName(attachment, source.path),
    );
    await _ensureStorageForCopy(
      source,
      _storagePurposeFor(attachment),
      'That receipt proof could not be saved into Maintainiac storage.',
    );
    await _copyIntoAppStorage(
      source,
      destination,
      'That receipt proof could not be copied into Maintainiac storage.',
    );
    final inspection = attachment.isPdf
        ? await ReceiptPdfInspector.inspect(destination.path)
        : null;

    return attachment.copyWith(
      path: destination.path,
      displayName: attachment.displayName.trim().isEmpty
          ? path.basename(destination.path)
          : attachment.displayName,
      originalFileName: _metadataFileName(attachment, source.path),
      mimeType: attachment.mimeType.trim().isEmpty
          ? _mimeTypeFor(attachment.kind)
          : attachment.mimeType,
      byteSize: await _safeLength(destination),
      fileHash: await _safeHash(destination),
      pageCount: inspection?.pageCount ?? attachment.pageCount,
      pageCountStatus:
          inspection?.pageCountStatus ?? attachment.pageCountStatus,
      validationStatus:
          inspection?.validationStatus ?? attachment.validationStatus,
      riskFlags: inspection?.riskFlags ?? attachment.riskFlags,
      documentSignals:
          inspection?.documentSignals ?? attachment.documentSignals,
      isOriginalImmutable: true,
      storageState: ReceiptAttachmentStorageState.permanent,
      promotedAt: DateTime.now(),
    );
  }

  Future<ReceiptAttachmentRecord> stageAttachment(
    ReceiptAttachmentRecord attachment,
  ) async {
    if (attachment.path.trim().isEmpty || attachment.isImportedText) {
      return attachment;
    }
    final source = File(attachment.path);
    if (!await source.exists()) return attachment;
    await _validatePdfSourceForStorage(attachment, source);
    final stagingDir = await _stagingRoot();
    await _createProofDirectory(
      stagingDir,
      'That receipt proof could not be copied into Maintainiac storage.',
    );
    final destination = await _availableDestinationFile(
      stagingDir,
      _storageFileName(attachment, source.path),
    );
    await _ensureStorageForCopy(
      source,
      _storagePurposeFor(attachment),
      'That receipt proof could not be copied into Maintainiac storage.',
    );
    await _copyIntoAppStorage(
      source,
      destination,
      'That receipt proof could not be copied into Maintainiac storage.',
    );
    final inspection = attachment.isPdf
        ? await ReceiptPdfInspector.inspect(destination.path)
        : null;
    return attachment.copyWith(
      path: destination.path,
      originalFileName: _metadataFileName(attachment, source.path),
      mimeType: attachment.mimeType.trim().isEmpty
          ? _mimeTypeFor(attachment.kind)
          : attachment.mimeType,
      byteSize: await _safeLength(destination),
      fileHash: await _safeHash(destination),
      pageCount: inspection?.pageCount ?? attachment.pageCount,
      pageCountStatus:
          inspection?.pageCountStatus ?? attachment.pageCountStatus,
      validationStatus:
          inspection?.validationStatus ?? attachment.validationStatus,
      riskFlags: inspection?.riskFlags ?? attachment.riskFlags,
      documentSignals:
          inspection?.documentSignals ?? attachment.documentSignals,
      isOriginalImmutable: true,
      storageState: ReceiptAttachmentStorageState.staged,
    );
  }

  Future<ReceiptAttachmentRecord> promoteStagedAttachment(
    ReceiptAttachmentRecord attachment,
  ) async {
    if (attachment.storageState != ReceiptAttachmentStorageState.staged) {
      return persistAttachment(attachment);
    }
    final source = File(attachment.path);
    if (!await source.exists()) {
      return attachment.copyWith(
        storageState: ReceiptAttachmentStorageState.missing,
      );
    }
    await _validatePdfSourceForStorage(attachment, source);
    final proofRoot = await _proofRoot();
    final destinationDir = Directory(
      path.join(
        proofRoot.path,
        attachment.isPdf
            ? 'pdfs'
            : attachment.isPhoto
            ? 'photos'
            : 'text',
      ),
    );
    await _createProofDirectory(
      destinationDir,
      'That receipt proof could not be saved into permanent receipt storage.',
    );
    final destination = await _availableDestinationFile(
      destinationDir,
      _storageFileName(attachment, source.path),
    );
    await _ensureStorageForCopy(
      source,
      _storagePurposeFor(attachment),
      'That receipt proof could not be saved into permanent receipt storage.',
    );
    await _copyIntoAppStorage(
      source,
      destination,
      'That receipt proof could not be saved into permanent receipt storage.',
    );
    final inspection = attachment.isPdf
        ? await ReceiptPdfInspector.inspect(destination.path)
        : null;
    try {
      await source.delete();
    } catch (_) {}
    return attachment.copyWith(
      path: destination.path,
      byteSize: await _safeLength(destination),
      fileHash: await _safeHash(destination),
      pageCount: inspection?.pageCount ?? attachment.pageCount,
      pageCountStatus:
          inspection?.pageCountStatus ?? attachment.pageCountStatus,
      validationStatus:
          inspection?.validationStatus ?? attachment.validationStatus,
      riskFlags: inspection?.riskFlags ?? attachment.riskFlags,
      documentSignals:
          inspection?.documentSignals ?? attachment.documentSignals,
      storageState: ReceiptAttachmentStorageState.permanent,
      promotedAt: DateTime.now(),
    );
  }

  Future<void> deleteStagedAttachment(
    ReceiptAttachmentRecord attachment,
  ) async {
    if (attachment.storageState != ReceiptAttachmentStorageState.staged) return;
    final stagingRoot = await _stagingRoot();
    if (!path.isWithin(stagingRoot.path, attachment.path)) return;
    final file = File(attachment.path);
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  Future<void> deleteStagedAttachments(
    Iterable<ReceiptAttachmentRecord> attachments,
  ) async {
    for (final attachment in attachments) {
      await deleteStagedAttachment(attachment);
    }
  }

  Future<void> cleanOrphanProofFiles({
    required Iterable<String> retainedPaths,
  }) async {
    final retained = retainedPaths
        .map((item) => path.normalize(item.trim()))
        .where((item) => item.isNotEmpty)
        .toSet();
    final root = await _proofRoot();
    if (!await root.exists()) return;
    await for (final entity in root.list(recursive: true)) {
      if (entity is! File) continue;
      final normalized = path.normalize(entity.path);
      if (retained.contains(normalized)) continue;
      try {
        await entity.delete();
      } catch (_) {
        continue;
      }
    }
  }

  Future<void> cleanOldStagedFiles({
    required Iterable<String> retainedPaths,
    Duration olderThan = const Duration(days: 7),
    DateTime? now,
  }) async {
    final retained = retainedPaths
        .map((item) => path.normalize(item.trim()))
        .where((item) => item.isNotEmpty)
        .toSet();
    final root = await _stagingRoot();
    if (!await root.exists()) return;
    final cutoff = (now ?? DateTime.now()).subtract(olderThan);
    await for (final entity in root.list(recursive: true)) {
      if (entity is! File) continue;
      final normalized = path.normalize(entity.path);
      if (retained.contains(normalized)) continue;
      try {
        final stat = await entity.stat();
        if (stat.modified.isAfter(cutoff)) continue;
        await entity.delete();
      } catch (_) {
        continue;
      }
    }
  }

  Future<void> _rollbackPersistedBatch(
    List<ReceiptAttachmentRecord> saved,
    List<ReceiptAttachmentRecord> original,
  ) async {
    final originalById = {
      for (final attachment in original) attachment.id: attachment,
    };
    final originalPaths = original
        .map((item) => path.normalize(item.path.trim()))
        .where((item) => item.isNotEmpty)
        .toSet();
    final root = await _proofRoot();
    for (final attachment in saved) {
      if (attachment.path.trim().isEmpty || attachment.isImportedText) {
        continue;
      }
      final normalized = path.normalize(attachment.path);
      if (originalPaths.contains(normalized)) continue;
      if (!path.isWithin(root.path, attachment.path)) continue;
      await _restoreStagedSourceIfNeeded(
        attachment,
        originalById[attachment.id],
      );
      await _deleteIfExists(File(attachment.path));
    }
  }

  Future<void> _restoreStagedSourceIfNeeded(
    ReceiptAttachmentRecord saved,
    ReceiptAttachmentRecord? original,
  ) async {
    if (original == null ||
        original.storageState != ReceiptAttachmentStorageState.staged ||
        original.path.trim().isEmpty ||
        saved.path.trim().isEmpty ||
        path.normalize(original.path) == path.normalize(saved.path)) {
      return;
    }
    final staged = File(original.path);
    if (await staged.exists()) return;
    try {
      await staged.parent.create(recursive: true);
      await File(saved.path).copy(staged.path);
    } catch (_) {}
  }

  Future<Directory> _proofRoot() async {
    final directory = await getApplicationDocumentsDirectory();
    return Directory(path.join(directory.path, 'receipt_proofs'));
  }

  Future<Directory> _stagingRoot() async {
    final directory = await getApplicationDocumentsDirectory();
    return Directory(path.join(directory.path, 'receipt_proofs_staging'));
  }

  Future<int?> _safeLength(File file) async {
    try {
      return await file.length();
    } catch (_) {
      return null;
    }
  }

  Future<String> _safeHash(File file) async {
    try {
      return (await sha256.bind(file.openRead()).first).toString();
    } catch (_) {
      return '';
    }
  }

  Future<void> _deleteIfExists(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  Future<File> _availableDestinationFile(
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
    throw const ReceiptProofStorageException(
      'That receipt proof could not be saved because Maintainiac could not create a safe file name.',
    );
  }

  Future<void> _createProofDirectory(
    Directory directory,
    String message,
  ) async {
    try {
      await directory.create(recursive: true);
    } catch (_) {
      throw ReceiptProofStorageException(message);
    }
  }

  Future<void> _validatePdfSourceForStorage(
    ReceiptAttachmentRecord attachment,
    File source,
  ) async {
    if (!attachment.isPdf) return;
    final inspection = await ReceiptPdfInspector.inspect(source.path);
    final blocker = inspection.importBlocker;
    if (blocker == null) return;
    throw ReceiptProofStorageException(blocker);
  }

  String _mimeTypeFor(ReceiptAttachmentKind kind) {
    return switch (kind) {
      ReceiptAttachmentKind.pdf => 'application/pdf',
      ReceiptAttachmentKind.photo => 'image/*',
      ReceiptAttachmentKind.emailText ||
      ReceiptAttachmentKind.textMessageText => 'text/plain',
    };
  }

  ReceiptStoragePurpose _storagePurposeFor(ReceiptAttachmentRecord attachment) {
    return attachment.isPdf
        ? ReceiptStoragePurpose.importPdf
        : ReceiptStoragePurpose.savePhotos;
  }

  Future<void> _ensureStorageForCopy(
    File source,
    ReceiptStoragePurpose purpose,
    String fallbackMessage,
  ) async {
    final sourceBytes = await _safeLength(source);
    if (sourceBytes == null) {
      throw ReceiptProofStorageException(fallbackMessage);
    }
    final requiredBytes = sourceBytes + (2 * 1024 * 1024);
    final storageCheck = await ReceiptStorageGuard.checkForBytes(
      requiredBytes: requiredBytes,
      purpose: purpose,
    );
    if (!storageCheck.hasEnoughSpace) {
      throw ReceiptProofStorageException(storageCheck.blockingMessage(purpose));
    }
    if (storageCheck.canVerify && storageCheck.availableBytes == null) {
      throw ReceiptProofStorageException(fallbackMessage);
    }
  }
}
