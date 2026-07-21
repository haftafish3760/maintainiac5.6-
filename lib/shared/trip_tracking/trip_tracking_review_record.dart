// odometerIsGlobalTruth: true.
part of 'trip_tracking_session_store.dart';

/// Locally durable GPS review state awaiting explicit user confirmation.
enum TripTrackingCloudSyncState { localOnly, pending, queued, synced, failed }

enum TripTrackingCloudBackupScope { personal, organization }

enum TripManualMileageAdjustmentReason {
  missedTrip,
  personalMiles,
  businessMiles,
  odometerCorrection,
  gpsGap,
  other,
}

enum TripManualEventType {
  pickup,
  dropoff,
  workStop,
  fuelStop,
  loading,
  unloading,
  customerWait,
  personalInterruption,
  note,
}

class TripManualEvent {
  const TripManualEvent({
    required this.id,
    required this.type,
    required this.occurredAt,
    required this.userConfirmed,
    this.note,
  });

  final String id;
  final TripManualEventType type;
  final DateTime occurredAt;
  final bool userConfirmed;
  final String? note;

  bool get canFinalizeTrip => false;
  bool get canChangeMileage => false;

  bool get isValid => _safeIdentifier(id).isNotEmpty && userConfirmed;

  Map<String, Object?> toMap() => {
    'id': _safeIdentifier(id),
    'type': type.name,
    'occurredAt': occurredAt.toUtc().toIso8601String(),
    'userConfirmed': userConfirmed,
    if (_optionalSafeCloudSyncError(note, maxLength: 240) != null)
      'note': _optionalSafeCloudSyncError(note, maxLength: 240),
    'canFinalizeTrip': false,
    'canChangeMileage': false,
  };

  static TripManualEvent? tryFromMap(Map<dynamic, dynamic> map) {
    final types = TripManualEventType.values.where(
      (value) => value.name == map['type'],
    );
    final occurredAt = DateTime.tryParse('${map['occurredAt'] ?? ''}')?.toUtc();
    if (types.isEmpty || occurredAt == null) return null;
    final result = TripManualEvent(
      id: _safeIdentifier(map['id']),
      type: types.first,
      occurredAt: occurredAt,
      userConfirmed: map['userConfirmed'] == true,
      note: _optionalSafeCloudSyncError(map['note'], maxLength: 240),
    );
    return result.isValid ? result : null;
  }
}

class TripManualMileageAdjustment {
  const TripManualMileageAdjustment({
    required this.id,
    required this.deltaMiles,
    required this.reason,
    required this.createdAt,
    required this.userConfirmed,
    this.note,
  });

  final String id;
  final double deltaMiles;
  final TripManualMileageAdjustmentReason reason;
  final DateTime createdAt;
  final bool userConfirmed;
  final String? note;

  bool get canRewriteConfirmedOdometer => false;

  bool get isValid =>
      _safeIdentifier(id).isNotEmpty &&
      deltaMiles.isFinite &&
      deltaMiles.abs() <= 100000 &&
      userConfirmed;

  Map<String, Object?> toMap() => {
    'id': _safeIdentifier(id),
    'deltaMiles': deltaMiles,
    'reason': reason.name,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'userConfirmed': userConfirmed,
    if (_optionalSafeCloudSyncError(note, maxLength: 240) != null)
      'note': _optionalSafeCloudSyncError(note, maxLength: 240),
    'canRewriteConfirmedOdometer': false,
  };

  static TripManualMileageAdjustment? tryFromMap(Map<dynamic, dynamic> map) {
    final reasons = TripManualMileageAdjustmentReason.values.where(
      (value) => value.name == map['reason'],
    );
    final createdAt = DateTime.tryParse('${map['createdAt'] ?? ''}')?.toUtc();
    final delta = map['deltaMiles'];
    final result = TripManualMileageAdjustment(
      id: _safeIdentifier(map['id']),
      deltaMiles: delta is num ? delta.toDouble() : double.nan,
      reason: reasons.isEmpty
          ? TripManualMileageAdjustmentReason.other
          : reasons.first,
      createdAt:
          createdAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      userConfirmed: map['userConfirmed'] == true,
      note: _optionalSafeCloudSyncError(map['note'], maxLength: 240),
    );
    return reasons.isNotEmpty && createdAt != null && result.isValid
        ? result
        : null;
  }
}

enum TripTrackingTripLogProposalState { pending, submitted }

enum TripOdometerUsageDayClassification { regular, exceptional, outOfTown }

