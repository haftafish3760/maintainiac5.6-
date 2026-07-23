part of 'app_state.dart';

extension AppStateMaintenanceController on AppStateController {
  String maintenanceVehicleName({
    required String vehicleId,
    required String fallback,
  }) {
    final current = vehicleById(vehicleId.trim());
    return current?.nickname ?? fallback;
  }

  List<MaintenanceRecord> get maintenance =>
      List.unmodifiable(_maintenance.where((record) => !record.isArchived));
  List<MaintenanceRecord> get allMaintenanceRecords =>
      List.unmodifiable(_maintenance);
  List<MaintenanceServiceEvent> get maintenanceEvents =>
      List.unmodifiable(_maintenanceEvents);
  bool get maintenanceRecoveredFromBackup => _maintenanceRecoveredFromBackup;
  bool get maintenancePrimaryWasInvalid => _maintenancePrimaryWasInvalid;

  Future<void> addMaintenanceRecords(List<MaintenanceRecord> records) {
    final now = DateTime.now().toUtc();
    final nextRecords = [..._maintenance];
    for (final record in records) {
      final normalized = _normalizeMaintenanceRecord(record, now: now);
      if (normalized == null) continue;
      final naturalKey = _maintenanceRecordNaturalKey(normalized);
      final existingIndex = nextRecords.indexWhere(
        (saved) => _maintenanceRecordNaturalKey(saved) == naturalKey,
      );
      if (existingIndex < 0) {
        nextRecords.add(normalized);
        continue;
      }
      final existing = nextRecords[existingIndex];
      if (existing.isArchived) {
        nextRecords[existingIndex] = normalized.copyWith(
          recordId: existing.recordId,
          createdAt: existing.createdAt,
          updatedAt: now,
          revision: existing.revision + 1,
          clearArchivedAt: true,
        );
      }
    }
    return _saveMaintenanceChange(
      records: nextRecords,
      events: _maintenanceEvents,
    );
  }

  Future<void> updateMaintenanceRecord(MaintenanceRecord record) {
    final normalized = _normalizeMaintenanceRecord(
      record,
      now: DateTime.now().toUtc(),
      incrementRevision: true,
    );
    if (normalized == null) return Future<void>.value();
    final nextRecords = [..._maintenance];
    final index = nextRecords.indexWhere(
      (saved) =>
          saved.recordId == normalized.recordId ||
          _maintenanceRecordNaturalKey(saved) ==
              _maintenanceRecordNaturalKey(normalized),
    );
    if (index == -1) return Future<void>.value();
    nextRecords[index] = normalized;
    return _saveMaintenanceChange(
      records: nextRecords,
      events: _maintenanceEvents,
    );
  }

  Future<void> archiveMaintenanceRecord(String recordId) {
    final normalizedId = recordId.trim();
    if (normalizedId.isEmpty) return Future<void>.value();
    final nextRecords = [..._maintenance];
    final index = nextRecords.indexWhere(
      (record) => record.recordId == normalizedId,
    );
    if (index < 0 || nextRecords[index].isArchived) {
      return Future<void>.value();
    }
    final now = DateTime.now().toUtc();
    nextRecords[index] = nextRecords[index].copyWith(
      archivedAt: now,
      updatedAt: now,
      revision: nextRecords[index].revision + 1,
    );
    return _saveMaintenanceChange(
      records: nextRecords,
      events: _maintenanceEvents,
    );
  }

  Future<void> restoreMaintenanceRecord(String recordId) {
    final normalizedId = recordId.trim();
    if (normalizedId.isEmpty) return Future<void>.value();
    final nextRecords = [..._maintenance];
    final index = nextRecords.indexWhere(
      (record) => record.recordId == normalizedId,
    );
    if (index < 0 || !nextRecords[index].isArchived) {
      return Future<void>.value();
    }
    final now = DateTime.now().toUtc();
    nextRecords[index] = nextRecords[index].copyWith(
      clearArchivedAt: true,
      updatedAt: now,
      revision: nextRecords[index].revision + 1,
    );
    return _saveMaintenanceChange(
      records: nextRecords,
      events: _maintenanceEvents,
    );
  }

