import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_stop_classification.dart';
import 'package:maintaniac/shared/trip_tracking/trip_stop_summary_validation.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';

void main() {
  Map<String, Object?> safeDeliveryStopSummary() => TripStopClassifier.classify(
    profile: TripTrackingProfile.deliveryVehicle,
    motionState: TripMotionState.stopped,
    needsWalkingReview: true,
    excludedWalkingCount: 3,
    rejectedDriftCount: 0,
    rejectedUnsafeCount: 0,
    acceptedDistanceCount: 4,
  ).toSafeSummary();

  test('valid stop summary remains renderable but advisory only', () {
    final validation = TripStopSummaryValidation.fromSummary(
      safeDeliveryStopSummary(),
    );

    expect(validation.isRenderable, isTrue);
    expect(validation.signal, TripStopSignal.reviewOnlyStop);
    expect(validation.reasonCode, 'delivery_stop_walk_review');
    expect(validation.reasons, isEmpty);
  });

  test('remote stop payload cannot create official trip facts', () {
    final summary = safeDeliveryStopSummary()
      ..addAll({
        'remoteStopSummaryCanOverrideLocalTrip': true,
        'firestoreCanCreateOfficialStop': true,
        'cloudFunctionCanCreateOfficialStop': true,
        'activityRecognitionCanCreateOfficialStop': true,
        'canCreateOfficialStop': true,
        'canEndTripAutomatically': true,
        'canReplaceOdometer': true,
      });
    final validation = TripStopSummaryValidation.fromSummary(summary);

    expect(validation.isRenderable, isFalse);
    expect(validation.signal, isNull);
    expect(
      validation.reasons,
      containsAll([
        'activity_recognition_can_create_stop',
        'remote_summary_can_override_local_trip',
        'firestore_can_create_stop',
        'cloud_function_can_create_stop',
        'summary_can_mutate_trip_truth',
      ]),
    );
  });

  test('manual fallback policy must remain advisory and signal bounded', () {
    final summary = safeDeliveryStopSummary()
      ..addAll({
        'signal': 'unsafeEvidence',
        'shouldSurfaceManualStopFallback': true,
      });
    final validation = TripStopSummaryValidation.fromSummary(summary);

    expect(validation.isRenderable, isFalse);
    expect(
      validation.reasons,
      contains('manual_stop_fallback_on_unsafe_signal'),
    );
  });

  test(
    'mapbox and route material cannot ride through stop summary boundary',
    () {
      final summary = safeDeliveryStopSummary()
        ..addAll({
          'mapsRequiredForStopReview': true,
          'mapboxCanCreateStop': true,
          'mapboxCanEndTrip': true,
          'rawSamplesIncluded': true,
          'rawMotionPayloadIncluded': true,
          'coordinatesIncluded': true,
          'routeGeometryIncluded': true,
          'mapboxGeometryIncluded': true,
        });
      final validation = TripStopSummaryValidation.fromSummary(summary);

      expect(validation.isRenderable, isFalse);
      expect(
        validation.reasons,
        containsAll([
          'mapbox_can_control_stop_review',
          'summary_contains_sensitive_route_material',
        ]),
      );
    },
  );

  test('malformed stop summary schema and enums fail closed', () {
    final summary = safeDeliveryStopSummary()
      ..addAll({
        'schemaVersion': 2,
        'signal': 'forceStop',
        'reasonCode': 'private_address_stop',
        'reviewConfidence': 'certain',
        'officialStopSource': 'firestore',
        'officialMileageSource': 'gps',
      });
    final validation = TripStopSummaryValidation.fromSummary(summary);

    expect(validation.isRenderable, isFalse);
    expect(validation.signal, isNull);
    expect(validation.reasonCode, isNull);
    expect(
      validation.reasons,
      containsAll([
        'unsupported_schema_version',
        'invalid_stop_signal',
        'invalid_reason_code',
        'invalid_review_confidence',
        'official_stop_source_not_user_review',
        'official_mileage_source_not_odometer',
      ]),
    );
  });
}
