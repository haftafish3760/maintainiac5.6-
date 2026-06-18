part of 'receipt_proof_storage.dart';

extension ReceiptProofStorageCopy on ReceiptProofStorage {
  Future<void> _copyIntoAppStorage(
    File source,
    File destination,
    String message,
  ) async {
    final temp = File('${destination.path}.partial');
    try {
      await _deleteIfExists(temp);
      await source.copy(temp.path);
      final copiedBytes = await _safeLength(temp);
      final sourceBytes = await _safeLength(source);
      if (copiedBytes == null ||
          sourceBytes == null ||
          copiedBytes != sourceBytes) {
        throw const FileSystemException('Receipt proof copy was incomplete.');
      }
      final sourceHash = await _safeHash(source);
      final copiedHash = await _safeHash(temp);
      if (sourceHash.isEmpty ||
          copiedHash.isEmpty ||
          sourceHash != copiedHash) {
        throw const FileSystemException('Receipt proof copy did not verify.');
      }
      await _deleteIfExists(destination);
      await temp.rename(destination.path);
    } catch (_) {
      await _deleteIfExists(temp);
      await _deleteIfExists(destination);
      throw ReceiptProofStorageException(message);
    }
  }
}
