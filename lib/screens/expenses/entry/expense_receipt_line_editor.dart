part of 'expense_receipt_entry_screen.dart';

class _ReceiptLineEditorSheet extends StatefulWidget {
  const _ReceiptLineEditorSheet({
    required this.initial,
    required this.lineNumber,
    this.allowLineClassification = true,
  });

  final _ExpenseReceiptLine initial;
  final int lineNumber;
  final bool allowLineClassification;

  @override
  State<_ReceiptLineEditorSheet> createState() =>
      _ReceiptLineEditorSheetState();
}

class _ReceiptLineEditorSheetState extends State<_ReceiptLineEditorSheet> {
  final _descriptionFocus = FocusNode();
  final _unitPriceFocus = FocusNode();
  final _quantityFocus = FocusNode();
  late final _descriptionController = TextEditingController(
    text: widget.initial.description,
  );
  late final _quantityController = TextEditingController(
    text: widget.initial.quantityText,
  );
  late final _unitsPerPackageController = TextEditingController(
    text: widget.initial.unitsPerPackageText,
  );
  late final _subtotalController = TextEditingController(
    text: widget.initial.subtotalText,
  );
  late final _businessPercentController = TextEditingController(
    text: widget.initial.businessPercentText,
  );
  late final _businessAmountController = TextEditingController(
    text:
        widget.initial.splitAllocation?.method ==
            ExpenseSplitAllocationMethod.amount
        ? widget.initial.splitAllocation!.businessValue.abs().toStringAsFixed(2)
        : '',
  );
  late final _odometerController = TextEditingController(
    text: widget.initial.odometerReading?.toString() ?? '',
  );
  late final _unitPriceController = TextEditingController(
    text: widget.initial.unitPrice == null
        ? ''
        : widget.initial.unitPrice!.toStringAsFixed(3),
  );
  late final _categorySearchController = TextEditingController(
    text: widget.initial.category == 'Uncategorized'
        ? ''
        : widget.initial.category,
  );
  late _ExpenseLineUse _use = widget.initial.use;
  late ExpenseSplitAllocationMethod _splitMethod =
      widget.initial.splitAllocation?.method ??
      ExpenseSplitAllocationMethod.percentage;
  late String _category = widget.initial.category;
  late String _stockUnit = widget.initial.stockUnit;
  late String _fuelType = widget.initial.fuelType ?? 'Gasoline';
  late String _fillType = widget.initial.fillType ?? 'Full fill-up';
  var _seededOdometer = false;

  @override
  void initState() {
    super.initState();
    _quantityController.addListener(_refreshPreview);
    _unitsPerPackageController.addListener(_refreshPreview);
    _businessPercentController.addListener(_refreshPreview);
    _businessAmountController.addListener(_refreshPreview);
    _odometerController.addListener(_refreshPreview);
    _unitPriceController.addListener(_refreshPreview);
    _categorySearchController.addListener(_refreshPreview);
    if (_category == 'Fuel') {
      _stockUnit = _fuelType == 'Electric' ? 'kWh' : 'gallon';
    } else if (widget.initial.stockUnit == 'each' &&
        widget.initial.category != 'Uncategorized') {
      _stockUnit = defaultExpenseReceiptUnit(_category);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seededOdometer || _category != 'Fuel') return;
    _seededOdometer = true;
    if (_odometerController.text.trim().isEmpty) {
      _odometerController.text = GlobalOdometerScope.of(
        context,
      ).reading.toString();
    }
  }

  @override
  void dispose() {
    _quantityController.removeListener(_refreshPreview);
    _unitsPerPackageController.removeListener(_refreshPreview);
    _businessPercentController.removeListener(_refreshPreview);
    _businessAmountController.removeListener(_refreshPreview);
    _odometerController.removeListener(_refreshPreview);
    _unitPriceController.removeListener(_refreshPreview);
    _categorySearchController.removeListener(_refreshPreview);
    _descriptionController.dispose();
    _quantityController.dispose();
    _unitsPerPackageController.dispose();
    _businessPercentController.dispose();
    _businessAmountController.dispose();
    _subtotalController.dispose();
    _odometerController.dispose();
    _unitPriceController.dispose();
    _categorySearchController.dispose();
    _descriptionFocus.dispose();
    _unitPriceFocus.dispose();
    _quantityFocus.dispose();
    super.dispose();
  }

  void _refreshPreview() => setState(() {});

