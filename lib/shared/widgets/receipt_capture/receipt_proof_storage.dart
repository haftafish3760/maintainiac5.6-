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
part 'receipt_proof_storage_helpers.dart';
part 'receipt_proof_storage_cleanup.dart';

Future<void> _receiptProofWriteTail = Future<void>.value();

class ReceiptProofStorage {
  const ReceiptProofStorage._();

  static const instance = ReceiptProofStorage._();

  /// True only for a completed regular file inside Maintainiac's private proof
  /// root. External, staged, missing, and symbolic-link paths are rejected.
  Future<bool> isManagedPermanentProofPath(String filePath) async {
    final clean = filePath.trim();
    if (clean.isEmpty) return false;
    final proofRoot = await _proofRoot();
    final stagingRoot = await _stagingRoot();
    if (!path.isWithin(proofRoot.path, clean) ||
        path.isWithin(stagingRoot.path, clean) ||
        await FileSystemEntity.type(clean, followLinks: false) !=
            FileSystemEntityType.file) {
      return false;
    }
    try {
      final resolvedProofRoot = await proofRoot.resolveSymbolicLinks();
      final resolvedFile = await File(clean).resolveSymbolicLinks();
      return path.isWithin(resolvedProofRoot, resolvedFile);
    } on FileSystemException {
      return false;
    }
  }

  /// Explicitly removes only an already-verified app-managed permanent proof.
  /// Receipt deletion does not call this automatically.
  Future<bool> removeManagedPermanentProof(String filePath) =>
      _enqueue(() => _removeManagedPermanentProof(filePath));

  Future<bool> _removeManagedPermanentProof(String filePath) async {
    if (!await isManagedPermanentProofPath(filePath)) return false;
    try {
      await File(filePath.trim()).delete();
      return true;
    } on FileSystemException {
      return false;
    }
  }

  Future<List<ReceiptAttachmentRecord>> persistAttachments(
    List<ReceiptAttachmentRecord> attachments, {
    bool retainStagedSources = false,
  }) => _enqueue(
    () => _persistAttachments(
      attachments,
      retainStagedSources: retainStagedSources,
    ),
  );

  Future<List<ReceiptAttachmentRecord>> _persistAttachments(
    List<ReceiptAttachmentRecord> attachments, {
    required bool retainStagedSources,
  }) async {
    final saved = <ReceiptAttachmentRecord>[];
    try {
      for (final attachment in attachments) {
        final persisted = await _persistAttachment(
          attachment,
          retainStagedSource: retainStagedSources,
        );
        saved.add(persisted);
      }
    } catch (_) {
      await _rollbackPersistedBatch(saved, attachments);
      rethrow;
    }
    return saved;
  }

  Future<ReceiptAttachmentRecord> persistAttachment(
    ReceiptAttachmentRecord attachment, {
    bool retainStagedSource = false,
  }) => _enqueue(
    () =>
        _persistAttachment(attachment, retainStagedSource: retainStagedSource),
  );

  Future<ReceiptAttachmentRecord> _persistAttachment(
    ReceiptAttachmentRecord attachment, {
    bool retainStagedSource = false,
  }) async {
    if (attachment.path.trim().isEmpty || attachment.isImportedText) {
      return attachment;
    }
    final source = File(attachment.path);
    if (!await source.exists()) {
      return attachment.copyWith(
        storageState: ReceiptAttachmentStorageState.missing,
      );
    }
    await _validatePdfSourceForStorage(attachment, source);

    final proofRoot = await _proofRoot();
    if (attachment.storageState == ReceiptAttachmentStorageState.staged) {
      return _promoteStagedAttachment(
        attachment,
        retainStagedSource: retainStagedSource,
      );
    }
    if (path.isWithin(proofRoot.path, source.path)) {
      final currentHash = await _safeHash(source);
      // A previously saved immutable proof must never silently adopt a new
      // hash. Treat changed or unreadable bytes as unavailable evidence so the
      // record retains its original fingerprint and asks for recovery.
      if (attachment.fileHash.trim().isNotEmpty &&
          (currentHash.isEmpty || currentHash != attachment.fileHash)) {
        return attachment.copyWith(
          storageState: ReceiptAttachmentStorageState.missing,
        );
      }
      final inspection = attachment.isPdf
          ? await ReceiptPdfInspector.inspect(source.path)
          : null;
      return attachment.copyWith(
        byteSize: await _safeLength(source),
        fileHash: currentHash,
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
        originalFileName: attachment.originalFileName.trim().isEmpty
            ? path.basename(source.path)
            : attachment.originalFileName,
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
      originalFileName: attachment.originalFileName.trim().isEmpty
          ? path.basename(source.path)
          : attachment.originalFileName,
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
  ) => _enqueue(() => _stageAttachment(attachment));

  Future<ReceiptAttachmentRecord> _stageAttachment(
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
      originalFileName: attachment.originalFileName.trim().isEmpty
          ? path.basename(source.path)
          : attachment.originalFileName,
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
    ReceiptAttachmentRecord attachment, {
    bool retainStagedSource = false,
  }) => _enqueue(
    () => _promoteStagedAttachment(
      attachment,
      retainStagedSource: retainStagedSource,
    ),
  );

  Future<ReceiptAttachmentRecord> _promoteStagedAttachment(
    ReceiptAttachmentRecord attachment, {
    bool retainStagedSource = false,
  }) async {
    if (attachment.storageState != ReceiptAttachmentStorageState.staged) {
      return _persistAttachment(attachment);
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
    final stagingRoot = await _stagingRoot();
    if (!retainStagedSource && path.isWithin(stagingRoot.path, source.path)) {
      try {
        await source.delete();
      } catch (_) {}
    }
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

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final next = _receiptProofWriteTail.then((_) => operation());
    _receiptProofWriteTail = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }
}
