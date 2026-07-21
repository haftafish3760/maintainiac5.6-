part of 'trip_tracking_profile_strategy.dart';

class TripTrackingProfileStrategySummaryValidation {
  const TripTrackingProfileStrategySummaryValidation._({
    required this.isRenderable,
    required this.reasons,
  });

  factory TripTrackingProfileStrategySummaryValidation.fromSummary(
    Map<String, Object?> summary,
  ) {
    final reasons = <String>[];
    if (summary['schemaVersion'] != 1) {
      reasons.add('unsupported_schema_version');
    }
    if (_safeProfile(summary['profile']) == null) {
      reasons.add('invalid_profile');
    }
    if (_safeWorkStyle(summary['workStyle']) == null) {
      reasons.add('invalid_work_style');
    }
    if (summary['dashboardMode'] !=
        _safeDashboardModeToken('${summary['dashboardMode'] ?? ''}')) {
      reasons.add('invalid_dashboard_mode');
    }
    for (final key in const [
      'recommendedActivityRecognition',
      'usesWalkingStopEvidence',
      'requiresStrongerStopDebounce',
      'phoneMayStayInVehicleDuringStops',
      'vehicleOnlyStopsNeedManualFallback',
      'defaultSingleVehicleSupported',
      'workProfileOptionalForDefaultSetup',
      'vehicleProfileOptionalForDefaultSetup',
      'dashboardCustomizationSupported',
      'profileCanBeChangedLater',
      'walkingEvidenceCanOnlySuggestReview',
      'activityRecognitionRequiresOptIn',
      'activityRecognitionCanConfirmStopAutomatically',
      'vehicleOnlyStopsRequireReview',
      'longStoplightCanRequireReview',
      'gpsAssistedTrackingAvailableWithoutMaps',
      'mapsRequiredForTracking',
      'mapsCanOnlyAssistVisualization',
      'mapRouteOptimizationOptional',
      'mapboxCanConfirmStop',
      'mapboxCanReplaceGpsDistance',
      'odometerIsGlobalTruth',
      'odometerRemainsCanonical',
      'gpsDistanceCanOnlyAssistOdometerReview',
      'calibrationRequiresMultipleReviewedTrips',
      'calibrationRequiresTrustedGpsWindow',
      'poorGpsDaysExcludedFromCalibration',
      'calibrationCanAutoRewriteConfirmedOdometer',
      'locationSharingRequiresActiveOptIn',
      'employeeTrackingRequiresMutualConsent',
      'employerGodModeAllowed',
      'authDoesNotImplyAuthorization',
      'profileDataTrustedAfterValidationOnly',
      'remoteProfileCanEnableEmployeeTracking',
      'remoteProfileCanEnableMapRouteStorage',
      'remoteProfileCanChangeConfirmedMileage',
      'firestoreProfileCanOverrideUserConsent',
      'cloudFunctionProfileCanOverrideUserConsent',
      'mapboxProfileCanOverrideStopPolicy',
      'profileStrategyCanDeleteTripData',
      'profileStrategyCanEndTripAutomatically',
      'rawLocationIncluded',
      'rawSensorPayloadIncluded',
      'preciseLocationIncluded',
      'routeGeometryIncluded',
      'tokensIncluded',
    ]) {
      if (summary[key] is! bool) reasons.add('${key}_not_bool');
    }
    if (summary['walkingEvidenceCanOnlySuggestReview'] != true ||
        summary['activityRecognitionRequiresOptIn'] !=
            summary['recommendedActivityRecognition'] ||
        summary['activityRecognitionCanConfirmStopAutomatically'] != false ||
        summary['vehicleOnlyStopsRequireReview'] !=
            summary['vehicleOnlyStopsNeedManualFallback'] ||
        summary['longStoplightCanRequireReview'] != true) {
      reasons.add('stop_review_boundary_missing');
    }
    if (summary['gpsAssistedTrackingAvailableWithoutMaps'] != true ||
        summary['mapsRequiredForTracking'] != false ||
        summary['mapsCanOnlyAssistVisualization'] != true ||
        summary['mapboxCanConfirmStop'] != false ||
        summary['mapboxCanReplaceGpsDistance'] != false ||
        summary['mapboxProfileCanOverrideStopPolicy'] != false) {
      reasons.add('mapbox_can_control_profile_strategy');
    }
    if (summary['odometerIsGlobalTruth'] != true ||
        summary['odometerRemainsCanonical'] != true ||
        summary['gpsDistanceCanOnlyAssistOdometerReview'] != true ||
        summary['calibrationRequiresMultipleReviewedTrips'] != true ||
        summary['calibrationRequiresTrustedGpsWindow'] != true ||
        summary['poorGpsDaysExcludedFromCalibration'] != true ||
        summary['calibrationCanAutoRewriteConfirmedOdometer'] != false) {
      reasons.add('odometer_or_calibration_boundary_missing');
    }
    if (summary['locationSharingRequiresActiveOptIn'] != true ||
        summary['employeeTrackingRequiresMutualConsent'] != true ||
        summary['employerGodModeAllowed'] != false ||
        summary['authDoesNotImplyAuthorization'] != true ||
        summary['profileDataTrustedAfterValidationOnly'] != true ||
        summary['remoteProfileCanEnableEmployeeTracking'] != false ||
        summary['firestoreProfileCanOverrideUserConsent'] != false ||
        summary['cloudFunctionProfileCanOverrideUserConsent'] != false) {
      reasons.add('tracking_consent_boundary_missing');
    }
    if (summary['remoteProfileCanEnableMapRouteStorage'] != false ||
        summary['remoteProfileCanChangeConfirmedMileage'] != false ||
        summary['profileStrategyCanDeleteTripData'] != false ||
        summary['profileStrategyCanEndTripAutomatically'] != false) {
      reasons.add('remote_profile_can_mutate_trip_truth');
    }
    if (summary['rawLocationIncluded'] != false ||
        summary['rawSensorPayloadIncluded'] != false ||
        summary['preciseLocationIncluded'] != false ||
        summary['routeGeometryIncluded'] != false ||
        summary['tokensIncluded'] != false ||
        summary.values.any(_looksSensitive)) {
      reasons.add('summary_contains_sensitive_profile_material');
    }

    return TripTrackingProfileStrategySummaryValidation._(
      isRenderable: reasons.isEmpty,
      reasons: List.unmodifiable(reasons),
    );
  }

