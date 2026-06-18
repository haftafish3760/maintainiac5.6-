part of 'expense_export_screen.dart';

class _ExportHeader extends StatelessWidget {
  const _ExportHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const AppBackButton(),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Export Expenses',
                style: TextStyle(
                  color: Color(0xFFE8ECEE),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Choose the date range and category set before generating files.',
                style: TextStyle(
                  color: Color(0xFFC8D0D3),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LastExportPanel extends StatelessWidget {
  const _LastExportPanel({required this.lastExport});

  final ExpenseExportRecord? lastExport;

  @override
  Widget build(BuildContext context) {
    return _ExportPanel(
      title: 'Last Export',
      icon: Icons.history_rounded,
      child: Text(
        lastExport == null
            ? 'No expense export has been recorded yet.'
            : '${_fullDateTime(lastExport!.exportedAt)} | ${lastExport!.lineCount} lines | ${_money(lastExport!.total)}',
        style: const TextStyle(
          color: Color(0xFFE8ECEE),
          fontSize: 14,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _ExportRangePanel extends StatelessWidget {
  const _ExportRangePanel({
    required this.preset,
    required this.from,
    required this.to,
    required this.lastExport,
    required this.onPresetChanged,
    required this.onPickFrom,
    required this.onPickTo,
  });

  final ExpenseExportRangePreset preset;
  final DateTime from;
  final DateTime to;
  final ExpenseExportRecord? lastExport;
  final ValueChanged<ExpenseExportRangePreset> onPresetChanged;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;

  @override
  Widget build(BuildContext context) {
    return _ExportPanel(
      title: 'Date Range',
      icon: Icons.date_range_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final value in ExpenseExportRangePreset.values)
                ChoiceChip(
                  selected: preset == value,
                  label: Text(value.label),
                  onSelected: (_) => onPresetChanged(value),
                  selectedColor: const Color(0xFFFFD166),
                  backgroundColor: const Color(0xFF0B1113),
                  labelStyle: TextStyle(
                    color: preset == value
                        ? const Color(0xFF101416)
                        : const Color(0xFFE8ECEE),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _DateButton(
                  label: 'From',
                  value: _shortDate(from),
                  onTap: onPickFrom,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DateButton(
                  label: 'To',
                  value: _shortDate(to),
                  onTap: onPickTo,
                ),
              ),
            ],
          ),
          if (lastExport != null) ...[
            const SizedBox(height: 8),
            Text(
              'Last exported ${_fullDateTime(lastExport!.exportedAt)}.',
              style: const TextStyle(
                color: Color(0xFFC8D0D3),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
