import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Checksummed, generation-ordered recovery envelope used by the two-slot
/// active-session checkpoint. The prior slot is retained until the next write.
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
    final schema = map['schemaVersion'];
    final generation = map['generation'];
    final sessionId = map['sessionId'];
    final checksum = map['checksum'];
    final rawPayload = map['payload'];
    if (schema != currentSchemaVersion ||
        generation is! int ||
        generation < 1 ||
        sessionId is! String ||
        sessionId.isEmpty ||
        sessionId.length > 160 ||
        checksum is! String ||
        rawPayload is! Map) {
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
    .convert(utf8.encode(jsonEncode([generation, sessionId, payload])))
    .toString();
