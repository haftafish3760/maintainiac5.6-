part of 'expense_receipt_entry_screen.dart';

class _ReceiptPaperLineRow extends StatelessWidget {
  const _ReceiptPaperLineRow({
    required this.lineNumber,
    required this.line,
    required this.showLineUseControls,
    required this.showItemDetails,
    required this.onEdit,
    required this.onSetUse,
    required this.onDelete,
  });

  final int lineNumber;
  final _ExpenseReceiptLine line;
  final bool showLineUseControls;
  final bool showItemDetails;
  final VoidCallback onEdit;
  final FutureOr<void> Function(_ExpenseLineUse use) onSetUse;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 26,
                child: Text(
                  '$lineNumber.',
                  style: const TextStyle(
                    color: Color(0xFF25211A),
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
                    Text(
                      showItemDetails
                          ? line.description
                          : 'Receipt line $lineNumber',
                      style: const TextStyle(
                        color: Color(0xFF25211A),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      showItemDetails
                          ? '${line.allocationSummary} | ${line.category} | ${line.packageSummary}'
                          : '${line.allocationSummary} | ${line.category}',
                      style: const TextStyle(
                        color: Color(0xFF62584C),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                    if (line.hasParserReview) ...[
                      const SizedBox(height: 3),
                      _ReceiptParserBadge(line: line),
                    ],
                    if (showLineUseControls) ...[
                      const SizedBox(height: 6),
                      _ReceiptLineUseSegment(
                        selected: line.use,
                        onSelected: onSetUse,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      line.allocationDetail,
                      style: const TextStyle(
                        color: Color(0xFF62584C),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
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
                      color: Color(0xFF25211A),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _LineButton(icon: Icons.edit_rounded, onTap: onEdit),
                      _LineButton(
                        icon: Icons.delete_outline_rounded,
                        color: Color(0xFFD85B4A),
                        onTap: onDelete,
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
          color: selected ? color : const Color(0x1A25211A),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: selected ? color : const Color(0x66756B5D)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF25211A),
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
    required this.icon,
    required this.onTap,
    this.color = const Color(0xFF34A9E8),
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: IconButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: color, size: 18),
      ),
    );
  }
}
