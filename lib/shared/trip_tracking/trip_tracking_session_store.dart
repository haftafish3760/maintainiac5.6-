import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../storage/app_storage_guard.dart';
import 'trip_tracking_models.dart';
import 'trip_tracking_quarantined_session.dart';
import 'trip_tracking_recovery_diagnostic.dart';
import 'trip_tracking_session_snapshot.dart';

part 'trip_tracking_session_record.dart';
part 'trip_tracking_review_record.dart';
part 'trip_tracking_session_ancestry.dart';

typedef TripTrackingSessionStorageCheck = Future<AppStorageCheck> Function();

double _safeGpsAssistanceCalibrationMultiplier(Object? value) {
  if (value is! num || !value.isFinite || value <= 0) return 1;
  return value.toDouble().clamp(0.8, 1.25).toDouble();
}

bool _isValidGpsAssistanceCalibrationMultiplier(Object? value) =>
    value is num && value.isFinite && value >= 0.8 && value <= 1.25;

extension _TakeLastExtension<T> on List<T> {
  Iterable<T> takeLast(int maxLength) {
    if (length <= maxLength) return this;
    return skip(length - maxLength);
  }
}

/// A locally durable handoff from active tracking into review. It intentionally
/// preserves the measured distance and the final engine state; the permanent
/// odometer event is created only after the user reviews this record.
class TripTrackingPendingSample {
  const TripTrackingPendingSample({
    required this.sessionId,
    required this.sample,
    this.activity,
    this.schemaVersion = _pendingSampleSchemaVersion,
  });

  final String sessionId;
  final TripLocationSample sample;
  final TripActivityObservation? activity;
  final int schemaVersion;

  Map<String, Object?> toMap() => {
    'schemaVersion': _pendingSampleSchemaVersion,
    'sessionId': sessionId,
    'sample': sample.toMap(),
    'activity': activity?.toMap(),
  };

  Map<String, Object?> toBoundarySummary({DateTime? now}) {
    final activitySafe = _isSafePendingActivity(sample, activity);
    return {
      'schemaVersion': _pendingSampleSchemaVersion,
      'hasSafeSessionId': _isSafePendingSessionId(sessionId),
      'hasValidCoordinate': sample.hasValidCoordinate,
      'hasValidAccuracy': sample.hasValidAccuracy,
      'hasActivityEvidence': activity != null,
      'hasSafeActivityEvidence': activitySafe,
      'mockedLocationReported': sample.mockedLocation == true,
      'preciseLocationIncluded': false,
      'preciseTimestampIncluded': false,
      'rawProviderPayloadIncluded': false,
      'authoritativeForMileage': false,
      'odometerIsGlobalTruth': true,
      'pendingSampleCanCreateCalibration': false,
      'pendingSampleCanApplyCalibration': false,
      'calibrationRequiresTrustedGpsWindow': true,
      'poorGpsDaysExcludedFromCalibration': true,
      'canOverrideOdometer': false,
      'canCreateTripLogEntry': false,
    };
  }

  static TripTrackingPendingSample? tryFromMap(Map<dynamic, dynamic> map) {
    final sampleMap = map['sample'];
    final sessionId = map['sessionId'];
    if (_pendingSchemaVersion(map['schemaVersion']) !=
            _pendingSampleSchemaVersion ||
        !_isSafePendingSessionId(sessionId) ||
        sampleMap is! Map) {
      return null;
    }
    final sample = TripLocationSample.tryFromMap(sampleMap);
    if (sample == null) return null;
    final activity = map['activity'] is Map
        ? TripActivityObservation.tryFromMap(map['activity'] as Map)
        : null;
    return TripTrackingPendingSample(
      sessionId: sessionId as String,
      sample: sample,
      activity: _isSafePendingActivity(sample, activity) ? activity : null,
      schemaVersion: _pendingSampleSchemaVersion,
    );
  }
}

const int _pendingSampleSchemaVersion = 1;

int? _pendingSchemaVersion(Object? value) {
  if (value is int && value == _pendingSampleSchemaVersion) return value;
  return null;
}

bool _isSafePendingActivity(
  TripLocationSample sample,
  TripActivityObservation? activity,
) {
  if (activity == null) return false;
  if (activity.confidence < 0 || activity.confidence > 100) return false;
  if (sample.recordedAt.isBefore(activity.recordedAt)) return false;
  return sample.recordedAt.difference(activity.recordedAt) <=
      const Duration(seconds: 90);
}

