part of 'expense_receipt_entry_screen.dart';

extension _ReceiptLineEditorActions on _ReceiptLineEditorSheetState {
  Future<void> _save() async {
    final typedCategory = _categorySearchController.text.trim();
    final category = _expenseCategoryNames.contains(typedCategory)
        ? typedCategory
        : _category;
    final subtotal = _parseMoneyInput(_subtotalController.text) ?? 0;
    if (subtotal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the line subtotal first.')),
      );
      return;
    }
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
    final quantity = rule.usesQuantityFields ? _quantityForSave : 1.0;
    final unitsPerPackage = rule.usesQuantityFields
        ? _unitsPerPackageForSave
        : 1.0;
    final stockUnit = rule.usesQuantityFields ? _stockUnit : 'each';
    final unitPrice = isFuel ? _unitPriceForSave : null;
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
        businessPercent: _use == _ExpenseLineUse.split
            ? _businessPercent
            : null,
        odometerReading: isFuel ? odometerReading : null,
        fuelType: isFuel ? _fuelType : null,
        fillType: isFuel ? _fillType : null,
        unitPrice: unitPrice,
        rawReceiptText: widget.initial.rawReceiptText,
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
        _businessPercent != widget.initial.effectiveBusinessPercent ||
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
  double? get _unitPriceForSave => double.tryParse(_unitPriceController.text);

  String _defaultReceiptLineDescription(_ExpenseLineUse use) {
    return switch (use) {
      _ExpenseLineUse.unclassified => 'Receipt items',
      _ExpenseLineUse.business => 'Business receipt items',
      _ExpenseLineUse.personal => 'Personal receipt items',
      _ExpenseLineUse.split => 'Split receipt items',
    };
  }
}
