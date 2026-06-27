part of 'maintenance_screen.dart';

class _MaintenanceActionGrid extends StatelessWidget {
  const _MaintenanceActionGrid({required this.records});

  final List<MaintenanceRecord> records;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionSpec(
        'Set Up Items',
        Icons.playlist_add_check_rounded,
        AppActionColors.positive,
        () => Navigator.of(context).push(
          appNativeRoute<void>(context, const MaintenanceWorkSourceScreen()),
        ),
      ),
      _ActionSpec(
        'Log Service',
        Icons.build_circle_outlined,
        AppActionColors.primary,
        () => _openServiceLog(context),
      ),
      _ActionSpec(
        'Log Next',
        Icons.flash_on_rounded,
        AppActionColors.primary,
        () => _quickLogNext(context),
      ),
    ];

    return Row(
      children: [
        for (var index = 0; index < actions.length; index++) ...[
          Expanded(
            child: _FlowButton(
              label: actions[index].label,
              icon: actions[index].icon,
              color: actions[index].color,
              onPressed: actions[index].onPressed,
            ),
          ),
          if (index != actions.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }

  void _openServiceLog(BuildContext context) {
    if (records.isEmpty) {
      _showTrackItemsFirst(context);
      return;
    }
    Navigator.of(context).push(
      appNativeRoute<void>(
        context,
        MaintenanceLogServiceScreen(records: records),
      ),
    );
  }

  void _quickLogNext(BuildContext context) {
    if (records.isEmpty) {
      _showTrackItemsFirst(context);
      return;
    }
    Navigator.of(context).push(
      appNativeRoute<void>(
        context,
        MaintenanceLogServiceScreen(records: [records.first]),
      ),
    );
  }

  void _showTrackItemsFirst(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Track at least one maintenance item first.'),
      ),
    );
  }
}

class _FlowButton extends StatelessWidget {
  const _FlowButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 46),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        tapTargetSize: MaterialTapTargetSize.padded,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 6),
          Flexible(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class _ActionSpec {
  const _ActionSpec(this.label, this.icon, this.color, this.onPressed);

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
}