class TripTrackingSessionStore {
  TripTrackingSessionStore._(
    this._box, {
    TripTrackingSessionStorageCheck? storageCheck,
  }) : _storageCheck = storageCheck ?? _defaultStorageCheck;
  TripTrackingSessionStore.memory({
    TripTrackingSessionStorageCheck? storageCheck,
  }) : _box = null,
       _storageCheck = storageCheck;

  static const boxName = 'active_gps_trip_tracking_session';
  static const _activeSessionKey = 'activeSession';
  static const _previousSessionKey = 'previousCommittedSession';
  static const _pendingSessionWriteKey = 'pendingSessionWrite';
  static const _quarantinedPrefix = 'quarantinedSession:';
  static const _recoveryDiagnosticPrefix = 'recoveryDiagnostic:';
  static const _reviewPrefix = 'review:';
  static const _pendingPrefix = 'pending:';

  final Box<dynamic>? _box;
  TripTrackingSessionRecord? _memorySession;
  final Map<String, TripTrackingReviewRecord> _memoryReviews = {};
  final Map<String, TripTrackingPendingSample> _memoryPending = {};
  final Map<String, TripTrackingQuarantinedSession> _memoryQuarantined = {};
  final Map<String, TripTrackingRecoveryDiagnostic> _memoryRecoveryDiagnostics =
      {};
  final TripTrackingSessionStorageCheck? _storageCheck;
  static Future<void> _sharedWriteTail = Future<void>.value();

  static Future<TripTrackingSessionStore> create({
    TripTrackingSessionStorageCheck? storageCheck,
  }) async {
    final box = await Hive.openBox<dynamic>(boxName);
    return TripTrackingSessionStore._(box, storageCheck: storageCheck);
  }

  TripTrackingSessionRecord? get activeSession {
    if (_box == null) return _memorySession;
    return _selectedStoredSession()?.session;
  }

  TripTrackingPendingWriteState get pendingWriteState {
    if (_box == null) return TripTrackingPendingWriteState.none;
    final pendingValue = _box.get(_pendingSessionWriteKey);
    if (pendingValue == null) return TripTrackingPendingWriteState.none;
    final pending = _storedSessionCandidate(pendingValue, priority: 2);
    if (pending == null) return TripTrackingPendingWriteState.malformed;
    final active = _storedSessionCandidate(
      _box.get(_activeSessionKey),
      priority: 3,
    );
    return active != null && _candidateIsAtLeast(active, pending)
        ? TripTrackingPendingWriteState.committedCleanupPending
        : TripTrackingPendingWriteState.interrupted;
  }

  /// Selects the newest valid generation and records bounded local evidence
  /// when a corrupt latest generation required fallback.
  Future<TripTrackingSessionRecord?> recoverActive({
    DateTime? recordedAtUtc,
  }) => _enqueue(() async {
    if (_box == null) return _memorySession;
    final selected = _selectedStoredSession();
    final expectedGeneration = _maximumRawRecoveryGeneration;
    final restoredGeneration = selected?.generation ?? 0;
    final rawActive = _box.get(_activeSessionKey);
    final active = _storedSessionCandidate(rawActive, priority: 3);
    final usedFallback =
        selected != null &&
        (expectedGeneration > restoredGeneration ||
            (rawActive != null && active == null));
    if (usedFallback) {
      final key =
          '${_recoveryDiagnosticPrefix}snapshot:$expectedGeneration:$restoredGeneration';
      if (!_box.containsKey(key)) {
        final diagnostic = TripTrackingRecoveryDiagnostic(
          code: 'corrupt_latest_snapshot_fallback',
          recordedAtUtc: (recordedAtUtc ?? DateTime.now()).toUtc(),
          expectedGeneration: expectedGeneration,
          restoredGeneration: restoredGeneration,
        );
        await _box.put(key, diagnostic.toMap());
      }
    }
    return selected?.session;
  });

