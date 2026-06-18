import 'package:flutter/material.dart';

import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_screen_shell.dart';
import '../data/work_supply_catalog.dart';
import '../data/work_supply_models.dart';

part 'work_supply_catalog_sections.dart';

class WorkSupplyCatalogScreen extends StatefulWidget {
  const WorkSupplyCatalogScreen({super.key, required this.onAddItem});

  final ValueChanged<WorkSupplyItem> onAddItem;

  @override
  State<WorkSupplyCatalogScreen> createState() =>
      _WorkSupplyCatalogScreenState();
}

class _WorkSupplyCatalogScreenState extends State<WorkSupplyCatalogScreen> {
  final _search = TextEditingController();
  WorkSupplyTrade? _trade;
  WorkSupplyCategory? _category;
  WorkSupplySystem? _system;
  WorkSupplyItemType? _itemType;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searching = _search.text.trim().isNotEmpty;
    return PopScope(
      canPop: !_canGoBack,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _canGoBack) _goBackOneLevel();
      },
      child: AppScreenShell(
        section: AppSection.materials,
        body: ListView(
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 24),
          children: [
            const GlobalOdometerHeader(section: AppSection.materials),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CatalogHeader(
                    title: _title,
                    subtitle: _subtitle,
                    canGoBack: _canGoBack,
                    onBack: _goBackOneLevel,
                  ),
                  const SizedBox(height: 10),
                  _SearchBox(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  if (searching)
                    _SearchResults(
                      results: searchWorkSupplies(_search.text),
                      onAddItem: widget.onAddItem,
                      onCreateCustom: _addCustomFromSearch,
                    )
                  else
                    _CurrentLevel(
                      trade: _trade,
                      category: _category,
                      system: _system,
                      itemType: _itemType,
                      onTrade: (trade) {
                        setState(() {
                          _trade = trade;
                          _category = null;
                          _system = null;
                          _itemType = null;
                        });
                      },
                      onCategory: (category) {
                        setState(() {
                          _category = category;
                          _system = null;
                          _itemType = null;
                        });
                      },
                      onSystem: (system) {
                        setState(() {
                          _system = system;
                          _itemType = null;
                        });
                      },
                      onItemType: (itemType) {
                        setState(() => _itemType = itemType);
                      },
                      onAddItem: widget.onAddItem,
                      onCreateCustom: _addCustomFromBranch,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _canGoBack =>
      _trade != null ||
      _category != null ||
      _system != null ||
      _itemType != null;

  String get _title {
    if (_itemType != null) return _itemType!.name;
    if (_system != null) return _system!.name;
    if (_category != null) return _category!.name;
    if (_trade != null) return _trade!.name;
    return 'Browse Catalog';
  }

  String get _subtitle {
    if (_itemType != null) {
      return 'Choose the exact size or variant. This is the item that gets counted.';
    }
    if (_system != null) return '${_system!.name} item types';
    if (_category != null) return '${_category!.name} materials and systems';
    if (_trade != null) return '${_trade!.name} categories';
    return 'Choose a trade, then drill down to the exact item.';
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

  void _addCustomFromSearch() {
    final name = _search.text.trim();
    if (name.isEmpty) return;
    widget.onAddItem(
      WorkSupplyItem(
        id: 'USER',
        name: name,
        trade: _trade?.name ?? 'Unsorted',
        category: _category?.name ?? 'Custom',
        system: _system?.name ?? 'User Added',
        itemType: _itemType?.name ?? 'Manual Item',
        variant: 'manual',
        unit: 'each',
        aliases: [name],
      ),
    );
  }

  void _addCustomFromBranch() {
    widget.onAddItem(
      WorkSupplyItem(
        id: 'USER',
        name:
            _itemType?.name ??
            _system?.name ??
            _category?.name ??
            'Custom Inventory Item',
        trade: _trade?.name ?? 'Unsorted',
        category: _category?.name ?? 'Custom',
        system: _system?.name ?? 'User Added',
        itemType: _itemType?.name ?? 'Manual Item',
        variant: 'manual',
        unit: 'each',
        aliases: const [],
      ),
    );
  }
}
