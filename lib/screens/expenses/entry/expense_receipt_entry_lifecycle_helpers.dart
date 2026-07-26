part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptEntryLifecycleHelpers
    on _ExpenseReceiptEntryScreenState {
  void _initReceiptEntryState() {
    _screenOpenedAtUtc = DateTime.now().toUtc();
    _expenseOdometerReading = widget.initialOdometerReading;
    _draftId =
        widget.draftId ??
        (widget.receiptId == null
            ? 'EXPD-${DateTime.now().microsecondsSinceEpoch}'
            : 'EXPD-EDIT-${widget.receiptId}');
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
    _storeController.addListener(_trackMerchantUserEdit);
    for (final controller in [
      _receiptSubtotalController,
      _salesTaxController,
      _receiptTotalController,
    ]) {
      controller.addListener(_refreshReceiptTotals);
    }
    _receiptSubtotalController.addListener(_trackSubtotalUserEdit);
    _salesTaxController.addListener(_trackTaxUserEdit);
    _receiptTotalController.addListener(_trackTotalUserEdit);
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
    _telemetrySnapshot = ExpenseScreenTelemetryRecorder.snapshot(context);
    _drafts = ExpenseDraftScope.maybeOf(context);
    if (_expenseContext.isEmpty) {
      final activeVehicle = AppStateScope.of(context).activeVehicle;
      final activeWorkProfile = ExpenseWorkProfileScope.of(
        context,
      ).activeWorkProfile;
      _expenseContext = ExpenseReceiptContextSnapshot(
        workProfileId: activeWorkProfile.id,
        workProfileName: activeWorkProfile.name,
        vehicleId: activeVehicle == null
            ? ''
            : odometerVehicleIdForVehicleId(
                activeVehicle.id,
                fallbackLabel: activeVehicle.nickname,
              ),
        vehicleLabel: activeVehicle?.displayName ?? '',
      );
    }
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
      final editDraft = _drafts?.draftById(_draftId);
      if (editDraft?.editingReceiptId == receiptId) {
        _applyDraft(editDraft!);
        return;
      }
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
    final telemetrySnapshot = _telemetrySnapshot;
    if (telemetrySnapshot != null) {
      ExpenseScreenTelemetryRecorder.recordSnapshot(
        telemetrySnapshot,
        ExpenseTelemetryEventType.screenClosed,
        durationMs: elapsedMs,
        metadata: {'source': _receiptPrivacyFeatureArea},
      );
      ExpenseScreenTelemetryRecorder.recordSnapshot(
        telemetrySnapshot,
        ExpenseTelemetryEventType.timeSpentOnScreen,
        durationMs: elapsedMs,
        metadata: {'source': _receiptPrivacyFeatureArea},
      );
      if (!_isEditingReceipt && !_telemetryAddFlowFinished) {
        ExpenseScreenTelemetryRecorder.recordSnapshot(
          telemetrySnapshot,
          ExpenseTelemetryEventType.addExpenseAbandoned,
          diagnostic: _abandonedReceiptEntryDiagnostic,
          metadata: {
            'entryMode': 'receipt',
            'source': _receiptPrivacyFeatureArea,
          },
        );
      }
    }
    _draftTimer?.cancel();
    if (!_savedReceipt) {
      unawaited(_saveDraftNow());
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
    _storeController.removeListener(_trackMerchantUserEdit);
    for (final controller in [
      _receiptSubtotalController,
      _salesTaxController,
      _receiptTotalController,
    ]) {
      controller.removeListener(_refreshReceiptTotals);
    }
    _receiptSubtotalController.removeListener(_trackSubtotalUserEdit);
    _salesTaxController.removeListener(_trackTaxUserEdit);
    _receiptTotalController.removeListener(_trackTotalUserEdit);
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

  void _trackMerchantUserEdit() {
    if (_applyingParsedFieldValues) return;
    final current = _storeController.text.trim();
    final parsed = (_lastParsedMerchantValue ?? '').trim();
    if (current == parsed) return;
    _merchantValueLockedByUser = true;
  }

  void _trackSubtotalUserEdit() {
    if (_applyingParsedFieldValues) return;
    final current = _receiptSubtotalController.text.trim();
    final parsed = (_lastParsedSubtotalValue ?? '').trim();
    if (current == parsed) return;
    _receiptSubtotalLockedByUser = true;
  }

  void _trackTaxUserEdit() {
    if (_applyingParsedFieldValues) return;
    final current = _salesTaxController.text.trim();
    final parsed = (_lastParsedTaxValue ?? '').trim();
    if (current == parsed) return;
    _receiptTaxLockedByUser = true;
  }

  void _trackTotalUserEdit() {
    if (_applyingParsedFieldValues) return;
    final current = _receiptTotalController.text.trim();
    final parsed = (_lastParsedTotalValue ?? '').trim();
    if (current == parsed) return;
    _receiptTotalLockedByUser = true;
  }
}
