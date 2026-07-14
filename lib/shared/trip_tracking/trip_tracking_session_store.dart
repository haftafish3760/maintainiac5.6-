import 'package:hive_flutter/hive_flutter.dart';

import 'trip_tracking_models.dart';

class TripTrackingSessionRecord {
  const TripTrackingSessionRecord({
    required this.id,
    required this.vehicleId,
    required this.startingOdometer,
    required this.profile,
    required this.startedAt,
    required this.updatedAt,
    required this.engineSnapshot,
    this.advisories = const [],
    this.lifecycleState = TripTrackingSessionLifecycleState.ready,
    this.healthState = TripTrackingHealthState.healthy,
    this.schemaVersion = 1,
  });

  final String id;
  final String vehicleId;
  final int startingOdometer;
  final TripTrackingProfile profile;
  final DateTime startedAt;
  final DateTime updatedAt;
  final TripTrackingEngineSnapshot engineSnapshot;
  final List<TripTrackingAdvisoryEvent> advisories;
  final TripTrackingSessionLifecycleState lifecycleState;
  final TripTrackingHealthState healthState;
  final int schemaVersion;

  TripTrackingSessionRecord copyWith({
    DateTime? updatedAt,
    TripTrackingEngineSnapshot? engineSnapshot,
    List<TripTrackingAdvisoryEvent>? advisories,
    TripTrackingSessionLifecycleState? lifecycleState,
    TripTrackingHealthState? healthState,
    int? schemaVersion,
  }) => TripTrackingSessionRecord(
    id: id,
    vehicleId: vehicleId,
    startingOdometer: startingOdometer,
    profile: profile,
    startedAt: startedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    engineSnapshot: engineSnapshot ?? this.engineSnapshot,
    advisories: advisories ?? this.advisories,
    lifecycleState: lifecycleState ?? this.lifecycleState,
    healthState: healthState ?? this.healthState,
    schemaVersion: schemaVersion ?? this.schemaVersion,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'vehicleId': vehicleId,
    'startingOdometer': startingOdometer,
    'profile': profile.name,
    'startedAt': startedAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'engineSnapshot': engineSnapshot.toMap(),
    'advisories': advisories.map((item) => item.toMap()).toList(),
    'lifecycleState': lifecycleState.name,
    'healthState': healthState.name,
    'schemaVersion': schemaVersion,
  };

  factory TripTrackingSessionRecord.fromMap(
    Map<dynamic, dynamic> map,
  ) => TripTrackingSessionRecord(
    id: '${map['id'] ?? ''}',
    vehicleId: '${map['vehicleId'] ?? ''}',
    startingOdometer: (map['startingOdometer'] as num?)?.round() ?? 0,
    profile: TripTrackingProfile.values.firstWhere(
      (value) => value.name == map['profile'],
      orElse: () => TripTrackingProfile.roadVehicle,
    ),
    startedAt: DateTime.tryParse('${map['startedAt'] ?? ''}') ?? DateTime.now(),
    updatedAt: DateTime.tryParse('${map['updatedAt'] ?? ''}') ?? DateTime.now(),
    engineSnapshot: map['engineSnapshot'] is Map
        ? TripTrackingEngineSnapshot.fromMap(map['engineSnapshot'] as Map)
        : const TripTrackingEngineSnapshot(
            totalAcceptedMeters: 0,
            walkingReviewSuggested: false,
          ),
    advisories:
        (map['advisories'] as Iterable?)
            ?.whereType<Map>()
            .map(TripTrackingAdvisoryEvent.fromMap)
            .toList(growable: false) ??
        const [],
    lifecycleState: TripTrackingSessionLifecycleState.values.firstWhere(
      (value) => value.name == map['lifecycleState'],
      orElse: () => TripTrackingSessionLifecycleState.ready,
    ),
    healthState: TripTrackingHealthState.values.firstWhere(
      (value) => value.name == map['healthState'],
      orElse: () => TripTrackingHealthState.healthy,
    ),
    schemaVersion: _sessionSchemaVersion(map['schemaVersion']),
  );
}

