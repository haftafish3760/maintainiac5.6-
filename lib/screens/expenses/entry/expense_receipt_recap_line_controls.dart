part of 'expense_receipt_entry_screen.dart';

class _ReceiptPaperLineRow extends StatelessWidget {
  const _ReceiptPaperLineRow({
    required this.lineNumber,
    required this.line,
    required this.showLineUseControls,
    required this.showItemDetails,
    required this.onEdit,
    required this.onSetUse,
  });

  final int lineNumber;
  final _ExpenseReceiptLine line;
  final bool showLineUseControls;
  final bool showItemDetails;
  final VoidCallback onEdit;
  final FutureOr<void> Function(_ExpenseLineUse use) onSetUse;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(2, 5, 0, 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  '$lineNumber',
                  style: const TextStyle(
                    color: Color(0xFFFFD166),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showLineUseControls) ...[
                      _ReceiptLineUseSegment(
                        selected: line.use,
                        onSelected: onSetUse,
                      ),
                      const SizedBox(height: 5),
                    ],
                    Text(
                      showItemDetails
                          ? line.description
                          : 'Receipt line $lineNumber',
                      style: const TextStyle(
                        color: Color(0xFFE8ECEE),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (showItemDetails) ...[
                      _ReceiptPaperLineFacts(line: line),
                      const SizedBox(height: 3),
                    ],
                    if (line.category != 'Uncategorized')
                      Text(
                        line.category,
                        style: const TextStyle(
                          color: Color(0xFFC8D0D3),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _money(line.subtotal),
                    style: const TextStyle(
                      color: Color(0xFFE8ECEE),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _LineButton(
                        label: 'Edit',
                        icon: Icons.edit_rounded,
                        onTap: onEdit,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptPaperLineFacts extends StatelessWidget {
  const _ReceiptPaperLineFacts({required this.line});

  final _ExpenseReceiptLine line;

  @override
  Widget build(BuildContext context) {
    final price = line.unitPrice;
    final priceLabel = price == null || !price.isFinite || price <= 0
        ? 'Not listed'
        : _money(price);
    final unitLabel = line.stockUnit.trim().isEmpty ? 'each' : line.stockUnit;
    return Wrap(
      spacing: 5,
      runSpacing: 4,
      children: [
        _ReceiptPaperLineFact(label: 'Price', value: priceLabel),
        _ReceiptPaperLineFact(label: 'Unit', value: unitLabel),
        _ReceiptPaperLineFact(label: 'Qty', value: line.quantityText),
      ],
    );
  }
}

class _ReceiptPaperLineFact extends StatelessWidget {
  const _ReceiptPaperLineFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF172126),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        child: Text(
          '$label: $value',
          style: const TextStyle(
            color: Color(0xFFC8D0D3),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

// Kept for the optional parser-diagnostic presentation.
// ignore: unused_element
class _ReceiptParserBadge extends StatelessWidget {
  const _ReceiptParserBadge({required this.line});

  final _ExpenseReceiptLine line;

  @override
  Widget build(BuildContext context) {
    final color = line.parserBadgeColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: .75)),
      ),
      child: Text(
        line.parserReviewSummary,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _ReceiptLineUseSegment extends StatelessWidget {
  const _ReceiptLineUseSegment({
    required this.selected,
    required this.onSelected,
  });

  final _ExpenseLineUse selected;
  final FutureOr<void> Function(_ExpenseLineUse use) onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        _ReceiptLineUseChip(
          label: 'Business',
          use: _ExpenseLineUse.business,
          selected: selected == _ExpenseLineUse.business,
          color: const Color(0xFF1F6FA8),
          onSelected: onSelected,
        ),
        _ReceiptLineUseChip(
          label: 'Personal',
          use: _ExpenseLineUse.personal,
          selected: selected == _ExpenseLineUse.personal,
          color: const Color(0xFF5D666D),
          onSelected: onSelected,
        ),
        _ReceiptLineUseChip(
          label: 'Split',
          use: _ExpenseLineUse.split,
          selected: selected == _ExpenseLineUse.split,
          color: const Color(0xFF2E756C),
          onSelected: onSelected,
        ),
      ],
    );
  }
}

class _ReceiptLineUseChip extends StatelessWidget {
  const _ReceiptLineUseChip({
    required this.label,
    required this.use,
    required this.selected,
    required this.color,
    required this.onSelected,
  });

  final String label;
  final _ExpenseLineUse use;
  final bool selected;
  final Color color;
  final FutureOr<void> Function(_ExpenseLineUse use) onSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => unawaited(Future<void>.value(onSelected(use))),
      borderRadius: BorderRadius.circular(4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? color : const Color(0xFF172126),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: selected ? color : const Color(0xFF526168)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFFE8ECEE),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _LineButton extends StatelessWidget {
  const _LineButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  static const color = Color(0xFF34A9E8);

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: color, size: 15),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: color,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        minimumSize: const Size(0, 30),
        textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
      ),
    );
  }
}
