part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptEntryAttachmentPanel
    on _ExpenseReceiptEntryScreenState {
  Widget _buildReceiptAttachmentPanel(BuildContext context) {
    return SharedReceiptAttachmentPanel(
      hasReceipt: _hasReceipt,
      area: _receiptCaptureArea,
      showInterruptedCaptureRecovery: widget.showInterruptedCaptureRecovery,
      initialAttachments: _receiptAttachments,
      receiptContinuationReasonCode:
          _lastOcrDiagnostics?.receiptMayNeedBottomSection == true
          ? _lastOcrDiagnostics?.receiptCompletionReviewReasonCode
          : null,
      receiptContinuationGuidance:
          _lastOcrDiagnostics?.receiptMayNeedBottomSection == true
          ? _lastOcrDiagnostics?.receiptMissingBottomEdgeAndTotals == true
                ? 'Add the bottom receipt section. Repeat 3-5 readable lines from the previous photo in the top ghost slice so subtotal, total, and final lines can be matched.'
                : 'Add the lower receipt section if the receipt continues. Repeat 3-5 readable lines in the top ghost slice so duplicate lines can be matched.'
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
      onReceiptReadStarted: _markReceiptReadStarted,
      onReceiptOcrCompleted: _markReceiptOcrCompleted,
      onReceiptOcrReadyForReview: _parseReceiptOcrResultForAttachmentReview,
      onReceiptReadFinished: _markReceiptReadFinished,
      onReceiptCaptureDiagnostic: _recordReceiptCaptureDiagnostic,
    );
  }
}
