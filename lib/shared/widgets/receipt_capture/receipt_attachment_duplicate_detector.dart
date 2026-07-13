import 'dart:io';

import 'package:crypto/crypto.dart';

import 'receipt_capture_models.dart';

class ReceiptPhotoDuplicateReport {
  const ReceiptPhotoDuplicateReport({required this.duplicateAttachmentIndexes});

  /// Indexes within the input sequence. Indexes, rather than attachment IDs,
  /// keep a malformed repeated ID from suppressing the original image too.
  final Set<int> duplicateAttachmentIndexes;

  int get duplicateCount => duplicateAttachmentIndexes.length;
  bool get hasDuplicates => duplicateAttachmentIndexes.isNotEmpty;
}

/// Exact-content detection only. Similar adjacent receipt sections are never
/// treated as duplicates, so an uncertain image remains available for review.
Future<ReceiptPhotoDuplicateReport> detectDuplicateReceiptPhotos(
  Iterable<ReceiptAttachmentRecord> attachments,
) async {
  final records = attachments.toList(growable: false);
  final knownHashes = <String>{};
  final duplicateIndexes = <int>{};
  for (var index = 0; index < records.length; index++) {
    final attachment = records[index];
    if (!attachment.isPhoto) continue;
    final hash = await _contentHashFor(attachment);
    if (hash.isEmpty) continue;
    if (!knownHashes.add(hash)) duplicateIndexes.add(index);
  }
  return ReceiptPhotoDuplicateReport(
    duplicateAttachmentIndexes: Set.unmodifiable(duplicateIndexes),
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
