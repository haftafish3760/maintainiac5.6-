import 'dart:async';

import 'package:flutter/material.dart';

import '../../../shared/navigation/app_page_routes.dart';
import '../../../shared/state/app_state.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_screen_shell.dart';
import '../../../shared/widgets/receipt_capture/receipt_capture.dart';
import '../../../shared/widgets/receipt_form_sections.dart';
import '../../../shared/widgets/structural_border_label.dart';
import '../../../shared/receipts/receipt_line_models.dart';
import '../../dashboard/vehicle_profile_flow.dart';
import '../../dashboard/vehicle_profile_widgets.dart';
import '../../expenses/categories/expense_categories.dart';
import '../../expenses/data/expense_receipt_item_memory_store.dart';
import '../../expenses/data/expense_receipt_parser.dart';
import '../../expenses/data/expense_receipt_privacy_event_store.dart';
import '../data/work_supply_catalog.dart';
import '../data/work_supply_custom_catalog_store.dart';
import '../data/work_supply_item_identity_store.dart';
import '../data/work_supply_inventory_destination.dart';
import '../data/work_supply_models.dart';
import '../data/work_supply_parsed_receipt_bridge.dart';
import '../data/work_supply_parser_device_profile.dart';
import '../data/work_supply_receipt_staging.dart';
import '../data/work_supply_receipt_parser.dart';

part 'receipt_destination_section.dart';
part 'receipt_preview_section.dart';
part 'add_items_receipt_sections.dart';
part 'add_items_receipt_command_sections.dart';
part 'add_items_receipt_parser_actions.dart';
part 'add_items_picker_sections.dart';
part 'add_items_picker_choice_sections.dart';
part 'add_items_line_editor_sections.dart';
part 'add_items_line_editor_shell.dart';
part 'add_items_line_editor_shared_widgets.dart';
part 'add_items_business_use_sections.dart';
part 'add_items_line_choice_sections.dart';
part 'add_items_custom_inventory_sections.dart';
part 'add_items_custom_inventory_support.dart';
part 'add_items_manual_required_panel.dart';
part 'add_items_typed_catalog_suggestions.dart';
part 'add_items_catalog_path_bar.dart';
part 'add_items_catalog_tile_grid.dart';
part 'add_items_inventory_summary.dart';
part 'add_items_non_inventory_inline_form.dart';
part 'add_items_field_sections.dart';
part 'add_items_line_editor_actions.dart';
part 'add_items_receipt_actions.dart';
part 'add_items_receipt_values.dart';
part 'add_items_custom_path_actions.dart';
part 'add_items_screen_helpers.dart';

enum _ItemEntryMode { newInventory, catalogInventory, nonInventory }

enum _LineBusinessUse {
  business('business', 'Business', 'Company record'),
  personal('personal', 'Personal', 'Keep on receipt, not business stock'),
  split('split', 'Split', 'Part business, part personal');

  const _LineBusinessUse(this.storageValue, this.label, this.detail);

  final String storageValue;
  final String label;
  final String detail;
}

enum _PurchaseType {
  each('each', 'Each', 'Individual pieces', 'Quantity', 'Each'),
  package(
    'package',
    'Package',
    'Box, pack, or bundle',
    'Packages bought',
    'Items per package',
  ),
  roll(
    'roll',
    'Roll',
    'Wire, tubing, tape, or duct',
    'Rolls bought',
    'Items per roll',
  ),
  caseBox('case', 'Case', 'Cases or cartons', 'Cases bought', 'Items per case'),
  bag(
    'bag',
    'Bag',
    'Bags of mix, fasteners, or supplies',
    'Bags bought',
    'Items per bag',
  ),
  can(
    'can',
    'Can',
    'Paint, spray, adhesive, or chemical can',
    'Cans bought',
    'Items per can',
  ),
  gallon(
    'gallon',
    'Gallon',
    'Paint, herbicide, sealant, or liquid',
    'Gallons bought',
    'Items per gallon',
  ),
  quart(
    'quart',
    'Quart',
    'Small paint, primer, cleaner, or liquid',
    'Quarts bought',
    'Items per quart',
  ),
  ounce(
    'ounce',
    'Ounce',
    'Liquid, sealant, adhesive, or chemical',
    'Ounces bought',
    'Items per ounce',
  ),
  pound(
    'pound',
    'Pound',
    'Seed, mortar, fasteners, or bulk material',
    'Pounds bought',
    'Items per pound',
  ),
  foot(
    'foot',
    'Foot',
    'Cable, pipe, tubing, trim, or rolls',
    'Feet bought',
    'Items per foot',
  );

