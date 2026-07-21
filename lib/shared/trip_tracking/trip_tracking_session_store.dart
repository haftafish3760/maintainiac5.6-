import 'package:hive_flutter/hive_flutter.dart';

import '../storage/app_storage_guard.dart';
import 'trip_tracking_cancelled_session.dart';
import 'trip_tracking_lifecycle_event.dart';
import 'trip_tracking_models.dart';
import 'trip_tracking_recovery_diagnostic.dart';
import 'trip_tracking_quarantined_session.dart';
import 'trip_tracking_session_snapshot.dart';
import 'trip_tracking_state_machine.dart';

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
    this.profileId = 'legacy-local-profile',
    this.vehicleConfigurationRevision = 0,
    this.revision = 0,
    this.lastEventSequence = 0,
    this.advisories = const [],
    this.lifecycleState = TripTrackingSessionLifecycleState.preparing,
    this.healthState = TripTrackingHealthState.healthy,
    this.backgroundTrackingAllowed = false,
    this.activityRecognitionEnabled = false,
    this.nativeSampling,
    this.samplingCeiling,
    this.adaptiveSamplingEnabled = false,
    this.lowBatteryProtectionEnabled = true,
    this.lowBatteryOverrideEnabled = false,
    this.lowBatteryWarningDismissed = false,
    this.hasValidTimeline = true,
    this.schemaVersion = 3,
  });

  final String id;
  final String vehicleId;
  final String profileId;
  final int vehicleConfigurationRevision;
  final int revision;
  final int lastEventSequence;
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

  /// Bounded collector configuration survives process recovery so adaptive
  /// sampling cannot silently become more aggressive than the driver's last
  /// selected cadence.
  final TripSamplingRecommendation? nativeSampling;
  final TripSamplingRecommendation? samplingCeiling;
  final bool adaptiveSamplingEnabled;
  final bool lowBatteryProtectionEnabled;
  final bool lowBatteryOverrideEnabled;
  final bool lowBatteryWarningDismissed;
  final bool hasValidTimeline;
  final int schemaVersion;

  TripTrackingSessionRecord copyWith({
    String? profileId,
    int? vehicleConfigurationRevision,
    int? revision,
    int? lastEventSequence,
    DateTime? updatedAt,
    TripTrackingEngineSnapshot? engineSnapshot,
    List<TripTrackingAdvisoryEvent>? advisories,
    TripTrackingSessionLifecycleState? lifecycleState,
    TripTrackingHealthState? healthState,
    bool? backgroundTrackingAllowed,
    bool? activityRecognitionEnabled,
    TripSamplingRecommendation? nativeSampling,
    bool clearNativeSampling = false,
    TripSamplingRecommendation? samplingCeiling,
    bool clearSamplingCeiling = false,
    bool? adaptiveSamplingEnabled,
    bool? lowBatteryProtectionEnabled,
    bool? lowBatteryOverrideEnabled,
    bool? lowBatteryWarningDismissed,
    bool? hasValidTimeline,
    int? schemaVersion,
  }) {
    final nextSamplingCeiling = clearSamplingCeiling
        ? null
        : samplingCeiling ?? this.samplingCeiling;
    final nextNativeSampling = clearNativeSampling
        ? null
        : _recoveredNativeSampling(
            nativeSampling: nativeSampling ?? this.nativeSampling,
            samplingCeiling: nextSamplingCeiling,
          );
    return TripTrackingSessionRecord(
      id: id,
      vehicleId: vehicleId,
      profileId: profileId ?? this.profileId,
      vehicleConfigurationRevision:
          vehicleConfigurationRevision ?? this.vehicleConfigurationRevision,
      revision: revision ?? this.revision,
      lastEventSequence: lastEventSequence ?? this.lastEventSequence,
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
      nativeSampling: nextNativeSampling,
      samplingCeiling: nextSamplingCeiling,
      adaptiveSamplingEnabled:
          adaptiveSamplingEnabled ?? this.adaptiveSamplingEnabled,
      lowBatteryProtectionEnabled:
          lowBatteryProtectionEnabled ?? this.lowBatteryProtectionEnabled,
      lowBatteryOverrideEnabled:
          lowBatteryOverrideEnabled ?? this.lowBatteryOverrideEnabled,
      lowBatteryWarningDismissed:
          lowBatteryWarningDismissed ?? this.lowBatteryWarningDismissed,
      hasValidTimeline: hasValidTimeline ?? this.hasValidTimeline,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  Map<String, Object?> toMap() => {
    'id': _safeIdentifier(id),
    'vehicleId': _safeIdentifier(vehicleId),
    'profileId': _safeIdentifier(profileId),
    'vehicleConfigurationRevision': vehicleConfigurationRevision,
    'revision': revision,
    'lastEventSequence': lastEventSequence,
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
    'nativeSampling': _samplingToMap(nativeSampling),
    'samplingCeiling': _samplingToMap(samplingCeiling),
    'adaptiveSamplingEnabled': adaptiveSamplingEnabled,
    'lowBatteryProtectionEnabled': lowBatteryProtectionEnabled,
    'lowBatteryOverrideEnabled': lowBatteryOverrideEnabled,
    'lowBatteryWarningDismissed': lowBatteryWarningDismissed,
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
    final hasSupportedSchemaVersion = _hasSupportedActiveSessionSchemaVersion(
      map,
      'schemaVersion',
    );
    final safeId = _safeIdentifier(map['id']);
    final safeVehicleId = _safeIdentifier(map['vehicleId']);
    final sourceSchemaVersion = _sessionSchemaVersion(map['schemaVersion']);
    final hasValidVehicleConfigurationRevision =
        sourceSchemaVersion < 3 ||
        (map['vehicleConfigurationRevision'] is int &&
            (map['vehicleConfigurationRevision'] as int) >= 0);
    final safeProfileId = sourceSchemaVersion == 1
        ? 'legacy-local-profile'
        : _safeIdentifier(map['profileId']);
    final revision = map['revision'] is int && (map['revision'] as int) >= 0
        ? map['revision'] as int
        : 0;
    final lastEventSequence =
        map['lastEventSequence'] is int &&
            (map['lastEventSequence'] as int) >= 0
        ? map['lastEventSequence'] as int
        : 0;
    final vehicleConfigurationRevision =
        map['vehicleConfigurationRevision'] is int &&
            (map['vehicleConfigurationRevision'] as int) >= 0
        ? map['vehicleConfigurationRevision'] as int
        : 0;
    final safeProfile = TripTrackingProfile.values.firstWhere(
      (value) => value.name == map['profile'],
      orElse: () => TripTrackingProfile.roadVehicle,
    );
    final safeStartedAt =
        startedAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final samplingCeiling = _samplingFromMap(map['samplingCeiling']);
    final nativeSampling = _recoveredNativeSampling(
      nativeSampling: _samplingFromMap(map['nativeSampling']),
      samplingCeiling: samplingCeiling,
    );
    return TripTrackingSessionRecord(
      id: safeId,
      vehicleId: safeVehicleId,
      profileId: safeProfileId,
      vehicleConfigurationRevision: vehicleConfigurationRevision,
      revision: revision,
      lastEventSequence: lastEventSequence,
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
        orElse: () => TripTrackingSessionLifecycleState.preparing,
      ),
      healthState: TripTrackingHealthState.values.firstWhere(
        (value) => value.name == map['healthState'],
        orElse: () => TripTrackingHealthState.healthy,
      ),
      backgroundTrackingAllowed: map['backgroundTrackingAllowed'] == true,
      activityRecognitionEnabled: map['activityRecognitionEnabled'] == true,
      nativeSampling: nativeSampling,
      samplingCeiling: samplingCeiling,
      // A missing or malformed ceiling must not let a recovered collector
      // increase its native request beyond an unknown prior user preference.
      adaptiveSamplingEnabled:
          map['adaptiveSamplingEnabled'] == true && samplingCeiling != null,
      lowBatteryProtectionEnabled: map['lowBatteryProtectionEnabled'] != false,
      lowBatteryOverrideEnabled: map['lowBatteryOverrideEnabled'] == true,
      lowBatteryWarningDismissed: map['lowBatteryWarningDismissed'] == true,
      hasValidTimeline:
          startedAt != null &&
          updatedAt != null &&
          !updatedAt.isBefore(startedAt) &&
          hasSafeIdentity &&
          _isSafeStoreIdentifierValue(safeProfileId) &&
          revision >= lastEventSequence &&
          hasValidProfile &&
          hasValidLifecycleState &&
          hasValidHealthState &&
          hasValidVehicleConfigurationRevision &&
          hasSupportedSchemaVersion,
      schemaVersion: sourceSchemaVersion < 3 ? 3 : sourceSchemaVersion,
    );
  }
}

