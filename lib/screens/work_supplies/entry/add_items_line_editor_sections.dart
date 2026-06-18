part of 'work_supply_add_items_screen.dart';

class _LineItemForm extends StatelessWidget {
  const _LineItemForm({
    required this.receiptLineNumber,
    required this.entryMode,
    this.showLineChoices = true,
    required this.search,
    required this.customItemName,
    required this.customItemDescription,
    required this.customTrade,
    required this.customCategorySelection,
    required this.customSystemSelection,
    required this.customItemTypeSelection,
    required this.customSizeSelection,
    required this.customCategory,
    required this.customSystem,
    required this.customItemType,
    required this.customSize,
    required this.typedSuggestion,
    required this.nonInventoryExpenseCategory,
    required this.results,
    required this.selectedItem,
    required this.trade,
    required this.category,
    required this.system,
    required this.itemType,
    required this.searchFocus,
    required this.packages,
    required this.unitsPerPackage,
    required this.subtotal,
    required this.taxRate,
    required this.threshold,
    required this.businessUse,
    required this.businessPercent,
    required this.barcodeValue,
    required this.barcodePackageLabel,
    required this.showBusinessUsePicker,
    required this.storageArea,
    required this.customDestination,
    required this.storageDetail,
    required this.destinationChoices,
    required this.showDestinationPicker,
    required this.purchaseType,
    required this.onEntryMode,
    required this.onSearchChanged,
    required this.onCustomItemChanged,
    required this.onCustomTrade,
    required this.onCustomCategory,
    required this.onCustomSystem,
    required this.onCustomItemType,
    required this.onCustomSize,
    required this.onApplyTypedSuggestion,
    required this.onApplyCatalogSuggestion,
    required this.onNonInventoryExpenseCategory,
    required this.onMathChanged,
    required this.onStorageDetailChanged,
    required this.onBusinessUse,
    required this.onBusinessPercentChanged,
    required this.onBarcodeChanged,
    required this.onPurchaseType,
    required this.onStorageArea,
    required this.onAddVehicle,
    required this.onTrade,
    required this.onCategory,
    required this.onSystem,
    required this.onItemType,
    required this.onBack,
    required this.onItemSelected,
  });

  final int receiptLineNumber;
  final _ItemEntryMode? entryMode;
  final bool showLineChoices;
  final TextEditingController search;
  final TextEditingController customItemName;
  final TextEditingController customItemDescription;
  final String customTrade;
  final String? customCategorySelection;
  final String? customSystemSelection;
  final String? customItemTypeSelection;
  final String? customSizeSelection;
  final TextEditingController customCategory;
  final TextEditingController customSystem;
  final TextEditingController customItemType;
  final TextEditingController customSize;
  final WorkSupplyItem? typedSuggestion;
  final String nonInventoryExpenseCategory;
  final List<WorkSupplyItem> results;
  final WorkSupplyItem? selectedItem;
  final WorkSupplyTrade? trade;
  final WorkSupplyCategory? category;
  final WorkSupplySystem? system;
  final WorkSupplyItemType? itemType;
  final FocusNode searchFocus;
  final TextEditingController packages;
  final TextEditingController unitsPerPackage;
  final TextEditingController subtotal;
  final TextEditingController taxRate;
  final TextEditingController threshold;
  final _LineBusinessUse businessUse;
  final TextEditingController businessPercent;
  final TextEditingController barcodeValue;
  final TextEditingController barcodePackageLabel;
  final bool showBusinessUsePicker;
  final String storageArea;
  final TextEditingController customDestination;
  final TextEditingController storageDetail;
  final List<String> destinationChoices;
  final bool showDestinationPicker;
  final _PurchaseType purchaseType;
  final ValueChanged<_ItemEntryMode> onEntryMode;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onCustomItemChanged;
  final ValueChanged<String> onCustomTrade;
  final ValueChanged<String?> onCustomCategory;
  final ValueChanged<String?> onCustomSystem;
  final ValueChanged<String?> onCustomItemType;
  final ValueChanged<String?> onCustomSize;
  final VoidCallback onApplyTypedSuggestion;
  final ValueChanged<WorkSupplyItem> onApplyCatalogSuggestion;
  final ValueChanged<String> onNonInventoryExpenseCategory;
  final ValueChanged<String> onMathChanged;
  final ValueChanged<String> onStorageDetailChanged;
  final ValueChanged<_LineBusinessUse> onBusinessUse;
  final ValueChanged<String> onBusinessPercentChanged;
  final ValueChanged<String> onBarcodeChanged;
  final ValueChanged<_PurchaseType> onPurchaseType;
  final ValueChanged<String> onStorageArea;
  final VoidCallback onAddVehicle;
  final ValueChanged<WorkSupplyTrade> onTrade;
  final ValueChanged<WorkSupplyCategory> onCategory;
  final ValueChanged<WorkSupplySystem> onSystem;
  final ValueChanged<WorkSupplyItemType> onItemType;
  final VoidCallback onBack;
  final ValueChanged<WorkSupplyItem> onItemSelected;

