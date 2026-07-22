class TripTrackingQuarantinedSession {
  const TripTrackingQuarantinedSession({
    required this.sessionId,
    required this.revision,
    required this.sessionPayload,
    required this.reasonCode,
    required this.quarantinedAtUtc,
    this.schemaVersion = 1,
  });

  final String sessionId;
  final int revision;
  final Map<String, Object?> sessionPayload;
  final String reasonCode;
  final DateTime quarantinedAtUtc;
  final int schemaVersion;

  Map<String, Object?> toMap() => {
    'schemaVersion': schemaVersion,
    'sessionId': sessionId,
    'revision': revision,
    'reasonCode': reasonCode,
    'quarantinedAtUtc': quarantinedAtUtc.toUtc().toIso8601String(),
    'session': sessionPayload,
    'evidencePreserved': true,
    'automaticDeletionAllowed': false,
    'odometerIsGlobalTruth': true,
  };

  static TripTrackingQuarantinedSession? tryFromMap(Map<dynamic, dynamic> map) {
    final rawSession = map['session'];
    final sessionId = _safeToken(map['sessionId']);
    final revision = map['revision'];
    final reason = _safeToken(map['reasonCode']);
    final quarantinedAt = DateTime.tryParse('${map['quarantinedAtUtc'] ?? ''}');
    if (map['schemaVersion'] != 1 ||
        rawSession is! Map ||
        sessionId == null ||
        revision is! int ||
        revision < 0 ||
        reason == null ||
        quarantinedAt == null ||
        map['evidencePreserved'] != true ||
        map['automaticDeletionAllowed'] != false ||
        map['odometerIsGlobalTruth'] != true) {
      return null;
    }
    final sessionPayload = _stringKeyedMap(rawSession);
    if (sessionPayload == null ||
        sessionPayload['id'] != sessionId ||
        sessionPayload['revision'] != revision) {
      return null;
    }
    return TripTrackingQuarantinedSession(
      sessionId: sessionId,
      revision: revision,
      sessionPayload: Map.unmodifiable(sessionPayload),
      reasonCode: reason,
      quarantinedAtUtc: quarantinedAt.toUtc(),
    );
  }
}

Map<String, Object?>? _stringKeyedMap(Map<dynamic, dynamic> value) {
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) return null;
    result[entry.key as String] = entry.value;
  }
  return result;
}

String? _safeToken(Object? value) {
  if (value is! String ||
      value.isEmpty ||
      value.trim() != value ||
      value.length > 160) {
    return null;
  }
  return value;
}
