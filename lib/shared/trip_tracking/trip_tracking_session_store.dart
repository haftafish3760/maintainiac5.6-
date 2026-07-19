import 'package:hive_flutter/hive_flutter.dart';

import '../storage/app_storage_guard.dart';
import 'trip_tracking_models.dart';

typedef TripTrackingSessionStorageCheck = Future<AppStorageCheck> Function();

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
    this.backgroundTrackingAllowed = false,
    this.activityRecognitionEnabled = false,
    this.hasValidTimeline = true,
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

  /// Locally persisted consent for a collector that survives an app restart.
  /// Missing legacy values default to false; recovery never assumes consent.
  final bool backgroundTrackingAllowed;

  /// Explicit local consent for optional walking-assisted stop evidence.
  /// Missing legacy values remain false so recovery never expands collection.
  final bool activityRecognitionEnabled;
  final bool hasValidTimeline;
  final int schemaVersion;

  TripTrackingSessionRecord copyWith({
    DateTime? updatedAt,
    TripTrackingEngineSnapshot? engineSnapshot,
    List<TripTrackingAdvisoryEvent>? advisories,
    TripTrackingSessionLifecycleState? lifecycleState,
    TripTrackingHealthState? healthState,
    bool? backgroundTrackingAllowed,
    bool? activityRecognitionEnabled,
    bool? hasValidTimeline,
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
    backgroundTrackingAllowed:
        backgroundTrackingAllowed ?? this.backgroundTrackingAllowed,
    activityRecognitionEnabled:
        activityRecognitionEnabled ?? this.activityRecognitionEnabled,
    hasValidTimeline: hasValidTimeline ?? this.hasValidTimeline,
    schemaVersion: schemaVersion ?? this.schemaVersion,
  );

  Map<String, Object?> toMap() => {
    'id': _safeIdentifier(id),
    'vehicleId': _safeIdentifier(vehicleId),
    'startingOdometer': _persistedOdometerValue(startingOdometer),
    'profile': profile.name,
    'startedAt': startedAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'engineSnapshot': engineSnapshot.toMap(),
    'advisories': _boundedAdvisories(
      advisories,
    ).map((item) => item.toMap()).toList(),
    'lifecycleState': lifecycleState.name,
    'healthState': healthState.name,
    'backgroundTrackingAllowed': backgroundTrackingAllowed,
    'activityRecognitionEnabled': activityRecognitionEnabled,
    'schemaVersion': schemaVersion,
  };

  factory TripTrackingSessionRecord.fromMap(Map<dynamic, dynamic> map) {
    final startedAt = DateTime.tryParse('${map['startedAt'] ?? ''}');
    final updatedAt = DateTime.tryParse('${map['updatedAt'] ?? ''}');
    final hasSafeIdentity =
        _isSafeStoreIdentifierValue(map['id']) &&
        _isSafeStoreIdentifierValue(map['vehicleId']);
    final hasValidLifecycleState = _hasMissingOrKnownEnumName(
      map,
      'lifecycleState',
      TripTrackingSessionLifecycleState.values.map((value) => value.name),
    );
    final hasValidHealthState = _hasMissingOrKnownEnumName(
      map,
      'healthState',
      TripTrackingHealthState.values.map((value) => value.name),
    );
    final hasValidProfile = _hasKnownEnumName(
      map['profile'],
      TripTrackingProfile.values.map((value) => value.name),
    );
    final hasSupportedSchemaVersion = _hasSupportedSessionSchemaVersion(
      map,
      'schemaVersion',
    );
    final safeId = _safeIdentifier(map['id']);
    final safeVehicleId = _safeIdentifier(map['vehicleId']);
    final safeProfile = TripTrackingProfile.values.firstWhere(
      (value) => value.name == map['profile'],
      orElse: () => TripTrackingProfile.roadVehicle,
    );
    final safeStartedAt =
        startedAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    return TripTrackingSessionRecord(
      id: safeId,
      vehicleId: safeVehicleId,
      startingOdometer: _persistedOdometerValue(map['startingOdometer']),
      profile: safeProfile,
      startedAt: safeStartedAt,
      updatedAt:
          updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      engineSnapshot: map['engineSnapshot'] is Map
          ? TripTrackingEngineSnapshot.fromMap(map['engineSnapshot'] as Map)
          : const TripTrackingEngineSnapshot(
              totalAcceptedMeters: 0,
              walkingReviewSuggested: false,
            ),
      advisories: _advisoriesFromMapValue(
        map['advisories'],
        sessionId: safeId,
        vehicleId: safeVehicleId,
        profile: safeProfile,
        startedAt: safeStartedAt,
      ),
      lifecycleState: TripTrackingSessionLifecycleState.values.firstWhere(
        (value) => value.name == map['lifecycleState'],
        orElse: () => TripTrackingSessionLifecycleState.ready,
      ),
      healthState: TripTrackingHealthState.values.firstWhere(
        (value) => value.name == map['healthState'],
        orElse: () => TripTrackingHealthState.healthy,
      ),
      backgroundTrackingAllowed: map['backgroundTrackingAllowed'] == true,
      activityRecognitionEnabled: map['activityRecognitionEnabled'] == true,
      hasValidTimeline:
          startedAt != null &&
          updatedAt != null &&
          !updatedAt.isBefore(startedAt) &&
          hasSafeIdentity &&
          hasValidProfile &&
          hasValidLifecycleState &&
          hasValidHealthState &&
          hasSupportedSchemaVersion,
      schemaVersion: _sessionSchemaVersion(map['schemaVersion']),
    );
  }
}

