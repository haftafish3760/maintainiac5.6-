import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

import 'package:maintaniac/screens/expenses/data/expense_cloud_proof_storage.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_storage_guard.dart';

typedef ExpenseCloudProofCacheRoot = Future<Directory> Function();
typedef ExpenseCloudProofCacheSpaceCheck = Future<void> Function(int byteCount);

/// App-owned, integrity-checked cache for cloud-backed proof files.
///
/// A cache hit never consumes cloud retrieval allowance. A corrupt cache entry
/// is retained under an app-owned recovery name until a verified replacement is
/// durable; no source proof or user-owned file is ever removed here.
class ExpenseCloudProofCache {
  ExpenseCloudProofCache({
    required ExpenseCloudProofStorage cloudStorage,
    ExpenseCloudProofCacheRoot? rootDirectory,
    ExpenseCloudProofCacheSpaceCheck? ensureSpace,
  }) : _cloudStorage = cloudStorage,
       _rootDirectory = rootDirectory ?? _defaultRootDirectory,
       _ensureSpace = ensureSpace ?? _ensureDefaultSpace;

  final ExpenseCloudProofStorage _cloudStorage;
  final ExpenseCloudProofCacheRoot _rootDirectory;
  final ExpenseCloudProofCacheSpaceCheck _ensureSpace;
  Future<void> _writeTail = Future<void>.value();

  Future<ExpenseCloudCachedProof> restore(
    ExpenseCloudProofReference reference,
  ) => _enqueue(() => _restore(reference));

  Future<ExpenseCloudCachedProof> _restore(
    ExpenseCloudProofReference reference,
  ) async {
    _validateReference(reference);
    final root = await _rootDirectory();
    final destination = File('${root.path}/${_fileName(reference)}');
    final cached = await _validCachedBytes(destination, reference);
    if (cached != null) {
      return ExpenseCloudCachedProof(file: destination, wasDownloaded: false);
    }

    // A corrupt cache entry is preserved for recovery until the verified
    // replacement is durable, so reserve space for both files during repair.
    final existingBytes = await _safeFileLength(destination);
    await _ensureSpace(reference.byteCount + existingBytes);
    final bytes = await _cloudStorage.downloadProof(reference);
    await _writeVerifiedAtomically(destination, bytes, reference);
    return ExpenseCloudCachedProof(file: destination, wasDownloaded: true);
  }

  Future<void> _writeVerifiedAtomically(
    File destination,
    Uint8List bytes,
    ExpenseCloudProofReference reference,
  ) async {
    if (bytes.length != reference.byteCount ||
        sha256.convert(bytes).toString() != reference.contentHashSha256) {
      throw StateError('Cloud proof contents do not match its durable record.');
    }
    await destination.parent.create(recursive: true);
    final temp = File(
      '${destination.path}.${DateTime.now().microsecondsSinceEpoch}.tmp',
    );
    try {
      await temp.writeAsBytes(bytes, flush: true);
      if (await destination.exists()) {
        final recovery = File(
          '${destination.path}.corrupt.${DateTime.now().microsecondsSinceEpoch}',
        );
        await destination.rename(recovery.path);
      }
      await temp.rename(destination.path);
    } catch (_) {
      if (await temp.exists()) await temp.delete();
      rethrow;
    }
  }

  Future<Uint8List?> _validCachedBytes(
    File file,
    ExpenseCloudProofReference reference,
  ) async {
    if (!await file.exists() || await file.length() != reference.byteCount) {
      return null;
    }
    final bytes = await file.readAsBytes();
    return sha256.convert(bytes).toString() == reference.contentHashSha256
        ? bytes
        : null;
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final result = _writeTail.then((_) => operation());
    _writeTail = result.then<void>((_) {}, onError: (error, stackTrace) {});
    return result;
  }

  static Future<int> _safeFileLength(File file) async {
    try {
      return await file.exists() ? await file.length() : 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<Directory> _defaultRootDirectory() async {
    final support = await getApplicationSupportDirectory();
    return Directory('${support.path}/expense-proof-cache');
  }

  static Future<void> _ensureDefaultSpace(int byteCount) async {
    final check = await ReceiptStorageGuard.checkForBytes(
      requiredBytes: byteCount,
    );
    if (check.canVerify && !check.hasEnoughSpace) {
      throw StateError(check.blockingMessage(ReceiptStoragePurpose.savePhotos));
    }
  }

  static String _fileName(ExpenseCloudProofReference reference) =>
      '${reference.organizationId}--${reference.userId}--${reference.receiptId}'
      '--${reference.proofId}--${reference.contentHashSha256}.proof';

  static void _validateReference(ExpenseCloudProofReference reference) {
    final token = RegExp(r'^[A-Za-z0-9_-]{1,160}$');
    if (!reference.isFinalized ||
        reference.byteCount <= 0 ||
        !reference.contentType.startsWith('image/') ||
        !token.hasMatch(reference.organizationId) ||
        !token.hasMatch(reference.userId) ||
        !token.hasMatch(reference.receiptId) ||
        !token.hasMatch(reference.proofId) ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(reference.contentHashSha256)) {
      throw ArgumentError('Unsafe cloud proof cache reference.');
    }
  }
}

class ExpenseCloudCachedProof {
  const ExpenseCloudCachedProof({
    required this.file,
    required this.wasDownloaded,
  });

  final File file;
  final bool wasDownloaded;
}
