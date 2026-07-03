part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptEntryLifecycleHelpers
    on _ExpenseReceiptEntryScreenState {
  void _initReceiptEntryState() {
    _screenOpenedAtUtc = DateTime.now().toUtc();
    _draftId =
        widget.draftId ?? 'EXPD-${DateTime.now().microsecondsSinceEpoch}';
    final date = widget.initialDate ?? DateTime.now();
    _selectedDate = DateTime(date.year, date.month, date.day);
    _receiptAttachments.addAll(widget.initialAttachments);
    _lastAttachmentCount = _receiptAttachments.length;
    _hasReceipt = _receiptAttachments.isNotEmpty;
    _rawReceiptText = widget.initialImportedText.trim();
    _receiptReviewFlowStarted = _rawReceiptText.isNotEmpty;
    for (final controller in [
      _storeController,
      _phoneController,
      _streetController,
      _cityController,
      _stateController,
      _zipController,
      _emailController,
      _websiteController,
      _storeNotesController,
      _receiptSubtotalController,
      _salesTaxController,
      _receiptTotalController,
    ]) {
      controller.addListener(_scheduleDraftSave);
    }
    for (final controller in [
      _receiptSubtotalController,
      _salesTaxController,
      _receiptTotalController,
    ]) {
      controller.addListener(_refreshReceiptTotals);
    }
    if (_rawReceiptText.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_parseImportedReceiptText(_rawReceiptText));
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ExpenseScreenTelemetryRecorder.record(
        context,
        _isEditingReceipt
            ? ExpenseTelemetryEventType.editExpenseOpened
            : ExpenseTelemetryEventType.addExpenseStarted,
        metadata: {
          'entryMode': _isEditingReceipt ? 'edit' : 'receipt',
          'source': _receiptPrivacyFeatureArea,
        },
      );
      _scanReceiptAttachmentsIfNeeded();
    });
  }

  void _handleReceiptEntryDependencies() {
    _drafts = ExpenseDraftScope.maybeOf(context);
    if (!_appliedReceiptReviewStyleDefault) {
      _appliedReceiptReviewStyleDefault = true;
      _detailEntryMode = _ReceiptDetailEntryModeX.fromSettingsStyle(
        ExpenseSettingsScope.of(context).receiptReviewStyle,
      );
    }
    if (_draftLoaded) return;
    _draftLoaded = true;
    final receiptId = widget.receiptId;
    if (receiptId != null) {
      final receipt = ExpenseLedgerScope.of(context).receiptById(receiptId);
      if (receipt == null) return;
      _applyReceipt(receipt);
      return;
    }
    final draftId = widget.draftId;
    if (draftId == null) {
      if (_receiptAttachments.isNotEmpty || _rawReceiptText.isNotEmpty) {
        unawaited(_saveDraftNow());
      }
      return;
    }
    final draft = _drafts?.draftById(draftId);
    if (draft == null) return;
    _applyDraft(draft);
    final missingProof =
        _drafts?.missingAttachmentsForDraft(draftId) ?? const [];
    if (missingProof.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${missingProof.length} receipt proof file${missingProof.length == 1 ? '' : 's'} could not be found. The draft fields were restored, but that proof may need to be reattached.',
            ),
          ),
        );
      });
    }
  }

  void _disposeReceiptEntryState() {
    final elapsedMs = DateTime.now()
        .toUtc()
        .difference(_screenOpenedAtUtc)
        .inMilliseconds
        .clamp(0, 86400000);
    ExpenseScreenTelemetryRecorder.record(
      context,
      ExpenseTelemetryEventType.screenClosed,
      durationMs: elapsedMs,
      metadata: {'source': _receiptPrivacyFeatureArea},
    );
    ExpenseScreenTelemetryRecorder.record(
      context,
      ExpenseTelemetryEventType.timeSpentOnScreen,
      durationMs: elapsedMs,
      metadata: {'source': _receiptPrivacyFeatureArea},
    );
    if (!_isEditingReceipt && !_telemetryAddFlowFinished) {
      ExpenseScreenTelemetryRecorder.record(
        context,
        ExpenseTelemetryEventType.addExpenseAbandoned,
        diagnostic: _abandonedReceiptEntryDiagnostic,
        metadata: {
          'entryMode': 'receipt',
          'source': _receiptPrivacyFeatureArea,
        },
      );
    }
    _draftTimer?.cancel();
    if (!_savedReceipt && !_isEditingReceipt) {
      unawaited(_saveDraftNow());
    }
    if (!_savedReceipt && _isEditingReceipt) {
      unawaited(_discardUncommittedEditProofs());
    }
    for (final controller in [
      _storeController,
      _phoneController,
      _streetController,
      _cityController,
      _stateController,
      _zipController,
      _emailController,
      _websiteController,
      _storeNotesController,
      _receiptSubtotalController,
      _salesTaxController,
      _receiptTotalController,
    ]) {
      controller.removeListener(_scheduleDraftSave);
    }
    for (final controller in [
      _receiptSubtotalController,
      _salesTaxController,
      _receiptTotalController,
    ]) {
      controller.removeListener(_refreshReceiptTotals);
    }
    _storeController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _storeNotesController.dispose();
    _receiptSubtotalController.dispose();
    _salesTaxController.dispose();
    _receiptTotalController.dispose();
    _receiptScrollController.dispose();
  }

  Future<void> _discardUncommittedEditProofs() {
    final originalIds = widget.initialAttachments
        .map((attachment) => attachment.id)
        .toSet();
    final uncommitted = _receiptAttachments.where(
      (attachment) =>
          attachment.storageState == ReceiptAttachmentStorageState.staged &&
          !originalIds.contains(attachment.id),
    );
    return ReceiptProofStorage.instance.deleteStagedAttachments(uncommitted);
  }
}
