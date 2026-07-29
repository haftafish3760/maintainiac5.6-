// Durable coordination for a user-confirmed active-workday context handoff.
// Owns ordered local changes and interruption recovery across record owners.
// It does not own records or decide whether GPS evidence permits a handoff.
// Dashboard confirmation UI and app bootstrap consume this coordinator.

import '../../../shared/records/maintainiac_durable_record_store.dart';
import 'active_workday_store.dart';

enum ActiveWorkdayContextHandoffPhase {
  prepared,
  workdayApplied,
  odometerApplied,
  vehicleApplied,
  profileApplied,
  contextApplied,
  completed,
  needsReview,
}

final class ActiveWorkdayContextHandoffRequest {
  const ActiveWorkdayContextHandoffRequest({
    required this.operationId,
    required this.workdayId,
    required this.vehicleId,
    required this.vehicleLabel,
    required this.workProfileId,
    required this.endingOdometer,
    required this.startingOdometer,
    required this.occurredAt,
  });

  final String operationId;
  final String workdayId;
  final String vehicleId;
  final String vehicleLabel;
  final String workProfileId;
  final int endingOdometer;
  final int startingOdometer;
  final DateTime occurredAt;

  Map<String, dynamic> toMap({
    required ActiveWorkdayContextHandoffPhase phase,
  }) => {
    'schemaVersion': 1,
    'phase': phase.name,
    'operationId': operationId,
    'workdayId': workdayId,
    'vehicleId': vehicleId,
    'vehicleLabel': vehicleLabel,
    'workProfileId': workProfileId,
    'endingOdometer': endingOdometer,
    'startingOdometer': startingOdometer,
    'occurredAt': occurredAt.toUtc().toIso8601String(),
  };

  static ActiveWorkdayContextHandoffRequest? fromMap(
    Map<dynamic, dynamic> map,
  ) {
    if (map['schemaVersion'] != 1 ||
        map['operationId'] is! String ||
        map['workdayId'] is! String ||
        map['vehicleId'] is! String ||
        map['vehicleLabel'] is! String ||
        map['workProfileId'] is! String ||
        map['endingOdometer'] is! int ||
        map['startingOdometer'] is! int ||
        map['occurredAt'] is! String) {
      return null;
    }
    final occurredAt = DateTime.tryParse(map['occurredAt'] as String);
    final request = occurredAt == null
        ? null
        : ActiveWorkdayContextHandoffRequest(
            operationId: map['operationId'] as String,
            workdayId: map['workdayId'] as String,
            vehicleId: map['vehicleId'] as String,
            vehicleLabel: map['vehicleLabel'] as String,
            workProfileId: map['workProfileId'] as String,
            endingOdometer: map['endingOdometer'] as int,
            startingOdometer: map['startingOdometer'] as int,
            occurredAt: occurredAt,
          );
    return request != null && request.isValid ? request : null;
  }

  bool get isValid =>
      _safeToken(operationId) &&
      _safeToken(workdayId) &&
      _safeToken(vehicleId) &&
      _safeToken(workProfileId) &&
      vehicleLabel.trim().isNotEmpty &&
      vehicleLabel.length <= 120 &&
      endingOdometer >= 0 &&
      startingOdometer >= 0;
}

final class ActiveWorkdayContextHandoffResult {
  const ActiveWorkdayContextHandoffResult({
    required this.phase,
    required this.completed,
    this.message,
  });

  final ActiveWorkdayContextHandoffPhase phase;
  final bool completed;
  final String? message;
}

/// Adapts the record-owning stores without giving this coordinator ownership.
final class ActiveWorkdayContextHandoffPorts {
  const ActiveWorkdayContextHandoffPorts({
    required this.activeSession,
    required this.applyWorkdayBoundary,
    required this.switchOdometerVehicle,
    required this.selectVehicle,
    required this.selectWorkProfile,
    required this.syncOperationalContext,
  });

