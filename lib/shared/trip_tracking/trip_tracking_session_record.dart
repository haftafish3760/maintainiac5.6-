// odometerIsGlobalTruth: true.
part of 'trip_tracking_session_store.dart';

/// Last locally observed battery context that influenced GPS collection.
/// It is recovery evidence only and has no mileage authority.
class TripTrackingBatteryStateSummary {
  const TripTrackingBatteryStateSummary({
    required this.observedAt,
    required this.batteryPercent,
    required this.isCharging,
    required this.lowPowerModeEnabled,
    required this.allowsGps,
    required this.reasonCode,
  });

  final DateTime observedAt;
  final int? batteryPercent;
  final bool isCharging;
  final bool lowPowerModeEnabled;
  final bool allowsGps;
  final String reasonCode;

  Map<String, Object?> toMap() => {
    'observedAt': observedAt.toUtc().toIso8601String(),
    'batteryPercent': batteryPercent,
    'isCharging': isCharging,
    'lowPowerModeEnabled': lowPowerModeEnabled,
    'allowsGps': allowsGps,
    'reasonCode': reasonCode,
    'authoritativeForMileage': false,
  };

  static TripTrackingBatteryStateSummary? tryFromMap(Object? value) {
    if (value is! Map) return null;
    final observedAt = DateTime.tryParse('${value['observedAt'] ?? ''}');
    final percent = value['batteryPercent'];
    final reason = value['reasonCode'];
    if (observedAt == null ||
        (percent != null &&
            (percent is! int || percent < 0 || percent > 100)) ||
        value['isCharging'] is! bool ||
        value['lowPowerModeEnabled'] is! bool ||
        value['allowsGps'] is! bool ||
        reason is! String ||
        !_isSafeEvidenceCode(reason, maxLength: 80)) {
      return null;
    }
    return TripTrackingBatteryStateSummary(
      observedAt: observedAt.toUtc(),
      batteryPercent: percent as int?,
      isCharging: value['isCharging'] as bool,
      lowPowerModeEnabled: value['lowPowerModeEnabled'] as bool,
      allowsGps: value['allowsGps'] as bool,
      reasonCode: reason,
    );
  }
}

/// Bounded, coordinate-free permission evidence for deterministic recovery.
class TripTrackingPermissionEvidence {
  const TripTrackingPermissionEvidence({
    required this.observedAt,
    required this.state,
    required this.preciseLocation,
    required this.canTrackInBackground,
    required this.source,
  });

  final DateTime observedAt;
  final String state;
  final bool preciseLocation;
  final bool canTrackInBackground;
  final String source;

  Map<String, Object?> toMap() => {
    'observedAt': observedAt.toUtc().toIso8601String(),
    'state': state,
    'preciseLocation': preciseLocation,
    'canTrackInBackground': canTrackInBackground,
    'source': source,
    'authoritativeForMileage': false,
  };

  static TripTrackingPermissionEvidence? tryFromMap(Object? value) {
    if (value is! Map) return null;
    final observedAt = DateTime.tryParse('${value['observedAt'] ?? ''}');
    final state = value['state'];
    final source = value['source'];
    if (observedAt == null ||
        state is! String ||
        !_isSafeEvidenceCode(state, maxLength: 32) ||
        source is! String ||
        !_isSafeEvidenceCode(source, maxLength: 48) ||
        value['preciseLocation'] is! bool ||
        value['canTrackInBackground'] is! bool) {
      return null;
    }
    return TripTrackingPermissionEvidence(
      observedAt: observedAt.toUtc(),
      state: state,
      preciseLocation: value['preciseLocation'] as bool,
      canTrackInBackground: value['canTrackInBackground'] as bool,
      source: source,
    );
  }
}

bool _isSafeEvidenceCode(String value, {required int maxLength}) =>
    value.isNotEmpty &&
    value.length <= maxLength &&
    RegExp(r'^[A-Za-z][A-Za-z0-9_]*$').hasMatch(value);

