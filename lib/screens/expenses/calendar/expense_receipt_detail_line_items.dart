part of 'expense_calendar.dart';

class _ReceiptLineItemsPanel extends StatelessWidget {
  const _ReceiptLineItemsPanel({required this.receipt, required this.entry});

  final ExpenseReceiptRecord receipt;
  final _CalendarExpenseData entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF101719),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF445159)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Receipt line items',
                  style: TextStyle(
                    color: Color(0xFFF0F4F2),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
              _SmallCalendarButton(
                label: 'Add Line',
                icon: Icons.add_rounded,
                onTap: () =>
                    _editReceiptLine(context, receipt: receipt, line: null),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (var index = 0; index < entry.lines.length; index++) ...[
            _ReceiptLineRow(
              number: index + 1,
              line: entry.lines[index],
              onEdit: () => _editReceiptLine(
                context,
                receipt: receipt,
                line: receipt.lines[index],
              ),
              onCopy: () => _copyReceiptLine(
                context,
                receipt: receipt,
                line: receipt.lines[index],
              ),
              onDelete: () => _deleteReceiptLine(
                context,
                receipt: receipt,
                line: receipt.lines[index],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _ReceiptLineRow extends StatelessWidget {
  const _ReceiptLineRow({
    required this.number,
    required this.line,
    required this.onEdit,
    required this.onCopy,
    required this.onDelete,
  });

  final int number;
  final _ReceiptLineData line;
  final VoidCallback onEdit;
  final VoidCallback onCopy;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1A2226),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onEdit,
        onLongPress: () => _showReceiptLineActions(
          context,
          onEdit: onEdit,
          onCopy: onCopy,
          onDelete: onDelete,
        ),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 6, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF3E4A50)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: Color(0xFFFFD166),
                    fontSize: 13,
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
                      line.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFF0F4F2),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${line.scope} | ${line.category} | ${line.quantityLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFC8D0D3),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
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
                    _money(line.total),
                    style: const TextStyle(
                      color: Color(0xFFFFD166),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: IconButton(
                      tooltip: 'Line actions',
                      onPressed: () => _showReceiptLineActions(
                        context,
                        onEdit: onEdit,
                        onCopy: onCopy,
                        onDelete: onDelete,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 36,
                        height: 36,
                      ),
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        color: Color(0xFFE8ECEE),
                        size: 22,
                      ),
                    ),
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

Future<void> _showReceiptLineActions(
  BuildContext context, {
  required VoidCallback onEdit,
  required VoidCallback onCopy,
  required VoidCallback onDelete,
}) async {
  final action = await showModalBottomSheet<_ReceiptLineAction>(
    context: context,
    backgroundColor: const Color(0xFF101719),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ReceiptLineActionTile(
              icon: Icons.edit_rounded,
              label: 'Edit Line',
              value: _ReceiptLineAction.edit,
            ),
            _ReceiptLineActionTile(
              icon: Icons.content_copy_rounded,
              label: 'Copy Line',
              value: _ReceiptLineAction.copy,
            ),
            _ReceiptLineActionTile(
              icon: Icons.delete_outline_rounded,
              label: 'Delete Line',
              value: _ReceiptLineAction.delete,
              danger: true,
            ),
          ],
        ),
      ),
    ),
  );
  if (!context.mounted || action == null) return;
  switch (action) {
    case _ReceiptLineAction.edit:
      onEdit();
    case _ReceiptLineAction.copy:
      onCopy();
    case _ReceiptLineAction.delete:
      onDelete();
  }
}

enum _ReceiptLineAction { edit, copy, delete }

class _ReceiptLineActionTile extends StatelessWidget {
  const _ReceiptLineActionTile({
    required this.icon,
    required this.label,
    required this.value,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final _ReceiptLineAction value;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? _red : const Color(0xFFE8ECEE);
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
      onTap: () => Navigator.of(context).pop(value),
    );
  }
}
