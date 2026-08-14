// Maintenance-to-calendar projection adapter. It reads service-event history
// from the source owner and never writes a competing maintenance record.

import '../state/app_state.dart';
import 'calendar_projection_contract.dart';

class CalendarMaintenanceProjectionAdapter {
  const CalendarMaintenanceProjectionAdapter._();

  static List<CalendarProjectionEvent> eventsForDay(
    Iterable<MaintenanceServiceEvent> events,
    DateTime day,
  ) {
    final target = DateTime(day.year, day.month, day.day);
    return CalendarProjectionTimeline.normalize(
      events
          .where((event) => _sameDay(event.serviceDate, target))
          .map(fromEvent),
    );
  }

  static CalendarProjectionEvent fromEvent(MaintenanceServiceEvent event) {
    final sourceId = _sourceId(event);
    final recordedAt = event.createdAt ?? event.serviceDate;
    return CalendarProjectionEvent(
      eventId: 'maintenance:$sourceId',
      source: CalendarProjectionSource.maintenance,
      sourceRecordId: sourceId,
      timing: CalendarProjectionTiming(
        eventDate: event.serviceDate,
        recordedAt: recordedAt,
        timeSource: CalendarTimeSource.unknown,
      ),
      title: event.itemName.trim().isEmpty
          ? 'Maintenance service'
          : event.itemName,
      conciseDetail:
          '${event.vehicleName} · ${_odometerDetail(event)} · ${_money(event.totalCost)}',
      state: CalendarProjectionState.confirmed,
      sourceRecordStatus: 'completed_service',
      revision: _revisionFor(event),
      deepLink: CalendarProjectionDeepLink(
        target: CalendarDeepLinkTarget.maintenanceDetail,
        sourceRecordId: sourceId,
      ),
      vehicleIds: _vehicleIds(event),
      evidence: CalendarProjectionEvidence(
        evidenceId: _emptyToNull(event.sourceReceiptFingerprint),
        summary: event.receiptProofCount > 0
            ? '${event.receiptProofCount} receipt proof(s) attached.'
            : 'No receipt proof attached.',
        strength: event.receiptProofCount > 0
            ? 'service proof attached'
            : 'manual service record',
        explanation:
            'Completed maintenance service recorded by the maintenance owner.',
      ),
      auditReference: _emptyToNull(event.sourceCommandId),
    );
  }

  static String sourceIdFor(MaintenanceServiceEvent event) => _sourceId(event);
}

String _odometerDetail(MaintenanceServiceEvent event) =>
    event.odometer > 0 ? '${event.odometer} miles' : 'Odometer not recorded';

bool _sameDay(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;

String _sourceId(MaintenanceServiceEvent event) {
  final saved = event.eventId.trim();
  if (saved.isNotEmpty) return saved;
  return '${event.vehicleId}|${event.vehicleName}|${event.itemName}|${event.serviceDate.toIso8601String()}';
}

List<String> _vehicleIds(MaintenanceServiceEvent event) {
  final id = event.vehicleId.trim();
  return id.isEmpty ? const [] : [id];
}

String? _emptyToNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

int _revisionFor(MaintenanceServiceEvent event) {
  final value = (event.createdAt ?? event.serviceDate).microsecondsSinceEpoch;
  return value < 0 ? 0 : value;
}

String _money(double value) => '\$${value.toStringAsFixed(2)}';
