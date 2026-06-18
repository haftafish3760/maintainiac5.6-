part of 'work_supply_add_items_screen.dart';

class _ItemPicker extends StatelessWidget {
  const _ItemPicker({
    required this.search,
    required this.results,
    required this.selectedItem,
    required this.trade,
    required this.category,
    required this.system,
    required this.itemType,
    required this.searchFocus,
    required this.onSearchChanged,
    required this.onTrade,
    required this.onCategory,
    required this.onSystem,
    required this.onItemType,
    required this.onBack,
    required this.onItemSelected,
  });

  final TextEditingController search;
  final List<WorkSupplyItem> results;
  final WorkSupplyItem? selectedItem;
  final WorkSupplyTrade? trade;
  final WorkSupplyCategory? category;
  final WorkSupplySystem? system;
  final WorkSupplyItemType? itemType;
  final FocusNode searchFocus;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<WorkSupplyTrade> onTrade;
  final ValueChanged<WorkSupplyCategory> onCategory;
  final ValueChanged<WorkSupplySystem> onSystem;
  final ValueChanged<WorkSupplyItemType> onItemType;
  final VoidCallback onBack;
  final ValueChanged<WorkSupplyItem> onItemSelected;

  @override
  Widget build(BuildContext context) {
    final searching = search.text.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Field(
          controller: search,
          label: 'Search exact item',
          hint: 'Example: 1/2 in copper 90',
          focusNode: searchFocus,
          onChanged: onSearchChanged,
        ),
        if (selectedItem != null)
          _SelectedItem(item: selectedItem!)
        else if (searching)
          _SearchResults(results: results, onItemSelected: onItemSelected)
        else ...[
          _BrowseHeader(
            title: _browseTitle,
            canGoBack:
                trade != null ||
                category != null ||
                system != null ||
                itemType != null,
            onBack: onBack,
          ),
          const SizedBox(height: 8),
          _BrowseLevel(
            trade: trade,
            category: category,
            system: system,
            itemType: itemType,
            onTrade: onTrade,
            onCategory: onCategory,
            onSystem: onSystem,
            onItemType: onItemType,
            onItemSelected: onItemSelected,
          ),
        ],
      ],
    );
  }

  String get _browseTitle {
    if (itemType != null) return 'Choose the exact item';
    if (system != null) return 'Choose the item type';
    if (category != null) return 'Choose the material or system';
    if (trade != null) return 'Choose the category';
    return 'Choose which category your item belongs to';
  }
}

class _SelectedItem extends StatelessWidget {
  const _SelectedItem({required this.item});

  final WorkSupplyItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1519),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF64C98A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selected item',
            style: TextStyle(
              color: Color(0xFF64C98A),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            item.name,
            style: const TextStyle(
              color: Color(0xFFE8ECEE),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            item.path,
            style: const TextStyle(
              color: Color(0xFFC7D0D4),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BrowseHeader extends StatelessWidget {
  const _BrowseHeader({
    required this.title,
    required this.canGoBack,
    required this.onBack,
  });

  final String title;
  final bool canGoBack;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (canGoBack) ...[
          SizedBox(
            width: 34,
            height: 34,
            child: FilledButton(
              onPressed: onBack,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: const Color(0xFF435360),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              child: const Text(
                '<',
                style: TextStyle(
                  color: Color(0xFFE8ECEE),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFFE8ECEE),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _BrowseLevel extends StatelessWidget {
  const _BrowseLevel({
    required this.trade,
    required this.category,
    required this.system,
    required this.itemType,
    required this.onTrade,
    required this.onCategory,
    required this.onSystem,
    required this.onItemType,
    required this.onItemSelected,
  });

  final WorkSupplyTrade? trade;
  final WorkSupplyCategory? category;
  final WorkSupplySystem? system;
  final WorkSupplyItemType? itemType;
  final ValueChanged<WorkSupplyTrade> onTrade;
  final ValueChanged<WorkSupplyCategory> onCategory;
  final ValueChanged<WorkSupplySystem> onSystem;
  final ValueChanged<WorkSupplyItemType> onItemType;
  final ValueChanged<WorkSupplyItem> onItemSelected;

  @override
  Widget build(BuildContext context) {
    if (itemType != null) {
      return _ExactItemChoices(
        items: itemType!.items,
        onItemSelected: onItemSelected,
      );
    }
    if (system != null) {
      return _ChoiceGrid(
        accent: trade!.color,
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
        accent: trade!.color,
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
        accent: trade!.color,
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
            color: trade.color,
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
            final color = choice.color ?? accent;
            return _ChoiceTile(choice: choice, color: color);
          },
        );
      },
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({required this.choice, required this.color});

  final _Choice choice;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: choice.onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFF14202A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color, width: 1.2),
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
