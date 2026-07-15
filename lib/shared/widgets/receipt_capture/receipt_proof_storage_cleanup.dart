part of 'receipt_proof_storage.dart';

extension ReceiptProofStorageCleanup on ReceiptProofStorage {
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
    // Permanent receipt evidence is never garbage-collected from a path list.
    // A temporary incomplete index, interrupted restore, or delayed record
    // write must not turn a user's proof into an "orphan". Only explicitly
    // discarded drafts may remove their own staged, app-owned copies.
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
}
