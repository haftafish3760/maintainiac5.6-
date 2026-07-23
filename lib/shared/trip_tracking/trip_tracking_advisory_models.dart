// ignore_for_file: constant_identifier_names
// odometerIsGlobalTruth: true.
part of 'trip_tracking_models.dart';

enum TripTrackingProfile {
  roadVehicle,
  rideshareVehicle,
  deliveryVehicle,
  contractorVehicle,
  lowSpeedEquipment,
}

enum TripSamplingMode { economy, balanced, precision }

enum TripActivity { unknown, still, walking, running, cycling, automotive }

/// Shared, advisory-only interpretation of vehicle movement. It never creates
/// or closes a TripLog entry by itself.
enum TripMotionState { unknown, moving, stopCandidate, stopped }

/// A GPS-assisted suggestion. It is intentionally separate from confirmed
/// TripLog history and exists only until the driver reviews it.
enum TripTrackingAdvisoryType { probableStop, resumedMovement }

enum TripTrackingConfidence { unknown, low, medium, high }

enum TripInitialFixQuality {
  freshPrecise,
  freshModerate,
  freshLowQuality,
  staleCached,
  approximateOnly,
  unavailable,
  rejected,
}

/// Coordinate-free initial-fix evidence retained for recovery and diagnostics.
class TripInitialFixAssessment {
  const TripInitialFixAssessment({
    required this.quality,
    required this.assessedAt,
    required this.confidence,
    required this.mayUseProvisionally,
    this.sampleRecordedAt,
    this.sampleAge,
    this.horizontalAccuracyMeters,
  });

  final TripInitialFixQuality quality;
  final DateTime assessedAt;
  final DateTime? sampleRecordedAt;
  final Duration? sampleAge;
  final double? horizontalAccuracyMeters;
  final TripTrackingConfidence confidence;
  final bool mayUseProvisionally;

  bool get canConfirmMileage => false;

  Map<String, Object?> toMap() => {
    'quality': quality.name,
    'assessedAt': assessedAt.toUtc().toIso8601String(),
    'sampleRecordedAt': sampleRecordedAt?.toUtc().toIso8601String(),
    'sampleAgeMillis': sampleAge?.inMilliseconds,
    'horizontalAccuracyMeters': horizontalAccuracyMeters,
    'confidence': confidence.name,
    'mayUseProvisionally': mayUseProvisionally,
    'canConfirmMileage': false,
  };

  static TripInitialFixAssessment? tryFromMap(Map<dynamic, dynamic> map) {
    final qualities = TripInitialFixQuality.values.where(
      (value) => value.name == map['quality'],
    );
    final confidences = TripTrackingConfidence.values.where(
      (value) => value.name == map['confidence'],
    );
    final assessedAt = DateTime.tryParse('${map['assessedAt'] ?? ''}')?.toUtc();
    final sampleRecordedAt = map['sampleRecordedAt'] == null
        ? null
        : DateTime.tryParse('${map['sampleRecordedAt']}')?.toUtc();
    final rawAge = map['sampleAgeMillis'];
    final rawAccuracy = map['horizontalAccuracyMeters'];
    if (qualities.isEmpty ||
        confidences.isEmpty ||
        assessedAt == null ||
        (map['sampleRecordedAt'] != null && sampleRecordedAt == null) ||
        (rawAge != null && (rawAge is! num || rawAge < 0)) ||
        (rawAccuracy != null &&
            (rawAccuracy is! num ||
                !rawAccuracy.isFinite ||
                rawAccuracy < 0))) {
      return null;
    }
    final quality = qualities.first;
    final expectedUsable =
        quality == TripInitialFixQuality.freshPrecise ||
        quality == TripInitialFixQuality.freshModerate ||
        quality == TripInitialFixQuality.freshLowQuality;
    return TripInitialFixAssessment(
      quality: quality,
      assessedAt: assessedAt,
      sampleRecordedAt: sampleRecordedAt,
      sampleAge: rawAge == null ? null : Duration(milliseconds: rawAge.toInt()),
      horizontalAccuracyMeters: rawAccuracy?.toDouble(),
      confidence: confidences.first,
      mayUseProvisionally: map['mayUseProvisionally'] == true && expectedUsable,
    );
  }
}

enum TripStopCandidateEvidence { stationaryGps, walkingAssisted }

/// A recoverable, review-only suggestion that the vehicle may have stopped.
/// It never closes a trip, changes mileage, or writes confirmed TripLog data.
class TripStopCandidate {
  const TripStopCandidate({
    required this.startedAt,
    required this.detectedAt,
    required this.confidence,
    required this.evidence,
  });

