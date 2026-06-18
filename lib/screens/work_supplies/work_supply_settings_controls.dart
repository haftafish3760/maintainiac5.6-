part of 'work_supply_settings_screen.dart';

class _CatalogNodeButton extends StatelessWidget {
  const _CatalogNodeButton({
    required this.label,
    required this.count,
    required this.selected,
    required this.followed,
    required this.hidden,
    required this.color,
    required this.onTap,
    required this.onFollow,
    required this.onHide,
  });

  final String label;
  final int count;
  final bool selected;
  final bool followed;
  final bool hidden;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onFollow;
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    final fill = hidden
        ? const Color(0xFF2A1717)
        : selected
        ? color.withValues(alpha: .45)
        : const Color(0xFF18252C);
    final border = hidden
        ? const Color(0xFFE06161)
        : selected
        ? const Color(0xFFFFFFFF)
        : const Color(0xFFA4B0B5);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: border, width: selected ? 2.4 : 1.4),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onTap,
              child: Text(
                '$label $count',
                softWrap: true,
                style: const TextStyle(
                  color: Color(0xFFE8ECEE),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
            ),
            const SizedBox(height: 7),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MiniToggleButton(
                  label: followed ? 'Following' : 'Follow',
                  active: followed,
                  color: const Color(0xFF58D67D),
                  onTap: onFollow,
                ),
                const SizedBox(width: 6),
                _MiniToggleButton(
                  label: hidden ? 'Hidden' : 'Hide',
                  active: hidden,
                  color: const Color(0xFFE06161),
                  onTap: onHide,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemSettingsRow extends StatelessWidget {
  const _ItemSettingsRow({required this.settings, required this.item});

  final WorkSupplyInventorySettingsController settings;
  final WorkSupplyItem item;

  @override
  Widget build(BuildContext context) {
    final followed = settings.followsItem(item);
    final hidden = settings.hidesItem(item);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: hidden ? const Color(0xFF2A1717) : const Color(0xFF111B20),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: hidden ? const Color(0xFFE06161) : const Color(0xFF53656D),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              item.name,
              softWrap: true,
              style: const TextStyle(
                color: Color(0xFFE8ECEE),
                fontSize: 14,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.path,
              softWrap: true,
              style: const TextStyle(
                color: Color(0xFFC7D0D4),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _MiniToggleButton(
                  label: followed ? 'Following' : 'Follow',
                  active: followed,
                  color: const Color(0xFF58D67D),
                  onTap: () => settings.setItemFollowed(item, !followed),
                ),
                const SizedBox(width: 8),
                _MiniToggleButton(
                  label: hidden ? 'Hidden' : 'Hide',
                  active: hidden,
                  color: const Color(0xFFE06161),
                  onTap: () => settings.setItemHidden(item, !hidden),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSwitchRow extends StatelessWidget {
  const _SettingsSwitchRow({
    required this.label,
    required this.detail,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String detail;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF111B20),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF53656D)),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeThumbColor: const Color(0xFF58D67D),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        title: Text(
          label,
          softWrap: true,
          style: const TextStyle(
            color: Color(0xFFE8ECEE),
            fontSize: 14,
            fontWeight: FontWeight.w900,
            height: 1.15,
          ),
        ),
        subtitle: Text(
          detail,
          softWrap: true,
          style: const TextStyle(
            color: Color(0xFFC7D0D4),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
      ),
    );
  }
}

class _MiniToggleButton extends StatelessWidget {
  const _MiniToggleButton({
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: .7) : const Color(0xFF071014),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: active ? const Color(0xFFFFFFFF) : const Color(0xFF53656D),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(
            label,
            softWrap: true,
            style: const TextStyle(
              color: Color(0xFFE8ECEE),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF172126),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF53656D), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              softWrap: true,
              style: const TextStyle(
                color: Color(0xFFE8ECEE),
                fontSize: 18,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

int _tradeItemCount(WorkSupplyTrade trade) {
  return trade.categories.fold(0, (total, category) {
    return total + _categoryItemCount(category);
  });
}

int _categoryItemCount(WorkSupplyCategory category) {
  return category.systems.fold(0, (total, system) {
    return total +
        system.itemTypes.fold(0, (typeTotal, type) {
          return typeTotal + type.items.length;
        });
  });
}