const _maxPersistedAdvisories = 24;

Map<String, Object?>? _samplingToMap(TripSamplingRecommendation? sampling) {
  if (sampling == null ||
      sampling.interval.inSeconds < 1 ||
      sampling.interval.inSeconds > 60 ||
      !sampling.minimumDisplacementMeters.isFinite ||
      sampling.minimumDisplacementMeters < 1 ||
      sampling.minimumDisplacementMeters > 100) {
    return null;
  }
  return {
    'mode': sampling.mode.name,
    'intervalSeconds': sampling.interval.inSeconds,
    'minimumDisplacementMeters': sampling.minimumDisplacementMeters,
  };
}

TripSamplingRecommendation? _samplingFromMap(Object? value) {
  if (value is! Map) return null;
  final modeName = value['mode'];
  final intervalSeconds = value['intervalSeconds'];
  final displacement = value['minimumDisplacementMeters'];
  if (modeName is! String ||
      intervalSeconds is! num ||
      displacement is! num ||
      !intervalSeconds.isFinite ||
      intervalSeconds != intervalSeconds.roundToDouble() ||
      intervalSeconds < 1 ||
      intervalSeconds > 60 ||
      !displacement.isFinite ||
      displacement < 1 ||
      displacement > 100) {
    return null;
  }
  final mode = TripSamplingMode.values.where((item) => item.name == modeName);
  if (mode.length != 1) return null;
  return TripSamplingRecommendation(
    mode: mode.single,
    interval: Duration(seconds: intervalSeconds.toInt()),
    minimumDisplacementMeters: displacement.toDouble(),
  );
}

