part of 'receipt_proof_storage.dart';

extension ReceiptProofStorageCleanup on ReceiptProofStorage {
  Future<void> deleteStagedAttachment(
    ReceiptAttachmentRecord attachment,
  ) async {
    if (attachment.storageState != ReceiptAttachmentStorageState.staged) return;
    final stagingRoot = await _stagingRoot();
    final file = File(attachment.path);
    try {
      if (!await file.exists()) return;
      final resolvedRoot = path.normalize(
        await stagingRoot.resolveSymbolicLinks(),
      );
      final resolvedFile = path.normalize(await file.resolveSymbolicLinks());
      if (!path.isWithin(resolvedRoot, resolvedFile)) return;
      await file.delete();
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
    // Kept as a compatibility hook for callers from older branches. Receipt
    // staging can represent the only recovery point after an interruption, so
    // elapsed time and an incomplete retained-path index never authorize
    // deletion. Explicit discard/completion paths own cleanup instead.
  }
}
