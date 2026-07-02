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
  late final _ExpenseLineUse _use = widget.initial.use;
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
    _odometerController.removeListener(_refreshPreview);
    _unitPriceController.removeListener(_refreshPreview);
    _categorySearchController.removeListener(_refreshPreview);
    _descriptionController.dispose();
    _quantityController.dispose();
    _unitsPerPackageController.dispose();
    _businessPercentController.dispose();
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
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          ReceiptFormPanel(
            title: 'Receipt Line ${widget.lineNumber}',
            subtitle:
                'Select the receipt category, describe the item, then enter how it was sold.',
            icon: Icons.edit_note_rounded,
            accentColor: const Color(0xFF34A9E8),
            children: [
              if (_isFuelLine)
                const _FuelAllocationNotice()
              else
                _LineUseBanner(use: _use),
              if (widget.initial.hasParserReview) ...[
                const SizedBox(height: 10),
                _ParserReviewNotice(line: widget.initial),
              ],
              if (_use == _ExpenseLineUse.split) ...[
                const SizedBox(height: 10),
                _SplitAllocationFields(
                  businessPercentController: _businessPercentController,
                  businessPercent: _businessPercent,
                ),
              ],
              const SizedBox(height: 10),
              _ExpenseCategorySearch(
                selectedCategory: _category,
                controller: _categorySearchController,
                matches: _matchingCategories,
                onSelected: _selectCategory,
              ),
              const SizedBox(height: 10),
              _CategoryRuleNotice(rule: _categoryRule),
              const SizedBox(height: 10),
              if (_isFuelLine) ...[
                _FuelReceiptFields(
                  odometerController: _odometerController,
                  unitPriceController: _unitPriceController,
                  fuelType: _fuelType,
                  fillType: _fillType,
                  onFuelTypeChanged: (value) => setState(() {
                    _fuelType = value;
                    _stockUnit = value == 'Electric' ? 'kWh' : 'gallon';
                  }),
                  onFillTypeChanged: (value) =>
                      setState(() => _fillType = value),
                ),
                const SizedBox(height: 10),
              ],
              RecordTextField(
                label: _descriptionLabel,
                controller: _descriptionController,
                hintText: _descriptionHint,
              ),
              const SizedBox(height: 10),
              if (_usesMeasuredLine) ...[
                if (!_isFuelLine) ...[
                  RecordDropdownField<String>(
                    label: 'How Was This Item Sold?',
                    value: _stockUnit,
                    items: _stockUnits,
                    itemLabel: (item) => item,
                    onChanged: (value) => setState(() {
                      _stockUnit = value;
                      if (!_usesPackageContents) {
                        _unitsPerPackageController.text = '1';
                      }
                    }),
                  ),
                  const SizedBox(height: 10),
                ],
                _quantityFields,
                const SizedBox(height: 10),
              ],
              RecordTextField(
                label: 'Line Subtotal',
                controller: _subtotalController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 6),
              Text(
                _lineMathPreview,
                style: const TextStyle(
                  color: Color(0xFFC8D0D3),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _save,
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
        if (!_usesMeasuredLine) {
          _quantityController.text = '1';
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
