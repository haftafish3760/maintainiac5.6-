import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_location_sample_intake_guard.dart';

void main() {
  final receivedAt = DateTime.utc(2026, 7, 18, 12);

  test(
    'accepts complete local native sample for the current owner session',
    () {
      final decision = evaluate(sample(recordedAt: receivedAt));
      final safe = decision.toSafeSummary();

      expect(decision.canFeedTripEngine, isTrue);
      expect(
        decision.reason,
        TripLocationSampleIntakeReason.acceptedNativeSample,
      );
      expect(decision.sample, isNotNull);
      expect(safe['validatedBeforeUse'], isTrue);
      expect(safe['hiveRemainsOperationalSourceOfTruth'], isTrue);
      expect(safe['firestoreMirrorOnly'], isTrue);
    },
  );

  test('rejects non-map, bad schema, owner mismatch, and session mismatch', () {
    final notMap = evaluate('not a sample');
    final badSchema = evaluate({
      ...payload(sample(recordedAt: receivedAt)),
      'schemaVersion': 2,
    });
    final wrongOwner = evaluate({
      ...payload(sample(recordedAt: receivedAt)),
      'ownerUid': 'other-user',
    });
    final wrongSession = evaluate({
      ...payload(sample(recordedAt: receivedAt)),
      'sessionId': 'other-session',
    });

    expect(notMap.reason, TripLocationSampleIntakeReason.payloadNotMap);
    expect(
      badSchema.reason,
      TripLocationSampleIntakeReason.schemaVersionUnsupported,
    );
    expect(wrongOwner.reason, TripLocationSampleIntakeReason.ownerMismatch);
    expect(wrongSession.reason, TripLocationSampleIntakeReason.sessionMismatch);
    expect(wrongOwner.toSafeSummary()['authDoesNotImplyAuthorization'], isTrue);
  });

  test(
    'rejects missing fields, invalid coordinates, accuracy, and timestamps',
    () {
      final missing = evaluate(sample(remove: 'latitude'));
      final badCoordinate = evaluate(sample(latitude: 95));
      final badAccuracy = evaluate(sample(accuracy: 20000));
      final badTimestamp = evaluate(sample(recordedAtRaw: 'not-a-date'));

      expect(
        missing.reason,
        TripLocationSampleIntakeReason.missingRequiredFields,
      );
      expect(
        badCoordinate.reason,
        TripLocationSampleIntakeReason.invalidCoordinate,
      );
      expect(
        badAccuracy.reason,
        TripLocationSampleIntakeReason.invalidAccuracy,
      );
      expect(
        badTimestamp.reason,
        TripLocationSampleIntakeReason.invalidTimestamp,
      );
    },
  );

  test('rejects future, stale, mock, and impossible speed samples', () {
    final future = evaluate(
      sample(recordedAt: receivedAt.add(const Duration(minutes: 3))),
    );
    final stale = evaluate(
      sample(recordedAt: receivedAt.subtract(const Duration(hours: 19))),
    );
    final mock = evaluate(sample(mockedLocation: true));
    final invalidSpeed = evaluate(sample(speed: -2));
    final tooFast = evaluate(sample(speed: 71));

    expect(future.reason, TripLocationSampleIntakeReason.futureTimestamp);
    expect(stale.reason, TripLocationSampleIntakeReason.staleTimestamp);
    expect(mock.reason, TripLocationSampleIntakeReason.mockedLocationRejected);
    expect(
      invalidSpeed.reason,
      TripLocationSampleIntakeReason.invalidReportedSpeed,
    );
    expect(
      tooFast.reason,
      TripLocationSampleIntakeReason.impossibleReportedSpeed,
    );
  });

  test('rejects duplicate and out-of-order replayed samples', () {
    final latestAccepted = receivedAt.subtract(const Duration(seconds: 10));
    final duplicate = evaluate(
      sample(recordedAt: latestAccepted),
      latestAcceptedRecordedAt: latestAccepted,
    );
    final olderReplay = evaluate(
      sample(recordedAt: latestAccepted.subtract(const Duration(seconds: 1))),
      latestAcceptedRecordedAt: latestAccepted,
    );
    final nextSample = evaluate(
      sample(recordedAt: latestAccepted.add(const Duration(seconds: 1))),
      latestAcceptedRecordedAt: latestAccepted,
    );

    expect(duplicate.reason, TripLocationSampleIntakeReason.duplicateTimestamp);
    expect(
      olderReplay.reason,
      TripLocationSampleIntakeReason.outOfOrderTimestamp,
    );
    expect(nextSample.canFeedTripEngine, isTrue);
    expect(duplicate.toSafeSummary()['orderedAfterAcceptedSample'], isFalse);
    expect(
      olderReplay.toSafeSummary()['remoteSampleCanOverrideLocalTruth'],
      isFalse,
    );
  });

  test('safe summary never leaks coordinates, route geometry, or tokens', () {
    final safe = evaluate(
      sample(
        latitude: 35.123456,
        longitude: -80.987654,
        recordedAt: receivedAt,
      ),
    ).toSafeSummary();

    expect(safe['coordinatesIncluded'], isFalse);
    expect(safe['rawLocationIncluded'], isFalse);
    expect(safe['preciseTimestampIncluded'], isFalse);
    expect(safe['routeGeometryIncluded'], isFalse);
    expect(safe['tokensIncluded'], isFalse);
    expect(safe['sampleCanCreateOfficialStop'], isFalse);
    expect(safe['sampleCanConfirmMileage'], isFalse);
    expect(safe['odometerRemainsOfficialMileageTruth'], isTrue);
    expect(safe.toString(), isNot(contains('35.123456')));
    expect(safe.toString(), isNot(contains('pk.')));
    expect(safe.toString(), isNot(contains('sk.')));
  });
}

TripLocationSampleIntakeDecision evaluate(
  Object? payloadValue, {
  DateTime? latestAcceptedRecordedAt,
}) {
  final externalPayload =
      payloadValue is Map &&
          payloadValue.containsKey('schemaVersion') &&
          payloadValue.containsKey('sample')
      ? payloadValue
      : payloadValue is Map
      ? payload(payloadValue.cast<String, Object?>())
      : payloadValue;
  return TripLocationSampleIntakeGuard.evaluate(
    payload: externalPayload,
    expectedOwnerUid: 'user-1',
    expectedSessionId: 'session-1',
    receivedAt: DateTime.utc(2026, 7, 18, 12),
    latestAcceptedRecordedAt: latestAcceptedRecordedAt,
  );
}

Map<String, Object?> payload(Map<String, Object?> sample) => {
  'schemaVersion': 1,
  'ownerUid': 'user-1',
  'sessionId': 'session-1',
  'sample': sample,
};

Map<String, Object?> sample({
  double latitude = 35.0,
  double longitude = -80.0,
  double accuracy = 8,
  double? speed = 12,
  DateTime? recordedAt,
  Object? recordedAtRaw,
  bool? mockedLocation,
  String? remove,
}) {
  final map = <String, Object?>{
    'latitude': latitude,
    'longitude': longitude,
    'horizontalAccuracyMeters': accuracy,
    'recordedAt':
        recordedAtRaw ??
        (recordedAt ?? DateTime.utc(2026, 7, 18, 12)).toIso8601String(),
  };
  if (speed != null) map['speedMetersPerSecond'] = speed;
  if (mockedLocation != null) map['mockedLocation'] = mockedLocation;
  if (remove != null) map.remove(remove);
  return map;
}