  List<TripTrackingQuarantinedSession> get quarantinedSessions {
    final records = _box == null
        ? _memoryQuarantined.values.toList()
        : _box.keys
              .whereType<String>()
              .where((key) => key.startsWith(_quarantinedPrefix))
              .map((key) => _box.get(key))
              .whereType<Map>()
              .map(TripTrackingQuarantinedSession.tryFromMap)
              .whereType<TripTrackingQuarantinedSession>()
              .toList();
    records.sort((a, b) => a.quarantinedAtUtc.compareTo(b.quarantinedAtUtc));
    return List.unmodifiable(records);
  }

  List<TripTrackingRecoveryDiagnostic> get recoveryDiagnostics {
    final records = _box == null
        ? _memoryRecoveryDiagnostics.values.toList()
        : _box.keys
              .whereType<String>()
              .where((key) => key.startsWith(_recoveryDiagnosticPrefix))
              .map((key) => _box.get(key))
              .whereType<Map>()
              .map(TripTrackingRecoveryDiagnostic.tryFromMap)
              .whereType<TripTrackingRecoveryDiagnostic>()
              .toList();
    records.sort((a, b) => a.recordedAtUtc.compareTo(b.recordedAtUtc));
    return List.unmodifiable(records);
  }

  bool get hasUnreadableActiveEvidence {
    if (_box == null || activeSession != null) return false;
    return _box.containsKey(_activeSessionKey) ||
        _box.containsKey(_previousSessionKey) ||
        _box.containsKey(_pendingSessionWriteKey);
  }

  Future<TripTrackingRecoveryDiagnostic?> recordUnreadableRecoveryDiagnostic({
    DateTime? recordedAtUtc,
  }) => _enqueue(() async {
    if (!hasUnreadableActiveEvidence) return null;
    final expectedRevision = _maximumRawRecoveryRevision;
    final key = '${_recoveryDiagnosticPrefix}unreadable:$expectedRevision:0';
    final existing = _box == null
        ? _memoryRecoveryDiagnostics[key]
        : switch (_box.get(key)) {
            Map value => TripTrackingRecoveryDiagnostic.tryFromMap(value),
            _ => null,
          };
    if (existing != null) return existing;
    final diagnostic = TripTrackingRecoveryDiagnostic(
      code: 'corrupt_active_session_recovery_required',
      recordedAtUtc: (recordedAtUtc ?? DateTime.now()).toUtc(),
      expectedGeneration: expectedRevision,
      restoredGeneration: 0,
    );
    if (_box == null) {
      _memoryRecoveryDiagnostics[key] = diagnostic;
    } else {
      await _box.put(key, diagnostic.toMap());
    }
    return diagnostic;
  });

  int get _maximumRawRecoveryRevision {
    if (_box == null) return _memorySession?.revision ?? 0;
    var maximum = 0;
    for (final key in [
      _activeSessionKey,
      _previousSessionKey,
      _pendingSessionWriteKey,
    ]) {
      final value = _box.get(key);
      final revision = _rawSessionPayload(value)?['revision'];
      if (revision is int && revision >= 0 && revision > maximum) {
        maximum = revision;
      }
    }
    return maximum;
  }

  List<TripTrackingReviewRecord> get pendingReviews {
    if (_box == null) {
      return _memoryReviews.values
          .where((review) => review.hasValidTimeline)
          .toList(growable: false)
        ..sort((a, b) => b.finishedAt.compareTo(a.finishedAt));
    }
    return _box.keys
        .whereType<String>()
        .where((key) => key.startsWith(_reviewPrefix))
        .map((key) => _box.get(key))
        .whereType<Map>()
        .map(TripTrackingReviewRecord.fromMap)
        .where((review) => review.hasValidTimeline)
        .toList(growable: false)
      ..sort((a, b) => b.finishedAt.compareTo(a.finishedAt));
  }

  TripTrackingReviewRecord? reviewForTrip(String tripId) {
    if (!_isSafeStoreIdentifier(tripId)) return null;
    final value = _box == null
        ? _memoryReviews[tripId]
        : _box.get('$_reviewPrefix$tripId');
    if (value is TripTrackingReviewRecord) {
      return value.hasValidTimeline ? value : null;
    }
    if (value is Map) {
      final review = TripTrackingReviewRecord.fromMap(value);
      return review.hasValidTimeline ? review : null;
    }
    return null;
  }