  void _sortMaintenanceRecords() {
    _maintenance.sort((a, b) {
      final urgency = _maintenanceAttentionRank(
        b,
      ).compareTo(_maintenanceAttentionRank(a));
      if (urgency != 0) return urgency;
      return b.importance.compareTo(a.importance);
    });
  }

  int _maintenanceAttentionRank(MaintenanceRecord record) {
    if (record.timeOnly) {
      if (record.monthsRemaining <= 0) return 4000 + record.importance;
      if (record.monthsRemaining <= 3) return 3000 + record.importance;
      if (record.monthsRemaining <= 6) return 2000 + record.importance;
      return record.importance;
    }
    if (record.milesRemaining <= 300) return 4000 + record.importance;
    if (record.milesRemaining <= 600) return 3000 + record.importance;
    if (record.milesRemaining <= 900) return 2000 + record.importance;
    return record.importance;
  }

  Future<void> logMaintenanceService(MaintenanceServiceEvent event) {
    return logMaintenanceServices([event]);
  }

  Future<void> logMaintenanceServices(List<MaintenanceServiceEvent> events) {
    final now = DateTime.now().toUtc();
    final nextEvents = [..._maintenanceEvents];
    final nextRecords = [..._maintenance];
    final eventIds = {for (final event in nextEvents) event.eventId};
    var changed = false;
    for (final event in events) {
      final normalized = _normalizeMaintenanceEvent(event, now: now);
      if (normalized == null || !eventIds.add(normalized.eventId)) continue;
      nextEvents.add(normalized);
      changed = true;
      final index = nextRecords.indexWhere(
        (record) =>
            !record.isArchived &&
            record.itemName == normalized.itemName &&
            _maintenanceVehicleMatches(
              record.vehicleId,
              record.vehicleName,
              normalized.vehicleId,
              normalized.vehicleName,
            ),
      );
      if (index != -1) {
        nextRecords[index] = nextRecords[index].copyWith(
          milesSinceService: 0,
          monthsSinceService: 0,
          lastServiceDate: normalized.serviceDate,
          lastServiceOdometer: normalized.odometer,
          setupComplete: true,
          lastServiceEstimated: false,
          lastOdometerEstimated: false,
          updatedAt: now,
          revision: nextRecords[index].revision + 1,
        );
      }
    }
    if (!changed) return Future<void>.value();
    return _saveMaintenanceChange(records: nextRecords, events: nextEvents);
  }

  /// Applies receipt-confirmed setup records and service events in one durable
  /// snapshot. Event IDs and record natural keys make exact retries idempotent.
  Future<void> applyMaintenanceTransaction({
    required List<MaintenanceRecord> records,
    required List<MaintenanceServiceEvent> events,
  }) {
    final now = DateTime.now().toUtc();
    final nextRecords = [..._maintenance];
    final nextEvents = [..._maintenanceEvents];
    var changed = false;

    for (final record in records) {
      final normalized = _normalizeMaintenanceRecord(record, now: now);
      if (normalized == null) continue;
      final naturalKey = _maintenanceRecordNaturalKey(normalized);
      final existingIndex = nextRecords.indexWhere(
        (saved) => _maintenanceRecordNaturalKey(saved) == naturalKey,
      );
      if (existingIndex < 0) {
        nextRecords.add(normalized);
        changed = true;
        continue;
      }
      final existing = nextRecords[existingIndex];
      if (existing.isArchived) {
        nextRecords[existingIndex] = normalized.copyWith(
          recordId: existing.recordId,
          createdAt: existing.createdAt,
          updatedAt: now,
          revision: existing.revision + 1,
          clearArchivedAt: true,
        );
        changed = true;
      }
    }

    final eventIds = {for (final event in nextEvents) event.eventId};
    for (final event in events) {
      final normalized = _normalizeMaintenanceEvent(event, now: now);
      if (normalized == null || !eventIds.add(normalized.eventId)) continue;
      nextEvents.add(normalized);
      changed = true;
      final recordIndex = nextRecords.indexWhere(
        (record) =>
            !record.isArchived &&
            record.itemName == normalized.itemName &&
            _maintenanceVehicleMatches(
              record.vehicleId,
              record.vehicleName,
              normalized.vehicleId,
              normalized.vehicleName,
            ),
      );
      if (recordIndex >= 0) {
        nextRecords[recordIndex] = nextRecords[recordIndex].copyWith(
          milesSinceService: 0,
          monthsSinceService: 0,
          lastServiceDate: normalized.serviceDate,
          lastServiceOdometer: normalized.odometer,
          setupComplete: true,
          lastServiceEstimated: false,
          lastOdometerEstimated: false,
          updatedAt: now,
          revision: nextRecords[recordIndex].revision + 1,
        );
      }
    }

    if (!changed) return Future<void>.value();
    return _saveMaintenanceChange(records: nextRecords, events: nextEvents);
  }

