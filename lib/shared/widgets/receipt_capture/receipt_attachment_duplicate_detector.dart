import 'dart:io';

import 'package:crypto/crypto.dart';

import 'receipt_capture_models.dart';

class ReceiptPhotoDuplicateReport {
  const ReceiptPhotoDuplicateReport({required this.duplicateAttachmentIds});

  final Set<String> duplicateAttachmentIds;

  int get duplicateCount => duplicateAttachmentIds.length;
  bool get hasDuplicates => duplicateAttachmentIds.isNotEmpty;
}

/// Exact-content detection only. Similar adjacent receipt sections are never
/// treated as duplicates, so an uncertain image remains available for review.
Future<ReceiptPhotoDuplicateReport> detectDuplicateReceiptPhotos(
  Iterable<ReceiptAttachmentRecord> attachments,
) async {
  final knownHashes = <String>{};
  final duplicates = <String>{};
  for (final attachment in attachments) {
    if (!attachment.isPhoto) continue;
    final hash = await _contentHashFor(attachment);
    if (hash.isEmpty) continue;
    if (!knownHashes.add(hash)) duplicates.add(attachment.id);
  }
  return ReceiptPhotoDuplicateReport(
    duplicateAttachmentIds: Set.unmodifiable(duplicates),
  );
}

Future<String> _contentHashFor(ReceiptAttachmentRecord attachment) async {
  final stored = attachment.fileHash.trim();
  if (stored.isNotEmpty) return stored;
  final source = attachment.path.trim();
  if (source.isEmpty) return '';
  try {
    return (await sha256.bind(File(source).openRead()).first).toString();
  } catch (_) {
    return '';
  }
}
