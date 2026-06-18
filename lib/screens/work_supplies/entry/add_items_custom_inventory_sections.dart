part of 'work_supply_add_items_screen.dart';

class _CustomInventoryItemForm extends StatelessWidget {
  const _CustomInventoryItemForm({
    required this.receiptLineNumber,
    required this.name,
    required this.description,
    required this.trade,
    required this.categorySelection,
    required this.systemSelection,
    required this.itemTypeSelection,
    required this.sizeSelection,
    required this.customCategory,
    required this.customSystem,
    required this.customItemType,
    required this.customSize,
    required this.typedSuggestion,
    required this.onChanged,
    required this.onApplyTypedSuggestion,
    required this.onApplyCatalogSuggestion,
    required this.onTrade,
    required this.onCategory,
    required this.onSystem,
    required this.onItemType,
    required this.onSize,
  });

  final int receiptLineNumber;
  final TextEditingController name;
  final TextEditingController description;
  final String trade;
  final String? categorySelection;
  final String? systemSelection;
  final String? itemTypeSelection;
  final String? sizeSelection;
  final TextEditingController customCategory;
  final TextEditingController customSystem;
  final TextEditingController customItemType;
  final TextEditingController customSize;
  final WorkSupplyItem? typedSuggestion;
  final ValueChanged<String> onChanged;
  final VoidCallback onApplyTypedSuggestion;
  final ValueChanged<WorkSupplyItem> onApplyCatalogSuggestion;
  final ValueChanged<String> onTrade;
  final ValueChanged<String?> onCategory;
  final ValueChanged<String?> onSystem;
  final ValueChanged<String?> onItemType;
  final ValueChanged<String?> onSize;

