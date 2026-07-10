part of 'expense_export_screen.dart';

class _ExportCategoryPanel extends StatelessWidget {
  const _ExportCategoryPanel({required this.value, required this.onChanged});

  final ExpenseExportCategoryFilter value;
  final ValueChanged<ExpenseExportCategoryFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return _ExportPanel(
      title: 'Export Categories',
      icon: Icons.category_rounded,
      child: DropdownButtonFormField<ExpenseExportCategoryFilter>(
        initialValue: value,
        dropdownColor: const Color(0xFF101719),
        decoration: _inputDecoration('Category Set'),
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
          onChanged(value);
        },
      ),
    );
  }
}

class _ExportDestinationPanel extends StatelessWidget {
  const _ExportDestinationPanel({required this.value, required this.onChanged});

  final ExpenseExportDestination value;
  final ValueChanged<ExpenseExportDestination> onChanged;

  @override
  Widget build(BuildContext context) {
    return _ExportPanel(
      title: 'Export Destination',
      icon: Icons.ios_share_rounded,
      child: Wrap(
        spacing: 7,
        runSpacing: 7,
        children: [
          for (final destination in ExpenseExportDestination.values)
            ChoiceChip(
              selected: value == destination,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _destinationIcon(destination),
                    size: 17,
                    color: value == destination
                        ? const Color(0xFF101416)
                        : const Color(0xFFE8ECEE),
                  ),
                  const SizedBox(width: 5),
                  Text(destination.label),
                ],
              ),
              onSelected: (_) => onChanged(destination),
              selectedColor: const Color(0xFFFFD166),
              backgroundColor: const Color(0xFF0B1113),
              labelStyle: TextStyle(
                color: value == destination
                    ? const Color(0xFF101416)
                    : const Color(0xFFE8ECEE),
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
        ],
      ),
    );
  }
}

class _ExportPreviewPanel extends StatelessWidget {
  const _ExportPreviewPanel({
    required this.snapshot,
    required this.pdfEstimate,
    required this.canExport,
    required this.cloudUsedThisMonth,
    required this.onExport,
  });

  final ExpenseExportSnapshot snapshot;
  final AppGeneratedPdfExportEstimate pdfEstimate;
  final bool canExport;
  final int cloudUsedThisMonth;
  final VoidCallback? onExport;

  @override
  Widget build(BuildContext context) {
    return _ExportPanel(
      title: 'Export Preview',
      icon: Icons.file_download_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _PreviewStat(
                  label: 'Receipts',
                  value: '${snapshot.receiptCount}',
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _PreviewStat(
                  label: 'Lines',
                  value: '${snapshot.lineCount}',
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _PreviewStat(
                  label: 'Total',
                  value: _money(snapshot.total),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'PDF summary estimate: ${_formatBytes(pdfEstimate.estimatedPdfBytes)}',
            style: const TextStyle(
              color: Color(0xFFE8ECEE),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            snapshot.source == ExpenseExportSource.localDevice
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
                  ? 'Generate Expense Export'
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

  String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).ceil()} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
