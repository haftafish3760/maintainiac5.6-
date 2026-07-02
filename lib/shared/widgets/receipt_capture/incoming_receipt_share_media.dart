part of 'incoming_receipt_share.dart';

List<ReceiptAttachmentRecord> receiptAttachmentsFromSharedMedia(
  List<SharedMediaFile> media, {
  DateTime? receivedAt,
}) {
  final now = receivedAt ?? DateTime.now();
  final attachments = <ReceiptAttachmentRecord>[];
  for (var index = 0; index < media.length; index += 1) {
    final attachment = _attachmentFromSharedMedia(media[index], now, index);
    if (attachment != null) attachments.add(attachment);
  }
  return attachments;
}

ReceiptAttachmentRecord? _attachmentFromSharedMedia(
  SharedMediaFile media,
  DateTime receivedAt,
  int index,
) {
  final path = _normalizedSharedPath(media.path);
  final mime = media.mimeType?.toLowerCase().trim() ?? '';
  final lowerPath = path.toLowerCase();
  final displayName = _displayNameFromPath(path);
  final id = 'SHARE-${receivedAt.microsecondsSinceEpoch}-$index';

  if (media.type == SharedMediaType.url) return null;

  if (media.type == SharedMediaType.text) {
    return ReceiptAttachmentRecord(
      id: id,
      path: '',
      kind: ReceiptAttachmentKind.emailText,
      dataSaverLevel: ReceiptDataSaverLevel.original,
      createdAt: receivedAt,
      displayName: displayName.isEmpty ? 'Shared receipt text' : displayName,
      importedText: path,
      sourceLabel: 'Shared',
    );
  }

  if (media.type == SharedMediaType.image ||
      mime.startsWith('image/') ||
      _hasImageExtension(lowerPath)) {
    return ReceiptAttachmentRecord(
      id: id,
      path: path,
      kind: ReceiptAttachmentKind.photo,
      dataSaverLevel: ReceiptDataSaverLevel.original,
      createdAt: receivedAt,
      displayName: displayName.isEmpty ? 'Shared receipt image' : displayName,
      originalFileName: displayName,
      mimeType: mime.isEmpty ? 'image/*' : mime,
      byteSize: _fileSize(path),
      sourceLabel: 'Shared',
    );
  }

  if (mime == 'application/pdf' ||
      mime == 'application/x-pdf' ||
      mime == 'application/acrobat' ||
      mime == 'application/vnd.pdf' ||
      mime == 'application/octet-stream' ||
      lowerPath.endsWith('.pdf')) {
    return ReceiptAttachmentRecord(
      id: id,
      path: path,
      kind: ReceiptAttachmentKind.pdf,
      dataSaverLevel: ReceiptDataSaverLevel.original,
      createdAt: receivedAt,
      displayName: displayName.isEmpty ? 'Shared receipt PDF' : displayName,
      originalFileName: displayName,
      mimeType: mime.isEmpty ? 'application/pdf' : mime,
      byteSize: _fileSize(path),
      pageCountStatus: ReceiptPdfPageCountStatus.unknown,
      validationStatus: ReceiptPdfValidationStatus.notChecked,
      sourceLabel: 'Shared',
    );
  }

  if (mime.startsWith('text/')) {
    return ReceiptAttachmentRecord(
      id: id,
      path: '',
      kind: ReceiptAttachmentKind.emailText,
      dataSaverLevel: ReceiptDataSaverLevel.original,
      createdAt: receivedAt,
      displayName: displayName.isEmpty ? 'Shared receipt text' : displayName,
      importedText: path,
      sourceLabel: 'Shared',
    );
  }

  return null;
}

bool _hasImageExtension(String path) {
  return path.endsWith('.jpg') ||
      path.endsWith('.jpeg') ||
      path.endsWith('.png') ||
      path.endsWith('.webp') ||
      path.endsWith('.heic') ||
      path.endsWith('.heif');
}

String _displayNameFromPath(String path) {
  final trimmed = path.trim();
  if (trimmed.isEmpty || trimmed.contains('\n')) return '';
  final slash = trimmed.lastIndexOf('/');
  final rawName = slash == -1 ? trimmed : trimmed.substring(slash + 1);
  return _safeDecodePathComponent(rawName);
}

String _safeDecodePathComponent(String value) {
  try {
    return Uri.decodeComponent(value);
  } catch (_) {
    return value;
  }
}

String _normalizedSharedPath(String value) {
  final trimmed = value.trim();
  if (trimmed.startsWith('file://')) {
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.isScheme('file')) return uri.toFilePath();
  }
  return trimmed;
}

int? _fileSize(String path) {
  try {
    final file = File(path);
    if (!file.existsSync()) return null;
    return file.lengthSync();
  } catch (_) {
    return null;
  }
}

String _unsupportedSharedMediaMessage(SharedMediaFile media) {
  final path = _normalizedSharedPath(media.path);
  final name = _displayNameFromPath(path);
  if (media.type == SharedMediaType.url) {
    return 'Maintainiac received a link, not a receipt file. Open the link, save or share the actual PDF/photo receipt, then import it again.';
  }
  final label = name.isEmpty ? 'That shared item' : name;
  final mime = media.mimeType?.trim();
  final typeLabel = mime == null || mime.isEmpty
      ? media.type.name
      : '$mime ${media.type.name}';
  return '$label could not be imported as receipt proof. Share a PDF, receipt photo, or receipt text instead. File type: $typeLabel.';
}
