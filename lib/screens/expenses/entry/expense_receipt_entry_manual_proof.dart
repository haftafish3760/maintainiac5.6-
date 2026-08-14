part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptEntryManualProof on _ExpenseReceiptEntryScreenState {
  Future<void> _openOptionalManualReceiptProof() async {
    final result = await _manualReceiptAttachmentController.openImportOptions(
      intent: ReceiptImportEntryIntent.optionalManualProof,
    );
    if (!mounted) return;
    final reviewResult = result?.reviewResult;
    if (reviewResult?.exitsReceiptFlow == true) {
      await _handleReceiptPhotoReviewExitRequested(reviewResult!);
    }
  }

  String get _manualReceiptProofSummary {
    final count = _receiptAttachments.length;
    if (count == 0) {
      return 'Optional. Take a photo or choose an image, PDF, or text copy.';
    }
    final noun = count == 1 ? 'attachment' : 'attachments';
    return '$count receipt $noun added. Tap to add another.';
  }
}
