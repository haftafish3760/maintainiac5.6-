import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_engine.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_profile_strategy.dart';

void main() {
  final start = DateTime.utc(2026, 7, 17, 8);

  TripLocationSample sample(double longitude, int seconds) =>
      TripLocationSample(
        latitude: 35,
        longitude: longitude,
        recordedAt: start.add(Duration(seconds: seconds)),
        horizontalAccuracyMeters: 5,
        speedMetersPerSecond: 0,
      );

  TripActivityObservation walking(int seconds) => TripActivityObservation(
    activity: TripActivity.walking,
    confidence: 95,
    recordedAt: start.add(Duration(seconds: seconds)),
  );

  TripActivityObservation automotive(int seconds) => TripActivityObservation(
    activity: TripActivity.automotive,
    confidence: 95,
    recordedAt: start.add(Duration(seconds: seconds)),
  );

  test(
    'rideshare profile requires stronger walking evidence than delivery',
    () {
      final rideshare = TripTrackingProfileStrategy.forProfile(
        TripTrackingProfile.rideshareVehicle,
      );
      final delivery = TripTrackingProfileStrategy.forProfile(
        TripTrackingProfile.deliveryVehicle,
      );

      expect(
        rideshare.walkingConfirmationCount,
        greaterThan(delivery.walkingConfirmationCount),
      );
      expect(
        rideshare.walkingStopConfirmationDuration,
        greaterThan(delivery.walkingStopConfirmationDuration),
      );
      expect(rideshare.stopReviewReasonCode, contains('rideshare'));
      expect(rideshare.dashboardModeToken, 'gig_driver');
      expect(rideshare.driverKindToken, 'passenger_service');
      expect(rideshare.stopEvidenceTier, 'strong_debounce_review');
      expect(rideshare.recommendedActivityRecognition, isTrue);
      expect(rideshare.requiresStrongerStopDebounce, isTrue);
      expect(rideshare.stopDetectionSummary, contains('stays in the vehicle'));
    },
  );

  test('delivery walking stop evidence can identify a real stop quickly', () {
    final engine = TripTrackingEngine(
      profile: TripTrackingProfile.deliveryVehicle,
    );

    engine.ingest(sample(-80, 0), activity: automotive(0));
    engine.ingest(sample(-79.9997, 15), activity: automotive(15));
    engine.ingest(sample(-79.9997, 30), activity: walking(30));
    engine.ingest(sample(-79.9997, 45), activity: walking(45));
    engine.ingest(sample(-79.9997, 60), activity: walking(60));

    expect(engine.motionState, TripMotionState.stopped);
    expect(engine.needsWalkingReview, isTrue);
  });

  test(
    'rideshare does not treat a short passenger stop as a completed stop',
    () {
      final engine = TripTrackingEngine(
        profile: TripTrackingProfile.rideshareVehicle,
      );

      engine.ingest(sample(-80, 0), activity: automotive(0));
      engine.ingest(sample(-79.9997, 15), activity: automotive(15));
      engine.ingest(sample(-79.9997, 30), activity: walking(30));
      engine.ingest(sample(-79.9997, 45), activity: walking(45));
      engine.ingest(sample(-79.9997, 60), activity: walking(60));

      expect(engine.motionState, TripMotionState.stopCandidate);
      expect(engine.needsWalkingReview, isFalse);
    },
  );

  test('rideshare eventually accepts sustained walking stop evidence', () {
    final engine = TripTrackingEngine(
      profile: TripTrackingProfile.rideshareVehicle,
    );

    engine.ingest(sample(-80, 0), activity: automotive(0));
    engine.ingest(sample(-79.9997, 15), activity: automotive(15));
    engine.ingest(sample(-79.9997, 30), activity: walking(30));
    engine.ingest(sample(-79.9997, 45), activity: walking(45));
    engine.ingest(sample(-79.9997, 60), activity: walking(60));
    engine.ingest(sample(-79.9997, 75), activity: walking(75));

    expect(engine.motionState, TripMotionState.stopped);
    expect(engine.needsWalkingReview, isTrue);
  });

  test(
    'profile dashboard hints distinguish gig contractor and equipment modes',
    () {
      final delivery = TripTrackingProfileStrategy.forProfile(
        TripTrackingProfile.deliveryVehicle,
      );
      final contractor = TripTrackingProfileStrategy.forProfile(
        TripTrackingProfile.contractorVehicle,
      );
      final equipment = TripTrackingProfileStrategy.forProfile(
        TripTrackingProfile.lowSpeedEquipment,
      );

      expect(delivery.dashboardModeToken, 'gig_driver');
      expect(contractor.dashboardModeToken, 'contractor');
      expect(equipment.dashboardModeToken, 'default');
      expect(equipment.driverKindToken, 'equipment');
      expect(equipment.stopEvidenceTier, 'gps_only_review');
      expect(equipment.recommendedActivityRecognition, isFalse);
      expect(equipment.usesWalkingStopEvidence, isFalse);
    },
  );

  test(
    'rideshare dashboard defaults prioritize pay and miles over stop tools',
    () {
      final strategy = TripTrackingProfileStrategy.forProfile(
        TripTrackingProfile.rideshareVehicle,
      );

      expect(strategy.dashboardWidgetTokens, contains('pay'));
      expect(strategy.dashboardWidgetTokens, contains('miles'));
      expect(strategy.dashboardWidgetTokens, isNot(contains('stops')));
      expect(strategy.quickActionTokens, contains('add_pay'));
      expect(strategy.quickActionTokens, isNot(contains('add_dropoff')));
    },
  );

  test('delivery dashboard defaults include stop and earnings workflow', () {
    final strategy = TripTrackingProfileStrategy.forProfile(
      TripTrackingProfile.deliveryVehicle,
    );

    expect(strategy.dashboardWidgetTokens, contains('stops'));
    expect(strategy.dashboardWidgetTokens, contains('pay'));
    expect(strategy.dashboardWidgetTokens, contains('expenses'));
    expect(strategy.quickActionTokens, contains('add_pickup'));
    expect(strategy.quickActionTokens, contains('add_dropoff'));
    expect(strategy.quickActionTokens, contains('review_mileage'));
  });

  test('contractor dashboard defaults include jobs materials and payments', () {
    final strategy = TripTrackingProfileStrategy.forProfile(
      TripTrackingProfile.contractorVehicle,
    );

    expect(strategy.dashboardModeToken, 'contractor');
    expect(strategy.dashboardWidgetTokens, contains('jobs'));
    expect(strategy.dashboardWidgetTokens, contains('materials'));
    expect(strategy.dashboardWidgetTokens, contains('payments'));
    expect(strategy.quickActionTokens, contains('add_job'));
    expect(strategy.quickActionTokens, contains('record_payment'));
  });

  test('equipment dashboard defaults stay minimal and skip motion assist', () {
    final strategy = TripTrackingProfileStrategy.forProfile(
      TripTrackingProfile.lowSpeedEquipment,
    );

    expect(strategy.dashboardWidgetTokens, contains('maintenance'));
    expect(strategy.dashboardWidgetTokens, isNot(contains('pay')));
    expect(strategy.quickActionTokens, contains('maintenance_log'));
    expect(strategy.recommendedActivityRecognition, isFalse);
    expect(strategy.requiresStrongerStopDebounce, isFalse);
  });

  test('dashboard profile map is safe for dashboard summaries', () {
    final strategy = TripTrackingProfileStrategy.forProfile(
      TripTrackingProfile.contractorVehicle,
    );

    expect(strategy.toDashboardProfileMap(), {
      'schemaVersion': 1,
      'profile': 'contractorVehicle',
      'driverKind': 'contractor_or_jobsite',
      'workStyle': 'contractor',
      'dashboardMode': 'contractor',
      'stopDetectionMode': 'walking_assisted',
      'stopEvidenceTier': 'walking_assisted_review',
      'recommendedActivityRecognition': true,
      'usesWalkingStopEvidence': true,
      'requiresStrongerStopDebounce': false,
      'minimumWalkingEvidenceSpacingSeconds': 5,
      'phoneMayStayInVehicleDuringStops': false,
      'vehicleOnlyStopsNeedManualFallback': false,
      'stopReviewConfidencePolicy': 'walking_assist_jobsite_review',
      'stopReviewReasonCode': 'contractor_stop_walk_review',
      'dashboardWidgetTokens': [
        'start_day',
        'live_odometer',
        'jobs',
        'materials',
        'expenses',
        'payments',
        'miles',
      ],
      'quickActionTokens': [
        'add_stop',
        'add_job',
        'add_expense',
        'record_payment',
        'review_mileage',
      ],
      'walkingEvidenceCanOnlySuggestReview': true,
      'activityRecognitionRequiresOptIn': true,
      'activityRecognitionCanConfirmStopAutomatically': false,
      'vehicleOnlyStopsRequireReview': false,
      'longStoplightCanRequireReview': true,
      'gpsAssistedTrackingAvailableWithoutMaps': true,
      'mapsRequiredForTracking': false,
      'mapsCanOnlyAssistVisualization': true,
      'mapRouteOptimizationOptional': true,
      'mapboxCanConfirmStop': false,
      'mapboxCanReplaceGpsDistance': false,
      'odometerRemainsCanonical': true,
      'gpsDistanceCanOnlyAssistOdometerReview': true,
      'calibrationRequiresMultipleReviewedTrips': true,
      'calibrationCanAutoRewriteConfirmedOdometer': false,
      'locationSharingRequiresActiveOptIn': true,
      'employeeTrackingRequiresMutualConsent': true,
      'employerGodModeAllowed': false,
      'authDoesNotImplyAuthorization': true,
      'rawLocationIncluded': false,
      'rawSensorPayloadIncluded': false,
    });
  });

  test('profile maps never require maps or expose raw sensor payloads', () {
    for (final profile in TripTrackingProfile.values) {
      final profileMap = TripTrackingProfileStrategy.forProfile(
        profile,
      ).toDashboardProfileMap();

      expect(profileMap['schemaVersion'], 1);
      expect(profileMap['mapsRequiredForTracking'], isFalse);
      expect(profileMap['gpsAssistedTrackingAvailableWithoutMaps'], isTrue);
      expect(profileMap['mapsCanOnlyAssistVisualization'], isTrue);
      expect(profileMap['mapRouteOptimizationOptional'], isTrue);
      expect(profileMap['mapboxCanConfirmStop'], isFalse);
      expect(profileMap['mapboxCanReplaceGpsDistance'], isFalse);
      expect(profileMap['walkingEvidenceCanOnlySuggestReview'], isTrue);
      expect(
        profileMap['activityRecognitionCanConfirmStopAutomatically'],
        isFalse,
      );
      expect(profileMap['odometerRemainsCanonical'], isTrue);
      expect(profileMap['gpsDistanceCanOnlyAssistOdometerReview'], isTrue);
      expect(profileMap['calibrationCanAutoRewriteConfirmedOdometer'], isFalse);
      expect(profileMap['authDoesNotImplyAuthorization'], isTrue);
      expect(profileMap['rawLocationIncluded'], isFalse);
      expect(profileMap['rawSensorPayloadIncluded'], isFalse);
      expect(profileMap['driverKind'], isA<String>());
      expect(profileMap['stopEvidenceTier'], isA<String>());
      expect(profileMap['stopReviewConfidencePolicy'], isA<String>());
    }
  });

  test('vehicle-only stop profiles expose manual fallback policy', () {
    final rideshare = TripTrackingProfileStrategy.forProfile(
      TripTrackingProfile.rideshareVehicle,
    );
    final delivery = TripTrackingProfileStrategy.forProfile(
      TripTrackingProfile.deliveryVehicle,
    );
    final equipment = TripTrackingProfileStrategy.forProfile(
      TripTrackingProfile.lowSpeedEquipment,
    );

    expect(rideshare.phoneMayStayInVehicleDuringStops, isTrue);
    expect(rideshare.vehicleOnlyStopsNeedManualFallback, isTrue);
    expect(
      rideshare.toDashboardProfileMap()['vehicleOnlyStopsRequireReview'],
      isTrue,
    );
    expect(
      rideshare.stopReviewConfidencePolicyToken,
      'strong_vehicle_only_manual_review',
    );
    expect(delivery.phoneMayStayInVehicleDuringStops, isTrue);
    expect(delivery.vehicleOnlyStopsNeedManualFallback, isTrue);
    expect(
      delivery.toDashboardProfileMap()['vehicleOnlyStopsRequireReview'],
      isTrue,
    );
    expect(
      delivery.stopReviewConfidencePolicyToken,
      'walking_assist_with_manual_fallback',
    );
    expect(equipment.vehicleOnlyStopsNeedManualFallback, isTrue);
    expect(equipment.stopReviewConfidencePolicyToken, 'gps_only_manual_review');
  });

  test('profile strategy clamps malformed walking thresholds safely', () {
    final strategy = TripTrackingProfileStrategy.forProfile(
      TripTrackingProfile.contractorVehicle,
      policy: const TripTrackingPolicy(
        walkingConfirmationCount: 0,
        walkingStopConfirmationDuration: Duration(days: -1),
      ),
    );

    expect(strategy.walkingConfirmationCount, 3);
    expect(
      strategy.walkingStopConfirmationDuration,
      const Duration(seconds: 20),
    );
    expect(strategy.minimumWalkingEvidenceSpacing, const Duration(seconds: 5));
  });
}
