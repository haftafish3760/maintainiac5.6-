import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Checksummed envelope for one generation of the active trip checkpoint.
class TripTrackingSessionSnapshotEnvelope {
  const TripTrackingSessionSnapshotEnvelope({
    required this.generation,
    required this.sessionId,
    required this.payload,
    required this.checksum,
    this.schemaVersion = currentSchemaVersion,
  });

  static const currentSchemaVersion = 1;

  final int generation;
  final String sessionId;
  final Map<String, Object?> payload;
  final String checksum;
  final int schemaVersion;

  factory TripTrackingSessionSnapshotEnvelope.create({
    required int generation,
    required String sessionId,
    required Map<String, Object?> payload,
  }) => TripTrackingSessionSnapshotEnvelope(
    generation: generation,
    sessionId: sessionId,
    payload: payload,
    checksum: _checksum(generation, sessionId, payload),
  );

  Map<String, Object?> toMap() => {
    'schemaVersion': schemaVersion,
    'generation': generation,
    'sessionId': sessionId,
    'payload': payload,
    'checksum': checksum,
  };

  static TripTrackingSessionSnapshotEnvelope? tryFromMap(
    Map<dynamic, dynamic> map,
  ) {
    final generation = map['generation'];
    final sessionId = map['sessionId'];
    final rawPayload = map['payload'];
    final checksum = map['checksum'];
    if (map['schemaVersion'] != currentSchemaVersion ||
        generation is! int ||
        generation < 1 ||
        sessionId is! String ||
        sessionId.isEmpty ||
        sessionId.length > 160 ||
        rawPayload is! Map ||
        checksum is! String) {
      return null;
    }
    final payload = <String, Object?>{};
    for (final entry in rawPayload.entries) {
      if (entry.key is! String) return null;
      payload[entry.key as String] = entry.value;
    }
    if (_checksum(generation, sessionId, payload) != checksum) return null;
    return TripTrackingSessionSnapshotEnvelope(
      generation: generation,
      sessionId: sessionId,
      payload: payload,
      checksum: checksum,
    );
  }
}

String _checksum(
  int generation,
  String sessionId,
  Map<String, Object?> payload,
) => sha256
    .convert(
      utf8.encode(jsonEncode([generation, sessionId, _canonicalize(payload)])),
    )
    .toString();

Object? _canonicalize(Object? value) {
  if (value is Map) {
    final entries = value.entries.toList()
      ..sort((a, b) => '${a.key}'.compareTo('${b.key}'));
    return <String, Object?>{
      for (final entry in entries) '${entry.key}': _canonicalize(entry.value),
    };
  }
  if (value is Iterable) return value.map(_canonicalize).toList();
  return value;
}
