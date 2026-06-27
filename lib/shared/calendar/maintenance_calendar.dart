import 'package:flutter/widgets.dart';

import '../state/app_state.dart';
import 'app_month_calendar.dart';
import 'calendar_flow_models.dart';

class MaintenanceCalendar extends StatelessWidget {
  const MaintenanceCalendar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return AppMonthCalendar(
      source: CalendarFlowSource.maintenance,
      dayEntryCounts: _maintenanceEntryCounts(state.maintenanceEvents),
    );
  }
}

Map<DateTime, int> _maintenanceEntryCounts(
  List<MaintenanceServiceEvent> events,
) {
  final counts = <DateTime, int>{};
  for (final event in events) {
    final day = DateTime.utc(
      event.serviceDate.year,
      event.serviceDate.month,
      event.serviceDate.day,
    );
    counts[day] = (counts[day] ?? 0) + 1;
  }
  return counts;
}
