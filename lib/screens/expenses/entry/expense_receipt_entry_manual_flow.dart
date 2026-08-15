part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptEntryManualFlow on _ExpenseReceiptEntryScreenState {
  /// Every new Expenses receipt starts on the same classification screen.
  /// Specialized legacy forms remain available only when reopening their
  /// existing records, where their lane-owned edit controls are still needed.
  bool get _usesRebuiltManualDetailedReceiptFlow =>
      !_isEditingReceipt || (!_isMaterialsFlow && !_isMaintenanceRepairFlow);

  Widget _buildManualDetailedReceiptFlow(BuildContext context) {
    return PopScope<Object?>(
      // The classification screen is the entry point for every new Expense
      // receipt. Android Back leaves Expenses until the person has confirmed
      // that first receipt-wide choice and entered the receipt workflow.
      canPop:
          expenseReceiptBackActionFor(
            stepToken: _manualReceiptStep.name,
            hasRecoverableContent: _hasDraftContentWorthRecovering,
          ) ==
          ExpenseReceiptBackAction.popRoute,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleManualReceiptBack();
      },
      child: Scaffold(
        backgroundColor: _receiptReferencePage,
        body: SafeArea(
          child: Column(
            children: [
              _ReferenceReceiptAppBar(
                title: _manualReceiptStep == _ManualReceiptStep.review
                    ? 'Review Receipt'
                    : 'Add Receipt',
                entryModeLabel: _manualReceiptStep == _ManualReceiptStep.start
                    ? _receiptEntryModeLabel
                    : (_hasReceipt ||
                          _receiptAttachments.isNotEmpty ||
                          _receiptReviewFlowStarted)
                    ? 'Receipt photos'
                    : _receiptEntryModeLabel,
                onBack: _handleManualReceiptBack,
                onSettings: () => unawaited(
                  _manualReceiptAttachmentController.openSettings(
                    screenContext: _manualReceiptStep.settingsScreenContext,
                  ),
                ),
              ),
              Expanded(
                child: switch (_manualReceiptStep) {
                  _ManualReceiptStep.start => _buildReceiptClassificationStep(),
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
      ),
    );
  }

  /// The selected Expense receipt-assistance setting is context only. It
  /// must never choose a different first screen or silently open a camera.
  String get _receiptEntryModeLabel {
    final settings = ReceiptCaptureSettingsScope.maybeOf(context);
    return switch (settings?.expenseReceiptAssistanceChoice) {
      ExpenseReceiptAssistanceChoice.onDevice ||
      ExpenseReceiptAssistanceChoice.maintainiacAi ||
      ExpenseReceiptAssistanceChoice.chatGptAccount => 'App-assisted',
      _ => 'Manual',
    };
  }

  Widget _buildManualReceiptDetailsStep(BuildContext context) {
    if (!_receiptClassificationConfirmed) {
      return _buildReceiptClassificationStep();
    }
    final localizations = MaterialLocalizations.of(context);
    return ListView(
      key: const ValueKey('manual-receipt-details'),
      controller: _receiptScrollController,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
      children: [
        _ReferenceReceiptSelectionContext(
          classification: _receiptUse.label,
          category: _receiptCategoryContextLabel,
        ),
        const SizedBox(height: 14),
        _ReferenceReceiptContextRow(
          vehicleLabel:
              AppStateScope.of(context).activeVehicle?.nickname ?? 'No vehicle',
          workProfileLabel: ExpenseWorkProfileScope.of(
            context,
          ).activeWorkProfile.name,
          onVehicleTap: _chooseReceiptVehicle,
          onWorkProfileTap: _chooseReceiptWorkProfile,
        ),
        const SizedBox(height: 14),
        _ManualReceiptDateTimeStrip(
          date: localizations.formatMediumDate(_selectedDate),
          time: _selectedTime == null
              ? 'Optional'
              : localizations.formatTimeOfDay(_selectedTime!),
          onSelectDate: _selectDate,
          onSelectTime: _selectTime,
        ),
        const SizedBox(height: 14),
        _ReferenceReceiptTotalField(
          controller: _receiptTotalController,
          onChanged: (_) => _scheduleDraftSave(),
        ),
        const SizedBox(height: 14),
        _ManualReceiptActionTile(
          icon: Icons.storefront_outlined,
          label: 'Store information',
          value: _storeController.text.trim().isEmpty
              ? 'Optional. Add the store name and address.'
              : _manualMerchantSummary,
          onTap: () => unawaited(_manualReceiptStoreController.openEditor()),
          color: const Color(0xFFE8ECEE),
          referenceChevronOnly: true,
        ),
        const SizedBox(height: 18),
        const _ReferenceReceiptSectionLabel(
          label: 'Actions',
          helper: 'Optional',
        ),
        const SizedBox(height: 10),
        _ManualReceiptActionTile(
          icon: Icons.format_list_bulleted_rounded,
          label: _lines.isEmpty ? 'Add items' : 'Edit items',
          value: _lines.isEmpty
              ? 'Add receipt line items'
              : '${_lines.length} ${_lines.length == 1 ? 'item' : 'items'} added',
          onTap: _addManualReceiptItem,
          color: const Color(0xFFE8ECEE),
          referenceChevronOnly: true,
        ),
        const SizedBox(height: 10),
        _ManualReceiptActionTile(
          icon: _receiptAttachments.isEmpty
              ? Icons.attach_file_rounded
              : Icons.verified_outlined,
          label: 'Add image of your receipt',
          value: _manualReceiptProofSummary,
          onTap: () => unawaited(_openOptionalManualReceiptProof()),
          color: _receiptAttachments.isEmpty
              ? const Color(0xFFB7C8CE)
              : const Color(0xFF8EF6A4),
          referenceChevronOnly: true,
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: _openManualReceiptPreview,
          icon: const Icon(Icons.preview_outlined),
          label: const Text('Preview receipt'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFD9FFE0),
            minimumSize: const Size.fromHeight(50),
            side: const BorderSide(color: Color(0xFF2B9947), width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _ManualReceiptPrimaryButton(
          label: 'Continue to receipt preview',
          icon: Icons.arrow_forward_rounded,
          onPressed: _openManualReceiptPreview,
        ),
      ],
    );
  }

  Widget _buildReceiptClassificationStep() => LayoutBuilder(
    builder: (context, viewport) {
      final usesWideLayout = viewport.maxWidth >= 600;
      return ListView(
        key: const ValueKey('receipt-classification-step'),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 18),
        children: [
          SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ReceiptSetupSection(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'How should this receipt count?',
                        style: TextStyle(
                          color: _receiptReferenceText,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Choose whether this purchase was for work, personal use, or both. You can also decide during final review.',
                        style: TextStyle(
                          color: _receiptReferenceMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _ReferenceReceiptClassificationRow(
                        selected: _receiptUseSelectionMade ? _receiptUse : null,
                        onChanged: _setReceiptUse,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _ReceiptSetupSection(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Choose a category for this receipt',
                        style: TextStyle(
                          color: _receiptReferenceText,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ReferenceReceiptCategoryTile(
                        category: _receiptCategory,
                        onTap: _openReceiptCategoryPicker,
                      ),
                      const SizedBox(height: 10),
                      _ReceiptCategoryEntryOptions(
                        selected: _receiptCategoryEntryChoice,
                        onChanged: _setReceiptCategoryEntryChoice,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (usesWideLayout)
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: 280,
                      child: _ManualReceiptPrimaryButton(
                        label: 'Continue',
                        icon: Icons.arrow_forward_rounded,
                        onPressed: _confirmReceiptClassification,
                      ),
                    ),
                  )
                else
                  _ManualReceiptPrimaryButton(
                    label: 'Continue',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: _confirmReceiptClassification,
                  ),
              ],
            ),
          ),
        ],
      );
    },
  );

  Future<void> _openReceiptCategoryPicker() async {
    await Navigator.of(context).push<void>(
      appNativeRoute<void>(
        context,
        _ReceiptWholeCategoryPicker(
          selectedCategory: _receiptCategory,
          onCategorySelected: _setManualReceiptCategory,
        ),
      ),
    );
  }

  Future<void> _confirmReceiptClassification() async {
    final choice =
        ReceiptCaptureSettingsScope.maybeOf(
          context,
        )?.expenseReceiptAssistanceChoice ??
        ExpenseReceiptAssistanceChoice.manual;
    final destination = expenseReceiptEntryDestinationFor(choice);
    _setReceiptEntryState(() {
      _receiptClassificationConfirmed = true;
      if (destination == ExpenseReceiptEntryDestination.manualDetails) {
        _manualReceiptStep = _ManualReceiptStep.details;
      }
    });
    _scheduleDraftSave();
    if (destination == ExpenseReceiptEntryDestination.manualDetails) return;
    // App-assisted entry starts from a receipt source. Manual entry reaches the
    // editable form first and may open this chooser later as optional proof.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || !_receiptClassificationConfirmed) return;
    final result = await _manualReceiptAttachmentController.openImportOptions();
    if (!mounted) return;
    final reviewResult = result?.reviewResult;
    if (reviewResult?.exitsReceiptFlow == true) {
      await _handleReceiptPhotoReviewExitRequested(reviewResult!);
    }
  }

  void _setReceiptCategoryEntryChoice(_ReceiptCategoryEntryChoice choice) {
    _setReceiptEntryState(() {
      _receiptCategoryEntryChoice = choice;
      if (choice == _ReceiptCategoryEntryChoice.wholeReceipt) return;
      _receiptCategory = 'Uncategorized';
      _receiptCategoryAppliesToAll = false;
    });
    _scheduleDraftSave();
  }

  Future<void> _chooseReceiptVehicle() async {
    openGlobalVehiclePicker(
      context,
      section: AppSection.expenses,
      onVehicleSelected: (_) => unawaited(_editExpenseOdometerReading()),
    );
  }

  Future<void> _chooseReceiptWorkProfile() async {
    final profiles = ExpenseWorkProfileScope.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF101315),
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          children: [
            const Text(
              'Choose work profile',
              style: TextStyle(
                color: _receiptReferenceText,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            for (final profile in profiles.profiles)
              ListTile(
                title: Text(
                  profile.name,
                  style: const TextStyle(
                    color: _receiptReferenceText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                trailing: profile.id == profiles.activeWorkProfile.id
                    ? const Icon(Icons.check_rounded, color: Color(0xFF51D26C))
                    : null,
                onTap: () async {
                  await profiles.select(profile.id);
                  if (!mounted) return;
                  final operational = OperationalContextScope.maybeOf(context);
                  await operational?.setActiveWorkProfile(
                    workProfileId: profile.id,
                    workProfileName: profile.name,
                  );
                  if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveManualReceiptFromMain() async {
    if (_lines.isEmpty) {
      if (_enteredReceiptTotal == null || _enteredReceiptTotal! <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enter the receipt total before saving.'),
          ),
        );
        return;
      }
      await _addReceiptTotalLine(
        use: _receiptUse == _ExpenseLineUse.unclassified
            ? _ExpenseLineUse.business
            : _receiptUse,
        category: _newReceiptLineCategory,
      );
      if (!mounted || _lines.isEmpty) return;
    }
    await _saveReceipt();
  }

  Future<void> _openManualReceiptPreview() async {
    if (_lines.isEmpty &&
        (_enteredReceiptTotal == null || _enteredReceiptTotal! <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add a receipt total or at least one item before previewing.',
          ),
        ),
      );
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => _ManualReceiptPreviewScreen(
          storeName: _storeController.text.trim(),
          storeAddress: _receiptStoreAddressLabel,
          dateLabel: MaterialLocalizations.of(
            context,
          ).formatMediumDate(_selectedDate),
          timeLabel: _selectedTime == null
              ? ''
              : MaterialLocalizations.of(
                  context,
                ).formatTimeOfDay(_selectedTime!),
          classification: _receiptUse.label,
          lines: _lines,
          total: _receiptTotal,
          tax: _enteredReceiptTax,
          attachments: _receiptAttachments,
          onEdit: () => Navigator.of(context).pop(),
          onSave: () async {
            Navigator.of(context).pop();
            await _saveManualReceiptFromMain();
          },
        ),
      ),
    );
  }

  // Retained solely to open old locally saved manual drafts without changing
  // their data contract. New receipts use the Figma-derived single-page form.
  // ignore: unused_element
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
        if (_lines.isEmpty) ...[
          const _ManualReceiptEmptyItems(),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _addManualReceiptItem,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add first item'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF8FC9FF),
              side: const BorderSide(color: Color(0xFF4A90C2)),
              minimumSize: const Size.fromHeight(48),
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 14),
        ],
        for (var index = 0; index < _lines.length; index++) ...[
          _ManualReceiptItemCard(
            lineNumber: index + 1,
            line: _lines[index],
            onEdit: () => _editLine(index: index, initial: _lines[index]),
            onDelete: () {
              _setReceiptEntryState(() => _lines.removeAt(index));
              _scheduleDraftSave();
            },
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
          totalHelperText: _receiptTotalReviewHelperText,
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

  String get _receiptCategoryContextLabel =>
      switch (_receiptCategoryEntryChoice) {
        _ReceiptCategoryEntryChoice.mixedItems => 'Mixed categories',
        _ReceiptCategoryEntryChoice.notSureYet => 'No category yet',
        _ReceiptCategoryEntryChoice.wholeReceipt => _receiptCategory,
        null =>
          _receiptCategory == 'Uncategorized'
              ? 'No category yet'
              : _receiptCategory,
      };

  void _handleManualReceiptBack() {
    switch (expenseReceiptBackActionFor(
      stepToken: _manualReceiptStep.name,
      hasRecoverableContent: _hasDraftContentWorthRecovering,
    )) {
      case ExpenseReceiptBackAction.popRoute:
        _returnToExpensesHome();
        return;
      case ExpenseReceiptBackAction.confirmExit:
        unawaited(_confirmLeaveManualReceipt());
        return;
      case ExpenseReceiptBackAction.showStart:
        _setReceiptEntryState(() {
          _manualReceiptStep = _ManualReceiptStep.start;
          _receiptClassificationConfirmed = false;
        });
        _scheduleDraftSave();
        return;
      case ExpenseReceiptBackAction.showDetails:
        _setReceiptEntryState(
          () => _manualReceiptStep = _ManualReceiptStep.details,
        );
        _scheduleDraftSave();
        return;
      case ExpenseReceiptBackAction.showItems:
        _setReceiptEntryState(
          () => _manualReceiptStep = _ManualReceiptStep.items,
        );
        _scheduleDraftSave();
        return;
    }
  }

  Future<void> _confirmLeaveManualReceipt() async {
    final decision = await showDialog<_ManualReceiptExitDecision>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF283337),
        title: const Text(
          'Leave this receipt?',
          style: TextStyle(
            color: Color(0xFFF2F7F8),
            fontWeight: FontWeight.w900,
          ),
        ),
        content: const Text(
          'Your receipt is not finished. Save a local draft to continue later, or exit without saving this work.',
          style: TextStyle(
            color: Color(0xFFB7C8CE),
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(_ManualReceiptExitDecision.discard),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Exit without saving'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(_ManualReceiptExitDecision.saveDraft),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF28A745),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save draft and exit'),
          ),
        ],
      ),
    );
    if (!mounted || decision == null) return;
    if (decision == _ManualReceiptExitDecision.saveDraft) {
      await _saveReceiptDraftAndExit();
      return;
    }
    try {
      await _discardReceiptAndExit();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not discard this receipt. Your receipt is still open.',
          ),
        ),
      );
    }
  }

  // ignore: unused_element
  void _continueFromManualReceiptDetails() {
    _setReceiptEntryState(() => _manualReceiptStep = _ManualReceiptStep.items);
    _scheduleDraftSave();
  }

  // ignore: unused_element
  void _selectManualReceiptStep(_ManualReceiptStep target) {
    _setReceiptEntryState(() => _manualReceiptStep = target);
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
        use: _receiptUse == _ExpenseLineUse.split
            ? _ExpenseLineUse.unclassified
            : _receiptUse,
        category: _newReceiptLineCategory,
      ),
      allowLineClassification:
          _receiptUse == _ExpenseLineUse.split ||
          _receiptUse == _ExpenseLineUse.unclassified,
    );
  }

  void _setManualReceiptCategory(String category) {
    _setReceiptEntryState(() {
      _receiptCategory = category;
      _receiptCategoryAppliesToAll = category != 'Uncategorized';
      _receiptCategoryEntryChoice = _receiptCategoryAppliesToAll
          ? _ReceiptCategoryEntryChoice.wholeReceipt
          : _ReceiptCategoryEntryChoice.notSureYet;
      if (!_receiptCategoryAppliesToAll) return;
      for (var index = 0; index < _lines.length; index++) {
        _lines[index] = _lines[index].copyWith(category: category);
      }
    });
    _scheduleDraftSave();
  }
}

enum _ManualReceiptExitDecision { saveDraft, discard }

extension _ManualReceiptStepSettings on _ManualReceiptStep {
  // ignore: unused_element
  String get vehicleHeaderLabel => switch (this) {
    _ManualReceiptStep.start => 'ADD RECEIPT',
    _ManualReceiptStep.details => 'RECEIPT DETAILS',
    _ManualReceiptStep.items => 'RECEIPT ITEMS',
    _ManualReceiptStep.review => 'RECEIPT REVIEW',
  };

  ReceiptSettingsScreenContext get settingsScreenContext => switch (this) {
    _ManualReceiptStep.start => const ReceiptSettingsScreenContext(
      title: 'Add Receipt Settings',
      subtitle: 'Preferences for receipt photos and files.',
      description:
          'Choose how to begin on the Add Receipt screen. You can always add photos or a file later, and all receipt details remain editable before saving.',
      workflowNote:
          'These preferences affect optional receipt photos and app-assisted suggestions. They never replace the editable receipt form.',
    ),
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

class _ManualReceiptPreviewScreen extends StatelessWidget {
  const _ManualReceiptPreviewScreen({
    required this.storeName,
    required this.storeAddress,
    required this.dateLabel,
    required this.timeLabel,
    required this.classification,
    required this.lines,
    required this.total,
    required this.tax,
    required this.attachments,
    required this.onEdit,
    required this.onSave,
  });

  final String storeName;
  final String storeAddress;
  final String dateLabel;
  final String timeLabel;
  final String classification;
  final List<_ExpenseReceiptLine> lines;
  final double total;
  final double? tax;
  final List<ReceiptAttachmentRecord> attachments;
  final VoidCallback onEdit;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    final firstPhoto = attachments
        .where((attachment) => attachment.isPhoto)
        .firstOrNull;
    return Scaffold(
      backgroundColor: const Color(0xFF0B0D0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0D0F),
        foregroundColor: Colors.white,
        title: const Text('Receipt preview'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (firstPhoto != null && File(firstPhoto.path).existsSync()) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(File(firstPhoto.path), fit: BoxFit.contain),
            ),
            const SizedBox(height: 8),
            Text(
              '${attachments.length} ${attachments.length == 1 ? 'receipt image' : 'receipt images'} · ${_attachmentSizeLabel(attachments)}',
              style: const TextStyle(
                color: _receiptReferenceMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
          ],
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF15191B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF3B454A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  storeName.isEmpty ? 'Store not entered' : storeName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (storeAddress.isNotEmpty)
                  Text(
                    storeAddress,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: _receiptReferenceMuted),
                  ),
                const SizedBox(height: 6),
                Text(
                  [
                    dateLabel,
                    timeLabel,
                  ].where((value) => value.isNotEmpty).join(' · '),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _receiptReferenceMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Divider(height: 26, color: Color(0xFF3B454A)),
                Text(
                  classification.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _receiptReferenceOrange,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Divider(height: 26, color: Color(0xFF3B454A)),
                Text(
                  '${lines.length} ${lines.length == 1 ? 'item' : 'items'}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _receiptReferenceMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                for (final line in lines) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          line.displayDescription,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        _money(line.subtotal),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${line.quantityText} ${line.stockUnit} · ${line.category}',
                    style: const TextStyle(
                      color: _receiptReferenceMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                const Divider(height: 20, color: Color(0xFF3B454A)),
                if (tax != null) _previewTotalRow('Sales tax', tax!),
                _previewTotalRow('Receipt total', total, emphasized: true),
              ],
            ),
          ),
          if (attachments.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final attachment in attachments)
              Text(
                '${attachment.label}: ${attachment.kind.name} · ${attachment.dataSaverLevel.label} · ${attachment.byteSize == null ? 'size pending' : _singleAttachmentSizeLabel(attachment.byteSize!)}',
                style: const TextStyle(
                  color: _receiptReferenceMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit receipt'),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save receipt'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF297A2D),
              minimumSize: const Size.fromHeight(54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewTotalRow(
    String label,
    double value, {
    bool emphasized = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: emphasized ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ),
        Text(
          _money(value),
          style: TextStyle(
            color: emphasized ? _receiptReferenceOrange : Colors.white,
            fontSize: emphasized ? 20 : 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );

  String _attachmentSizeLabel(List<ReceiptAttachmentRecord> records) {
    final bytes = records.fold<int>(
      0,
      (sum, record) => sum + (record.byteSize ?? 0),
    );
    if (bytes <= 0) return 'size will be shown after saving';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB saved';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB saved';
  }

  String _singleAttachmentSizeLabel(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
