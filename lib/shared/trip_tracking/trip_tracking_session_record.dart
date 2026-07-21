part of 'trip_tracking_session_store.dart';

/// Versioned, locally durable active GPS-session state.
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
    this.nativeSampling,
    this.samplingCeiling,
    this.adaptiveSamplingEnabled = false,
    this.lowBatteryProtectionEnabled = true,
    this.lowBatteryOverrideEnabled = false,
    this.lowBatteryWarningDismissed = false,
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
    final samplingCeiling = _samplingFromMap(map['samplingCeiling']);
    final nativeSampling = _recoveredNativeSampling(
      nativeSampling: _samplingFromMap(map['nativeSampling']),
      samplingCeiling: samplingCeiling,
    );
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
          hasValidProfile &&
          hasValidLifecycleState &&
          hasValidHealthState &&
          hasSupportedSchemaVersion,
      schemaVersion: _sessionSchemaVersion(map['schemaVersion']),
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