/// A locally durable handoff from active tracking into review. It intentionally
/// preserves the measured distance and the final engine state; the permanent
/// odometer event is created only after the user reviews this record.
enum TripTrackingCloudSyncState { localOnly, pending, queued, synced, failed }

enum TripTrackingCloudBackupScope { personal, organization }

class TripTrackingReviewRecord {
  const TripTrackingReviewRecord({
    required this.id,
    required this.vehicleId,
    required this.startingOdometer,
    required this.estimatedEndingOdometer,
    required this.profile,
    required this.startedAt,
    required this.finishedAt,
    required this.engineSnapshot,
    this.cloudSyncState = TripTrackingCloudSyncState.localOnly,
    this.cloudAccountUid,
    this.cloudBackupScope,
    this.cloudOrganizationId,
    this.cloudSyncError,
    this.cloudSyncedAt,
    this.confirmedEndingOdometer,
    this.odometerConfirmedAt,
    this.schemaVersion = 1,
  });

  final String id;
  final String vehicleId;
  final int startingOdometer;
  final int estimatedEndingOdometer;
  final TripTrackingProfile profile;
  final DateTime startedAt;
  final DateTime finishedAt;
  final TripTrackingEngineSnapshot engineSnapshot;
  final TripTrackingCloudSyncState cloudSyncState;
  final String? cloudAccountUid;

  /// Immutable once backup has been queued, preventing later profile or
  /// organization changes from redirecting a pending mileage summary.
  final TripTrackingCloudBackupScope? cloudBackupScope;
  final String? cloudOrganizationId;
  final String? cloudSyncError;
  final DateTime? cloudSyncedAt;
  final int? confirmedEndingOdometer;
  final DateTime? odometerConfirmedAt;
  final int schemaVersion;

  bool get needsWalkingReview => engineSnapshot.walkingReviewSuggested;
  bool get isOdometerConfirmed =>
      confirmedEndingOdometer != null && odometerConfirmedAt != null;

  TripTrackingReviewRecord copyWith({
    TripTrackingCloudSyncState? cloudSyncState,
    String? cloudAccountUid,
    TripTrackingCloudBackupScope? cloudBackupScope,
    String? cloudOrganizationId,
    String? cloudSyncError,
    bool clearCloudSyncError = false,
    DateTime? cloudSyncedAt,
    int? confirmedEndingOdometer,
    DateTime? odometerConfirmedAt,
  }) => TripTrackingReviewRecord(
    id: id,
    vehicleId: vehicleId,
    startingOdometer: startingOdometer,
    estimatedEndingOdometer: estimatedEndingOdometer,
    profile: profile,
    startedAt: startedAt,
    finishedAt: finishedAt,
    engineSnapshot: engineSnapshot,
    cloudSyncState: cloudSyncState ?? this.cloudSyncState,
    cloudAccountUid: cloudAccountUid ?? this.cloudAccountUid,
    cloudBackupScope: cloudBackupScope ?? this.cloudBackupScope,
    cloudOrganizationId: cloudOrganizationId ?? this.cloudOrganizationId,
    cloudSyncError: clearCloudSyncError
        ? null
        : cloudSyncError ?? this.cloudSyncError,
    cloudSyncedAt: cloudSyncedAt ?? this.cloudSyncedAt,
    confirmedEndingOdometer:
        confirmedEndingOdometer ?? this.confirmedEndingOdometer,
    odometerConfirmedAt: odometerConfirmedAt ?? this.odometerConfirmedAt,
    schemaVersion: schemaVersion,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'vehicleId': vehicleId,
    'startingOdometer': startingOdometer,
    'estimatedEndingOdometer': estimatedEndingOdometer,
    'profile': profile.name,
    'startedAt': startedAt.toIso8601String(),
    'finishedAt': finishedAt.toIso8601String(),
    'engineSnapshot': engineSnapshot.toMap(),
    'cloudSyncState': cloudSyncState.name,
    if (cloudAccountUid != null) 'cloudAccountUid': cloudAccountUid,
    if (cloudBackupScope != null) 'cloudBackupScope': cloudBackupScope!.name,
    if (cloudOrganizationId != null) 'cloudOrganizationId': cloudOrganizationId,
    if (cloudSyncError != null) 'cloudSyncError': cloudSyncError,
    if (cloudSyncedAt != null)
      'cloudSyncedAt': cloudSyncedAt!.toUtc().toIso8601String(),
    if (confirmedEndingOdometer != null)
      'confirmedEndingOdometer': confirmedEndingOdometer,
    if (odometerConfirmedAt != null)
      'odometerConfirmedAt': odometerConfirmedAt!.toUtc().toIso8601String(),
    'schemaVersion': schemaVersion,
  };

