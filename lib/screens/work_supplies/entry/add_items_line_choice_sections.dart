part of 'work_supply_add_items_screen.dart';

class _ReceiptEntryLanes extends StatelessWidget {
  const _ReceiptEntryLanes({
    required this.nextLineNumber,
    required this.onInventoryLine,
    required this.onBusinessLine,
    required this.onPersonalLine,
  });

  final int nextLineNumber;
  final VoidCallback onInventoryLine;
  final VoidCallback onBusinessLine;
  final VoidCallback onPersonalLine;

  @override
  Widget build(BuildContext context) {
    final inventoryLane = _ReceiptEntryLane(
      title: 'Add inventory item',
      detail:
          'Use this when this receipt line adds inventory to your business.',
      lineLabel: 'Next line: $nextLineNumber',
      buttonLabel: 'Add Inventory Item',
      icon: Icons.inventory_2_outlined,
      color: const Color(0xFF63B3E6),
      onTap: onInventoryLine,
    );
    final businessLane = _ReceiptEntryLane(
      title: 'Add business expense only',
      detail:
          'Use this for a business line that belongs on the receipt but should not be added to inventory.',
      lineLabel: 'Next line: $nextLineNumber',
      buttonLabel: 'Add Business Expense',
      icon: Icons.receipt_long_outlined,
      color: const Color(0xFFFFC46B),
      onTap: onBusinessLine,
    );
    final personalLane = _ReceiptEntryLane(
      title: 'Add personal item',
      detail:
          'Use this for personal items on the same receipt so they stay out of business totals.',
      lineLabel: 'Next line: $nextLineNumber',
      buttonLabel: 'Add Personal Expense',
      icon: Icons.privacy_tip_outlined,
      color: const Color(0xFFE0A7FF),
      onTap: onPersonalLine,
    );
    final lanes = [inventoryLane, businessLane, personalLane];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AddReceiptItemHeader(nextLineNumber: nextLineNumber),
        const SizedBox(height: 10),
        for (var index = 0; index < lanes.length; index++) ...[
          if (index > 0) const SizedBox(height: 10),
          lanes[index],
        ],
      ],
    );
  }
}

class _AddReceiptItemHeader extends StatelessWidget {
  const _AddReceiptItemHeader({required this.nextLineNumber});

  final int nextLineNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2026),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF5E6D76), width: 1.1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.playlist_add_rounded,
            color: Color(0xFFD6DEE2),
            size: 22,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add receipt item $nextLineNumber',
                  style: const TextStyle(
                    color: Color(0xFFE8ECEE),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Choose what the next line on the receipt should become.',
                  style: TextStyle(
                    color: Color(0xFFC7D0D4),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptEntryLane extends StatelessWidget {
  const _ReceiptEntryLane({
    required this.title,
    required this.detail,
    required this.lineLabel,
    required this.buttonLabel,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String detail;
  final String lineLabel;
  final String buttonLabel;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
      decoration: BoxDecoration(
        color: const Color(0xFF141A1F),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF42515A), width: 1.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, color: const Color(0xFF07100A), size: 20),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFFE8ECEE),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      detail,
                      style: const TextStyle(
                        color: Color(0xFFD3DBDE),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                lineLabel,
                style: const TextStyle(
                  color: Color(0xFFC7D0D4),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text(buttonLabel),
              style: FilledButton.styleFrom(
                backgroundColor: color,
                foregroundColor: const Color(0xFF07100A),
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 10,
                ),
                minimumSize: const Size(0, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                textStyle: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineItemTypeButtons extends StatelessWidget {
  const _LineItemTypeButtons({
    required this.selected,
    required this.onSelected,
  });

  final _ItemEntryMode? selected;
  final ValueChanged<_ItemEntryMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < 390
            ? constraints.maxWidth
            : (constraints.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _EntryModeButton(
              label: 'Add Inventory Item',
              detail: 'Create a new stocked item from the next receipt line.',
              icon: Icons.add_box_outlined,
              color: const Color(0xFF1976B9),
              selected: selected == _ItemEntryMode.newInventory,
              width: width,
              onTap: () => onSelected(_ItemEntryMode.newInventory),
            ),
            _EntryModeButton(
              label: 'Use Saved Item',
              detail: 'Find an existing item and add it to this receipt.',
              icon: Icons.search_rounded,
              color: const Color(0xFF4B7F52),
              selected: selected == _ItemEntryMode.catalogInventory,
              width: width,
              onTap: () => onSelected(_ItemEntryMode.catalogInventory),
            ),
            _EntryModeButton(
              label: 'Add Expense Item',
              detail: 'Record a receipt line without adding inventory stock.',
              icon: Icons.receipt_long_outlined,
              color: const Color(0xFF9A6330),
              selected: selected == _ItemEntryMode.nonInventory,
              width: constraints.maxWidth,
              onTap: () => onSelected(_ItemEntryMode.nonInventory),
            ),
          ],
        );
      },
    );
  }
}

class _LineChoicePrompt extends StatelessWidget {
  const _LineChoicePrompt();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1114),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF3F5058)),
      ),
      child: const Text(
        'Enter the receipt from top to bottom. Start with the first line, save it, then add the next line.',
        style: TextStyle(
          color: Color(0xFFC7D0D4),
          fontSize: 12,
          fontWeight: FontWeight.w800,
          height: 1.25,
        ),
      ),
    );
  }
}

class _ReceiptItemHelper extends StatelessWidget {
  const _ReceiptItemHelper();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1519),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF4F6570), width: 1.15),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFF8FD3FF), size: 19),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Enter this receipt from top to bottom. Add each line, review the running total, then save the receipt when every line is listed.',
              style: TextStyle(
                color: Color(0xFFDDE6EA),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryModeButton extends StatelessWidget {
  const _EntryModeButton({
    required this.label,
    required this.detail,
    required this.icon,
    required this.color,
    required this.selected,
    required this.width,
    required this.onTap,
  });

  final String label;
  final String detail;
  final IconData icon;
  final Color color;
  final bool selected;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 19),
        label: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(
              detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10.5, height: 1.1),
            ),
          ],
        ),
        style: FilledButton.styleFrom(
          backgroundColor: selected ? color : const Color(0xFF263844),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