  final ActiveWorkdaySessionRecord? Function() activeSession;
  final Future<ActiveWorkdaySessionRecord?> Function(
    ActiveWorkdayContextHandoffRequest request,
  )
  applyWorkdayBoundary;
  final Future<bool> Function(String vehicleId) switchOdometerVehicle;
  final Future<void> Function(String vehicleId) selectVehicle;
  final Future<void> Function(String profileId) selectWorkProfile;
  final Future<void> Function(String vehicleId) syncOperationalContext;
}

/// Replays a persisted handoff until every owning store has the same context.
final class ActiveWorkdayContextHandoffCoordinator {
  ActiveWorkdayContextHandoffCoordinator({
    required MaintainiacDurableRecordStore records,
    required ActiveWorkdayContextHandoffPorts ports,
  }) : _records = records,
       _ports = ports;

  static const recordModule = 'activeWorkdayContextHandoffs';
  final MaintainiacDurableRecordStore _records;
  final ActiveWorkdayContextHandoffPorts _ports;
  Future<void> _tail = Future<void>.value();

  Future<ActiveWorkdayContextHandoffResult> apply(
    ActiveWorkdayContextHandoffRequest request,
  ) => _enqueue(
    () =>
        _apply(request, _records.recordFor(recordModule, request.operationId)),
  );

  Future<List<ActiveWorkdayContextHandoffResult>> recoverPending() => _enqueue(
    () async {
      final results = <ActiveWorkdayContextHandoffResult>[];
      for (final record in _records.recordsFor(recordModule)) {
        final request = ActiveWorkdayContextHandoffRequest.fromMap(
          record.payload,
        );
        final phase = _phase(record.payload['phase']);
        if (request == null || phase == null) {
          results.add(
            const ActiveWorkdayContextHandoffResult(
              phase: ActiveWorkdayContextHandoffPhase.needsReview,
              completed: false,
              message: 'A saved workday context change could not be recovered.',
            ),
          );
        } else if (phase != ActiveWorkdayContextHandoffPhase.completed &&
            phase != ActiveWorkdayContextHandoffPhase.needsReview) {
          results.add(await _apply(request, record));
        }
      }
      return List.unmodifiable(results);
    },
  );

