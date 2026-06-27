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
  ExpenseScreenTelemetryRecorder.record(
    context,
    ExpenseTelemetryEventType.editExpenseOpened,
    categoryGroup: receipt.lines.isEmpty ? null : receipt.lines.first.category,
  );
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

void _openReceiptDetailFromEntry(
  BuildContext context,
  _CalendarExpenseData entry,
) {
  Navigator.of(context).push(
    appNativeRoute<void>(
      context,
      ExpenseReceiptDetailScreen(receiptId: entry.receiptId),
    ),
  );
}

Future<void> _deleteReceipt(
  BuildContext context,
  ExpenseReceiptRecord receipt,
) async {
  ExpenseScreenTelemetryRecorder.record(
    context,
    ExpenseTelemetryEventType.deleteExpenseRequested,
    categoryGroup: receipt.lines.isEmpty ? null : receipt.lines.first.category,
  );
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
  try {
    await ExpenseLedgerScope.of(context).deleteReceipt(receipt.id);
  } catch (_) {
    if (context.mounted) {
      ExpenseScreenTelemetryRecorder.record(
        context,
        ExpenseTelemetryEventType.saveFailure,
        failureKind: 'calendar_delete_receipt_failed',
        diagnostic: const ExpenseFailureDiagnostic(
          workflowStep: ExpenseWorkflowStep.deleteExpense,
          failedAt: 'calendar_delete_receipt',
          confirmedCause: 'cause_not_confirmed_calendar_delete_receipt_failed',
          causeStatus: ExpenseFailureCauseStatus.notConfirmed,
          evidence: 'delete_receipt_threw_exception',
          missingEvidence: 'exception_type_and_hive_box_state',
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That receipt could not be deleted.')),
      );
    }
    return;
  }
  if (context.mounted) {
    ExpenseScreenTelemetryRecorder.record(
      context,
      ExpenseTelemetryEventType.deleteExpenseConfirmed,
      categoryGroup: receipt.lines.isEmpty
          ? null
          : receipt.lines.first.category,
    );
  }
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
  ExpenseScreenTelemetryRecorder.record(
    context,
    line == null
        ? ExpenseTelemetryEventType.categorySelected
        : ExpenseTelemetryEventType.categoryChanged,
    categoryGroup: savedLine.category,
  );
  final ledger = ExpenseLedgerScope.of(context);
  try {
    if (line == null) {
      final updated = receipt.copyWith(lines: [...receipt.lines, savedLine]);
      await ledger.saveReceipt(updated);
      return;
    }
    await ledger.replaceLine(receiptId: receipt.id, line: savedLine);
  } catch (_) {
    if (context.mounted) {
      ExpenseScreenTelemetryRecorder.record(
        context,
        ExpenseTelemetryEventType.saveFailure,
        failureKind: 'calendar_edit_line_failed',
        diagnostic: const ExpenseFailureDiagnostic(
          workflowStep: ExpenseWorkflowStep.calendarEdit,
          failedAt: 'calendar_receipt_line_save',
          confirmedCause: 'cause_not_confirmed_calendar_edit_line_failed',
          causeStatus: ExpenseFailureCauseStatus.notConfirmed,
          evidence: 'calendar_line_save_threw_exception',
          missingEvidence: 'exception_type_and_receipt_line_state',
        ),
        categoryGroup: savedLine.category,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That receipt line could not be saved.')),
      );
    }
  }
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
  try {
    await ExpenseLedgerScope.of(
      context,
    ).saveReceipt(receipt.copyWith(lines: [...receipt.lines, copy]));
  } catch (_) {
    if (context.mounted) {
      ExpenseScreenTelemetryRecorder.record(
        context,
        ExpenseTelemetryEventType.saveFailure,
        failureKind: 'calendar_copy_line_failed',
        diagnostic: const ExpenseFailureDiagnostic(
          workflowStep: ExpenseWorkflowStep.calendarEdit,
          failedAt: 'calendar_receipt_line_copy',
          confirmedCause: 'cause_not_confirmed_calendar_copy_line_failed',
          causeStatus: ExpenseFailureCauseStatus.notConfirmed,
          evidence: 'calendar_line_copy_threw_exception',
          missingEvidence: 'exception_type_and_receipt_line_state',
        ),
        categoryGroup: line.category,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That receipt line could not be copied.')),
      );
    }
  }
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
  try {
    await ExpenseLedgerScope.of(
      context,
    ).deleteLine(receiptId: receipt.id, lineId: line.id);
  } catch (_) {
    if (context.mounted) {
      ExpenseScreenTelemetryRecorder.record(
        context,
        ExpenseTelemetryEventType.saveFailure,
        failureKind: 'calendar_delete_line_failed',
        diagnostic: const ExpenseFailureDiagnostic(
          workflowStep: ExpenseWorkflowStep.deleteExpense,
          failedAt: 'calendar_receipt_line_delete',
          confirmedCause: 'cause_not_confirmed_calendar_delete_line_failed',
          causeStatus: ExpenseFailureCauseStatus.notConfirmed,
          evidence: 'delete_line_threw_exception',
          missingEvidence: 'exception_type_and_receipt_line_state',
        ),
        categoryGroup: line.category,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('That receipt line could not be deleted.'),
        ),
      );
    }
  }
}