  final DateTime startedAt;
  final DateTime detectedAt;
  final TripTrackingConfidence confidence;
  final TripStopCandidateEvidence evidence;

  bool get requiresUserReview => true;
  bool get canFinalizeTrip => false;
  bool get canChangeOdometer => false;
}

enum TripTrackingSignalGapReason { userPause, systemPause }

/// A durable boundary where trusted GPS collection was intentionally absent.
/// No route or distance is inferred across this boundary.
class TripTrackingSignalGap {
  const TripTrackingSignalGap({
    required this.startedAt,
    required this.reason,
    this.endedAt,
  });

  final DateTime startedAt;
  final DateTime? endedAt;
  final TripTrackingSignalGapReason reason;

  bool get isOpen => endedAt == null;
  double get estimatedDistanceMeters => 0;
  bool get requiresUserReview => true;
  bool get canChangeOdometer => false;

  TripTrackingSignalGap closeAt(DateTime value) => TripTrackingSignalGap(
    startedAt: startedAt,
    endedAt: value,
    reason: reason,
  );

  Map<String, Object?> toMap() => {
    'startedAt': startedAt.toUtc().toIso8601String(),
    'endedAt': endedAt?.toUtc().toIso8601String(),
    'reason': reason.name,
    'estimatedDistanceMeters': 0,
    'requiresUserReview': true,
  };

  static TripTrackingSignalGap? tryFromMap(Map<dynamic, dynamic> map) {
    final startedAt = DateTime.tryParse('${map['startedAt'] ?? ''}')?.toUtc();
    final rawEndedAt = map['endedAt'];
    final endedAt = rawEndedAt == null
        ? null
        : DateTime.tryParse('$rawEndedAt')?.toUtc();
    final reasons = TripTrackingSignalGapReason.values.where(
      (value) => value.name == map['reason'],
    );
    if (startedAt == null ||
        reasons.isEmpty ||
        (rawEndedAt != null && endedAt == null) ||
        (endedAt != null && endedAt.isBefore(startedAt))) {
      return null;
    }
    return TripTrackingSignalGap(
      startedAt: startedAt,
      endedAt: endedAt,
      reason: reasons.first,
    );
  }
}

enum TripTrackingSessionLifecycleState {
  disabled,
  permissionRequired,
  ready,
  starting,
  active,
  paused,
  degraded,
  interrupted,
  recovering,
  awaitingReview,
  stopping,
  completed,
  cancelled,
  failedRecoverable,
  failedTerminal,
}

/// Contract-level lifecycle states required by the Part 2 session-state-machine
/// specification. These are a stable façade used by audits and external
// decisioning while the runtime session state remains the canonical
// TripTrackingSessionLifecycleState.
enum TripTrackingSessionLifecycleContractState {
  IDLE,
  PREPARING,
  AWAITING_PERMISSION,
  AWAITING_LOCATION_SERVICES,
  AWAITING_INITIAL_FIX,
  CANDIDATE_MOVEMENT,
  ACTIVE_TRACKING,
  TEMPORARILY_STOPPED,
  PAUSED_BY_USER,
  PAUSED_BY_SYSTEM,
  SIGNAL_DEGRADED,
  SIGNAL_LOST,
  RECOVERING,
  COMPLETION_PENDING,
  COMPLETED,
  CANCELLED,
  FAILED_RECOVERABLE,
  FAILED_UNRECOVERABLE,
}

