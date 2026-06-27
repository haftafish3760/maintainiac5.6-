part of 'work_supply_add_items_screen.dart';

class _ReceiptEntryLanes extends StatelessWidget {
  const _ReceiptEntryLanes({
    required this.nextLineNumber,
    required this.onReceiptDetails,
    required this.onInventoryLine,
    required this.onBusinessLine,
    required this.onPersonalLine,
    required this.onSplitLine,
  });

  final int nextLineNumber;
  final VoidCallback onReceiptDetails;
  final VoidCallback onInventoryLine;
  final VoidCallback onBusinessLine;
  final VoidCallback onPersonalLine;
  final VoidCallback onSplitLine;

  @override
  Widget build(BuildContext context) {
    return _BorderPanel(
      label: 'Add Line Item',
      surfaceColor: const Color(0xFF152027),
      borderColor: const Color(0xFF5D7480),
      labelColor: const Color(0xFF8FD3FF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LineItemCommandHeader(
            nextLineNumber: nextLineNumber,
            onReceiptDetails: onReceiptDetails,
          ),
          const SizedBox(height: 11),
          const _ReceiptCommandSectionLabel(
            title: 'Inventory items',
            detail: 'Materials or supplies you want this app to track.',
          ),
          const SizedBox(height: 8),
          _PrimaryLineActions(onInventoryLine: onInventoryLine),
          const SizedBox(height: 12),
          const _ReceiptCommandSectionLabel(
            title: 'Additional receipt items',
            detail:
                'Use these for items on this receipt that should not update inventory.',
          ),
          const SizedBox(height: 9),
          _NonInventoryLineActions(
            onBusinessLine: onBusinessLine,
            onPersonalLine: onPersonalLine,
            onSplitLine: onSplitLine,
          ),
        ],
      ),
    );
  }
}

class _LineItemCommandHeader extends StatelessWidget {
  const _LineItemCommandHeader({
    required this.nextLineNumber,
    required this.onReceiptDetails,
  });

  final int nextLineNumber;
  final VoidCallback onReceiptDetails;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF20313A),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: const Color(0xFF6F8792)),
          ),
          child: Text(
            '$nextLineNumber',
            style: const TextStyle(
              color: Color(0xFFE8ECEE),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What did you buy?',
                style: TextStyle(
                  color: Color(0xFFE8ECEE),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Add the next line from the receipt. Repeat until the receipt recap matches the paper receipt.',
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
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Edit receipt information',
          onPressed: onReceiptDetails,
          icon: const Icon(Icons.edit_note_rounded),
          color: const Color(0xFF101416),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFFFD166),
            minimumSize: const Size(38, 38),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReceiptCommandSectionLabel extends StatelessWidget {
  const _ReceiptCommandSectionLabel({
    required this.title,
    required this.detail,
  });

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF10181D),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF3F535E)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.label_outline_rounded,
            color: Color(0xFF8FD3FF),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFE8ECEE),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    color: Color(0xFFC7D0D4),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
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

class _PrimaryLineActions extends StatelessWidget {
  const _PrimaryLineActions({required this.onInventoryLine});

  final VoidCallback onInventoryLine;

  @override
  Widget build(BuildContext context) {
    return _ReceiptCommandButton(
      width: double.infinity,
      title: 'Inventory item',
      detail:
          'Choose the material or supply from the catalog, or create it if it is not listed yet.',
      icon: Icons.inventory_2_outlined,
      color: const Color(0xFF2F8F5B),
      onTap: onInventoryLine,
    );
  }
}

class _NonInventoryLineActions extends StatelessWidget {
  const _NonInventoryLineActions({
    required this.onBusinessLine,
    required this.onPersonalLine,
    required this.onSplitLine,
  });

  final VoidCallback onBusinessLine;
  final VoidCallback onPersonalLine;
  final VoidCallback onSplitLine;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final paired = constraints.maxWidth >= 330;
        final smallWidth = paired
            ? (constraints.maxWidth - 7) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            _CompactReceiptCommandButton(
              width: smallWidth,
              label: 'Business expense',
              icon: Icons.receipt_long_outlined,
              color: const Color(0xFFFFC46B),
              onTap: onBusinessLine,
            ),
            _CompactReceiptCommandButton(
              width: smallWidth,
              label: 'Personal purchase',
              icon: Icons.privacy_tip_outlined,
              color: const Color(0xFFE0A7FF),
              onTap: onPersonalLine,
            ),
            _CompactReceiptCommandButton(
              width: constraints.maxWidth,
              label: 'Split business/personal',
              icon: Icons.call_split_rounded,
              color: const Color(0xFFFFD166),
              onTap: onSplitLine,
            ),
          ],
        );
      },
    );
  }
}

class _ReceiptCommandButton extends StatelessWidget {
  const _ReceiptCommandButton({
    required this.width,
    required this.title,
    required this.detail,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final double width;
  final String title;
  final String detail;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          minimumSize: const Size.fromHeight(64),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 21),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.8,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactReceiptCommandButton extends StatelessWidget {
  const _CompactReceiptCommandButton({
    required this.width,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final double width;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 17, color: color),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFE8ECEE),
          side: BorderSide(color: color, width: 1.25),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          minimumSize: const Size.fromHeight(42),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
          textStyle: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