const _maxPersistedAdvisories = 24;

Iterable<TripTrackingAdvisoryEvent> _boundedAdvisories(
  Iterable<TripTrackingAdvisoryEvent> advisories,
) {
  final items = advisories.toList(growable: false);
  return items.takeLast(_maxPersistedAdvisories);
}

List<TripTrackingAdvisoryEvent> _advisoriesFromMapValue(
  Object? value, {
  required String sessionId,
  required String vehicleId,
  required TripTrackingProfile profile,
  required DateTime startedAt,
}) {
  if (value is! Iterable) return const [];
  return value
      .whereType<Map>()
      .map(TripTrackingAdvisoryEvent.fromMap)
      .where(
        (event) => _advisoryBelongsToSession(
          event,
          sessionId: sessionId,
          vehicleId: vehicleId,
          profile: profile,
          startedAt: startedAt,
        ),
      )
      .toList(growable: false)
      .takeLast(_maxPersistedAdvisories)
      .toList(growable: false);
}

bool _advisoryBelongsToSession(
  TripTrackingAdvisoryEvent event, {
  required String sessionId,
  required String vehicleId,
  required TripTrackingProfile profile,
  required DateTime startedAt,
}) {
  if (event.sessionId != sessionId ||
      event.vehicleId != vehicleId ||
      event.profile != profile) {
    return false;
  }
  final tripStart = startedAt.toUtc();
  final detectedAt = event.detectedAt.toUtc();
  if (detectedAt.isBefore(tripStart)) return false;
  return !detectedAt.isAfter(tripStart.add(const Duration(days: 30)));
}

extension _TakeLastExtension<T> on List<T> {
  Iterable<T> takeLast(int maxLength) {
    if (length <= maxLength) return this;
    return skip(length - maxLength);
  }
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
    this.hasValidTimeline = true,
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

  /// False only for a persisted record whose required timeline could not be
  /// parsed. Directly-created records are presumed valid.
  final bool hasValidTimeline;

