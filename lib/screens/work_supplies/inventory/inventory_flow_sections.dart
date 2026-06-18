part of 'work_supply_inventory_screen.dart';

class _CurrentInventoryFlow extends StatelessWidget {
  const _CurrentInventoryFlow({
    required this.trade,
    required this.category,
    required this.system,
    required this.companyRecords,
    required this.activeRecords,
    required this.selectedRecord,
    required this.onTrade,
    required this.onCategory,
    required this.onSystem,
    required this.onChangeTrade,
    required this.onChangeCategory,
    required this.onRecord,
  });

  final String? trade;
  final String? category;
  final String? system;
  final List<WorkSupplyInventoryRecord> companyRecords;
  final List<WorkSupplyInventoryRecord> activeRecords;
  final WorkSupplyInventoryRecord? selectedRecord;
  final ValueChanged<String> onTrade;
  final ValueChanged<String> onCategory;
  final ValueChanged<String> onSystem;
  final VoidCallback onChangeTrade;
  final VoidCallback onChangeCategory;
  final ValueChanged<WorkSupplyInventoryRecord> onRecord;

  @override
  Widget build(BuildContext context) {
    final selectedTrade = trade;
    final selectedCategory = category;
    if (selectedTrade == null) {
      return _FilterRow(
        label: 'Select a trade',
        choices: _filterChoices(
          records: companyRecords,
          valueFor: (record) => record.item.trade,
          colorFor: _tradeColor,
          imageFor: _generatedTradeIconAsset,
          order: _inventoryTradeOrder,
        ),
        selected: null,
        onSelected: onTrade,
      );
    }

    if (selectedCategory == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InventoryPathBar(
            trade: selectedTrade,
            category: null,
            system: null,
            onChangeTrade: onChangeTrade,
            onChangeCategory: null,
          ),
          const SizedBox(height: 8),
          _FilterRow(
            label: 'Select a $selectedTrade category',
            choices: _filterChoices(
              records: _recordsForPath(companyRecords, trade: selectedTrade),
              valueFor: (record) => record.item.category,
              colorFor: (_) => _tradeColor(selectedTrade),
            ),
            selected: null,
            onSelected: onCategory,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InventoryPathBar(
          trade: selectedTrade,
          category: selectedCategory,
          system: system,
          onChangeTrade: onChangeTrade,
          onChangeCategory: onChangeCategory,
        ),
        const SizedBox(height: 8),
        _InventoryPathBody(
          trade: selectedTrade,
          category: selectedCategory,
          allCategoryRecords: _recordsForPath(
            companyRecords,
            trade: selectedTrade,
            category: selectedCategory,
          ),
          activeCategoryRecords: _recordsForPath(
            activeRecords,
            trade: selectedTrade,
            category: selectedCategory,
          ),
          selectedSystem: system,
          selectedRecord: selectedRecord,
          onSystem: onSystem,
          onRecord: onRecord,
        ),
      ],
    );
  }
}

class _InventoryPathBar extends StatelessWidget {
  const _InventoryPathBar({
    required this.trade,
    required this.category,
    required this.system,
    required this.onChangeTrade,
    required this.onChangeCategory,
  });

  final String trade;
  final String? category;
  final String? system;
  final VoidCallback onChangeTrade;
  final VoidCallback? onChangeCategory;

  @override
  Widget build(BuildContext context) {
    final color = _tradeColor(trade);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF10191E),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color, width: 1.8),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _PathToken(
            label: trade,
            icon: Icons.handyman_rounded,
            color: color,
            onTap: onChangeTrade,
          ),
          if (category != null)
            _PathToken(
              label: category!,
              icon: Icons.inventory_2_rounded,
              color: const Color(0xFF8FD3FF),
              onTap: onChangeCategory,
            ),
          if (system != null)
            _PathToken(
              label: system!,
              icon: Icons.account_tree_rounded,
              color: const Color(0xFFFFC46B),
              onTap: null,
            ),
        ],
      ),
    );
  }
}