class TripTrackingReviewRecord {
  const TripTrackingReviewRecord({
    required this.id,
    required this.vehicleId,
    required this.startingOdometer,
    required this.estimatedEndingOdometer,
    required this.profile,
    this.profileId = '',
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
    this.endingOdometerDraft,
    this.manualAdjustments = const [],
    this.advisories = const [],
    this.tripEvents = const [],
    this.transitionAudits = const [],
    this.batteryStateSummary,
    this.permissionHistory = const [],
    this.recoveryCount = 0,
    this.tripLogProposalState = TripTrackingTripLogProposalState.pending,
    this.tripLogProposalAttemptCount = 0,
    this.tripLogProposalLastAttemptAt,
    this.usageDayClassification = TripOdometerUsageDayClassification.regular,
    this.schemaVersion = 1,
    this.hasValidTimeline = true,
  });

  final String id;
  final String vehicleId;
  final int startingOdometer;
  final int estimatedEndingOdometer;
  final TripTrackingProfile profile;
  final String profileId;
  String get effectiveProfileId => _safeIdentifier(profileId).isEmpty
      ? profile.name
      : _safeIdentifier(profileId);
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
  final int? endingOdometerDraft;
  final List<TripManualMileageAdjustment> manualAdjustments;
  final List<TripTrackingAdvisoryEvent> advisories;
  final List<TripManualEvent> tripEvents;
  final List<TripTrackingSessionTransitionAudit> transitionAudits;
  final TripTrackingBatteryStateSummary? batteryStateSummary;
  final List<TripTrackingPermissionEvidence> permissionHistory;
  final int recoveryCount;
  final TripTrackingTripLogProposalState tripLogProposalState;
  final int tripLogProposalAttemptCount;
  final DateTime? tripLogProposalLastAttemptAt;
  final TripOdometerUsageDayClassification usageDayClassification;
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
    int? endingOdometerDraft,
    bool clearEndingOdometerDraft = false,
    List<TripManualMileageAdjustment>? manualAdjustments,
    List<TripTrackingAdvisoryEvent>? advisories,
    List<TripManualEvent>? tripEvents,
    List<TripTrackingSessionTransitionAudit>? transitionAudits,
    TripTrackingBatteryStateSummary? batteryStateSummary,
    List<TripTrackingPermissionEvidence>? permissionHistory,
    int? recoveryCount,
    TripTrackingTripLogProposalState? tripLogProposalState,
    int? tripLogProposalAttemptCount,
    DateTime? tripLogProposalLastAttemptAt,
    TripOdometerUsageDayClassification? usageDayClassification,
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
      profileId: effectiveProfileId,
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
      endingOdometerDraft: clearEndingOdometerDraft
          ? null
          : endingOdometerDraft ?? this.endingOdometerDraft,
      manualAdjustments: List.unmodifiable(
        manualAdjustments ?? this.manualAdjustments,
      ),
      advisories: List.unmodifiable(advisories ?? this.advisories),
      tripEvents: List.unmodifiable(tripEvents ?? this.tripEvents),
      transitionAudits: List.unmodifiable(
        transitionAudits ?? this.transitionAudits,
      ),
      batteryStateSummary: batteryStateSummary ?? this.batteryStateSummary,
      permissionHistory: List.unmodifiable(
        permissionHistory ?? this.permissionHistory,
      ),
      recoveryCount: recoveryCount ?? this.recoveryCount,
      tripLogProposalState: tripLogProposalState ?? this.tripLogProposalState,
      tripLogProposalAttemptCount:
          tripLogProposalAttemptCount ?? this.tripLogProposalAttemptCount,
      tripLogProposalLastAttemptAt:
          tripLogProposalLastAttemptAt ?? this.tripLogProposalLastAttemptAt,
      usageDayClassification:
          usageDayClassification ?? this.usageDayClassification,
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
    'profileId': effectiveProfileId,
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
    if (_optionalPersistedOdometerValue(endingOdometerDraft) != null)
      'endingOdometerDraft': _optionalPersistedOdometerValue(
        endingOdometerDraft,
      ),
    'manualAdjustments': manualAdjustments
        .where((item) => item.isValid)
        .map((item) => item.toMap())
        .toList(growable: false),
    'advisories': advisories
        .map((item) => item.toMap())
        .toList(growable: false),
    'tripEvents': tripEvents
        .where((item) => item.isValid)
        .map((item) => item.toMap())
        .toList(growable: false),
    'transitionAudits': _boundedTransitionAudits(
      transitionAudits,
    ).map((item) => item.toMap()).toList(growable: false),
    'batteryStateSummary': batteryStateSummary?.toMap(),
    'permissionHistory': permissionHistory
        .takeLast(24)
        .map((item) => item.toMap())
        .toList(growable: false),
    'recoveryCount': recoveryCount < 0 ? 0 : recoveryCount,
    'tripLogProposalState': tripLogProposalState.name,
    'tripLogProposalAttemptCount': tripLogProposalAttemptCount < 0
        ? 0
        : tripLogProposalAttemptCount,
    if (tripLogProposalLastAttemptAt != null)
      'tripLogProposalLastAttemptAt': tripLogProposalLastAttemptAt!
          .toUtc()
          .toIso8601String(),
    'usageDayClassification': usageDayClassification.name,
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
    final safeProfile = TripTrackingProfile.values.firstWhere(
      (value) => value.name == map['profile'],
      orElse: () => TripTrackingProfile.roadVehicle,
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
    final endingOdometerDraft = _optionalPersistedOdometerValue(
      map['endingOdometerDraft'],
    );
    final manualAdjustments = map['manualAdjustments'] is Iterable
        ? (map['manualAdjustments'] as Iterable)
              .whereType<Map>()
              .map(TripManualMileageAdjustment.tryFromMap)
              .whereType<TripManualMileageAdjustment>()
              .toList(growable: false)
        : const <TripManualMileageAdjustment>[];
    final advisories = map['advisories'] is Iterable
        ? (map['advisories'] as Iterable)
              .whereType<Map>()
              .map(TripTrackingAdvisoryEvent.fromMap)
              .where(
                (event) =>
                    event.sessionId == id &&
                    event.vehicleId == vehicleId &&
                    startedAt != null &&
                    finishedAt != null &&
                    !event.detectedAt.isBefore(startedAt) &&
                    !event.detectedAt.isAfter(finishedAt),
              )
              .toList(growable: false)
        : const <TripTrackingAdvisoryEvent>[];
    final tripEvents = map['tripEvents'] is Iterable
        ? (map['tripEvents'] as Iterable)
              .whereType<Map>()
              .map(TripManualEvent.tryFromMap)
              .whereType<TripManualEvent>()
              .where(
                (event) =>
                    startedAt != null &&
                    finishedAt != null &&
                    !event.occurredAt.isBefore(startedAt) &&
                    !event.occurredAt.isAfter(finishedAt),
              )
              .toList(growable: false)
        : const <TripManualEvent>[];
    final transitionAudits =
        _transitionAuditsFromMapValue(
              map['transitionAudits'],
              sessionId: id,
              vehicleId: vehicleId,
              profile: safeProfile,
              startedAt:
                  startedAt ??
                  DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
            )
            .where(
              (event) =>
                  finishedAt == null ||
                  !event.eventTimestamp.isAfter(finishedAt),
            )
            .toList(growable: false);
    final batteryStateSummary = TripTrackingBatteryStateSummary.tryFromMap(
      map['batteryStateSummary'],
    );
    final permissionHistory = _permissionHistoryFromMap(
      map['permissionHistory'],
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
      profile: safeProfile,
      profileId: _safeIdentifier(map['profileId']).isEmpty
          ? TripTrackingProfile.values
                .firstWhere(
                  (value) => value.name == map['profile'],
                  orElse: () => TripTrackingProfile.roadVehicle,
                )
                .name
          : _safeIdentifier(map['profileId']),
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
      endingOdometerDraft: endingOdometerDraft,
      manualAdjustments: manualAdjustments,
      advisories: advisories,
      tripEvents: tripEvents,
      transitionAudits: transitionAudits,
      batteryStateSummary: batteryStateSummary,
      permissionHistory: permissionHistory,
      recoveryCount: _safeRecoveryCount(map['recoveryCount']),
      tripLogProposalState: TripTrackingTripLogProposalState.values.firstWhere(
        (value) => value.name == map['tripLogProposalState'],
        orElse: () => TripTrackingTripLogProposalState.pending,
      ),
      tripLogProposalAttemptCount: _safeRecoveryCount(
        map['tripLogProposalAttemptCount'],
      ),
      tripLogProposalLastAttemptAt: DateTime.tryParse(
        '${map['tripLogProposalLastAttemptAt'] ?? ''}',
      )?.toUtc(),
      usageDayClassification: TripOdometerUsageDayClassification.values
          .firstWhere(
            (value) => value.name == map['usageDayClassification'],
            orElse: () => TripOdometerUsageDayClassification.regular,
          ),
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
