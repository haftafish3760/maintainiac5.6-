part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptEntryManualFlow on _ExpenseReceiptEntryScreenState {
  bool get _usesRebuiltManualDetailedReceiptFlow =>
      !_isEditingReceipt &&
      widget.mode == ExpenseReceiptFlowMode.general &&
      widget.initialCategory != 'Fuel' &&
      !_isMaterialsFlow &&
      !_isMaintenanceRepairFlow;

  Widget _buildManualDetailedReceiptFlow(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F2528),
      body: SafeArea(
        child: Column(
          children: [
            _ManualReceiptHeader(
              step: _manualReceiptStep,
              onBack: _handleManualReceiptBack,
            ),
            GlobalOdometerHeader(
              section: AppSection.expenses,
              headerLabel: _manualReceiptStep.vehicleHeaderLabel,
              onSettingsPressed: () => unawaited(
                _manualReceiptAttachmentController.openSettings(
                  screenContext: _manualReceiptStep.settingsScreenContext,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: switch (_manualReceiptStep) {
                  _ManualReceiptStep.details => _buildManualReceiptDetailsStep(
                    context,
                  ),
                  _ManualReceiptStep.items => _buildManualReceiptItemsStep(
                    context,
                  ),
                  _ManualReceiptStep.review => _buildManualReceiptReviewStep(
                    context,
                  ),
                },
              ),
            ),
            Offstage(
              offstage: true,
              child: Column(
                children: [
                  _buildReceiptAttachmentPanel(
                    context,
                    controller: _manualReceiptAttachmentController,
                  ),
                  _ManualReceiptStoreBinding(
                    controller: _manualReceiptStoreController,
                    store: _storeController,
                    phone: _phoneController,
                    street: _streetController,
                    city: _cityController,
                    state: _stateController,
                    zip: _zipController,
                    email: _emailController,
                    website: _websiteController,
                    notes: _storeNotesController,
                    onChanged: () {
                      _setReceiptEntryState(() {});
                      _scheduleDraftSave();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualReceiptDetailsStep(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final jobs = MaintainiacJobScope.maybeOf(context);
    final job = jobs?.jobById(_expenseContext.jobId);
    final jobLabel = job?.name ?? _expenseContext.jobLabel;
    final attachmentCount = _receiptAttachments.length;
    final receiptAttachmentValue = attachmentCount == 0
        ? 'Optional. Add photos, a PDF, or imported receipt text.'
        : '$attachmentCount receipt ${attachmentCount == 1 ? 'attachment is' : 'attachments are'} added.';
    return ListView(
      key: const ValueKey('manual-receipt-details'),
      controller: _receiptScrollController,
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 22),
      children: [
        _buildManualReceiptContextActions(
          context,
          jobs: jobs,
          jobLabel: jobLabel,
        ),
        const SizedBox(height: 8),
        _ManualReceiptDateTimeStrip(
          date: localizations.formatMediumDate(_selectedDate),
          time: _selectedTime == null
              ? 'Optional'
              : localizations.formatTimeOfDay(_selectedTime!),
          onSelectDate: _selectDate,
          onSelectTime: _selectTime,
        ),
        const SizedBox(height: 8),
        _ManualReceiptActionTile(
          icon: Icons.storefront_rounded,
          label: 'Store information',
          value: _manualMerchantSummary,
          actionLabel: _storeController.text.trim().isEmpty ? 'Add' : 'Edit',
          onTap: () => unawaited(_manualReceiptStoreController.openEditor()),
          color: const Color(0xFF6FC3FF),
        ),
        const SizedBox(height: 8),
        _ManualReceiptActionTile(
          icon: Icons.receipt_long_rounded,
          label: 'Add receipt',
          value: _scanningReceiptPhotos
              ? 'Preparing receipt suggestions.'
              : receiptAttachmentValue,
          actionLabel: attachmentCount == 0 ? 'Add' : 'Manage',
          onTap: () =>
              unawaited(_manualReceiptAttachmentController.openImportOptions()),
          color: const Color(0xFF8EF6A4),
        ),
        const SizedBox(height: 18),
        _ManualReceiptPrimaryButton(
          label: 'Continue to items',
          icon: Icons.arrow_forward_rounded,
          onPressed: _continueFromManualReceiptDetails,
        ),
      ],
    );
  }

  Widget _buildManualReceiptContextActions(
    BuildContext context, {
    required MaintainiacJobController? jobs,
    required String jobLabel,
  }) {
    final odometer = _ManualReceiptOdometerAction(
      reading: _expenseOdometerReading,
      onPressed: _editExpenseOdometerReading,
    );
    final job = _ManualReceiptActionTile(
      icon: Icons.work_outline_rounded,
      label: 'Job',
      value: jobLabel.isEmpty ? 'Optional. Not attached to a job.' : jobLabel,
      actionLabel: jobLabel.isEmpty ? 'Choose' : 'Change',
      onTap: jobs == null
          ? null
          : () => unawaited(_chooseReceiptJob(context, jobs)),
      color: const Color(0xFFB7C8CE),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 420) {
          return Column(children: [odometer, const SizedBox(height: 8), job]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: odometer),
            const SizedBox(width: 8),
            Expanded(child: job),
          ],
        );
      },
    );
  }

  Widget _buildManualReceiptItemsStep(BuildContext context) {
    final scopeValue = _receiptCategoryAppliesToAll
        ? _receiptCategory == 'Uncategorized'
              ? 'One receipt category has not been selected yet.'
              : 'One category for this receipt: $_receiptCategory'
        : 'Categories are optional and chosen per item.';
    return ListView(
      key: const ValueKey('manual-receipt-items'),
      controller: _receiptScrollController,
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 22),
      children: [
        const Text(
          'Enter the item exactly as it appears on the receipt. Do not guess product names.',
          style: TextStyle(
            color: Color(0xFFB7C8CE),
            fontSize: 13,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 14),
        _ManualReceiptActionTile(
          icon: Icons.category_outlined,
          label: 'Categories',
          value: scopeValue,
          actionLabel: 'Choose',
          onTap: () => unawaited(_showManualReceiptCategoryScope(context)),
          color: const Color(0xFFFFD166),
        ),
        const SizedBox(height: 14),
        if (_lines.isEmpty)
          const _ManualReceiptEmptyItems()
        else
          for (var index = 0; index < _lines.length; index++) ...[
            _ManualReceiptItemCard(
              lineNumber: index + 1,
              line: _lines[index],
              onEdit: () => _editLine(index: index, initial: _lines[index]),
              onDelete: () {
                _setReceiptEntryState(() => _lines.removeAt(index));
                _scheduleDraftSave();
              },
              onUseChanged: (use) =>
                  unawaited(_changeManualReceiptLineUse(index, use)),
            ),
            const SizedBox(height: 8),
          ],
        OutlinedButton.icon(
          onPressed: _addManualReceiptItem,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add item'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF8FC9FF),
            side: const BorderSide(color: Color(0xFF4A90C2)),
            minimumSize: const Size.fromHeight(48),
            textStyle: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: 18),
        _ManualReceiptPrimaryButton(
          label: 'Review receipt',
          icon: Icons.fact_check_outlined,
          onPressed: _continueFromManualReceiptItems,
        ),
      ],
    );
  }

  Widget _buildManualReceiptReviewStep(BuildContext context) {
    return ListView(
      key: const ValueKey('manual-receipt-review'),
      controller: _receiptScrollController,
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 22),
      children: [
        Text(
          _storeController.text.trim().isEmpty
              ? 'Review each printed item and the receipt total before saving.'
              : '${_storeController.text.trim()} · Review each printed item and the receipt total before saving.',
          style: const TextStyle(
            color: Color(0xFFB7C8CE),
            fontSize: 13,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 14),
        for (var index = 0; index < _lines.length; index++) ...[
          _ManualReceiptItemCard(
            lineNumber: index + 1,
            line: _lines[index],
            onEdit: () => _editLine(index: index, initial: _lines[index]),
            onDelete: () {
              _setReceiptEntryState(() => _lines.removeAt(index));
              _scheduleDraftSave();
            },
            onUseChanged: (use) =>
                unawaited(_changeManualReceiptLineUse(index, use)),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 6),
        _ManualReceiptTotalsEditor(
          itemSubtotal: _lineSubtotal,
          subtotalController: _receiptSubtotalController,
          taxController: _salesTaxController,
          totalController: _receiptTotalController,
          businessTotal: _businessTotal,
          personalTotal: _personalTotal,
        ),
        const SizedBox(height: 18),
        _ManualReceiptPrimaryButton(
          label: 'Save receipt',
          icon: Icons.save_rounded,
          onPressed: _saveReceipt,
        ),
      ],
    );
  }

  String get _manualMerchantSummary {
    final name = _storeController.text.trim();
    if (name.isEmpty) return 'Optional. Add store details if they are useful.';
    final address = [
      _streetController.text.trim(),
      _cityController.text.trim(),
      _stateController.text.trim(),
      _zipController.text.trim(),
    ].where((part) => part.isNotEmpty).join(', ');
    return address.isEmpty ? name : '$name · $address';
  }

  void _handleManualReceiptBack() {
    switch (_manualReceiptStep) {
      case _ManualReceiptStep.details:
        Navigator.of(context).maybePop();
      case _ManualReceiptStep.items:
        _setReceiptEntryState(
          () => _manualReceiptStep = _ManualReceiptStep.details,
        );
      case _ManualReceiptStep.review:
        _setReceiptEntryState(
          () => _manualReceiptStep = _ManualReceiptStep.items,
        );
    }
  }

  void _continueFromManualReceiptDetails() {
    _setReceiptEntryState(() => _manualReceiptStep = _ManualReceiptStep.items);
    _scheduleDraftSave();
  }

  void _continueFromManualReceiptItems() {
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one receipt item first.')),
      );
      return;
    }
    _setReceiptEntryState(() => _manualReceiptStep = _ManualReceiptStep.review);
    _scheduleDraftSave();
  }

  Future<void> _addManualReceiptItem() async {
    await _editLine(
      initial: _ExpenseReceiptLine.blank(
        use: _ExpenseLineUse.business,
        category: _newReceiptLineCategory,
      ),
    );
  }

  Future<void> _changeManualReceiptLineUse(
    int index,
    _ExpenseLineUse use,
  ) async {
    if (index < 0 || index >= _lines.length || _lines[index].use == use) {
      return;
    }
    if (use == _ExpenseLineUse.split) {
      final line = _lines[index];
      await _editLine(
        index: index,
        initial: line.copyWith(
          use: _ExpenseLineUse.split,
          businessPercent: null,
          splitAllocation: null,
        ),
      );
      return;
    }
    await _setReceiptLineUse(index, use);
  }
}

extension _ManualReceiptStepSettings on _ManualReceiptStep {
  String get vehicleHeaderLabel => switch (this) {
    _ManualReceiptStep.details => 'RECEIPT DETAILS',
    _ManualReceiptStep.items => 'RECEIPT ITEMS',
    _ManualReceiptStep.review => 'RECEIPT REVIEW',
  };

  ReceiptSettingsScreenContext get settingsScreenContext => switch (this) {
    _ManualReceiptStep.details => const ReceiptSettingsScreenContext(
      title: 'Receipt Details Settings',
      subtitle: 'Preferences for the Details step.',
      description:
          'These preferences apply while you add optional receipt evidence and details. The date, job, store, and odometer shown on Details belong to this receipt and stay editable on the form.',
      workflowNote:
          'Use these choices for optional receipt photos, PDFs, and app-assisted entry. Capture settings do not replace your phone camera software.',
    ),
    _ManualReceiptStep.items => const ReceiptSettingsScreenContext(
      title: 'Receipt Items Settings',
      subtitle: 'Preferences for the Items step.',
      description:
          'Descriptions, categories, and Business, Personal, or Split choices are saved with each receipt item. Change those record values on Items; the controls here set receipt-capture preferences.',
      workflowNote:
          'Receipt Assist can prepare editable line suggestions after you add evidence. It never changes an item or category without review.',
    ),
    _ManualReceiptStep.review => const ReceiptSettingsScreenContext(
      title: 'Receipt Review Settings',
      subtitle: 'Preferences for the Review step.',
      description:
          'Totals and allocations are part of this receipt and stay editable on Review. The controls here set how future receipt capture and app-assisted filling behave.',
      workflowNote:
          'These choices affect receipt capture and future app-assisted suggestions. They never replace the values shown on Review.',
    ),
  };
}
