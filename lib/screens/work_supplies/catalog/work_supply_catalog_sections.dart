part of 'work_supply_catalog_screen.dart';

class _CatalogHeader extends StatelessWidget {
  const _CatalogHeader({
    required this.title,
    required this.subtitle,
    required this.canGoBack,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final bool canGoBack;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (canGoBack) ...[
          SizedBox(
            width: 42,
            height: 42,
            child: FilledButton(
              onPressed: onBack,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: const Color(0xFF435360),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(21),
                ),
              ),
              child: const Text(
                '<',
                style: TextStyle(
                  color: Color(0xFFE8ECEE),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFE8ECEE),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFFC7D0D4),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      cursorColor: const Color(0xFFE8ECEE),
      style: const TextStyle(
        color: Color(0xFFE8ECEE),
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF172126),
        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFC7D0D4)),
        hintText: 'Search exact items, aliases, or item numbers',
        hintStyle: const TextStyle(
          color: Color(0xFF9DA9AE),
          fontWeight: FontWeight.w700,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(7)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: Color(0xFF58A6D6), width: 1.3),
        ),
      ),
    );
  }
}

class _CurrentLevel extends StatelessWidget {
  const _CurrentLevel({
    required this.trade,
    required this.category,
    required this.system,
    required this.itemType,
    required this.onTrade,
    required this.onCategory,
    required this.onSystem,
    required this.onItemType,
    required this.onAddItem,
    required this.onCreateCustom,
  });

  final WorkSupplyTrade? trade;
  final WorkSupplyCategory? category;
  final WorkSupplySystem? system;
  final WorkSupplyItemType? itemType;
  final ValueChanged<WorkSupplyTrade> onTrade;
  final ValueChanged<WorkSupplyCategory> onCategory;
  final ValueChanged<WorkSupplySystem> onSystem;
  final ValueChanged<WorkSupplyItemType> onItemType;
  final ValueChanged<WorkSupplyItem> onAddItem;
  final VoidCallback onCreateCustom;

  @override
  Widget build(BuildContext context) {
    if (itemType != null) {
      return _ExactItemList(
        items: itemType!.items,
        onAddItem: onAddItem,
        onCreateCustom: onCreateCustom,
      );
    }
    if (system != null) {
      return _ChoiceGrid(
        accent: Color(trade!.color.value),
        choices: [
          for (final type in system!.itemTypes)
            _Choice(
              label: type.name,
              detail: '${type.items.length} sizes',
              onTap: () => onItemType(type),
            ),
        ],
      );
    }
    if (category != null) {
      return _ChoiceGrid(
        accent: Color(trade!.color.value),
        choices: [
          for (final system in category!.systems)
            _Choice(
              label: system.name,
              detail: '${_countSystemItems(system)} items',
              onTap: () => onSystem(system),
            ),
        ],
      );
    }
    if (trade != null) {
      return _ChoiceGrid(
        accent: Color(trade!.color.value),
        choices: [
          for (final category in trade!.categories)
            _Choice(
              label: category.name,
              detail: '${_countCategoryItems(category)} items',
              onTap: () => onCategory(category),
            ),
        ],
      );
    }
    return _ChoiceGrid(
      accent: const Color(0xFF58A6D6),
      choices: [
        for (final trade in workSupplyTrades)
          _Choice(
            label: trade.name,
            detail: '${_countTradeItems(trade)} items',
            color: Color(trade.color.value),
            onTap: () => onTrade(trade),
          ),
      ],
    );
  }
}

class _ChoiceGrid extends StatelessWidget {
  const _ChoiceGrid({required this.choices, required this.accent});

  final List<_Choice> choices;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 390 ? 4 : 3;
        final spacing = width >= 520 ? 8.0 : 6.0;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: choices.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: 1.5,
          ),
          itemBuilder: (context, index) {
            final choice = choices[index];
            return _ChoiceTile(choice: choice, fallbackColor: accent);
          },
        );
      },
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({required this.choice, required this.fallbackColor});

  final _Choice choice;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    final color = choice.color ?? fallbackColor;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: choice.onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withValues(alpha: .34), const Color(0xFF121B20)],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: .85), width: 1.2),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(7, 7, 7, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 4,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const Spacer(),
                Text(
                  choice.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFE8ECEE),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    height: 1.08,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  choice.detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFC7D0D4),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExactItemList extends StatelessWidget {
  const _ExactItemList({
    required this.items,
    required this.onAddItem,
    required this.onCreateCustom,
  });

  final List<WorkSupplyItem> items;
  final ValueChanged<WorkSupplyItem> onAddItem;
  final VoidCallback onCreateCustom;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CustomAddRow(onTap: onCreateCustom),
        for (final item in items)
          _CatalogItemRow(item: item, onAddItem: () => onAddItem(item)),
      ],
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.results,
    required this.onAddItem,
    required this.onCreateCustom,
  });

  final List<WorkSupplyItem> results;
  final ValueChanged<WorkSupplyItem> onAddItem;
  final VoidCallback onCreateCustom;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 12, bottom: 10),
            child: Text(
              'No matching catalog items.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFC7D0D4),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _CustomAddRow(onTap: onCreateCustom),
        ],
      );
    }
    return Column(
      children: [
        _CustomAddRow(onTap: onCreateCustom),
        for (final item in results)
          _CatalogItemRow(item: item, onAddItem: () => onAddItem(item)),
      ],
    );
  }
}

class _CustomAddRow extends StatelessWidget {
  const _CustomAddRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      child: AppButton(
        label: 'Add Item Not In Catalog',
        icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
        onPressed: onTap,
      ),
    );
  }
}

class _CatalogItemRow extends StatelessWidget {
  const _CatalogItemRow({required this.item, required this.onAddItem});

  final WorkSupplyItem item;
  final VoidCallback onAddItem;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF10181C),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF46565E)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    color: Color(0xFFE8ECEE),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.id} | ${item.path}',
                  style: const TextStyle(
                    color: Color(0xFF9DA9AE),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AppButton(
            label: 'Add',
            compact: true,
            tone: AppButtonTone.commit,
            onPressed: onAddItem,
          ),
        ],
      ),
    );
  }
}

class _Choice {
  const _Choice({
    required this.label,
    required this.detail,
    required this.onTap,
    this.color,
  });

  final String label;
  final String detail;
  final VoidCallback onTap;
  final Color? color;
}

int _countTradeItems(WorkSupplyTrade trade) {
  return trade.categories.fold(0, (total, category) {
    return total + _countCategoryItems(category);
  });
}

int _countCategoryItems(WorkSupplyCategory category) {
  return category.systems.fold(0, (total, system) {
    return total + _countSystemItems(system);
  });
}

int _countSystemItems(WorkSupplySystem system) {
  return system.itemTypes.fold(0, (total, type) => total + type.items.length);
}
