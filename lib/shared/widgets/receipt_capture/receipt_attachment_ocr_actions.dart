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
            'Receipt backup image saved. This file is too large or not suitable for app-assisted filling on this device.';
      });
      if (showNoTextMessage || showDisabledMessage) {
        _showPickerError(warning);
      }
      return _ReceiptAttachmentReadResult(
        _ReceiptAttachmentReadOutcome.skipped,
        warning,
      );
    }
    final sourceSummary = _receiptReadSourceSummary(readable);
    final recoveryAdvice = _receiptReadRecoveryAdvice(readable);
    _updateAttachmentState(() {
      _readingForReview = true;
      _receiptReadStatus = _ReceiptReadStatusKind.reading;
      _receiptReadStatusMessage =
          'Preparing $sourceSummary for app assistance. When text is found, Maintainiac shows the receipt details so you can check the store, date, total, and item lines.';
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
              '${recoveryAdvice.failureLead} The app could not finish reading $sourceSummary before the review fields could be filled. ${recoveryAdvice.primaryAction}';
        });
        if (showNoTextMessage) {
          _showPickerError(
            '${recoveryAdvice.failureLead} The app could not finish reading $sourceSummary. ${recoveryAdvice.primaryAction}',
          );
        }
      }
      widget.onReceiptReadFinished?.call(false);
      return _ReceiptAttachmentReadResult(
        _ReceiptAttachmentReadOutcome.unreadable,
        '${recoveryAdvice.failureLead} Receipt reading failed for $sourceSummary. ${recoveryAdvice.shortAction}',
      );
    }
    if (!mounted) {
      return const _ReceiptAttachmentReadResult(
        _ReceiptAttachmentReadOutcome.skipped,
      );
    }
    if (!result.hasText) {
      final warning = result.strongestActionMessage;
      _updateAttachmentState(() {
        _readingForReview = false;
        _receiptReadStatus = _ReceiptReadStatusKind.failed;
        _receiptReadStatusMessage =
            '${recoveryAdvice.failureLead} $warning ${recoveryAdvice.primaryAction}';
      });
      if (showNoTextMessage) {
        _showPickerError(
          '${recoveryAdvice.failureLead} $warning ${recoveryAdvice.primaryAction}',
        );
      }
      widget.onReceiptReadFinished?.call(false);
      return _ReceiptAttachmentReadResult(
        _ReceiptAttachmentReadOutcome.unreadable,
        '${recoveryAdvice.failureLead} $warning ${recoveryAdvice.shortAction}',
      );
    }
    final message = result.reviewMessage(successMessage: successMessage);
    final onImportedText = widget.onImportedText;
    if (onImportedText != null) {
      await Future<void>.sync(() => onImportedText(result.appFillText));
    }
    if (!mounted) {
      widget.onReceiptReadFinished?.call(true);
      return const _ReceiptAttachmentReadResult(
        _ReceiptAttachmentReadOutcome.read,
      );
    }
    final structuredWarnings = result.structuredWarnings;
    _updateAttachmentState(() {
      _readingForReview = false;
      _receiptReadStatus =
          structuredWarnings.any(
            (warning) =>
                warning.isBlocking || warning.isPartial || warning.needsReview,
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

  String _receiptReadSourceSummary(List<ReceiptAttachmentRecord> attachments) {
    final photoCount = attachments
        .where((attachment) => attachment.isPhoto)
        .length;
    final pdfCount = attachments.where((attachment) => attachment.isPdf).length;
    final textCount = attachments
        .where((attachment) => attachment.isImportedText)
        .length;
    final parts = <String>[
      if (photoCount > 0)
        photoCount == 1
            ? '1 clear receipt photo'
            : '$photoCount clear receipt photos',
      if (pdfCount > 0)
        pdfCount == 1 ? '1 receipt PDF' : '$pdfCount receipt PDFs',
      if (textCount > 0)
        textCount == 1
            ? '1 saved receipt text'
            : '$textCount saved receipt texts',
    ];
    if (parts.isEmpty) return 'the receipt proof';
    if (parts.length == 1) return parts.single;
    if (parts.length == 2) return '${parts.first} and ${parts.last}';
    return '${parts.take(parts.length - 1).join(', ')}, and ${parts.last}';
  }

  _ReceiptReadRecoveryAdvice _receiptReadRecoveryAdvice(
    List<ReceiptAttachmentRecord> attachments,
  ) {
    final photoCount = attachments
        .where((attachment) => attachment.isPhoto)
        .length;
    final pdfCount = attachments.where((attachment) => attachment.isPdf).length;
    final textCount = attachments
        .where((attachment) => attachment.isImportedText)
        .length;
    final hasPhoto = photoCount > 0;
    final hasPdf = pdfCount > 0;
    final hasText = textCount > 0;
    if (hasPhoto && !hasPdf && !hasText) {
      if (photoCount > 1) {
        return const _ReceiptReadRecoveryAdvice(
          failureLead: 'Receipt photo text was not readable enough.',
          primaryAction:
              'Keep the proof attached, check the photo order, add a clearer missing section, or continue by hand.',
          shortAction:
              'Check photo order, add a clearer section, or continue by hand.',
        );
      }
      return const _ReceiptReadRecoveryAdvice(
        failureLead: 'Receipt photo text was not readable enough.',
        primaryAction:
            'Keep the proof attached, retake with brighter light and the full receipt in frame, add another photo if it is long, or continue by hand.',
        shortAction:
            'Retake, add another photo if needed, or continue by hand.',
      );
    }
    if (hasPdf && !hasPhoto && !hasText) {
      return const _ReceiptReadRecoveryAdvice(
        failureLead: 'Receipt PDF text was not readable enough.',
        primaryAction:
            'Keep the PDF proof attached, add a clear receipt photo if you have one, or continue by hand.',
        shortAction:
            'Add a clear receipt photo if available, or continue by hand.',
      );
    }
    if (hasText && !hasPhoto && !hasPdf) {
      return const _ReceiptReadRecoveryAdvice(
        failureLead: 'Saved receipt text could not be used to fill the form.',
        primaryAction:
            'Keep the saved text proof, paste cleaner receipt text, attach a clear photo, or continue by hand.',
        shortAction:
            'Paste cleaner text, attach a clear photo, or continue by hand.',
      );
    }
    if (hasPhoto || hasPdf || hasText) {
      return const _ReceiptReadRecoveryAdvice(
        failureLead: 'Receipt sources were not readable enough.',
        primaryAction:
            'Keep the proof attached, choose the clearest source, add a clearer receipt photo, or continue by hand.',
        shortAction:
            'Choose the clearest source, add a clearer photo, or continue by hand.',
      );
    }
    return const _ReceiptReadRecoveryAdvice(
      failureLead: 'Receipt proof was not readable enough.',
      primaryAction:
          'Attach a clear receipt photo, import a readable PDF, paste receipt text, or continue by hand.',
      shortAction: 'Attach a clear proof or continue by hand.',
    );
  }
}

class _ReceiptReadRecoveryAdvice {
  const _ReceiptReadRecoveryAdvice({
    required this.failureLead,
    required this.primaryAction,
    required this.shortAction,
  });

  final String failureLead;
  final String primaryAction;
  final String shortAction;
}
