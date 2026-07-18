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
    'source': 'native_location',
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
    expect(summary['sourceVerified'], isTrue);
    expect(summary['simulatorHarnessVerified'], isFalse);
    expect(summary['nativeLocationSourceRequired'], isTrue);
    expect(summary['simulatorSampleRequiresExplicitTestHarness'], isTrue);
    expect(summary['simulatorHarnessCanFeedTripEngine'], isFalse);
    expect(summary['simulatorHarnessCannotWriteProductionHistory'], isTrue);
    expect(summary['remoteSampleCanMasqueradeAsNative'], isFalse);
    expect(summary['sampleCanSetGlobalTruth'], isFalse);
    expect(summary['sampleCanConfirmOfficialMileage'], isFalse);
    expect(summary['sampleCanChangeOfficialMileage'], isFalse);
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

  test('remote or Mapbox source cannot feed native trip engine', () {
    for (final source in const [
      'firestore_mirror',
      'mapbox_map_matching',
      'cloud_function',
      'imported_file',
    ]) {
      final badPayload = payload()..['source'] = source;
      final decision = TripLocationSampleIntakeGuard.evaluate(
        payload: badPayload,
        expectedOwnerUid: 'driver-1',
        expectedSessionId: 'trip-1',
        receivedAt: receivedAt,
      );

      expect(decision.status, TripLocationSampleIntakeStatus.rejected);
      expect(decision.reason, TripLocationSampleIntakeReason.sourceMismatch);
      expect(decision.canFeedTripEngine, isFalse);
      expect(decision.toSafeSummary()['sourceVerified'], isFalse);
    }
  });

  test('simulated trip samples require explicit test harness opt-in', () {
    final blocked = TripLocationSampleIntakeGuard.evaluate(
      payload: payload()..['source'] = 'simulated_native_location',
      expectedOwnerUid: 'driver-1',
      expectedSessionId: 'trip-1',
      receivedAt: receivedAt,
    );
    final accepted = TripLocationSampleIntakeGuard.evaluate(
      payload: payload()..['source'] = 'simulated_native_location',
      expectedOwnerUid: 'driver-1',
      expectedSessionId: 'trip-1',
      receivedAt: receivedAt,
      allowExplicitSimulatorHarness: true,
    );
    final summary = accepted.toSafeSummary();
    final validation = TripLocationSampleIntakeSummaryValidation.fromSummary(
      summary,
    );

    expect(blocked.status, TripLocationSampleIntakeStatus.rejected);
    expect(
      blocked.reason,
      TripLocationSampleIntakeReason.simulatorHarnessRequired,
    );
    expect(blocked.canFeedTripEngine, isFalse);
    expect(accepted.status, TripLocationSampleIntakeStatus.accepted);
    expect(accepted.canFeedTripEngine, isTrue);
    expect(summary['simulatorHarnessVerified'], isTrue);
    expect(summary['simulatorHarnessCanFeedTripEngine'], isTrue);
    expect(summary['simulatorHarnessCannotWriteProductionHistory'], isTrue);
    expect(validation.isRenderable, isTrue);
  });

  test('forged native payloads with remote authority are rejected', () {
    final decision = TripLocationSampleIntakeGuard.evaluate(
      payload: payload()
        ..addAll({
          'remoteSampleCanOverrideLocalTruth': true,
          'firestoreCanCreateOfficialStop': true,
          'cloudFunctionCanConfirmMileage': true,
          'mapboxMapMatchingCanReplaceSample': true,
        }),
      expectedOwnerUid: 'driver-1',
      expectedSessionId: 'trip-1',
      receivedAt: receivedAt,
    );

    expect(decision.status, TripLocationSampleIntakeStatus.rejected);
    expect(
      decision.reason,
      TripLocationSampleIntakeReason.remoteAuthorityRejected,
    );
    expect(decision.canFeedTripEngine, isFalse);
    expect(decision.toSafeSummary()['canFeedTripEngine'], isFalse);
  });

  test('remote authority claims fail closed even when not boolean true', () {
    for (final claim in const [
      {'mapboxCanRepairRejectedSample': 'true'},
      {'firestoreCanCreateOfficialStop': 1},
      {
        'nested': {'cloudFunctionCanConfirmMileage': 'yes'},
      },
    ]) {
      final decision = TripLocationSampleIntakeGuard.evaluate(
        payload: payload()..addAll(claim),
        expectedOwnerUid: 'driver-1',
        expectedSessionId: 'trip-1',
        receivedAt: receivedAt,
      );

      expect(decision.status, TripLocationSampleIntakeStatus.rejected);
      expect(
        decision.reason,
        TripLocationSampleIntakeReason.remoteAuthorityRejected,
      );
      expect(decision.canFeedTripEngine, isFalse);
    }
  });

  test('native payloads carrying token or coordinate strings are rejected', () {
    final token = TripLocationSampleIntakeGuard.evaluate(
      payload: payload()..addAll({'diagnosticToken': 'pk.redacted'}),
      expectedOwnerUid: 'driver-1',
      expectedSessionId: 'trip-1',
      receivedAt: receivedAt,
    );
    final coordinateText = TripLocationSampleIntakeGuard.evaluate(
      payload: payload(
        sample: {
          'latitude': 35.123456,
          'longitude': -80.123456,
          'recordedAt': receivedAt.subtract(const Duration(seconds: 8)),
          'horizontalAccuracyMeters': 8,
          'debugText': 'near 35.123456,-80.123456',
        },
      ),
      expectedOwnerUid: 'driver-1',
      expectedSessionId: 'trip-1',
      receivedAt: receivedAt,
    );

    expect(token.status, TripLocationSampleIntakeStatus.rejected);
    expect(
      token.reason,
      TripLocationSampleIntakeReason.sensitivePayloadRejected,
    );
    expect(coordinateText.status, TripLocationSampleIntakeStatus.rejected);
    expect(
      coordinateText.reason,
      TripLocationSampleIntakeReason.sensitivePayloadRejected,
    );
  });

  test('malformed intake time windows fall back to safe defaults', () {
    final accepted = TripLocationSampleIntakeGuard.evaluate(
      payload: payload(
        sample: {
          'latitude': 35.123456,
          'longitude': -80.123456,
          'recordedAt': receivedAt.add(const Duration(seconds: 30)),
          'horizontalAccuracyMeters': 8,
        },
      ),
      expectedOwnerUid: 'driver-1',
      expectedSessionId: 'trip-1',
      receivedAt: receivedAt,
      maximumFutureSkew: Duration.zero,
      maximumStaleAge: Duration.zero,
    );
    final future = TripLocationSampleIntakeGuard.evaluate(
      payload: payload(
        sample: {
          'latitude': 35.123456,
          'longitude': -80.123456,
          'recordedAt': receivedAt.add(const Duration(minutes: 3)),
          'horizontalAccuracyMeters': 8,
        },
      ),
      expectedOwnerUid: 'driver-1',
      expectedSessionId: 'trip-1',
      receivedAt: receivedAt,
      maximumFutureSkew: Duration.zero,
    );

    expect(accepted.status, TripLocationSampleIntakeStatus.accepted);
    expect(future.status, TripLocationSampleIntakeStatus.rejected);
    expect(future.reason, TripLocationSampleIntakeReason.futureTimestamp);
  });

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
            'sourceVerified': false,
            'simulatorHarnessVerified': true,
            'simulatorHarnessCanFeedTripEngine': false,
            'simulatorHarnessCannotWriteProductionHistory': false,
            'validatedBeforeUse': false,
            'authDoesNotImplyAuthorization': false,
            'authenticatedUserStillNeedsAuthorization': false,
            'hiveRemainsOperationalSourceOfTruth': false,
            'firestoreMirrorOnly': false,
            'remoteSampleCanOverrideLocalTruth': true,
            'remoteSampleCanMasqueradeAsNative': true,
            'sampleCanCreateOfficialStop': true,
            'sampleCanConfirmMileage': true,
            'sampleCanSetGlobalTruth': true,
            'sampleCanConfirmOfficialMileage': true,
            'sampleCanChangeOfficialMileage': true,
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
          'simulator_harness_claim_inconsistent',
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
