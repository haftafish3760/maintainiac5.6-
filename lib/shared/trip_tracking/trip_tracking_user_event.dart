enum TripTrackingUserEventKind {
  stop,
  pickup,
  dropoff,
  fuel,
  loading,
  unloading,
  customer,
  jobSite,
  breakTime,
  other,
}

/// A driver-created trip event. It records only the user's explicit action;
/// GPS, motion recognition, maps, and remote systems cannot create one.
class TripTrackingUserEvent {
  const TripTrackingUserEvent({
    required this.id,
    required this.sessionId,
    required this.vehicleId,
    required this.profileId,
    required this.kind,
    required this.occurredAt,
    required this.recordedAt,
    required this.initiatingSource,
    this.note,
  });

  final String id;
  final String sessionId;
  final String vehicleId;
  final String profileId;
  final TripTrackingUserEventKind kind;
  final DateTime occurredAt;
  final DateTime recordedAt;
  final String initiatingSource;
  final String? note;

  Map<String, Object?> toMap() => {
    'id': _safeToken(id),
    'sessionId': _safeToken(sessionId),
    'vehicleId': _safeToken(vehicleId),
    'profileId': _safeToken(profileId),
    'kind': kind.name,
    'occurredAt': occurredAt.toUtc().toIso8601String(),
    'recordedAt': recordedAt.toUtc().toIso8601String(),
    'initiatingSource': _safeToken(initiatingSource, maxLength: 48),
    if (_safeNote(note) != null) 'note': _safeNote(note),
    'userConfirmed': true,
    'gpsInferred': false,
    'remoteCreated': false,
  };

  factory TripTrackingUserEvent.fromMap(Map<dynamic, dynamic> map) {
    final occurredAt = DateTime.tryParse('${map['occurredAt'] ?? ''}');
    final recordedAt = DateTime.tryParse('${map['recordedAt'] ?? ''}');
    final hasUserAuthority =
        map['userConfirmed'] == true &&
        map['gpsInferred'] == false &&
        map['remoteCreated'] == false;
    return TripTrackingUserEvent(
      id: hasUserAuthority ? _safeToken(map['id']) : '',
      sessionId: _safeToken(map['sessionId']),
      vehicleId: _safeToken(map['vehicleId']),
      profileId: _safeToken(map['profileId']),
      kind: TripTrackingUserEventKind.values.firstWhere(
        (value) => value.name == map['kind'],
        orElse: () => TripTrackingUserEventKind.other,
      ),
      occurredAt:
          occurredAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      recordedAt:
          recordedAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      initiatingSource: _safeToken(
        map['initiatingSource'],
        maxLength: 48,
        fallback: 'unknown',
      ),
      note: _safeNote(map['note']),
    );
  }

  bool belongsTo({
    required String expectedSessionId,
    required String expectedVehicleId,
    required String expectedProfileId,
    required DateTime tripStartedAt,
    DateTime? tripFinishedAt,
  }) {
    if (id.isEmpty ||
        sessionId != expectedSessionId ||
        vehicleId != expectedVehicleId ||
        profileId != expectedProfileId ||
        !_isAllowedInitiatingSource(initiatingSource) ||
        occurredAt.isBefore(tripStartedAt) ||
        recordedAt.isBefore(occurredAt)) {
      return false;
    }
    final latest =
        tripFinishedAt ?? tripStartedAt.add(const Duration(days: 30));
    return !occurredAt.isAfter(latest) &&
        !recordedAt.isAfter(latest.add(const Duration(days: 30)));
  }
}

bool _isAllowedInitiatingSource(String source) => switch (source) {
  'dashboard' ||
  'trip_screen' ||
  'voice_assistant' ||
  'recovery_review' => true,
  _ => false,
};

String _safeToken(Object? value, {int maxLength = 160, String fallback = ''}) {
  if (value is! String) return fallback;
  final clean = value.trim();
  if (clean.isEmpty ||
      clean.length > maxLength ||
      !RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(clean)) {
    return fallback;
  }
  return clean;
}

String? _safeNote(Object? value) {
  if (value is! String) return null;
  final clean = value.trim().replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ');
  if (clean.isEmpty) return null;
  return clean.length <= 240 ? clean : clean.substring(0, 240);
}