extension TripTrackingSessionLifecycleStateContractMapper
    on TripTrackingSessionLifecycleState {
  TripTrackingSessionLifecycleContractState toContractState() => switch (this) {
    TripTrackingSessionLifecycleState.disabled =>
      TripTrackingSessionLifecycleContractState.IDLE,
    TripTrackingSessionLifecycleState.permissionRequired =>
      TripTrackingSessionLifecycleContractState.AWAITING_PERMISSION,
    TripTrackingSessionLifecycleState.ready =>
      TripTrackingSessionLifecycleContractState.PREPARING,
    TripTrackingSessionLifecycleState.starting =>
      TripTrackingSessionLifecycleContractState.AWAITING_INITIAL_FIX,
    TripTrackingSessionLifecycleState.active =>
      TripTrackingSessionLifecycleContractState.ACTIVE_TRACKING,
    TripTrackingSessionLifecycleState.paused =>
      TripTrackingSessionLifecycleContractState.PAUSED_BY_USER,
    TripTrackingSessionLifecycleState.degraded =>
      TripTrackingSessionLifecycleContractState.SIGNAL_DEGRADED,
    TripTrackingSessionLifecycleState.interrupted =>
      TripTrackingSessionLifecycleContractState.SIGNAL_LOST,
    TripTrackingSessionLifecycleState.recovering =>
      TripTrackingSessionLifecycleContractState.RECOVERING,
    TripTrackingSessionLifecycleState.awaitingReview =>
      TripTrackingSessionLifecycleContractState.COMPLETION_PENDING,
    TripTrackingSessionLifecycleState.stopping =>
      TripTrackingSessionLifecycleContractState.COMPLETION_PENDING,
    TripTrackingSessionLifecycleState.completed =>
      TripTrackingSessionLifecycleContractState.COMPLETED,
    TripTrackingSessionLifecycleState.cancelled =>
      TripTrackingSessionLifecycleContractState.CANCELLED,
    TripTrackingSessionLifecycleState.failedRecoverable =>
      TripTrackingSessionLifecycleContractState.FAILED_RECOVERABLE,
    TripTrackingSessionLifecycleState.failedTerminal =>
      TripTrackingSessionLifecycleContractState.FAILED_UNRECOVERABLE,
  };
}

extension TripTrackingSessionLifecycleContractStateRuntimeMapper
    on TripTrackingSessionLifecycleContractState {
  TripTrackingSessionLifecycleState toRuntimeState() => switch (this) {
    TripTrackingSessionLifecycleContractState.IDLE =>
      TripTrackingSessionLifecycleState.disabled,
    TripTrackingSessionLifecycleContractState.PREPARING =>
      TripTrackingSessionLifecycleState.ready,
    TripTrackingSessionLifecycleContractState.AWAITING_PERMISSION =>
      TripTrackingSessionLifecycleState.permissionRequired,
    TripTrackingSessionLifecycleContractState.AWAITING_LOCATION_SERVICES =>
      TripTrackingSessionLifecycleState.permissionRequired,
    TripTrackingSessionLifecycleContractState.AWAITING_INITIAL_FIX =>
      TripTrackingSessionLifecycleState.starting,
    TripTrackingSessionLifecycleContractState.CANDIDATE_MOVEMENT =>
      TripTrackingSessionLifecycleState.active,
    TripTrackingSessionLifecycleContractState.ACTIVE_TRACKING =>
      TripTrackingSessionLifecycleState.active,
    TripTrackingSessionLifecycleContractState.TEMPORARILY_STOPPED =>
      TripTrackingSessionLifecycleState.active,
    TripTrackingSessionLifecycleContractState.PAUSED_BY_USER =>
      TripTrackingSessionLifecycleState.paused,
    TripTrackingSessionLifecycleContractState.PAUSED_BY_SYSTEM =>
      TripTrackingSessionLifecycleState.paused,
    TripTrackingSessionLifecycleContractState.SIGNAL_DEGRADED =>
      TripTrackingSessionLifecycleState.degraded,
    TripTrackingSessionLifecycleContractState.SIGNAL_LOST =>
      TripTrackingSessionLifecycleState.interrupted,
    TripTrackingSessionLifecycleContractState.RECOVERING =>
      TripTrackingSessionLifecycleState.recovering,
    TripTrackingSessionLifecycleContractState.COMPLETION_PENDING =>
      TripTrackingSessionLifecycleState.awaitingReview,
    TripTrackingSessionLifecycleContractState.COMPLETED =>
      TripTrackingSessionLifecycleState.completed,
    TripTrackingSessionLifecycleContractState.CANCELLED =>
      TripTrackingSessionLifecycleState.cancelled,
    TripTrackingSessionLifecycleContractState.FAILED_RECOVERABLE =>
      TripTrackingSessionLifecycleState.failedRecoverable,
    TripTrackingSessionLifecycleContractState.FAILED_UNRECOVERABLE =>
      TripTrackingSessionLifecycleState.failedTerminal,
  };
}

enum TripTrackingHealthState {
  healthy,
  reduced,
  poor,
  interrupted,
  unavailable,
  permissionBlocked,
  platformRestricted,
}

enum TripTrackingPauseKind { user, system }

enum TripTrackingAdvisoryDisposition {
  pending,
  confirmed,
  rejected,
  corrected,
  dismissed,
}

