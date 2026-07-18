import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_stop_debounce_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_stop_debounce_summary_validation.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';

void main() {
  final observedAt = DateTime.utc(2026, 7, 18, 16);

  TripStopDebounceObservation observation({
    TripMotionState motionState = TripMotionState.stopCandidate,
    Duration stationaryDuration = const Duration(minutes: 2),
    int walkingEvidenceCount = 5,
    Duration walkingEvidenceSpan = const Duration(seconds: 35),
    int rejectedDriftCount = 0,
    int rejectedUnsafeCount = 0,
    int acceptedDistanceCount = 8,
    bool acceptedVehicleMovementObserved = true,
    double speedMps = 0.2,
    double horizontalAccuracyMeters = 10,
  }) {
    return TripStopDebounceObservation(
      motionState: motionState,
      stationaryDuration: stationaryDuration,
      walkingEvidenceCount: walkingEvidenceCount,
      walkingEvidenceSpan: walkingEvidenceSpan,
      rejectedDriftCount: rejectedDriftCount,
      rejectedUnsafeCount: rejectedUnsafeCount,
      acceptedDistanceCount: acceptedDistanceCount,
      acceptedVehicleMovementObserved: acceptedVehicleMovementObserved,
      speedMps: speedMps,
      horizontalAccuracyMeters: horizontalAccuracyMeters,
      observedAt: observedAt,
      latestWalkingEvidenceAt: observedAt.subtract(const Duration(seconds: 20)),
    );
  }

  Map<String, Object?> safeDebounceSummary() => TripStopDebouncePolicy.evaluate(
    profile: TripTrackingProfile.deliveryVehicle,
    observation: observation(),
  ).toSafeDashboardMap();

  test('valid stop debounce summary remains renderable and advisory only', () {
    final validation = TripStopDebounceSummaryValidation.fromDashboardMap(
      safeDebounceSummary(),
    );

    expect(validation.isRenderable, isTrue);
    expect(validation.status, TripStopDebounceStatus.readyForReview);
    expect(validation.reasonCode, 'walking_stop_debounce_ready');
    expect(validation.reasons, isEmpty);
  });

  test('mapbox, remote, and dashboard cache stop authority fails closed', () {
    final summary = safeDebounceSummary()
      ..addAll({
        'mapboxCanCreateStop': true,
        'mapboxCanConfirmStop': true,
        'mapboxDirectionsCanConfirmStop': true,
        'mapboxMatrixCanConfirmStop': true,
        'mapboxMapMatchingCanReplaceMileage': true,
        'mapboxOptimizationCanCreateStopOrder': true,
        'mapboxTrafficSignalCanCreateStop': true,
        'mapboxGeocodeCanConfirmStopAddress': true,
        'firestoreCanCreateStop': true,
        'cloudFunctionCanCreateStop': true,
        'remoteDebounceCanOverrideLocalTrip': true,
        'remoteDebounceCanOpenReview': true,
        'remoteDebounceCanEndTrip': true,
        'importedDebounceCanOpenReview': true,
        'dashboardCacheCanOpenReview': true,
      });
    final validation = TripStopDebounceSummaryValidation.fromDashboardMap(
      summary,
    );

    expect(validation.isRenderable, isFalse);
    expect(
      validation.reasons,
      containsAll([
        'mapbox_can_control_stop_debounce',
        'remote_debounce_can_control_trip',
      ]),
    );
  });

  test('malformed schema, enums, and user-action gates are rejected', () {
    final summary = safeDebounceSummary()
      ..addAll({
        'schemaVersion': 99,
        'status': 'forceStop',
        'reasonCode': 'private_address_stop',
        'gpsAssistedOnly': false,
        'authenticatedUserStillNeedsAuthorization': false,
        'localTripLogRequiredForReview': false,
        'malformedStopDebounceObservationFailsClosed': false,
        'stopReviewCannotCommitWithoutUserAction': false,
        'stopReviewRequiredForOfficialStop': false,
        'walkingEvidenceCanOnlySuggestReview': false,
        'walkingEvidenceRequiresCurrentDeviceSensor': false,
        'walkingEvidenceCannotBeReplayedFromCloud': false,
        'walkingEvidenceCannotCommitStop': false,
        'vehicleOnlyDwellCanOnlySuggestManualFallback': false,
        'vehicleOnlyDwellCannotInferAddress': false,
        'longStoplightCannotCreateOfficialStop': false,
        'gridlockCannotCreateOfficialStop': false,
        'twoPersonDeliveryRequiresManualConfirmation': false,
        'driverProfileThresholdsAreLocalPolicy': false,
        'activityRecognitionCanCreateOfficialStop': true,
        'vehicleOnlyDwellCanCreateOfficialStop': true,
        'stopEvidenceCanCreateCalibration': true,
        'walkingEvidenceCanCreateCalibration': true,
        'trafficControlCanCreateCalibration': true,
        'stopEvidenceCanSetGlobalTruth': true,
        'stopEvidenceCanConfirmOfficialMileage': true,
        'stopEvidenceCanChangeOfficialMileage': true,
        'walkingEvidenceCanConfirmOfficialMileage': true,
        'trafficControlCanConfirmOfficialMileage': true,
        'calibrationRequiresTrustedGpsWindow': false,
        'poorGpsDaysExcludedFromCalibration': false,
        'odometerRemainsOfficialMileageTruth': false,
      });
    final validation = TripStopDebounceSummaryValidation.fromDashboardMap(
      summary,
    );

    expect(validation.isRenderable, isFalse);
    expect(
      validation.reasons,
      containsAll([
        'unsupported_schema_version',
        'invalid_debounce_status',
        'invalid_debounce_reason',
        'debounce_not_gps_assisted',
        'authentication_treated_as_authorization',
        'local_trip_log_not_required_for_review',
        'malformed_debounce_not_fail_closed',
        'stop_review_not_user_action_gated',
        'advisory_evidence_can_create_stop',
        'stop_evidence_can_create_calibration',
        'walking_evidence_not_advisory_only',
        'vehicle_only_dwell_not_manual_only',
        'odometer_not_official_truth',
      ]),
    );
  });

  test('classification and evidence digest are independently validated', () {
    final summary = safeDebounceSummary();
    final classification = Map<String, Object?>.from(
      summary['classification'] as Map<String, Object?>,
    )..addAll({'canCreateOfficialStop': true});
    final evidenceDigest =
        Map<String, Object?>.from(
          summary['evidenceDigest'] as Map<String, Object?>,
        )..addAll({
          'acceptedDistanceCount': -1,
          'rejectedDriftCount': 100001,
          'rejectedUnsafeCount': 'many',
          'walkingEvidenceCount': 4.5,
          'providerValuesUsable': 'yes',
          'coordinatesIncluded': true,
        });
    final validation = TripStopDebounceSummaryValidation.fromDashboardMap({
      ...summary,
      'classification': classification,
      'evidenceDigest': evidenceDigest,
    });

    expect(validation.isRenderable, isFalse);
    expect(validation.reasons, contains('invalid_classification_boundary'));
    expect(validation.reasons, contains('invalid_acceptedDistanceCount'));
    expect(validation.reasons, contains('invalid_rejectedDriftCount'));
    expect(validation.reasons, contains('invalid_rejectedUnsafeCount'));
    expect(validation.reasons, contains('invalid_walkingEvidenceCount'));
    expect(validation.reasons, contains('invalid_evidence_boolean'));
    expect(
      validation.reasons,
      contains('evidence_digest_contains_sensitive_route_material'),
    );
  });

  test('forged debounce review authority fails closed', () {
    final validation = TripStopDebounceSummaryValidation.fromDashboardMap(
      safeDebounceSummary()..addAll({
        'status': TripStopDebounceStatus.trafficControlProtected.name,
        'reasonCode': 'traffic_control_debounce_protected',
        'canOpenReview': true,
        'needsWalkingReview': true,
        'protectedTrafficControl': false,
        'shouldContinueSampling': false,
      }),
    );

    expect(validation.isRenderable, isFalse);
    expect(
      validation.reasons,
      containsAll([
        'debounce_open_review_authority_mismatch',
        'traffic_control_debounce_authority_mismatch',
      ]),
    );
  });

  test(
    'tokens and precise coordinate strings cannot render in debounce cards',
    () {
      final validation = TripStopDebounceSummaryValidation.fromDashboardMap(
        safeDebounceSummary()..addAll({
          'dashboardCopy': 'Stopped near 35.123456,-80.987654',
          'tokenHint': 'sk.download-token',
        }),
      );

      expect(validation.isRenderable, isFalse);
      expect(validation.reasons, contains('debounce_contains_sensitive_text'));
    },
  );
}