  TripTrackingReviewRecord? recoveryReviewForTrip(String tripId) {
    if (!_isSafeStoreIdentifier(tripId)) return null;
    final value = _box == null
        ? _memoryReviews[tripId]
        : _box.get('$_reviewPrefix$tripId');
    if (value is TripTrackingReviewRecord) return value;
    if (value is Map) return TripTrackingReviewRecord.fromMap(value);
    return null;
  }

  Future<void> save(TripTrackingSessionRecord session) =>
      _enqueue(() => _saveSession(session));

  Future<bool> createIfNoSessionEvidence(
    TripTrackingSessionRecord session,
  ) async {
    final reserved = await _enqueue(() async {
      final hasEvidence = _box == null
          ? _memorySession != null
          : _box.containsKey(_activeSessionKey) ||
                _box.containsKey(_previousSessionKey) ||
                _box.containsKey(_pendingSessionWriteKey);
      if (hasEvidence) return false;
      if (_box == null) {
        _memorySession = session;
      } else {
        await _box.put(_pendingSessionWriteKey, session.toMap());
      }
      return true;
    });
    if (!reserved) return false;
    try {
      // Preserve dynamic dispatch so test and platform stores can enforce their
      // normal write behavior after this store-wide atomic reservation.
      await save(session);
      return true;
    } catch (_) {
      await _releaseFailedMemoryReservation(session.id);
      rethrow;
    }
  }

  Future<void> _releaseFailedMemoryReservation(String sessionId) =>
      _enqueue(() async {
        if (_box == null && _memorySession?.id == sessionId) {
          _memorySession = null;
        }
      });

  Future<void> _saveSession(TripTrackingSessionRecord session) async {
    if (!_isSafeStoreIdentifier(session.id)) {
      throw ArgumentError.value(
        session.id,
        'session.id',
        'Active GPS sessions require a non-empty safe trip id.',
      );
    }
    if (!_isSafeStoreIdentifier(session.vehicleId)) {
      throw ArgumentError.value(
        session.vehicleId,
        'session.vehicleId',
        'Active GPS sessions require a non-empty safe vehicle id.',
      );
    }
    if (!_isSafeStoreIdentifier(session.effectiveProfileId)) {
      throw ArgumentError.value(
        session.effectiveProfileId,
        'session.profileId',
        'Active GPS sessions require a non-empty safe profile id.',
      );
    }
    if (!session.hasValidTimeline ||
        session.updatedAt.isBefore(session.startedAt) ||
        session.vehicleConfigurationRevision < 0 ||
        !_isValidTimeZoneOffset(session.startedTimeZoneOffsetMinutes) ||
        !_isSafeTimeZoneName(session.startedTimeZoneName) ||
        !_sessionAdvisoriesAreValid(session) ||
        !_sessionTripEventsAreValid(session) ||
        !_sessionTransitionAuditsAreValid(session) ||
        !_recoveryEvidenceIsValid(
          permissionHistory: session.permissionHistory,
          batteryStateSummary: session.batteryStateSummary,
          latestAt: session.updatedAt,
        )) {
      throw ArgumentError.value(
        session.id,
        'session',
        'Active GPS sessions require a sane timeline and known profile.',
      );
    }
    if (session.startingOdometer < 0) {
      throw ArgumentError.value(
        session.startingOdometer,
        'session.startingOdometer',
        'Active GPS sessions require a non-negative starting odometer.',
      );
    }
    if (_storageCheck != null) await _ensureStorageForWrite();
    if (_box == null) {
      // Keep the in-memory test/runtime adapter behaviorally identical to the
      // Hive boundary: bounded collections, UTC timestamps, and schema
      // normalization must not depend on which local adapter is active.
      _memorySession = TripTrackingSessionRecord.fromMap(session.toMap());
    } else {
      final generation = _maximumRawRecoveryGeneration + 1;
      final next = TripTrackingSessionSnapshotEnvelope.create(
        generation: generation,
        sessionId: session.id,
        payload: session.toMap(),
      ).toMap();
      final current = _box.get(_activeSessionKey);
      final writes = <String, Object?>{_pendingSessionWriteKey: next};
      if (current != null) writes[_previousSessionKey] = current;
      await _box.putAll(writes);
      await _box.put(_activeSessionKey, next);
      await _box.delete(_pendingSessionWriteKey);
    }
  }

  Future<void> clear() => _enqueue(() async {
    _memorySession = null;
    await _box?.deleteAll([
      _activeSessionKey,
      _previousSessionKey,
      _pendingSessionWriteKey,
    ]);
  });