  Future<void> _restoreMaintenance() async {
    final store = _maintenanceStore;
    if (store == null) return;
    final read = await store.read();
    _maintenanceRecoveredFromBackup = read.recoveredFromBackup;
    _maintenancePrimaryWasInvalid = read.primaryWasInvalid;
    final restoredRecords = <MaintenanceRecord>[];
    final recordKeys = <String>{};
    for (final source in read.snapshot.records) {
      try {
        final record = _normalizeMaintenanceRecord(
          MaintenanceRecord.fromMap(source),
          now: read.snapshot.updatedAt,
        );
        if (record == null) continue;
        if (recordKeys.add(_maintenanceRecordNaturalKey(record))) {
          restoredRecords.add(record);
        }
      } on FormatException {
        continue;
      }
    }
    final restoredEvents = <MaintenanceServiceEvent>[];
    final eventIds = <String>{};
    for (final source in read.snapshot.events) {
      try {
        final event = _normalizeMaintenanceEvent(
          MaintenanceServiceEvent.fromMap(source),
          now: read.snapshot.updatedAt,
        );
        if (event == null || !eventIds.add(event.eventId)) continue;
        restoredEvents.add(event);
      } on FormatException {
        continue;
      }
    }
    _maintenance
      ..clear()
      ..addAll(restoredRecords);
    _maintenanceEvents
      ..clear()
      ..addAll(restoredEvents);
    _sortMaintenanceRecords();

    if (read.recoveredFromBackup) {
      await _persistMaintenanceSnapshot(_maintenance, _maintenanceEvents);
    }
  }

  Future<void> _saveMaintenanceChange({
    required List<MaintenanceRecord> records,
    required List<MaintenanceServiceEvent> events,
  }) {
    final store = _maintenanceStore;
    if (store == null) {
      _commitMaintenanceState(records, events);
      return Future<void>.value();
    }
    return _persistMaintenanceSnapshot(records, events).then((_) {
      _commitMaintenanceState(records, events);
    });
  }

