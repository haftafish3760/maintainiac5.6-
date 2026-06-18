part of 'work_supply_inventory_screen.dart';

class _InventorySearchActionRow extends StatelessWidget {
  const _InventorySearchActionRow({
    required this.controller,
    required this.canGoBack,
    required this.onBack,
    required this.onAddItems,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool canGoBack;
  final VoidCallback onBack;
  final VoidCallback onAddItems;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (canGoBack) ...[
          SizedBox(
            width: 40,
            height: 40,
            child: FilledButton(
              onPressed: onBack,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: const Color(0xFF435360),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFFE8ECEE),
                size: 21,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: _InventorySearch(controller: controller, onChanged: onChanged),
        ),
        const SizedBox(width: 8),
        AppButton(
          label: 'Add Item',
          compact: true,
          tone: AppButtonTone.commit,
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
          onPressed: onAddItems,
        ),
      ],
    );
  }
}

class _InventorySearch extends StatelessWidget {
  const _InventorySearch({required this.controller, required this.onChanged});

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
        fillColor: const Color(0xFF0E1519),
        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFC7D0D4)),
        hintText: 'Search inventory',
        hintStyle: const TextStyle(
          color: Color(0xFF8F9EA5),
          fontWeight: FontWeight.w700,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF64C98A), width: 1.3),
        ),
      ),
    );
  }
}

class _InventoryModeToggle extends StatelessWidget {
  const _InventoryModeToggle({
    required this.selected,
    required this.currentCount,
    required this.previousCount,
    required this.onSelected,
  });

  final _InventoryReviewMode selected;
  final int currentCount;
  final int previousCount;
  final ValueChanged<_InventoryReviewMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ModeButton(
            label: 'Current Stock',
            count: currentCount,
            selected: selected == _InventoryReviewMode.current,
            color: const Color(0xFF58D67D),
            onTap: () => onSelected(_InventoryReviewMode.current),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ModeButton(
            label: 'Purchased, Not In Stock',
            count: previousCount,
            selected: selected == _InventoryReviewMode.previous,
            color: const Color(0xFFFFC46B),
            onTap: () => onSelected(_InventoryReviewMode.previous),
          ),
        ),
      ],
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.count,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: selected
            ? color.withValues(alpha: .62)
            : const Color(0xFF111B20),
        foregroundColor: const Color(0xFFE8ECEE),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(7),
          side: BorderSide(
            color: selected ? color : const Color(0xFF40515A),
            width: selected ? 1.5 : 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            count.toString(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.label,
    required this.choices,
    required this.selected,
    required this.onSelected,
    this.accentColor,
  });

  final String label;
  final List<_FilterChoice> choices;
  final String? selected;
  final ValueChanged<String> onSelected;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    if (choices.isEmpty) {
      return const _EmptyInventory(message: 'No stock here.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final hasImageTiles = choices.any(
              (choice) => choice.imageAsset != null,
            );
            final columns = hasImageTiles
                ? 3
                : constraints.maxWidth >= 520
                ? 4
                : 3;
            final spacing = hasImageTiles ? 16.0 : 10.0;
            final tileWidth =
                (constraints.maxWidth - (spacing * (columns - 1))) / columns;
            return Wrap(
              spacing: spacing,
              runSpacing: hasImageTiles ? 20 : 10,
              children: [
                for (final choice in choices)
                  SizedBox(
                    width: tileWidth,
                    child: _FilterChipTile(
                      choice: accentColor == null
                          ? choice
                          : _FilterChoice(
                              label: choice.label,
                              count: choice.count,
                              units: choice.units,
                              color: choice.color ?? accentColor,
                              imageAsset: choice.imageAsset,
                            ),
                      selected: selected == choice.label,
                      onTap: () => onSelected(choice.label),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _FilterChipTile extends StatelessWidget {
  const _FilterChipTile({
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  final _FilterChoice choice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageAsset = choice.imageAsset;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: imageAsset == null
          ? _FilterTextTile(choice: choice, selected: selected)
          : Column(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: _FilterTileArt(choice: choice, selected: selected),
                ),
                const SizedBox(height: 7),
                SizedBox(
                  height: 34,
                  child: Center(
                    child: Text(
                      choice.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFE8ECEE),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                        height: 1.05,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _FilterTextTile extends StatelessWidget {
  const _FilterTextTile({required this.choice, required this.selected});

  final _FilterChoice choice;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = choice.color ?? const Color(0xFF64C98A);
    return Ink(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            selected
                ? color.withValues(alpha: .50)
                : color.withValues(alpha: .31),
            selected ? const Color(0xFF17262C) : const Color(0xFF10191E),
          ],
        ),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: selected
              ? const Color(0xFFFFFFFF)
              : color.withValues(alpha: .8),
          width: selected ? 3 : 2.2,
        ),
        boxShadow: [
          const BoxShadow(
            color: Color(0x99000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: color.withValues(alpha: selected ? .34 : .18),
            blurRadius: selected ? 14 : 8,
            spreadRadius: selected ? 1 : 0,
          ),
        ],
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 116),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 5,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                choice.label,
                softWrap: true,
                style: const TextStyle(
                  color: Color(0xFFE8ECEE),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _filterChoiceDetail(choice),
                softWrap: true,
                style: const TextStyle(
                  color: Color(0xFFC7D0D4),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterTileArt extends StatelessWidget {
  const _FilterTileArt({required this.choice, required this.selected});

  final _FilterChoice choice;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = choice.color ?? const Color(0xFF64C98A);
    final imageAsset = choice.imageAsset;
    if (imageAsset != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              imageAsset,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return _FilterTileFallbackArt(color: color);
              },
            ),
            if (selected)
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: const Color(0xFFFFFFFF), width: 3),
                ),
              ),
          ],
        ),
      );
    }
    return Ink(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: selected
              ? [const Color(0xFF1F7ED0), const Color(0xFF073D76)]
              : [const Color(0xFF1A66A8), const Color(0xFF062B57)],
        ),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: selected ? const Color(0xFFFFFFFF) : const Color(0xFF4EA9FF),
          width: selected ? 3 : 2,
        ),
        boxShadow: [
          const BoxShadow(
            color: Color(0x99000000),
            blurRadius: 9,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: color.withValues(alpha: selected ? .48 : .24),
            blurRadius: selected ? 14 : 6,
            spreadRadius: selected ? 1 : 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: _FilterTileFallbackArt(color: color),
      ),
    );
  }
}

class _FilterTileFallbackArt extends StatelessWidget {
  const _FilterTileFallbackArt({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: .72), const Color(0xFF062B57)],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: SizedBox.expand(),
        ),
      ),
    );
  }
}
