part of 'expense_receipt_entry_screen.dart';

Future<ExpenseReceiptLineRecord?> showExpenseReceiptLineEditor(
  BuildContext context, {
  required ExpenseReceiptLineRecord? line,
  required int lineNumber,
  ExpenseLineUse defaultUse = ExpenseLineUse.business,
  String defaultCategory = 'Uncategorized',
}) async {
  final initial = line == null
      ? _ExpenseReceiptLine.blank(
          use: switch (defaultUse) {
            ExpenseLineUse.business => _ExpenseLineUse.business,
            ExpenseLineUse.personal => _ExpenseLineUse.personal,
            ExpenseLineUse.split => _ExpenseLineUse.split,
            ExpenseLineUse.unclassified => _ExpenseLineUse.unclassified,
          },
          category: defaultCategory,
        )
      : _ExpenseReceiptLine.fromLedgerLine(line);
  final edited = await showModalBottomSheet<_ExpenseReceiptLine>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1F2528),
    builder: (context) =>
        _ReceiptLineEditorSheet(initial: initial, lineNumber: lineNumber),
  );
  if (edited == null) return null;
  return edited.toLedgerLine(
    id: line?.id ?? 'EXPL-${DateTime.now().microsecondsSinceEpoch}',
  );
}
