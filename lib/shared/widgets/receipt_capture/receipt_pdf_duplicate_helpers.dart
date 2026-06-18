part of 'receipt_attachment_panel.dart';

bool _isDuplicatePdfSelection(
  ReceiptAttachmentRecord attachment,
  Set<String> selectedHashes,
  Set<String> selectedPaths,
) {
  final hash = attachment.fileHash.trim();
  final path = attachment.path.trim();
  return (hash.isNotEmpty && selectedHashes.contains(hash)) ||
      (path.isNotEmpty && selectedPaths.contains(path));
}

void _rememberPdfSelection(
  ReceiptAttachmentRecord attachment,
  Set<String> selectedHashes,
  Set<String> selectedPaths,
) {
  final hash = attachment.fileHash.trim();
  final path = attachment.path.trim();
  if (hash.isNotEmpty) selectedHashes.add(hash);
  if (path.isNotEmpty) selectedPaths.add(path);
}