class TripTrackingAdvisoryEvent {
  const TripTrackingAdvisoryEvent({
    required this.id,
    required this.type,
    required this.sessionId,
    required this.vehicleId,
    required this.profile,
    required this.detectedAt,
    required this.evidenceStartedAt,
    required this.evidenceEndedAt,
    required this.confidence,
    required this.suggestedAction,
    this.disposition = TripTrackingAdvisoryDisposition.pending,
    this.tripLogReference,
  });

  final String id;
  final TripTrackingAdvisoryType type;
  final String sessionId;
  final String vehicleId;
  final TripTrackingProfile profile;
  final DateTime detectedAt;
  final DateTime evidenceStartedAt;
  final DateTime evidenceEndedAt;
  final TripTrackingConfidence confidence;
  final String suggestedAction;
  final TripTrackingAdvisoryDisposition disposition;
  final String? tripLogReference;

  TripTrackingAdvisoryEvent copyWith({
    DateTime? evidenceStartedAt,
    DateTime? evidenceEndedAt,
    TripTrackingConfidence? confidence,
    TripTrackingAdvisoryDisposition? disposition,
    String? tripLogReference,
  }) => TripTrackingAdvisoryEvent(
    id: id,
    type: type,
    sessionId: sessionId,
    vehicleId: vehicleId,
    profile: profile,
    detectedAt: detectedAt,
    evidenceStartedAt: evidenceStartedAt ?? this.evidenceStartedAt,
    evidenceEndedAt: evidenceEndedAt ?? this.evidenceEndedAt,
    confidence: confidence ?? this.confidence,
    suggestedAction: suggestedAction,
    disposition: disposition ?? this.disposition,
    tripLogReference: tripLogReference ?? this.tripLogReference,
  );

  Map<String, Object?> toMap() {
    final safeEvidenceEndedAt = evidenceEndedAt.isBefore(evidenceStartedAt)
        ? evidenceStartedAt
        : evidenceEndedAt;
    return {
      'id': _safeText(id, maxLength: 160),
      'type': type.name,
      'sessionId': _safeText(sessionId, maxLength: 160),
      'vehicleId': _safeText(vehicleId, maxLength: 160),
      'profile': profile.name,
      'detectedAt': detectedAt.toIso8601String(),
      'evidenceStartedAt': evidenceStartedAt.toIso8601String(),
      'evidenceEndedAt': safeEvidenceEndedAt.toIso8601String(),
      'confidence': confidence.name,
      'suggestedAction': _safeText(suggestedAction, maxLength: 120),
      'disposition': disposition.name,
      'tripLogReference': _optionalSafeText(tripLogReference, maxLength: 160),
    };
  }

  factory TripTrackingAdvisoryEvent.fromMap(Map<dynamic, dynamic> map) {
    final detectedAt =
        _safeAdvisoryTimestamp(map['detectedAt']) ??
        _safeAdvisoryFallbackTimestamp();
    final evidenceStartedAt = _safeAdvisoryEvidenceStartedAt(
      map['evidenceStartedAt'],
      detectedAt: detectedAt,
    );
    final evidenceEndedAt = _safeAdvisoryEvidenceEndedAt(
      map['evidenceEndedAt'],
      evidenceStartedAt: evidenceStartedAt,
      detectedAt: detectedAt,
    );
    return TripTrackingAdvisoryEvent(
      id: _safeText(map['id'], maxLength: 160),
      type: TripTrackingAdvisoryType.values.firstWhere(
        (value) => value.name == map['type'],
        orElse: () => TripTrackingAdvisoryType.probableStop,
      ),
      sessionId: _safeText(map['sessionId'], maxLength: 160),
      vehicleId: _safeText(map['vehicleId'], maxLength: 160),
      profile: TripTrackingProfile.values.firstWhere(
        (value) => value.name == map['profile'],
        orElse: () => TripTrackingProfile.roadVehicle,
      ),
      detectedAt: detectedAt,
      evidenceStartedAt: evidenceStartedAt,
      evidenceEndedAt: evidenceEndedAt,
      confidence: TripTrackingConfidence.values.firstWhere(
        (value) => value.name == map['confidence'],
        orElse: () => TripTrackingConfidence.unknown,
      ),
      suggestedAction: _safeText(
        map['suggestedAction'],
        maxLength: 120,
        fallback: 'review',
      ),
      disposition: TripTrackingAdvisoryDisposition.values.firstWhere(
        (value) => value.name == map['disposition'],
        orElse: () => TripTrackingAdvisoryDisposition.pending,
      ),
      tripLogReference: _optionalSafeText(
        map['tripLogReference'],
        maxLength: 160,
      ),
    );
  }
}