  /// Releases active ownership only after preserving the complete valid
  /// checkpoint for explicit recovery or user-directed deletion.
  Future<bool> quarantineActiveSession({
    required String sessionId,
    required String reasonCode,
    DateTime? quarantinedAtUtc,
  }) => _enqueue(() async {
    if (!_isSafeStoreIdentifier(sessionId) ||
        !_isSafeStoreIdentifier(reasonCode)) {
      return false;
    }
    final current = activeSession;
    if (current == null || current.id != sessionId) return false;
    if (_storageCheck != null) await _ensureStorageForWrite();
    final record = TripTrackingQuarantinedSession(
      sessionId: current.id,
      revision: current.revision,
      sessionPayload: Map.unmodifiable(current.toMap()),
      reasonCode: reasonCode,
      quarantinedAtUtc: (quarantinedAtUtc ?? DateTime.now()).toUtc(),
    );
    final key = '$_quarantinedPrefix${current.id}:${current.revision}';
    if (_box == null) {
      _memoryQuarantined[key] = record;
      _memorySession = null;
    } else {
      await _box.put(key, record.toMap());
      await _box.deleteAll([
        _activeSessionKey,
        _previousSessionKey,
        _pendingSessionWriteKey,
      ]);
    }
    return true;
  });

  TripTrackingPendingSample? pendingSampleFor(String sessionId) {
    if (!_isSafePendingSessionId(sessionId)) return null;
    final value = _box == null
        ? _memoryPending[sessionId]
        : _box.get('$_pendingPrefix$sessionId');
    if (value is TripTrackingPendingSample) return value;
    if (value is Map) return TripTrackingPendingSample.tryFromMap(value);
    return null;
  }

  Future<void> savePending(
    TripTrackingPendingSample pending,
  ) => _enqueue(() async {
    if (!_isSafePendingSessionId(pending.sessionId)) {
      throw ArgumentError.value(
        pending.sessionId,
        'sessionId',
        'Pending GPS samples require a non-empty safe trip id.',
      );
    }
    if (!pending.sample.hasValidCoordinate ||
        !pending.sample.hasValidAccuracy ||
        !pending.sample.hasValidReportedSpeed ||
        pending.sample.mockedLocation == true) {
      throw ArgumentError.value(
        pending.sample,
        'sample',
        'Pending GPS samples require trusted coordinates, accuracy, and speed.',
      );
    }
    if (pending.activity != null &&
        !_isSafePendingActivity(pending.sample, pending.activity)) {
      throw ArgumentError.value(
        pending.activity,
        'activity',
        'Pending GPS activity evidence must be bounded and coherent.',
      );
    }
    if (_storageCheck != null) await _ensureStorageForWrite();
    if (_box == null) {
      _memoryPending[pending.sessionId] = pending;
    } else {
      await _box.put('$_pendingPrefix${pending.sessionId}', pending.toMap());
    }
  });

  Future<void> clearPending(String sessionId) => _enqueue(() async {
    if (!_isSafePendingSessionId(sessionId)) return;
    _memoryPending.remove(sessionId);
    await _box?.delete('$_pendingPrefix$sessionId');
  });

