part of 'work_supply_add_items_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _WorkSupplyAddItemsReceiptActions on _WorkSupplyAddItemsScreenState {
  Future<void> _openInventoryReceiptLine() async {
    setState(() {
      _clearInventoryPickerState();
      _businessUse = _LineBusinessUse.business;
      _businessPercent.text = '100';
      if (widget.initialStorageArea == null &&
          (_storageArea == workSupplyActiveVehicleInventoryLabel ||
              _storageArea == _chooseInventoryDestinationLabel)) {
        _storageArea = workSupplyCompanyInventoryLabel;
      }
    });
    await _openLineEditor(_ItemEntryMode.catalogInventory);
  }

  void _clearInventoryPickerState() {
    _selectedItem = null;
    _trade = null;
    _category = null;
    _system = null;
    _itemType = null;
    _search.clear();
  }

  Future<void> _openBusinessReceiptLine() async {
    setState(() {
      _applyLineBusinessUse(_LineBusinessUse.business);
    });
    await _openLineEditor(_ItemEntryMode.nonInventory);
  }

  Future<void> _openPersonalReceiptLine() async {
    setState(() {
      _applyLineBusinessUse(_LineBusinessUse.personal);
    });
    await _openLineEditor(_ItemEntryMode.nonInventory);
  }

  Future<void> _openSplitReceiptLine() async {
    setState(() {
      _applyLineBusinessUse(_LineBusinessUse.split);
    });
    await _openLineEditor(_ItemEntryMode.nonInventory);
  }

  void _confirmParsedReceiptLine(int index) {
    if (index < 0 || index >= _stagedReceiptLines.length) return;
    final line = _stagedReceiptLines[index];
    if (!line.canConfirmAssistedReview) return;
    setState(() {
      final confirmed = line.confirmedAssistedReview();
      _stagedReceiptLines[index] = confirmed;
      _syncStagedInventoryLine(confirmed);
      _refreshParsedReceiptReviewSummary();
    });
  }

  void _confirmAllParsedReceiptLines() {
    var changed = 0;
    setState(() {
      for (var index = 0; index < _stagedReceiptLines.length; index++) {
        final line = _stagedReceiptLines[index];
        if (!line.canConfirmAssistedReview) continue;
        final confirmed = line.confirmedAssistedReview();
        _stagedReceiptLines[index] = confirmed;
        _syncStagedInventoryLine(confirmed);
        changed++;
      }
      if (changed > 0) {
        _refreshParsedReceiptReviewSummary();
      }
    });
    if (changed == 0) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Confirmed $changed parsed receipt line${changed == 1 ? '' : 's'}.',
        ),
      ),
    );
  }

  void _syncStagedInventoryLine(ReceiptLineDraft line) {
    if (!line.isInventory) return;
    final index = stagedInventoryRecordIndexForLine(
      _stagedInventoryLines,
      line,
    );
    if (index == -1) return;
    _stagedInventoryLines[index] = syncedInventoryRecordForLine(
      record: _stagedInventoryLines[index],
      line: line,
    );
  }

  void _refreshParsedReceiptReviewSummary() {
    final parsedLines = _stagedReceiptLines
        .where((line) => line.hasAssistedReview)
        .toList(growable: false);
    if (parsedLines.isEmpty) {
      _parsedReceiptReview = null;
      return;
    }
    final needsReview =
        parsedLines.any((line) => line.parserNeedsReview) ||
        unconfirmedAssistedInventoryLineCount(parsedLines) > 0;
    final averageConfidence =
        parsedLines.fold<double>(
          0,
          (sum, line) => sum + (line.parserConfidence ?? 0),
        ) /
        parsedLines.length;
    _parsedReceiptReview = _ParsedMaterialsReceiptReviewSummary(
      qualityLabel: needsReview ? 'Review' : 'Good',
      confidenceLabel: '${(averageConfidence * 100).round()}%',
      needsReview: needsReview,
      warning: needsReview ? _parsedReceiptReview?.warning : null,
    );
  }

  void _applyLineBusinessUse(_LineBusinessUse value) {
    _businessUse = value;
    if (value == _LineBusinessUse.business) {
      _businessPercent.text = '100';
    } else if (value == _LineBusinessUse.personal) {
      _businessPercent.text = '0';
    } else if (_toDouble(_businessPercent.text, 0) <= 0) {
      _businessPercent.text = '50';
    }
  }

  Future<void> _openAddVehicleForReceipt() async {
    final preview = await Navigator.of(context).push<VehicleProfilePreview>(
      appNativeRoute(context, const AddVehicleProfileScreen()),
    );
    if (preview == null || !mounted) return;
    final vehicle = VehicleProfile(
      nickname: preview.nickname.trim().isEmpty
          ? 'New Vehicle'
          : preview.nickname.trim(),
      year: preview.year,
      make: preview.make,
      model: preview.model,
      usage: preview.usage,
    );
    AppStateScope.of(context).addVehicle(vehicle);
    setState(() {
      _storageArea = '${vehicle.nickname} inventory';
    });
  }

  WorkSupplyInventoryRecord? get _previewInventoryRecord {
    final item = _inventoryItem;
    if (item == null) return null;
    final line = _pendingReceiptLine;
    if (line == null) return null;
    final threshold = _toDouble(_threshold.text, 1);
    return WorkSupplyInventoryRecord(
      item: item,
      onHand: line.totalUnits,
      threshold: threshold,
      lastUnitCost: line.unitCostWithTax,
      storageArea: line.storageArea,
      storageDetail: line.storageDetail,
      receiptLinked: _hasReceipt,
      jobNumber: widget.jobNumber,
      jobName: widget.jobName,
      packagesPurchased: line.quantity,
      unitsPerPackage: line.unitsPerPackage,
      purchaseType: line.purchaseType,
      lineSubtotal: line.subtotal,
      taxRate: line.taxRate,
      businessUse: line.businessUse,
      businessPercent: line.businessPercent,
      loggedAt: _loggedAt,
      sourceReceiptId: _intakeId,
      sourceReceiptLineId: _nextLineId,
      sourceMerchantName: _storeController.text.trim(),
    );
  }

  String get _nextLineId => '$_intakeId-L${_lineSequence + 1}';

  void _removeStagedLine(int index) {
    if (index < 0 || index >= _stagedReceiptLines.length) return;
    setState(() {
      final line = _stagedReceiptLines.removeAt(index);
      if (line.isInventory) {
        final recordIndex = stagedInventoryRecordIndexForLine(
          _stagedInventoryLines,
          line,
        );
        if (recordIndex != -1) _stagedInventoryLines.removeAt(recordIndex);
      }
      if (_stagedReceiptLines.isEmpty) {
        _parsedReceiptReview = null;
      }
    });
  }

  Future<void> _editStagedLine(int index) async {
    if (index < 0 || index >= _stagedReceiptLines.length) return;
    final line = _stagedReceiptLines[index];
    setState(() {
      _stagedReceiptLines.removeAt(index);
      if (line.isInventory) {
        final recordIndex = stagedInventoryRecordIndexForLine(
          _stagedInventoryLines,
          line,
        );
        if (recordIndex != -1) _stagedInventoryLines.removeAt(recordIndex);
      }
      if (_stagedReceiptLines.isEmpty) {
        _parsedReceiptReview = null;
      }
      _loadLineForEditing(line);
    });
    await _openLineEditor(
      line.isInventory
          ? _ItemEntryMode.newInventory
          : _ItemEntryMode.nonInventory,
    );
  }

  void _commitStagedReceipt() {
    final blockedCount = unconfirmedAssistedInventoryLineCount(
      _stagedReceiptLines,
    );
    if (blockedCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Confirm $blockedCount parsed inventory line${blockedCount == 1 ? '' : 's'} before updating inventory.',
          ),
        ),
      );
      return;
    }
    final inventoryRecords = inventoryRecordsReadyForCommit(
      lines: _stagedReceiptLines,
      records: _stagedInventoryLines,
    );
    Navigator.of(context).pop(
      WorkSupplyAddItemsResult(
        receiptId: _intakeId,
        hasReceipt: _hasReceipt,
        receiptDate: _loggedAt,
        merchantName: _storeController.text.trim(),
        merchantPhone: _phoneController.text.trim(),
        merchantAddress: [
          _streetController.text.trim(),
          _cityController.text.trim(),
          _stateController.text.trim(),
          _zipController.text.trim(),
        ].where((value) => value.isNotEmpty).join(', '),
        inventoryRecords: List<WorkSupplyInventoryRecord>.unmodifiable(
          inventoryRecords,
        ),
        lines: List<ReceiptLineDraft>.unmodifiable(_stagedReceiptLines),
      ),
    );
  }

  void _resetLineFormAfterStaging() {
    _lineSequence++;
    _selectedItem = null;
    _search.clear();
    _customItemName.clear();
    _customItemDescription.clear();
    _customCategory.clear();
    _customSystem.clear();
    _customItemType.clear();
    _customSize.clear();
    _typedCatalogSuggestion = null;
    _customCategorySelection = null;
    _customSystemSelection = null;
    _customItemTypeSelection = null;
    _customSizeSelection = null;
    _customItemId = _newUserItemId();
    _packages.text = '1';
    _unitsPerPackage.text = '1';
    _subtotal.clear();
    _taxRate.text = '0';
    _threshold.text = '1';
    _barcodeValue.clear();
    _barcodePackageLabel.clear();
    _activeLineRawReceiptText = '';
    _activeLineCatalogMatchConfidence = null;
    _activeLineCatalogMatchedTerms = const [];
    _activeLineParserConfidence = null;
    _activeLineParserReviewLabel = null;
    _activeLineParserReviewReason = null;
    _activeLineParserNeedsReview = false;
    _activeLineOriginalParsedDescription = '';
    _activeLineOriginalParsedInventoryItemId = '';
    _activeLineOriginalParsedInventoryPath = '';
    _activeLineReviewAction = 'manual';
    _applyLineBusinessUse(_LineBusinessUse.business);
    _itemEntryMode = null;
    if (widget.initialStorageArea == null) {
      _storageDetail.clear();
      if (AppStateScope.of(context).vehicles.length > 1) {
        _storageArea = _chooseInventoryDestinationLabel;
      }
    }
  }

  void _loadLineForEditing(ReceiptLineDraft line) {
    _selectedItem = null;
    _search.text = line.description;
    _customItemName.text = line.isInventory ? line.description : '';
    _customItemDescription.text = line.isInventory ? '' : line.description;
    _packages.text = _formatEditableNumber(line.quantity);
    _unitsPerPackage.text = _formatEditableNumber(line.unitsPerPackage);
    _subtotal.text = line.subtotal <= 0
        ? ''
        : _formatEditableNumber(line.subtotal);
    _taxRate.text = _formatEditableNumber(line.taxRate * 100);
    _storageArea = line.storageArea.isEmpty ? _storageArea : line.storageArea;
    _storageDetail.text = line.storageDetail;
    _nonInventoryExpenseCategory = line.expenseCategory.isEmpty
        ? _nonInventoryExpenseCategory
        : line.expenseCategory;
    _businessUse = switch (line.businessUse) {
      'personal' => _LineBusinessUse.personal,
      'split' => _LineBusinessUse.split,
      _ => _LineBusinessUse.business,
    };
    _businessPercent.text = _formatEditableNumber(line.businessPercent * 100);
    _activeLineRawReceiptText = line.rawReceiptText;
    _activeLineCatalogMatchConfidence = line.catalogMatchConfidence;
    _activeLineCatalogMatchedTerms = line.catalogMatchedTerms;
    _activeLineParserConfidence = line.parserConfidence;
    _activeLineParserReviewLabel = line.parserReviewLabel;
    _activeLineParserReviewReason = line.parserReviewReason;
    _activeLineParserNeedsReview = line.parserNeedsReview;
    _activeLineOriginalParsedDescription = line.originalParsedDescription;
    _activeLineOriginalParsedInventoryItemId =
        line.originalParsedInventoryItemId;
    _activeLineOriginalParsedInventoryPath = line.originalParsedInventoryPath;
    _activeLineReviewAction = line.reviewAction;
    _purchaseType = _purchaseTypeFromValue(line.purchaseType);
    _customUnit = line.unit.isEmpty ? _customUnit : line.unit;
    _itemEntryMode = line.isInventory
        ? _ItemEntryMode.newInventory
        : _ItemEntryMode.nonInventory;
  }

  String _formatEditableNumber(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  _PurchaseType _purchaseTypeFromValue(String value) {
    for (final type in _PurchaseType.values) {
      if (type.storageValue == value) return type;
    }
    return _PurchaseType.each;
  }

  WorkSupplyItem? get _inventoryItem {
    if (_itemEntryMode == _ItemEntryMode.catalogInventory) return _selectedItem;
    if (_itemEntryMode != _ItemEntryMode.newInventory) return null;
    final name = _customItemName.text.trim().isEmpty
        ? _generatedCustomItemName
        : _customItemName.text.trim();
    if (name.isEmpty) return null;
    if (!_hasValidInventoryItemDetails) return null;
    return WorkSupplyItem(
      id: _customItemId,
      name: name,
      trade: _customTrade,
      category: _resolvedCustomCategory.isEmpty
          ? 'Uncategorized'
          : _resolvedCustomCategory,
      system: _resolvedCustomSystem.isEmpty ? 'General' : _resolvedCustomSystem,
      itemType: _resolvedCustomItemType.isEmpty
          ? 'Manual item'
          : _resolvedCustomItemType,
      variant: _resolvedCustomSize,
      unit: _resolvedInventoryUnit,
      aliases: [
        name,
        _customItemDescription.text.trim(),
        _generatedCustomItemName,
      ].where((value) => value.isNotEmpty).toList(),
    );
  }

  Future<void> _savePackageAliasFor(WorkSupplyItem item) async {
    final barcode = _barcodeValue.text.trim();
    if (barcode.isEmpty) return;
    final aliasStore = await WorkSupplyItemIdentityStore.create();
    await aliasStore.linkBarcodeToItem(
      barcodeValue: barcode,
      barcodeFormat: _guessBarcodeFormat(barcode),
      item: item,
      packageLabel: _resolvedBarcodePackageLabel,
      purchaseType: _purchaseType.storageValue,
      unitsPerPackage: _purchaseType.asksUnitsPerContainer
          ? _toDouble(_unitsPerPackage.text, 1)
          : 1,
      unit: item.unit,
      merchantName: _storeController.text.trim(),
      source: _hasReceipt ? 'manualReceipt' : 'manualEntry',
    );
  }

  String get _resolvedBarcodePackageLabel {
    final custom = _barcodePackageLabel.text.trim();
    if (custom.isNotEmpty) return custom;
    if (_purchaseType.isEach) return 'Each';
    final count = _toDouble(_unitsPerPackage.text, 1);
    final countText = count == count.roundToDouble()
        ? count.toInt().toString()
        : count.toStringAsFixed(2);
    return '${_purchaseType.label} of $countText';
  }
}
