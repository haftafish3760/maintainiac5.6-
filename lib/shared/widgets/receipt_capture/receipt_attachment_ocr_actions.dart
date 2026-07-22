part of 'receipt_attachment_panel.dart';

enum _ReceiptAttachmentReadOutcome { read, skipped, unreadable }

class _ReceiptAttachmentReadResult {
  const _ReceiptAttachmentReadResult(
    this.outcome, {
    this.warning = '',
    this.ocrDiagnostics,
  });

  final _ReceiptAttachmentReadOutcome outcome;
  final String warning;
  final ReceiptOcrDiagnostics? ocrDiagnostics;

  bool get didRead => outcome == _ReceiptAttachmentReadOutcome.read;
  bool get wasUnreadable => outcome == _ReceiptAttachmentReadOutcome.unreadable;
}

Duration _receiptOcrTimeout(
  ReceiptDeviceCapability capability,
  int sourceCount,
) {
  final baseSeconds = switch (capability.tier) {
    ReceiptCapabilityTier.heavyweight => 25,
    ReceiptCapabilityTier.medium => 35,
    ReceiptCapabilityTier.light => 50,
  };
  final perAdditionalSource = switch (capability.tier) {
    ReceiptCapabilityTier.heavyweight => 8,
    ReceiptCapabilityTier.medium => 10,
    ReceiptCapabilityTier.light => 12,
  };
  final seconds =
      baseSeconds + (sourceCount - 1).clamp(0, 4) * perAdditionalSource;
  return Duration(seconds: seconds.clamp(baseSeconds, 90).toInt());
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
    if (widget.onImportedText == null &&
            widget.onReceiptOcrResultForReview == null ||
        readable.isEmpty ||
        !_appAssistedReceiptFillEnabled) {
      if (showDisabledMessage) {
        showPickerError(
          'Automatic receipt filling is turned off for this area.',
        );
      }
      return const _ReceiptAttachmentReadResult(
        _ReceiptAttachmentReadOutcome.skipped,
      );
    }
    final capability =
        settings?.deviceCapability ?? const ReceiptDeviceCapability.standard();
    final cloudAssistPlan = capability.cloudAssistPlanFor(
      dataSaverLevel: settings?.defaultDataSaverLevel ?? _dataSaverLevel,
    );
    final policy = ReceiptAssistancePolicy(
      device: capability,
      cloudAssistedAvailable: cloudAssistPlan.cloudOcrOptional,
    );
    final decision = policy.decideForAttachments(readable);
    if (decision.mode == ReceiptAssistanceMode.proofOnly ||
        decision.mode == ReceiptAssistanceMode.cloudCandidate) {
      final warning = decision.warnings.isEmpty
          ? decision.reason
          : '${decision.reason} ${decision.warnings.first}';
      updateAttachmentState(() {
        _receiptReadStatus = _ReceiptReadStatusKind.warning;
        _receiptReadStatusMessage =
            'Receipt proof saved. This file is too large or not suitable for automatic receipt filling on this device.';
      });
      if (showNoTextMessage || showDisabledMessage) {
        showPickerError(warning);
      }
      return _ReceiptAttachmentReadResult(
        _ReceiptAttachmentReadOutcome.skipped,
        warning: warning,
      );
    }
    final cloudAssistSummary = cloudAssistPlan.hasOptionalCloudAssist
        ? ' Optional cloud help can be offered later if the user chooses it.'
        : '';
    final sourceSummary = _receiptReadSourceSummary(readable);
    final recoveryAdvice = _receiptReadRecoveryAdvice(readable);
    updateAttachmentState(() {
      _readingForReview = true;
      _receiptReadStatus = _ReceiptReadStatusKind.reading;
      _receiptReadProgressPhase = _ReceiptReadProgressPhase.readingText;
      _receiptReadStatusMessage =
          'Reading $sourceSummary. When the details are ready, Maintainiac shows them so you can check the store, date, total, and item lines.$cloudAssistSummary';
    });
    _notifyReceiptReadStarted();
    late final ReceiptOcrResult result;
    try {
      result = await ReceiptOcrService.forDevice(capability)
          .recognizeTextFromAttachments(readable)
          .timeout(_receiptOcrTimeout(capability, readable.length));
    } on TimeoutException {
      if (mounted) {
        updateAttachmentState(() {
          _readingForReview = false;
          _receiptReadStatus = _ReceiptReadStatusKind.failed;
          _receiptReadProgressPhase = _ReceiptReadProgressPhase.idle;
          _receiptReadStatusMessage =
              'Receipt reading took too long on this device. Review the photos and retry, or continue filling the receipt by hand.';
        });
        if (showNoTextMessage) {
          showPickerError(
            'Receipt reading took too long. Review the photos and retry, or continue manually.',
          );
        }
      }
      _notifyReceiptReadFinished(false);
      return const _ReceiptAttachmentReadResult(
        _ReceiptAttachmentReadOutcome.unreadable,
        warning: 'Receipt reading timed out before details could be filled.',
      );
    } catch (_) {
      if (mounted) {
        updateAttachmentState(() {
          _readingForReview = false;
          _receiptReadStatus = _ReceiptReadStatusKind.failed;
          _receiptReadProgressPhase = _ReceiptReadProgressPhase.idle;
          _receiptReadStatusMessage =
              '${recoveryAdvice.failureLead} The app could not finish reading $sourceSummary before the review fields could be filled. ${recoveryAdvice.primaryAction}';
        });
        if (showNoTextMessage) {
          showPickerError(
            '${recoveryAdvice.failureLead} The app could not finish reading $sourceSummary. ${recoveryAdvice.primaryAction}',
          );
        }
      }
      _notifyReceiptReadFinished(false);
      return _ReceiptAttachmentReadResult(
        _ReceiptAttachmentReadOutcome.unreadable,
        warning:
            '${recoveryAdvice.failureLead} Receipt assistance could not fill details for $sourceSummary. ${recoveryAdvice.shortAction}',
      );
    }
    if (!mounted) {
      return const _ReceiptAttachmentReadResult(
        _ReceiptAttachmentReadOutcome.skipped,
      );
    }
    _notifyReceiptOcrCompleted(result);
    if (!result.hasText) {
      final warning = result.strongestActionMessage;
      final resultRecoveryAdvice = _receiptReadRecoveryAdvice(
        readable,
        diagnostics: result.diagnostics,
      );
      updateAttachmentState(() {
        _readingForReview = false;
        _receiptReadStatus = _ReceiptReadStatusKind.failed;
        _receiptReadProgressPhase = _ReceiptReadProgressPhase.idle;
        _receiptReadStatusMessage =
            '${resultRecoveryAdvice.failureLead} $warning ${resultRecoveryAdvice.primaryAction}';
      });
      if (showNoTextMessage) {
        showPickerError(
          '${resultRecoveryAdvice.failureLead} $warning ${resultRecoveryAdvice.primaryAction}',
        );
      }
      _notifyReceiptReadFinished(false);
      return _ReceiptAttachmentReadResult(
        _ReceiptAttachmentReadOutcome.unreadable,
        warning:
            '${resultRecoveryAdvice.failureLead} $warning ${resultRecoveryAdvice.shortAction}',
        ocrDiagnostics: result.diagnostics,
      );
    }
    final message = result.reviewMessage(successMessage: successMessage);
    final onOcrResultForReview = widget.onReceiptOcrResultForReview;
    final onImportedText = widget.onImportedText;
    if (mounted) {
      updateAttachmentState(() {
        _receiptReadProgressPhase = _ReceiptReadProgressPhase.openingDetails;
      });
    }
    if (onOcrResultForReview != null || onImportedText != null) {
      try {
        await Future<void>.sync(
          () => onOcrResultForReview != null
              ? onOcrResultForReview(result)
              : onImportedText!(result.appFillText),
        ).timeout(_receiptOcrTimeout(capability, readable.length));
      } catch (_) {
        if (mounted) {
          updateAttachmentState(() {
            _readingForReview = false;
            _receiptReadStatus = _ReceiptReadStatusKind.failed;
            _receiptReadProgressPhase = _ReceiptReadProgressPhase.idle;
            _receiptReadStatusMessage =
                'Receipt text was read, but the editable receipt details could not open. Keep the proof and fill the receipt by hand.';
          });
          if (showNoTextMessage) {
            showPickerError(
              'Receipt details could not open. Keep the proof and continue filling the receipt by hand.',
            );
          }
        }
        _notifyReceiptReadFinished(false);
        return _ReceiptAttachmentReadResult(
          _ReceiptAttachmentReadOutcome.unreadable,
          warning:
              'Receipt text was read, but editable receipt details could not open. Keep the proof and continue filling the receipt by hand.',
          ocrDiagnostics: result.diagnostics,
        );
      }
    }
    if (!mounted) {
      _notifyReceiptReadFinished(true);
      return _ReceiptAttachmentReadResult(
        _ReceiptAttachmentReadOutcome.read,
        ocrDiagnostics: result.diagnostics,
      );
    }
    final structuredWarnings = result.structuredWarnings;
    updateAttachmentState(() {
      _readingForReview = false;
      _receiptReadStatus =
          structuredWarnings.any(
            (warning) =>
                warning.isBlocking || warning.isPartial || warning.needsReview,
          )
          ? _ReceiptReadStatusKind.warning
          : _ReceiptReadStatusKind.success;
      _receiptReadProgressPhase = _ReceiptReadProgressPhase.openingDetails;
      _receiptReadStatusMessage = message;
    });
    showPickerMessage(message);
    _notifyReceiptReadFinished(true);
    return _ReceiptAttachmentReadResult(
      _ReceiptAttachmentReadOutcome.read,
      ocrDiagnostics: result.diagnostics,
    );
  }

  void _notifyReceiptReadStarted() {
    try {
      widget.onReceiptReadStarted?.call();
    } catch (_) {
      // Status callbacks are optional UI notifications. Their failure must not
      // interrupt local receipt reading or close the capture flow.
    }
  }

  void _notifyReceiptOcrCompleted(ReceiptOcrResult result) {
    try {
      widget.onReceiptOcrCompleted?.call(result);
    } catch (_) {
      // Diagnostics observers cannot be allowed to turn a usable receipt into
      // a crash after text was already read.
    }
  }

  void _notifyReceiptReadFinished(bool succeeded) {
    try {
      widget.onReceiptReadFinished?.call(succeeded);
    } catch (_) {
      // Completion observers are best-effort; the editable form remains the
      // source of user recovery when a surrounding screen is no longer live.
    }
  }
}
