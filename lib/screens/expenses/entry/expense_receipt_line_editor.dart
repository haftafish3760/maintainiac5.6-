part of 'expense_receipt_entry_screen.dart';

class _ReceiptLineEditorSheet extends StatefulWidget {
  const _ReceiptLineEditorSheet({
    required this.initial,
    required this.lineNumber,
  });

  final _ExpenseReceiptLine initial;
  final int lineNumber;

  @override
  State<_ReceiptLineEditorSheet> createState() =>
      _ReceiptLineEditorSheetState();
}

class _ReceiptLineEditorSheetState extends State<_ReceiptLineEditorSheet> {
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
    super.dispose();
  }

  void _refreshPreview() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 10,
        right: 10,
        top: 10,
        bottom: math.max(
          MediaQuery.viewInsetsOf(context).bottom,
          MediaQuery.paddingOf(context).bottom,
        ) +
            16,
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt_long_rounded,
                color: Color(0xFF34A9E8),
                size: 23,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Receipt item ${widget.lineNumber}',
                  style: const TextStyle(
                    color: Color(0xFFE8ECEE),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Copy the printed item details. Every field stays editable during review.',
            style: TextStyle(
              color: Color(0xFFC8D0D3),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),
          if (widget.initial.hasParserReview) ...[
            _ParserReviewNotice(line: widget.initial),
            const SizedBox(height: 12),
          ],
          RecordTextField(
            label: 'Printed item description',
            controller: _descriptionController,
            hintText: 'Example: 2 in. PVC elbow',
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: RecordTextField(
                  label: 'Quantity',
                  controller: _quantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  hintText: 'Optional',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RecordTextField(
                  label: 'Price each',
                  controller: _unitPriceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  hintText: 'Optional',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RecordTextField(
            label: 'Printed line total',
            controller: _subtotalController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            hintText: 'Required',
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
          const SizedBox(height: 14),
          const Text(
            'How should this item count?',
            style: TextStyle(
              color: Color(0xFFE8ECEE),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          _LineUseBanner(
            use: _use,
            onChanged: (use) => setState(() => _use = use),
          ),
          if (_use == _ExpenseLineUse.split) ...[
            const SizedBox(height: 12),
            _SplitAllocationFields(
              method: _splitMethod,
              businessPercentController: _businessPercentController,
              businessAmountController: _businessAmountController,
              businessPercent: _enteredBusinessPercent,
              businessAmount: _enteredBusinessAmount,
              lineTotal: _enteredLineSubtotal,
              onMethodChanged: (method) =>
                  setState(() => _splitMethod = method),
            ),
          ],
          const SizedBox(height: 14),
          _ExpenseCategorySearch(
            selectedCategory: _category,
            controller: _categorySearchController,
            matches: _matchingCategories,
            onSelected: _selectCategory,
          ),
          const SizedBox(height: 6),
          const Text(
            'Category is optional. Leave it unresolved if you are not sure.',
            style: TextStyle(
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
              unitPriceController: _unitPriceController,
              fuelType: _fuelType,
              fillType: _fillType,
              onFuelTypeChanged: (value) => setState(() {
                _fuelType = value;
                _stockUnit = value == 'Electric' ? 'kWh' : 'gallon';
              }),
              onFillTypeChanged: (value) => setState(() => _fillType = value),
            ),
          ],
          const SizedBox(height: 16),
          Row(
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
        ],
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
