import 'dart:convert';

import '../records/maintainiac_durable_record_store.dart';
import 'trip_tracking_models.dart';
import 'trip_tracking_session_store.dart';

class TripTrackingDailyBundleBridge {
  const TripTrackingDailyBundleBridge(this.store);

  static const module = 'trip_tracking_day';
  static const maximumBundleBytes = 900000;
  static const maximumTripsPerDay = 5000;

  final MaintainiacDurableRecordStore store;

  Future<MaintainiacDurableRecord> upsertReviewedTrip(
    TripTrackingReviewRecord review, {
    DateTime? now,
  }) async {
    if (!review.isOdometerConfirmed || !review.hasValidTimeline) {
      throw ArgumentError('A daily trip bundle requires confirmed mileage.');
    }
    final dayId = dayIdFor(review);
    final existing = store.recordFor(module, dayId);
    final existingPayload = existing?.payload;
    if (existingPayload != null && !_isValidExistingBundle(existingPayload)) {
      throw StateError(
        'The saved daily trip bundle needs recovery before it can be updated.',
      );
    }
    final summaries = _existingTripSummaries(existingPayload)
      ..removeWhere((item) => item['tripId'] == review.id)
      ..add(_tripSummary(review));
    if (summaries.length > maximumTripsPerDay) {
      throw StateError('The daily trip bundle exceeds its safe record limit.');
    }
    summaries.sort(
      (a, b) => '${a['startedAtUtc']}'.compareTo('${b['startedAtUtc']}'),
    );
    final payload = _bundlePayload(
      dayId: dayId,
      summaries: summaries,
      startTimeZoneName: review.startedTimeZoneName,
      startTimeZoneOffsetMinutes: review.startedTimeZoneOffsetMinutes,
    );
    if (utf8.encode(jsonEncode(payload)).length > maximumBundleBytes) {
      throw StateError(
        'The daily trip bundle is too large to synchronize safely as one document.',
      );
    }
    return store.save(
      module: module,
      id: dayId,
      payload: payload,
      expectedRevision: existing?.lifecycle.revision,
      now: now,
    );
  }

  MaintainiacDurableRecord? bundleForDay(String dayId) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dayId)) return null;
    final record = store.recordFor(module, dayId);
    return record != null && _isValidExistingBundle(record.payload)
        ? record
        : null;
  }

  static String dayIdFor(TripTrackingReviewRecord review) {
    final localStart = review.startedAt.toUtc().add(
      Duration(minutes: review.startedTimeZoneOffsetMinutes),
    );
    return '${localStart.year.toString().padLeft(4, '0')}-'
        '${localStart.month.toString().padLeft(2, '0')}-'
        '${localStart.day.toString().padLeft(2, '0')}';
  }
}

List<Map<String, Object?>> _existingTripSummaries(
  Map<String, dynamic>? payload,
) {
  final trips = payload?['trips'];
  if (trips is! Iterable) return <Map<String, Object?>>[];
  return trips
      .whereType<Map>()
      .map((item) => Map<String, Object?>.from(item))
      .where((item) => _safeId(item['tripId']) != null)
      .toList(growable: true);
}

Map<String, Object?> _tripSummary(TripTrackingReviewRecord review) {
  final confirmedEnd = review.confirmedEndingOdometer!;
  final confirmedMiles = confirmedEnd - review.startingOdometer;
  final diagnostics = review.engineSnapshot.diagnostics;
  return {
    'tripId': review.id,
    'vehicleId': review.vehicleId,
    'profileId': review.profileId,
    'vehicleConfigurationRevision': review.vehicleConfigurationRevision,
    'trackingProfile': review.profile.name,
    'startedAtUtc': review.startedAt.toUtc().toIso8601String(),
    'finishedAtUtc': review.finishedAt.toUtc().toIso8601String(),
    'startedTimeZoneOffsetMinutes': review.startedTimeZoneOffsetMinutes,
    'startedTimeZoneName': review.startedTimeZoneName,
    'finishedTimeZoneOffsetMinutes': review.finishedTimeZoneOffsetMinutes,
    'finishedTimeZoneName': review.finishedTimeZoneName,
    'startingOdometer': review.startingOdometer,
    'confirmedEndingOdometer': confirmedEnd,
    'finalUserConfirmedMileage': confirmedMiles,
    'gpsAssistedDistanceMiles': _miles(
      review.engineSnapshot.totalAcceptedMeters,
    ),
    'estimatedGapDistanceMiles': _miles(diagnostics.estimatedGapDistanceMeters),
    'rejectedDistanceMiles': _miles(diagnostics.rejectedDistanceMeters),
    'events': review.advisories.map(_advisorySummary).toList(growable: false),
    'userEvents': review.userEvents
        .map((event) => event.toMap())
        .toList(growable: false),
    'odometerIsGlobalTruth': true,
    'gpsDistanceIsAdvisoryOnly': true,
  };
}

