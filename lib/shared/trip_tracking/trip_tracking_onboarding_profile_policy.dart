import 'trip_tracking_models.dart';
import 'trip_tracking_profile_strategy.dart';

enum TripTrackingOnboardingWorkIntent {
  skipDefault,
  personal,
  rideshare,
  delivery,
  contractor,
  equipment,
}

enum TripTrackingOnboardingDriverPattern {
  staysInVehicle,
  exitsVehicleAtStops,
  mixedOrTeamDelivery,
  lowSpeedEquipment,
}

class TripTrackingOnboardingProfileDecision {
  const TripTrackingOnboardingProfileDecision({
    required this.profile,
    required this.strategy,
    required this.workProfileRequired,
    required this.vehicleProfileRequired,
    required this.reasonCode,
  });

  final TripTrackingProfile profile;
  final TripTrackingProfileStrategy strategy;
  final bool workProfileRequired;
  final bool vehicleProfileRequired;
  final String reasonCode;

  Map<String, Object?> toSafeDashboardSetupMap() => {
    'schemaVersion': 1,
    'profile': profile.name,
    'dashboardMode': strategy.dashboardModeToken,
    'workStyle': strategy.workStyleToken,
    'driverKind': strategy.driverKindToken,
    'workProfileRequired': workProfileRequired,
    'vehicleProfileRequired': vehicleProfileRequired,
    'reasonCode': _safeOnboardingReason(reasonCode),
    'defaultSingleVehicleSupported': true,
    'skipSetupSupported': true,
    'profileCanBeChangedLater': true,
    'dashboardCanBeCustomizedLater': true,
    'startButtonShouldBeVisibleFirst': true,
    'liveOdometerShouldBeDashboardSurface': true,
    'gpsAssistedTrackingAvailableWithoutMaps': true,
    'mapsRequiredForTracking': false,
    'mapboxOptionalAfterSeparateOptIn': true,
    'activityRecognitionRequiresOptIn': strategy.recommendedActivityRecognition,
    'activityRecognitionCanCreateOfficialStop': false,
    'walkingEvidenceCanOnlySuggestReview': true,
    'vehicleOnlyStopsNeedManualFallback':
        strategy.vehicleOnlyStopsNeedManualFallback,
    'odometerRemainsCanonical': true,
    'odometerIsGlobalTruth': true,
    'profileDataTrustedAfterValidationOnly': true,
    'remoteProfileCanEnableTracking': false,
    'employerCanEnableTrackingWithoutMutualConsent': false,
    'rawLocationIncluded': false,
    'rawSensorPayloadIncluded': false,
    'tokensIncluded': false,
    'recommendedDashboardWidgets': strategy.dashboardWidgetTokens,
    'recommendedQuickActions': strategy.quickActionTokens,
  };
}

class TripTrackingOnboardingProfilePolicy {
  const TripTrackingOnboardingProfilePolicy._();

  static TripTrackingOnboardingProfileDecision choose({
    required TripTrackingOnboardingWorkIntent workIntent,
    required TripTrackingOnboardingDriverPattern driverPattern,
    required bool userWantsBusinessTracking,
    required bool userWantsMultipleVehicles,
    required bool userWantsMultipleWorkProfiles,
  }) {
    final profile = _profileFor(
      workIntent: workIntent,
      driverPattern: driverPattern,
      userWantsBusinessTracking: userWantsBusinessTracking,
    );
    return TripTrackingOnboardingProfileDecision(
      profile: profile,
      strategy: TripTrackingProfileStrategy.forProfile(profile),
      workProfileRequired:
          userWantsBusinessTracking &&
          userWantsMultipleWorkProfiles &&
          workIntent != TripTrackingOnboardingWorkIntent.skipDefault,
      vehicleProfileRequired:
          userWantsBusinessTracking &&
          userWantsMultipleVehicles &&
          workIntent != TripTrackingOnboardingWorkIntent.skipDefault,
      reasonCode: _reasonFor(
        workIntent: workIntent,
        driverPattern: driverPattern,
        userWantsBusinessTracking: userWantsBusinessTracking,
      ),
    );
  }
}

TripTrackingProfile _profileFor({
  required TripTrackingOnboardingWorkIntent workIntent,
  required TripTrackingOnboardingDriverPattern driverPattern,
  required bool userWantsBusinessTracking,
}) {
  if (!userWantsBusinessTracking ||
      workIntent == TripTrackingOnboardingWorkIntent.skipDefault ||
      workIntent == TripTrackingOnboardingWorkIntent.personal) {
    return TripTrackingProfile.roadVehicle;
  }
  if (workIntent == TripTrackingOnboardingWorkIntent.equipment ||
      driverPattern == TripTrackingOnboardingDriverPattern.lowSpeedEquipment) {
    return TripTrackingProfile.lowSpeedEquipment;
  }
  if (workIntent == TripTrackingOnboardingWorkIntent.contractor) {
    return TripTrackingProfile.contractorVehicle;
  }
  if (workIntent == TripTrackingOnboardingWorkIntent.rideshare ||
      driverPattern == TripTrackingOnboardingDriverPattern.staysInVehicle) {
    return TripTrackingProfile.rideshareVehicle;
  }
  if (workIntent == TripTrackingOnboardingWorkIntent.delivery ||
      driverPattern ==
          TripTrackingOnboardingDriverPattern.exitsVehicleAtStops ||
      driverPattern ==
          TripTrackingOnboardingDriverPattern.mixedOrTeamDelivery) {
    return TripTrackingProfile.deliveryVehicle;
  }
  return TripTrackingProfile.roadVehicle;
}

String _reasonFor({
  required TripTrackingOnboardingWorkIntent workIntent,
  required TripTrackingOnboardingDriverPattern driverPattern,
  required bool userWantsBusinessTracking,
}) {
  if (!userWantsBusinessTracking) return 'personal_default_profile';
  if (workIntent == TripTrackingOnboardingWorkIntent.skipDefault) {
    return 'setup_skipped_default_profile';
  }
  if (workIntent == TripTrackingOnboardingWorkIntent.contractor) {
    return 'contractor_jobsite_profile';
  }
  if (workIntent == TripTrackingOnboardingWorkIntent.rideshare ||
      driverPattern == TripTrackingOnboardingDriverPattern.staysInVehicle) {
    return 'rideshare_strong_debounce_profile';
  }
  if (workIntent == TripTrackingOnboardingWorkIntent.delivery ||
      driverPattern ==
          TripTrackingOnboardingDriverPattern.exitsVehicleAtStops ||
      driverPattern ==
          TripTrackingOnboardingDriverPattern.mixedOrTeamDelivery) {
    return 'delivery_walking_assist_profile';
  }
  if (workIntent == TripTrackingOnboardingWorkIntent.equipment ||
      driverPattern == TripTrackingOnboardingDriverPattern.lowSpeedEquipment) {
    return 'equipment_gps_only_profile';
  }
  return 'general_road_profile';
}

String _safeOnboardingReason(String value) {
  return switch (value.trim()) {
    'personal_default_profile' => 'personal_default_profile',
    'setup_skipped_default_profile' => 'setup_skipped_default_profile',
    'contractor_jobsite_profile' => 'contractor_jobsite_profile',
    'rideshare_strong_debounce_profile' => 'rideshare_strong_debounce_profile',
    'delivery_walking_assist_profile' => 'delivery_walking_assist_profile',
    'equipment_gps_only_profile' => 'equipment_gps_only_profile',
    'general_road_profile' => 'general_road_profile',
    _ => 'general_road_profile',
  };
}