  const _PurchaseType(
    this.storageValue,
    this.label,
    this.detail,
    this.containerLabel,
    this.unitsLabel,
  );

  final String storageValue;
  final String label;
  final String detail;
  final String containerLabel;
  final String unitsLabel;

  bool get isEach => this == _PurchaseType.each;
  bool get asksUnitsPerContainer {
    return this == _PurchaseType.package ||
        this == _PurchaseType.roll ||
        this == _PurchaseType.caseBox ||
        this == _PurchaseType.bag ||
        this == _PurchaseType.can;
  }
}

class WorkSupplyAddItemsScreen extends StatefulWidget {
  const WorkSupplyAddItemsScreen({
    super.key,
    this.initialItem,
    this.initialStorageArea,
    this.jobNumber = '',
    this.jobName = '',
    this.customCatalogItems = const [],
  });

  final WorkSupplyItem? initialItem;
  final String? initialStorageArea;
  final String jobNumber;
  final String jobName;
  final List<WorkSupplyItem> customCatalogItems;

  @override
  State<WorkSupplyAddItemsScreen> createState() =>
      _WorkSupplyAddItemsScreenState();
}

class WorkSupplyAddItemsResult {
  const WorkSupplyAddItemsResult({
    required this.receiptId,
    required this.hasReceipt,
    required this.receiptDate,
    required this.merchantName,
    required this.merchantPhone,
    required this.merchantAddress,
    required this.inventoryRecords,
    required this.lines,
  });

  final String receiptId;
  final bool hasReceipt;
  final DateTime receiptDate;
  final String merchantName;
  final String merchantPhone;
  final String merchantAddress;
  final List<WorkSupplyInventoryRecord> inventoryRecords;
  final List<ReceiptLineDraft> lines;
}

class _ParsedMaterialsReceiptReviewSummary {
  const _ParsedMaterialsReceiptReviewSummary({
    required this.qualityLabel,
    required this.confidenceLabel,
    required this.needsReview,
    this.warning,
  });

  final String qualityLabel;
  final String confidenceLabel;
  final bool needsReview;
  final String? warning;
}

class _WorkSupplyAddItemsScreenState extends State<WorkSupplyAddItemsScreen> {
  _ItemEntryMode? _itemEntryMode;
  WorkSupplyItem? _selectedItem;
  final _search = TextEditingController();
  final _customItemName = TextEditingController();
  final _customItemDescription = TextEditingController();
  final _packages = TextEditingController(text: '1');
  final _unitsPerPackage = TextEditingController(text: '1');
  final _subtotal = TextEditingController();
  final _taxRate = TextEditingController(text: '0');
  final _threshold = TextEditingController(text: '1');
  final _businessPercent = TextEditingController(text: '100');
  final _barcodeValue = TextEditingController();
  final _barcodePackageLabel = TextEditingController();
  final _customDestination = TextEditingController();
  final _storageDetail = TextEditingController();
  final _customCategory = TextEditingController();
  final _customSystem = TextEditingController();
  final _customItemType = TextEditingController();
  final _customSize = TextEditingController();
  final _storeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _storeNotesController = TextEditingController();
  final _scrollController = ScrollController();
  final _lineEditorScrollController = ScrollController();
  final _searchFocus = FocusNode();
  final _receiptDetailsKey = GlobalKey();
  WorkSupplyItem? _typedCatalogSuggestion;
  late DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;
  var _hasReceipt = false;
  var _receiptInfoComplete = false;
  late String _storageArea =
      widget.initialStorageArea ?? workSupplyActiveVehicleInventoryLabel;
  var _customTrade = '';
  String? _customCategorySelection;
  String? _customSystemSelection;
  String? _customItemTypeSelection;
  String? _customSizeSelection;
  var _nonInventoryExpenseCategory = 'Materials';
  var _customUnit = 'each';
  var _businessUse = _LineBusinessUse.business;
  _PurchaseType _purchaseType = _PurchaseType.each;
  String _customItemId = _newUserItemId();
  final String _intakeId = 'WRS-${DateTime.now().microsecondsSinceEpoch}';
  var _lineSequence = 0;
  final List<ReceiptLineDraft> _stagedReceiptLines = [];
  final List<WorkSupplyInventoryRecord> _stagedInventoryLines = [];
  var _lastImportedReceiptText = '';
  var _activeLineRawReceiptText = '';
  double? _activeLineCatalogMatchConfidence;
  List<String> _activeLineCatalogMatchedTerms = const [];
  double? _activeLineParserConfidence;
  String? _activeLineParserReviewLabel;
  String? _activeLineParserReviewReason;
  var _activeLineParserNeedsReview = false;
  var _activeLineOriginalParsedDescription = '';
  var _activeLineOriginalParsedInventoryItemId = '';
  var _activeLineOriginalParsedInventoryPath = '';
  var _activeLineReviewAction = 'manual';
  _ParsedMaterialsReceiptReviewSummary? _parsedReceiptReview;
  WorkSupplyTrade? _trade;
  WorkSupplyCategory? _category;
  WorkSupplySystem? _system;
  WorkSupplyItemType? _itemType;