  Future<void> _persistMaintenanceSnapshot(
    List<MaintenanceRecord> records,
    List<MaintenanceServiceEvent> events,
  ) {
    final store = _maintenanceStore;
    if (store == null) return Future<void>.value();
    return store.write(
      MaintenanceLocalSnapshot(
        schemaVersion: MaintenanceLocalSnapshot.currentSchemaVersion,
        records: [for (final record in records) record.toMap()],
        events: [for (final event in events) event.toMap()],
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  void _commitMaintenanceState(
    List<MaintenanceRecord> records,
    List<MaintenanceServiceEvent> events,
  ) {
    // Callers may intentionally retain one side of the current state. Copy
    // before clearing so an aliased `_maintenance` or `_maintenanceEvents`
    // list cannot erase itself during the commit.
    final committedRecords = List<MaintenanceRecord>.of(records);
    final committedEvents = List<MaintenanceServiceEvent>.of(events);
    _maintenance
      ..clear()
      ..addAll(committedRecords);
    _maintenanceEvents
      ..clear()
      ..addAll(committedEvents);
    _sortMaintenanceRecords();
    _notifyStateListeners();
  }

  MaintenanceRecord? _normalizeMaintenanceRecord(
    MaintenanceRecord record, {
    required DateTime now,
    bool incrementRevision = false,
  }) {
    final itemName = record.itemName.trim();
    final vehicle = _resolveMaintenanceVehicle(
      vehicleId: record.vehicleId,
      vehicleName: record.vehicleName,
    );
    if (itemName.isEmpty || vehicle == null) return null;
    final naturalId =
        'maintenance_${_safeMaintenanceId(vehicle.id)}_${_safeMaintenanceId(itemName)}';
    return record.copyWith(
      recordId: record.recordId.trim().isEmpty
          ? naturalId
          : record.recordId.trim(),
      vehicleId: vehicle.id,
      vehicleName: vehicle.nickname,
      createdAt: record.createdAt?.toUtc() ?? now,
      updatedAt: now,
      revision: incrementRevision ? record.revision + 1 : record.revision,
      sourceCommandId: _safeReceiptSha256(record.sourceCommandId),
      sourceReceiptFingerprint: _safeReceiptSha256(
        record.sourceReceiptFingerprint,
      ),
    );
  }

  MaintenanceServiceEvent? _normalizeMaintenanceEvent(
    MaintenanceServiceEvent event, {
    required DateTime now,
  }) {
    final itemName = event.itemName.trim();
    final vehicle = _resolveMaintenanceVehicle(
      vehicleId: event.vehicleId,
      vehicleName: event.vehicleName,
    );
    if (itemName.isEmpty || vehicle == null || event.odometer < 0) return null;
    final fallbackId = [
      'maintenance_event',
      _safeMaintenanceId(vehicle.id),
      _safeMaintenanceId(itemName),
      event.serviceDate.toUtc().microsecondsSinceEpoch,
      event.odometer,
    ].join('_');
    return event.copyWith(
      eventId: event.eventId.trim().isEmpty ? fallbackId : event.eventId.trim(),
      vehicleId: vehicle.id,
      vehicleName: vehicle.nickname,
      createdAt: event.createdAt?.toUtc() ?? now,
      sourceCommandId: _safeReceiptSha256(event.sourceCommandId),
      sourceReceiptFingerprint: _safeReceiptSha256(
        event.sourceReceiptFingerprint,
      ),
    );
  }

  VehicleProfile? _resolveMaintenanceVehicle({
    required String vehicleId,
    required String vehicleName,
  }) {
    final stableId = vehicleId.trim();
    if (stableId.isNotEmpty) {
      final byId = vehicleById(stableId);
      if (byId != null) return byId;
    }
    final normalizedName = vehicleName.trim().toLowerCase();
    if (normalizedName.isEmpty) return null;
    for (final vehicle in _vehicles) {
      if (vehicle.nickname.trim().toLowerCase() == normalizedName) {
        return vehicle;
      }
    }
    return null;
  }

  String _maintenanceRecordNaturalKey(MaintenanceRecord record) {
    return '${record.vehicleId.trim().toLowerCase()}|'
        '${record.itemName.trim().toLowerCase()}';
  }

  bool _maintenanceVehicleMatches(
    String leftVehicleId,
    String leftVehicleName,
    String rightVehicleId,
    String rightVehicleName,
  ) {
    final leftId = leftVehicleId.trim();
    final rightId = rightVehicleId.trim();
    if (leftId.isNotEmpty && rightId.isNotEmpty) return leftId == rightId;
    return leftVehicleName.trim().toLowerCase() ==
        rightVehicleName.trim().toLowerCase();
  }

  String _safeMaintenanceId(String source) {
    final normalized = source
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return normalized.isEmpty ? 'unknown' : normalized;
  }

  String _safeReceiptSha256(String source) {
    final normalized = source.trim().toLowerCase();
    return RegExp(r'^[a-f0-9]{64}$').hasMatch(normalized) ? normalized : '';
  }
}
