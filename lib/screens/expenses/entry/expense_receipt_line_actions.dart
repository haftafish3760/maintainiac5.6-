part of 'expense_receipt_entry_screen.dart';

class _ReceiptLineActionsPanel extends StatelessWidget {
  const _ReceiptLineActionsPanel({
    required this.nextLineNumber,
    required this.materialMode,
    required this.maintenanceRepairMode,
    required this.fuelMode,
    required this.onAddItem,
  });

  final int nextLineNumber;
  final bool materialMode;
  final bool maintenanceRepairMode;
  final bool fuelMode;
  final VoidCallback onAddItem;

  @override
  Widget build(BuildContext context) {
    final label = nextLineNumber == 1 ? 'Add Item' : 'Add Another Item';
    final helper = fuelMode
        ? 'Enter the fuel line from this receipt.'
        : maintenanceRepairMode
        ? 'Enter the service or repair line from this receipt.'
        : 'Full detail review: add names, quantities, categories, and amounts.';
    return _ReceiptActionButton(
      label: label,
      helper: helper,
      icon: Icons.playlist_add_rounded,
      color: const Color(0xFF2E78B7),
      onTap: onAddItem,
    );
  }
}

class _ReceiptActionButton extends StatelessWidget {
  const _ReceiptActionButton({
    required this.label,
    required this.helper,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String helper;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      helper,
                      style: const TextStyle(
                        color: Color(0xFFEAF0EE),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
