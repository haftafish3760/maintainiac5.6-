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
  failedRecoverable,
  failedTerminal,
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
