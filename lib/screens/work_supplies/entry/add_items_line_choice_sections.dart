part of 'work_supply_add_items_screen.dart';

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
              label: 'Existing Inventory Item',
              detail: 'Find saved stock and add quantity.',
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