  /// This write must happen before clearing [activeSession]. A duplicate write
  /// is safe because the trip id is the record key.
  Future<void> saveReview(TripTrackingReviewRecord review) =>
      _enqueue(() async {
        if (!_isSafeStoreIdentifier(review.id)) {
          throw ArgumentError.value(
            review.id,
            'review.id',
            'Trip reviews require a non-empty safe trip id.',
          );
        }
        if (!_isSafeStoreIdentifier(review.vehicleId)) {
          throw ArgumentError.value(
            review.vehicleId,
            'review.vehicleId',
            'Trip reviews require a non-empty safe vehicle id.',
          );
        }
        if (!_isSafeStoreIdentifier(review.effectiveProfileId)) {
          throw ArgumentError.value(
            review.effectiveProfileId,
            'review.profileId',
            'Trip reviews require a non-empty safe profile id.',
          );
        }
        if (!review.hasValidTimeline ||
            review.finishedAt.isBefore(review.startedAt) ||
            review.vehicleConfigurationRevision < 0 ||
            !_isValidTimeZoneOffset(review.startedTimeZoneOffsetMinutes) ||
            !_isSafeTimeZoneName(review.startedTimeZoneName) ||
            !_isValidTimeZoneOffset(review.finishedTimeZoneOffsetMinutes) ||
            !_isSafeTimeZoneName(review.finishedTimeZoneName) ||
            !_reviewAdvisoriesAreValid(review) ||
            !_reviewTripEventsAreValid(review) ||
            !_reviewTransitionAuditsAreValid(review) ||
            !_reviewManualAdjustmentsAreValid(review) ||
            !_recoveryEvidenceIsValid(
              permissionHistory: review.permissionHistory,
              batteryStateSummary: review.batteryStateSummary,
              latestAt: review.finishedAt,
            ) ||
            review.startingOdometer < 0 ||
            review.estimatedEndingOdometer < review.startingOdometer ||
            !_hasValidCloudBackupScopeBinding(
              review.cloudBackupScope,
              review.cloudOrganizationId,
            ) ||
            ((review.confirmedEndingOdometer != null ||
                    review.odometerConfirmedAt != null) &&
                !review.isOdometerConfirmed)) {
          throw ArgumentError.value(
            review.id,
            'review',
            'Trip reviews require a sane timeline and odometer range.',
          );
        }
        final existing = reviewForTrip(review.id);
        if (existing != null) {
          if (review.revision < existing.revision ||
              (review.revision == existing.revision &&
                  jsonEncode(review.toMap()) != jsonEncode(existing.toMap()))) {
            throw StateError(
              'A stale trip review cannot overwrite newer local evidence.',
            );
          }
          if (review.revision == existing.revision) return;
        }
        if (_storageCheck != null) await _ensureStorageForWrite();
        if (_box == null) {
          _memoryReviews[review.id] = TripTrackingReviewRecord.fromMap(
            review.toMap(),
          );
        } else {
          await _box.put('$_reviewPrefix${review.id}', review.toMap());
        }
      });

  Future<void> _ensureStorageForWrite() async {
    final check = _storageCheck;
    if (check == null) return;
    final storage = await check();
    if (!storage.hasEnoughSpace) throw StateError(storage.blockingMessage());
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final next = _sharedWriteTail.then((_) => operation());
    _sharedWriteTail = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }

  static Future<AppStorageCheck> _defaultStorageCheck() =>
      AppStorageGuard.check(AppStoragePurpose.mileageTracking);

  _StoredSessionCandidate? _selectedStoredSession() {
    final active = _storedSessionCandidate(
      _box?.get(_activeSessionKey),
      priority: 3,
    );
    final candidates =
        <_StoredSessionCandidate?>[
              active,
              _storedSessionCandidate(
                _box?.get(_pendingSessionWriteKey),
                priority: 2,
              ),
              _storedSessionCandidate(
                _box?.get(_previousSessionKey),
                priority: 1,
              ),
            ]
            .whereType<_StoredSessionCandidate>()
            .where(
              (candidate) =>
                  active == null || candidate.session.id == active.session.id,
            )
            .toList();
    if (candidates.isEmpty) return null;
    candidates.sort(_compareStoredCandidates);
    return candidates.first;
  }

  int get _maximumRawRecoveryGeneration {
    if (_box == null) return _memorySession?.revision ?? 0;
    var maximum = 0;
    for (final key in [
      _activeSessionKey,
      _previousSessionKey,
      _pendingSessionWriteKey,
    ]) {
      final raw = _box.get(key);
      final generation = raw is Map ? raw['generation'] : null;
      if (generation is int && generation > maximum) maximum = generation;
    }
    return maximum;
  }
}

enum TripTrackingPendingWriteState {
  none,
  interrupted,
  committedCleanupPending,
  malformed,
}

TripTrackingSessionRecord? _validSessionFromValue(Object? value) {
  final payload = _rawSessionPayload(value);
  final session = value is TripTrackingSessionRecord
      ? value
      : payload != null
      ? TripTrackingSessionRecord.fromMap(payload)
      : null;
  if (session == null ||
      !session.hasValidTimeline ||
      !_isSafeStoreIdentifier(session.id) ||
      !_isSafeStoreIdentifier(session.vehicleId) ||
      session.startingOdometer < 0 ||
      session.updatedAt.isBefore(session.startedAt)) {
    return null;
  }
  return session;
}