  factory TripTrackingReviewRecord.fromMap(
    Map<dynamic, dynamic> map,
  ) => TripTrackingReviewRecord(
    id: '${map['id'] ?? ''}',
    vehicleId: '${map['vehicleId'] ?? ''}',
    startingOdometer: (map['startingOdometer'] as num?)?.round() ?? 0,
    estimatedEndingOdometer:
        (map['estimatedEndingOdometer'] as num?)?.round() ?? 0,
    profile: TripTrackingProfile.values.firstWhere(
      (value) => value.name == map['profile'],
      orElse: () => TripTrackingProfile.roadVehicle,
    ),
    startedAt: DateTime.tryParse('${map['startedAt'] ?? ''}') ?? DateTime.now(),
    finishedAt:
        DateTime.tryParse('${map['finishedAt'] ?? ''}') ?? DateTime.now(),
    engineSnapshot: map['engineSnapshot'] is Map
        ? TripTrackingEngineSnapshot.fromMap(map['engineSnapshot'] as Map)
        : const TripTrackingEngineSnapshot(
            totalAcceptedMeters: 0,
            walkingReviewSuggested: false,
          ),
    cloudSyncState: TripTrackingCloudSyncState.values.firstWhere(
      (value) => value.name == map['cloudSyncState'],
      orElse: () => TripTrackingCloudSyncState.localOnly,
    ),
    cloudAccountUid: map['cloudAccountUid'] is String
        ? map['cloudAccountUid'] as String
        : null,
    confirmedEndingOdometer: (map['confirmedEndingOdometer'] as num?)?.round(),
    odometerConfirmedAt: DateTime.tryParse(
      '${map['odometerConfirmedAt'] ?? ''}',
    ),
    cloudBackupScope: map['cloudBackupScope'] is String
        ? TripTrackingCloudBackupScope.values.firstWhere(
            (value) => value.name == map['cloudBackupScope'],
            orElse: () => TripTrackingCloudBackupScope.personal,
          )
        : null,
    cloudOrganizationId:
        map['cloudBackupScope'] is String &&
            map['cloudOrganizationId'] is String
        ? map['cloudOrganizationId'] as String
        : null,
    cloudSyncError: map['cloudSyncError'] is String
        ? map['cloudSyncError'] as String
        : null,
    cloudSyncedAt: DateTime.tryParse('${map['cloudSyncedAt'] ?? ''}'),
    schemaVersion: _sessionSchemaVersion(map['schemaVersion']),
  );
}

int _sessionSchemaVersion(Object? value) {
  final version = (value as num?)?.toInt() ?? 1;
  return version < 1 ? 1 : version;
}

/// One durable, bounded checkpoint for a sample currently entering the shared
/// engine. Native events are serialized, so a single record closes the crash
/// window without retaining an unbounded raw-location backlog.
class TripTrackingPendingSample {
  const TripTrackingPendingSample({
    required this.sessionId,
    required this.sample,
    this.activity,
  });

  final String sessionId;
  final TripLocationSample sample;
  final TripActivityObservation? activity;

  Map<String, Object?> toMap() => {
    'sessionId': sessionId,
    'sample': sample.toMap(),
    'activity': activity?.toMap(),
  };

