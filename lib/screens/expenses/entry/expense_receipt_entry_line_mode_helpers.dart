part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptEntryLineModeHelpers
    on _ExpenseReceiptEntryScreenState {
  // An entry point category is only a hint. When the user chose category per
  // line, a new receipt line must begin unresolved rather than silently
  // inheriting that hint as a real classification.
  String get _newReceiptLineCategory =>
      _receiptCategoryAppliesToAll ? _receiptCategory : 'Uncategorized';

  void _selectReceiptDetailMode(_ReceiptDetailEntryMode mode) {
    if (mode == _detailEntryMode) return;
    _setReceiptEntryState(() {
      _detailEntryMode = mode;
      _receiptReviewModeChangedByUser = true;
      if (mode != _ReceiptDetailEntryMode.basicReceipt &&
          _lines.length == 1 &&
          _isReceiptTotalSummaryLine(_lines.single)) {
        _lines.clear();
      }
    });
    _scheduleDraftSave();
  }

  void _selectReceiptCategory(String category) {
    final normalized = category.trim().isEmpty ? 'Uncategorized' : category;
    _setReceiptEntryState(() {
      _receiptCategory = normalized;
      if (_detailEntryMode == _ReceiptDetailEntryMode.basicReceipt ||
          _receiptCategoryAppliesToAll) {
        for (var index = 0; index < _lines.length; index++) {
          _lines[index] = _lines[index].copyWith(category: normalized);
        }
      }
    });
    _scheduleDraftSave();
  }

  void _selectReceiptCategoryScope(bool appliesToAll) {
    _setReceiptEntryState(() {
      _receiptCategoryAppliesToAll = appliesToAll;
      if (appliesToAll) {
        for (var index = 0; index < _lines.length; index++) {
          _lines[index] = _lines[index].copyWith(category: _receiptCategory);
        }
      }
    });
    _scheduleDraftSave();
  }

  Future<void> _setReceiptSummaryUse(_ExpenseLineUse use) async {
    final amount =
        _enteredReceiptTotal ?? _enteredReceiptSubtotal ?? _receiptTotal;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the final receipt total first.')),
      );
      return;
    }
    await _addReceiptTotalLine(
      use: use,
      category: _receiptCategory,
      replaceExisting: true,
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
    if (use == _ExpenseLineUse.split) {
      final index = _lines.length - 1;
      final allocation = await _chooseSplitAllocation(
        index,
        allowQuantity: false,
      );
      if (!mounted) return;
      if (allocation == null) {
        _setReceiptEntryState(() => _lines.removeAt(index));
        return;
      }
      final percent = allocation.businessPercentFor(
        _lines[index].toLedgerLine(),
      );
      _setReceiptEntryState(() {
        _lines[index] = _lines[index].copyWith(
          businessPercent: percent,
          splitAllocation: allocation,
        );
      });
    }
    _scheduleDraftSave();
  }

  Future<void> _addReceiptTotalLine({
    required _ExpenseLineUse use,
    required String category,
    bool replaceExisting = false,
  }) async {
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
      parserReviewLabel: 'Good',
      parserReviewReason:
          'User chose how the final receipt total should count.',
      parserNeedsReview: use == _ExpenseLineUse.split,
    );
    final previousLines = replaceExisting
        ? List<_ExpenseReceiptLine>.of(_lines)
        : const <_ExpenseReceiptLine>[];
    _setReceiptEntryState(() {
      if (replaceExisting) _lines.clear();
      _lines.add(line);
    });
    if (use == _ExpenseLineUse.split) {
      final index = _lines.length - 1;
      final allocation = await _chooseSplitAllocation(
        index,
        allowQuantity: false,
      );
      if (!mounted) return;
      if (allocation == null) {
        _setReceiptEntryState(() {
          _lines.removeAt(index);
          if (replaceExisting) _lines.addAll(previousLines);
        });
        return;
      }
      final percent = allocation.businessPercentFor(
        _lines[index].toLedgerLine(),
      );
      _setReceiptEntryState(() {
        _lines[index] = _lines[index].copyWith(
          businessPercent: percent,
          splitAllocation: allocation,
          parserNeedsReview: false,
          parserReviewLabel: 'Good',
          parserReviewReason: _splitLineReviewReason(percent),
        );
      });
    }
    _scheduleDraftSave();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Receipt total added. Review classification before saving.',
        ),
      ),
    );
  }

  bool _isReceiptTotalSummaryLine(_ExpenseReceiptLine line) {
    return line.stockUnit == 'receipt' &&
        line.quantity == 1 &&
        line.unitsPerPackage == 1 &&
        switch (line.description) {
          'Receipt total' ||
          'Business receipt total' ||
          'Personal receipt total' ||
          'Split receipt total' => true,
          _ => false,
        };
  }

  Future<_ExpenseReceiptLine?> _showQuickClassifyLineSheet({
    required _ExpenseLineUse use,
    required String category,
    required int lineNumber,
  }) async {
    final amount = TextEditingController();
    final categorySearch = TextEditingController(
      text: category == 'Uncategorized' ? '' : category,
    );
    var selectedCategory = category;
    try {
      return await showModalBottomSheet<_ExpenseReceiptLine>(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF1F2528),
        builder: (context) => StatefulBuilder(
          builder: (context, setSheetState) {
            final query = categorySearch.text.trim().toLowerCase();
            final matches = _availableExpenseCategoryNames(context)
                .where(
                  (candidate) =>
                      query.isEmpty || candidate.toLowerCase().contains(query),
                )
                .take(8)
                .toList(growable: false);
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
                        'Enter the amount from this receipt line and choose how it should count. Category is optional. The receipt photo stays attached as proof.',
                    icon: switch (use) {
                      _ExpenseLineUse.unclassified =>
                        Icons.help_outline_rounded,
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
                      _ExpenseCategorySearch(
                        selectedCategory: selectedCategory,
                        controller: categorySearch,
                        matches: matches,
                        onQueryChanged: (_) => setSheetState(() {}),
                        onSelected: (value) => setSheetState(() {
                          selectedCategory = value;
                          categorySearch.text = value;
                        }),
                      ),
                      const SizedBox(height: 10),
                      _LineUseBanner(use: use),
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
                              category: selectedCategory,
                              use: use,
                              quantity: 1,
                              unitsPerPackage: 1,
                              stockUnit: 'each',
                              subtotal: subtotal,
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
        ),
      );
    } finally {
      amount.dispose();
      categorySearch.dispose();
    }
  }
}