Map<String, Object?> _advisorySummary(TripTrackingAdvisoryEvent event) => {
  'eventId': event.id,
  'type': event.type.name,
  'detectedAtUtc': event.detectedAt.toUtc().toIso8601String(),
  'confidence': event.confidence.name,
  'disposition': event.disposition.name,
};

Map<String, dynamic> _bundlePayload({
  required String dayId,
  required List<Map<String, Object?>> summaries,
  required String startTimeZoneName,
  required int startTimeZoneOffsetMinutes,
}) {
  var confirmedMiles = 0;
  var gpsMiles = 0.0;
  var estimatedGapMiles = 0.0;
  var rejectedMiles = 0.0;
  var eventCount = 0;
  for (final trip in summaries) {
    confirmedMiles += trip['finalUserConfirmedMileage'] as int? ?? 0;
    gpsMiles += trip['gpsAssistedDistanceMiles'] as double? ?? 0;
    estimatedGapMiles += trip['estimatedGapDistanceMiles'] as double? ?? 0;
    rejectedMiles += trip['rejectedDistanceMiles'] as double? ?? 0;
    eventCount += (trip['events'] as List?)?.length ?? 0;
    eventCount += (trip['userEvents'] as List?)?.length ?? 0;
  }
  return {
    'schemaVersion': 1,
    'bundleType': 'trip_tracking_day',
    'localDay': dayId,
    'dayStartTimeZoneName': startTimeZoneName,
    'dayStartTimeZoneOffsetMinutes': startTimeZoneOffsetMinutes,
    'tripCount': summaries.length,
    'eventCount': eventCount,
    'confirmedMileage': confirmedMiles,
    'gpsAssistedDistanceMiles': _rounded(gpsMiles),
    'estimatedGapDistanceMiles': _rounded(estimatedGapMiles),
    'rejectedDistanceMiles': _rounded(rejectedMiles),
    'trips': summaries,
    'singleDocumentPerLocalDay': true,
    'crossMidnightTripAssignedToStartDay': true,
    'syncEligible': true,
    'hiveRemainsSourceOfTruth': true,
    'odometerIsGlobalTruth': true,
    'gpsDistanceIsAdvisoryOnly': true,
    'rawGpsIncluded': false,
    'coordinatesIncluded': false,
    'routeGeometryIncluded': false,
    'tokensIncluded': false,
  };
}

bool _isValidExistingBundle(Map<String, dynamic> payload) =>
    payload['schemaVersion'] == 1 &&
    payload['bundleType'] == 'trip_tracking_day' &&
    payload['singleDocumentPerLocalDay'] == true &&
    payload['hiveRemainsSourceOfTruth'] == true &&
    payload['odometerIsGlobalTruth'] == true &&
    payload['rawGpsIncluded'] == false &&
    payload['coordinatesIncluded'] == false &&
    payload['routeGeometryIncluded'] == false &&
    payload['trips'] is Iterable;

String? _safeId(Object? value) {
  if (value is! String || value.isEmpty || value.length > 160) return null;
  return RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(value) ? value : null;
}

double _miles(double meters) =>
    !meters.isFinite || meters < 0 ? 0 : _rounded(meters / 1609.344);

double _rounded(double value) => double.parse(value.toStringAsFixed(3));