class _PathToken extends StatelessWidget {
  const _PathToken({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: .24),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color, width: 1.4),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: const Color(0xFFE8ECEE), size: 16),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  softWrap: true,
                  style: const TextStyle(
                    color: Color(0xFFE8ECEE),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InventoryPathBody extends StatelessWidget {
  const _InventoryPathBody({
    required this.trade,
    required this.category,
    required this.allCategoryRecords,
    required this.activeCategoryRecords,
    required this.selectedSystem,
    required this.selectedRecord,
    required this.onSystem,
    required this.onRecord,
  });

  final String trade;
  final String category;
  final List<WorkSupplyInventoryRecord> allCategoryRecords;
  final List<WorkSupplyInventoryRecord> activeCategoryRecords;
  final String? selectedSystem;
  final WorkSupplyInventoryRecord? selectedRecord;
  final ValueChanged<String> onSystem;
  final ValueChanged<WorkSupplyInventoryRecord> onRecord;

  @override
  Widget build(BuildContext context) {
    final systems = _filterChoices(
      records: allCategoryRecords,
      valueFor: (record) => record.item.system,
    );
    final meaningfulSubcategories = systems.length > 1;
    final gridRecords = selectedSystem == null
        ? allCategoryRecords
        : _recordsForPath(allCategoryRecords, system: selectedSystem);
    final activeGridRecords = selectedSystem == null
        ? activeCategoryRecords
        : _recordsForPath(activeCategoryRecords, system: selectedSystem);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (meaningfulSubcategories) ...[
          _FilterRow(
            label: 'Select composition',
            choices: systems,
            selected: selectedSystem,
            accentColor: _tradeColor(trade),
            onSelected: onSystem,
          ),
          const SizedBox(height: 10),
        ],
        _CompactInventoryGrid(
          records: gridRecords,
          activeRecords: activeGridRecords,
          selected: selectedRecord,
          emptyMessage: 'No stocked items in this selection.',
          onSelected: onRecord,
        ),
      ],
    );
  }
}

class _PreviouslyPurchasedView extends StatelessWidget {
  const _PreviouslyPurchasedView({
    required this.items,
    required this.selectedTrade,
    required this.selectedCategory,
    required this.onTrade,
    required this.onCategory,
    required this.onAddItem,
  });

  final List<_PreviouslyPurchasedItem> items;
  final String? selectedTrade;
  final String? selectedCategory;
  final ValueChanged<String> onTrade;
  final ValueChanged<String> onCategory;
  final ValueChanged<WorkSupplyItem> onAddItem;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyInventory(
        message: 'No previously purchased out-of-stock items match this view.',
      );
    }
    final tradeChoices = _previousFilterChoices(
      items: items,
      valueFor: (entry) => entry.item.trade,
      colorFor: _tradeColor,
      order: _inventoryTradeOrder,
    );
    final categoryChoices = selectedTrade == null
        ? <_FilterChoice>[]
        : _previousFilterChoices(
            items: items
                .where((entry) => entry.item.trade == selectedTrade)
                .toList(),
            valueFor: (entry) => entry.item.category,
          );
    final visible = items.where((entry) {
      if (selectedTrade != null && entry.item.trade != selectedTrade) {
        return false;
      }
      if (selectedCategory != null && entry.item.category != selectedCategory) {
        return false;
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FilterRow(
          label: 'Previously purchased trades',
          choices: tradeChoices,
          selected: selectedTrade,
          onSelected: onTrade,
        ),
        if (selectedTrade != null) ...[
          const SizedBox(height: 10),
          _FilterRow(
            label: 'Previously purchased $selectedTrade categories',
            choices: categoryChoices,
            selected: selectedCategory,
            onSelected: onCategory,
          ),
        ],
        const SizedBox(height: 10),
        const _SectionLabel('Previously Purchased, Not Currently In Stock'),
        const SizedBox(height: 6),
        for (final entry in visible)
          _PreviouslyPurchasedRow(entry: entry, onAddItem: onAddItem),
      ],
    );
  }
}

class _PreviouslyPurchasedRow extends StatelessWidget {
  const _PreviouslyPurchasedRow({required this.entry, required this.onAddItem});

  final _PreviouslyPurchasedItem entry;
  final ValueChanged<WorkSupplyItem> onAddItem;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.fromLTRB(9, 8, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF201B12),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFFFC46B), width: 1.15),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFE8ECEE),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  [
                    'Last: ${_dateLabel(entry.lastPurchasedAt)}',
                    if (entry.lastMerchant.isNotEmpty) entry.lastMerchant,
                    _money(entry.lastUnitCost),
                  ].join(' | '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFD9C49A),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 34,
            child: FilledButton(
              onPressed: () => onAddItem(entry.item),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4B7F52),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text(
                'Add More',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