  void _updateEditorState(VoidCallback update) {
    if (!mounted) return;
    setState(update);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0D0F),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 58,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Back',
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: _receiptReferenceText,
                  ),
                  const Expanded(
                    child: Text(
                      'Add Item',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _receiptReferenceText,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _save,
                    tooltip: 'Save item',
                    icon: const Icon(Icons.check_rounded),
                    color: _receiptReferenceText,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 14,
                  right: 14,
                  bottom:
                      math.max(
                        MediaQuery.viewInsetsOf(context).bottom,
                        MediaQuery.paddingOf(context).bottom,
                      ) +
                      16,
                ),
                child: ListView(
                  children: [
                    Text(
                      'Line ${widget.lineNumber}',
                      style: const TextStyle(
                        color: _receiptReferenceMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (widget.initial.cameFromAppAssistedReceiptRead &&
                        widget.initial.parserNeedsReview) ...[
                      const SizedBox(height: 8),
                      const _AppFilledLineReviewNotice(),
                    ],
                    const SizedBox(height: 10),
                    _ExpenseCategorySearch(
                      compact: true,
                      selectedCategory: _category,
                      controller: _categorySearchController,
                      matches: _matchingCategories,
                      onSelected: _selectCategory,
                    ),
                    if (widget.allowLineClassification) ...[
                      const SizedBox(height: 14),
                      const Text(
                        'HOW SHOULD THIS ITEM COUNT?',
                        style: TextStyle(
                          color: _receiptReferenceMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 7),
                      _LineUseBanner(use: _use, onChanged: _chooseLineUse),
                    ],
                    const SizedBox(height: 14),
                    RecordTextField(
                      label: 'Item description',
                      dark: true,
                      controller: _descriptionController,
                      focusNode: _descriptionFocus,
                      nextFocusNode: _unitPriceFocus,
                      textInputAction: TextInputAction.next,
                      hintText: _categoryRule.descriptionHint,
                    ),
                    const SizedBox(height: 10),
                    if (_categoryRule.usesQuantityFields) ...[
                      Row(
                        children: [
                          Expanded(
                            child: RecordTextField(
                              label: _unitPriceLabel,
                              dark: true,
                              controller: _unitPriceController,
                              focusNode: _unitPriceFocus,
                              nextFocusNode: _quantityFocus,
                              textInputAction: TextInputAction.next,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              hintText: r'$0.00',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RecordDropdownField<String>(
                              label: 'Unit of measure',
                              dark: true,
                              value: _stockUnit,
                              items: _unitChoices,
                              itemLabel: (value) => value,
                              labelMaxWidthFactor: .94,
                              onChanged: (value) =>
                                  setState(() => _stockUnit = value),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _ReceiptQuantityStepper(
                              label: _categoryRule.quantityLabel,
                              controller: _quantityController,
                              onChanged: _refreshPreview,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _ReceiptItemLineTotal(
                              total: _resolvedLineSubtotal,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    RecordTextField(
                      label: 'Printed line total (optional)',
                      dark: true,
                      controller: _subtotalController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      hintText: r'$0.00',
                      helperText:
                          'Use this only when the receipt shows one line amount.',
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _lineMathPreview,
                      style: const TextStyle(
                        color: Color(0xFFC8D0D3),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    if (_isFuelLine) ...[
                      const SizedBox(height: 12),
                      _FuelReceiptFields(
                        odometerController: _odometerController,
                        fuelType: _fuelType,
                        fillType: _fillType,
                        onFuelTypeChanged: (value) => setState(() {
                          _fuelType = value;
                          _stockUnit = value == 'Electric' ? 'kWh' : 'gallon';
                        }),
                        onFillTypeChanged: (value) =>
                            setState(() => _fillType = value),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: const Color(0xFF0B0D0F),
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          child: Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFC62828),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Save Item'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF28A745),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectCategory(String category) {
    setState(() {
      _category = category;
      if (_category == 'Fuel') {
        _stockUnit = _fuelType == 'Electric' ? 'kWh' : 'gallon';
        _unitsPerPackageController.text = '1';
        if (_odometerController.text.trim().isEmpty) {
          _odometerController.text = GlobalOdometerScope.of(
            context,
          ).reading.toString();
        }
      } else {
        _stockUnit = defaultExpenseReceiptUnit(category);
        if (!_usesPackageContents) {
          _unitsPerPackageController.text = '1';
        }
      }
      _categorySearchController.text = category;
      _categorySearchController.selection = TextSelection.collapsed(
        offset: category.length,
      );
    });
  }
}