  Future<ActiveWorkdayContextHandoffResult> _apply(
    ActiveWorkdayContextHandoffRequest request,
    MaintainiacDurableRecord? existing,
  ) async {
    if (!request.isValid) {
      return const ActiveWorkdayContextHandoffResult(
        phase: ActiveWorkdayContextHandoffPhase.needsReview,
        completed: false,
        message: 'The selected vehicle or work profile is not valid.',
      );
    }
    final persistedRequest = existing == null
        ? null
        : ActiveWorkdayContextHandoffRequest.fromMap(existing.payload);
    if (existing != null &&
        (persistedRequest == null ||
            !_sameRequest(persistedRequest, request))) {
      return const ActiveWorkdayContextHandoffResult(
        phase: ActiveWorkdayContextHandoffPhase.needsReview,
        completed: false,
        message:
            'This saved context change does not match the current request.',
      );
    }
    final persistedPhase = _phase(existing?.payload['phase']);
    if (persistedPhase == ActiveWorkdayContextHandoffPhase.completed) {
      return const ActiveWorkdayContextHandoffResult(
        phase: ActiveWorkdayContextHandoffPhase.completed,
        completed: true,
      );
    }
    if (persistedPhase == ActiveWorkdayContextHandoffPhase.needsReview) {
      return ActiveWorkdayContextHandoffResult(
        phase: persistedPhase!,
        completed: false,
        message:
            existing?.payload['message'] as String? ??
            'Review the saved context change before retrying it.',
      );
    }
    final active = _ports.activeSession();
    if (active == null || active.id != request.workdayId) {
      return _saveResult(
        request,
        existing,
        ActiveWorkdayContextHandoffPhase.needsReview,
        'The active workday changed before this context switch completed.',
      );
    }
    var phase = persistedPhase ?? ActiveWorkdayContextHandoffPhase.prepared;
    var record = existing ?? await _save(request, phase, null);
    try {
      if (phase == ActiveWorkdayContextHandoffPhase.prepared) {
        final updated = await _ports.applyWorkdayBoundary(request);
        if (updated == null || updated.id != request.workdayId) {
          return _saveResult(
            request,
            record,
            ActiveWorkdayContextHandoffPhase.needsReview,
            'The workday context boundary could not be saved.',
          );
        }
        phase = ActiveWorkdayContextHandoffPhase.workdayApplied;
        record = await _save(request, phase, record);
      }
      if (phase == ActiveWorkdayContextHandoffPhase.workdayApplied) {
        if (!await _ports.switchOdometerVehicle(request.vehicleId)) {
          throw StateError('The odometer vehicle could not be switched.');
        }
        phase = ActiveWorkdayContextHandoffPhase.odometerApplied;
        record = await _save(request, phase, record);
      }
      if (phase == ActiveWorkdayContextHandoffPhase.odometerApplied) {
        await _ports.selectVehicle(request.vehicleId);
        phase = ActiveWorkdayContextHandoffPhase.vehicleApplied;
        record = await _save(request, phase, record);
      }
      if (phase == ActiveWorkdayContextHandoffPhase.vehicleApplied) {
        await _ports.selectWorkProfile(request.workProfileId);
        phase = ActiveWorkdayContextHandoffPhase.profileApplied;
        record = await _save(request, phase, record);
      }
      if (phase == ActiveWorkdayContextHandoffPhase.profileApplied) {
        await _ports.syncOperationalContext(request.vehicleId);
        phase = ActiveWorkdayContextHandoffPhase.contextApplied;
        record = await _save(request, phase, record);
      }
      await _save(request, ActiveWorkdayContextHandoffPhase.completed, record);
      return const ActiveWorkdayContextHandoffResult(
        phase: ActiveWorkdayContextHandoffPhase.completed,
        completed: true,
      );
    } catch (_) {
      return _saveResult(
        request,
        record,
        phase,
        'The context switch is saved for recovery. Review it before continuing.',
      );
    }
  }

  Future<ActiveWorkdayContextHandoffResult> _saveResult(
    ActiveWorkdayContextHandoffRequest request,
    MaintainiacDurableRecord? existing,
    ActiveWorkdayContextHandoffPhase phase,
    String message,
  ) async {
    await _save(request, phase, existing, message: message);
    return ActiveWorkdayContextHandoffResult(
      phase: phase,
      completed: false,
      message: message,
    );
  }

  Future<MaintainiacDurableRecord> _save(
    ActiveWorkdayContextHandoffRequest request,
    ActiveWorkdayContextHandoffPhase phase,
    MaintainiacDurableRecord? existing, {
    String? message,
  }) => _records.save(
    module: recordModule,
    id: request.operationId,
    payload: {
      ...request.toMap(phase: phase),
      ...?(message == null ? null : {'message': message}),
    },
    expectedRevision: existing?.lifecycle.revision,
  );

  Future<T> _enqueue<T>(Future<T> Function() action) {
    final next = _tail.then((_) => action());
    _tail = next.then<void>((_) {}, onError: (error, stackTrace) {});
    return next;
  }
}

ActiveWorkdayContextHandoffPhase? _phase(Object? value) {
  if (value is! String) return null;
  for (final phase in ActiveWorkdayContextHandoffPhase.values) {
    if (phase.name == value) return phase;
  }
  return null;
}

bool _safeToken(String value) =>
    value.isNotEmpty &&
    value.length <= 96 &&
    RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(value);

bool _sameRequest(
  ActiveWorkdayContextHandoffRequest left,
  ActiveWorkdayContextHandoffRequest right,
) =>
    left.operationId == right.operationId &&
    left.workdayId == right.workdayId &&
    left.vehicleId == right.vehicleId &&
    left.vehicleLabel == right.vehicleLabel &&
    left.workProfileId == right.workProfileId &&
    left.endingOdometer == right.endingOdometer &&
    left.startingOdometer == right.startingOdometer &&
    left.occurredAt.toUtc().isAtSameMomentAs(right.occurredAt.toUtc());
