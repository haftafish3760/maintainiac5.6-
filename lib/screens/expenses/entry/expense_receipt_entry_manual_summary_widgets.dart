part of 'expense_receipt_entry_screen.dart';

class _ManualReceiptTotalsEditor extends StatelessWidget {
  const _ManualReceiptTotalsEditor({
    required this.itemSubtotal,
    required this.subtotalController,
    required this.taxController,
    required this.totalController,
    required this.businessTotal,
    required this.personalTotal,
  });

  final double itemSubtotal;
  final TextEditingController subtotalController;
  final TextEditingController taxController;
  final TextEditingController totalController;
  final double businessTotal;
  final double personalTotal;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Items total ${_money(itemSubtotal)}',
          style: const TextStyle(
            color: Color(0xFFB7C8CE),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        RecordTextField(
          label: 'Receipt subtotal',
          controller: subtotalController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 10),
        RecordTextField(
          label: 'Sales tax',
          controller: taxController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 10),
        RecordTextField(
          label: 'Final receipt total',
          controller: totalController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ManualReceiptAmount(
                label: 'Business',
                value: businessTotal,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ManualReceiptAmount(
                label: 'Personal',
                value: personalTotal,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ManualReceiptAmount extends StatelessWidget {
  const _ManualReceiptAmount({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF182226),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF91A4AB),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _money(value),
              style: const TextStyle(
                color: Color(0xFFF2F7F8),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManualReceiptEmptyItems extends StatelessWidget {
  const _ManualReceiptEmptyItems();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 22),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, color: Color(0xFF8FC9FF), size: 32),
          SizedBox(height: 9),
          Text(
            'No items yet',
            style: TextStyle(
              color: Color(0xFFF2F7F8),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Add each printed item, then review the totals.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFB7C8CE),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
