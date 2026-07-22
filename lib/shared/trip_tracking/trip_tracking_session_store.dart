import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../storage/app_storage_guard.dart';
import 'trip_tracking_models.dart';

part 'trip_tracking_session_record.dart';
part 'trip_tracking_review_record.dart';

typedef TripTrackingSessionStorageCheck = Future<AppStorageCheck> Function();

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
  static const _reviewPrefix = 'review:';
  static const _pendingPrefix = 'pending:';

  final Box<dynamic>? _box;
  TripTrackingSessionRecord? _memorySession;
  final Map<String, TripTrackingReviewRecord> _memoryReviews = {};
  final Map<String, TripTrackingPendingSample> _memoryPending = {};
  final TripTrackingSessionStorageCheck? _storageCheck;
  static Future<void> _sharedWriteTail = Future<void>.value();

  static Future<TripTrackingSessionStore> create({
    TripTrackingSessionStorageCheck? storageCheck,
  }) async {
    final box = await Hive.openBox<dynamic>(boxName);
    return TripTrackingSessionStore._(box, storageCheck: storageCheck);
  }

  TripTrackingSessionRecord? get activeSession {
    final value = _box == null ? _memorySession : _box.get(_activeSessionKey);
    final active = _validSessionFromValue(value);
    if (active != null) return active;
    return _box == null
        ? null
        : _validSessionFromValue(_box.get(_previousSessionKey));
  }

  TripTrackingPendingWriteState get pendingWriteState {
    if (_box == null) return TripTrackingPendingWriteState.none;
    final pendingValue = _box.get(_pendingSessionWriteKey);
    if (pendingValue == null) return TripTrackingPendingWriteState.none;
    final pending = _validSessionFromValue(pendingValue);
    if (pending == null) return TripTrackingPendingWriteState.malformed;
    final active = _validSessionFromValue(_box.get(_activeSessionKey));
    return active != null && active.revision >= pending.revision
        ? TripTrackingPendingWriteState.committedCleanupPending
        : TripTrackingPendingWriteState.interrupted;
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
        !_isSafeTimeZoneName(session.startedTimeZoneName)) {
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
      final boundedTransitionAudits = _boundedTransitionAudits(
        session.transitionAudits,
      ).toList();
      _memorySession =
          session.transitionAudits.length == boundedTransitionAudits.length
          ? session
          : TripTrackingSessionRecord(
              id: session.id,
              vehicleId: session.vehicleId,
              vehicleConfigurationRevision:
                  session.vehicleConfigurationRevision,
              startedTimeZoneOffsetMinutes:
                  session.startedTimeZoneOffsetMinutes,
              startedTimeZoneName: session.startedTimeZoneName,
              startingOdometer: session.startingOdometer,
              profile: session.profile,
              profileId: session.effectiveProfileId,
              startedAt: session.startedAt,
              updatedAt: session.updatedAt,
              engineSnapshot: session.engineSnapshot,
              advisories: session.advisories,
              lifecycleState: session.lifecycleState,
              healthState: session.healthState,
              backgroundTrackingAllowed: session.backgroundTrackingAllowed,
              activityRecognitionEnabled: session.activityRecognitionEnabled,
              nativeSampling: session.nativeSampling,
              samplingCeiling: session.samplingCeiling,
              adaptiveSamplingEnabled: session.adaptiveSamplingEnabled,
              lowBatteryProtectionEnabled: session.lowBatteryProtectionEnabled,
              lowBatteryOverrideEnabled: session.lowBatteryOverrideEnabled,
              lowBatteryWarningDismissed: session.lowBatteryWarningDismissed,
              hasValidTimeline: session.hasValidTimeline,
              schemaVersion: session.schemaVersion,
              revision: session.revision,
              recoveryCount: session.recoveryCount,
              transitionAudits: boundedTransitionAudits,
            );
    } else {
      final next = session.toMap();
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
          _memoryReviews[review.id] = review;
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
}

enum TripTrackingPendingWriteState {
  none,
  interrupted,
  committedCleanupPending,
  malformed,
}

TripTrackingSessionRecord? _validSessionFromValue(Object? value) {
  final session = value is TripTrackingSessionRecord
      ? value
      : value is Map
      ? TripTrackingSessionRecord.fromMap(value)
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

bool _isSafePendingSessionId(Object? value) =>
    _isSafeStoreIdentifierValue(value);

bool _isSafeStoreIdentifier(String value) => _isSafeStoreIdentifierValue(value);

bool _isSafeStoreIdentifierValue(Object? value) =>
    value is String &&
    value.trim() == value &&
    value.isNotEmpty &&
    value.length <= 160 &&
    _safeIdentifier(value) == value;
