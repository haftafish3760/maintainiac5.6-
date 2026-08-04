import 'dart:io';

import 'package:path/path.dart' as path;

/// Deletes only image artifacts created by Maintainiac inside system temp.
///
/// Gallery originals, native recovery captures, staged attachments, and saved
/// receipt images are deliberately outside this helper's authority.
class ReceiptTemporaryArtifactCleanup {
  const ReceiptTemporaryArtifactCleanup();

  Future<void> deleteAppOwnedFiles(
    Iterable<String> candidates, {
    Iterable<String> keptPaths = const [],
  }) async {
    final tempRoot = await _resolvedPath(Directory.systemTemp);
    if (tempRoot == null) return;
    final kept = <String>{};
    for (final keptPath in keptPaths) {
      final resolved = await _resolvedPath(File(keptPath));
      if (resolved != null) kept.add(resolved);
    }
    for (final candidate in candidates.toSet()) {
      await _deleteCandidate(candidate, tempRoot: tempRoot, kept: kept);
    }
  }

  Future<void> _deleteCandidate(
    String candidate, {
    required String tempRoot,
    required Set<String> kept,
  }) async {
    final raw = candidate.trim();
    if (raw.isEmpty) return;
    final file = File(raw);
    try {
      if (!await file.exists()) return;
      final resolved = await _resolvedPath(file);
      if (resolved == null || kept.contains(resolved)) return;
      if (!path.isWithin(tempRoot, resolved)) return;
      final name = path.basename(resolved);
      if (!name.startsWith('maintaniac_receipt_') ||
          !name.toLowerCase().endsWith('.jpg')) {
        return;
      }
      await file.delete();
    } catch (_) {
      // Cleanup is best effort. The durable receipt and saved image already
      // exist before this helper is called.
    }
  }

  Future<String?> _resolvedPath(FileSystemEntity entity) async {
    try {
      return path.normalize(await entity.resolveSymbolicLinks());
    } catch (_) {
      return null;
    }
  }
}
