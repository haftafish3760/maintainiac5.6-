// odometerIsGlobalTruth: true.
import 'dart:math' as math;

import 'package:hive_flutter/hive_flutter.dart';

import 'trip_tracking_map_route_point_payload_policy.dart';
import 'trip_tracking_map_storage_policy.dart';
import 'trip_tracking_settings_store.dart';

class TripTrackingRoutePointWriteResult {
  const TripTrackingRoutePointWriteResult({
    required this.saved,
    required this.reasonCode,
    required this.persistedPointsForDay,
  });

  final bool saved;
  final String reasonCode;
  final int persistedPointsForDay;

  bool get gpsTrackingMayContinue => true;
  bool get canChangeOdometer => false;
  bool get canUploadRawPointToFirestore => false;
}

/// Optional local route history. It is not used by distance calculation,
/// odometer confirmation, TripLog creation, or cloud synchronization.
class TripTrackingRoutePointStore {
  TripTrackingRoutePointStore._(this._box) : _available = true;
  TripTrackingRoutePointStore.memory() : _box = null, _available = true;
  TripTrackingRoutePointStore.unavailable() : _box = null, _available = false;

  static const boxName = 'gps_trip_tracking_compact_route_points';
  static const compactEncodingVersion = 2;

  final Box<dynamic>? _box;
  final bool _available;
  final Map<String, Object?> _memory = {};
  Future<void> _writeTail = Future<void>.value();

  static Future<TripTrackingRoutePointStore> create() async =>
      TripTrackingRoutePointStore._(await Hive.openBox<dynamic>(boxName));

  Future<TripTrackingRoutePointWriteResult> persist({
    required Map<dynamic, dynamic> payload,
    required String expectedTripId,
    required String localDayKey,
    required DateTime nowUtc,
    required TripTrackingSettings settings,
  }) => _enqueue(() async {
    if (!_available) {
      return const TripTrackingRoutePointWriteResult(
        saved: false,
        reasonCode: 'local_route_storage_unavailable',
        persistedPointsForDay: 0,
      );
    }
    final safeDayKey = _safeDayKey(localDayKey);
    if (safeDayKey == null) {
      return const TripTrackingRoutePointWriteResult(
        saved: false,
        reasonCode: 'invalid_local_day_key',
        persistedPointsForDay: 0,
      );
    }
    final lastSequence = _readInt(_lastSequenceKey(expectedTripId));
    final payloadDecision = TripTrackingMapRoutePointPayloadPolicy.validate(
      payload: payload,
      expectedTripId: expectedTripId,
      nowUtc: nowUtc.toUtc(),
      lastPersistedSequence: lastSequence,
    );
    final dayCountKey = _dayCountKey(safeDayKey);
    final persistedToday = _readInt(dayCountKey) ?? 0;
    if (!payloadDecision.accepted) {
      return TripTrackingRoutePointWriteResult(
        saved: false,
        reasonCode: payloadDecision.reasonCode,
        persistedPointsForDay: persistedToday,
      );
    }
    final budget = TripTrackingMapStoragePolicy.canPersistNextRoutePoint(
      settings: settings,
      persistedPointsToday: persistedToday,
    );
    if (!budget.allowedToPersistPoint) {
      return TripTrackingRoutePointWriteResult(
        saved: false,
        reasonCode: budget.reasonCode,
        persistedPointsForDay: persistedToday,
      );
    }
    final point = <String, Object?>{
      'v': compactEncodingVersion,
      't': expectedTripId,
      'q': payloadDecision.sequence,
      's': payloadDecision.source,
      'e': DateTime.parse(
        '${payload['recordedAt']}',
      ).toUtc().millisecondsSinceEpoch,
      'a': ((payload['latitude'] as num).toDouble() * 1000000).round(),
      'o': ((payload['longitude'] as num).toDouble() * 1000000).round(),
      'h': ((payload['horizontalAccuracyMeters'] as num).toDouble() * 10)
          .round(),
    };
    final updates = <String, Object?>{
      _pointKey(safeDayKey, expectedTripId, payloadDecision.sequence): point,
      _lastSequenceKey(expectedTripId): payloadDecision.sequence,
      dayCountKey: persistedToday + 1,
    };
    if (_box == null) {
      _memory.addAll(updates);
    } else {
      await _box.putAll(updates);
    }
    return TripTrackingRoutePointWriteResult(
      saved: true,
      reasonCode: 'route_point_saved_locally',
      persistedPointsForDay: persistedToday + 1,
    );
  });