/// Versioned, locally durable active GPS-session state.
class TripTrackingSessionRecord {
  const TripTrackingSessionRecord({
    required this.id,
    required this.vehicleId,
    this.vehicleConfigurationRevision = 0,
    this.gpsAssistanceCalibrationMultiplier = 1,
    required this.startingOdometer,
    this.startingOdometerTenths,
    this.projectionAnchorOdometer,
    this.projectionAnchorOdometerTenths,
    this.projectionAnchorAcceptedMeters = 0,
    this.deviceLocationIntervalFloorSeconds = 1,
    required this.profile,
    this.profileId = '',
    required this.startedAt,
    required this.updatedAt,
    this.startedTimeZoneOffsetMinutes = 0,
    this.startedTimeZoneName = 'UTC',
    required this.engineSnapshot,
    this.advisories = const [],
    this.tripEvents = const [],
    this.lifecycleState = TripTrackingSessionLifecycleState.ready,
    this.healthState = TripTrackingHealthState.healthy,
    this.pauseKind,
    this.backgroundTrackingAllowed = false,
    this.activityRecognitionEnabled = false,
    this.nativeSampling,
    this.samplingCeiling,
    this.adaptiveSamplingEnabled = false,
    this.lowBatteryProtectionEnabled = true,
    this.lowBatteryOverrideEnabled = false,
    this.lowBatteryWarningDismissed = false,
    this.batteryStateSummary,
    this.permissionHistory = const [],
    this.hasValidTimeline = true,
    this.schemaVersion = 1,
    this.revision = 1,
    this.recoveryCount = 0,
    this.transitionAudits = const [],
    this.ancestry,
    this.persistedContractState,
  });

  final String id;
  final String vehicleId;
  final int vehicleConfigurationRevision;
  final double gpsAssistanceCalibrationMultiplier;
  final int startingOdometer;
  final int? startingOdometerTenths;
  final int? projectionAnchorOdometer;
  final int? projectionAnchorOdometerTenths;
  final double projectionAnchorAcceptedMeters;
  final int deviceLocationIntervalFloorSeconds;
  int get effectiveProjectionAnchorOdometer =>
      projectionAnchorOdometer ?? startingOdometer;
  int get effectiveStartingOdometerTenths =>
      startingOdometerTenths ?? startingOdometer * 10;
  int get effectiveProjectionAnchorOdometerTenths =>
      projectionAnchorOdometerTenths ?? effectiveProjectionAnchorOdometer * 10;
  final TripTrackingProfile profile;
  final String profileId;
  String get effectiveProfileId => _safeIdentifier(profileId).isEmpty
      ? profile.name
      : _safeIdentifier(profileId);
  final DateTime startedAt;
  final DateTime updatedAt;
  final int startedTimeZoneOffsetMinutes;
  final String startedTimeZoneName;
  final TripTrackingEngineSnapshot engineSnapshot;
  final List<TripTrackingAdvisoryEvent> advisories;
  final List<TripManualEvent> tripEvents;
  final TripTrackingSessionLifecycleState lifecycleState;
  final TripTrackingHealthState healthState;
  final TripTrackingPauseKind? pauseKind;
  final TripTrackingSessionLifecycleContractState? persistedContractState;
  TripTrackingSessionLifecycleContractState get effectiveContractState =>
      persistedContractState?.toRuntimeState() == lifecycleState
      ? persistedContractState!
      : lifecycleState == TripTrackingSessionLifecycleState.paused
      ? pauseKind == TripTrackingPauseKind.system
            ? TripTrackingSessionLifecycleContractState.PAUSED_BY_SYSTEM
            : TripTrackingSessionLifecycleContractState.PAUSED_BY_USER
      : lifecycleState.toContractState();

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
  final TripTrackingBatteryStateSummary? batteryStateSummary;
  final List<TripTrackingPermissionEvidence> permissionHistory;
  final bool hasValidTimeline;
  final int schemaVersion;
  final int revision;
  final int recoveryCount;
  final List<TripTrackingSessionTransitionAudit> transitionAudits;
  final TripTrackingSessionAncestry? ancestry;

