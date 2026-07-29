// Date-based maintenance interval projection. Odometer-only intervals remain
// in Maintenance because Calendar must not invent a due date from mileage.

import '../state/app_state.dart';
import 'calendar_projection_contract.dart';

class CalendarMaintenanceDueProjectionAdapter {
  const CalendarMaintenanceDueProjectionAdapter._();

  static Iterable<CalendarProjectionEvent> eventsForDay(
    Iterable<MaintenanceRecord> records,
    DateTime day, {
    DateTime? now,
  }) sync* {
    final referenceNow = now ?? DateTime.now();
    for (final record in records) {
      if (record.isArchived ||
          !record.setupComplete ||
          !record.thresholdsEnabled) {
        continue;
      }
      final dueDate = _dueDate(record);
      if (dueDate == null || !_sameDay(dueDate, day)) continue;
      final sourceId = record.recordId.trim();
      if (sourceId.isEmpty) continue;
      yield CalendarProjectionEvent(
        eventId: 'maintenance-due:$sourceId:${dueDate.toIso8601String()}',
        source: CalendarProjectionSource.reminder,
        sourceRecordId: sourceId,
        timing: CalendarProjectionTiming(
          eventDate: dueDate,
          recordedAt: record.updatedAt ?? record.createdAt ?? dueDate,
          scheduledAt: dueDate,
          timeSource: CalendarTimeSource.scheduled,
        ),
        title: 'Maintenance due · ${record.itemName}',
        conciseDetail:
            '${record.vehicleName} · ${record.intervalMonths}-month interval',
        state: dueDate.isBefore(_dateOnly(referenceNow))
            ? CalendarProjectionState.needsReview
            : CalendarProjectionState.proposed,
        sourceRecordStatus: 'active',
        revision: record.revision,
        vehicleIds: record.vehicleId.isEmpty ? const [] : [record.vehicleId],
        evidence: CalendarProjectionEvidence(
          summary:
              'Scheduled from the confirmed service date and time interval.',
          explanation: record.intervalMiles > 0
              ? 'Mileage interval remains independently tracked by Maintenance.'
              : null,
        ),
        deepLink: CalendarProjectionDeepLink(
          target: CalendarDeepLinkTarget.maintenanceDetail,
          sourceRecordId: sourceId,
        ),
      );
    }
  }

  static DateTime? _dueDate(MaintenanceRecord record) {
    final serviceDate = record.lastServiceDate;
    if (serviceDate == null || record.intervalMonths <= 0) return null;
    return _addMonths(_dateOnly(serviceDate), record.intervalMonths);
  }
}

DateTime _addMonths(DateTime date, int months) {
  final monthIndex = date.month - 1 + months;
  final year = date.year + monthIndex ~/ 12;
  final month = monthIndex % 12 + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, date.day.clamp(1, lastDay).toInt());
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

bool _sameDay(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;
