part of 'active_workday_screen.dart';

class _WorkdayContextBar extends StatelessWidget {
  const _WorkdayContextBar({
    required this.activeVehicle,
    required this.workProfileName,
    required this.onVehicleChanged,
  });

  final VehicleProfilePreview activeVehicle;
  final String workProfileName;
  final ValueChanged<VehicleProfilePreview> onVehicleChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _WorkProfilePanel(workProfileName: workProfileName)),
        const SizedBox(width: 8),
        Expanded(
          child: ActiveVehicleDrawer(
            activeVehicle: activeVehicle,
            onChanged: onVehicleChanged,
            fullWidth: true,
          ),
        ),
      ],
    );
  }
}

class _WorkProfilePanel extends StatelessWidget {
  const _WorkProfilePanel({required this.workProfileName});

  final String workProfileName;

  @override
  Widget build(BuildContext context) {
    return VehicleProfilePanel(
      label: 'WORK PROFILE',
      child: InkWell(
        onTap: () => _openWorkProfiles(context),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 7, 8),
          child: Row(
            children: [
              const Text('💼', style: TextStyle(fontSize: 18, height: 1)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  workProfileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF101416),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _openWorkProfiles(BuildContext context) {
    _openFlow(
      context,
      title: 'Work Profiles',
      icon: Icons.work_rounded,
      summary:
          'Work profiles keep jobs, contracts, or business lines separated while preserving the active day workflow.',
      requiresOdometer: false,
    );
  }
}
