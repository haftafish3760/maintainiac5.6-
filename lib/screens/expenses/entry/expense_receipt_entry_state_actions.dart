part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptEntryStateActions on _ExpenseReceiptEntryScreenState {
  Future<void> _editLine({
    int? index,
    required _ExpenseReceiptLine initial,
  }) async {
    final line = await showModalBottomSheet<_ExpenseReceiptLine>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1F2528),
      builder: (context) => _ReceiptLineEditorSheet(
        initial: initial,
        lineNumber: index == null ? _lines.length + 1 : index + 1,
      ),
    );
    if (line == null) return;
    _updateReceiptState(() {
      if (index == null) {
        _lines.add(line);
      } else {
        _lines[index] = line;
      }
    });
    _scheduleDraftSave();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFFFD166),
            surface: Color(0xFF1F2528),
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    _updateReceiptState(() => _selectedDate = picked);
    _scheduleDraftSave();
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFFFD166),
            surface: Color(0xFF1F2528),
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    _updateReceiptState(() => _selectedTime = picked);
    _scheduleDraftSave();
  }

  void _scheduleDraftSave() {
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 450), () {
      unawaited(_saveDraftNow());
    });
  }

  void _refreshReceiptTotals() {
    if (!mounted) return;
    _updateReceiptState(() {});
  }

  Future<void> _saveDraftNow() {
    if (_isEditingReceipt) return Future<void>.value();
    final drafts = _drafts;
    if (drafts == null) return Future<void>.value();
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
      enteredSubtotal: _enteredReceiptSubtotal,
      enteredTax: _enteredReceiptTax,
      enteredTotal: _enteredReceiptTotal,
      trackMaterialsInInventory: _trackMaterialsInInventory,
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
    return drafts.saveDraft(draft);
  }

  void _applyDraft(ExpenseReceiptDraftRecord draft) {
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
    _receiptClassification = draft.rawOcrText.trim().isEmpty
        ? null
        : ExpenseReceiptClassifier.classifyText(draft.rawOcrText);
    _lastParseQuality = null;
    _maintenanceHints.clear();
    _trackMaterialsInInventory = draft.trackMaterialsInInventory;
    _lines
      ..clear()
      ..addAll(draft.lines.map(_ExpenseReceiptLine.fromLedgerLine));
  }

  void _applyReceipt(ExpenseReceiptRecord receipt) {
    _editingReceipt = receipt;
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
    _receiptClassification = receipt.rawOcrText.trim().isEmpty
        ? null
        : ExpenseReceiptClassifier.classifyText(receipt.rawOcrText);
    _lastParseQuality = null;
    _maintenanceHints.clear();
    _trackMaterialsInInventory = receipt.trackMaterialsInInventory;
    _lines
      ..clear()
      ..addAll(receipt.lines.map(_ExpenseReceiptLine.fromLedgerLine));
  }

  void _parseImportedReceiptText(String text) {
    if (!_appAssistedReceiptFillEnabled) return;
    final parsed = parseExpenseReceiptText(text, fallbackDate: _selectedDate);
    _applyParsedReceipt(parsed);
  }

  void _scanReceiptAttachmentsIfNeeded() {
    if (!_appAssistedReceiptFillEnabled) return;
    final signature = _receiptAttachments
        .where(
          (attachment) =>
              (attachment.isPhoto && attachment.path.trim().isNotEmpty) ||
              (attachment.isPdf && attachment.path.trim().isNotEmpty) ||
              (attachment.isImportedText &&
                  attachment.importedText.trim().isNotEmpty),
        )
        .map(
          (attachment) => [
            attachment.id,
            attachment.kind.name,
            attachment.path.trim(),
            attachment.importedText.trim(),
          ].join(':'),
        )
        .join('|');
    if (signature.isEmpty || signature == _lastReceiptScanSignature) return;
    _lastReceiptScanSignature = signature;
    unawaited(_scanAttachedReceiptAttachments());
  }

  Future<void> _scanAttachedReceiptAttachments() async {
    if (!_appAssistedReceiptFillEnabled) return;
    if (_scanningReceiptPhotos) return;
    final readableAttachments = _receiptAttachments
        .where(
          (attachment) =>
              (attachment.isPhoto && attachment.path.trim().isNotEmpty) ||
              (attachment.isPdf && attachment.path.trim().isNotEmpty) ||
              (attachment.isImportedText &&
                  attachment.importedText.trim().isNotEmpty),
        )
        .toList(growable: false);
    if (readableAttachments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attach a receipt photo, PDF, or pasted text first.'),
        ),
      );
      return;
    }
    _updateReceiptState(() => _scanningReceiptPhotos = true);
    final ocr = await const ReceiptOcrService().recognizeTextFromAttachments(
      _receiptAttachments,
    );
    if (!mounted) return;
    _updateReceiptState(() => _scanningReceiptPhotos = false);
    if (!ocr.hasText) {
      final warning = ocr.warnings.isEmpty
          ? 'No readable text was found in the receipt attachment.'
          : ocr.warnings.first;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(warning)));
      return;
    }
    final parsed = parseExpenseReceiptText(
      ocr.appFillText,
      fallbackDate: _selectedDate,
    );
    _applyParsedReceipt(parsed);
    if (ocr.warnings.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ocr.warnings.first)));
    }
  }

  bool get _appAssistedReceiptFillEnabled {
    final settings = ReceiptCaptureSettingsScope.maybeOf(context);
    return settings?.appAssistedEnabledFor(_receiptCaptureArea) != false;
  }

  void _applySuggestedReceiptCategory(String category) {
    final cleanCategory = category.trim();
    if (cleanCategory.isEmpty || cleanCategory == 'Uncategorized') return;
    var changed = 0;
    _updateReceiptState(() {
      for (var index = 0; index < _lines.length; index++) {
        final line = _lines[index];
        if (line.category != 'Uncategorized') continue;
        _lines[index] = line.copyWith(
          category: cleanCategory,
          fuelType: cleanCategory == 'Fuel'
              ? line.fuelType ?? 'Gasoline'
              : null,
          fillType: cleanCategory == 'Fuel'
              ? line.fillType ?? 'Full fill-up'
              : null,
          stockUnit: defaultExpenseReceiptUnit(cleanCategory),
        );
        changed++;
      }
    });
    _scheduleDraftSave();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          changed == 0
              ? 'No uncategorized receipt lines needed that suggestion.'
              : 'Applied $cleanCategory to $changed uncategorized receipt line${changed == 1 ? '' : 's'}.',
        ),
      ),
    );
  }

  void _applyParsedReceipt(ExpenseReceiptParseResult parsed) {
    if (!parsed.hasUsableData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No usable receipt fields were found in that text.'),
        ),
      );
      return;
    }
    _updateReceiptState(() {
      _rawReceiptText = parsed.sourceText;
      _receiptClassification = ExpenseReceiptClassifier.classifyText(
        parsed.sourceText,
      );
      _lastParseQuality = parsed.quality;
      _maintenanceHints
        ..clear()
        ..addAll(parsed.maintenanceHints);
      if ((parsed.merchantName ?? '').trim().isNotEmpty) {
        _storeController.text = parsed.merchantName!.trim();
      }
      final parsedDate = parsed.receiptDate;
      if (parsedDate != null) {
        _selectedDate = DateTime(
          parsedDate.year,
          parsedDate.month,
          parsedDate.day,
        );
      }
      final parsedTime = parsed.receiptTimeMinutes;
      if (parsedTime != null) {
        _selectedTime = TimeOfDay(
          hour: parsedTime ~/ 60,
          minute: parsedTime % 60,
        );
      }
      if (parsed.enteredSubtotal != null) {
        _receiptSubtotalController.text = _moneyInputText(
          parsed.enteredSubtotal,
        );
      }
      if (parsed.enteredTax != null) {
        _salesTaxController.text = _moneyInputText(parsed.enteredTax);
      }
      if (parsed.enteredTotal != null) {
        _receiptTotalController.text = _moneyInputText(parsed.enteredTotal);
      }
      for (var index = 0; index < parsed.lines.length; index++) {
        _lines.add(
          _lineFromParsedReceipt(
            parsed.lines[index],
            review: index < parsed.lineReviews.length
                ? parsed.lineReviews[index]
                : null,
          ),
        );
      }
    });
    _scheduleDraftSave();
    final warning = parsed.warnings.isEmpty ? null : parsed.warnings.first;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          warning == null
              ? 'Receipt text parsed. Review each field before saving.'
              : '$warning Review the parsed receipt before saving.',
        ),
      ),
    );
  }

  _ExpenseReceiptLine _lineFromParsedReceipt(
    ExpenseReceiptLineRecord line, {
    ExpenseReceiptLineReview? review,
  }) {
    return _ExpenseReceiptLine(
      description: line.description,
      category: line.category,
      use: switch (line.use) {
        ExpenseLineUse.business => _ExpenseLineUse.business,
        ExpenseLineUse.personal => _ExpenseLineUse.personal,
        ExpenseLineUse.split => _ExpenseLineUse.split,
      },
      quantity: line.quantity,
      unitsPerPackage: line.unitsPerPackage,
      stockUnit: line.unit,
      subtotal: line.subtotal,
      businessPercent: line.businessPercent,
      odometerReading: line.odometerReading,
      fuelType: line.fuelType,
      fillType: line.fillType,
      unitPrice: line.unitPrice,
      parserConfidence: review?.confidence ?? line.parserConfidence,
      parserReviewLabel: review?.label ?? line.parserReviewLabel,
      parserReviewReason: review?.reason ?? line.parserReviewReason,
      parserNeedsReview: review?.needsReview ?? line.parserNeedsReview,
    );
  }
}
