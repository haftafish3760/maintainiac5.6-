part of 'active_workday_screen.dart';

class _WorkdayContextBar extends StatelessWidget {
  const _WorkdayContextBar({required this.workProfileName});

  final String workProfileName;

  @override
  Widget build(BuildContext context) {
    return VehicleProfilePanel(
      label: 'WORK PROFILE',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
        child: Row(
          children: [
            const Icon(
              Icons.work_outline_rounded,
              size: 20,
              color: Color(0xFFEAF2F5),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                workProfileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFEAF2F5),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const Icon(
              Icons.lock_outline_rounded,
              size: 18,
              color: Color(0xFFC9D9E0),
            ),
          ],
        ),
      ),
    );
  }
}
