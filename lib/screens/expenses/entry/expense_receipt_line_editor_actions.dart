part of 'expense_receipt_entry_screen.dart';

extension _ReceiptLineEditorActions on _ReceiptLineEditorSheetState {
  Future<void> _save() async {
    final typedCategory = _categorySearchController.text.trim();
    final category =
        _availableExpenseCategoryNames(context).contains(typedCategory)
        ? typedCategory
        : _category;
    final subtotal = _resolvedLineSubtotal ?? 0;
    if (subtotal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter quantity and price, or enter the printed line total.',
          ),
        ),
      );
      return;
    }
    final enteredBusinessPercent =
        _use == _ExpenseLineUse.split &&
            _splitMethod == ExpenseSplitAllocationMethod.percentage
        ? _enteredBusinessPercent
        : null;
    final enteredBusinessAmount =
        _use == _ExpenseLineUse.split &&
            _splitMethod == ExpenseSplitAllocationMethod.amount
        ? _enteredBusinessAmount
        : null;
    if (_use == _ExpenseLineUse.split &&
        ((_splitMethod == ExpenseSplitAllocationMethod.percentage &&
                enteredBusinessPercent == null) ||
            (_splitMethod == ExpenseSplitAllocationMethod.amount &&
                enteredBusinessAmount == null))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _splitMethod == ExpenseSplitAllocationMethod.amount
                ? 'Enter a business dollar amount before saving this split line.'
                : 'Enter a business percentage from 0 to 100 before saving this split line.',
          ),
        ),
      );
      return;
    }
    if (enteredBusinessAmount != null &&
        enteredBusinessAmount > subtotal.abs()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Business amount cannot exceed this printed line total.',
          ),
        ),
      );
      return;
    }
    final splitAllocation = _splitAllocationForEditedLine(
      percent: enteredBusinessPercent,
      amount: enteredBusinessAmount,
      subtotal: subtotal,
    );
    final rule = expenseReceiptRuleForCategory(category);
    final isFuel = rule.isFuel;
    final odometerReading = int.tryParse(
      _odometerController.text.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    if (isFuel) {
      final workProfileId = AppStateScope.of(context).activeWorkProfile?.name;
      const sourceType = 'expense_receipt_fuel_line';
      final sourceId = _descriptionController.text.trim().isEmpty
          ? 'line_${widget.lineNumber}'
          : 'line_${widget.lineNumber}_${_descriptionController.text.trim()}';
      var result = GlobalOdometerScope.of(context).updateFromText(
        _odometerController.text,
        workProfileId: workProfileId,
        sourceType: sourceType,
        sourceId: sourceId,
      );
      if (result.requiresCorrectionReview) {
        final review = await _collectCorrectionReview(
          currentReading: result.currentReading ?? 0,
          candidateReading: result.candidateReading ?? 0,
        );
        if (review == null || !mounted) return;
        result = GlobalOdometerScope.of(context).updateFromText(
          _odometerController.text,
          correctionReview: review,
          workProfileId: workProfileId,
          sourceType: sourceType,
          sourceId: sourceId,
        );
      }
      if (result.requiresMileageReview) {
        final review = await _collectMileageReview(result.deltaMiles ?? 0);
        if (review == null || !mounted) return;
        result = GlobalOdometerScope.of(context).updateFromText(
          _odometerController.text,
          mileageReview: review,
          workProfileId: workProfileId,
          sourceType: sourceType,
          sourceId: sourceId,
        );
      }
      if (result.requiresConfirmation) {
        final confirmed = await _confirmSuspiciousOdometer(result.message);
        if (!confirmed || !mounted) return;
        final confirmedResult = GlobalOdometerScope.of(context).updateFromText(
          _odometerController.text,
          confirmSuspicious: true,
          mileageReview: result.mileageReview,
          correctionReview: result.correctionReview,
          workProfileId: workProfileId,
          sourceType: sourceType,
          sourceId: sourceId,
        );
        if (!confirmedResult.ok) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                confirmedResult.message ?? 'Check odometer reading.',
              ),
            ),
          );
          return;
        }
      } else if (!result.ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Check odometer reading.')),
        );
        return;
      }
    }
    if (!mounted) return;
    final description = _descriptionController.text.trim();
    final quantity = _quantityForSave;
    final unitsPerPackage = _unitsPerPackageForSave;
    final stockUnit = _stockUnit;
    final unitPrice = _unitPriceForSave;
    final parserReviewLabel = _parserReviewLabelForSavedLine(
      description: description,
      category: category,
      subtotal: subtotal,
      quantity: quantity,
      unitsPerPackage: unitsPerPackage,
      stockUnit: stockUnit,
      odometerReading: isFuel ? odometerReading : null,
      fuelType: isFuel ? _fuelType : null,
      fillType: isFuel ? _fillType : null,
      unitPrice: unitPrice,
    );
    final parserReviewReason = _parserReviewReasonForSavedLine(
      parserReviewLabel,
    );
    Navigator.of(context).pop(
      _ExpenseReceiptLine(
        description: description.isEmpty
            ? _defaultReceiptLineDescription(_use)
            : description,
        category: category,
        use: _use,
        quantity: quantity,
        unitsPerPackage: unitsPerPackage,
        stockUnit: stockUnit,
        subtotal: subtotal,
        businessPercent: enteredBusinessPercent,
        splitAllocation: splitAllocation,
        odometerReading: isFuel ? odometerReading : null,
        fuelType: isFuel ? _fuelType : null,
        fillType: isFuel ? _fillType : null,
        unitPrice: unitPrice,
        rawReceiptText: widget.initial.rawReceiptText,
        sourceReceiptText: widget.initial.sourceReceiptText,
        normalizedReceiptText: widget.initial.normalizedReceiptText,
        receiptInterpretation: widget.initial.receiptInterpretation,
        catalogItemId: widget.initial.catalogItemId,
        catalogItemName: widget.initial.catalogItemName,
        catalogItemPath: widget.initial.catalogItemPath,
        catalogMatchConfidence: widget.initial.catalogMatchConfidence,
        catalogMatchedTerms: widget.initial.catalogMatchedTerms,
        parserConfidence: widget.initial.parserConfidence,
        parserReviewLabel: parserReviewLabel,
        parserReviewReason: parserReviewReason,
        parserNeedsReview: false,
      ),
    );
  }

  ExpenseSplitAllocation? _splitAllocationForEditedLine({
    required double? percent,
    required double? amount,
    required double subtotal,
  }) {
    if (_use != _ExpenseLineUse.split) return null;
    if (_splitMethod == ExpenseSplitAllocationMethod.amount) {
      final entered = amount;
      if (entered == null) return null;
      return ExpenseSplitAllocation(
        method: ExpenseSplitAllocationMethod.amount,
        businessValue: subtotal < 0 ? -entered : entered,
      );
    }
    final entered = percent;
    if (entered == null) return null;
    final existing = widget.initial.splitAllocation;
    if (existing != null) {
      final existingPercent = existing.businessPercentFor(
        widget.initial.toLedgerLine(),
      );
      if (existingPercent != null &&
          (existingPercent - entered).abs() < .0001) {
        return existing;
      }
    }
    return ExpenseSplitAllocation(
      method: ExpenseSplitAllocationMethod.percentage,
      businessValue: entered,
    );
  }

  String? _parserReviewLabelForSavedLine({
    required String description,
    required String category,
    required double subtotal,
    required double quantity,
    required double unitsPerPackage,
    required String stockUnit,
    required int? odometerReading,
    required String? fuelType,
    required String? fillType,
    required double? unitPrice,
  }) {
    if (!widget.initial.cameFromAppAssistedReceiptRead) return null;
    return _lineWasChanged(
          description: description,
          category: category,
          subtotal: subtotal,
          quantity: quantity,
          unitsPerPackage: unitsPerPackage,
          stockUnit: stockUnit,
          odometerReading: odometerReading,
          fuelType: fuelType,
          fillType: fillType,
          unitPrice: unitPrice,
        )
        ? 'Corrected'
        : 'Confirmed';
  }

  String? _parserReviewReasonForSavedLine(String? label) {
    return switch (label) {
      'Corrected' =>
        'User reviewed and corrected this app-filled receipt line.',
      'Confirmed' =>
        'User reviewed and confirmed this app-filled receipt line.',
      _ => null,
    };
  }

  bool _lineWasChanged({
    required String description,
    required String category,
    required double subtotal,
    required double quantity,
    required double unitsPerPackage,
    required String stockUnit,
    required int? odometerReading,
    required String? fuelType,
    required String? fillType,
    required double? unitPrice,
  }) {
    return description.trim() != widget.initial.description.trim() ||
        category != widget.initial.category ||
        _use != widget.initial.use ||
        subtotal != widget.initial.subtotal ||
        (_use == _ExpenseLineUse.split &&
            _enteredBusinessPercent !=
                widget.initial.effectiveBusinessPercent) ||
        quantity != widget.initial.quantity ||
        unitsPerPackage != widget.initial.unitsPerPackage ||
        stockUnit != widget.initial.stockUnit ||
        odometerReading != widget.initial.odometerReading ||
        fuelType != widget.initial.fuelType ||
        fillType != widget.initial.fillType ||
        unitPrice != widget.initial.unitPrice;
  }

  double get _quantityForSave => double.tryParse(_quantityController.text) ?? 1;
  double get _unitsPerPackageForSave =>
      double.tryParse(_unitsPerPackageController.text) ?? 1;
  double? get _unitPriceForSave => _parseMoneyInput(_unitPriceController.text);

  String _defaultReceiptLineDescription(_ExpenseLineUse use) {
    return switch (use) {
      _ExpenseLineUse.unclassified => 'Receipt items',
      _ExpenseLineUse.business => 'Business receipt items',
      _ExpenseLineUse.personal => 'Personal receipt items',
      _ExpenseLineUse.split => 'Split receipt items',
    };
  }
}