TripSamplingRecommendation? _recoveredNativeSampling({
  required TripSamplingRecommendation? nativeSampling,
  required TripSamplingRecommendation? samplingCeiling,
}) {
  if (samplingCeiling == null) return nativeSampling;
  if (nativeSampling == null ||
      _isMoreAggressiveThan(nativeSampling, samplingCeiling)) {
    return samplingCeiling;
  }
  return nativeSampling;
}

bool _isMoreAggressiveThan(
  TripSamplingRecommendation candidate,
  TripSamplingRecommendation ceiling,
) =>
    candidate.interval < ceiling.interval ||
    candidate.minimumDisplacementMeters < ceiling.minimumDisplacementMeters ||
    _samplingAggressiveness(candidate.mode) >
        _samplingAggressiveness(ceiling.mode);

int _samplingAggressiveness(TripSamplingMode mode) => switch (mode) {
  TripSamplingMode.precision => 3,
  TripSamplingMode.balanced => 2,
  TripSamplingMode.economy => 1,
};

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
    this.profileId = 'legacy-local-profile',
    this.vehicleConfigurationRevision = 0,
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
    this.schemaVersion = 2,
    this.hasValidTimeline = true,
  });

  final String id;
  final String vehicleId;
  final String profileId;
  final int vehicleConfigurationRevision;
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
      profileId: profileId,
      vehicleConfigurationRevision: vehicleConfigurationRevision,
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
    'profileId': _safeIdentifier(profileId),
    'vehicleConfigurationRevision': vehicleConfigurationRevision,
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
    final sourceSchemaVersion = _sessionSchemaVersion(map['schemaVersion']);
    final safeProfileId = sourceSchemaVersion < 2
        ? 'legacy-local-profile'
        : _safeIdentifier(map['profileId']);
    final hasValidVehicleConfigurationRevision =
        sourceSchemaVersion < 2 ||
        (map['vehicleConfigurationRevision'] is int &&
            (map['vehicleConfigurationRevision'] as int) >= 0);
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
    final hasSupportedSchemaVersion = _hasSupportedReviewSchemaVersion(
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
      profileId: safeProfileId,
      vehicleConfigurationRevision:
          map['vehicleConfigurationRevision'] is int &&
              (map['vehicleConfigurationRevision'] as int) >= 0
          ? map['vehicleConfigurationRevision'] as int
          : 0,
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
      schemaVersion: sourceSchemaVersion < 2 ? 2 : sourceSchemaVersion,
      hasValidTimeline:
          startedAt != null &&
          finishedAt != null &&
          !finishedAt.isBefore(startedAt) &&
          hasSafeIdentity &&
          _isSafeStoreIdentifierValue(safeProfileId) &&
          hasValidVehicleConfigurationRevision &&
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

bool _hasSupportedActiveSessionSchemaVersion(
  Map<dynamic, dynamic> map,
  String key,
) {
  if (!map.containsKey(key)) return true;
  final rawVersion = map[key];
  return rawVersion is int && rawVersion >= 1 && rawVersion <= 3;
}

bool _hasSupportedReviewSchemaVersion(Map<dynamic, dynamic> map, String key) {
  if (!map.containsKey(key)) return true;
  final rawVersion = map[key];
  return rawVersion is int && rawVersion >= 1 && rawVersion <= 2;
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

enum TripTrackingSessionClaimStatus { claimed, existing, corrupt }

class TripTrackingSessionClaimResult {
  const TripTrackingSessionClaimResult(this.status, {this.session});

  final TripTrackingSessionClaimStatus status;
  final TripTrackingSessionRecord? session;
}

class TripTrackingTransitionCommitResult {
  const TripTrackingTransitionCommitResult({
    required this.accepted,
    required this.session,
    required this.event,
  });

  final bool accepted;
  final TripTrackingSessionRecord session;
  final TripTrackingLifecycleEvent event;
}

class TripTrackingSessionRecoveryResult {
  const TripTrackingSessionRecoveryResult({
    required this.session,
    required this.usedFallback,
    this.diagnostic,
  });

  final TripTrackingSessionRecord? session;
  final bool usedFallback;
  final TripTrackingRecoveryDiagnostic? diagnostic;
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
  static const _snapshotAKey = 'activeSnapshot:a';
  static const _snapshotBKey = 'activeSnapshot:b';
  static const _snapshotHeadKey = 'activeSnapshot:head';
  static const _quarantinedPrefix = 'quarantinedSession:';
  static const _reviewPrefix = 'review:';
  static const _pendingPrefix = 'pending:';
  static const _cancelledPrefix = 'cancelled:';
  static const _transitionPrefix = 'transition:';
  static const _recoveryDiagnosticPrefix = 'recoveryDiagnostic:';
  static Future<void> _sharedWriteTail = Future<void>.value();

  final Box<dynamic>? _box;
  TripTrackingSessionRecord? _memorySession;
  Map<String, Object?>? _memorySnapshotA;
  Map<String, Object?>? _memorySnapshotB;
  int _memorySnapshotHead = 0;
  final Map<String, TripTrackingReviewRecord> _memoryReviews = {};
  final Map<String, TripTrackingPendingSample> _memoryPending = {};
  final Map<String, TripTrackingCancelledSessionRecord> _memoryCancelled = {};
  final Map<String, TripTrackingLifecycleEvent> _memoryTransitions = {};
  final Map<String, TripTrackingRecoveryDiagnostic> _memoryRecoveryDiagnostics =
      {};
  final Map<String, TripTrackingQuarantinedSession> _memoryQuarantined = {};
  final TripTrackingSessionStorageCheck? _storageCheck;

  static Future<TripTrackingSessionStore> create({
    TripTrackingSessionStorageCheck? storageCheck,
  }) async {
    final box = await Hive.openBox<dynamic>(boxName);
    return TripTrackingSessionStore._(box, storageCheck: storageCheck);
  }

  TripTrackingSessionRecord? get activeSession {
    final snapshots = _validSnapshots();
    if (snapshots.isNotEmpty) return snapshots.first.session;
    final value = _box == null ? _memorySession : _box.get(_activeSessionKey);
    return _validSessionFromValue(value);
  }

  List<TripTrackingRecoveryDiagnostic> get recoveryDiagnostics {
    final diagnostics = _box == null
        ? _memoryRecoveryDiagnostics.values.toList()
        : _box.keys
              .whereType<String>()
              .where((key) => key.startsWith(_recoveryDiagnosticPrefix))
              .map((key) => _box.get(key))
              .whereType<Map>()
              .map(TripTrackingRecoveryDiagnostic.tryFromMap)
              .whereType<TripTrackingRecoveryDiagnostic>()
              .toList();
    diagnostics.sort((a, b) => a.recordedAtUtc.compareTo(b.recordedAtUtc));
    return diagnostics;
  }

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
    return records;
  }

  Future<TripTrackingSessionRecoveryResult>
  recoverActive() => _enqueue(() async {
    final snapshots = _validSnapshots();
    final rawHead = _box == null
        ? _memorySnapshotHead
        : _box.get(_snapshotHeadKey);
    final expectedGeneration = rawHead is int && rawHead >= 0 ? rawHead : 0;
    final selected = snapshots.isEmpty ? null : snapshots.first;
    final legacy = _validSessionFromValue(
      _box == null ? _memorySession : _box.get(_activeSessionKey),
    );
    final session = selected?.session ?? legacy;
    final restoredGeneration = selected?.generation ?? 0;
    final corruptWithoutFallback = session == null && _hasRawActiveEvidence;
    final usedFallback =
        session != null &&
        ((expectedGeneration > restoredGeneration) ||
            (selected == null && _hasRawActiveEvidence));
    TripTrackingRecoveryDiagnostic? diagnostic;
    if (usedFallback || corruptWithoutFallback) {
      final code = usedFallback
          ? 'corrupt_latest_snapshot_fallback'
          : 'corrupt_active_session_recovery_required';
      final safeSessionId = session?.id ?? 'unreadable';
      final key =
          '$_recoveryDiagnosticPrefix$safeSessionId:$expectedGeneration:$restoredGeneration';
      final existing = _box == null
          ? _memoryRecoveryDiagnostics[key]
          : switch (_box.get(key)) {
              Map value => TripTrackingRecoveryDiagnostic.tryFromMap(value),
              _ => null,
            };
      if (existing != null) {
        diagnostic = existing;
      } else {
        diagnostic = TripTrackingRecoveryDiagnostic(
          code: code,
          recordedAtUtc: DateTime.now().toUtc(),
          expectedGeneration: expectedGeneration,
          restoredGeneration: restoredGeneration,
        );
        if (_box == null) {
          _memoryRecoveryDiagnostics[key] = diagnostic;
        } else {
          await _box.put(key, diagnostic.toMap());
        }
      }
    }
    return TripTrackingSessionRecoveryResult(
      session: session,
      usedFallback: usedFallback,
      diagnostic: diagnostic,
    );
  });

  List<TripTrackingLifecycleEvent> transitionEventsFor(String sessionId) {
    if (!_isSafeStoreIdentifier(sessionId)) return const [];
    final prefix = '$_transitionPrefix$sessionId:';
    final events = _box == null
        ? _memoryTransitions.entries
              .where((entry) => entry.key.startsWith(prefix))
              .map((entry) => entry.value)
              .toList()
        : _box.keys
              .whereType<String>()
              .where((key) => key.startsWith(prefix))
              .map((key) => _box.get(key))
              .whereType<Map>()
              .map(TripTrackingLifecycleEvent.tryFromMap)
              .whereType<TripTrackingLifecycleEvent>()
              .toList();
    events.sort((a, b) => a.sequenceNumber.compareTo(b.sequenceNumber));
    return events;
  }

  List<TripTrackingCancelledSessionRecord> get cancelledSessions {
    final records = _box == null
        ? _memoryCancelled.values.toList()
        : _box.keys
              .whereType<String>()
              .where((key) => key.startsWith(_cancelledPrefix))
              .map((key) => _box.get(key))
              .whereType<Map>()
              .map(TripTrackingCancelledSessionRecord.tryFromMap)
              .whereType<TripTrackingCancelledSessionRecord>()
              .toList();
    records.sort((a, b) => b.cancelledAt.compareTo(a.cancelledAt));
    return records;
  }

  Future<void> saveCancelled(TripTrackingCancelledSessionRecord record) =>
      _enqueue(() async {
        if (!_isSafeStoreIdentifier(record.sessionId) ||
            !_isSafeStoreIdentifier(record.vehicleId) ||
            !_isSafeStoreIdentifier(record.profileId) ||
            record.vehicleConfigurationRevision < 0 ||
            record.cancelledAt.isBefore(record.startedAt) ||
            record.startingOdometer < 0) {
          throw ArgumentError.value(record.sessionId, 'record');
        }
        if (_storageCheck != null) await _ensureStorageForWrite();
        if (_box == null) {
          _memoryCancelled[record.sessionId] = record;
        } else {
          await _box.put(
            '$_cancelledPrefix${record.sessionId}',
            record.toMap(),
          );
        }
      });

  Future<TripTrackingSessionClaimResult> claimActive(
    TripTrackingSessionRecord candidate, {
    String reasonCode = 'manual_start_requested',
    String initiatingSource = 'user',
    String confidenceState = 'unknown',
    String permissionState = 'unknown',
    String trackingQualityMode = 'preparing',
  }) => _enqueue(() async {
    _validateActiveSessionRecord(candidate);
    final existing = activeSession;
    if (existing != null || _hasRawActiveEvidence) {
      return TripTrackingSessionClaimResult(
        existing == null
            ? TripTrackingSessionClaimStatus.corrupt
            : TripTrackingSessionClaimStatus.existing,
        session: existing,
      );
    }
    if (_storageCheck != null) await _ensureStorageForWrite();
    final claimed = candidate.copyWith(revision: 1, lastEventSequence: 1);
    final event = TripTrackingLifecycleEvent(
      sessionId: claimed.id,
      previousState: TripTrackingSessionLifecycleState.idle,
      newState: claimed.lifecycleState,
      eventTimestampUtc: claimed.updatedAt.toUtc(),
      sequenceNumber: 1,
      reasonCode: reasonCode,
      initiatingSource: initiatingSource,
      vehicleId: claimed.vehicleId,
      profileId: claimed.profileId,
      revision: 1,
      confidenceState: confidenceState,
      permissionState: permissionState,
      trackingQualityMode: trackingQualityMode,
      accepted: true,
    );
    final eventKey = _transitionKey(claimed.id, event.sequenceNumber);
    if (_box == null) {
      _writeMemorySnapshot(claimed);
      _memoryTransitions[eventKey] = event;
    } else {
      await _box.putAll({
        ..._activeSnapshotEntries(claimed),
        eventKey: event.toMap(),
      });
    }
    return TripTrackingSessionClaimResult(
      TripTrackingSessionClaimStatus.claimed,
      session: claimed,
    );
  });

  Future<TripTrackingTransitionCommitResult> commitTransition({
    required String sessionId,
    required int expectedRevision,
    required TripTrackingSessionLifecycleState nextState,
    required DateTime eventTimestamp,
    TripTrackingHealthState? healthState,
    String reasonCode = 'lifecycle_condition_changed',
    String initiatingSource = 'coordinator',
    String confidenceState = 'unknown',
    String permissionState = 'unknown',
    String? trackingQualityMode,
  }) => _enqueue(() async {
    final current = activeSession;
    if (current == null || !current.hasValidTimeline) {
      throw StateError('No valid active GPS session can accept a transition.');
    }
    if (current.id != sessionId || current.revision != expectedRevision) {
      throw StateError('The active GPS session revision changed.');
    }
    if (_storageCheck != null) await _ensureStorageForWrite();
    final accepted = TripTrackingSessionStateMachine.canTransition(
      current.lifecycleState,
      nextState,
    );
    final revision = current.revision + 1;
    final sequence = current.lastEventSequence + 1;
    final next = current.copyWith(
      updatedAt: eventTimestamp,
      lifecycleState: accepted ? nextState : current.lifecycleState,
      healthState: accepted ? healthState : current.healthState,
      revision: revision,
      lastEventSequence: sequence,
    );
    final event = TripTrackingLifecycleEvent(
      sessionId: current.id,
      previousState: current.lifecycleState,
      newState: nextState,
      eventTimestampUtc: eventTimestamp.toUtc(),
      sequenceNumber: sequence,
      reasonCode: accepted ? reasonCode : 'illegal_transition_rejected',
      initiatingSource: initiatingSource,
      vehicleId: current.vehicleId,
      profileId: current.profileId,
      revision: revision,
      confidenceState: confidenceState,
      permissionState: permissionState,
      trackingQualityMode: trackingQualityMode ?? next.lifecycleState.name,
      accepted: accepted,
    );
    final eventKey = _transitionKey(current.id, sequence);
    if (_box == null) {
      _writeMemorySnapshot(next);
      _memoryTransitions[eventKey] = event;
    } else {
      await _box.putAll({
        ..._activeSnapshotEntries(next),
        eventKey: event.toMap(),
      });
    }
    return TripTrackingTransitionCommitResult(
      accepted: accepted,
      session: next,
      event: event,
    );
  });

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
    _validateActiveSessionRecord(session);
    if (_storageCheck != null) await _ensureStorageForWrite();
    if (_box == null) {
      _writeMemorySnapshot(session);
    } else {
      await _box.putAll(_activeSnapshotEntries(session));
    }
  });

  Future<TripTrackingSessionRecord> checkpoint(
    TripTrackingSessionRecord session, {
    required int expectedRevision,
  }) => _enqueue(() async {
    _validateActiveSessionRecord(session);
    final current = activeSession;
    if (current == null ||
        current.id != session.id ||
        current.revision != expectedRevision) {
      throw StateError('The active GPS session revision changed.');
    }
    if (_storageCheck != null) await _ensureStorageForWrite();
    final next = session.copyWith(revision: current.revision + 1);
    if (_box == null) {
      _writeMemorySnapshot(next);
    } else {
      await _box.putAll(_activeSnapshotEntries(next));
    }
    return next;
  });

  Future<void> clear() => _enqueue(() async {
    _memorySession = null;
    _memorySnapshotA = null;
    _memorySnapshotB = null;
    _memorySnapshotHead = 0;
    await _box?.deleteAll([
      _activeSessionKey,
      _snapshotAKey,
      _snapshotBKey,
      _snapshotHeadKey,
    ]);
  });

  Future<bool> clearIfSession(String sessionId) => _enqueue(() async {
    if (!_isSafeStoreIdentifier(sessionId)) return false;
    final current = activeSession;
    if (current == null || current.id != sessionId) return false;
    _memorySession = null;
    _memorySnapshotA = null;
    _memorySnapshotB = null;
    _memorySnapshotHead = 0;
    await _box?.deleteAll([
      _activeSessionKey,
      _snapshotAKey,
      _snapshotBKey,
      _snapshotHeadKey,
    ]);
    return true;
  });

  /// Removes an unsafe record from active ownership only after preserving a
  /// complete local copy for explicit recovery or user-directed deletion.
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
    await _ensureStorageForWrite();
    final record = TripTrackingQuarantinedSession(
      sessionId: current.id,
      revision: current.revision,
      sessionPayload: current.toMap(),
      reasonCode: reasonCode,
      quarantinedAtUtc: (quarantinedAtUtc ?? DateTime.now()).toUtc(),
    );
    final key = '$_quarantinedPrefix${current.id}:${current.revision}';
    if (_box == null) {
      _memoryQuarantined[key] = record;
    } else {
      await _box.put(key, record.toMap());
    }
    _memorySession = null;
    _memorySnapshotA = null;
    _memorySnapshotB = null;
    _memorySnapshotHead = 0;
    await _box?.deleteAll([
      _activeSessionKey,
      _snapshotAKey,
      _snapshotBKey,
      _snapshotHeadKey,
    ]);
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
        if (!_isSafeStoreIdentifier(review.profileId)) {
          throw ArgumentError.value(
            review.profileId,
            'review.profileId',
            'Trip reviews require a non-empty safe profile id.',
          );
        }
        if (!review.hasValidTimeline ||
            review.finishedAt.isBefore(review.startedAt) ||
            review.vehicleConfigurationRevision < 0 ||
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

  bool get _hasRawActiveEvidence => _box == null
      ? _memorySession != null ||
            _memorySnapshotA != null ||
            _memorySnapshotB != null
      : _box.get(_activeSessionKey) != null ||
            _box.get(_snapshotAKey) != null ||
            _box.get(_snapshotBKey) != null;

  List<_RecoveredSessionSnapshot> _validSnapshots() {
    final rawSnapshots = _box == null
        ? <Object?>[_memorySnapshotA, _memorySnapshotB]
        : <Object?>[_box.get(_snapshotAKey), _box.get(_snapshotBKey)];
    final recovered = <_RecoveredSessionSnapshot>[];
    for (final raw in rawSnapshots) {
      if (raw is! Map) continue;
      final envelope = TripTrackingSessionSnapshotEnvelope.tryFromMap(raw);
      if (envelope == null) continue;
      final session = _validSessionFromValue(envelope.payload);
      if (session == null || session.id != envelope.sessionId) continue;
      recovered.add(
        _RecoveredSessionSnapshot(
          generation: envelope.generation,
          session: session,
        ),
      );
    }
    recovered.sort((a, b) => b.generation.compareTo(a.generation));
    return recovered;
  }

  int _nextSnapshotGeneration() {
    final validGeneration = _validSnapshots().fold<int>(
      0,
      (highest, snapshot) =>
          snapshot.generation > highest ? snapshot.generation : highest,
    );
    final rawHead = _box == null
        ? _memorySnapshotHead
        : _box.get(_snapshotHeadKey);
    final safeHead = rawHead is int && rawHead >= 0 && rawHead < 0x7fffffff
        ? rawHead
        : 0;
    final current = safeHead > validGeneration ? safeHead : validGeneration;
    return current + 1;
  }

  Map<String, Object?> _activeSnapshotEntries(
    TripTrackingSessionRecord session,
  ) {
    final generation = _nextSnapshotGeneration();
    final envelope = TripTrackingSessionSnapshotEnvelope.create(
      generation: generation,
      sessionId: session.id,
      payload: session.toMap(),
    );
    return {
      _activeSessionKey: session.toMap(),
      generation.isOdd ? _snapshotAKey : _snapshotBKey: envelope.toMap(),
      _snapshotHeadKey: generation,
    };
  }

  void _writeMemorySnapshot(TripTrackingSessionRecord session) {
    final generation = _nextSnapshotGeneration();
    final envelope = TripTrackingSessionSnapshotEnvelope.create(
      generation: generation,
      sessionId: session.id,
      payload: session.toMap(),
    ).toMap();
    _memorySession = session;
    _memorySnapshotHead = generation;
    if (generation.isOdd) {
      _memorySnapshotA = envelope;
    } else {
      _memorySnapshotB = envelope;
    }
  }

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

class _RecoveredSessionSnapshot {
  const _RecoveredSessionSnapshot({
    required this.generation,
    required this.session,
  });

  final int generation;
  final TripTrackingSessionRecord session;
}

TripTrackingSessionRecord? _validSessionFromValue(Object? value) {
  final session = switch (value) {
    TripTrackingSessionRecord record => record,
    Map map => TripTrackingSessionRecord.fromMap(map),
    _ => null,
  };
  return session?.hasValidTimeline == true ? session : null;
}

String _transitionKey(String sessionId, int sequence) =>
    '${TripTrackingSessionStore._transitionPrefix}$sessionId:${sequence.toString().padLeft(20, '0')}';

void _validateActiveSessionRecord(TripTrackingSessionRecord session) {
  if (!_isSafeStoreIdentifier(session.id) ||
      !_isSafeStoreIdentifier(session.vehicleId) ||
      !_isSafeStoreIdentifier(session.profileId)) {
    throw ArgumentError.value(
      session.id,
      'session',
      'Active GPS sessions require safe session, vehicle, and profile ids.',
    );
  }
  if (!session.hasValidTimeline ||
      session.updatedAt.isBefore(session.startedAt) ||
      session.revision < session.lastEventSequence ||
      session.vehicleConfigurationRevision < 0) {
    throw ArgumentError.value(
      session.id,
      'session',
      'Active GPS sessions require a sane timeline and revision.',
    );
  }
  if (session.startingOdometer < 0) {
    throw ArgumentError.value(
      session.startingOdometer,
      'session.startingOdometer',
      'Active GPS sessions require a non-negative starting odometer.',
    );
  }
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
