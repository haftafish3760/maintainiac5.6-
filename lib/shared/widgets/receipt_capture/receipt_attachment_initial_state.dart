part of 'receipt_attachment_panel.dart';

extension _ReceiptAttachmentInitialState on _SharedReceiptAttachmentPanelState {
  void _applyInitialAttachments(List<ReceiptAttachmentRecord> attachments) {
    final photoAttachments = _normalizedInitialPhotoAttachments(attachments);
    _photoPaths
      ..clear()
      ..addAll(photoAttachments.map((attachment) => attachment.path));
    _photoIdByPath
      ..clear()
      ..addEntries(
        photoAttachments
            .where((attachment) => attachment.id.trim().isNotEmpty)
            .map((attachment) => MapEntry(attachment.path, attachment.id)),
      );
    _photoQualityByPath
      ..clear()
      ..addEntries(
        photoAttachments.map((attachment) {
          final quality = qualityCheckFromAttachment(attachment);
          return quality == null ? null : MapEntry(attachment.path, quality);
        }).whereType<MapEntry<String, ReceiptPhotoQualityCheck>>(),
      );
    _photoCaptureDiagnosticsByPath.clear();
    _photoReadStateByPath
      ..clear()
      ..addEntries(
        photoAttachments.map(
          (attachment) => MapEntry(attachment.path, attachment.readState),
        ),
      );
    _documentAttachments
      ..clear()
      ..addAll(attachments.where((attachment) => !attachment.isPhoto));
    if (attachments.isNotEmpty) {
      _dataSaverLevel = attachments.last.dataSaverLevel;
    }
  }

  List<ReceiptAttachmentRecord> _normalizedInitialPhotoAttachments(
    List<ReceiptAttachmentRecord> attachments,
  ) {
    final normalized = <ReceiptAttachmentRecord>[];
    final seenPaths = <String>{};
    for (final attachment in attachments) {
      if (!attachment.isPhoto) continue;
      final path = attachment.path.trim();
      if (path.isEmpty || !seenPaths.add(path)) continue;
      normalized.add(attachment.copyWith(path: path));
    }
    return List.unmodifiable(normalized);
  }
}
