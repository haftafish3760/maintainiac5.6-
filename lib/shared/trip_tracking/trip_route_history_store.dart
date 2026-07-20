import 'package:hive_flutter/hive_flutter.dart';

import 'trip_route_history_models.dart';
import 'trip_tracking_map_route_point_payload_policy.dart';
import 'trip_tracking_map_storage_policy.dart';
import 'trip_tracking_settings_store.dart';

class TripRouteHistoryStore {
  TripRouteHistoryStore._(this._box);
  TripRouteHistoryStore.memory() : _box = null;

  static const boxName = 'gps_trip_route_history_v1';
  static const _routePrefix = 'route:';
  static const _metaPrefix = 'routeMeta:';
  static const _dayPrefix = 'routeDay:';
  static Future<void> _writeTail = Future<void>.value();

  final Box<dynamic>? _box;
  final Map<String, Object?> _memory = {};

  static Future<TripRouteHistoryStore> create() async =>
      TripRouteHistoryStore._(await Hive.openBox<dynamic>(boxName));

  Future<TripRouteHistoryAppendResult> appendGpsPoint({
    required String tripId,
    required double latitude,
    required double longitude,
    required DateTime recordedAtUtc,
    required double horizontalAccuracyMeters,
    required String localDayKey,
    required TripTrackingSettings settings,
    required DateTime nowUtc,
  }) => _enqueue(() async {
    if (!_safeDayKey(localDayKey)) {
      return const TripRouteHistoryAppendResult(
        persisted: false,
        reasonCode: 'invalid_local_day_key',
        persistedPointsToday: 0,
        tripPointCount: 0,
      );
    }
    final meta = _metaFor(tripId);
    final sequence = meta?.lastSequence == null ? 0 : meta!.lastSequence + 1;
    final dayCount = _safeCount(_read('$_dayPrefix$localDayKey'));
    final budget = TripTrackingMapStoragePolicy.canPersistNextRoutePoint(
      settings: settings,
      persistedPointsToday: dayCount,
    );
    if (!budget.allowedToPersistPoint) {
      return TripRouteHistoryAppendResult(
        persisted: false,
        reasonCode: budget.reasonCode,
        persistedPointsToday: dayCount,
        tripPointCount: meta?.pointCount ?? 0,
      );
    }
    final validation = TripTrackingMapRoutePointPayloadPolicy.validate(
      payload: {
        'schemaVersion': 1,
        'tripId': tripId,
        'source': 'gps',
        'recordedAt': recordedAtUtc.toUtc().toIso8601String(),
        'sequence': sequence,
        'latitude': latitude,
        'longitude': longitude,
        'horizontalAccuracyMeters': horizontalAccuracyMeters,
      },
      expectedTripId: tripId,
      nowUtc: nowUtc.toUtc(),
      lastPersistedSequence: meta?.lastSequence,
    );
    if (!validation.accepted) {
      return TripRouteHistoryAppendResult(
        persisted: false,
        reasonCode: validation.reasonCode,
        persistedPointsToday: dayCount,
        tripPointCount: meta?.pointCount ?? 0,
      );
    }
    final lastAt = meta?.lastPointAtUtc;
    if (lastAt != null &&
        recordedAtUtc.toUtc().difference(lastAt) <
            Duration(seconds: settings.mapRouteHistorySampleIntervalSeconds)) {
      return TripRouteHistoryAppendResult(
        persisted: false,
        reasonCode: 'route_sample_interval_not_elapsed',
        persistedPointsToday: dayCount,
        tripPointCount: meta?.pointCount ?? 0,
      );
    }
    final point = TripRouteHistoryPoint(
      latitude: latitude,
      longitude: longitude,
      recordedAtUtc: recordedAtUtc.toUtc(),
      horizontalAccuracyMeters: horizontalAccuracyMeters,
      sequence: sequence,
    );
    final currentSegmentIndex = meta?.lastSegmentIndex ?? 0;
    final current = _segmentFor(tripId, currentSegmentIndex);
    final nextSegment = current != null && current.canAppend
        ? current.append(point)
        : TripRouteHistorySegment.create(
            tripId: tripId,
            segmentIndex: current == null && meta == null
                ? 0
                : currentSegmentIndex + 1,
            points: [point],
          );
    final nextMeta = _RouteMeta(
      pointCount: (meta?.pointCount ?? 0) + 1,
      segmentCount: nextSegment.segmentIndex + 1,
      lastSegmentIndex: nextSegment.segmentIndex,
      lastSequence: sequence,
      lastPointAtUtc: recordedAtUtc.toUtc(),
    );
    await _writeAll({
      _segmentKey(tripId, nextSegment.segmentIndex): nextSegment.toMap(),
      '$_metaPrefix$tripId': nextMeta.toMap(),
      '$_dayPrefix$localDayKey': dayCount + 1,
    });
    return TripRouteHistoryAppendResult(
      persisted: true,
      reasonCode: 'route_point_persisted',
      persistedPointsToday: dayCount + 1,
      tripPointCount: nextMeta.pointCount,
    );
  });

