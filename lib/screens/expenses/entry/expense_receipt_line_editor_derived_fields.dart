part of 'expense_receipt_entry_screen.dart';

extension _ReceiptLineEditorDerivedFields on _ReceiptLineEditorSheetState {
  String get _lineMathPreview {
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final units = double.tryParse(_unitsPerPackageController.text) ?? 1;
    final totalUnits = quantity * units;
    final split = _use == _ExpenseLineUse.split
        ? ' Business ${_percent(_businessPercent)}, personal ${_percent(1 - _businessPercent)}.'
        : '';
    if (!_usesMeasuredLine) {
      return '${_categoryRule.guidance}$split';
    }
    if (quantity <= 0) {
      return _usesPackageContents
          ? 'Enter how many packages were bought.'
          : 'Enter how many $_stockUnitLabelPlural were bought.';
    }
    if (!_usesPackageContents || units <= 1) {
      return 'This line adds ${_formatNumber(quantity)} $_stockUnitLabelPlural.$split';
    }
    return 'This line adds ${_formatNumber(totalUnits)} items total from ${_formatNumber(quantity)} $_stockUnitLabelPlural.$split';
  }

  bool get _usesMeasuredLine => _categoryRule.usesQuantityFields;

  ExpenseReceiptCategoryRule get _categoryRule =>
      expenseReceiptRuleForCategory(_category);

  bool get _isFuelLine => _categoryRule.isFuel;

  double get _businessPercent {
    final raw = _businessPercentController.text.trim();
    final normalized = raw.replaceAll('%', '').replaceAll(',', '').trim();
    final numeric = double.tryParse(normalized);
    if (numeric == null) return .5;
    final percent = numeric > 1 ? numeric / 100 : numeric;
    if (percent < 0) return 0;
    if (percent > 1) return 1;
    return percent;
  }

  String get _descriptionLabel {
    if (_isFuelLine) {
      return 'Fuel Receipt Description';
    }
    if (!_usesMeasuredLine) {
      return 'Receipt Line Description';
    }
    return 'Receipt Item Description';
  }

  String get _descriptionHint {
    if (_isFuelLine) {
      return _fuelType == 'Electric'
          ? 'Example: EV charge'
          : 'Example: $_fuelType fuel';
    }
    if (!_usesMeasuredLine) {
      return 'Example: loan payment, insurance premium, permit fee';
    }
    return _categoryRule.descriptionHint;
  }

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

  String get _stockUnitLabelPlural {
    return switch (_stockUnit) {
      'each' => 'items',
      'foot' => 'feet',
      'kWh' => 'kWh',
      _ => _stockUnit,
    };
  }

  Widget get _quantityFields {
    if (_usesPackageContents) {
      return Row(
        children: [
          Expanded(
            child: RecordTextField(
              label: 'How Many $_stockUnitLabelPlural?',
              controller: _quantityController,
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RecordTextField(
              label: 'Items In Each',
              controller: _unitsPerPackageController,
              keyboardType: TextInputType.number,
            ),
          ),
        ],
      );
    }
    return RecordTextField(
      label: _quantityLabel,
      controller: _quantityController,
      keyboardType: TextInputType.number,
    );
  }

  String get _quantityLabel {
    return switch (_stockUnit) {
      'each' => 'How Many Items?',
      'kWh' => 'How Many kWh?',
      'gallon' => 'How Many Gallons?',
      'quart' => 'How Many Quarts?',
      'ounce' => 'How Many Ounces?',
      'pound' => 'How Many Pounds?',
      'foot' || 'linear foot' => 'How Many Feet?',
      'sheet' => 'How Many Sheets?',
      'tube' => 'How Many Tubes?',
      _ => 'How Many $_stockUnitLabelPlural?',
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
