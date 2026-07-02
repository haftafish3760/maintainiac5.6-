part of 'receipt_proof_storage.dart';

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
    await _restoreStagedSourceIfNeeded(attachment, originalById[attachment.id]);
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
  if (!await first.exists() && !await File('${first.path}.partial').exists()) {
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

Future<void> _createProofDirectory(Directory directory, String message) async {
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