  TripRouteHistoryReplayResult replay(String tripId) {
    final entries = _routeEntries(tripId);
    final points = <TripRouteHistoryPoint>[];
    var corrupt = 0;
    for (final entry in entries) {
      final value = entry.value;
      final segment = value is Map
          ? TripRouteHistorySegment.tryFromMap(value)
          : null;
      if (segment == null || segment.tripId != tripId) {
        corrupt += 1;
        continue;
      }
      points.addAll(segment.points);
    }
    points.sort((a, b) => a.sequence.compareTo(b.sequence));
    final deduplicated = <TripRouteHistoryPoint>[];
    var lastSequence = -1;
    for (final point in points) {
      if (point.sequence <= lastSequence) continue;
      deduplicated.add(point);
      lastSequence = point.sequence;
    }
    return TripRouteHistoryReplayResult(
      points: List.unmodifiable(deduplicated),
      corruptSegmentCount: corrupt,
    );
  }

  TripRouteHistorySummary summary(String tripId) {
    final replayed = replay(tripId);
    return TripRouteHistorySummary(
      tripId: tripId,
      pointCount: replayed.points.length,
      segmentCount: _routeEntries(tripId).length,
      corruptSegmentCount: replayed.corruptSegmentCount,
      firstPointAtUtc: replayed.points.isEmpty
          ? null
          : replayed.points.first.recordedAtUtc,
      lastPointAtUtc: replayed.points.isEmpty
          ? null
          : replayed.points.last.recordedAtUtc,
    );
  }

  Future<bool> deleteRoute(String tripId, {required bool userConfirmed}) =>
      _enqueue(() async {
        if (!userConfirmed) return false;
        final keys = _routeEntries(tripId).map((entry) => entry.key).toList()
          ..add('$_metaPrefix$tripId');
        if (_box == null) {
          for (final key in keys) {
            _memory.remove(key);
          }
        } else {
          await _box.deleteAll(keys);
        }
        return true;
      });

  _RouteMeta? _metaFor(String tripId) {
    final value = _read('$_metaPrefix$tripId');
    return value is Map ? _RouteMeta.tryFromMap(value) : null;
  }

  TripRouteHistorySegment? _segmentFor(String tripId, int index) {
    final value = _read(_segmentKey(tripId, index));
    return value is Map ? TripRouteHistorySegment.tryFromMap(value) : null;
  }

  List<MapEntry<String, Object?>> _routeEntries(String tripId) {
    final prefix = '$_routePrefix$tripId:';
    final entries = _box == null
        ? _memory.entries
              .where((entry) => entry.key.startsWith(prefix))
              .toList()
        : _box.keys
              .whereType<String>()
              .where((key) => key.startsWith(prefix))
              .map((key) => MapEntry(key, _box.get(key)))
              .toList();
    entries.sort((a, b) => a.key.compareTo(b.key));
    return entries;
  }

  Object? _read(String key) => _box == null ? _memory[key] : _box.get(key);

  Future<void> _writeAll(Map<String, Object?> values) async {
    if (_box == null) {
      _memory.addAll(values);
    } else {
      await _box.putAll(values);
    }
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final next = _writeTail.then((_) => operation());
    _writeTail = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }
}

class _RouteMeta {
  const _RouteMeta({
    required this.pointCount,
    required this.segmentCount,
    required this.lastSegmentIndex,
    required this.lastSequence,
    required this.lastPointAtUtc,
  });

  final int pointCount;
  final int segmentCount;
  final int lastSegmentIndex;
  final int lastSequence;
  final DateTime lastPointAtUtc;

  Map<String, Object?> toMap() => {
    'schemaVersion': 1,
    'pointCount': pointCount,
    'segmentCount': segmentCount,
    'lastSegmentIndex': lastSegmentIndex,
    'lastSequence': lastSequence,
    'lastPointAtUtc': lastPointAtUtc.toIso8601String(),
  };

  static _RouteMeta? tryFromMap(Map<dynamic, dynamic> map) {
    final pointCount = map['pointCount'];
    final segmentCount = map['segmentCount'];
    final lastSegmentIndex = map['lastSegmentIndex'];
    final lastSequence = map['lastSequence'];
    final lastAt = DateTime.tryParse('${map['lastPointAtUtc'] ?? ''}');
    if (map['schemaVersion'] != 1 ||
        pointCount is! int ||
        pointCount < 0 ||
        segmentCount is! int ||
        segmentCount < 0 ||
        lastSegmentIndex is! int ||
        lastSegmentIndex < 0 ||
        lastSequence is! int ||
        lastSequence < 0 ||
        lastAt == null) {
      return null;
    }
    return _RouteMeta(
      pointCount: pointCount,
      segmentCount: segmentCount,
      lastSegmentIndex: lastSegmentIndex,
      lastSequence: lastSequence,
      lastPointAtUtc: lastAt.toUtc(),
    );
  }
}

String _segmentKey(String tripId, int index) =>
    'route:$tripId:${index.toString().padLeft(8, '0')}';

bool _safeDayKey(String value) =>
    RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value);

int _safeCount(Object? value) =>
    value is int && value >= 0 && value <= 1000000 ? value : 0;
