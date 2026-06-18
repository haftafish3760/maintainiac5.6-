part of 'receipt_attachment_panel.dart';

enum _ReceiptAttachmentReadOutcome { read, skipped, unreadable }

class _ReceiptAttachmentReadResult {
  const _ReceiptAttachmentReadResult(this.outcome, [this.warning = '']);

  final _ReceiptAttachmentReadOutcome outcome;
  final String warning;

  bool get didRead => outcome == _ReceiptAttachmentReadOutcome.read;
  bool get wasUnreadable => outcome == _ReceiptAttachmentReadOutcome.unreadable;
}

extension _ReceiptAttachmentOcrActions on _SharedReceiptAttachmentPanelState {
  Future<_ReceiptAttachmentReadResult> _readAttachmentsForReceiptForm(
    List<ReceiptAttachmentRecord> attachments, {
    required String successMessage,
    bool showDisabledMessage = false,
    bool showNoTextMessage = false,
  }) async {
    final readable = attachments
        .where(
          (attachment) =>
              (attachment.isPhoto && attachment.path.trim().isNotEmpty) ||
              (attachment.isPdf && attachment.path.trim().isNotEmpty) ||
              (attachment.isImportedText &&
                  attachment.importedText.trim().isNotEmpty),
        )
        .toList(growable: false);
    final settings = ReceiptCaptureSettingsScope.maybeOf(context);
    if (widget.onImportedText == null ||
        readable.isEmpty ||
        settings?.appAssistedEnabledFor(widget.area) == false) {
      if (showDisabledMessage) {
        _showPickerError('Receipt reading is turned off for this area.');
      }
      return const _ReceiptAttachmentReadResult(
        _ReceiptAttachmentReadOutcome.skipped,
      );
    }
    final result = await const ReceiptOcrService().recognizeTextFromAttachments(
      readable,
    );
    if (!mounted) {
      return const _ReceiptAttachmentReadResult(
        _ReceiptAttachmentReadOutcome.skipped,
      );
    }
    if (!result.hasText) {
      final warning = result.warnings.isEmpty
          ? 'No readable text was found in that receipt.'
          : result.warnings.first;
      if (showNoTextMessage) {
        _showPickerError(warning);
      }
      return _ReceiptAttachmentReadResult(
        _ReceiptAttachmentReadOutcome.unreadable,
        warning,
      );
    }
    widget.onImportedText?.call(result.appFillText);
    _showPickerMessage(
      result.warnings.isEmpty ? successMessage : result.warnings.first,
    );
    return const _ReceiptAttachmentReadResult(
      _ReceiptAttachmentReadOutcome.read,
    );
  }
}
