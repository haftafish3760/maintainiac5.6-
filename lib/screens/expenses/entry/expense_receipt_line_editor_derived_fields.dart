part of 'expense_receipt_entry_screen.dart';

extension _ReceiptLineEditorDerivedFields on _ReceiptLineEditorSheetState {
  String get _lineMathPreview {
    final quantity = double.tryParse(_quantityController.text.trim());
    final unitPrice = _parseMoneyInput(_unitPriceController.text);
    final printedTotal = _enteredLineSubtotal;
    final calculated = _calculatedLineSubtotal;
    if (quantity != null &&
        quantity > 0 &&
        unitPrice != null &&
        calculated != null) {
      final totalNote = printedTotal == null
          ? ' The line total is calculated automatically.'
          : ' The line total is calculated from quantity and price.';
      return '${_formatNumber(quantity)} × ${_money(unitPrice)} = ${_money(calculated)}.$totalNote';
    }
    return 'Enter a printed total when quantity and price each are not available.';
  }

  double? get _calculatedLineSubtotal {
    final quantity = double.tryParse(_quantityController.text.trim());
    final unitPrice = _parseMoneyInput(_unitPriceController.text);
    if (quantity == null || quantity <= 0 || unitPrice == null) return null;
    return quantity * unitPrice;
  }

  double? get _resolvedLineSubtotal =>
      _calculatedLineSubtotal ?? _enteredLineSubtotal;

  ExpenseReceiptCategoryRule get _categoryRule =>
      expenseReceiptRuleForCategory(_category);

  bool get _isFuelLine => _categoryRule.isFuel;

  String get _unitPriceLabel {
    if (_isFuelLine) {
      return _fuelType == 'Electric' ? 'Price per kWh' : 'Price per gallon';
    }
    return _categoryRule.unitPriceLabel;
  }

  List<String> get _unitChoices {
    final choices = <String>{
      ..._categoryRule.unitChoices,
      'each',
      'piece',
      'ounce',
      'pound',
      'quart',
      'gallon',
      'case',
      'box',
      'bag',
      'pack',
      'foot',
      'inch',
      'service',
      'kWh',
      _stockUnit,
    };
    return choices.toList(growable: false);
  }

  double? get _enteredBusinessPercent {
    final raw = _businessPercentController.text.trim();
    if (raw.isEmpty) return null;
    final normalized = raw.replaceAll('%', '').replaceAll(',', '').trim();
    final numeric = double.tryParse(normalized);
    if (numeric == null || !numeric.isFinite) return null;
    final percent = numeric > 1 ? numeric / 100 : numeric;
    if (percent < 0 || percent > 1) return null;
    return percent;
  }

  double? get _enteredBusinessAmount {
    final value = _parseMoneyInput(_businessAmountController.text);
    if (value == null || !value.isFinite || value < 0) return null;
    return value;
  }

  double? get _enteredLineSubtotal =>
      _parseMoneyInput(_subtotalController.text);

  bool get _usesPackageContents {
    return switch (_stockUnit) {
      'pack' ||
      'package' ||
      'box' ||
      'case' ||
      'bag' ||
      'roll' ||
      'set' => true,
      _ => false,
    };
  }

  List<String> get _matchingCategories {
    final query = _categorySearchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return [
        'Uncategorized',
        ..._homeCategoryNames(context),
      ].take(10).toList(growable: false);
    }
    return _availableExpenseCategoryNames(context)
        .where((category) => category.toLowerCase().contains(query))
        .take(10)
        .toList();
  }
}
