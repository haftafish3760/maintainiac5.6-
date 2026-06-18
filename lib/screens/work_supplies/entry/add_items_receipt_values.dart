part of 'work_supply_add_items_screen.dart';

extension _WorkSupplyAddItemsReceiptValues on _WorkSupplyAddItemsScreenState {
  ReceiptLineDraft? get _pendingReceiptLine {
    final packages = _toDouble(_packages.text, 1);
    final unitsPerPackage = !_purchaseType.asksUnitsPerContainer
        ? 1.0
        : _toDouble(_unitsPerPackage.text, 1);
    final subtotal = _toDouble(_subtotal.text, 0);
    final taxPercent = _toDouble(_taxRate.text, 0);
    if (_itemEntryMode == _ItemEntryMode.nonInventory) {
      final description = _resolvedExpenseLineDescription;
      return ReceiptLineDraft(
        kind: ReceiptLineKind.expense,
        description: description,
        expenseCategory: _nonInventoryExpenseCategory,
        quantity: packages,
        unitsPerPackage: unitsPerPackage,
        purchaseType: _purchaseType.storageValue,
        unit: _customUnit,
        subtotal: subtotal,
        taxRate: taxPercent / 100,
        storageDetail: _storageDetail.text.trim(),
        businessUse: _effectiveBusinessUse.storageValue,
        businessPercent: _resolvedBusinessPercent,
        note: 'Created from Work Supplies receipt flow.',
      );
    }

    final item = _inventoryItem;
    if (item == null) return null;
    return ReceiptLineDraft(
      kind: ReceiptLineKind.inventory,
      description: item.name,
      inventoryItemId: item.id,
      inventoryPath: item.path,
      quantity: packages,
      unitsPerPackage: unitsPerPackage,
      purchaseType: _purchaseType.storageValue,
      unit: item.unit,
      subtotal: subtotal,
      taxRate: taxPercent / 100,
      storageArea: _resolvedStorageArea,
      storageDetail: _storageDetail.text.trim(),
      businessUse: _effectiveBusinessUse.storageValue,
      businessPercent: _resolvedBusinessPercent,
      note: item.variant,
    );
  }

  bool get _canSave {
    if (!_hasValidBusinessUse) return false;
    if (_itemEntryMode == _ItemEntryMode.nonInventory) {
      return true;
    }
    if (!_hasValidDestination) return false;
    if (_itemEntryMode == _ItemEntryMode.newInventory) {
      return _hasValidInventoryItemDetails && _inventoryItem != null;
    }
    if (_itemEntryMode == _ItemEntryMode.catalogInventory) {
      return _inventoryItem != null;
    }
    return false;
  }

  bool get _hasValidDestination {
    if (_storageArea == _chooseInventoryDestinationLabel) return false;
    if (_storageArea == workSupplyCustomDestinationLabel) {
      return _customDestination.text.trim().isNotEmpty;
    }
    return _storageArea.trim().isNotEmpty;
  }

  bool get _hasValidBusinessUse {
    if (_effectiveBusinessUse != _LineBusinessUse.split) return true;
    final percent = _toDouble(_businessPercent.text, -1);
    return percent > 0 && percent < 100;
  }

  bool get _hasValidInventoryItemDetails {
    return _customTrade.trim().isNotEmpty &&
        _resolvedCustomCategory.trim().isNotEmpty &&
        _resolvedCustomItemType.trim().isNotEmpty &&
        _resolvedCustomSystem.trim().isNotEmpty &&
        _resolvedCustomSize.trim().isNotEmpty;
  }

  _LineBusinessUse get _effectiveBusinessUse {
    return _businessUse;
  }

  double get _resolvedBusinessPercent {
    return switch (_effectiveBusinessUse) {
      _LineBusinessUse.business => 1,
      _LineBusinessUse.personal => 0,
      _LineBusinessUse.split => _toDouble(_businessPercent.text, 0) / 100,
    };
  }

  String get _resolvedExpenseLineDescription {
    final description = _customItemDescription.text.trim();
    if (description.isNotEmpty) return description;
    final name = _customItemName.text.trim();
    if (name.isNotEmpty) return name;
    final category = _nonInventoryExpenseCategory.trim();
    if (category.isNotEmpty) {
      return switch (_effectiveBusinessUse) {
        _LineBusinessUse.personal => 'Personal - $category',
        _LineBusinessUse.split => 'Split - $category',
        _LineBusinessUse.business => 'Business - $category',
      };
    }
    return switch (_effectiveBusinessUse) {
      _LineBusinessUse.personal => 'Personal',
      _LineBusinessUse.split => 'Split business/personal',
      _LineBusinessUse.business => 'Business',
    };
  }

  String get _generatedCustomItemName {
    return [
      _resolvedCustomSize,
      _resolvedCustomSystem,
      _resolvedCustomItemType.replaceAll(RegExp(r's$'), ''),
    ].where((value) => value.trim().isNotEmpty).join(' ').trim();
  }

  String get _resolvedCustomCategory {
    if (_customCategorySelection == _customAddCategoryLabel ||
        _customCategorySelection == null) {
      return _customCategory.text.trim();
    }
    if (_customCategorySelection == _chooseCategoryLabel) return '';
    return _customCategorySelection!;
  }

  String get _resolvedCustomSystem {
    if (_customSystemSelection == _customAddSystemLabel ||
        _customSystemSelection == null) {
      return _customSystem.text.trim();
    }
    if (_customSystemSelection == _chooseSystemLabel) return '';
    return _customSystemSelection!;
  }

  String get _resolvedCustomItemType {
    if (_customItemTypeSelection == _customAddItemTypeLabel ||
        _customItemTypeSelection == null) {
      return _customItemType.text.trim();
    }
    if (_customItemTypeSelection == _chooseItemTypeLabel) return '';
    return _customItemTypeSelection!;
  }

  String get _resolvedCustomSize {
    if (_customSizeSelection == _customAddSizeLabel ||
        _customSizeSelection == null) {
      return _customSize.text.trim();
    }
    if (_customSizeSelection == _chooseSizeLabel) return '';
    return _customSizeSelection!;
  }

  String get _resolvedInventoryUnit {
    if (_purchaseType.asksUnitsPerContainer) return _customUnit;
    return _purchaseType.storageValue;
  }
}
