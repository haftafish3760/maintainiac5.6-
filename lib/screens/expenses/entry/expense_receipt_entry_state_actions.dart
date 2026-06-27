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
    if (!mounted) return;
    if (line.category != initial.category) {
      ExpenseScreenTelemetryRecorder.record(
        context,
        ExpenseTelemetryEventType.categoryChanged,
        categoryGroup: line.category,
      );
    } else {
      ExpenseScreenTelemetryRecorder.record(
        context,
        ExpenseTelemetryEventType.categorySelected,
        categoryGroup: line.category,
      );
    }
    if (initial.hasParserReview) {
      ExpenseScreenTelemetryRecorder.record(
        context,
        ExpenseTelemetryEventType.ocrCorrectionOpened,
        metadata: {'source': _receiptPrivacyFeatureArea},
      );
    }
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

  void _confirmParsedLine(int index) {
    if (index < 0 || index >= _lines.length) return;
    _updateReceiptState(() {
      _lines[index] = _lines[index].confirmParserReview();
    });
    _scheduleDraftSave();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Receipt line confirmed.')));
  }

  void _markLineExpenseOnly(int index) {
    if (index < 0 || index >= _lines.length) return;
    _updateReceiptState(() {
      _lines[index] = _lines[index].markExpenseOnly();
    });
    _scheduleDraftSave();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Line marked expense-only.')));
  }

  void _markAllReceiptLines(_ExpenseLineUse use) {
    if (_lines.isEmpty) return;
    _updateReceiptState(() {
      for (var index = 0; index < _lines.length; index++) {
        final line = _lines[index];
        _lines[index] = line.copyWith(
          use: use,
          businessPercent: use == _ExpenseLineUse.split ? .5 : null,
          parserNeedsReview: false,
          parserReviewLabel: 'Good',
          parserReviewReason: switch (use) {
            _ExpenseLineUse.business =>
              'User marked the full receipt as business.',
            _ExpenseLineUse.personal =>
              'User marked the full receipt as personal.',
            _ExpenseLineUse.split =>
              'User marked the full receipt as mixed; split lines default to 50% business.',
          },
        );
      }
    });
    _scheduleDraftSave();
    final label = switch (use) {
      _ExpenseLineUse.business => 'business',
      _ExpenseLineUse.personal => 'personal',
      _ExpenseLineUse.split => 'mixed',
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Marked the full receipt as $label.')),
    );
  }

  Future<void> _setReceiptLineUse(int index, _ExpenseLineUse use) async {
    if (index < 0 || index >= _lines.length) return;
    double? splitPercent;
    if (use == _ExpenseLineUse.split) {
      splitPercent = await _chooseSplitBusinessPercent(index);
      if (!mounted || splitPercent == null) return;
    }
    _updateReceiptState(() {
      final line = _lines[index];
      _lines[index] = line.copyWith(
        use: use,
        businessPercent: use == _ExpenseLineUse.split ? splitPercent : null,
        parserNeedsReview: false,
        parserReviewLabel: 'Good',
        parserReviewReason: switch (use) {
          _ExpenseLineUse.business =>
            'User marked this receipt line as business.',
          _ExpenseLineUse.personal =>
            'User marked this receipt line as personal.',
          _ExpenseLineUse.split =>
            'User marked this receipt line as split; split starts at 50% business.',
        },
      );
    });
    _scheduleDraftSave();
  }

  Future<double?> _chooseSplitBusinessPercent(int index) async {
    final line = _lines[index];
    final initial = line.use == _ExpenseLineUse.split
        ? line.effectiveBusinessPercent
        : .5;
    final customController = TextEditingController(
      text: (initial * 100).round().toString(),
    );
    try {
      return await showModalBottomSheet<double>(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF1F2528),
        builder: (context) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                10,
                10,
                10,
                MediaQuery.viewInsetsOf(context).bottom + 14,
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  ReceiptFormPanel(
                    title: 'Split Receipt Line ${index + 1}',
                    subtitle:
                        'Choose the business portion for this line. The rest counts as personal.',
                    icon: Icons.call_split_rounded,
                    accentColor: const Color(0xFF3B7C73),
                    children: [
                      Text(
                        line.displayDescription,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFE8ECEE),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Line amount: ${_money(line.subtotal)}',
                        style: const TextStyle(
                          color: Color(0xFFC8D0D3),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _SplitPercentButton(
                            label: '25% Business',
                            percent: .25,
                            onSelected: (value) =>
                                Navigator.of(context).pop(value),
                          ),
                          _SplitPercentButton(
                            label: '50% Business',
                            percent: .5,
                            onSelected: (value) =>
                                Navigator.of(context).pop(value),
                          ),
                          _SplitPercentButton(
                            label: '75% Business',
                            percent: .75,
                            onSelected: (value) =>
                                Navigator.of(context).pop(value),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      RecordTextField(
                        label: 'Custom Business %',
                        helperText:
                            'Enter 0 to 100. Example: 80 means 80% business and 20% personal.',
                        controller: customController,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () {
                          final entered = double.tryParse(
                            customController.text.trim(),
                          );
                          if (entered == null || entered < 0 || entered > 100) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Enter a business percentage from 0 to 100.',
                                ),
                              ),
                            );
                            return;
                          }
                          Navigator.of(context).pop(entered / 100);
                        },
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Use Custom Split'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF28A745),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    } finally {
      customController.dispose();
    }
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
      ocrReview: _currentOcrReview(),
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

  ExpenseReceiptOcrReview _currentOcrReview() {
    final diagnostics = _lastOcrDiagnostics;
    if (diagnostics == null) return const ExpenseReceiptOcrReview();
    return ExpenseReceiptOcrReview.fromDiagnostics(
      diagnostics: diagnostics,
      warnings: _lastOcrWarnings,
    );
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
    _lastFieldConfidences = const {};
    _lastOcrDiagnostics = null;
    _lastOcrWarnings = const [];
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
    _lastFieldConfidences = const {};
    _lastOcrDiagnostics = null;
    _lastOcrWarnings = const [];
    _maintenanceHints.clear();
    _trackMaterialsInInventory = receipt.trackMaterialsInInventory;
    _lines
      ..clear()
      ..addAll(receipt.lines.map(_ExpenseReceiptLine.fromLedgerLine));
  }

  Future<void> _parseImportedReceiptText(String text) async {
    if (!_appAssistedReceiptFillEnabled) return;
    await _parseImportedReceiptTextWithMemory(text);
  }

  Future<void> _parseImportedReceiptTextWithMemory(String text) async {
    if (mounted) {
      _updateReceiptState(() => _scanningReceiptPhotos = true);
    }
    final capability =
        ReceiptCaptureSettingsScope.maybeOf(context)?.deviceCapability ??
        const ReceiptDeviceCapability.standard();
    ExpenseScreenTelemetryRecorder.record(
      context,
      ExpenseTelemetryEventType.parserStarted,
      metadata: {
        'source': _receiptPrivacyFeatureArea,
        'parserDepth': capability.parserDepth.name,
      },
    );
    try {
      final parsed = await parseExpenseReceiptTextWithLocalMemory(
        text,
        fallbackDate: _selectedDate,
        parserDepth: capability.parserDepth,
        maxCatalogCandidates: capability.maxLocalCatalogMatches,
      );
      unawaited(_recordPrivacySafeParseEvent(parsed));
      _recordParserTelemetry(parsed);
      if (!mounted) return;
      _updateReceiptState(() => _scanningReceiptPhotos = false);
      _applyParsedReceipt(parsed);
    } catch (_) {
      if (!mounted) return;
      _updateReceiptState(() => _scanningReceiptPhotos = false);
      ExpenseScreenTelemetryRecorder.record(
        context,
        ExpenseTelemetryEventType.parserFailed,
        failureKind: 'receipt_parser_exception',
        diagnostic: const ExpenseFailureDiagnostic(
          workflowStep: ExpenseWorkflowStep.receiptParser,
          failedAt: 'receipt_parser_exception',
          confirmedCause: 'receipt_parser_exception',
          causeStatus: ExpenseFailureCauseStatus.confirmed,
          evidence: 'parser_threw_exception',
          missingEvidence: 'none',
        ),
        metadata: {'source': _receiptPrivacyFeatureArea},
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Receipt text could not be parsed. Review manually.'),
        ),
      );
    }
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
      ExpenseScreenTelemetryRecorder.record(
        context,
        ExpenseTelemetryEventType.validationError,
        validationErrorKind: 'missing_receipt_attachment',
        diagnostic: const ExpenseFailureDiagnostic(
          workflowStep: ExpenseWorkflowStep.receiptAttachment,
          failedAt: 'before_ocr_start',
          confirmedCause: 'missing_receipt_attachment',
          causeStatus: ExpenseFailureCauseStatus.confirmed,
          evidence: 'readable_attachment_count_zero',
          missingEvidence: 'none',
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attach a receipt photo, PDF, or pasted text first.'),
        ),
      );
      return;
    }
    _updateReceiptState(() => _scanningReceiptPhotos = true);
    ExpenseScreenTelemetryRecorder.record(
      context,
      ExpenseTelemetryEventType.ocrStarted,
      metadata: {'source': _receiptPrivacyFeatureArea},
    );
    final settings = ReceiptCaptureSettingsScope.maybeOf(context);
    final capability =
        settings?.deviceCapability ?? const ReceiptDeviceCapability.standard();
    final policy = ReceiptAssistancePolicy(device: capability);
    final decision = policy.decideForAttachments(readableAttachments);
    if (decision.mode == ReceiptAssistanceMode.proofOnly ||
        decision.mode == ReceiptAssistanceMode.cloudCandidate) {
      final warning = decision.warnings.isEmpty
          ? decision.reason
          : '${decision.reason} ${decision.warnings.first}';
      if (!mounted) return;
      _updateReceiptState(() => _scanningReceiptPhotos = false);
      _lastOcrDiagnostics = null;
      _lastOcrWarnings = const [];
      ExpenseScreenTelemetryRecorder.record(
        context,
        ExpenseTelemetryEventType.ocrFailed,
        failureKind: 'assistance_policy_blocked',
        diagnostic: ExpenseFailureDiagnostic(
          workflowStep: ExpenseWorkflowStep.receiptOcr,
          failedAt: 'before_ocr_start',
          confirmedCause: 'assistance_policy_blocked',
          causeStatus: ExpenseFailureCauseStatus.confirmed,
          evidence: decision.mode.name,
          missingEvidence: 'none',
        ),
        metadata: {'source': _receiptPrivacyFeatureArea},
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(warning)));
      return;
    }
    final ocr = await ReceiptOcrService.forDevice(
      capability,
    ).recognizeTextFromAttachments(_receiptAttachments);
    final failureDiagnostic = ocr.hasText
        ? null
        : ExpenseOcrFailureDiagnostics.fromOcrResult(ocr);
    if (!mounted) return;
    ExpenseScreenTelemetryRecorder.record(
      context,
      ocr.hasText
          ? ExpenseTelemetryEventType.ocrCompleted
          : ExpenseTelemetryEventType.ocrFailed,
      failureKind: failureDiagnostic?.confirmedCause,
      diagnostic: failureDiagnostic,
      metadata: {
        'source': _receiptPrivacyFeatureArea,
        'ocrEngine': capability.tier.name,
        'parserDepth': capability.parserDepth.name,
        'count': readableAttachments.length,
      },
    );
    unawaited(_recordPrivacySafeOcrEvent(ocr, capability: capability));
    _updateReceiptState(() => _scanningReceiptPhotos = false);
    if (!ocr.hasText) {
      _lastOcrDiagnostics = ocr.diagnostics;
      _lastOcrWarnings = ocr.structuredWarnings;
      final warning = ocr.structuredWarnings.isEmpty
          ? 'No readable text was found in the receipt attachment.'
          : ocr.structuredWarnings.first.reviewMessage;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(warning)));
      return;
    }
    ExpenseScreenTelemetryRecorder.record(
      context,
      ExpenseTelemetryEventType.parserStarted,
      metadata: {
        'source': _receiptPrivacyFeatureArea,
        'parserDepth': capability.parserDepth.name,
      },
    );
    final parsed = await parseExpenseReceiptTextWithLocalMemory(
      ocr.appFillText,
      fallbackDate: _selectedDate,
      parserDepth: capability.parserDepth,
      maxCatalogCandidates: capability.maxLocalCatalogMatches,
    );
    unawaited(_recordPrivacySafeParseEvent(parsed));
    _recordParserTelemetry(parsed);
    if (!mounted) return;
    _updateReceiptState(() {
      _lastOcrDiagnostics = ocr.diagnostics;
      _lastOcrWarnings = ocr.structuredWarnings;
    });
    _applyParsedReceipt(parsed);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ocr.reviewMessage(
            successMessage:
                'Receipt filled. Review the store, date, totals, and lines below before saving.',
          ),
        ),
      ),
    );
  }

  bool get _appAssistedReceiptFillEnabled {
    final settings = ReceiptCaptureSettingsScope.maybeOf(context);
    return settings?.appAssistedEnabledFor(_receiptCaptureArea) != false;
  }

  Future<void> _recordPrivacySafeOcrEvent(
    ReceiptOcrResult result, {
    required ReceiptDeviceCapability capability,
  }) async {
    try {
      final store = await PrivacySafeReceiptEventStore.create();
      await store.enqueue(
        PrivacySafeReceiptEvent.fromOcrResult(
          result: result,
          featureArea: _receiptPrivacyFeatureArea,
          capability: capability,
        ),
      );
    } catch (_) {
      // Receipt diagnostics must never interrupt the user's receipt workflow.
    }
  }

  Future<void> _recordPrivacySafeParseEvent(
    ExpenseReceiptParseResult result,
  ) async {
    try {
      final store = await PrivacySafeReceiptEventStore.create();
      await store.enqueue(
        PrivacySafeReceiptEvent.fromParseResult(
          result: result,
          featureArea: _receiptPrivacyFeatureArea,
        ),
      );
    } catch (_) {
      // Receipt diagnostics must never interrupt the user's receipt workflow.
    }
  }

  void _recordParserTelemetry(ExpenseReceiptParseResult result) {
    final outcome = ExpenseParserFailureDiagnostics.outcomeFor(result);
    final diagnostic = ExpenseParserFailureDiagnostics.diagnosticFor(result);
    ExpenseScreenTelemetryRecorder.record(
      context,
      switch (outcome) {
        ExpenseParserTelemetryOutcome.completed =>
          ExpenseTelemetryEventType.parserCompleted,
        ExpenseParserTelemetryOutcome.needsReview =>
          ExpenseTelemetryEventType.parserNeedsReview,
        ExpenseParserTelemetryOutcome.failed =>
          ExpenseTelemetryEventType.parserFailed,
      },
      failureKind: diagnostic?.confirmedCause,
      diagnostic: diagnostic,
      metadata: {
        'source': _receiptPrivacyFeatureArea,
        'parserDepth': result.diagnostics.parserDepth.name,
        'lineCount': result.diagnostics.detectedLineCount,
      },
    );
  }

  String get _receiptPrivacyFeatureArea {
    return switch (_receiptCaptureArea) {
      ReceiptCaptureArea.expenses => 'expenses',
      ReceiptCaptureArea.materialsInventory => 'materials_inventory',
      ReceiptCaptureArea.maintenanceRepair => 'maintenance_repair',
    };
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
    if (changed > 0) {
      ExpenseScreenTelemetryRecorder.record(
        context,
        ExpenseTelemetryEventType.userCorrectedCategory,
        categoryGroup: cleanCategory,
      );
    }
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
      _applyUnusableParsedReceipt(parsed);
      return;
    }
    _updateReceiptState(() {
      _rawReceiptText = parsed.sourceText;
      _receiptClassification = ExpenseReceiptClassifier.classifyText(
        parsed.sourceText,
      );
      _lastParseQuality = parsed.quality;
      _lastFieldConfidences = parsed.fieldConfidences;
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
      _removeAppAssistedReceiptLines();
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
    _scrollToReceiptReview();
    final warning = parsed.warnings.isEmpty ? null : parsed.warnings.first;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          warning == null
              ? 'Receipt fields filled. Review each field before saving.'
              : '$warning Review the filled receipt before saving.',
        ),
      ),
    );
  }

  void _applyUnusableParsedReceipt(ExpenseReceiptParseResult parsed) {
    _updateReceiptState(() {
      _rawReceiptText = parsed.sourceText;
      _receiptClassification = ExpenseReceiptClassifier.classifyText(
        parsed.sourceText,
      );
      _lastParseQuality = parsed.quality;
      _lastFieldConfidences = parsed.fieldConfidences;
      _maintenanceHints
        ..clear()
        ..addAll(parsed.maintenanceHints);
      _removeAppAssistedReceiptLines();
    });
    _scheduleDraftSave();
    _scrollToReceiptReview();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Receipt was read, but the app could not find usable fields. Keep the proof and fill in the receipt manually.',
        ),
      ),
    );
  }

  void _removeAppAssistedReceiptLines() {
    _lines.removeWhere((line) => line.cameFromAppAssistedReceiptRead);
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
      rawReceiptText: line.receiptEvidenceText,
      catalogItemId: line.catalogItemId,
      catalogItemName: line.catalogItemName,
      catalogItemPath: line.catalogItemPath,
      catalogMatchConfidence: line.catalogMatchConfidence,
      catalogMatchedTerms: line.catalogMatchedTerms,
      parserConfidence: review?.confidence ?? line.parserConfidence,
      parserReviewLabel: review?.label ?? line.parserReviewLabel,
      parserReviewReason: review?.reason ?? line.parserReviewReason,
      parserNeedsReview: review?.needsReview ?? line.parserNeedsReview,
    );
  }
}

class _SplitPercentButton extends StatelessWidget {
  const _SplitPercentButton({
    required this.label,
    required this.percent,
    required this.onSelected,
  });

  final String label;
  final double percent;
  final ValueChanged<double> onSelected;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => onSelected(percent),
      icon: const Icon(Icons.percent_rounded, size: 17),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFE8ECEE),
        side: const BorderSide(color: Color(0xFF526168)),
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
