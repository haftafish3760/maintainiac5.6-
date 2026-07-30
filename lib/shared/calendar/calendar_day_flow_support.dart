// Calendar day-flow support. Presentation helpers only; source modules retain data ownership.
import 'package:flutter/material.dart';
import '../context/operational_context_store.dart';
import '../navigation/app_page_routes.dart';
import '../state/app_state.dart';
import '../widgets/app_screen_shell.dart';
import 'calendar_flow_models.dart';
import 'calendar_month_projection_reader.dart';
import 'calendar_maintenance_due_projection_adapter.dart';
import 'calendar_maintenance_projection_adapter.dart';
import 'calendar_recap_screen.dart';
import 'month_year_picker.dart';

CalendarDayData calendarFilterToActiveContext(
  BuildContext context,
  CalendarDayData data,
) {
  final active = OperationalContextScope.maybeOf(context)?.context;
  if (active == null) return data;
  final entries = data.entries
      .where((entry) {
        final event = entry.projection;
        return event == null ||
            ((event.vehicleIds.isEmpty ||
                    event.vehicleIds.contains(active.activeVehicleId)) &&
                (event.workProfileId == null ||
                    event.workProfileId == active.workProfileId));
      })
      .toList(growable: false);
  if (entries.length == data.entries.length) return data;
  return CalendarDayData(
    recapItems: [
      CalendarRecapItem(label: 'Visible records', value: '${entries.length}'),
      CalendarRecapItem(
        label: 'Other context',
        value: '${data.entries.length - entries.length}',
      ),
    ],
    entries: entries,
  );
}

/// Adds Calendar-owned appointments to a source-specific day view without
/// duplicating its source records. The Dashboard already reads all projections.
CalendarDayData calendarDataWithSchedules(
  BuildContext context,
  CalendarDayData sourceData,
  CalendarFlowSource source,
  DateTime day,
) {
  final schedules = CalendarMonthProjectionReader.calendarScheduleEventsForDay(
    context,
    source,
    day,
  );
  if (schedules.isEmpty) return sourceData;
  final entries = [
    ...sourceData.entries,
    for (final event in schedules) CalendarTimelineEntry.fromProjection(event),
  ]..sort((left, right) => left.timestamp.compareTo(right.timestamp));
  return CalendarDayData(recapItems: sourceData.recapItems, entries: entries);
}

AppSection calendarAppSectionFor(CalendarFlowSource source) => switch (source) {
  CalendarFlowSource.expenses => AppSection.expenses,
  CalendarFlowSource.invoices => AppSection.invoices,
  CalendarFlowSource.maintenance => AppSection.maintenance,
  CalendarFlowSource.jobs => AppSection.materials,
  CalendarFlowSource.materials => AppSection.materials,
  _ => AppSection.dashboard,
};

String calendarScreenTitle(CalendarFlowSource source) => switch (source) {
  CalendarFlowSource.expenses => 'Expense Calendar',
  CalendarFlowSource.maintenance => 'Maintenance Calendar',
  CalendarFlowSource.contractor => 'Contractor Calendar',
  CalendarFlowSource.jobs => 'Jobs Calendar',
  CalendarFlowSource.materials => 'Materials Calendar',
  CalendarFlowSource.employee => 'Employee Calendar',
  _ => 'Calendar',
};

/// Calendar presentation of the shared operating context. Vehicle and profile
/// selection remains owned by their established screens; Calendar only makes
/// the active scope explicit before projecting source-owned records.
class CalendarActiveContextStrip extends StatelessWidget {
  const CalendarActiveContextStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = OperationalContextScope.maybeOf(context);
    if (controller == null) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final active = controller.context;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF101719),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF445159)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _CalendarContextValue(
                  icon: Icons.directions_car_filled_rounded,
                  label: 'VEHICLE',
                  value: active.activeVehicleLabel,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CalendarContextValue(
                  icon: Icons.badge_rounded,
                  label: 'WORK PROFILE',
                  value: active.workProfileName,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CalendarContextValue extends StatelessWidget {
  const _CalendarContextValue({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: const Color(0xFF65B8FF), size: 18),
      const SizedBox(width: 6),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFB7C4CA),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
            Text(
              value,
              softWrap: true,
              style: const TextStyle(
                color: Color(0xFFE8ECEE),
                fontSize: 13,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

void calendarOpenRecap(
  BuildContext context,
  DateTime day,
  CalendarFlowSource source, [
  String? employeeId,
]) {
  Navigator.of(context).push(
    appNativeRoute<void>(
      context,
      CalendarRecapScreen(
        anchorDay: day,
        source: source,
        employeeId: employeeId,
      ),
    ),
  );
}

CalendarDayData calendarMaintenanceDataFor(BuildContext context, DateTime day) {
  final state = AppStateScope.of(context);
  final normalized = DateUtils.dateOnly(day);
  final events =
      state.maintenanceEvents
          .where((e) => DateUtils.isSameDay(e.serviceDate, normalized))
          .toList()
        ..sort((a, b) => a.serviceDate.compareTo(b.serviceDate));
  final cost = events.fold<double>(0, (sum, e) => sum + e.totalCost);
  final proofs = events.fold<int>(0, (sum, e) => sum + e.receiptProofCount);
  return CalendarDayData(
    recapItems: [
      CalendarRecapItem(label: 'Services', value: '${events.length}'),
      CalendarRecapItem(
        label: 'Vehicles',
        value: '${events.map((e) => e.vehicleName).toSet().length}',
      ),
      CalendarRecapItem(label: 'Receipts', value: '$proofs'),
      CalendarRecapItem(
        label: 'Cost',
        value: cost <= 0 ? r'$0' : '\$${cost.toStringAsFixed(2)}',
      ),
    ],
    entries: [
      for (final e in CalendarMaintenanceProjectionAdapter.eventsForDay(
        events,
        normalized,
      ))
        CalendarTimelineEntry.fromProjection(e),
      for (final e in CalendarMaintenanceDueProjectionAdapter.eventsForDay(
        state.allMaintenanceRecords,
        normalized,
      ))
        CalendarTimelineEntry.fromProjection(e),
    ],
  );
}

class CalendarDayNavigation extends StatelessWidget {
  const CalendarDayNavigation({
    super.key,
    required this.day,
    required this.onPreviousDay,
    required this.onNextDay,
    required this.onPickDate,
  });
  final DateTime day;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;
  final VoidCallback onPickDate;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
    decoration: BoxDecoration(
      color: const Color(0xFF101719),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFF445159)),
    ),
    child: Row(
      children: [
        IconButton(
          tooltip: 'Previous day',
          onPressed: onPreviousDay,
          icon: const Icon(
            Icons.chevron_left_rounded,
            color: Color(0xFFE2E8EA),
          ),
        ),
        Expanded(
          child: Semantics(
            button: true,
            label: 'Select calendar date ${calendarFullDateLabel(day)}',
            child: TextButton(
              onPressed: onPickDate,
              child: Text(
                calendarFullDateLabel(day),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFE8ECEE),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Next day',
          onPressed: onNextDay,
          icon: const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFFE2E8EA),
          ),
        ),
      ],
    ),
  );
}