Map<dynamic, dynamic>? _rawSessionPayload(Object? value) {
  if (value is! Map) return null;
  if (value.containsKey('payload') || value.containsKey('checksum')) {
    return TripTrackingSessionSnapshotEnvelope.tryFromMap(value)?.payload;
  }
  return value;
}

_StoredSessionCandidate? _storedSessionCandidate(
  Object? value, {
  required int priority,
}) {
  final session = _validSessionFromValue(value);
  if (session == null) return null;
  final envelope = value is Map
      ? TripTrackingSessionSnapshotEnvelope.tryFromMap(value)
      : null;
  return _StoredSessionCandidate(
    session: session,
    generation: envelope?.generation ?? 0,
    priority: priority,
  );
}

bool _candidateIsAtLeast(
  _StoredSessionCandidate left,
  _StoredSessionCandidate right,
) =>
    left.generation > right.generation ||
    (left.generation == right.generation &&
        left.session.revision >= right.session.revision);

int _compareStoredCandidates(
  _StoredSessionCandidate left,
  _StoredSessionCandidate right,
) {
  final generation = right.generation.compareTo(left.generation);
  if (generation != 0) return generation;
  final revision = right.session.revision.compareTo(left.session.revision);
  if (revision != 0) return revision;
  return right.priority.compareTo(left.priority);
}

class _StoredSessionCandidate {
  const _StoredSessionCandidate({
    required this.session,
    required this.generation,
    required this.priority,
  });

  final TripTrackingSessionRecord session;
  final int generation;
  final int priority;
}

bool _isSafePendingSessionId(Object? value) =>
    _isSafeStoreIdentifierValue(value);

bool _isSafeStoreIdentifier(String value) => _isSafeStoreIdentifierValue(value);

bool _isSafeStoreIdentifierValue(Object? value) =>
    value is String &&
    value.trim() == value &&
    value.isNotEmpty &&
    value.length <= 160 &&
    _safeIdentifier(value) == value;

bool _reviewAdvisoriesAreValid(TripTrackingReviewRecord review) =>
    _hasUniqueAdvisoryIds(review.advisories) &&
    review.advisories.every(
      (event) =>
          _isSafeStoreIdentifier(event.id) &&
          event.sessionId == review.id &&
          event.vehicleId == review.vehicleId &&
          event.profile == review.profile &&
          !event.detectedAt.isBefore(review.startedAt) &&
          !event.detectedAt.isAfter(review.finishedAt) &&
          !event.evidenceStartedAt.isBefore(review.startedAt) &&
          !event.evidenceStartedAt.isAfter(review.finishedAt) &&
          !event.evidenceEndedAt.isBefore(event.evidenceStartedAt) &&
          !event.evidenceEndedAt.isAfter(review.finishedAt),
    );

bool _sessionAdvisoriesAreValid(TripTrackingSessionRecord session) =>
    _hasUniqueAdvisoryIds(session.advisories) &&
    session.advisories.every(
      (event) =>
          _isSafeStoreIdentifier(event.id) &&
          event.sessionId == session.id &&
          event.vehicleId == session.vehicleId &&
          event.profile == session.profile &&
          !event.detectedAt.isBefore(session.startedAt) &&
          !event.detectedAt.isAfter(session.updatedAt) &&
          !event.evidenceStartedAt.isBefore(session.startedAt) &&
          !event.evidenceStartedAt.isAfter(session.updatedAt) &&
          !event.evidenceEndedAt.isBefore(event.evidenceStartedAt) &&
          !event.evidenceEndedAt.isAfter(session.updatedAt),
    );

bool _reviewTripEventsAreValid(TripTrackingReviewRecord review) =>
    review.tripEvents.length <= TripManualEvent.maximumPerTrip &&
    _hasUniqueTripEventIds(review.tripEvents) &&
    review.tripEvents.every(
      (event) =>
          event.isValid &&
          !event.occurredAt.isBefore(review.startedAt) &&
          !event.occurredAt.isAfter(review.finishedAt) &&
          (!event.hasAnyTripContext ||
              event.belongsTo(
                expectedSessionId: review.id,
                expectedVehicleId: review.vehicleId,
                expectedProfileId: review.effectiveProfileId,
                tripStartedAt: review.startedAt,
                tripFinishedAt: review.finishedAt,
              )),
    );