  @override
  void initState() {
    super.initState();
    _selectedItem = widget.initialItem;
    if (_selectedItem != null) {
      _itemEntryMode = _ItemEntryMode.catalogInventory;
      _search.text = _selectedItem!.name;
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _customItemName.dispose();
    _customItemDescription.dispose();
    _packages.dispose();
    _unitsPerPackage.dispose();
    _subtotal.dispose();
    _taxRate.dispose();
    _threshold.dispose();
    _businessPercent.dispose();
    _barcodeValue.dispose();
    _barcodePackageLabel.dispose();
    _customDestination.dispose();
    _storageDetail.dispose();
    _customCategory.dispose();
    _customSystem.dispose();
    _customItemType.dispose();
    _customSize.dispose();
    _storeController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _storeNotesController.dispose();
    _scrollController.dispose();
    _lineEditorScrollController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_canStepBack,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _canStepBack) _stepBack();
      },
      child: AppScreenShell(
        section: AppSection.materials,
        body: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 24),
          children: [
            const GlobalOdometerHeader(section: AppSection.materials),
            const SizedBox(height: 10),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _AddHeader(receiptInfoComplete: _receiptInfoComplete),
                      const SizedBox(height: 10),
                      if (!_receiptInfoComplete) ...[
                        KeyedSubtree(
                          key: _receiptDetailsKey,
                          child: _ReceiptSection(
                            selectedDate: _selectedDate,
                            selectedTime: _selectedTime,
                            hasReceipt: _hasReceipt,
                            showCamera: true,
                            store: _storeController,
                            phone: _phoneController,
                            street: _streetController,
                            city: _cityController,
                            state: _stateController,
                            zip: _zipController,
                            email: _emailController,
                            website: _websiteController,
                            storeNotes: _storeNotesController,
                            onSelectDate: _selectDate,
                            onSelectTime: _selectTime,
                            onClearTime: () =>
                                setState(() => _selectedTime = null),
                            onReceiptChanged: (value) =>
                                setState(() => _hasReceipt = value),
                            onImportedText: _parseImportedMaterialsReceiptText,
                            onStoreChanged: () => setState(() {}),
                          ),
                        ),
                        const SizedBox(height: 12),
                        AppButton(
                          label: 'Save And Continue',
                          tone: AppButtonTone.commit,
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                          ),
                          onPressed: _continueToReceiptLines,
                        ),
                      ] else ...[
                        _ReceiptEntryLanes(
                          nextLineNumber: _stagedReceiptLines.length + 1,
                          onReceiptDetails: _editReceiptInfo,
                          onInventoryLine: _openInventoryReceiptLine,
                          onBusinessLine: _openBusinessReceiptLine,
                          onPersonalLine: _openPersonalReceiptLine,
                          onSplitLine: _openSplitReceiptLine,
                        ),
                        const SizedBox(height: 12),
                        _InventoryReceiptPreview(
                          lines: _stagedReceiptLines,
                          currentLine: null,
                          parsedReview: _parsedReceiptReview,
                          onConfirmAll: _confirmAllParsedReceiptLines,
                          onConfirmLine: _confirmParsedReceiptLine,
                          onEdit: _editStagedLine,
                          onRemove: _removeStagedLine,
                        ),
                        if (_stagedReceiptLines.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: AppButton(
                                  label: 'Save Receipt',
                                  tone: AppButtonTone.commit,
                                  icon: const Icon(
                                    Icons.receipt_long_outlined,
                                    color: Colors.white,
                                  ),
                                  onPressed: _commitStagedReceipt,
                                ),
                              ),
                              const SizedBox(width: 8),
                              AppButton(
                                label: 'Edit Info',
                                compact: true,
                                icon: const Icon(
                                  Icons.edit_note_rounded,
                                  color: Colors.white,
                                ),
                                onPressed: _editReceiptInfo,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _continueToReceiptLines() {
    if (_hasReceipt && _storeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add the store name before continuing.')),
      );
      return;
    }
    setState(() => _receiptInfoComplete = true);
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  void _editReceiptInfo() {
    setState(() => _receiptInfoComplete = false);
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }
}