  final bool isRenderable;
  final List<String> reasons;
}

int _safePositiveInt(int value, {required int fallback}) =>
    value > 0 ? value : fallback;

Duration _safePositiveDuration(Duration value, Duration fallback) =>
    value > Duration.zero ? value : fallback;

Duration _minimumEvidenceSpacingFor(Duration stopConfirmationDuration) {
  final seconds = stopConfirmationDuration.inSeconds;
  if (seconds <= 0) return const Duration(seconds: 5);
  final spacing = seconds ~/ 4;
  if (spacing < 5) return const Duration(seconds: 5);
  if (spacing > 15) return const Duration(seconds: 15);
  return Duration(seconds: spacing);
}

String _safeDashboardModeToken(String value) {
  return switch (value.trim()) {
    'default' => 'default',
    'gig_driver' => 'gig_driver',
    'contractor' => 'contractor',
    _ => 'default',
  };
}

String _safeStopReviewReason(String value) {
  return switch (value.trim()) {
    'rideshare_stop_requires_extra_evidence' =>
      'rideshare_stop_requires_extra_evidence',
    'delivery_stop_walk_review' => 'delivery_stop_walk_review',
    'contractor_stop_walk_review' => 'contractor_stop_walk_review',
    'equipment_ignores_walking_stop_evidence' =>
      'equipment_ignores_walking_stop_evidence',
    'road_vehicle_stop_walk_review' => 'road_vehicle_stop_walk_review',
    _ => 'road_vehicle_stop_walk_review',
  };
}

String _safeDashboardWidgetToken(String value) {
  return switch (value.trim()) {
    'start_day' => 'start_day',
    'live_odometer' => 'live_odometer',
    'pay' => 'pay',
    'profit' => 'profit',
    'miles' => 'miles',
    'hours' => 'hours',
    'stops' => 'stops',
    'expenses' => 'expenses',
    'jobs' => 'jobs',
    'materials' => 'materials',
    'payments' => 'payments',
    'maintenance' => 'maintenance',
    _ => 'start_day',
  };
}

String _safeQuickActionToken(String value) {
  return switch (value.trim()) {
    'add_pay' => 'add_pay',
    'end_trip' => 'end_trip',
    'review_mileage' => 'review_mileage',
    'add_pickup' => 'add_pickup',
    'add_dropoff' => 'add_dropoff',
    'add_stop' => 'add_stop',
    'add_job' => 'add_job',
    'add_expense' => 'add_expense',
    'record_payment' => 'record_payment',
    'start_trip' => 'start_trip',
    'maintenance_log' => 'maintenance_log',
    _ => 'review_mileage',
  };
}

TripTrackingProfile? _safeProfile(Object? value) {
  if (value is! String) return null;
  for (final profile in TripTrackingProfile.values) {
    if (profile.name == value) return profile;
  }
  return null;
}

String? _safeWorkStyle(Object? value) {
  if (value is! String) return null;
  return switch (value) {
    'general_road' ||
    'rideshare' ||
    'delivery' ||
    'contractor' ||
    'equipment' => value,
    _ => null,
  };
}

bool _looksSensitive(Object? value) {
  if (value is! String) return false;
  final clean = value.trim();
  return clean.startsWith('pk.') ||
      clean.startsWith('sk.') ||
      clean.contains(RegExp(r'-?\d{1,3}\.\d{5,}'));
}
