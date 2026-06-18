part of 'master_export_screen.dart';

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

class _ExportSourcePanel extends StatelessWidget {
  const _ExportSourcePanel({required this.value, required this.onChanged});

  final ExpenseExportSource value;
  final ValueChanged<ExpenseExportSource> onChanged;

  @override
  Widget build(BuildContext context) {
    return _ExportPanel(
      title: 'Export Source',
      icon: Icons.storage_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ExportSourceRow(
            title: 'Local Device',
            detail:
                'Unlimited. Exports records saved on this device without backup-service reads.',
            icon: Icons.smartphone_rounded,
            selected: value == ExpenseExportSource.localDevice,
            enabled: true,
            onTap: () => onChanged(ExpenseExportSource.localDevice),
          ),
          const SizedBox(height: 7),
          _ExportSourceRow(
            title: 'Backed-Up Data',
            detail:
                'Coming after backup is connected. This covers iCloud, Google Drive, or app cloud backup exports that may use backend reads.',
            icon: Icons.cloud_download_rounded,
            selected: value == ExpenseExportSource.cloudBackup,
            enabled: false,
            onTap: () => onChanged(ExpenseExportSource.cloudBackup),
          ),
        ],
      ),
    );
  }
}

class _ExportSourceRow extends StatelessWidget {
  const _ExportSourceRow({
    required this.title,
    required this.detail,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final String detail;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = selected ? const Color(0xFFFFD166) : const Color(0xFF728188);
    return Material(
      color: enabled ? const Color(0xFF0B1113) : const Color(0xFF151C1F),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected ? accent : const Color(0xFF445159),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: accent, size: 21),
              const SizedBox(width: 9),
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
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: enabled ? accent : const Color(0xFF727D82),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