  @override
  Widget build(BuildContext context) {
    final resolvedCustomCategory =
        customCategorySelection == _customAddCategoryLabel
        ? customCategory.text.trim()
        : customCategorySelection ?? '';
    final resolvedCustomSystem = customSystemSelection == _customAddSystemLabel
        ? customSystem.text.trim()
        : customSystemSelection ?? '';
    final resolvedCustomItemType =
        customItemTypeSelection == _customAddItemTypeLabel
        ? customItemType.text.trim()
        : customItemTypeSelection ?? '';
    final resolvedCustomSize = customSizeSelection == _customAddSizeLabel
        ? customSize.text.trim()
        : customSizeSelection ?? '';
    final customItemReady =
        customTrade.trim().isNotEmpty &&
        resolvedCustomCategory.trim().isNotEmpty &&
        resolvedCustomSystem.trim().isNotEmpty &&
        resolvedCustomItemType.trim().isNotEmpty &&
        resolvedCustomSize.trim().isNotEmpty;
    final destinationReady =
        !showDestinationPicker ||
        storageArea != _chooseInventoryDestinationLabel;
    final purchaseReady =
        packages.text.trim().isNotEmpty && subtotal.text.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showLineChoices) ...[
          const _ReceiptItemHelper(),
          const SizedBox(height: 10),
          _LineItemTypeButtons(selected: entryMode, onSelected: onEntryMode),
          if (entryMode == null) const _LineChoicePrompt(),
          const SizedBox(height: 10),
        ],
        if (entryMode != null && showBusinessUsePicker) ...[
          _LineEditorSection(
            color: const Color(0xFF263D4D),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _InlineSectionHeader(
                  icon: Icons.work_outline_rounded,
                  title: 'Business use',
                  detail: 'Choose how this receipt line should count.',
                ),
                const SizedBox(height: 10),
                _BusinessUsePicker(
                  selected: businessUse,
                  businessPercent: businessPercent,
                  onSelected: onBusinessUse,
                  onPercentChanged: onBusinessPercentChanged,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (entryMode != null &&
            showDestinationPicker &&
            !destinationReady) ...[
          _LineEditorSection(
            color: const Color(0xFF233A49),
            child: _InventoryDestinationPicker(
              selected: storageArea,
              customDestination: customDestination,
              storageDetail: storageDetail,
              choices: destinationChoices,
              onSelected: onStorageArea,
              onChanged: onMathChanged,
              onStorageDetailChanged: onStorageDetailChanged,
              onAddVehicle: onAddVehicle,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (entryMode == _ItemEntryMode.newInventory && destinationReady) ...[
          _LineEditorSection(
            color: const Color(0xFF2E3531),
            child: customItemReady
                ? _InventoryItemDetailsSummary(
                    complete: customItemReady,
                    itemName: customItemName.text.trim(),
                    trade: customTrade,
                    category: resolvedCustomCategory,
                    system: resolvedCustomSystem,
                    itemType: resolvedCustomItemType,
                    size: resolvedCustomSize,
                    onEdit: () => onCustomSize(_chooseSizeLabel),
                  )
                : _CustomInventoryItemForm(
                    receiptLineNumber: receiptLineNumber,
                    name: customItemName,
                    description: customItemDescription,
                    trade: customTrade,
                    categorySelection: customCategorySelection,
                    systemSelection: customSystemSelection,
                    itemTypeSelection: customItemTypeSelection,
                    sizeSelection: customSizeSelection,
                    customCategory: customCategory,
                    customSystem: customSystem,
                    customItemType: customItemType,
                    customSize: customSize,
                    typedSuggestion: typedSuggestion,
                    onChanged: onCustomItemChanged,
                    onApplyTypedSuggestion: onApplyTypedSuggestion,
                    onApplyCatalogSuggestion: onApplyCatalogSuggestion,
                    onTrade: onCustomTrade,
                    onCategory: onCustomCategory,
                    onSystem: onCustomSystem,
                    onItemType: onCustomItemType,
                    onSize: onCustomSize,
                  ),
          ),
          const SizedBox(height: 12),
        ] else if (entryMode == _ItemEntryMode.catalogInventory &&
            destinationReady) ...[
          _LineEditorSection(
            color: const Color(0xFF2D3B2F),
            child: selectedItem == null
                ? _ItemPicker(
                    search: search,
                    results: results,
                    selectedItem: selectedItem,
                    trade: trade,
                    category: category,
                    system: system,
                    itemType: itemType,
                    searchFocus: searchFocus,
                    onSearchChanged: onSearchChanged,
                    onTrade: onTrade,
                    onCategory: onCategory,
                    onSystem: onSystem,
                    onItemType: onItemType,
                    onBack: onBack,
                    onItemSelected: onItemSelected,
                  )
                : _InventoryItemDetailsSummary(
                    complete: true,
                    itemName: selectedItem!.name,
                    trade: selectedItem!.trade,
                    category: selectedItem!.category,
                    system: selectedItem!.system,
                    itemType: selectedItem!.itemType,
                    size: selectedItem!.variant,
                    onEdit: onBack,
                  ),
          ),
          const SizedBox(height: 12),
        ] else if (entryMode == _ItemEntryMode.nonInventory) ...[
          _LineEditorSection(
            color: const Color(0xFF3F321E),
            child: _NonInventoryInlineForm(
              description: customItemDescription,
              expenseCategory: nonInventoryExpenseCategory,
              onExpenseCategory: onNonInventoryExpenseCategory,
              onChanged: onCustomItemChanged,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (entryMode != null &&
            destinationReady &&
            (entryMode == _ItemEntryMode.nonInventory ||
                customItemReady ||
                selectedItem != null)) ...[
          _LineEditorSection(
            color: const Color(0xFF2A2E35),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _InlineSectionHeader(
                  icon: Icons.calculate_outlined,
                  title: 'Purchase information',
                  detail: 'Enter the quantity and cost from this receipt line.',
                ),
                const SizedBox(height: 10),
                _PurchaseTypePicker(
                  selected: purchaseType,
                  onSelected: onPurchaseType,
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(
                      child: _Field(
                        controller: packages,
                        label: purchaseType.containerLabel,
                        hint: purchaseType.isEach
                            ? 'How many pieces?'
                            : 'How many did you buy?',
                        keyboardType: TextInputType.number,
                        onChanged: onMathChanged,
                      ),
                    ),
                    if (purchaseType.asksUnitsPerContainer) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: _Field(
                          controller: unitsPerPackage,
                          label: purchaseType.unitsLabel,
                          hint: 'Pieces, ft, or count',
                          keyboardType: TextInputType.number,
                          onChanged: onMathChanged,
                        ),
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: _Field(
                        controller: subtotal,
                        label: 'Total paid before tax',
                        hint: 'Optional without receipt',
                        keyboardType: TextInputType.number,
                        onChanged: onMathChanged,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _Field(
                        controller: taxRate,
                        label: 'Tax %',
                        hint: 'Optional',
                        keyboardType: TextInputType.number,
                        onChanged: onMathChanged,
                      ),
                    ),
                  ],
                ),
                _PurchaseMathPreview(
                  purchaseType: purchaseType,
                  packages: packages,
                  unitsPerPackage: unitsPerPackage,
                  subtotal: subtotal,
                  taxRate: taxRate,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (entryMode != null &&
            destinationReady &&
            purchaseReady &&
            entryMode != _ItemEntryMode.nonInventory) ...[
          _LineEditorSection(
            color: const Color(0xFF3B2F1D),
            child: _PackageIdentityPanel(
              barcodeValue: barcodeValue,
              packageLabel: barcodePackageLabel,
              purchaseType: purchaseType,
              unitsPerPackage: unitsPerPackage,
              onChanged: onBarcodeChanged,
            ),
          ),
          const SizedBox(height: 12),
          _LineEditorSection(
            color: const Color(0xFF342E25),
            child: _Field(
              controller: threshold,
              label: 'Reminder threshold',
              hint: 'Optional: notify when on-hand count reaches this number',
              keyboardType: TextInputType.number,
              onChanged: onMathChanged,
            ),
          ),
        ],
      ],
    );
  }
}