  TripTrackingSessionRecord copyWith({
    DateTime? updatedAt,
    TripTrackingEngineSnapshot? engineSnapshot,
    List<TripTrackingAdvisoryEvent>? advisories,
    List<TripManualEvent>? tripEvents,
    TripTrackingSessionLifecycleState? lifecycleState,
    TripTrackingHealthState? healthState,
    TripTrackingPauseKind? pauseKind,
    bool clearPauseKind = false,
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
    TripTrackingBatteryStateSummary? batteryStateSummary,
    List<TripTrackingPermissionEvidence>? permissionHistory,
    bool? hasValidTimeline,
    int? schemaVersion,
    int? revision,
    int? recoveryCount,
    List<TripTrackingSessionTransitionAudit>? transitionAudits,
    TripTrackingSessionLifecycleContractState? persistedContractState,
    int? projectionAnchorOdometer,
    int? projectionAnchorOdometerTenths,
    double? projectionAnchorAcceptedMeters,
    int? deviceLocationIntervalFloorSeconds,
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
      vehicleConfigurationRevision: vehicleConfigurationRevision,
      gpsAssistanceCalibrationMultiplier: gpsAssistanceCalibrationMultiplier,
      startingOdometer: startingOdometer,
      startingOdometerTenths: startingOdometerTenths,
      projectionAnchorOdometer:
          projectionAnchorOdometer ?? this.projectionAnchorOdometer,
      projectionAnchorOdometerTenths:
          projectionAnchorOdometerTenths ?? this.projectionAnchorOdometerTenths,
      projectionAnchorAcceptedMeters:
          projectionAnchorAcceptedMeters ?? this.projectionAnchorAcceptedMeters,
      deviceLocationIntervalFloorSeconds:
          deviceLocationIntervalFloorSeconds ??
          this.deviceLocationIntervalFloorSeconds,
      profile: profile,
      profileId: effectiveProfileId,
      startedAt: startedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      startedTimeZoneOffsetMinutes: startedTimeZoneOffsetMinutes,
      startedTimeZoneName: startedTimeZoneName,
      engineSnapshot: engineSnapshot ?? this.engineSnapshot,
      advisories: advisories ?? this.advisories,
      tripEvents: tripEvents ?? this.tripEvents,
      lifecycleState: lifecycleState ?? this.lifecycleState,
      healthState: healthState ?? this.healthState,
      pauseKind: clearPauseKind ? null : pauseKind ?? this.pauseKind,
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
      batteryStateSummary: batteryStateSummary ?? this.batteryStateSummary,
      permissionHistory: permissionHistory ?? this.permissionHistory,
      hasValidTimeline: hasValidTimeline ?? this.hasValidTimeline,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      revision: revision ?? this.revision,
      recoveryCount: recoveryCount ?? this.recoveryCount,
      transitionAudits: transitionAudits ?? this.transitionAudits,
      ancestry: ancestry,
      persistedContractState:
          persistedContractState ??
          (lifecycleState == null ? this.persistedContractState : null),
    );
  }

