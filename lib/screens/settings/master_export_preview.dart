part of 'master_export_screen.dart';

class _MasterExportPreviewPanel extends StatelessWidget {
  const _MasterExportPreviewPanel({
    required this.expenseSnapshot,
    required this.includeExpenses,
    required this.fileCount,
    required this.canExport,
    required this.cloudUsedThisMonth,
    required this.onExport,
  });

  final ExpenseExportSnapshot expenseSnapshot;
  final bool includeExpenses;
  final int fileCount;
  final bool canExport;
  final int cloudUsedThisMonth;
  final VoidCallback? onExport;

  @override
  Widget build(BuildContext context) {
    final totalLines = includeExpenses ? expenseSnapshot.lineCount : 0;
    final total = includeExpenses ? expenseSnapshot.total : 0.0;
    return _ExportPanel(
      title: 'Export Preview',
      icon: Icons.file_download_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _PreviewStat(label: 'Files', value: '$fileCount'),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _PreviewStat(label: 'Lines', value: '$totalLines'),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _PreviewStat(label: 'Total', value: _money(total)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            expenseSnapshot.source == ExpenseExportSource.localDevice
                ? 'Local device export. Unlimited and does not use backup-service reads.'
                : canExport
                ? 'Free monthly backed-up data export available.'
                : 'Monthly free backed-up data export already used. Local exports are still unlimited.',
            style: TextStyle(
              color: canExport
                  ? const Color(0xFF58D67D)
                  : const Color(0xFFFFD166),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Cloud backup exports used this month: $cloudUsedThisMonth',
            style: const TextStyle(
              color: Color(0xFFC8D0D3),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: onExport,
            icon: const Icon(Icons.file_download_done_rounded),
            label: Text(
              canExport
                  ? 'Generate Selected Export'
                  : 'Cloud Export Limit Reached',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF28A745),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewStat extends StatelessWidget {
  const _PreviewStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1113),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF445159)),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFFFD166),
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFC8D0D3),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
