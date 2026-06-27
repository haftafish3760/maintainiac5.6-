part of 'maintenance_screen.dart';

class _MaintenanceDraftPanel extends StatefulWidget {
  const _MaintenanceDraftPanel({
    required this.activeVehicle,
    required this.records,
  });

  final VehicleProfile? activeVehicle;
  final List<MaintenanceRecord> records;

  @override
  State<_MaintenanceDraftPanel> createState() => _MaintenanceDraftPanelState();
}

class _MaintenanceDraftPanelState extends State<_MaintenanceDraftPanel> {
  late Future<List<MaintenanceDraftSummary>> _draftsFuture;

  @override
  void initState() {
    super.initState();
    _draftsFuture = _loadDrafts();
  }

  @override
  void didUpdateWidget(covariant _MaintenanceDraftPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeVehicle?.nickname != widget.activeVehicle?.nickname) {
      _draftsFuture = _loadDrafts();
    }
  }

  Future<List<MaintenanceDraftSummary>> _loadDrafts() {
    return MaintenanceDraftStore.loadDrafts(
      vehicleName: widget.activeVehicle?.nickname,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MaintenanceDraftSummary>>(
      future: _draftsFuture,
      builder: (context, snapshot) {
        final drafts = snapshot.data ?? const <MaintenanceDraftSummary>[];
        if (drafts.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(2, 0, 2, 8),
              child: Text(
                'Unfinished Maintenance',
                style: TextStyle(
                  color: Color(0xFFE7EEF1),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            for (final draft in drafts.take(2)) ...[
              _MaintenanceDraftRow(
                draft: draft,
                onTap: () => _openDraft(context, draft),
              ),
              if (draft != drafts.take(2).last) const SizedBox(height: 7),
            ],
          ],
        );
      },
    );
  }

  void _openDraft(BuildContext context, MaintenanceDraftSummary draft) {
    if (draft.kind == 'Setup draft') {
      final record = widget.records.where(
        (item) => item.itemName == draft.title,
      );
      if (record.isEmpty) return;
      Navigator.of(context).push(
        appNativeRoute<void>(
          context,
          MaintenanceItemDetailScreen(record: record.first),
        ),
      );
      return;
    }
    if (widget.records.isEmpty) return;
    Navigator.of(context).push(
      appNativeRoute<void>(
        context,
        MaintenanceLogServiceScreen(records: widget.records),
      ),
    );
  }
}

class _MaintenanceDraftRow extends StatelessWidget {
  const _MaintenanceDraftRow({required this.draft, required this.onTap});

  final MaintenanceDraftSummary draft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
            color: const Color(0xFF111719),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.orange),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.edit_note_rounded,
                color: AppColors.orange,
                size: 24,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      draft.kind,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      draft.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFE2E8EA),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        height: 1.08,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _draftAgeLabel(draft.updatedAt),
                style: const TextStyle(
                  color: Color(0xFFC8D2D6),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFC8D2D6),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _draftAgeLabel(DateTime updatedAt) {
    final minutes = DateTime.now().difference(updatedAt).inMinutes;
    if (minutes < 1) return 'just now';
    if (minutes < 60) return '${minutes}m ago';
    final hours = minutes ~/ 60;
    if (hours < 24) return '${hours}h ago';
    return '${hours ~/ 24}d ago';
  }
}
