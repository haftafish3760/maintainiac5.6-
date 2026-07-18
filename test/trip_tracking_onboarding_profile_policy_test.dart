import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_onboarding_profile_policy.dart';

void main() {
  test('skip setup preserves the default single-vehicle road profile', () {
    final decision = choose(
      workIntent: TripTrackingOnboardingWorkIntent.skipDefault,
      driverPattern: TripTrackingOnboardingDriverPattern.exitsVehicleAtStops,
      userWantsBusinessTracking: false,
      userWantsMultipleVehicles: true,
      userWantsMultipleWorkProfiles: true,
    );
    final safe = decision.toSafeDashboardSetupMap();

    expect(decision.profile, TripTrackingProfile.roadVehicle);
    expect(decision.workProfileRequired, isFalse);
    expect(decision.vehicleProfileRequired, isFalse);
    expect(safe['skipSetupSupported'], isTrue);
    expect(safe['defaultSingleVehicleSupported'], isTrue);
    expect(safe['startButtonShouldBeVisibleFirst'], isTrue);
    expect(safe['gpsAssistedTrackingAvailableWithoutMaps'], isTrue);
    expect(safe['mapsRequiredForTracking'], isFalse);
  });

  test('rideshare users get stronger stop debounce and manual fallback', () {
    final decision = choose(
      workIntent: TripTrackingOnboardingWorkIntent.rideshare,
      driverPattern: TripTrackingOnboardingDriverPattern.staysInVehicle,
    );
    final safe = decision.toSafeDashboardSetupMap();

    expect(decision.profile, TripTrackingProfile.rideshareVehicle);
    expect(safe['dashboardMode'], 'gig_driver');
    expect(safe['workStyle'], 'rideshare');
    expect(safe['reasonCode'], 'rideshare_strong_debounce_profile');
    expect(safe['vehicleOnlyStopsNeedManualFallback'], isTrue);
    expect(decision.strategy.stopDetectionModeToken, 'strong_debounce');
  });

  test(
    'delivery and team delivery choose walking assist with manual fallback',
    () {
      for (final pattern in const [
        TripTrackingOnboardingDriverPattern.exitsVehicleAtStops,
        TripTrackingOnboardingDriverPattern.mixedOrTeamDelivery,
      ]) {
        final decision = choose(
          workIntent: TripTrackingOnboardingWorkIntent.delivery,
          driverPattern: pattern,
        );
        final safe = decision.toSafeDashboardSetupMap();

        expect(decision.profile, TripTrackingProfile.deliveryVehicle);
        expect(safe['workStyle'], 'delivery');
        expect(safe['reasonCode'], 'delivery_walking_assist_profile');
        expect(safe['recommendedDashboardWidgets'], contains('stops'));
        expect(safe['recommendedQuickActions'], contains('add_dropoff'));
        expect(safe['activityRecognitionCanCreateOfficialStop'], isFalse);
      }
    },
  );

  test('contractors get jobs and materials dashboard recommendations', () {
    final decision = choose(
      workIntent: TripTrackingOnboardingWorkIntent.contractor,
      driverPattern: TripTrackingOnboardingDriverPattern.exitsVehicleAtStops,
      userWantsMultipleVehicles: true,
      userWantsMultipleWorkProfiles: true,
    );
    final safe = decision.toSafeDashboardSetupMap();

    expect(decision.profile, TripTrackingProfile.contractorVehicle);
    expect(decision.workProfileRequired, isTrue);
    expect(decision.vehicleProfileRequired, isTrue);
    expect(safe['dashboardMode'], 'contractor');
    expect(safe['recommendedDashboardWidgets'], contains('jobs'));
    expect(safe['recommendedDashboardWidgets'], contains('materials'));
    expect(safe['recommendedQuickActions'], contains('add_job'));
  });

  test('low-speed equipment ignores walking stop evidence', () {
    final decision = choose(
      workIntent: TripTrackingOnboardingWorkIntent.equipment,
      driverPattern: TripTrackingOnboardingDriverPattern.lowSpeedEquipment,
    );
    final safe = decision.toSafeDashboardSetupMap();

    expect(decision.profile, TripTrackingProfile.lowSpeedEquipment);
    expect(decision.strategy.usesWalkingStopEvidence, isFalse);
    expect(safe['reasonCode'], 'equipment_gps_only_profile');
    expect(safe['activityRecognitionRequiresOptIn'], isFalse);
    expect(safe['vehicleOnlyStopsNeedManualFallback'], isTrue);
  });

  test('safe onboarding summary never grants remote tracking authority', () {
    final safe = choose(
      workIntent: TripTrackingOnboardingWorkIntent.delivery,
      driverPattern: TripTrackingOnboardingDriverPattern.exitsVehicleAtStops,
    ).toSafeDashboardSetupMap();

    expect(safe['profileDataTrustedAfterValidationOnly'], isTrue);
    expect(safe['remoteProfileCanEnableTracking'], isFalse);
    expect(safe['employerCanEnableTrackingWithoutMutualConsent'], isFalse);
    expect(safe['rawLocationIncluded'], isFalse);
    expect(safe['rawSensorPayloadIncluded'], isFalse);
    expect(safe['tokensIncluded'], isFalse);
    expect(safe.toString(), isNot(contains('pk.')));
    expect(safe.toString(), isNot(contains('sk.')));
  });
}

TripTrackingOnboardingProfileDecision choose({
  required TripTrackingOnboardingWorkIntent workIntent,
  required TripTrackingOnboardingDriverPattern driverPattern,
  bool userWantsBusinessTracking = true,
  bool userWantsMultipleVehicles = false,
  bool userWantsMultipleWorkProfiles = false,
}) {
  return TripTrackingOnboardingProfilePolicy.choose(
    workIntent: workIntent,
    driverPattern: driverPattern,
    userWantsBusinessTracking: userWantsBusinessTracking,
    userWantsMultipleVehicles: userWantsMultipleVehicles,
    userWantsMultipleWorkProfiles: userWantsMultipleWorkProfiles,
  );
}
