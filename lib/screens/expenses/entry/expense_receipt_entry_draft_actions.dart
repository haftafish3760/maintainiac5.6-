part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptEntryDraftActions on _ExpenseReceiptEntryScreenState {
  Future<bool> _saveDraftNow() async {
    final drafts = _drafts;
    if (drafts == null) return true;
    if (!_isEditingReceipt && !_hasDraftContentWorthRecovering) return true;
    final draft = ExpenseReceiptDraftRecord(
      id: _draftId,
      receiptDate: _selectedDate,
      receiptTimeMinutes: _selectedTime == null
          ? null
          : (_selectedTime!.hour * 60) + _selectedTime!.minute,
      merchantName: _storeController.text.trim(),
      phone: _phoneController.text.trim(),
      street: _streetController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      zip: _zipController.text.trim(),
      email: _emailController.text.trim(),
      website: _websiteController.text.trim(),
      notes: _storeNotesController.text.trim(),
      hasReceiptProof: _hasReceipt || _receiptAttachments.isNotEmpty,
      attachments: List.unmodifiable(_receiptAttachments),
      rawOcrText: _rawReceiptText,
      ocrReview: _currentOcrReview(),
      receiptReviewFlowStarted: _receiptReviewFlowStarted,
      receiptReadAttemptedWithoutText: _receiptReadAttemptedWithoutText,
      receiptReadHandoffProofCount: _receiptReadHandoffProofCount,
      receiptReadHandoffOcrSourceCount: _receiptReadHandoffOcrSourceCount,
      receiptReadHandoffDecision: _receiptReadHandoffDecision,
      receiptReadHandoffAction: _receiptReadHandoffAction,
      receiptReadHandoffStage: _receiptReadHandoffStage,
      receiptReadHandoffRouteResult: _receiptReadHandoffRouteResult,
      receiptReadHandoffCoverageWarning: _receiptReadHandoffCoverageWarning,
      receiptReviewMode: _detailEntryMode.name,
      receiptReviewModeChangedByUser: _receiptReviewModeChangedByUser,
      receiptCategory: _receiptCategory,
      receiptCategoryAppliesToAll: _receiptCategoryAppliesToAll,
      enteredSubtotal: _enteredReceiptSubtotal,
      enteredTax: _enteredReceiptTax,
      enteredTotal: _enteredReceiptTotal,
      trackMaterialsInInventory: _trackMaterialsInInventory,
      odometerReading: _expenseOdometerReading,
      contextSnapshot: _expenseContext,
      editingReceiptId: _isEditingReceipt ? widget.receiptId : null,
      sourceScreen: _isMaterialsFlow
          ? 'materials_expense_receipt'
          : _isMaintenanceRepairFlow
          ? 'maintenance_repair_expense_receipt'
          : 'expenses',
      updatedAt: DateTime.now(),
      lines: [
        for (var index = 0; index < _lines.length; index++)
          _lines[index].toLedgerLine(id: 'DRAFT-LINE-$index'),
      ],
    );
    try {
      await drafts.saveDraft(draft);
      _draftSaveFailureShown = false;
      return true;
    } catch (error) {
      if (!mounted || _draftSaveFailureShown) return false;
      _draftSaveFailureShown = true;
      final message = error is StateError
          ? error.message.toString()
          : 'Could not save your progress on this device. Keep this screen open and try again.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return false;
    }
  }

  bool get _hasDraftContentWorthRecovering {
    if (_hasReceipt || _receiptAttachments.isNotEmpty) return true;
    if (_rawReceiptText.trim().isNotEmpty || _receiptReviewFlowStarted) {
      return true;
    }
    if (_lines.isNotEmpty ||
        _enteredReceiptSubtotal != null ||
        _enteredReceiptTax != null ||
        _enteredReceiptTotal != null ||
        _expenseOdometerReading != null) {
      return true;
    }
    return [
      _storeController.text,
      _phoneController.text,
      _streetController.text,
      _cityController.text,
      _stateController.text,
      _zipController.text,
      _emailController.text,
      _websiteController.text,
      _storeNotesController.text,
    ].any((value) => value.trim().isNotEmpty);
  }

  ExpenseReceiptOcrReview _currentOcrReview() {
    final diagnostics = _lastOcrDiagnostics;
    if (diagnostics == null) return const ExpenseReceiptOcrReview();
    return ExpenseReceiptOcrReview.fromDiagnostics(
      diagnostics: diagnostics,
      warnings: _lastOcrWarnings,
    );
  }

  void _applyDraft(ExpenseReceiptDraftRecord draft) {
    _expenseContext = draft.contextSnapshot;
    _selectedDate = DateTime(
      draft.receiptDate.year,
      draft.receiptDate.month,
      draft.receiptDate.day,
    );
    _selectedTime = draft.receiptTimeMinutes == null
        ? null
        : TimeOfDay(
            hour: draft.receiptTimeMinutes! ~/ 60,
            minute: draft.receiptTimeMinutes! % 60,
          );
    _storeController.text = draft.merchantName;
    _phoneController.text = draft.phone;
    _streetController.text = draft.street;
    _cityController.text = draft.city;
    _stateController.text = draft.state;
    _zipController.text = draft.zip;
    _emailController.text = draft.email;
    _websiteController.text = draft.website;
    _storeNotesController.text = draft.notes;
    _receiptSubtotalController.text = _moneyInputText(draft.enteredSubtotal);
    _salesTaxController.text = _moneyInputText(draft.enteredTax);
    _receiptTotalController.text = _moneyInputText(draft.enteredTotal);
    _hasReceipt = draft.hasReceiptAttachment;
    _receiptAttachments
      ..clear()
      ..addAll(draft.attachments);
    _rawReceiptText = draft.rawOcrText;
    _receiptReviewFlowStarted =
        draft.receiptReviewFlowStarted ||
        draft.rawOcrText.trim().isNotEmpty ||
        draft.lines.isNotEmpty;
    _receiptReadAttemptedWithoutText = draft.receiptReadAttemptedWithoutText;
    _receiptReadHandoffProofCount = draft.receiptReadHandoffProofCount;
    _receiptReadHandoffOcrSourceCount = draft.receiptReadHandoffOcrSourceCount;
    _receiptReadHandoffDecision = draft.receiptReadHandoffDecision;
    _receiptReadHandoffAction = draft.receiptReadHandoffAction;
    _receiptReadHandoffStage = draft.receiptReadHandoffStage.trim().isEmpty
        ? 'Waiting for receipt details'
        : draft.receiptReadHandoffStage;
    _receiptReadHandoffRouteResult = draft.receiptReadHandoffRouteResult;
    _receiptReadHandoffCoverageWarning =
        draft.receiptReadHandoffCoverageWarning;
    _receiptReviewModeChangedByUser = draft.receiptReviewModeChangedByUser;
    _receiptCategoryAppliesToAll = draft.receiptCategoryAppliesToAll;
    _detailEntryMode =
        _receiptDetailEntryModeFromDraftName(draft.receiptReviewMode) ??
        _detailEntryMode;
    _receiptClassification = draft.rawOcrText.trim().isEmpty
        ? null
        : ExpenseReceiptClassifier.classifyText(draft.rawOcrText);
    _lastParseQuality = null;
    _lastParseDiagnostics = null;
    _lastFieldConfidences = const {};
    _lastReceiptParseCompleted =
        draft.rawOcrText.trim().isNotEmpty || draft.lines.isNotEmpty;
    _lastReceiptParseHadUsableData = _lastReceiptParseCompleted;
    _lastReceiptParseHadSafeLines = draft.lines.isNotEmpty;
    _lastOcrDiagnostics = null;
    _lastOcrWarnings = const [];
    _maintenanceHints.clear();
    _trackMaterialsInInventory = draft.trackMaterialsInInventory;
    _expenseOdometerReading = draft.odometerReading;
    _lines
      ..clear()
      ..addAll(draft.lines.map(_ExpenseReceiptLine.fromLedgerLine));
    _receiptCategory = _lines.isNotEmpty
        ? _lines.first.category
        : draft.receiptCategory;
  }

  _ReceiptDetailEntryMode? _receiptDetailEntryModeFromDraftName(String name) {
    final normalized = name.trim();
    if (normalized.isEmpty) return null;
    for (final mode in _ReceiptDetailEntryMode.values) {
      if (mode.name == normalized) return mode;
    }
    return null;
  }

  void _applyReceipt(ExpenseReceiptRecord receipt) {
    _editingReceipt = receipt;
    _expenseContext = receipt.contextSnapshot;
    _selectedDate = DateTime(
      receipt.receiptDate.year,
      receipt.receiptDate.month,
      receipt.receiptDate.day,
    );
    _selectedTime = receipt.receiptTimeMinutes == null
        ? null
        : TimeOfDay(
            hour: receipt.receiptTimeMinutes! ~/ 60,
            minute: receipt.receiptTimeMinutes! % 60,
          );
    _storeController.text = receipt.merchantName;
    _phoneController.text = receipt.phone;
    _streetController.text = receipt.street;
    _cityController.text = receipt.city;
    _stateController.text = receipt.state;
    _zipController.text = receipt.zip;
    _emailController.text = receipt.email;
    _websiteController.text = receipt.website;
    _storeNotesController.text = receipt.notes;
    _receiptSubtotalController.text = _moneyInputText(receipt.enteredSubtotal);
    _salesTaxController.text = _moneyInputText(receipt.enteredTax);
    _receiptTotalController.text = _moneyInputText(receipt.enteredTotal);
    _hasReceipt = receipt.hasReceiptAttachment;
    _receiptAttachments
      ..clear()
      ..addAll(receipt.attachments);
    _rawReceiptText = receipt.rawOcrText;
    _receiptReviewFlowStarted =
        receipt.rawOcrText.trim().isNotEmpty || receipt.lines.isNotEmpty;
    _receiptClassification = receipt.rawOcrText.trim().isEmpty
        ? null
        : ExpenseReceiptClassifier.classifyText(receipt.rawOcrText);
    _lastParseQuality = null;
    _lastParseDiagnostics = null;
    _lastFieldConfidences = const {};
    _lastReceiptParseCompleted =
        receipt.rawOcrText.trim().isNotEmpty || receipt.lines.isNotEmpty;
    _lastReceiptParseHadUsableData = _lastReceiptParseCompleted;
    _lastReceiptParseHadSafeLines = receipt.lines.isNotEmpty;
    _lastOcrDiagnostics = null;
    _lastOcrWarnings = const [];
    _maintenanceHints.clear();
    _trackMaterialsInInventory = receipt.trackMaterialsInInventory;
    _expenseOdometerReading = receipt.odometerReading;
    _lines
      ..clear()
      ..addAll(receipt.lines.map(_ExpenseReceiptLine.fromLedgerLine));
  }
}