  bool get needsWalkingReview => engineSnapshot.walkingReviewSuggested;
  bool get isOdometerConfirmed =>
      confirmedEndingOdometer != null &&
      confirmedEndingOdometer! >= startingOdometer &&
      odometerConfirmedAt != null &&
      !odometerConfirmedAt!.isBefore(finishedAt);

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
  }) {
    final effectiveScope = cloudBackupScope ?? this.cloudBackupScope;
    final effectiveOrganizationId =
        effectiveScope == TripTrackingCloudBackupScope.organization
        ? _optionalSafeCloudToken(
            cloudOrganizationId ?? this.cloudOrganizationId,
          )
        : null;
    return TripTrackingReviewRecord(
      id: id,
      vehicleId: vehicleId,
      startingOdometer: startingOdometer,
      estimatedEndingOdometer: estimatedEndingOdometer,
      profile: profile,
      startedAt: startedAt,
      finishedAt: finishedAt,
      engineSnapshot: engineSnapshot,
      cloudSyncState: cloudSyncState ?? this.cloudSyncState,
      cloudAccountUid: _optionalSafeCloudToken(
        cloudAccountUid ?? this.cloudAccountUid,
      ),
      cloudBackupScope: effectiveScope,
      cloudOrganizationId: effectiveOrganizationId,
      cloudSyncError: clearCloudSyncError
          ? null
          : _optionalSafeCloudSyncError(
              cloudSyncError ?? this.cloudSyncError,
              maxLength: 240,
            ),
      cloudSyncedAt: cloudSyncedAt ?? this.cloudSyncedAt,
      confirmedEndingOdometer:
          confirmedEndingOdometer ?? this.confirmedEndingOdometer,
      odometerConfirmedAt: odometerConfirmedAt ?? this.odometerConfirmedAt,
      schemaVersion: schemaVersion,
      hasValidTimeline: hasValidTimeline,
    );
  }

  Map<String, Object?> toMap() => {
    'id': _safeIdentifier(id),
    'vehicleId': _safeIdentifier(vehicleId),
    'startingOdometer': _persistedOdometerValue(startingOdometer),
    'estimatedEndingOdometer': _persistedOdometerValue(estimatedEndingOdometer),
    'profile': profile.name,
    'startedAt': startedAt.toIso8601String(),
    'finishedAt': finishedAt.toIso8601String(),
    'engineSnapshot': engineSnapshot.toMap(),
    'cloudSyncState': cloudSyncState.name,
    if (_optionalSafeCloudToken(cloudAccountUid) != null)
      'cloudAccountUid': _optionalSafeCloudToken(cloudAccountUid),
    if (cloudBackupScope != null) 'cloudBackupScope': cloudBackupScope!.name,
    if (_optionalSafeCloudToken(cloudOrganizationId) != null)
      'cloudOrganizationId': _optionalSafeCloudToken(cloudOrganizationId),
    if (_optionalSafeCloudSyncError(cloudSyncError, maxLength: 240) != null)
      'cloudSyncError': _optionalSafeCloudSyncError(
        cloudSyncError,
        maxLength: 240,
      ),
    if (cloudSyncedAt != null)
      'cloudSyncedAt': cloudSyncedAt!.toUtc().toIso8601String(),
    if (_optionalPersistedOdometerValue(confirmedEndingOdometer) != null)
      'confirmedEndingOdometer': _optionalPersistedOdometerValue(
        confirmedEndingOdometer,
      ),
    if (odometerConfirmedAt != null)
      'odometerConfirmedAt': odometerConfirmedAt!.toUtc().toIso8601String(),
    'schemaVersion': schemaVersion,
  };

  factory TripTrackingReviewRecord.fromMap(Map<dynamic, dynamic> map) {
    final startedAt = DateTime.tryParse('${map['startedAt'] ?? ''}');
    final finishedAt = DateTime.tryParse('${map['finishedAt'] ?? ''}');
    final id = _safeIdentifier(map['id']);
    final vehicleId = _safeIdentifier(map['vehicleId']);
    final cloudBackupScope = _cloudBackupScopeFromMap(map['cloudBackupScope']);
    final hasSafeIdentity =
        _isSafeStoreIdentifierValue(map['id']) &&
        _isSafeStoreIdentifierValue(map['vehicleId']);
    final hasValidProfile = _hasKnownEnumName(
      map['profile'],
      TripTrackingProfile.values.map((value) => value.name),
    );
    final hasValidCloudSyncState = _hasMissingOrKnownEnumName(
      map,
      'cloudSyncState',
      TripTrackingCloudSyncState.values.map((value) => value.name),
    );
    final hasSupportedSchemaVersion = _hasSupportedSessionSchemaVersion(
      map,
      'schemaVersion',
    );
    final startingOdometer = _persistedOdometerValue(map['startingOdometer']);
    final estimatedEndingOdometer = _persistedOdometerValue(
      map['estimatedEndingOdometer'],
    );
    final cloudSyncState = TripTrackingCloudSyncState.values.firstWhere(
      (value) => value.name == map['cloudSyncState'],
      orElse: () => TripTrackingCloudSyncState.localOnly,
    );
    final cloudSyncedAt = DateTime.tryParse('${map['cloudSyncedAt'] ?? ''}');
    final confirmedEndingOdometer = _optionalPersistedOdometerValue(
      map['confirmedEndingOdometer'],
    );
    final odometerConfirmedAt = DateTime.tryParse(
      '${map['odometerConfirmedAt'] ?? ''}',
    );
    final hasValidConfirmation =
        (confirmedEndingOdometer == null && odometerConfirmedAt == null) ||
        (confirmedEndingOdometer != null &&
            confirmedEndingOdometer >= startingOdometer &&
            odometerConfirmedAt != null &&
            finishedAt != null &&
            !odometerConfirmedAt.isBefore(finishedAt));
    return TripTrackingReviewRecord(
      id: id,
      vehicleId: vehicleId,
      startingOdometer: startingOdometer,
      estimatedEndingOdometer: estimatedEndingOdometer,
      profile: TripTrackingProfile.values.firstWhere(
        (value) => value.name == map['profile'],
        orElse: () => TripTrackingProfile.roadVehicle,
      ),
      startedAt:
          startedAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      finishedAt:
          finishedAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      engineSnapshot: map['engineSnapshot'] is Map
          ? TripTrackingEngineSnapshot.fromMap(map['engineSnapshot'] as Map)
          : const TripTrackingEngineSnapshot(
              totalAcceptedMeters: 0,
              walkingReviewSuggested: false,
            ),
      cloudSyncState: cloudSyncState,
      cloudAccountUid: _optionalSafeCloudToken(map['cloudAccountUid']),
      confirmedEndingOdometer: confirmedEndingOdometer,
      odometerConfirmedAt: odometerConfirmedAt,
      cloudBackupScope: cloudBackupScope,
      cloudOrganizationId:
          cloudBackupScope == TripTrackingCloudBackupScope.organization
          ? _optionalSafeCloudToken(map['cloudOrganizationId'])
          : null,
      cloudSyncError: _optionalSafeCloudSyncError(
        map['cloudSyncError'],
        maxLength: 240,
      ),
      cloudSyncedAt: cloudSyncedAt,
      schemaVersion: _sessionSchemaVersion(map['schemaVersion']),
      hasValidTimeline:
          startedAt != null &&
          finishedAt != null &&
          !finishedAt.isBefore(startedAt) &&
          hasSafeIdentity &&
          hasValidProfile &&
          hasValidCloudSyncState &&
          _hasValidCloudSyncTimeline(
            cloudSyncState,
            syncedAt: cloudSyncedAt,
            finishedAt: finishedAt,
          ) &&
          _hasValidCloudBackupScopeBinding(
            cloudBackupScope,
            map['cloudOrganizationId'],
          ) &&
          hasValidConfirmation &&
          estimatedEndingOdometer >= startingOdometer &&
          hasSupportedSchemaVersion,
    );
  }
}

