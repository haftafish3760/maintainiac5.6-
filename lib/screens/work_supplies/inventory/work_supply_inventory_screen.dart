import 'package:flutter/material.dart';

import '../../../shared/state/app_state.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_screen_shell.dart';
import '../data/work_supply_inventory_destination.dart';
import '../data/work_supply_models.dart';

part 'inventory_filter_controls.dart';
part 'inventory_flow_sections.dart';
part 'inventory_helpers.dart';
part 'inventory_record_sheet.dart';
part 'inventory_stock_rows.dart';

enum _InventoryReviewMode { current, previous }

class WorkSupplyInventoryScreen extends StatefulWidget {
  const WorkSupplyInventoryScreen({
    super.key,
    required this.records,
    required this.transactions,
    required this.onAddItems,
    required this.onAddItem,
    required this.onRemove,
  });

  final List<WorkSupplyInventoryRecord> records;
  final List<WorkSupplyInventoryTransaction> transactions;
  final VoidCallback onAddItems;
  final ValueChanged<WorkSupplyItem> onAddItem;
  final ValueChanged<WorkSupplyInventoryRecord> onRemove;

  @override
  State<WorkSupplyInventoryScreen> createState() =>
      _WorkSupplyInventoryScreenState();
}

class _WorkSupplyInventoryScreenState extends State<WorkSupplyInventoryScreen> {
  final _search = TextEditingController();
  String? _trade;
  String? _category;
  String? _system;
  var _mode = _InventoryReviewMode.current;
  WorkSupplyInventoryRecord? _selectedRecord;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final activeRecords = _scopedRecords(appState);
    final companyRecords = widget.records;
    final previousItems = _previouslyPurchasedItems;
    final searching = _search.text.trim().isNotEmpty;
    return PopScope(
      canPop: !_canGoBack,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _canGoBack) _goBackOneLevel();
      },
      child: AppScreenShell(
        section: AppSection.materials,
        body: Column(
          children: [
            const GlobalOdometerHeader(section: AppSection.materials),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                children: [
                  _InventorySearchActionRow(
                    controller: _search,
                    canGoBack: _canGoBack,
                    onBack: _goBackOneLevel,
                    onAddItems: widget.onAddItems,
                    onChanged: (_) => setState(() => _selectedRecord = null),
                  ),
                  const SizedBox(height: 10),
                  _InventoryModeToggle(
                    selected: _mode,
                    currentCount: _uniqueInventoryRecords(
                      companyRecords,
                    ).length,
                    previousCount: previousItems.length,
                    onSelected: (mode) => setState(() {
                      _mode = mode;
                      _trade = null;
                      _category = null;
                      _system = null;
                      _selectedRecord = null;
                    }),
                  ),
                  const SizedBox(height: 10),
                  if (_mode == _InventoryReviewMode.previous)
                    _PreviouslyPurchasedView(
                      items: _visiblePreviousItems(previousItems),
                      selectedTrade: _trade,
                      selectedCategory: _category,
                      onTrade: (value) => setState(() {
                        _trade = value;
                        _category = null;
                      }),
                      onCategory: (value) => setState(() => _category = value),
                      onAddItem: widget.onAddItem,
                    )
                  else if (searching)
                    _CompactInventoryGrid(
                      records: _visibleRecords(companyRecords),
                      activeRecords: activeRecords,
                      selected: _selectedRecord,
                      emptyMessage: 'No matching inventory items.',
                      onSelected: _openRecordDetail,
                    )
                  else
                    _CurrentInventoryFlow(
                      trade: _trade,
                      category: _category,
                      system: _system,
                      companyRecords: companyRecords,
                      activeRecords: activeRecords,
                      selectedRecord: _selectedRecord,
                      onTrade: (value) => setState(() {
                        _trade = value;
                        _category = null;
                        _system = null;
                        _selectedRecord = null;
                      }),
                      onCategory: (value) => setState(() {
                        _category = value;
                        _system = null;
                        _selectedRecord = null;
                      }),
                      onSystem: (value) => setState(() {
                        _system = value;
                        _selectedRecord = null;
                      }),
                      onChangeTrade: () => setState(() {
                        _trade = null;
                        _category = null;
                        _system = null;
                        _selectedRecord = null;
                      }),
                      onChangeCategory: () => setState(() {
                        _category = null;
                        _system = null;
                        _selectedRecord = null;
                      }),
                      onRecord: _openRecordDetail,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<WorkSupplyInventoryRecord> _scopedRecords(AppStateController appState) {
    final activeVehicle = appState.activeVehicle?.nickname.trim();
    final activeVehicleLabel = activeVehicle == null || activeVehicle.isEmpty
        ? ''
        : '$activeVehicle inventory';
    return widget.records.where((record) {
      return record.storageArea == workSupplyActiveVehicleInventoryLabel ||
          (activeVehicleLabel.isNotEmpty &&
              record.storageArea == activeVehicleLabel);
    }).toList();
  }

  List<WorkSupplyInventoryRecord> _visibleRecords(
    List<WorkSupplyInventoryRecord> records,
  ) {
    final query = _search.text.trim().toLowerCase();
    final visible = records.where((record) {
      if (query.isEmpty) return true;
      return record.item.searchableText.contains(query) ||
          record.item.name.toLowerCase().contains(query) ||
          record.storageDetail.toLowerCase().contains(query);
    }).toList();
    return visible..sort((a, b) => a.item.name.compareTo(b.item.name));
  }

  bool get _canGoBack => _system != null || _category != null || _trade != null;

  void _goBackOneLevel() {
    setState(() {
      if (_system != null) {
        _system = null;
      } else if (_category != null) {
        _category = null;
      } else {
        _trade = null;
      }
      _selectedRecord = null;
    });
  }

  void _openRecordDetail(WorkSupplyInventoryRecord record) {
    setState(() => _selectedRecord = record);
    final appState = AppStateScope.of(context);
    final relatedRecords = _relatedRecords(record);
    final relatedActiveRecords = relatedRecords
        .where((candidate) => _isActiveVehicleRecord(candidate, appState))
        .toList();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFE1E5E7),
      barrierColor: Colors.black.withValues(alpha: .45),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _InventoryRecordSheet(
        record: record,
        relatedRecords: relatedRecords,
        recentTransactions: _recentTransactionsFor(record.item),
        activeVehicleName: _activeVehicleInventoryLabel(appState),
        activeVehicleQuantity: _totalUnits(relatedActiveRecords),
        onAddMore: () {
          Navigator.of(context).pop();
          widget.onAddItem(record.item);
        },
        onRemove: () {
          Navigator.of(context).pop();
          widget.onRemove(record);
        },
      ),
    );
  }

  bool _isActiveVehicleRecord(
    WorkSupplyInventoryRecord record,
    AppStateController appState,
  ) {
    final activeVehicle = appState.activeVehicle?.nickname.trim();
    final activeVehicleLabel = activeVehicle == null || activeVehicle.isEmpty
        ? ''
        : '$activeVehicle inventory';
    return record.storageArea == workSupplyActiveVehicleInventoryLabel ||
        (activeVehicleLabel.isNotEmpty &&
            record.storageArea == activeVehicleLabel);
  }

  String _activeVehicleInventoryLabel(AppStateController appState) {
    final vehicle = appState.activeVehicle;
    if (vehicle == null) return 'Active vehicle';
    return vehicle.nickname;
  }

  List<WorkSupplyInventoryRecord> _relatedRecords(
    WorkSupplyInventoryRecord record,
  ) {
    final related = widget.records.where((candidate) {
      return candidate.item.id == record.item.id ||
          (candidate.item.name == record.item.name &&
              candidate.item.path == record.item.path);
    }).toList();
    related.sort((a, b) {
      final aDate = a.loggedAt ?? a.updatedAt ?? a.createdAt ?? DateTime(1900);
      final bDate = b.loggedAt ?? b.updatedAt ?? b.createdAt ?? DateTime(1900);
      return bDate.compareTo(aDate);
    });
    return related;
  }

  List<WorkSupplyInventoryTransaction> _recentTransactionsFor(
    WorkSupplyItem item,
  ) {
    final transactions = widget.transactions.where((transaction) {
      return _sameItemValues(transaction.item, item) &&
          transaction.type == WorkSupplyStockEventType.stockAdded;
    }).toList();
    transactions.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return transactions.take(10).toList();
  }

  List<_PreviouslyPurchasedItem> get _previouslyPurchasedItems {
    final inStockKeys = <String>{
      for (final record in widget.records)
        if (record.onHand > 0) _itemKey(record.item),
    };
    final byItem = <String, List<WorkSupplyInventoryTransaction>>{};
    for (final transaction in widget.transactions) {
      if (transaction.type != WorkSupplyStockEventType.stockAdded) {
        continue;
      }
      final key = _itemKey(transaction.item);
      if (inStockKeys.contains(key)) continue;
      byItem.putIfAbsent(key, () => []).add(transaction);
    }
    final items = <_PreviouslyPurchasedItem>[];
    for (final transactions in byItem.values) {
      transactions.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
      items.add(
        _PreviouslyPurchasedItem(
          item: transactions.first.item,
          transactions: transactions,
        ),
      );
    }
    items.sort((a, b) => b.lastPurchasedAt.compareTo(a.lastPurchasedAt));
    return items;
  }

  List<_PreviouslyPurchasedItem> _visiblePreviousItems(
    List<_PreviouslyPurchasedItem> items,
  ) {
    final query = _search.text.trim().toLowerCase();
    return items.where((entry) {
      if (query.isEmpty) return true;
      return entry.item.searchableText.contains(query) ||
          entry.lastMerchant.toLowerCase().contains(query);
    }).toList();
  }
}
