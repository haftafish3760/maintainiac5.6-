part of 'work_supply_add_items_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _WorkSupplyAddItemsCustomPathActions
    on _WorkSupplyAddItemsScreenState {
  void _handleCustomItemTyping(String _) {
    final hadSuggestion = _typedCatalogSuggestion != null;
    setState(_updateCatalogSuggestionFromTypedText);
    if (!hadSuggestion && _typedCatalogSuggestion != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_lineEditorScrollController.hasClients) return;
        final position = _lineEditorScrollController.position;
        final target = (_lineEditorScrollController.offset + 120).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        );
        _lineEditorScrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _updateCatalogSuggestionFromTypedText() {
    final query = [
      _customItemName.text.trim(),
      _customItemDescription.text.trim(),
    ].where((value) => value.isNotEmpty).join(' ');
    if (query.length < 4) {
      _typedCatalogSuggestion = null;
      return;
    }

    final searchResults = searchWorkSupplies(query);
    _typedCatalogSuggestion =
        matchReceiptLineToCatalog(query)?.item ??
        (searchResults.isEmpty ? null : searchResults.first);
  }

  void _applyCatalogItemToCustomPath(WorkSupplyItem item) {
    _customTrade = item.trade;
    _customCategorySelection = item.category;
    _customItemTypeSelection = item.itemType;
    _customSystemSelection = item.system;
    _customSizeSelection = item.variant;
    _customCategory.clear();
    _customSystem.clear();
    _customItemType.clear();
    _customSize.clear();
    if (_customUnit == 'each') _customUnit = item.unit;
    _typedCatalogSuggestion = null;
  }

  void _acceptTypedCatalogSuggestion() {
    final suggestion = _typedCatalogSuggestion;
    if (suggestion == null) return;
    setState(() => _applyCatalogItemToCustomPath(suggestion));
  }

  void _selectCustomTrade(String trade) {
    setState(() {
      _customTrade = trade == _chooseTradeLabel ? '' : trade;
      _customCategorySelection = null;
      _customSystemSelection = null;
      _customItemTypeSelection = null;
      _customSizeSelection = null;
      _customCategory.clear();
      _customSystem.clear();
      _customItemType.clear();
      _customSize.clear();
    });
  }

  void _selectCustomCategory(String? category) {
    setState(() {
      _customCategorySelection = category;
      _customSystemSelection = null;
      _customItemTypeSelection = null;
      _customSizeSelection = null;
      _customSystem.clear();
      _customItemType.clear();
      _customSize.clear();
    });
  }

  void _selectCustomSystem(String? system) {
    setState(() {
      _customSystemSelection = system;
      _customSizeSelection = null;
      _customSize.clear();
    });
  }

  void _selectCustomItemType(String? itemType) {
    setState(() {
      _customItemTypeSelection = itemType;
      _customSystemSelection = null;
      _customSizeSelection = null;
      _customSystem.clear();
      _customSize.clear();
    });
  }

  void _selectCustomSize(String? size) {
    setState(() => _customSizeSelection = size);
  }

  DateTime get _loggedAt {
    final time = _selectedTime;
    if (time == null) return _selectedDate;
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      time.hour,
      time.minute,
    );
  }

  String get _resolvedStorageArea {
    return resolveWorkSupplyInventoryDestination(
      selectedDestination: _storageArea,
      customDestination: _customDestination.text,
    );
  }

  bool get _canStepBack {
    return _selectedItem != null ||
        _itemType != null ||
        _system != null ||
        _category != null ||
        _trade != null ||
        _itemEntryMode != null;
  }

  void _stepBack() {
    setState(() {
      if (_selectedItem != null) {
        _selectedItem = null;
      } else if (_itemType != null) {
        _itemType = null;
      } else if (_system != null) {
        _system = null;
      } else if (_category != null) {
        _category = null;
      } else if (_trade != null) {
        _trade = null;
      } else if (_itemEntryMode != null) {
        _itemEntryMode = null;
      }
    });
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
    setState(() => _selectedDate = picked);
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
    setState(() => _selectedTime = picked);
  }

  double _toDouble(String value, double fallback) {
    return double.tryParse(value.trim()) ?? fallback;
  }

  void _goBackOneLevel() {
    setState(() {
      if (_itemType != null) {
        _itemType = null;
      } else if (_system != null) {
        _system = null;
      } else if (_category != null) {
        _category = null;
      } else {
        _trade = null;
      }
    });
  }
}
