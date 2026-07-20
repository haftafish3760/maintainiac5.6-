import 'trip_tracking_models.dart';

/// Durable audit evidence for one accepted or rejected lifecycle transition.
class TripTrackingLifecycleEvent {
  const TripTrackingLifecycleEvent({
    required this.sessionId,
    required this.previousState,
    required this.newState,
    required this.eventTimestampUtc,
    required this.sequenceNumber,
    required this.reasonCode,
    required this.initiatingSource,
    required this.vehicleId,
    required this.profileId,
    required this.revision,
    required this.confidenceState,
    required this.permissionState,
    required this.trackingQualityMode,
    required this.accepted,
    this.schemaVersion = currentSchemaVersion,
  });

  static const currentSchemaVersion = 1;

  final String sessionId;
  final TripTrackingSessionLifecycleState previousState;
  final TripTrackingSessionLifecycleState newState;
  final DateTime eventTimestampUtc;
  final int sequenceNumber;
  final String reasonCode;
  final String initiatingSource;
  final String vehicleId;
  final String profileId;
  final int revision;
  final String confidenceState;
  final String permissionState;
  final String trackingQualityMode;
  final bool accepted;
  final int schemaVersion;

  Map<String, Object?> toMap() => {
    'schemaVersion': schemaVersion,
    'sessionId': sessionId,
    'previousState': previousState.name,
    'newState': newState.name,
    'eventTimestampUtc': eventTimestampUtc.toUtc().toIso8601String(),
    'sequenceNumber': sequenceNumber,
    'reasonCode': reasonCode,
    'initiatingSource': initiatingSource,
    'vehicleId': vehicleId,
    'profileId': profileId,
    'revision': revision,
    'confidenceState': confidenceState,
    'permissionState': permissionState,
    'trackingQualityMode': trackingQualityMode,
    'accepted': accepted,
  };

  static TripTrackingLifecycleEvent? tryFromMap(Map<dynamic, dynamic> map) {
    final previous = _stateNamed(map['previousState']);
    final next = _stateNamed(map['newState']);
    final timestamp = DateTime.tryParse('${map['eventTimestampUtc'] ?? ''}');
    final sequence = map['sequenceNumber'];
    final revision = map['revision'];
    final schemaVersion = map['schemaVersion'];
    final sessionId = _boundedToken(map['sessionId']);
    final vehicleId = _boundedToken(map['vehicleId']);
    final profileId = _boundedToken(map['profileId']);
    final reasonCode = _boundedToken(map['reasonCode']);
    final source = _boundedToken(map['initiatingSource']);
    final confidence = _boundedToken(map['confidenceState']);
    final permission = _boundedToken(map['permissionState']);
    final quality = _boundedToken(map['trackingQualityMode']);
    if (previous == null ||
        next == null ||
        timestamp == null ||
        !timestamp.isUtc ||
        sequence is! int ||
        sequence < 1 ||
        revision is! int ||
        revision < 1 ||
        schemaVersion != currentSchemaVersion ||
        sessionId == null ||
        vehicleId == null ||
        profileId == null ||
        reasonCode == null ||
        source == null ||
        confidence == null ||
        permission == null ||
        quality == null ||
        map['accepted'] is! bool) {
      return null;
    }
    return TripTrackingLifecycleEvent(
      sessionId: sessionId,
      previousState: previous,
      newState: next,
      eventTimestampUtc: timestamp,
      sequenceNumber: sequence,
      reasonCode: reasonCode,
      initiatingSource: source,
      vehicleId: vehicleId,
      profileId: profileId,
      revision: revision,
      confidenceState: confidence,
      permissionState: permission,
      trackingQualityMode: quality,
      accepted: map['accepted'] as bool,
    );
  }
}

TripTrackingSessionLifecycleState? _stateNamed(Object? value) {
  for (final state in TripTrackingSessionLifecycleState.values) {
    if (state.name == value) return state;
  }
  return null;
}

String? _boundedToken(Object? value) {
  if (value is! String ||
      value.isEmpty ||
      value.trim() != value ||
      value.length > 160) {
    return null;
  }
  return value;
}
