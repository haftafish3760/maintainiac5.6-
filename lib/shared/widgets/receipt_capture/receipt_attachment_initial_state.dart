part of 'receipt_attachment_panel.dart';

extension _ReceiptAttachmentInitialState on _SharedReceiptAttachmentPanelState {
  void _applyInitialAttachments(List<ReceiptAttachmentRecord> attachments) {
    _photoPaths
      ..clear()
      ..addAll(
        attachments
            .where((attachment) => attachment.isPhoto)
            .map((attachment) => attachment.path)
            .where((path) => path.trim().isNotEmpty),
      );
    _photoIdByPath
      ..clear()
      ..addEntries(
        attachments
            .where((attachment) => attachment.isPhoto)
            .where((attachment) => attachment.path.trim().isNotEmpty)
            .where((attachment) => attachment.id.trim().isNotEmpty)
            .map((attachment) => MapEntry(attachment.path, attachment.id)),
      );
    _photoQualityByPath
      ..clear()
      ..addEntries(
        attachments
            .where((attachment) => attachment.isPhoto)
            .where((attachment) => attachment.path.trim().isNotEmpty)
            .map((attachment) {
              final quality = qualityCheckFromAttachment(attachment);
              return quality == null
                  ? null
                  : MapEntry(attachment.path, quality);
            })
            .whereType<MapEntry<String, ReceiptPhotoQualityCheck>>(),
      );
    _photoCaptureDiagnosticsByPath.clear();
    _photoReadStateByPath
      ..clear()
      ..addEntries(
        attachments
            .where((attachment) => attachment.isPhoto)
            .where((attachment) => attachment.path.trim().isNotEmpty)
            .map(
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
}
