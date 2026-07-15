part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptEntryLineModeHelpers
    on _ExpenseReceiptEntryScreenState {
  void _setReceiptReviewMode(_ReceiptDetailEntryMode value) {
    _setReceiptEntryState(() {
      _detailEntryMode = value;
      _receiptReviewModeChangedByUser = true;
    });
    _scheduleDraftSave();
    unawaited(
      ExpenseSettingsScope.of(
        context,
      ).setReceiptReviewStyle(value.settingsStyle),
    );
  }

  Future<void> _addReceiptLineForMode({
    required _ExpenseLineUse use,
    required String category,
  }) async {
    if (_detailEntryMode == _ReceiptDetailEntryMode.detailedItems ||
        widget.initialCategory == 'Fuel' ||
        _isMaintenanceRepairFlow) {
      await _editLine(
        initial: _ExpenseReceiptLine.blank(use: use, category: category),
      );
      return;
    }
    final line = await _showQuickClassifyLineSheet(
      use: use,
      category: category,
      lineNumber: _lines.length + 1,
    );
    if (line == null || !mounted) return;
    _setReceiptEntryState(() => _lines.add(line));
    _scheduleDraftSave();
  }

  void _addReceiptTotalLine({
    required _ExpenseLineUse use,
    required String category,
  }) {
    final amount =
        _enteredReceiptTotal ?? _enteredReceiptSubtotal ?? _receiptTotal;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter the receipt total first, or add the line manually.',
          ),
        ),
      );
      return;
    }
    final line = _ExpenseReceiptLine(
      description: switch (use) {
        _ExpenseLineUse.unclassified => 'Receipt total',
        _ExpenseLineUse.business => 'Business receipt total',
        _ExpenseLineUse.personal => 'Personal receipt total',
        _ExpenseLineUse.split => 'Split receipt total',
      },
      category: category,
      use: use,
      quantity: 1,
      unitsPerPackage: 1,
      stockUnit: 'receipt',
      subtotal: amount,
      businessPercent: null,
      rawReceiptText: _rawReceiptText,
      parserConfidence: _lastParseQuality?.confidence,
      parserReviewLabel: 'Review',
      parserReviewReason:
          'Receipt text was found, but line items were not safe enough. User chose to save the receipt total.',
      parserNeedsReview: use == _ExpenseLineUse.split,
    );
    _setReceiptEntryState(() => _lines.add(line));
    _scheduleDraftSave();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Receipt total added. Review classification before saving.',
        ),
      ),
    );
  }

  Future<_ExpenseReceiptLine?> _showQuickClassifyLineSheet({
    required _ExpenseLineUse use,
    required String category,
    required int lineNumber,
  }) async {
    final amount = TextEditingController();
    final businessPercent = TextEditingController();
    try {
      return await showModalBottomSheet<_ExpenseReceiptLine>(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF1F2528),
        builder: (context) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              10,
              10,
              10,
              MediaQuery.viewInsetsOf(context).bottom + 16,
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                ReceiptFormPanel(
                  title: 'Receipt Line $lineNumber',
                  subtitle:
                      'Enter the amount from this receipt line and choose how it should count. The receipt photo stays attached as proof.',
                  icon: switch (use) {
                    _ExpenseLineUse.unclassified => Icons.help_outline_rounded,
                    _ExpenseLineUse.business => Icons.business_center_rounded,
                    _ExpenseLineUse.personal => Icons.person_rounded,
                    _ExpenseLineUse.split => Icons.call_split_rounded,
                  },
                  accentColor: switch (use) {
                    _ExpenseLineUse.unclassified => const Color(0xFFFFD166),
                    _ExpenseLineUse.business => const Color(0xFF34A9E8),
                    _ExpenseLineUse.personal => const Color(0xFF8F9BA1),
                    _ExpenseLineUse.split => const Color(0xFFFFD166),
                  },
                  children: [
                    _LineUseBanner(use: use),
                    if (use == _ExpenseLineUse.split) ...[
                      const SizedBox(height: 10),
                      RecordTextField(
                        label: 'Business %',
                        helperText:
                            'Enter the business portion. The rest is personal.',
                        controller: businessPercent,
                        keyboardType: TextInputType.number,
                      ),
                    ],
                    const SizedBox(height: 10),
                    RecordTextField(
                      label: 'Line Amount',
                      helperText:
                          'Use the amount from this receipt line. Description and item details can be left out.',
                      controller: amount,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () {
                        final subtotal = _parseMoneyInput(amount.text) ?? 0;
                        if (subtotal <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Enter the line amount first.'),
                            ),
                          );
                          return;
                        }
                        final percent = use == _ExpenseLineUse.split
                            ? _quickSplitBusinessPercent(businessPercent.text)
                            : null;
                        if (use == _ExpenseLineUse.split && percent == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Enter a business percentage from 0 to 100.',
                              ),
                            ),
                          );
                          return;
                        }
                        Navigator.of(context).pop(
                          _ExpenseReceiptLine(
                            description: switch (use) {
                              _ExpenseLineUse.unclassified => 'Receipt items',
                              _ExpenseLineUse.business =>
                                'Business receipt items',
                              _ExpenseLineUse.personal =>
                                'Personal receipt items',
                              _ExpenseLineUse.split => 'Split receipt items',
                            },
                            category: category,
                            use: use,
                            quantity: 1,
                            unitsPerPackage: 1,
                            stockUnit: 'each',
                            subtotal: subtotal,
                            businessPercent: percent,
                            splitAllocation: percent == null
                                ? null
                                : ExpenseSplitAllocation(
                                    method:
                                        ExpenseSplitAllocationMethod.percentage,
                                    businessValue: percent,
                                  ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Save Line'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF28A745),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    } finally {
      amount.dispose();
      businessPercent.dispose();
    }
  }
}

double? _quickSplitBusinessPercent(String value) =>
    _customSplitBusinessPercent(value);
