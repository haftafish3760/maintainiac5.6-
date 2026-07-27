part of 'expense_receipt_entry_screen.dart';

class _ManualReceiptHeader extends StatelessWidget {
  const _ManualReceiptHeader({
    required this.step,
    required this.onBack,
    required this.onStepSelected,
  });

  final _ManualReceiptStep step;
  final VoidCallback onBack;
  final ValueChanged<_ManualReceiptStep> onStepSelected;

  @override
  Widget build(BuildContext context) {
    const labels = ['Details', 'Items', 'Review'];
    final index = step.index;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                tooltip: index == 0 ? 'Leave receipt' : 'Previous step',
                icon: const Icon(Icons.arrow_back_rounded),
                color: const Color(0xFFE8ECEE),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Manual Receipt',
                      style: TextStyle(
                        color: Color(0xFFF2F7F8),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Step ${index + 1} of 3 · ${labels[index]}',
                      style: const TextStyle(
                        color: Color(0xFFB7C8CE),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var itemIndex = 0; itemIndex < labels.length; itemIndex++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: itemIndex == labels.length - 1 ? 0 : 6,
                    ),
                    child: _ManualReceiptStepButton(
                      label: labels[itemIndex],
                      step: _ManualReceiptStep.values[itemIndex],
                      selected: itemIndex == index,
                      completed: itemIndex < index,
                      enabled: itemIndex <= index,
                      onPressed: onStepSelected,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ManualReceiptStepButton extends StatelessWidget {
  const _ManualReceiptStepButton({
    required this.label,
    required this.step,
    required this.selected,
    required this.completed,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final _ManualReceiptStep step;
  final bool selected;
  final bool completed;
  final bool enabled;
  final ValueChanged<_ManualReceiptStep> onPressed;

  @override
  Widget build(BuildContext context) {
    final background = selected
        ? const Color(0xFFFFD166)
        : completed
        ? const Color(0xFF2D7A4B)
        : const Color(0xFF344247);
    final foreground = selected
        ? const Color(0xFF1F2528)
        : completed
        ? Colors.white
        : const Color(0xFFB7C8CE);
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: '$label step',
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: enabled ? () => onPressed(step) : null,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: foreground,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ManualReceiptActionTile extends StatelessWidget {
  const _ManualReceiptActionTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.actionLabel,
    this.color = const Color(0xFF8FC9FF),
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final String? actionLabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: enabled,
      label: '$label. $value',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              color: const Color(0xFF283337),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF41545B)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 22),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            color: Color(0xFFF2F7F8),
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          value,
                          style: const TextStyle(
                            color: Color(0xFFB7C8CE),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    actionLabel ?? 'Edit',
                    style: TextStyle(
                      color: enabled ? color : const Color(0xFF91A4AB),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: enabled ? color : const Color(0xFF91A4AB),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ManualReceiptPrimaryButton extends StatelessWidget {
  const _ManualReceiptPrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF28A745),
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(50),
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _ManualReceiptItemCard extends StatelessWidget {
  const _ManualReceiptItemCard({
    required this.lineNumber,
    required this.line,
    required this.onEdit,
    required this.onDelete,
    required this.onUseChanged,
  });

  final int lineNumber;
  final _ExpenseReceiptLine line;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<_ExpenseLineUse> onUseChanged;

  @override
  Widget build(BuildContext context) {
    final unitPrice = line.unitPrice;
    final quantityLabel = line.quantity == 1 && unitPrice == null
        ? ''
        : 'Qty ${line.quantityText}';
    final priceLabel = unitPrice == null ? '' : '${_money(unitPrice)} each';
    final category = line.category == 'Uncategorized'
        ? 'No category'
        : line.category;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF283337),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF41545B)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(13, 12, 8, 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF132B39),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    child: Text(
                      '$lineNumber',
                      style: const TextStyle(
                        color: Color(0xFF8FC9FF),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    line.displayDescription,
                    style: const TextStyle(
                      color: Color(0xFFF2F7F8),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  tooltip: 'Edit item $lineNumber',
                  icon: const Icon(Icons.edit_outlined),
                  color: const Color(0xFF8FC9FF),
                ),
                IconButton(
                  onPressed: onDelete,
                  tooltip: 'Delete item $lineNumber',
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: const Color(0xFFFF9B8E),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  child: Text(
                    [
                      quantityLabel,
                      priceLabel,
                    ].where((label) => label.isNotEmpty).join(' · '),
                    style: const TextStyle(
                      color: Color(0xFFB7C8CE),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  _money(line.subtotal),
                  style: const TextStyle(
                    color: Color(0xFFF2F7F8),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              category,
              style: const TextStyle(
                color: Color(0xFF91A4AB),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 5,
              children: [
                for (final use in const [
                  _ExpenseLineUse.business,
                  _ExpenseLineUse.personal,
                  _ExpenseLineUse.split,
                ])
                  _ManualReceiptUseButton(
                    use: use,
                    selected: line.use == use,
                    color: _colorForUse(use),
                    onPressed: () => onUseChanged(use),
                  ),
              ],
            ),
            if (line.use == _ExpenseLineUse.split) ...[
              const SizedBox(height: 7),
              Text(
                line.allocationDetail,
                style: const TextStyle(
                  color: Color(0xFFC8D0D3),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _colorForUse(_ExpenseLineUse use) => switch (use) {
    _ExpenseLineUse.business => const Color(0xFF2E78B7),
    _ExpenseLineUse.personal => const Color(0xFF59636A),
    _ExpenseLineUse.split => const Color(0xFF3B7C73),
    _ExpenseLineUse.unclassified => const Color(0xFF182226),
  };
}

class _ManualReceiptUseButton extends StatelessWidget {
  const _ManualReceiptUseButton({
    required this.use,
    required this.selected,
    required this.color,
    required this.onPressed,
  });

  final _ExpenseLineUse use;
  final bool selected;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${use.label} receipt line',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(5),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 34, minWidth: 86),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: selected ? color : const Color(0xFF182226),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: selected ? color : const Color(0xFF526168),
              ),
            ),
            child: Center(
              child: Text(
                use.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFFC8D0D3),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
