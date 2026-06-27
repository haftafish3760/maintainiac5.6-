part of 'work_supply_add_items_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _WorkSupplyAddItemsLineEditorActions
    on _WorkSupplyAddItemsScreenState {
  Future<void> _save() async {
    final line = _pendingReceiptLine;
    if (line == null) return;
    if (_itemEntryMode == _ItemEntryMode.nonInventory) {
      setState(() {
        _stagedReceiptLines.add(line);
        _resetLineFormAfterStaging();
      });
      return;
    }
    final record = _previewInventoryRecord;
    if (record == null) return;
    await _savePackageAliasFor(record.item);
    if (!mounted) return;
    setState(() {
      _stagedReceiptLines.add(line);
      _stagedInventoryLines.add(record);
      _resetLineFormAfterStaging();
    });
  }

  Future<void> _openLineEditor(_ItemEntryMode mode) async {
    setState(() => _itemEntryMode = mode);
    final appState = AppStateScope.of(context);
    final destinationChoices = buildWorkSupplyInventoryDestinations(
      appState: appState,
      jobNumber: widget.jobNumber,
    );
    final isInventoryLine = mode != _ItemEntryMode.nonInventory;
    final requiresExplicitDestination =
        isInventoryLine &&
        widget.initialStorageArea == null &&
        appState.vehicles.length > 1;
    if (requiresExplicitDestination &&
        _storageArea == workSupplyActiveVehicleInventoryLabel) {
      setState(() => _storageArea = _chooseInventoryDestinationLabel);
    }
    final result = await Navigator.of(context).push<bool>(
      appNativeRoute(
        context,
        StatefulBuilder(
          builder: (context, setEditorState) {
            final query = _search.text.trim();
            final results = query.isEmpty
                ? <WorkSupplyItem>[]
                : mergeWorkSupplySearchResults(
                    query: query,
                    customItems: widget.customCatalogItems,
                  ).take(8).toList();
            void refresh() {
              if (mounted) setState(() {});
              setEditorState(() {});
            }

            return _ReceiptLineEditorScreen(
              mode: mode,
              lineNumber: _stagedReceiptLines.length + 1,
              showDestinationPicker: isInventoryLine,
              scrollController: _lineEditorScrollController,
              canSave: _canSave,
              canStepBack: _canLineEditorStepBack,
              onStepBack: () {
                _goBackOneLevel();
                setEditorState(() {});
              },
              onSave: () async {
                await _save();
                if (!context.mounted) return;
                Navigator.of(context).pop(true);
              },
              child: _LineItemForm(
                receiptLineNumber: _stagedInventoryLines.length + 1,
                entryMode: mode,
                showLineChoices: false,
                search: _search,
                customItemName: _customItemName,
                customItemDescription: _customItemDescription,
                customTrade: _customTrade,
                customCategorySelection: _customCategorySelection,
                customSystemSelection: _customSystemSelection,
                customItemTypeSelection: _customItemTypeSelection,
                customSizeSelection: _customSizeSelection,
                customCategory: _customCategory,
                customSystem: _customSystem,
                customItemType: _customItemType,
                customSize: _customSize,
                typedSuggestion: _typedCatalogSuggestion,
                nonInventoryExpenseCategory: _nonInventoryExpenseCategory,
                results: results,
                selectedItem: _selectedItem,
                trade: _trade,
                category: _category,
                system: _system,
                itemType: _itemType,
                searchFocus: _searchFocus,
                packages: _packages,
                unitsPerPackage: _unitsPerPackage,
                subtotal: _subtotal,
                taxRate: _taxRate,
                threshold: _threshold,
                businessUse: _businessUse,
                businessPercent: _businessPercent,
                barcodeValue: _barcodeValue,
                barcodePackageLabel: _barcodePackageLabel,
                showBusinessUsePicker: false,
                storageArea: _storageArea,
                customDestination: _customDestination,
                storageDetail: _storageDetail,
                destinationChoices: destinationChoices,
                showDestinationPicker: isInventoryLine,
                purchaseType: _purchaseType,
                onEntryMode: (_) {},
                onSearchChanged: (_) => refresh(),
                onCustomItemChanged: (value) {
                  _handleCustomItemTyping(value);
                  setEditorState(() {});
                },
                onCustomTrade: (value) {
                  _selectCustomTrade(value);
                  setEditorState(() {});
                },
                onCustomCategory: (value) {
                  _selectCustomCategory(value);
                  setEditorState(() {});
                },
                onCustomSystem: (value) {
                  _selectCustomSystem(value);
                  setEditorState(() {});
                },
                onCustomItemType: (value) {
                  _selectCustomItemType(value);
                  setEditorState(() {});
                },
                onCustomSize: (value) {
                  _selectCustomSize(value);
                  setEditorState(() {});
                },
                onApplyTypedSuggestion: () {
                  _acceptTypedCatalogSuggestion();
                  setEditorState(() {});
                },
                onApplyCatalogSuggestion: (item) {
                  setState(() => _applyCatalogItemToCustomPath(item));
                  setEditorState(() {});
                },
                onNonInventoryExpenseCategory: (value) {
                  setState(() => _nonInventoryExpenseCategory = value);
                  setEditorState(() {});
                },
                onMathChanged: (_) => refresh(),
                onStorageDetailChanged: (_) => refresh(),
                onBusinessUse: (value) {
                  setState(() {
                    _applyLineBusinessUse(value);
                  });
                  setEditorState(() {});
                },
                onBusinessPercentChanged: (_) => refresh(),
                onBarcodeChanged: (_) => refresh(),
                onPurchaseType: (type) {
                  setState(() {
                    _purchaseType = type;
                    if (!type.asksUnitsPerContainer) {
                      _unitsPerPackage.text = '1';
                      _customUnit = type.storageValue;
                    }
                  });
                  setEditorState(() {});
                },
                onStorageArea: (value) {
                  setState(() => _storageArea = value);
                  setEditorState(() {});
                },
                onAddVehicle: () async {
                  await _openAddVehicleForReceipt();
                  setEditorState(() {});
                },
                onTrade: (trade) {
                  setState(() {
                    _trade = trade;
                    _category = null;
                    _system = null;
                    _itemType = null;
                  });
                  setEditorState(() {});
                },
                onCategory: (category) {
                  setState(() {
                    _category = category;
                    _system = null;
                    _itemType = null;
                  });
                  setEditorState(() {});
                },
                onSystem: (system) {
                  setState(() {
                    _system = system;
                    _itemType = null;
                  });
                  setEditorState(() {});
                },
                onItemType: (itemType) {
                  setState(() => _itemType = itemType);
                  setEditorState(() {});
                },
                onBack: () {
                  _goBackOneLevel();
                  setEditorState(() {});
                },
                onItemSelected: (item) {
                  setState(() {
                    _selectedItem = item;
                    _search.text = item.name;
                  });
                  setEditorState(() {});
                },
                onCreateInventoryItem: () {
                  setState(() {
                    _itemEntryMode = _ItemEntryMode.newInventory;
                    _selectedItem = null;
                  });
                  setEditorState(() {});
                },
              ),
            );
          },
        ),
      ),
    );
    if (result != true && mounted) {
      setState(() => _itemEntryMode = null);
    }
  }
}