  List<Map<String, Object?>> pointsForTrip(String tripId) {
    if (!_available) return const [];
    final values = _box == null ? _memory.values : _box.values;
    final points =
        values
            .whereType<Map>()
            .map(_decodeRoutePoint)
            .whereType<Map<String, Object?>>()
            .where((value) => value['tripId'] == tripId)
            .toList(growable: false)
          ..sort(
            (a, b) => (a['sequence'] as int).compareTo(b['sequence'] as int),
          );
    return List.unmodifiable(points);
  }

  int? _readInt(String key) {
    final value = _box == null ? _memory[key] : _box.get(key);
    return value is int && value >= 0 ? value : null;
  }

  int nextSequenceForTrip(String tripId) =>
      _available ? (_readInt(_lastSequenceKey(tripId)) ?? -1) + 1 : 0;

  /// Route history is optional private data and can only be erased after an
  /// explicit user confirmation. Trip mileage and reviews are not stored here.
  Future<bool> deleteRoute(String tripId, {required bool userConfirmed}) =>
      _enqueue(() async {
        if (!_available) return false;
        if (!userConfirmed) return false;
        final pointKeys = <String>[];
        final removedByDay = <String, int>{};
        for (final key in _keys.whereType<String>()) {
          if (!key.startsWith('point:')) continue;
          final value = _read(key);
          if (value is! Map || _decodeRoutePoint(value)?['tripId'] != tripId) {
            continue;
          }
          pointKeys.add(key);
          final day = _dayFromPointKey(key);
          if (day != null) {
            removedByDay.update(day, (count) => count + 1, ifAbsent: () => 1);
          }
        }
        final keysToDelete = <String>[...pointKeys, _lastSequenceKey(tripId)];
        if (_box == null) {
          for (final key in keysToDelete) {
            _memory.remove(key);
          }
        } else {
          await _box.deleteAll(keysToDelete);
        }
        final countUpdates = <String, int>{};
        for (final entry in removedByDay.entries) {
          final countKey = _dayCountKey(entry.key);
          final current = _readInt(countKey) ?? 0;
          countUpdates[countKey] = math.max(0, current - entry.value);
        }
        if (_box == null) {
          _memory.addAll(countUpdates);
        } else if (countUpdates.isNotEmpty) {
          await _box.putAll(countUpdates);
        }
        return true;
      });

  Iterable<dynamic> get _keys => _box == null ? _memory.keys : _box.keys;

  Object? _read(String key) => _box == null ? _memory[key] : _box.get(key);

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final next = _writeTail.then((_) => operation());
    _writeTail = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }
}

String tripTrackingLocalDayKey(DateTime instant) {
  final local = instant.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}

Map<String, Object?>? _decodeRoutePoint(Map<dynamic, dynamic> value) {
  if (value['v'] == TripTrackingRoutePointStore.compactEncodingVersion) {
    final epoch = value['e'];
    final latitude = value['a'];
    final longitude = value['o'];
    final accuracy = value['h'];
    final sequence = value['q'];
    if (epoch is! int ||
        latitude is! int ||
        longitude is! int ||
        accuracy is! int ||
        sequence is! int ||
        value['t'] is! String ||
        value['s'] is! String) {
      return null;
    }
    return {
      'schemaVersion': 1,
      'tripId': value['t'],
      'sequence': sequence,
      'source': value['s'],
      'recordedAt': DateTime.fromMillisecondsSinceEpoch(
        epoch,
        isUtc: true,
      ).toIso8601String(),
      'latitude': latitude / 1000000,
      'longitude': longitude / 1000000,
      'horizontalAccuracyMeters': accuracy / 10,
    };
  }
  if (value['schemaVersion'] == 1 &&
      value['tripId'] is String &&
      value['sequence'] is int) {
    return Map<String, Object?>.fromEntries(
      value.entries.map((entry) => MapEntry('${entry.key}', entry.value)),
    );
  }
  return null;
}

String? _safeDayKey(String value) =>
    RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value) ? value : null;

String _pointKey(String day, String tripId, int sequence) =>
    'point:$day:$tripId:$sequence';
String _dayCountKey(String day) => 'count:$day';
String _lastSequenceKey(String tripId) => 'last:$tripId';

String? _dayFromPointKey(String key) {
  if (key.length < 17 || !key.startsWith('point:') || key[16] != ':') {
    return null;
  }
  return _safeDayKey(key.substring(6, 16));
}
