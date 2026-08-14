part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptEntryStateActions on _ExpenseReceiptEntryScreenState {
  Future<void> _editLine({
    int? index,
    required _ExpenseReceiptLine initial,
    bool allowLineClassification = true,
  }) async {
    final previousItemsTotal = _lineSubtotal;
    final previousReceiptTotal = _enteredReceiptTotal;
    final line = await Navigator.of(context).push<_ExpenseReceiptLine>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => _ReceiptLineEditorSheet(
          initial: initial,
          lineNumber: index == null ? _lines.length + 1 : index + 1,
          allowLineClassification: allowLineClassification,
        ),
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
    _recordAppFilledLineReviewTelemetry(initial: initial, reviewed: line);
    _updateReceiptState(() {
      if (index == null) {
        _lines.add(line);
      } else {
        _lines[index] = line;
      }
    });
    final shouldFollowItems =
        previousReceiptTotal == null ||
        (previousReceiptTotal - previousItemsTotal).abs() < .01;
    if (shouldFollowItems) {
      _receiptTotalController.text = _lineSubtotal.toStringAsFixed(2);
    }
    _scheduleDraftSave();
  }

  void _recordAppFilledLineReviewTelemetry({
    required _ExpenseReceiptLine initial,
    required _ExpenseReceiptLine reviewed,
  }) {
    if (!initial.cameFromAppAssistedReceiptRead) return;
    final label = (reviewed.parserReviewLabel ?? '').trim().toLowerCase();
    final wasCorrected = label == 'corrected';
    final wasConfirmed = label == 'confirmed' || label == 'good';
    if (!wasCorrected && !wasConfirmed) return;
    ExpenseScreenTelemetryRecorder.record(
      context,
      wasCorrected
          ? ExpenseTelemetryEventType.appFilledReceiptLineCorrected
          : ExpenseTelemetryEventType.appFilledReceiptLineConfirmed,
      categoryGroup: reviewed.category,
      metadata: {
        'source': _receiptPrivacyFeatureArea,
        'lineUse': reviewed.use.name,
        'hadParserReview': initial.hasParserReview,
        'neededReviewBeforeEdit': initial.parserNeedsReview,
        'parserConfidenceBucket': _confidenceBucket(initial.parserConfidence),
      },
    );
  }

  String _confidenceBucket(double? confidence) {
    if (confidence == null) return 'unknown';
    if (confidence >= .9) return 'high';
    if (confidence >= .75) return 'medium';
    if (confidence >= .55) return 'low';
    return 'very_low';
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
    _receiptDateLockedByUser = true;
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
    _receiptTimeLockedByUser = true;
    _updateReceiptState(() => _selectedTime = picked);
    _scheduleDraftSave();
  }

  void _scheduleDraftSave() {
    if (_receiptReviewExitInFlight || _receiptExitResolved) return;
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 200), () {
      unawaited(_saveDraftNow());
    });
  }

  void _refreshReceiptTotals() {
    if (!mounted) return;
    _updateReceiptState(() {});
  }

  // Retained for detailed review drafts saved by earlier builds.
  // ignore: unused_element
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

  // Retained for detailed review drafts saved by earlier builds.
  // ignore: unused_element
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

  void _setReceiptUse(_ExpenseLineUse use) {
    _updateReceiptState(() {
      _receiptUse = use;
      _receiptUseSelectionMade = true;
      for (var index = 0; index < _lines.length; index++) {
        final line = _lines[index];
        _lines[index] = line.copyWith(
          use: use,
          businessPercent: null,
          splitAllocation: null,
          // A mixed receipt is not permission to invent an ownership split.
          // Keep every line blocked until the user chooses its allocation.
          parserNeedsReview:
              use == _ExpenseLineUse.unclassified ||
              use == _ExpenseLineUse.split,
          parserReviewLabel:
              use == _ExpenseLineUse.unclassified ||
                  use == _ExpenseLineUse.split
              ? 'Review'
              : 'Good',
          parserReviewReason: switch (use) {
            _ExpenseLineUse.unclassified =>
              'Ownership still requires the user to choose business, personal, or split.',
            _ExpenseLineUse.business =>
              'User marked the full receipt as business.',
            _ExpenseLineUse.personal =>
              'User marked the full receipt as personal.',
            _ExpenseLineUse.split =>
              'Split receipt lines require the user to choose each allocation before saving.',
          },
        );
      }
    });
    _scheduleDraftSave();
    if (_usesRebuiltManualDetailedReceiptFlow) return;
    final label = switch (use) {
      _ExpenseLineUse.unclassified => 'unclassified',
      _ExpenseLineUse.business => 'business',
      _ExpenseLineUse.personal => 'personal',
      _ExpenseLineUse.split => 'split',
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _lines.isEmpty
              ? 'New receipt items will count as $label.'
              : 'Marked the full receipt as $label.',
        ),
      ),
    );
  }

  Future<void> _setReceiptLineUse(int index, _ExpenseLineUse use) async {
    if (index < 0 || index >= _lines.length) return;
    ExpenseSplitAllocation? splitAllocation;
    if (use == _ExpenseLineUse.split) {
      splitAllocation = await _chooseSplitAllocation(index);
      if (!mounted || splitAllocation == null) return;
    }
    final splitPercent = use == _ExpenseLineUse.split
        ? splitAllocation?.businessPercentFor(_lines[index].toLedgerLine())
        : null;
    _updateReceiptState(() {
      final line = _lines[index];
      _lines[index] = line.copyWith(
        use: use,
        businessPercent: splitPercent,
        splitAllocation: use == _ExpenseLineUse.split ? splitAllocation : null,
        parserNeedsReview: use == _ExpenseLineUse.unclassified,
        parserReviewLabel: use == _ExpenseLineUse.unclassified
            ? 'Needs classification'
            : 'Good',
        parserReviewReason: switch (use) {
          _ExpenseLineUse.unclassified =>
            'Ownership still requires the user to choose business, personal, or split.',
          _ExpenseLineUse.business =>
            'User marked this receipt line as business.',
          _ExpenseLineUse.personal =>
            'User marked this receipt line as personal.',
          _ExpenseLineUse.split => _splitLineReviewReason(splitPercent),
        },
      );
    });
    _scheduleDraftSave();
  }
}

String _splitLineReviewReason(double? businessPercent) {
  final safePercent = businessPercent == null || !businessPercent.isFinite
      ? .5
      : businessPercent.clamp(0, 1).toDouble();
  final percent = (safePercent * 100).round();
  return 'User marked this receipt line as split; split is $percent% business.';
}
