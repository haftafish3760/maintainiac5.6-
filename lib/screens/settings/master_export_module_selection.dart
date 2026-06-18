part of 'master_export_screen.dart';

class _ModuleSelectionPanel extends StatelessWidget {
  const _ModuleSelectionPanel({
    required this.includeExpenses,
    required this.expenseSnapshot,
    required this.expenseFilter,
    required this.onIncludeExpenses,
    required this.onExpenseFilter,
  });

  final bool includeExpenses;
  final ExpenseExportSnapshot expenseSnapshot;
  final ExpenseExportCategoryFilter expenseFilter;
  final ValueChanged<bool> onIncludeExpenses;
  final ValueChanged<ExpenseExportCategoryFilter> onExpenseFilter;

  @override
  Widget build(BuildContext context) {
    return _ExportPanel(
      title: 'What To Export',
      icon: Icons.inventory_2_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ModuleRow(
            title: 'Expenses',
            detail:
                '${expenseSnapshot.receiptCount} receipts | ${expenseSnapshot.lineCount} lines | ${_money(expenseSnapshot.total)}',
            value: includeExpenses,
            enabled: true,
            onChanged: onIncludeExpenses,
          ),
          if (includeExpenses) ...[
            const SizedBox(height: 8),
            DropdownButtonFormField<ExpenseExportCategoryFilter>(
              initialValue: expenseFilter,
              dropdownColor: const Color(0xFF101719),
              decoration: _inputDecoration('Expense Category Set'),
              items: [
                for (final item in ExpenseExportCategoryFilter.values)
                  DropdownMenuItem(value: item, child: Text(item.label)),
              ],
              style: const TextStyle(
                color: Color(0xFFE8ECEE),
                fontWeight: FontWeight.w900,
              ),
              onChanged: (value) {
                if (value == null) return;
                onExpenseFilter(value);
              },
            ),
          ],
          const SizedBox(height: 8),
          _ModuleRow(
            title: 'Materials / Inventory',
            detail: 'Coming after inventory export is connected here.',
            value: false,
            enabled: false,
            onChanged: (_) {},
          ),
          _ModuleRow(
            title: 'Maintenance',
            detail: 'Coming after maintenance records are finalized.',
            value: false,
            enabled: false,
            onChanged: (_) {},
          ),
          _ModuleRow(
            title: 'Invoices',
            detail: 'Coming after invoice records are finalized.',
            value: false,
            enabled: false,
            onChanged: (_) {},
          ),
        ],
      ),
    );
  }
}

class _ModuleRow extends StatelessWidget {
  const _ModuleRow({
    required this.title,
    required this.detail,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String title;
  final String detail;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFF0B1113) : const Color(0xFF151C1F),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF445159)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: enabled
                        ? const Color(0xFFE8ECEE)
                        : const Color(0xFF8F9A9D),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(
                    color: enabled
                        ? const Color(0xFFC8D0D3)
                        : const Color(0xFF727D82),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeThumbColor: const Color(0xFF58D67D),
          ),
        ],
      ),
    );
  }
}