  static TripTrackingPendingSample? tryFromMap(Map<dynamic, dynamic> map) {
    final sampleMap = map['sample'];
    if (map['sessionId'] is! String ||
        (map['sessionId'] as String).isEmpty ||
        sampleMap is! Map) {
      return null;
    }
    final sample = TripLocationSample.tryFromMap(sampleMap);
    if (sample == null) return null;
    return TripTrackingPendingSample(
      sessionId: map['sessionId'] as String,
      sample: sample,
      activity: map['activity'] is Map
          ? TripActivityObservation.tryFromMap(map['activity'] as Map)
          : null,
    );
  }
}

class TripTrackingSessionStore {
  TripTrackingSessionStore._(this._box);
  TripTrackingSessionStore.memory() : _box = null;

  static const boxName = 'active_gps_trip_tracking_session';
  static const _activeSessionKey = 'activeSession';
  static const _reviewPrefix = 'review:';
  static const _pendingPrefix = 'pending:';

  final Box<dynamic>? _box;
  TripTrackingSessionRecord? _memorySession;
  final Map<String, TripTrackingReviewRecord> _memoryReviews = {};
  final Map<String, TripTrackingPendingSample> _memoryPending = {};

  static Future<TripTrackingSessionStore> create() async {
    final box = await Hive.openBox<dynamic>(boxName);
    return TripTrackingSessionStore._(box);
  }

  TripTrackingSessionRecord? get activeSession {
    final value = _box == null ? _memorySession : _box.get(_activeSessionKey);
    if (value is TripTrackingSessionRecord) return value;
    if (value is Map) return TripTrackingSessionRecord.fromMap(value);
    return null;
  }

  List<TripTrackingReviewRecord> get pendingReviews {
    if (_box == null) {
      return _memoryReviews.values.toList(growable: false)
        ..sort((a, b) => b.finishedAt.compareTo(a.finishedAt));
    }
    return _box.keys
        .whereType<String>()
        .where((key) => key.startsWith(_reviewPrefix))
        .map((key) => _box.get(key))
        .whereType<Map>()
        .map(TripTrackingReviewRecord.fromMap)
        .toList(growable: false)
      ..sort((a, b) => b.finishedAt.compareTo(a.finishedAt));
  }

  TripTrackingReviewRecord? reviewForTrip(String tripId) {
    final value = _box == null
        ? _memoryReviews[tripId]
        : _box.get('$_reviewPrefix$tripId');
    if (value is TripTrackingReviewRecord) return value;
    if (value is Map) return TripTrackingReviewRecord.fromMap(value);
    return null;
  }

  Future<void> save(TripTrackingSessionRecord session) async {
    if (_box == null) {
      _memorySession = session;
    } else {
      await _box.put(_activeSessionKey, session.toMap());
    }
  }

  Future<void> clear() async {
    _memorySession = null;
    await _box?.delete(_activeSessionKey);
  }

  TripTrackingPendingSample? pendingSampleFor(String sessionId) {
    final value = _box == null
        ? _memoryPending[sessionId]
        : _box.get('$_pendingPrefix$sessionId');
    if (value is TripTrackingPendingSample) return value;
    if (value is Map) return TripTrackingPendingSample.tryFromMap(value);
    return null;
  }

  Future<void> savePending(TripTrackingPendingSample pending) async {
    if (_box == null) {
      _memoryPending[pending.sessionId] = pending;
    } else {
      await _box.put('$_pendingPrefix${pending.sessionId}', pending.toMap());
    }
  }

  Future<void> clearPending(String sessionId) async {
    _memoryPending.remove(sessionId);
    await _box?.delete('$_pendingPrefix$sessionId');
  }

  /// This write must happen before clearing [activeSession]. A duplicate write
  /// is safe because the trip id is the record key.
  Future<void> saveReview(TripTrackingReviewRecord review) async {
    if (_box == null) {
      _memoryReviews[review.id] = review;
    } else {
      await _box.put('$_reviewPrefix${review.id}', review.toMap());
    }
  }
}
