part of 'expense_calendar.dart';

class _SmallCalendarButton extends StatelessWidget {
  const _SmallCalendarButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF2E78B7),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 7, 9, 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _editFullReceipt(
  BuildContext context,
  ExpenseReceiptRecord receipt,
) async {
  await Navigator.of(context).push(
    appNativeRoute<void>(
      context,
      ExpenseReceiptEntryScreen(
        mode: receipt.sourceScreen == 'materials_expense_receipt'
            ? ExpenseReceiptFlowMode.materials
            : ExpenseReceiptFlowMode.general,
        initialCategory: receipt.lines.isEmpty
            ? null
            : receipt.lines.first.category,
        initialDate: receipt.receiptDate,
        receiptId: receipt.id,
      ),
    ),
  );
}

void _openReceiptFormFromEntry(
  BuildContext context,
  _CalendarExpenseData entry,
) {
  Navigator.of(context).push(
    appNativeRoute<void>(
      context,
      ExpenseReceiptEntryScreen(
        initialCategory: entry.category,
        initialDate: entry.date,
        receiptId: entry.receiptId,
      ),
    ),
  );
}

Future<void> _deleteReceipt(
  BuildContext context,
  ExpenseReceiptRecord receipt,
) async {
  final remove = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF101719),
      title: const Text(
        'Delete receipt?',
        style: TextStyle(color: Color(0xFFF0F4F2), fontWeight: FontWeight.w900),
      ),
      content: Text(
        'This removes ${receipt.title} and all ${receipt.lines.length} receipt lines.',
        style: const TextStyle(
          color: Color(0xFFC8D0D3),
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (remove != true || !context.mounted) return;
  await ExpenseLedgerScope.of(context).deleteReceipt(receipt.id);
  if (context.mounted) Navigator.of(context).maybePop();
}

Future<void> _editReceiptLine(
  BuildContext context, {
  required ExpenseReceiptRecord receipt,
  required ExpenseReceiptLineRecord? line,
}) async {
  final lineNumber = line == null
      ? receipt.lines.length + 1
      : receipt.lines.indexWhere((current) => current.id == line.id) + 1;
  final savedLine = await showExpenseReceiptLineEditor(
    context,
    line: line,
    lineNumber: lineNumber <= 0 ? receipt.lines.length + 1 : lineNumber,
  );
  if (savedLine == null || !context.mounted) return;
  final ledger = ExpenseLedgerScope.of(context);
  if (line == null) {
    final updated = receipt.copyWith(lines: [...receipt.lines, savedLine]);
    await ledger.saveReceipt(updated);
    return;
  }
  await ledger.replaceLine(receiptId: receipt.id, line: savedLine);
}

Future<void> _copyReceiptLine(
  BuildContext context, {
  required ExpenseReceiptRecord receipt,
  required ExpenseReceiptLineRecord line,
}) async {
  final copy = ExpenseReceiptLineRecord(
    id: 'EXPL-${DateTime.now().microsecondsSinceEpoch}',
    description: line.description,
    category: line.category,
    use: line.use,
    businessPercent: line.businessPercent,
    quantity: line.quantity,
    unitsPerPackage: line.unitsPerPackage,
    unit: line.unit,
    subtotal: line.subtotal,
    odometerReading: line.odometerReading,
    fuelType: line.fuelType,
    fillType: line.fillType,
    unitPrice: line.unitPrice,
  );
  await ExpenseLedgerScope.of(
    context,
  ).saveReceipt(receipt.copyWith(lines: [...receipt.lines, copy]));
}

Future<void> _deleteReceiptLine(
  BuildContext context, {
  required ExpenseReceiptRecord receipt,
  required ExpenseReceiptLineRecord line,
}) async {
  final remove = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF101719),
      title: const Text(
        'Delete receipt line?',
        style: TextStyle(color: Color(0xFFF0F4F2), fontWeight: FontWeight.w900),
      ),
      content: Text(
        line.description,
        style: const TextStyle(
          color: Color(0xFFC8D0D3),
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (remove != true || !context.mounted) return;
  await ExpenseLedgerScope.of(
    context,
  ).deleteLine(receiptId: receipt.id, lineId: line.id);
}