/// Deterministic transition audit record for every local lifecycle change.
///
/// This is intentionally advisory data that remains local to the active-trip
/// checkpoint and is required for deterministic recovery, evidence replay, and
/// user-facing diagnostics.
class TripTrackingSessionTransitionAudit {
  const TripTrackingSessionTransitionAudit({
    required this.id,
    required this.sessionId,
    required this.vehicleId,
    required this.profile,
    required this.profileId,
    required this.fromState,
    required this.toState,
    this.fromContractState,
    this.toContractState,
    this.schemaVersion = 1,
    required this.eventTimestamp,
    required this.sequenceNumber,
    required this.reasonCode,
    required this.initiatingSource,
    required this.revision,
    required this.permissionState,
    required this.confidenceState,
    required this.trackingQualityMode,
    this.accepted = true,
  });

  final String id;
  final String sessionId;
  final String vehicleId;
  final TripTrackingProfile profile;
  final String profileId;
  final TripTrackingSessionLifecycleState fromState;
  final TripTrackingSessionLifecycleState toState;
  final TripTrackingSessionLifecycleContractState? fromContractState;
  final TripTrackingSessionLifecycleContractState? toContractState;
  final int schemaVersion;
  TripTrackingSessionLifecycleContractState get effectiveFromContractState =>
      fromContractState ?? fromState.toContractState();
  TripTrackingSessionLifecycleContractState get effectiveToContractState =>
      toContractState ?? toState.toContractState();
  final DateTime eventTimestamp;
  final int sequenceNumber;
  final String reasonCode;
  final String initiatingSource;
  final int revision;
  final String permissionState;
  final String confidenceState;
  final String trackingQualityMode;
  final bool accepted;

  Map<String, Object?> toMap() => {
    'schemaVersion': 1,
    'id': _safeText(id, maxLength: 160),
    'sessionId': _safeText(sessionId, maxLength: 160),
    'vehicleId': _safeText(vehicleId, maxLength: 160),
    'profile': profile.name,
    'profileId': _safeText(profileId, maxLength: 80),
    'fromState': fromState.name,
    'toState': toState.name,
    'fromContractState': effectiveFromContractState.name,
    'toContractState': effectiveToContractState.name,
    'eventTimestamp': eventTimestamp.toIso8601String(),
    'sequenceNumber': sequenceNumber,
    'reasonCode': _safeTransitionReasonCode(reasonCode),
    'initiatingSource': _safeSource(initiatingSource),
    'revision': revision,
    'permissionState': _safeText(permissionState, maxLength: 64),
    'confidenceState': _safeText(confidenceState, maxLength: 64),
    'trackingQualityMode': _safeText(trackingQualityMode, maxLength: 64),
    'accepted': accepted,
  };

  factory TripTrackingSessionTransitionAudit.fromMap(
    Map<dynamic, dynamic> map,
  ) {
    final eventTimestamp = _safeTimestamp(map['eventTimestamp']);
    final profileId = _safeText(
      map['profileId'],
      maxLength: 80,
      fallback: TripTrackingProfile.roadVehicle.name,
    );
    final profileValue = _safeText(map['profile'], maxLength: 80);
    final resolvedProfile = TripTrackingProfile.values.firstWhere(
      (value) => value.name == profileValue,
      orElse: () => TripTrackingProfile.values.firstWhere(
        (value) => value.name == profileId,
        orElse: () => TripTrackingProfile.roadVehicle,
      ),
    );
    return TripTrackingSessionTransitionAudit(
      schemaVersion: map['schemaVersion'] == null
          ? 1
          : map['schemaVersion'] is int
          ? map['schemaVersion'] as int
          : 0,
      id: _safeText(map['id'], maxLength: 160),
      sessionId: _safeText(map['sessionId'], maxLength: 160),
      vehicleId: _safeText(map['vehicleId'], maxLength: 160),
      profile: resolvedProfile,
      profileId: profileId,
      fromState: TripTrackingSessionLifecycleState.values.firstWhere(
        (value) => value.name == map['fromState'],
        orElse: () => TripTrackingSessionLifecycleState.ready,
      ),
      toState: TripTrackingSessionLifecycleState.values.firstWhere(
        (value) => value.name == map['toState'],
        orElse: () => TripTrackingSessionLifecycleState.ready,
      ),
      fromContractState: TripTrackingSessionLifecycleContractState.values
          .where((value) => value.name == map['fromContractState'])
          .firstOrNull,
      toContractState: TripTrackingSessionLifecycleContractState.values
          .where((value) => value.name == map['toContractState'])
          .firstOrNull,
      eventTimestamp: eventTimestamp,
      sequenceNumber: _safeSequenceNumber(map['sequenceNumber']),
      reasonCode: _safeTransitionReasonCode(map['reasonCode']),
      initiatingSource: _safeSource(map['initiatingSource']),
      revision: _safeTransitionRevision(map['revision']),
      permissionState: _safeTransitionMetaField(map['permissionState']),
      confidenceState: _safeTransitionMetaField(map['confidenceState']),
      trackingQualityMode: _safeTransitionMetaField(map['trackingQualityMode']),
      accepted: map['accepted'] != false,
    );
  }
}