bool _reviewManualAdjustmentsAreValid(TripTrackingReviewRecord review) {
  final ids = <String>{};
  for (final adjustment in review.manualAdjustments) {
    final safeNote = _optionalSafeCloudSyncError(
      adjustment.note,
      maxLength: 240,
    );
    if (!adjustment.isValid ||
        !ids.add(adjustment.id) ||
        safeNote != adjustment.note ||
        (review.odometerConfirmedAt != null &&
            adjustment.createdAt.isAfter(review.odometerConfirmedAt!))) {
      return false;
    }
  }
  return true;
}

bool _sessionTripEventsAreValid(TripTrackingSessionRecord session) =>
    session.tripEvents.length <= TripManualEvent.maximumPerTrip &&
    _hasUniqueTripEventIds(session.tripEvents) &&
    session.tripEvents.every(
      (event) =>
          event.belongsTo(
            expectedSessionId: session.id,
            expectedVehicleId: session.vehicleId,
            expectedProfileId: session.effectiveProfileId,
            tripStartedAt: session.startedAt,
            tripFinishedAt: session.updatedAt,
          ) &&
          !event.recordedAt!.isAfter(session.updatedAt),
    );

bool _sessionTransitionAuditsAreValid(TripTrackingSessionRecord session) =>
    _transitionAuditsAreValid(
      session.transitionAudits,
      sessionId: session.id,
      vehicleId: session.vehicleId,
      profile: session.profile,
      profileId: session.effectiveProfileId,
      startedAt: session.startedAt,
      latestAt: session.updatedAt,
    );

bool _reviewTransitionAuditsAreValid(TripTrackingReviewRecord review) =>
    _transitionAuditsAreValid(
      review.transitionAudits,
      sessionId: review.id,
      vehicleId: review.vehicleId,
      profile: review.profile,
      profileId: review.effectiveProfileId,
      startedAt: review.startedAt,
      latestAt: review.finishedAt,
    );

bool _transitionAuditsAreValid(
  Iterable<TripTrackingSessionTransitionAudit> audits, {
  required String sessionId,
  required String vehicleId,
  required TripTrackingProfile profile,
  required String profileId,
  required DateTime startedAt,
  required DateTime latestAt,
}) {
  final ids = <String>{};
  final sequences = <int>{};
  for (final event in audits) {
    if (event.schemaVersion != 1 ||
        !_isSafeStoreIdentifier(event.id) ||
        !ids.add(event.id) ||
        !sequences.add(event.sequenceNumber) ||
        event.sessionId != sessionId ||
        event.vehicleId != vehicleId ||
        event.profile != profile ||
        event.profileId != profileId ||
        event.sequenceNumber < 1 ||
        event.revision < 1 ||
        event.eventTimestamp.isBefore(startedAt) ||
        event.eventTimestamp.isAfter(latestAt)) {
      return false;
    }
  }
  return true;
}

bool _recoveryEvidenceIsValid({
  required Iterable<TripTrackingPermissionEvidence> permissionHistory,
  required TripTrackingBatteryStateSummary? batteryStateSummary,
  required DateTime latestAt,
}) {
  for (final evidence in permissionHistory) {
    if (evidence.observedAt.isAfter(latestAt) ||
        !_isSafeEvidenceCode(evidence.state, maxLength: 32) ||
        !_isSafeEvidenceCode(evidence.source, maxLength: 48)) {
      return false;
    }
  }
  final battery = batteryStateSummary;
  return battery == null ||
      (!battery.observedAt.isAfter(latestAt) &&
          (battery.batteryPercent == null ||
              (battery.batteryPercent! >= 0 &&
                  battery.batteryPercent! <= 100)) &&
          _isSafeEvidenceCode(battery.reasonCode, maxLength: 80));
}

bool _hasUniqueTripEventIds(Iterable<TripManualEvent> events) {
  final ids = <String>{};
  for (final event in events) {
    if (!ids.add(event.id)) return false;
  }
  return true;
}

bool _hasUniqueAdvisoryIds(Iterable<TripTrackingAdvisoryEvent> advisories) {
  final ids = <String>{};
  for (final advisory in advisories) {
    if (!ids.add(advisory.id)) return false;
  }
  return true;
}