  Map<String, Object?> toMap() => {
    'id': _safeIdentifier(id),
    'vehicleId': _safeIdentifier(vehicleId),
    'vehicleConfigurationRevision': vehicleConfigurationRevision < 0
        ? 0
        : vehicleConfigurationRevision,
    'gpsAssistanceCalibrationMultiplier':
        _safeGpsAssistanceCalibrationMultiplier(
          gpsAssistanceCalibrationMultiplier,
        ),
    'startingOdometer': _persistedOdometerValue(startingOdometer),
    if (_optionalPersistedOdometerTenths(startingOdometerTenths) != null)
      'startingOdometerTenths': _optionalPersistedOdometerTenths(
        startingOdometerTenths,
      ),
    if (projectionAnchorOdometer != null)
      'projectionAnchorOdometer': _persistedOdometerValue(
        projectionAnchorOdometer!,
      ),
    if (_optionalPersistedOdometerTenths(projectionAnchorOdometerTenths) !=
        null)
      'projectionAnchorOdometerTenths': _optionalPersistedOdometerTenths(
        projectionAnchorOdometerTenths,
      ),
    if (projectionAnchorOdometer != null)
      'projectionAnchorAcceptedMeters': projectionAnchorAcceptedMeters,
    'deviceLocationIntervalFloorSeconds': deviceLocationIntervalFloorSeconds
        .clamp(1, 60),
    'profile': profile.name,
    'profileId': effectiveProfileId,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'startedTimeZoneOffsetMinutes': startedTimeZoneOffsetMinutes,
    'startedTimeZoneName': _safeTimeZoneName(startedTimeZoneName),
    'engineSnapshot': engineSnapshot.toMap(),
    'advisories': advisories.map((item) => item.toMap()).toList(),
    'tripEvents': _boundedTripEvents(
      tripEvents,
    ).map((item) => item.toMap()).toList(growable: false),
    'lifecycleState': lifecycleState.name,
    'healthState': healthState.name,
    if (pauseKind != null) 'pauseKind': pauseKind!.name,
    'backgroundTrackingAllowed': backgroundTrackingAllowed,
    'activityRecognitionEnabled': activityRecognitionEnabled,
    'nativeSampling': _samplingToMap(nativeSampling),
    'samplingCeiling': _samplingToMap(samplingCeiling),
    'adaptiveSamplingEnabled': adaptiveSamplingEnabled,
    'lowBatteryProtectionEnabled': lowBatteryProtectionEnabled,
    'lowBatteryOverrideEnabled': lowBatteryOverrideEnabled,
    'lowBatteryWarningDismissed': lowBatteryWarningDismissed,
    'batteryStateSummary': batteryStateSummary?.toMap(),
    'permissionHistory': permissionHistory.map((item) => item.toMap()).toList(),
    'schemaVersion': schemaVersion,
    'revision': revision,
    'recoveryCount': recoveryCount < 0 ? 0 : recoveryCount,
    'transitionAudits': transitionAudits.map((item) => item.toMap()).toList(),
    if (ancestry != null) 'ancestry': ancestry!.toMap(),
    'contractState': effectiveContractState.name,
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
    final hasValidVehicleConfigurationRevision =
        !map.containsKey('vehicleConfigurationRevision') ||
        (map['vehicleConfigurationRevision'] is int &&
            (map['vehicleConfigurationRevision'] as int) >= 0);
    final hasValidCalibrationMultiplier =
        !map.containsKey('gpsAssistanceCalibrationMultiplier') ||
        _isValidGpsAssistanceCalibrationMultiplier(
          map['gpsAssistanceCalibrationMultiplier'],
        );
    final hasProjectionAnchor =
        map.containsKey('projectionAnchorOdometer') ||
        map.containsKey('projectionAnchorAcceptedMeters');
    final hasValidProjectionAnchor =
        !hasProjectionAnchor ||
        (map['projectionAnchorOdometer'] is int &&
            (map['projectionAnchorOdometer'] as int) >= 0 &&
            map['projectionAnchorAcceptedMeters'] is num &&
            (map['projectionAnchorAcceptedMeters'] as num).isFinite &&
            (map['projectionAnchorAcceptedMeters'] as num) >= 0);
    final hasValidOdometerTenths =
        _hasConsistentOdometerTenths(
          map,
          wholeKey: 'startingOdometer',
          tenthsKey: 'startingOdometerTenths',
        ) &&
        _hasConsistentOdometerTenths(
          map,
          wholeKey: 'projectionAnchorOdometer',
          tenthsKey: 'projectionAnchorOdometerTenths',
          optionalWhole: true,
        );
    final hasValidDeviceIntervalFloor =
        !map.containsKey('deviceLocationIntervalFloorSeconds') ||
        (map['deviceLocationIntervalFloorSeconds'] is int &&
            (map['deviceLocationIntervalFloorSeconds'] as int) >= 1 &&
            (map['deviceLocationIntervalFloorSeconds'] as int) <= 60);
    final hasValidStartedTimeZone =
        !map.containsKey('startedTimeZoneOffsetMinutes') ||
        (_isValidTimeZoneOffset(map['startedTimeZoneOffsetMinutes']) &&
            _isSafeTimeZoneName(map['startedTimeZoneName']));
    final safeId = _safeIdentifier(map['id']);
    final safeVehicleId = _safeIdentifier(map['vehicleId']);
    final safeProfile = TripTrackingProfile.values.firstWhere(
      (value) => value.name == map['profile'],
      orElse: () => TripTrackingProfile.roadVehicle,
    );
    final safeLifecycleState = TripTrackingSessionLifecycleState.values
        .firstWhere(
          (value) => value.name == map['lifecycleState'],
          orElse: () => TripTrackingSessionLifecycleState.ready,
        );
    final rawContractState = map['contractState'];
    final persistedContractState = rawContractState is String
        ? TripTrackingSessionLifecycleContractState.values
              .where((value) => value.name == rawContractState)
              .firstOrNull
        : null;
    final hasValidContractState =
        !map.containsKey('contractState') ||
        (persistedContractState != null &&
            (persistedContractState.toRuntimeState() == safeLifecycleState ||
                (safeLifecycleState ==
                        TripTrackingSessionLifecycleState.stopping &&
                    persistedContractState ==
                        TripTrackingSessionLifecycleContractState
                            .COMPLETION_PENDING)));
    final safeStartedAt =
        startedAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final samplingCeiling = _samplingFromMap(map['samplingCeiling']);
    final nativeSampling = _recoveredNativeSampling(
      nativeSampling: _samplingFromMap(map['nativeSampling']),
      samplingCeiling: samplingCeiling,
    );
    final rawAncestry = map['ancestry'];
    final ancestry = rawAncestry is Map
        ? TripTrackingSessionAncestry.tryFromMap(rawAncestry, sessionId: safeId)
        : null;
    final hasValidAncestry =
        !map.containsKey('ancestry') ||
        (rawAncestry is Map && ancestry != null);
    return TripTrackingSessionRecord(
      id: safeId,
      vehicleId: safeVehicleId,
      vehicleConfigurationRevision: _safeRecoveryCount(
        map['vehicleConfigurationRevision'],
      ),
      gpsAssistanceCalibrationMultiplier:
          _safeGpsAssistanceCalibrationMultiplier(
            map['gpsAssistanceCalibrationMultiplier'],
          ),
      startingOdometer: _persistedOdometerValue(map['startingOdometer']),
      startingOdometerTenths: _optionalPersistedOdometerTenths(
        map['startingOdometerTenths'],
      ),
      projectionAnchorOdometer: map['projectionAnchorOdometer'] is int
          ? _persistedOdometerValue(map['projectionAnchorOdometer'])
          : null,
      projectionAnchorOdometerTenths: _optionalPersistedOdometerTenths(
        map['projectionAnchorOdometerTenths'],
      ),
      projectionAnchorAcceptedMeters:
          map['projectionAnchorAcceptedMeters'] is num
          ? (map['projectionAnchorAcceptedMeters'] as num).toDouble()
          : 0,
      deviceLocationIntervalFloorSeconds:
          map['deviceLocationIntervalFloorSeconds'] is int
          ? (map['deviceLocationIntervalFloorSeconds'] as int).clamp(1, 60)
          : 1,
      profile: safeProfile,
      profileId: _safeIdentifier(map['profileId']).isEmpty
          ? safeProfile.name
          : _safeIdentifier(map['profileId']),
      startedAt: safeStartedAt,
      updatedAt:
          updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      startedTimeZoneOffsetMinutes:
          map.containsKey('startedTimeZoneOffsetMinutes')
          ? _safeTimeZoneOffset(map['startedTimeZoneOffsetMinutes'])
          : 0,
      startedTimeZoneName: map.containsKey('startedTimeZoneName')
          ? _safeTimeZoneName(map['startedTimeZoneName'])
          : 'unknown',
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
      tripEvents: _tripEventsFromMapValue(
        map['tripEvents'],
        sessionId: safeId,
        vehicleId: safeVehicleId,
        profileId: _safeIdentifier(map['profileId']).isEmpty
            ? safeProfile.name
            : _safeIdentifier(map['profileId']),
        startedAt: safeStartedAt,
      ),
      lifecycleState: safeLifecycleState,
      healthState: TripTrackingHealthState.values.firstWhere(
        (value) => value.name == map['healthState'],
        orElse: () => TripTrackingHealthState.healthy,
      ),
      pauseKind: TripTrackingPauseKind.values
          .where((value) => value.name == map['pauseKind'])
          .firstOrNull,
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
      batteryStateSummary: _batteryStateSummaryFromMap(
        map['batteryStateSummary'],
        latestAt: updatedAt ?? safeStartedAt,
      ),
      permissionHistory: _permissionHistoryFromMap(
        map['permissionHistory'],
        latestAt: updatedAt ?? safeStartedAt,
      ),
      hasValidTimeline:
          startedAt != null &&
          updatedAt != null &&
          !updatedAt.isBefore(startedAt) &&
          hasSafeIdentity &&
          hasValidProfile &&
          hasValidLifecycleState &&
          hasValidContractState &&
          hasValidHealthState &&
          hasValidVehicleConfigurationRevision &&
          hasValidCalibrationMultiplier &&
          hasValidProjectionAnchor &&
          hasValidOdometerTenths &&
          hasValidDeviceIntervalFloor &&
          hasValidStartedTimeZone &&
          hasValidAncestry &&
          hasSupportedSchemaVersion,
      revision: _safeTransitionRevision(map['revision']),
      recoveryCount: _safeRecoveryCount(map['recoveryCount']),
      schemaVersion: _sessionSchemaVersion(map['schemaVersion']),
      transitionAudits: _transitionAuditsFromMapValue(
        map['transitionAudits'],
        sessionId: safeId,
        vehicleId: safeVehicleId,
        profile: safeProfile,
        startedAt: safeStartedAt,
        latestAt: updatedAt ?? safeStartedAt,
      ),
      ancestry: ancestry,
      persistedContractState: persistedContractState,
    );
  }
}

