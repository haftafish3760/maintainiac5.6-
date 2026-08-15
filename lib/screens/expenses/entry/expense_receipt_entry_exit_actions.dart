part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptEntryExitActions on _ExpenseReceiptEntryScreenState {
  /// Ends the entire receipt transaction at its documented owner destination.
  /// A plain pop is unsafe here because a source chooser, review route, or
  /// caller from another app section can still be above or below this route.
  /// Returning through the section root makes Android Back, iOS Back, Save
  /// Draft, and Exit Without Saving converge on the Expenses landing screen.
  void _returnToExpensesHome() {
    if (!mounted) return;
    openAppSectionRoot(context, AppSection.expenses);
  }

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
    _returnToExpensesHome();
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
    _returnToExpensesHome();
    return true;
  }
}
