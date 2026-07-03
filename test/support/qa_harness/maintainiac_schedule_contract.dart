enum MaintainiacScheduleKind { job, maintenance, expenseReminder, recap }

class MaintainiacScheduleEntry {
  const MaintainiacScheduleEntry({
    required this.id,
    required this.kind,
    required this.accountId,
    required this.sourceId,
    required this.startsAt,
    required this.timeZone,
    this.vehicleId = '',
    this.employeeId = '',
    this.notificationPermissionGranted = true,
    this.mutatesSource = false,
    this.auditId = '',
  });

  final String id;
  final MaintainiacScheduleKind kind;
  final String accountId;
  final String sourceId;
  final DateTime startsAt;
  final String timeZone;
  final String vehicleId;
  final String employeeId;
  final bool notificationPermissionGranted;
  final bool mutatesSource;
  final String auditId;

  List<String> validate() {
    final failures = <String>[];
    if (id.trim().isEmpty) failures.add('schedule entry missing id');
    if (accountId.trim().isEmpty) failures.add('$id missing account id');
    if (sourceId.trim().isEmpty) failures.add('$id missing source id');
    if (timeZone.trim().isEmpty) failures.add('$id missing time zone');
    if (!startsAt.isUtc) failures.add('$id startsAt must be stored as UTC');
    if (mutatesSource) {
      failures.add('$id schedule output must not mutate source');
    }
    if (kind == MaintainiacScheduleKind.maintenance &&
        vehicleId.trim().isEmpty) {
      failures.add('$id maintenance schedule needs vehicle id');
    }
    if (kind == MaintainiacScheduleKind.job && auditId.trim().isEmpty) {
      failures.add('$id job schedule edit needs audit id');
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'kind': kind.name,
      'accountId': accountId,
      'sourceId': sourceId,
      'startsAt': startsAt.toIso8601String(),
      'timeZone': timeZone,
      if (vehicleId.isNotEmpty) 'vehicleId': vehicleId,
      if (employeeId.isNotEmpty) 'employeeId': employeeId,
      'notificationPermissionGranted': notificationPermissionGranted,
      'mutatesSource': mutatesSource,
      if (auditId.isNotEmpty) 'auditId': auditId,
    };
  }
}

class MaintainiacScheduleContract {
  const MaintainiacScheduleContract(this.entries);

  final List<MaintainiacScheduleEntry> entries;

  List<String> validate() {
    final failures = <String>[];
    final ids = <String>{};
    if (entries.isEmpty) failures.add('schedule contract has no entries');
    for (final entry in entries) {
      if (!ids.add(entry.id)) {
        failures.add('duplicate schedule entry id ${entry.id}');
      }
      failures.addAll(entry.validate());
    }
    for (final pair in _overlappingVehicleAssignments()) {
      failures.add('vehicle schedule overlap ${pair.$1} ${pair.$2}');
    }
    return failures;
  }

  List<MaintainiacScheduleEntry> notificationQueue() {
    return [
      for (final entry in entries)
        if (entry.notificationPermissionGranted) entry,
    ];
  }

  List<(String, String)> _overlappingVehicleAssignments() {
    final overlaps = <(String, String)>[];
    for (var a = 0; a < entries.length; a++) {
      for (var b = a + 1; b < entries.length; b++) {
        final first = entries[a];
        final second = entries[b];
        if (first.vehicleId.isEmpty || second.vehicleId.isEmpty) continue;
        if (first.accountId != second.accountId) continue;
        if (first.vehicleId != second.vehicleId) continue;
        if (first.startsAt == second.startsAt) {
          overlaps.add((first.id, second.id));
        }
      }
    }
    return overlaps;
  }

  Map<String, Object?> toJson() {
    return {
      'entryCount': entries.length,
      'notificationCount': notificationQueue().length,
      'entries': [for (final entry in entries) entry.toJson()],
    };
  }
}
