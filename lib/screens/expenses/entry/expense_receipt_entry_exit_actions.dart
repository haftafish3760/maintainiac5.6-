part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptEntryExitActions on _ExpenseReceiptEntryScreenState {
  /// Completes one owner-level route transaction after the review route and
  /// import chooser have already closed. Repeated taps cannot stack pops.
  Future<bool> _saveReceiptDraftAndExit() async {
    if (_receiptReviewExitInFlight) return false;
    _receiptReviewExitInFlight = true;
    _draftTimer?.cancel();

    final saved = await _saveDraftNow();
    if (!saved) {
      _receiptReviewExitInFlight = false;
      return false;
    }

    _receiptExitResolved = true;
    if (mounted) await Navigator.of(context).maybePop();
    return true;
  }

  /// Deletes the draft and only Maintainiac-owned temporary receipt artifacts.
  /// The exit is not marked resolved until cleanup succeeds, so a recoverable
  /// failure leaves the route usable and does not silently disable autosave.
  Future<bool> _discardReceiptAndExit() async {
    if (_receiptReviewExitInFlight) return false;
    _receiptReviewExitInFlight = true;
    _draftTimer?.cancel();

    try {
      // Keep the durable draft until app-owned temporary cleanup completes.
      // If cleanup fails, the user still has a recovery record to reopen.
      await _manualReceiptAttachmentController.discardReceiptSession();
      await _drafts?.deleteDraft(_draftId);
    } catch (_) {
      _receiptReviewExitInFlight = false;
      rethrow;
    }

    _receiptExitResolved = true;
    if (mounted) await Navigator.of(context).maybePop();
    return true;
  }
}
