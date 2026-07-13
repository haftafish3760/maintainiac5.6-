part of 'receipt_attachment_panel.dart';

class _ExpenseReceiptReviewDefaultPicker extends StatelessWidget {
  const _ExpenseReceiptReviewDefaultPicker({required this.settings});

  final ExpenseSettingsController settings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF101719),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF445159)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Expense Receipt Review Detail',
            style: TextStyle(
              color: Color(0xFFE8ECEE),
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Choose what Maintainiac shows after it reads an expense receipt. You can still change this on each receipt before saving.',
            style: TextStyle(
              color: Color(0xFFC7D0D4),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              height: 1.24,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          _ReceiptReviewStyleChoice(
            selected:
                settings.receiptReviewStyle ==
                ExpenseReceiptReviewStyle.basicReceipt,
            icon: Icons.receipt_outlined,
            title: 'Basic Receipt',
            detail:
                'Fastest review. Keep the receipt proof and confirm the store, date, category, and total without item lines.',
            onTap: () => settings.setReceiptReviewStyle(
              ExpenseReceiptReviewStyle.basicReceipt,
            ),
          ),
          const SizedBox(height: 8),
          _ReceiptReviewStyleChoice(
            selected:
                settings.receiptReviewStyle ==
                ExpenseReceiptReviewStyle.simpleAmounts,
            icon: Icons.price_check_rounded,
            title: 'Show Prices Only',
            detail:
                'Fastest review. Maintainiac lists detected receipt amounts so you can mark each one Business, Personal, or Split.',
            onTap: () => settings.setReceiptReviewStyle(
              ExpenseReceiptReviewStyle.simpleAmounts,
            ),
          ),
          const SizedBox(height: 8),
          _ReceiptReviewStyleChoice(
            selected:
                settings.receiptReviewStyle ==
                ExpenseReceiptReviewStyle.fullItemDetails,
            icon: Icons.receipt_long_rounded,
            title: 'Show Full Item Details',
            detail:
                'Use this when you want item names, quantities, fuel details, materials, packages, or inventory review.',
            onTap: () => settings.setReceiptReviewStyle(
              ExpenseReceiptReviewStyle.fullItemDetails,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptReviewStyleChoice extends StatelessWidget {
  const _ReceiptReviewStyleChoice({
    required this.selected,
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = selected ? const Color(0xFFFFD166) : const Color(0xFF526168);
    final fill = selected ? const Color(0xFF2E2812) : const Color(0xFF172126);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: selected
                  ? const Color(0xFFFFD166)
                  : const Color(0xFFC7D0D4),
              size: 19,
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
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    detail,
                    style: const TextStyle(
                      color: Color(0xFFC7D0D4),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      height: 1.23,
                      letterSpacing: 0,
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
                  ? const Color(0xFFFFD166)
                  : const Color(0xFFC7D0D4),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