  @override
  Widget build(BuildContext context) {
    final tradeOptions = [
      _chooseTradeLabel,
      for (final trade in workSupplyTrades) trade.name,
    ];
    final tradeValue = _safePathValue(trade, tradeOptions, _chooseTradeLabel);
    final selectedTrade = tradeValue == _chooseTradeLabel
        ? null
        : _tradeByName(tradeValue);
    final categories =
        selectedTrade?.categories ?? const <WorkSupplyCategory>[];
    final selectedCategory = _categoryByName(categories, categorySelection);
    final systems = selectedCategory?.systems ?? const <WorkSupplySystem>[];
    final itemTypeOptions = [
      _chooseItemTypeLabel,
      ..._itemTypeNamesForSystems(systems),
      _customAddItemTypeLabel,
    ];
    final categoryOptions = [
      _chooseCategoryLabel,
      for (final category in categories) category.name,
      _customAddCategoryLabel,
    ];
    final itemTypeValue = _safePathValue(
      itemTypeSelection,
      itemTypeOptions,
      _chooseItemTypeLabel,
    );
    final materialSystems = _systemsForItemType(systems, itemTypeValue);
    final systemOptions = [
      _chooseSystemLabel,
      for (final system in materialSystems) system.name,
      _customAddSystemLabel,
    ];
    final categoryValue = _safePathValue(
      categorySelection,
      categoryOptions,
      _chooseCategoryLabel,
    );
    final systemValue = _safePathValue(
      systemSelection,
      systemOptions,
      _chooseSystemLabel,
    );
    final sizeOptions = [
      _chooseSizeLabel,
      ..._variantNamesForSelection(
        systems: materialSystems,
        systemName: systemValue,
        itemTypeName: itemTypeValue,
      ),
      _customAddSizeLabel,
    ];
    final sizeValue = _safePathValue(
      sizeSelection,
      sizeOptions,
      _chooseSizeLabel,
    );
    final resolvedCategory = categoryValue == _customAddCategoryLabel
        ? customCategory.text.trim()
        : categoryValue == _chooseCategoryLabel
        ? ''
        : categoryValue;
    final resolvedItemType = itemTypeValue == _customAddItemTypeLabel
        ? customItemType.text.trim()
        : itemTypeValue == _chooseItemTypeLabel
        ? ''
        : itemTypeValue;
    final resolvedSystem = systemValue == _customAddSystemLabel
        ? customSystem.text.trim()
        : systemValue == _chooseSystemLabel
        ? ''
        : systemValue;
    final resolvedSize = sizeValue == _customAddSizeLabel
        ? customSize.text.trim()
        : sizeValue == _chooseSizeLabel
        ? ''
        : sizeValue;
    final tradeReady = selectedTrade != null;
    final categoryReady = tradeReady && resolvedCategory.isNotEmpty;
    final itemTypeReady = categoryReady && resolvedItemType.isNotEmpty;
    final systemReady = itemTypeReady && resolvedSystem.isNotEmpty;
    final sizeReady = systemReady && resolvedSize.isNotEmpty;
    final generatedName = [
      resolvedSize,
      resolvedSystem,
      resolvedItemType.replaceAll(RegExp(r's$'), ''),
    ].where((value) => value.trim().isNotEmpty).join(' ').trim();
    final query = [
      name.text.trim(),
      description.text.trim(),
    ].where((value) => value.isNotEmpty).join(' ');
    final suggestions = query.length < 3
        ? const <WorkSupplyItem>[]
        : searchWorkSupplies(query).take(8).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ManualInventoryRequiredPanel(
          name: name,
          description: description,
          generatedName: generatedName,
          typedSuggestion: typedSuggestion,
          suggestions: suggestions,
          onChanged: onChanged,
          onApplyTypedSuggestion: onApplyTypedSuggestion,
          onApplyCatalogSuggestion: onApplyCatalogSuggestion,
        ),
        _CatalogWizardPathBar(
          trade: tradeReady ? tradeValue : '',
          category: resolvedCategory,
          itemType: resolvedItemType,
          system: resolvedSystem,
          size: resolvedSize,
          onTrade: tradeReady ? () => onTrade(_chooseTradeLabel) : null,
          onCategory: categoryReady
              ? () => onCategory(_chooseCategoryLabel)
              : null,
          onItemType: itemTypeReady
              ? () => onItemType(_chooseItemTypeLabel)
              : null,
          onSystem: systemReady ? () => onSystem(_chooseSystemLabel) : null,
          onSize: sizeReady ? () => onSize(_chooseSizeLabel) : null,
        ),
        if (!tradeReady)
          _CatalogWizardTileGrid(
            title: 'Choose a trade',
            detail: 'Pick the trade this receipt item belongs to.',
            choices: [
              for (final trade in workSupplyTrades)
                _CatalogWizardChoice(
                  label: trade.name,
                  detail: '${_countTradeItems(trade)} catalog items',
                  color: _receiptTradeColor(trade.name),
                  imageAsset: _receiptTradeIconAsset(trade.name),
                  onTap: () => onTrade(trade.name),
                ),
            ],
          )
        else if (!categoryReady)
          _CatalogWizardTileGrid(
            title: 'Choose a $tradeValue category',
            detail: 'Pick the closest category for this item.',
            choices: [
              for (final category in categories)
                _CatalogWizardChoice(
                  label: category.name,
                  detail: '${_countCategoryItems(category)} catalog items',
                  color: _receiptTradeColor(tradeValue),
                  onTap: () => onCategory(category.name),
                ),
              _CatalogWizardChoice(
                label: _customAddCategoryLabel,
                detail: 'Create a category for this item',
                color: const Color(0xFFFFC46B),
                onTap: () => onCategory(_customAddCategoryLabel),
              ),
            ],
            customField: categoryValue == _customAddCategoryLabel
                ? _Field(
                    controller: customCategory,
                    label: 'New category name',
                    hint: 'Example: Fittings, Paint, Irrigation, Fasteners',
                    onChanged: onChanged,
                  )
                : null,
          )
        else if (!itemTypeReady)
          _CatalogWizardTileGrid(
            title: 'Choose the item type',
            detail: 'Pick the field name a tradesperson would use.',
            choices: [
              for (final itemType in itemTypeOptions)
                if (itemType != _chooseItemTypeLabel)
                  _CatalogWizardChoice(
                    label: itemType,
                    detail: itemType == _customAddItemTypeLabel
                        ? 'Create a new item type'
                        : 'Available in this category',
                    color: itemType == _customAddItemTypeLabel
                        ? const Color(0xFFFFC46B)
                        : _receiptTradeColor(tradeValue),
                    onTap: () => onItemType(itemType),
                  ),
            ],
            customField: itemTypeValue == _customAddItemTypeLabel
                ? _Field(
                    controller: customItemType,
                    label: 'Custom item type',
                    hint: 'Example: Tee, 90, Angle Valve, Supply Line',
                    onChanged: onChanged,
                  )
                : null,
          )
        else if (!systemReady)
          _CatalogWizardTileGrid(
            title: 'Choose the material',
            detail: 'Pick what this item is made of or belongs to.',
            choices: [
              for (final system in systemOptions)
                if (system != _chooseSystemLabel)
                  _CatalogWizardChoice(
                    label: system,
                    detail: system == _customAddSystemLabel
                        ? 'Create a new material'
                        : 'Material or item family',
                    color: system == _customAddSystemLabel
                        ? const Color(0xFFFFC46B)
                        : _receiptTradeColor(tradeValue),
                    onTap: () => onSystem(system),
                  ),
            ],
            customField: systemValue == _customAddSystemLabel
                ? _Field(
                    controller: customSystem,
                    label: 'Custom material',
                    hint: 'Example: Copper, PVC, CPVC, PEX, Brass',
                    onChanged: onChanged,
                  )
                : null,
          )
        else if (!sizeReady)
          _CatalogWizardTileGrid(
            title: 'Choose the size',
            detail: 'Pick the size printed on the receipt or package.',
            choices: [
              for (final size in sizeOptions)
                if (size != _chooseSizeLabel)
                  _CatalogWizardChoice(
                    label: size,
                    detail: size == _customAddSizeLabel
                        ? 'Enter the printed size'
                        : '$resolvedSystem $resolvedItemType',
                    color: size == _customAddSizeLabel
                        ? const Color(0xFFFFC46B)
                        : _receiptTradeColor(tradeValue),
                    onTap: () => onSize(size),
                  ),
            ],
            customField: sizeValue == _customAddSizeLabel
                ? _Field(
                    controller: customSize,
                    label: 'Custom size',
                    hint: 'Example: 3/4 x 1/2 x 3/4 in',
                    onChanged: onChanged,
                  )
                : null,
          ),
        if (sizeReady)
          _PathHint(
            trade: tradeValue,
            category: resolvedCategory,
            system: resolvedSystem,
            itemType: resolvedItemType,
            size: resolvedSize,
          ),
      ],
    );
  }
}