bool _hasValidCloudSyncTimeline(
  TripTrackingCloudSyncState state, {
  required DateTime? syncedAt,
  required DateTime? finishedAt,
}) =>
    state != TripTrackingCloudSyncState.synced ||
    (syncedAt != null && finishedAt != null && !syncedAt.isBefore(finishedAt));

bool _hasValidCloudBackupScopeBinding(
  TripTrackingCloudBackupScope? scope,
  Object? organizationId,
) {
  final safeOrganizationId = _optionalSafeCloudToken(organizationId);
  return switch (scope) {
    TripTrackingCloudBackupScope.organization => safeOrganizationId != null,
    TripTrackingCloudBackupScope.personal || null => safeOrganizationId == null,
  };
}

int _sessionSchemaVersion(Object? value) {
  if (value is! int) return 1;
  return value < 1 ? 1 : value;
}

bool _hasSupportedSessionSchemaVersion(Map<dynamic, dynamic> map, String key) {
  if (!map.containsKey(key)) return true;
  final rawVersion = map[key];
  return rawVersion is int && rawVersion >= 1 && rawVersion <= 1;
}

TripTrackingCloudBackupScope? _cloudBackupScopeFromMap(Object? value) {
  if (value is! String) return null;
  for (final scope in TripTrackingCloudBackupScope.values) {
    if (scope.name == value) return scope;
  }
  return null;
}

