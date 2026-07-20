import 'dart:convert';

import 'package:crypto/crypto.dart';

class TripRouteHistoryPoint {
  const TripRouteHistoryPoint({
    required this.latitude,
    required this.longitude,
    required this.recordedAtUtc,
    required this.horizontalAccuracyMeters,
    required this.sequence,
  });

  final double latitude;
  final double longitude;
  final DateTime recordedAtUtc;
  final double horizontalAccuracyMeters;
  final int sequence;
}

class TripRouteHistorySegment {
  const TripRouteHistorySegment({
    required this.tripId,
    required this.segmentIndex,
    required this.points,
    required this.checksum,
    this.schemaVersion = 1,
  });

  static const maxPoints = 256;
  final String tripId;
  final int segmentIndex;
  final List<TripRouteHistoryPoint> points;
  final String checksum;
  final int schemaVersion;

  factory TripRouteHistorySegment.create({
    required String tripId,
    required int segmentIndex,
    required List<TripRouteHistoryPoint> points,
  }) {
    final bounded = List<TripRouteHistoryPoint>.unmodifiable(points);
    return TripRouteHistorySegment(
      tripId: tripId,
      segmentIndex: segmentIndex,
      points: bounded,
      checksum: _segmentChecksum(tripId, segmentIndex, _encodePoints(bounded)),
    );
  }

  bool get canAppend => points.length < maxPoints;

  TripRouteHistorySegment append(TripRouteHistoryPoint point) =>
      TripRouteHistorySegment.create(
        tripId: tripId,
        segmentIndex: segmentIndex,
        points: [...points, point],
      );

  Map<String, Object?> toMap() {
    final encoded = _encodePoints(points);
    return {
      'schemaVersion': schemaVersion,
      'tripId': tripId,
      'segmentIndex': segmentIndex,
      'encodedPoints': encoded,
      'checksum': checksum,
    };
  }

  static TripRouteHistorySegment? tryFromMap(Map<dynamic, dynamic> map) {
    final tripId = map['tripId'];
    final segmentIndex = map['segmentIndex'];
    final encoded = map['encodedPoints'];
    final checksum = map['checksum'];
    if (map['schemaVersion'] != 1 ||
        !_safeId(tripId) ||
        segmentIndex is! int ||
        segmentIndex < 0 ||
        encoded is! List ||
        checksum is! String ||
        checksum != _segmentChecksum(tripId as String, segmentIndex, encoded)) {
      return null;
    }
    final points = _decodePoints(encoded);
    if (points == null || points.isEmpty || points.length > maxPoints) {
      return null;
    }
    return TripRouteHistorySegment(
      tripId: tripId,
      segmentIndex: segmentIndex,
      points: List.unmodifiable(points),
      checksum: checksum,
    );
  }
}

class TripRouteHistoryAppendResult {
  const TripRouteHistoryAppendResult({
    required this.persisted,
    required this.reasonCode,
    required this.persistedPointsToday,
    required this.tripPointCount,
  });

  final bool persisted;
  final String reasonCode;
  final int persistedPointsToday;
  final int tripPointCount;
}

class TripRouteHistoryReplayResult {
  const TripRouteHistoryReplayResult({
    required this.points,
    required this.corruptSegmentCount,
  });

  final List<TripRouteHistoryPoint> points;
  final int corruptSegmentCount;
}

class TripRouteHistorySummary {
  const TripRouteHistorySummary({
    required this.tripId,
    required this.pointCount,
    required this.segmentCount,
    required this.corruptSegmentCount,
    required this.firstPointAtUtc,
    required this.lastPointAtUtc,
  });

  final String tripId;
  final int pointCount;
  final int segmentCount;
  final int corruptSegmentCount;
  final DateTime? firstPointAtUtc;
  final DateTime? lastPointAtUtc;

  Map<String, Object?> toBundleSafeMap() => {
    'schemaVersion': 1,
    'tripId': tripId,
    'pointCount': pointCount,
    'segmentCount': segmentCount,
    'corruptSegmentCount': corruptSegmentCount,
    'firstPointAtUtc': firstPointAtUtc?.toIso8601String(),
    'lastPointAtUtc': lastPointAtUtc?.toIso8601String(),
    'routeHistoryAvailableLocally': pointCount > 0,
    'rawCoordinatesIncluded': false,
    'routeGeometryIncluded': false,
    'odometerIsGlobalTruth': true,
  };
}

List<Object?> _encodePoints(List<TripRouteHistoryPoint> points) {
  if (points.isEmpty) return const [];
  final first = points.first;
  var latitude = (first.latitude * 100000).round();
  var longitude = (first.longitude * 100000).round();
  var timestamp = first.recordedAtUtc.toUtc().millisecondsSinceEpoch;
  final encoded = <Object?>[
    [
      latitude,
      longitude,
      timestamp,
      (first.horizontalAccuracyMeters * 10).round(),
      first.sequence,
    ],
  ];
  for (final point in points.skip(1)) {
    final nextLatitude = (point.latitude * 100000).round();
    final nextLongitude = (point.longitude * 100000).round();
    final nextTimestamp = point.recordedAtUtc.toUtc().millisecondsSinceEpoch;
    encoded.add([
      nextLatitude - latitude,
      nextLongitude - longitude,
      nextTimestamp - timestamp,
      (point.horizontalAccuracyMeters * 10).round(),
      point.sequence,
    ]);
    latitude = nextLatitude;
    longitude = nextLongitude;
    timestamp = nextTimestamp;
  }
  return encoded;
}

List<TripRouteHistoryPoint>? _decodePoints(List<dynamic> encoded) {
  if (encoded.isEmpty || encoded.first is! List) return null;
  var latitude = 0;
  var longitude = 0;
  var timestamp = 0;
  var previousSequence = -1;
  final points = <TripRouteHistoryPoint>[];
  for (var index = 0; index < encoded.length; index += 1) {
    final values = encoded[index];
    if (values is! List || values.length != 5 || values.any((v) => v is! int)) {
      return null;
    }
    final raw = values.cast<int>();
    if (index == 0) {
      latitude = raw[0];
      longitude = raw[1];
      timestamp = raw[2];
    } else {
      latitude += raw[0];
      longitude += raw[1];
      timestamp += raw[2];
    }
    final accuracy = raw[3] / 10;
    final sequence = raw[4];
    if (latitude < -9000000 ||
        latitude > 9000000 ||
        longitude < -18000000 ||
        longitude > 18000000 ||
        timestamp < 0 ||
        accuracy < 0 ||
        accuracy > 250 ||
        sequence <= previousSequence) {
      return null;
    }
    points.add(
      TripRouteHistoryPoint(
        latitude: latitude / 100000,
        longitude: longitude / 100000,
        recordedAtUtc: DateTime.fromMillisecondsSinceEpoch(
          timestamp,
          isUtc: true,
        ),
        horizontalAccuracyMeters: accuracy,
        sequence: sequence,
      ),
    );
    previousSequence = sequence;
  }
  return points;
}

String _segmentChecksum(String tripId, int segmentIndex, Object encoded) =>
    sha256
        .convert(utf8.encode(jsonEncode([tripId, segmentIndex, encoded])))
        .toString();

bool _safeId(Object? value) =>
    value is String &&
    value.isNotEmpty &&
    value.trim() == value &&
    value.length <= 160 &&
    RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(value);
