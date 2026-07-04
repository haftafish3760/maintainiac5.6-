part of 'receipt_proof_storage.dart';

String _safeFileName(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '';
  final sanitized = trimmed
      .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')
      .replaceAll(RegExp(r'\.{2,}'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^[._-]+|[._-]+$'), '');
  if (sanitized.isEmpty) return '';
  final reservedSafe = _isWindowsReservedFileName(sanitized)
      ? 'receipt-$sanitized'
      : sanitized;
  return reservedSafe.length <= 90
      ? reservedSafe
      : reservedSafe.substring(0, 90);
}

bool _isWindowsReservedFileName(String value) {
  final baseName = path.basenameWithoutExtension(value).toLowerCase();
  return const {
    'con',
    'prn',
    'aux',
    'nul',
    'com1',
    'com2',
    'com3',
    'com4',
    'com5',
    'com6',
    'com7',
    'com8',
    'com9',
    'lpt1',
    'lpt2',
    'lpt3',
    'lpt4',
    'lpt5',
    'lpt6',
    'lpt7',
    'lpt8',
    'lpt9',
  }.contains(baseName);
}

String _storageFileName(ReceiptAttachmentRecord attachment, String source) {
  final extension = _storageExtensionFor(attachment.kind, source);
  final safeName = _safeFileName(
    attachment.originalFileName.trim().isNotEmpty
        ? attachment.originalFileName
        : attachment.displayName,
  );
  final rawBaseName = safeName.isEmpty
      ? switch (attachment.kind) {
          ReceiptAttachmentKind.pdf => 'receipt-pdf',
          ReceiptAttachmentKind.photo => 'receipt-photo',
          ReceiptAttachmentKind.emailText ||
          ReceiptAttachmentKind.textMessageText => 'receipt-text',
        }
      : path.basenameWithoutExtension(safeName);
  final baseName = _safeFileName(rawBaseName).isEmpty
      ? 'receipt-proof'
      : _safeFileName(rawBaseName);
  final safeId = _safeFileName(attachment.id);
  final idLabel = safeId.isEmpty ? 'receipt' : safeId;
  return '${baseName}_${idLabel}_${DateTime.now().microsecondsSinceEpoch}$extension';
}

String _metadataFileName(ReceiptAttachmentRecord attachment, String source) {
  final candidate = attachment.originalFileName.trim().isNotEmpty
      ? attachment.originalFileName
      : path.basename(source);
  final baseName = _safeFileName(path.basenameWithoutExtension(candidate));
  final safeBaseName = baseName.isEmpty
      ? switch (attachment.kind) {
          ReceiptAttachmentKind.pdf => 'receipt-pdf',
          ReceiptAttachmentKind.photo => 'receipt-photo',
          ReceiptAttachmentKind.emailText ||
          ReceiptAttachmentKind.textMessageText => 'receipt-text',
        }
      : baseName;
  return '$safeBaseName${_storageExtensionFor(attachment.kind, source)}';
}

String _storageExtensionFor(ReceiptAttachmentKind kind, String source) {
  final sourceExtension = path.extension(source).toLowerCase();
  return switch (kind) {
    ReceiptAttachmentKind.pdf => '.pdf',
    ReceiptAttachmentKind.photo =>
      sourceExtension == '.png' ||
              sourceExtension == '.jpg' ||
              sourceExtension == '.jpeg' ||
              sourceExtension == '.webp'
          ? sourceExtension
          : '.jpg',
    ReceiptAttachmentKind.emailText ||
    ReceiptAttachmentKind.textMessageText => '.txt',
  };
}