bool _hasMissingOrKnownEnumName(
  Map<dynamic, dynamic> map,
  String key,
  Iterable<String> allowedNames,
) {
  if (!map.containsKey(key)) return true;
  return _hasKnownEnumName(map[key], allowedNames);
}

bool _hasKnownEnumName(Object? value, Iterable<String> allowedNames) {
  return value is String && allowedNames.contains(value);
}

int _persistedOdometerValue(Object? value) {
  if (value is! num || !value.isFinite) return 0;
  final odometer = value.round();
  return odometer < 0 ? 0 : odometer;
}

int? _optionalPersistedOdometerValue(Object? value) {
  if (value is! num || !value.isFinite) return null;
  final odometer = value.round();
  return odometer < 0 ? null : odometer;
}

String _safeIdentifier(Object? value) {
  final clean = '${value ?? ''}'
      .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ')
      .trim();
  if (clean.isEmpty) return '';
  return clean.length > 160 ? clean.substring(0, 160) : clean;
}

String? _optionalSafeText(Object? value, {required int maxLength}) {
  if (value == null) return null;
  final clean = '$value'.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ').trim();
  if (clean.isEmpty) return null;
  return clean.length > maxLength ? clean.substring(0, maxLength) : clean;
}

String? _optionalSafeCloudSyncError(Object? value, {required int maxLength}) {
  final clean = _optionalSafeText(value, maxLength: maxLength * 2);
  if (clean == null) return null;
  final redacted = clean
      .replaceAll(RegExp(r'\b[ps]k\.[A-Za-z0-9._-]+'), '[redacted_token]')
      .replaceAllMapped(
        RegExp(
          r'\b(token|access[_ -]?token|secret)\s*[:=]\s*\S+',
          caseSensitive: false,
        ),
        (match) => '${match.group(1)}=[redacted]',
      )
      .replaceAll(
        RegExp(r'\b-?\d{1,3}\.\d{3,}\s*,\s*-?\d{1,3}\.\d{3,}\b'),
        '[redacted_coordinates]',
      );
  return redacted.length > maxLength
      ? redacted.substring(0, maxLength)
      : redacted;
}

String? _optionalSafeCloudToken(Object? value) {
  final clean = _optionalSafeText(value, maxLength: 160);
  if (clean == null) return null;
  return RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(clean) ? clean : null;
}

/// One durable, bounded checkpoint for a sample currently entering the shared
/// engine. Native events are serialized, so a single record closes the crash
/// window without retaining an unbounded raw-location backlog.
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
  static const _reviewPrefix = 'review:';
  static const _pendingPrefix = 'pending:';

  final Box<dynamic>? _box;
  TripTrackingSessionRecord? _memorySession;
  final Map<String, TripTrackingReviewRecord> _memoryReviews = {};
  final Map<String, TripTrackingPendingSample> _memoryPending = {};
  final TripTrackingSessionStorageCheck? _storageCheck;
  Future<void> _writeTail = Future<void>.value();

  static Future<TripTrackingSessionStore> create({
    TripTrackingSessionStorageCheck? storageCheck,
  }) async {
    final box = await Hive.openBox<dynamic>(boxName);
    return TripTrackingSessionStore._(box, storageCheck: storageCheck);
  }

  TripTrackingSessionRecord? get activeSession {
    final value = _box == null ? _memorySession : _box.get(_activeSessionKey);
    if (value is TripTrackingSessionRecord) return value;
    if (value is Map) return TripTrackingSessionRecord.fromMap(value);
    return null;
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

  Future<void> save(TripTrackingSessionRecord session) => _enqueue(() async {
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
    if (!session.hasValidTimeline ||
        session.updatedAt.isBefore(session.startedAt)) {
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
      _memorySession = session;
    } else {
      await _box.put(_activeSessionKey, session.toMap());
    }
  });

  Future<void> clear() => _enqueue(() async {
    _memorySession = null;
    await _box?.delete(_activeSessionKey);
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
        if (!review.hasValidTimeline ||
            review.finishedAt.isBefore(review.startedAt) ||
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
    if (_box == null && _storageCheck == null) return operation();
    final next = _writeTail.then((_) => operation());
    _writeTail = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }

  static Future<AppStorageCheck> _defaultStorageCheck() =>
      AppStorageGuard.check(AppStoragePurpose.mileageTracking);
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
