part of 'expense_receipt_entry_screen.dart';

// Kept to render drafts produced by the earlier detailed assisted-review UI.
// ignore: unused_element
class _ReceiptMixedAllocationReview extends StatelessWidget {
  const _ReceiptMixedAllocationReview({
    required this.lines,
    required this.businessTotal,
    required this.personalTotal,
  });

  final List<_ExpenseReceiptLine> lines;
  final double businessTotal;
  final double personalTotal;

  @override
  Widget build(BuildContext context) {
    final businessSubtotal = lines.fold(
      0.0,
      (sum, line) => sum + math.max(0, line.businessAmount),
    );
    final personalSubtotal = lines.fold(
      0.0,
      (sum, line) => sum + math.max(0, line.personalAmount),
    );
    final businessAdjustment = businessTotal - businessSubtotal;
    final personalAdjustment = personalTotal - personalSubtotal;
    final splitCount = lines
        .where((line) => line.use == _ExpenseLineUse.split)
        .length;
    final businessCount = lines
        .where((line) => line.use == _ExpenseLineUse.business)
        .length;
    final personalCount = lines
        .where((line) => line.use == _ExpenseLineUse.personal)
        .length;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EBD9),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFFB8AD9B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'ALLOCATION REVIEW',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF25211A),
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '$businessCount business lines, $personalCount personal lines, $splitCount split lines',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF62584C),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 7),
          _ReceiptAllocationBreakdownLine(
            label: 'Business subtotal',
            value: businessSubtotal,
          ),
          _ReceiptAllocationBreakdownLine(
            label: 'Business tax/adjustment',
            value: businessAdjustment,
          ),
          _ReceiptAllocationBreakdownLine(
            label: 'Business final',
            value: businessTotal,
            strong: true,
          ),
          const Divider(height: 10, color: Color(0x66756B5D)),
          _ReceiptAllocationBreakdownLine(
            label: 'Personal subtotal',
            value: personalSubtotal,
          ),
          _ReceiptAllocationBreakdownLine(
            label: 'Personal tax/adjustment',
            value: personalAdjustment,
          ),
          _ReceiptAllocationBreakdownLine(
            label: 'Personal final',
            value: personalTotal,
            strong: true,
          ),
        ],
      ),
    );
  }
}

class _ReceiptAllocationBreakdownLine extends StatelessWidget {
  const _ReceiptAllocationBreakdownLine({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final double value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: strong ? 2.5 : 1.5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: const Color(0xFF25211A),
                fontSize: strong ? 11 : 10.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
          Text(
            _money(value),
            style: TextStyle(
              color: const Color(0xFF25211A),
              fontSize: strong ? 12 : 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptPaperTotalLine extends StatelessWidget {
  const _ReceiptPaperTotalLine({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: strong ? 4 : 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                color: const Color(0xFF25211A),
                fontSize: strong ? 13 : 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: const Color(0xFF25211A),
              fontSize: strong ? 15 : 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
