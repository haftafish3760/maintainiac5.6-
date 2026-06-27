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
    final capability =
        settings?.deviceCapability ?? const ReceiptDeviceCapability.standard();
    final policy = ReceiptAssistancePolicy(device: capability);
    final decision = policy.decideForAttachments(readable);
    if (decision.mode == ReceiptAssistanceMode.proofOnly ||
        decision.mode == ReceiptAssistanceMode.cloudCandidate) {
      final warning = decision.warnings.isEmpty
          ? decision.reason
          : '${decision.reason} ${decision.warnings.first}';
      _updateAttachmentState(() {
        _receiptReadStatus = _ReceiptReadStatusKind.warning;
        _receiptReadStatusMessage =
            'Receipt proof saved. This file is too large or not suitable for app-assisted filling on this device.';
      });
      if (showNoTextMessage || showDisabledMessage) {
        _showPickerError(warning);
      }
      return _ReceiptAttachmentReadResult(
        _ReceiptAttachmentReadOutcome.skipped,
        warning,
      );
    }
    _updateAttachmentState(() {
      _readingForReview = true;
      _receiptReadStatus = _ReceiptReadStatusKind.reading;
      _receiptReadStatusMessage =
          'Reading the clear receipt image now. If text is found, the filled receipt review appears below.';
    });
    widget.onReceiptReadStarted?.call();
    late final ReceiptOcrResult result;
    try {
      result = await ReceiptOcrService.forDevice(
        capability,
      ).recognizeTextFromAttachments(readable);
    } catch (_) {
      if (mounted) {
        _updateAttachmentState(() {
          _readingForReview = false;
          _receiptReadStatus = _ReceiptReadStatusKind.failed;
          _receiptReadStatusMessage =
              'Receipt reading failed before the review fields could be filled. Keep the proof or try a clearer photo.';
        });
        if (showNoTextMessage) {
          _showPickerError('Receipt reading failed. Try another photo.');
        }
      }
      widget.onReceiptReadFinished?.call(false);
      return const _ReceiptAttachmentReadResult(
        _ReceiptAttachmentReadOutcome.unreadable,
        'Receipt reading failed.',
      );
    }
    if (!mounted) {
      return const _ReceiptAttachmentReadResult(
        _ReceiptAttachmentReadOutcome.skipped,
      );
    }
    if (!result.hasText) {
      final warning = result.structuredWarnings.isEmpty
          ? 'No readable text was found in that receipt.'
          : result.structuredWarnings.first.reviewMessage;
      _updateAttachmentState(() {
        _readingForReview = false;
        _receiptReadStatus = _ReceiptReadStatusKind.failed;
        _receiptReadStatusMessage =
            'No readable receipt text was found. Keep the proof, add another photo, or retake with brighter light.';
      });
      if (showNoTextMessage) {
        _showPickerError(warning);
      }
      widget.onReceiptReadFinished?.call(false);
      return _ReceiptAttachmentReadResult(
        _ReceiptAttachmentReadOutcome.unreadable,
        warning,
      );
    }
    final message = result.reviewMessage(successMessage: successMessage);
    final onImportedText = widget.onImportedText;
    if (onImportedText != null) {
      await Future<void>.sync(() => onImportedText(result.appFillText));
    }
    _updateAttachmentState(() {
      _readingForReview = false;
      _receiptReadStatus =
          result.structuredWarnings.any(
            (warning) => warning.isBlocking || warning.isPartial,
          )
          ? _ReceiptReadStatusKind.warning
          : _ReceiptReadStatusKind.success;
      _receiptReadStatusMessage = message;
    });
    _showPickerMessage(message);
    widget.onReceiptReadFinished?.call(true);
    return const _ReceiptAttachmentReadResult(
      _ReceiptAttachmentReadOutcome.read,
    );
  }
}
