import 'package:flutter/material.dart';

import '../../shared/navigation/app_page_routes.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_screen_shell.dart';
import '../../shared/receipts/receipt_line_models.dart';
import '../expenses/data/expense_receipt_item_memory_store.dart';
import 'data/work_supply_custom_catalog_store.dart';
import 'data/work_supply_inventory_receipt_models.dart';
import 'data/work_supply_inventory_receipt_store.dart';
import 'data/work_supply_inventory_settings_store.dart';
import 'data/work_supply_inventory_store.dart';
import 'data/work_supply_models.dart';
import 'data/work_supply_preloader.dart';
import 'home/work_supply_home_screen.dart';
import 'inventory/inventory_receipts_flow.dart';
import 'inventory/work_supply_inventory_screen.dart';
import 'jobs/work_supply_jobs_screen.dart';

class WorkSupplyScreen extends StatefulWidget {
  const WorkSupplyScreen({super.key});

  @override
  State<WorkSupplyScreen> createState() => _WorkSupplyScreenState();
}

class _WorkSupplyScreenState extends State<WorkSupplyScreen> {
  WorkSupplyInventoryStore? _store;
  WorkSupplyCustomCatalogStore? _customCatalogStore;
  WorkSupplyInventoryReceiptStore? _receiptStore;
  WorkSupplyInventorySettingsController? _settings;
  List<WorkSupplyInventoryRecord> _inventory = [];
  List<WorkSupplyInventoryTransaction> _transactions = [];
  List<WorkSupplyItem> _customCatalogItems = [];
  final List<_InventoryDraft> _drafts = [];
  String _query = '';
  DateTime _selectedInventoryDay = _dayKey(DateTime.now());
  var _loading = true;
  var _showIntro = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInventory());
  }

  @override
  Widget build(BuildContext context) {
    final lowCount = _inventory.where((record) => record.isRunningLow).length;
    return AppScreenShell(
      section: AppSection.materials,
      body: Column(
        children: [
          const GlobalOdometerHeader(section: AppSection.materials),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
              children: [
                if (_loading)
                  const _InventoryLoadingState()
                else
                  WorkSupplyHomeScreen(
                    query: _query,
                    inventoryRecords: _inventory,
                    draftCount: _drafts.length,
                    selectedCalendarDay: _selectedInventoryDay,
                    inventoryCount: _inventory.length,
                    lowCount: lowCount,
                    hasMessages: lowCount > 0,
                    showIntro: _showIntro,
                    onQueryChanged: (value) => setState(() => _query = value),
                    onAddItems: () => _openAddItems(),
                    onDismissIntro: _dismissIntro,
                    onResumeDraft: _resumeLatestDraft,
                    onReviewInventory: _openInventory,
                    onCalendarDaySelected: (day) =>
                        setState(() => _selectedInventoryDay = _dayKey(day)),
                    onOpenJobs: _openJobs,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadInventory() async {
    final resources = await loadWorkSupplyHomeResources();
    final settings = await WorkSupplyInventorySettingsController.create();
    if (!mounted) return;
    setState(() {
      _store = resources.inventoryStore;
      _settings = settings;
      _inventory = resources.inventoryRecords;
      _transactions = resources.inventoryTransactions;
      _showIntro = !settings.hasSeenWorkSupplyIntro;
      _loading = false;
    });
  }

  Future<void> _openAddItems({WorkSupplyItem? initialItem}) async {
    await _ensureCustomCatalogLoaded();
    if (!mounted) return;
    final result = await Navigator.of(context).push<WorkSupplyAddItemsResult>(
      appNativeRoute(
        context,
        WorkSupplyAddItemsScreen(
          initialItem: initialItem,
          customCatalogItems: _customCatalogItems,
        ),
      ),
    );
    if (result == null || result.lines.isEmpty) {
      _saveInterruptedDraft();
      return;
    }
    await _addReceiptResult(result);
  }

  Future<void> _resumeLatestDraft() async {
    if (_drafts.isEmpty) return;
    await _ensureCustomCatalogLoaded();
    if (!mounted) return;
    final result = await Navigator.of(context).push<WorkSupplyAddItemsResult>(
      appNativeRoute(
        context,
        WorkSupplyAddItemsScreen(customCatalogItems: _customCatalogItems),
      ),
    );
    if (result == null || result.lines.isEmpty) return;
    await _addReceiptResult(result);
    if (!mounted) return;
    setState(() {
      _drafts.removeLast();
    });
  }

  Future<void> _dismissIntro() async {
    setState(() => _showIntro = false);
    await _settings?.setHasSeenWorkSupplyIntro(true);
  }

  Future<void> _addReceiptResult(WorkSupplyAddItemsResult result) async {
    final store = _store;
    if (store == null) return;
    final savedRecords = <WorkSupplyInventoryRecord>[];
    for (final record in result.inventoryRecords) {
      if (record.item.id.startsWith('USER-')) {
        final customCatalogStore =
            _customCatalogStore ?? await WorkSupplyCustomCatalogStore.create();
        await customCatalogStore.saveItem(record.item);
        _customCatalogStore = customCatalogStore;
      }
      savedRecords.add(await store.addStock(record));
    }
    await _saveReceiptResult(result, savedRecords);
    final resources = await refreshWorkSupplyHomeResources();
    if (!mounted) return;
    setState(() {
      _inventory = resources.inventoryRecords;
      _transactions = resources.inventoryTransactions;
    });
  }

  Future<void> _saveReceiptResult(
    WorkSupplyAddItemsResult result,
    List<WorkSupplyInventoryRecord> savedRecords,
  ) async {
    final receiptStore =
        _receiptStore ?? await WorkSupplyInventoryReceiptStore.create();
    _receiptStore = receiptStore;
    final lines = <WorkSupplyInventoryReceiptLine>[];
    for (var index = 0; index < result.lines.length; index++) {
      final draft = result.lines[index];
      final savedRecord = draft.isInventory
          ? _savedRecordForDraft(draft, savedRecords)
          : null;
      final item = savedRecord?.item ?? _expenseReceiptItem(draft);
      lines.add(
        WorkSupplyInventoryReceiptLine(
          id: draft.receiptLineId.trim().isEmpty
              ? '${result.receiptId}-L${index + 1}'
              : draft.receiptLineId.trim(),
          item: item,
          displayName: draft.description,
          kind: _receiptLineKindForDraft(draft),
          rawReceiptText: draft.rawReceiptText.trim().isEmpty
              ? draft.description
              : draft.rawReceiptText,
          expenseCategory: draft.expenseCategory,
          quantity: draft.quantity,
          unitsPerPackage: draft.unitsPerPackage,
          purchaseType: draft.purchaseType,
          unit: draft.unit,
          subtotal: draft.subtotal,
          taxRate: draft.taxRate,
          storageArea: draft.storageArea,
          storageDetail: draft.storageDetail,
          inventoryRecordId: savedRecord?.id ?? '',
          businessUse: draft.businessUse,
          businessPercent: draft.businessPercent,
          confidence:
              draft.parserConfidence ?? draft.catalogMatchConfidence ?? 1,
          reviewStatus: draft.parserNeedsReview
              ? WorkSupplyLineReviewStatus.needsReview
              : WorkSupplyLineReviewStatus.confirmed,
          invoiceProofMode: WorkSupplyInvoiceProofMode.hidden,
          note: draft.note,
          originalParsedDescription: draft.originalParsedDescription,
          originalParsedInventoryItemId: draft.originalParsedInventoryItemId,
          originalParsedInventoryPath: draft.originalParsedInventoryPath,
          reviewAction: draft.reviewAction,
        ),
      );
    }
    await receiptStore.saveReceipt(
      WorkSupplyInventoryReceiptRecord(
        id: result.receiptId,
        source: result.hasReceipt
            ? WorkSupplyInventoryIntakeSource.manualWithReceipt
            : WorkSupplyInventoryIntakeSource.manualWithoutReceipt,
        merchantName: result.merchantName,
        merchantPhone: result.merchantPhone,
        merchantAddress: result.merchantAddress,
        receiptDate: result.receiptDate,
        lines: lines,
      ),
    );
    await _rememberMaterialsReceiptCorrections(result);
  }

  Future<void> _rememberMaterialsReceiptCorrections(
    WorkSupplyAddItemsResult result,
  ) async {
    if (result.merchantName.trim().isEmpty || result.lines.isEmpty) return;
    try {
      final memory = await ExpenseReceiptItemMemoryStore.create();
      await memory.rememberMaterialsReceiptLines(
        merchantName: result.merchantName,
        lines: result.lines.where(
          (line) =>
              line.hasAssistedReview &&
              (line.reviewState == ReceiptLineReviewState.confirmed ||
                  line.reviewState == ReceiptLineReviewState.corrected),
        ),
      );
    } catch (_) {
      return;
    }
  }

  WorkSupplyInventoryRecord? _savedRecordForDraft(
    ReceiptLineDraft draft,
    List<WorkSupplyInventoryRecord> savedRecords,
  ) {
    final lineId = draft.receiptLineId.trim();
    if (lineId.isNotEmpty) {
      for (final record in savedRecords) {
        if (record.sourceReceiptLineId == lineId) return record;
      }
    }
    for (final record in savedRecords) {
      if (record.item.id == draft.inventoryItemId) return record;
    }
    return null;
  }

  WorkSupplyReceiptLineKind _receiptLineKindForDraft(ReceiptLineDraft draft) {
    if (draft.isInventory) return WorkSupplyReceiptLineKind.inventory;
    if (draft.businessUse == 'personal') {
      return WorkSupplyReceiptLineKind.personal;
    }
    return WorkSupplyReceiptLineKind.businessExpense;
  }

  WorkSupplyItem _expenseReceiptItem(ReceiptLineDraft draft) {
    final category = draft.expenseCategory.trim().isEmpty
        ? 'Uncategorized'
        : draft.expenseCategory.trim();
    final personal = draft.businessUse == 'personal';
    return WorkSupplyItem(
      id: '',
      name: draft.description,
      trade: personal ? 'Personal' : 'Business Expense',
      category: category,
      system: 'Receipt',
      itemType: personal ? 'Personal line' : 'Expense line',
      variant: '',
      unit: draft.unit,
      aliases: [draft.description, category],
    );
  }

  void _saveInterruptedDraft() {
    setState(() {
      _drafts.add(
        _InventoryDraft(
          title: 'Inventory receipt draft',
          detail: 'Started ${TimeOfDay.now().format(context)}',
        ),
      );
    });
  }

  void _openInventory() {
    Navigator.of(context).push(
      appNativeRoute(
        context,
        WorkSupplyInventoryScreen(
          records: _inventory,
          transactions: _transactions,
          onAddItems: () => _openAddItems(),
          onAddItem: (item) => _openAddItems(initialItem: item),
          onRemove: _markOutOfStock,
        ),
      ),
    );
  }

  Future<void> _markOutOfStock(WorkSupplyInventoryRecord record) async {
    final store = _store;
    if (store == null) return;
    await store.markOutOfStock(record);
    final resources = await refreshWorkSupplyHomeResources();
    if (!mounted) return;
    setState(() {
      _inventory = resources.inventoryRecords;
      _transactions = resources.inventoryTransactions;
    });
  }

  Future<void> _ensureCustomCatalogLoaded() async {
    if (_customCatalogStore != null) return;
    final customCatalogStore = await WorkSupplyCustomCatalogStore.create();
    final customCatalogItems = customCatalogStore.loadItems();
    if (!mounted) return;
    setState(() {
      _customCatalogStore = customCatalogStore;
      _customCatalogItems = customCatalogItems;
    });
  }

  void _openJobs() {
    Navigator.of(
      context,
    ).push(appNativeRoute(context, const WorkSupplyJobsScreen()));
  }
}

class _InventoryDraft {
  const _InventoryDraft({required this.title, required this.detail});

  final String title;
  final String detail;
}

class _InventoryLoadingState extends StatelessWidget {
  const _InventoryLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 28),
      child: Center(child: CircularProgressIndicator(color: Color(0xFF58D67D))),
    );
  }
}

DateTime _dayKey(DateTime day) => DateTime.utc(day.year, day.month, day.day);

class WorkSupplyActionButton extends StatelessWidget {
  const WorkSupplyActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.tone = AppButtonTone.general,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final AppButtonTone tone;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: label,
      tone: tone,
      icon: Icon(icon, color: Colors.white, size: 18),
      onPressed: onPressed,
    );
  }
}
