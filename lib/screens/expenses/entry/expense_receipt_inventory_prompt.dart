part of 'expense_receipt_entry_screen.dart';

class _InventoryTrackingPrompt extends StatelessWidget {
  const _InventoryTrackingPrompt({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ReceiptFormPanel(
      title: 'Save Materials Receipt',
      subtitle:
          'Choose whether this is only an expense record or should also be prepared for Materials inventory.',
      icon: Icons.inventory_2_rounded,
      accentColor: const Color(0xFF58D67D),
      children: [
        _InventoryTrackingChoice(
          selected: !value,
          icon: Icons.receipt_long_rounded,
          title: 'Expense only',
          subtitle: 'Save the receipt in Expenses. Do not add inventory items.',
          onTap: () => onChanged(false),
        ),
        const SizedBox(height: 8),
        _InventoryTrackingChoice(
          selected: value,
          icon: Icons.inventory_rounded,
          title: 'Also prepare Materials inventory',
          subtitle:
              'Create review lines in Materials so stock can be confirmed later.',
          onTap: () => onChanged(true),
        ),
      ],
    );
  }
}

class _InventoryTrackingChoice extends StatelessWidget {
  const _InventoryTrackingChoice({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? const Color(0xFF58D67D)
        : const Color(0xFF425059);
    final backgroundColor = selected
        ? const Color(0xFF173525)
        : const Color(0xFF151B1E);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected
                  ? const Color(0xFF58D67D)
                  : const Color(0xFFC8D0D3),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFFE8ECEE),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFFC8D0D3),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected
                  ? const Color(0xFF58D67D)
                  : const Color(0xFFC8D0D3),
            ),
          ],
        ),
      ),
    );
  }
}