DateTime _safeAdvisoryFallbackTimestamp() =>
    DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

DateTime? _safeAdvisoryTimestamp(Object? value) {
  if (value == null) return null;
  if (value is num) return _tripTimestampFrom(value);
  return DateTime.tryParse('$value');
}

DateTime _safeAdvisoryEvidenceStartedAt(
  Object? value, {
  required DateTime detectedAt,
}) {
  final parsed = _safeAdvisoryTimestamp(value);
  if (parsed == null || parsed.isAfter(detectedAt)) return detectedAt;
  if (detectedAt.difference(parsed) > const Duration(hours: 24)) {
    return detectedAt;
  }
  return parsed;
}

DateTime _safeAdvisoryEvidenceEndedAt(
  Object? value, {
  required DateTime evidenceStartedAt,
  required DateTime detectedAt,
}) {
  final parsed = _safeAdvisoryTimestamp(value);
  if (parsed == null) return detectedAt;
  if (parsed.isBefore(evidenceStartedAt)) return evidenceStartedAt;
  if (parsed.difference(evidenceStartedAt) > const Duration(hours: 24)) {
    return detectedAt.isBefore(evidenceStartedAt)
        ? evidenceStartedAt
        : detectedAt;
  }
  return parsed;
}

String _safeText(
  Object? value, {
  required int maxLength,
  String fallback = '',
}) {
  final clean = '${value ?? ''}'
      .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ')
      .trim();
  if (clean.isEmpty) return fallback;
  return clean.length > maxLength ? clean.substring(0, maxLength) : clean;
}

String? _optionalSafeText(Object? value, {required int maxLength}) {
  if (value == null) return null;
  final clean = _safeText(value, maxLength: maxLength);
  return clean.isEmpty ? null : clean;
}

const int _minTransitionSequenceNumber = 1;
const int _minTransitionRevision = 1;

String _safeTransitionReasonCode(Object? value) {
  if (value is! String) {
    return 'gps_session_transition_allowed';
  }
  final cleaned = _safeText(
    value,
    maxLength: 80,
    fallback: 'gps_session_transition_allowed',
  );
  if (!RegExp(r'^[a-z][a-z0-9_]{0,79}$').hasMatch(cleaned)) {
    return 'gps_session_transition_allowed';
  }
  return cleaned;
}

String _safeTransitionMetaField(Object? value) {
  if (value is! String) return '';
  final cleaned = _safeText(value, maxLength: 64);
  if (!RegExp(r'^[a-z][a-z0-9_]{0,63}$').hasMatch(cleaned)) {
    return '';
  }
  return cleaned;
}

String _safeSource(Object? value) {
  if (value is! String) return 'controller';
  final cleaned = _safeText(value.toLowerCase(), maxLength: 48);
  if (!RegExp(r'^[a-z][a-z0-9_]{0,47}$').hasMatch(cleaned)) {
    return 'controller';
  }
  return cleaned;
}

DateTime _safeTimestamp(Object? value) {
  final parsed = _tripTimestampFrom(value);
  return parsed ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}

int _safeTransitionRevision(Object? value) {
  if (value is! num || !value.isFinite) return _minTransitionRevision;
  final parsed = value.toInt();
  if (parsed < _minTransitionRevision) return _minTransitionRevision;
  return parsed;
}

int _safeSequenceNumber(Object? value) {
  if (value is! num || !value.isFinite) {
    return _minTransitionSequenceNumber;
  }
  final parsed = value.toInt();
  if (parsed < _minTransitionSequenceNumber) {
    return _minTransitionSequenceNumber;
  }
  return parsed;
}
