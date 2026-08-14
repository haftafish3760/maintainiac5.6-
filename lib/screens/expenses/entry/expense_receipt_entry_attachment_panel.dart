part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptEntryAttachmentPanel
    on _ExpenseReceiptEntryScreenState {
  Widget _buildReceiptAttachmentPanel(
    BuildContext context, {
    ReceiptAttachmentPanelController? controller,
  }) {
    final receiptSettings = ReceiptCaptureSettingsScope.maybeOf(context);
    final startsWithAssistedCapture =
        _usesRebuiltManualDetailedReceiptFlow &&
        receiptSettings?.appAssistedEnabledFor(_receiptCaptureArea) == true;
    return SharedReceiptAttachmentPanel(
      controller: controller,
      hasReceipt: _hasReceipt,
      area: _receiptCaptureArea,
      // General receipts choose their method on the visible Add Receipt screen.
      // A setting must never open camera/import over that choice or force a
      // person who wants manual entry into receipt capture. Specialized forms
      // retain their established lane-owned behavior.
      openImportOptionsOnFirstBuild:
          !_usesRebuiltManualDetailedReceiptFlow &&
          !_isEditingReceipt &&
          !_hasReceipt &&
          _receiptAttachments.isEmpty &&
          _rawReceiptText.isEmpty &&
          receiptSettings?.appAssistedEnabledFor(_receiptCaptureArea) == true,
      closeParentWhenImportCanceled:
          !_usesRebuiltManualDetailedReceiptFlow && startsWithAssistedCapture,
      showInterruptedCaptureRecovery: widget.showInterruptedCaptureRecovery,
      initialAttachments: _receiptAttachments,
      receiptContinuationReasonCode:
          _lastOcrDiagnostics?.receiptMayNeedBottomSection == true
          ? _lastOcrDiagnostics?.receiptCompletionReviewReasonCode
          : null,
      receiptContinuationGuidance:
          _lastOcrDiagnostics?.receiptMayNeedBottomSection == true
          ? _lastOcrDiagnostics?.receiptMissingBottomEdgeAndTotals == true
                ? 'Add the bottom receipt section. Repeat 3-5 readable lines from the previous photo in the top reference strip so subtotal, total, and final lines can be lined up.'
                : 'Add the lower receipt section if the receipt continues. Repeat 3-5 readable lines in the top reference strip so duplicate lines can be lined up.'
          : null,
      onChanged: (value) {
        _setReceiptEntryState(() => _hasReceipt = value);
        _scheduleDraftSave();
      },
      onAttachmentsChanged: (attachments) {
        final previousCount = _lastAttachmentCount;
        _setReceiptEntryState(() {
          _receiptAttachments
            ..clear()
            ..addAll(attachments);
          _hasReceipt = attachments.isNotEmpty;
        });
        _lastAttachmentCount = attachments.length;
        if (attachments.length > previousCount) {
          final newest = attachments.last;
          ExpenseScreenTelemetryRecorder.record(
            context,
            ExpenseTelemetryEventType.imageAttachSuccess,
            metadata: {
              'attachmentKind': newest.kind.name,
              'bytesBucket': _byteBucket(newest.byteSize),
            },
          );
          ExpenseScreenTelemetryRecorder.record(
            context,
            ExpenseTelemetryEventType.storageModeUsed,
            metadata: {
              'storageAction':
                  ExpenseScreenTelemetryRecorder.storageModeForAttachment(
                    newest,
                  ).name,
            },
          );
        } else if (attachments.length < previousCount) {
          ExpenseScreenTelemetryRecorder.record(
            context,
            ExpenseTelemetryEventType.localImageRemoved,
            metadata: {'storageAction': 'attachment_removed'},
          );
        }
        _scheduleDraftSave();
      },
      onImportedText: _parseImportedReceiptText,
      onReceiptPhotoReviewAccepted: _markReceiptPhotoReviewAccepted,
      onReceiptPhotoReviewExitRequested: _handleReceiptPhotoReviewExitRequested,
      onReceiptReadStarted: _markReceiptReadStarted,
      onReceiptOcrResultForReview: _parseReceiptOcrResultFromCapture,
      onReceiptReadFinished: _markReceiptReadFinished,
      onReceiptCaptureDiagnostic: _recordReceiptCaptureDiagnostic,
    );
  }

  Future<void> _handleReceiptPhotoReviewExitRequested(
    ReceiptPhotoReviewResult result,
  ) async {
    if (!result.exitsReceiptFlow) return;
    if (result.outcome == ReceiptPhotoReviewOutcome.saveDraftAndExit) {
      await _saveReceiptDraftAndExit();
      return;
    }
    await _discardReceiptAndExit();
  }
}
