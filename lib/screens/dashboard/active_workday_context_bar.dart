part of 'active_workday_screen.dart';

class _WorkdayContextBar extends StatelessWidget {
  const _WorkdayContextBar({
    required this.workProfileName,
    required this.onChangeContext,
  });

  final String workProfileName;
  final VoidCallback onChangeContext;

  @override
  Widget build(BuildContext context) {
    final session = ActiveWorkdayScope.of(context).activeSession;
    final activeContext = session?.currentContextSegment;
    final vehicleLabel = activeContext?.vehicleLabel ?? 'Active vehicle';
    final profileLabel = activeContext == null
        ? workProfileName
        : activeContext.workProfileId == workProfileName
        ? workProfileName
        : '$workProfileName • ${activeContext.workProfileId}';
    return VehicleProfilePanel(
      label: 'WORKDAY CONTEXT',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
        child: Row(
          children: [
            const Icon(
              Icons.directions_car_filled_rounded,
              size: 20,
              color: Color(0xFFEAF2F5),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    vehicleLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFEAF2F5),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    profileLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFB9C9CF),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Change vehicle or work profile',
              onPressed: onChangeContext,
              icon: const Icon(
                Icons.swap_horiz_rounded,
                color: Color(0xFFEAF2F5),
              ),
            ),
            IconButton(
              tooltip: 'Open contractor dashboard',
              onPressed: () => Navigator.of(context).push(
                appNativeRoute<void>(
                  context,
                  const ContractorDashboardScreen(),
                ),
              ),
              icon: const Icon(
                Icons.dashboard_customize_rounded,
                color: Color(0xFF7CC7FF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
