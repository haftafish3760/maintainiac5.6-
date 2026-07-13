part of 'expense_receipt_entry_screen.dart';

class _ReceiptDetailModePanel extends StatelessWidget {
  const _ReceiptDetailModePanel({required this.value, required this.onChanged});

  final _ReceiptDetailEntryMode value;
  final ValueChanged<_ReceiptDetailEntryMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return ReceiptFormPanel(
      title: 'How Should Maintainiac Help Review This Receipt?',
      subtitle:
          'Choose the amount of detail you want for receipt lines. You can change this here or in Expense settings.',
      icon: Icons.tune_rounded,
      accentColor: const Color(0xFF8FD3FF),
      children: [
        _ReceiptDetailModeChoice(
          selected: value == _ReceiptDetailEntryMode.basicReceipt,
          icon: Icons.receipt_outlined,
          title: ExpenseReceiptReviewStyle.basicReceipt.label,
          subtitle: ExpenseReceiptReviewStyle.basicReceipt.description,
          onTap: () => onChanged(_ReceiptDetailEntryMode.basicReceipt),
        ),
        const SizedBox(height: 8),
        _ReceiptDetailModeChoice(
          selected: value == _ReceiptDetailEntryMode.quickClassify,
          icon: Icons.fact_check_outlined,
          title: ExpenseReceiptReviewStyle.simpleAmounts.label,
          subtitle: ExpenseReceiptReviewStyle.simpleAmounts.description,
          onTap: () => onChanged(_ReceiptDetailEntryMode.quickClassify),
        ),
        const SizedBox(height: 8),
        _ReceiptDetailModeChoice(
          selected: value == _ReceiptDetailEntryMode.detailedItems,
          icon: Icons.list_alt_rounded,
          title: ExpenseReceiptReviewStyle.fullItemDetails.label,
          subtitle: ExpenseReceiptReviewStyle.fullItemDetails.description,
          onTap: () => onChanged(_ReceiptDetailEntryMode.detailedItems),
        ),
      ],
    );
  }
}

class _ReceiptDetailModeChoice extends StatelessWidget {
  const _ReceiptDetailModeChoice({
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
    final border = selected ? const Color(0xFF8FD3FF) : const Color(0xFF425059);
    final fill = selected ? const Color(0xFF173143) : const Color(0xFF151B1E);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: selected
                  ? const Color(0xFF8FD3FF)
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
                      fontSize: 14,
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
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected
                  ? const Color(0xFF8FD3FF)
                  : const Color(0xFFC8D0D3),
            ),
          ],
        ),
      ),
    );
  }
}
