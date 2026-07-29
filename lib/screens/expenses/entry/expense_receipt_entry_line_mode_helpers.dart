part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptEntryLineModeHelpers
    on _ExpenseReceiptEntryScreenState {
  String get _newReceiptLineCategory =>
      _receiptCategoryAppliesToAll ? _receiptCategory : 'Uncategorized';

  Future<void> _addReceiptLineForMode({
    required _ExpenseLineUse use,
    required String category,
  }) => _editLine(
    initial: _ExpenseReceiptLine.blank(use: use, category: category),
  );

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
}
