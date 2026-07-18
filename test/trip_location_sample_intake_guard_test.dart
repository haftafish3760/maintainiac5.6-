import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_location_sample_intake_guard.dart';

void main() {
  final receivedAt = DateTime.utc(2026, 7, 18, 20);

  Map<String, Object?> payload({
    Object? ownerUid = 'driver-1',
    Object? sessionId = 'trip-1',
    Object? schemaVersion = 1,
    Map<String, Object?>? sample,
  }) => {
    'schemaVersion': schemaVersion,
    'ownerUid': ownerUid,
    'sessionId': sessionId,
    'sample':
        sample ??
        {
          'latitude': 35.123456,
          'longitude': -80.123456,
          'recordedAt': receivedAt.subtract(const Duration(seconds: 8)),
          'horizontalAccuracyMeters': 8,
          'speedMetersPerSecond': 12,
        },
  };

  test('accepted native sample summary validates without leaking location', () {
    final decision = TripLocationSampleIntakeGuard.evaluate(
      payload: payload(),
      expectedOwnerUid: 'driver-1',
      expectedSessionId: 'trip-1',
      receivedAt: receivedAt,
    );
    final summary = decision.toSafeSummary();
    final validation = TripLocationSampleIntakeSummaryValidation.fromSummary(
      summary,
    );

    expect(decision.canFeedTripEngine, isTrue);
    expect(validation.isRenderable, isTrue);
    expect(validation.status, TripLocationSampleIntakeStatus.accepted);
    expect(
      validation.reason,
      TripLocationSampleIntakeReason.acceptedNativeSample,
    );
    expect(summary.toString(), isNot(contains('35.123456')));
    expect(summary.toString(), isNot(contains('-80.123456')));
  });

  test(
    'token-like owner or session identifiers are never treated as verified',
    () {
      final ownerToken = TripLocationSampleIntakeGuard.evaluate(
        payload: payload(ownerUid: 'pk.public-token'),
        expectedOwnerUid: 'pk.public-token',
        expectedSessionId: 'trip-1',
        receivedAt: receivedAt,
      );
      final sessionToken = TripLocationSampleIntakeGuard.evaluate(
        payload: payload(sessionId: 'sk.secret-token'),
        expectedOwnerUid: 'driver-1',
        expectedSessionId: 'sk.secret-token',
        receivedAt: receivedAt,
      );

      expect(ownerToken.status, TripLocationSampleIntakeStatus.rejected);
      expect(ownerToken.reason, TripLocationSampleIntakeReason.ownerMismatch);
      expect(ownerToken.toSafeSummary()['tokensIncluded'], isFalse);
      expect(sessionToken.status, TripLocationSampleIntakeStatus.rejected);
      expect(
        sessionToken.reason,
        TripLocationSampleIntakeReason.sessionMismatch,
      );
    },
  );

  test(
    'summary validation rejects remote authority and odometer truth claims',
    () {
      final summary =
          TripLocationSampleIntakeGuard.evaluate(
            payload: payload(),
            expectedOwnerUid: 'driver-1',
            expectedSessionId: 'trip-1',
            receivedAt: receivedAt,
          ).toSafeSummary()..addAll({
            'canFeedTripEngine': true,
            'ownerVerified': false,
            'sessionVerified': false,
            'validatedBeforeUse': false,
            'authDoesNotImplyAuthorization': false,
            'authenticatedUserStillNeedsAuthorization': false,
            'hiveRemainsOperationalSourceOfTruth': false,
            'firestoreMirrorOnly': false,
            'remoteSampleCanOverrideLocalTruth': true,
            'sampleCanCreateOfficialStop': true,
            'sampleCanConfirmMileage': true,
            'odometerRemainsOfficialMileageTruth': false,
            'mockLocationAccepted': true,
          });
      final validation = TripLocationSampleIntakeSummaryValidation.fromSummary(
        summary,
      );

      expect(validation.isRenderable, isFalse);
      expect(
        validation.reasons,
        containsAll([
          'unsafe_engine_feed_claim',
          'authorization_boundary_missing',
          'local_truth_boundary_missing',
          'sample_can_create_trip_truth',
        ]),
      );
    },
  );

  test('summary validation rejects Mapbox and sensitive material claims', () {
    final summary =
        TripLocationSampleIntakeGuard.evaluate(
          payload: payload(),
          expectedOwnerUid: 'driver-1',
          expectedSessionId: 'trip-1',
          receivedAt: receivedAt,
        ).toSafeSummary()..addAll({
          'mapboxResponsesTreatedAsExternalInput': false,
          'mapboxDirectionsCanSupplyOfficialSample': true,
          'mapboxMapMatchingCanReplaceSample': true,
          'mapboxOptimizationCanCreateMileage': true,
          'rawLocationIncluded': true,
          'coordinatesIncluded': true,
          'preciseTimestampIncluded': true,
          'routeGeometryIncluded': true,
          'tokensIncluded': true,
          'publicMapboxTokenIncluded': true,
          'secretMapboxTokenIncluded': true,
          'debugCoordinate': '35.123456,-80.123456',
        });
    final validation = TripLocationSampleIntakeSummaryValidation.fromSummary(
      summary,
    );

    expect(validation.isRenderable, isFalse);
    expect(validation.reasons, contains('mapbox_can_control_sample_truth'));
    expect(
      validation.reasons,
      contains('summary_contains_sensitive_trip_material'),
    );
    expect(validation.reasons, contains('summary_contains_sensitive_text'));
  });

  test('malformed summary shape fails closed', () {
    final validation = TripLocationSampleIntakeSummaryValidation.fromSummary({
      'schemaVersion': 2,
      'status': 'forceAccepted',
      'reason': 'privateReason',
      'payloadSchemaVersion': 'one',
      'malformedPayloadFailsClosed': false,
    });

    expect(validation.isRenderable, isFalse);
    expect(
      validation.reasons,
      containsAll([
        'unsupported_schema_version',
        'invalid_intake_status',
        'invalid_intake_reason',
        'invalid_payload_schema_version',
        'malformed_payload_not_fail_closed',
      ]),
    );
  });
}
