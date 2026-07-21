part of 'trip_tracking_session_store.dart';

/// Locally durable GPS review state awaiting explicit user confirmation.
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