TripTrackingBatteryStateSummary? _batteryStateSummaryFromMap(
  Object? value, {
  required DateTime latestAt,
}) {
  final summary = TripTrackingBatteryStateSummary.tryFromMap(value);
  if (summary == null || summary.observedAt.isAfter(latestAt)) {
    return null;
  }
  return summary;
}

List<TripTrackingPermissionEvidence> _permissionHistoryFromMap(
  Object? value, {
  required DateTime latestAt,
}) {
  if (value is! List) return const [];
  return value
      .map(TripTrackingPermissionEvidence.tryFromMap)
      .whereType<TripTrackingPermissionEvidence>()
      .where((item) => !item.observedAt.isAfter(latestAt))
      .toList(growable: false);
}

int _safeRecoveryCount(Object? value) {
  if (value is! int || value < 0) return 0;
  return value > 1000000 ? 1000000 : value;
}

const _maxPersistedTripEvents = TripManualEvent.maximumPerTrip;

Iterable<TripManualEvent> _boundedTripEvents(Iterable<TripManualEvent> events) {
  final items = events.toList(growable: false);
  return items.takeLast(_maxPersistedTripEvents);
}

List<TripManualEvent> _tripEventsFromMapValue(
  Object? value, {
  required String sessionId,
  required String vehicleId,
  required String profileId,
  required DateTime startedAt,
  DateTime? finishedAt,
}) {
  if (value is! Iterable) return const [];
  return value
      .whereType<Map>()
      .map(TripManualEvent.tryFromMap)
      .whereType<TripManualEvent>()
      .where(
        (event) => event.belongsTo(
          expectedSessionId: sessionId,
          expectedVehicleId: vehicleId,
          expectedProfileId: profileId,
          tripStartedAt: startedAt,
          tripFinishedAt: finishedAt,
        ),
      )
      .toList(growable: false)
      .takeLast(_maxPersistedTripEvents)
      .toList(growable: false);
}

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

List<TripTrackingSessionTransitionAudit> _transitionAuditsFromMapValue(
  Object? value, {
  required String sessionId,
  required String vehicleId,
  required TripTrackingProfile profile,
  required DateTime startedAt,
  required DateTime latestAt,
}) {
  if (value is! Iterable) return const [];
  final ordered = value
      .whereType<Map>()
      .map(TripTrackingSessionTransitionAudit.fromMap)
      .where(
        (event) =>
            event.schemaVersion == 1 &&
            _transitionAuditBelongsToSession(
              event,
              sessionId: sessionId,
              vehicleId: vehicleId,
              profile: profile,
              startedAt: startedAt,
              latestAt: latestAt,
            ),
      )
      .toList(growable: false)
      ._sortByMonotonicEvent();
  final seenIds = <String>{};
  final seenSequences = <int>{};
  final unique = ordered.where(
    (event) => seenIds.add(event.id) && seenSequences.add(event.sequenceNumber),
  );
  return unique.toList(growable: false);
}

extension _TripTrackingTransitionAuditSort
    on List<TripTrackingSessionTransitionAudit> {
  List<TripTrackingSessionTransitionAudit> _sortByMonotonicEvent() {
    sort((a, b) {
      final sequenceDiff = a.sequenceNumber.compareTo(b.sequenceNumber);
      if (sequenceDiff != 0) return sequenceDiff;
      final revisionDiff = a.revision.compareTo(b.revision);
      if (revisionDiff != 0) return revisionDiff;
      final eventDiff = a.eventTimestamp.compareTo(b.eventTimestamp);
      if (eventDiff != 0) return eventDiff;
      return a.id.compareTo(b.id);
    });
    return this;
  }
}

bool _transitionAuditBelongsToSession(
  TripTrackingSessionTransitionAudit event, {
  required String sessionId,
  required String vehicleId,
  required TripTrackingProfile profile,
  required DateTime startedAt,
  required DateTime latestAt,
}) {
  if (event.sessionId != sessionId || event.vehicleId != vehicleId) {
    return false;
  }
  if (event.profile != profile) {
    return false;
  }
  final tripStart = startedAt.toUtc();
  final eventAt = event.eventTimestamp.toUtc();
  if (eventAt.isBefore(tripStart)) {
    return false;
  }
  return !eventAt.isAfter(latestAt.toUtc());
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

int _safeTransitionRevision(Object? value) {
  if (value is! num || !value.isFinite) return 1;
  final parsed = value.toInt();
  return parsed < 1 ? 1 : parsed;
}
