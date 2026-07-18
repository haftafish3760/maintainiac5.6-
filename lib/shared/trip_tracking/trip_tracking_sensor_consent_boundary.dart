import 'trip_tracking_device_operational_policy.dart';
import 'trip_tracking_settings_store.dart';

enum TripTrackingSensorConsentStatus {
  gpsOff,
  gpsOnly,
  motionAssistAllowed,
  backgroundGpsAllowed,
  fullAssistAllowed,
}

class TripTrackingSensorConsentBoundary {
  const TripTrackingSensorConsentBoundary._({
    required this.status,
    required this.gpsAllowed,
    required this.activityRecognitionAllowed,
    required this.backgroundTrackingAllowed,
    required this.reasonCodes,
  });

  factory TripTrackingSensorConsentBoundary.evaluate({
    required TripTrackingSettings settings,
    required TripTrackingDeviceOperationalPolicy devicePolicy,
    required bool platformLocationPermissionGranted,
    required bool platformActivityPermissionGranted,
    required bool platformBackgroundPermissionGranted,
  }) {
    final reasons = <String>[];
    if (!settings.gpsAssistedTrackingEnabled) {
      return const TripTrackingSensorConsentBoundary._(
        status: TripTrackingSensorConsentStatus.gpsOff,
        gpsAllowed: false,
        activityRecognitionAllowed: false,
        backgroundTrackingAllowed: false,
        reasonCodes: ['gps_assist_user_disabled'],
      );
    }
    if (!platformLocationPermissionGranted ||
        !devicePolicy.platformCapabilities.locationAvailable) {
      reasons.add('location_permission_or_capability_required');
    }

    final gpsAllowed = reasons.isEmpty;
    final activityAllowed =
        gpsAllowed &&
        settings.activityRecognitionEnabled &&
        devicePolicy.activityRecognitionRecommended &&
        devicePolicy.platformCapabilities.activityRecognitionAvailable &&
        platformActivityPermissionGranted;
    if (settings.activityRecognitionEnabled && !activityAllowed) {
      reasons.add('activity_recognition_not_available_or_not_permitted');
    }

    final backgroundAllowed =
        gpsAllowed &&
        settings.backgroundTrackingEnabled &&
        devicePolicy.backgroundTrackingAllowed &&
        devicePolicy.platformCapabilities.backgroundTrackingAvailable &&
        platformBackgroundPermissionGranted;
    if (settings.backgroundTrackingEnabled && !backgroundAllowed) {
      reasons.add('background_tracking_not_available_or_not_permitted');
    }

    final status = _statusFor(
      gpsAllowed: gpsAllowed,
      activityAllowed: activityAllowed,
      backgroundAllowed: backgroundAllowed,
    );
    if (gpsAllowed && reasons.isEmpty) reasons.add('gps_assist_allowed');
    return TripTrackingSensorConsentBoundary._(
      status: status,
      gpsAllowed: gpsAllowed,
      activityRecognitionAllowed: activityAllowed,
      backgroundTrackingAllowed: backgroundAllowed,
      reasonCodes: List.unmodifiable(reasons),
    );
  }

  final TripTrackingSensorConsentStatus status;
  final bool gpsAllowed;
  final bool activityRecognitionAllowed;
  final bool backgroundTrackingAllowed;
  final List<String> reasonCodes;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'status': status.name,
    'gpsAllowed': gpsAllowed,
    'activityRecognitionAllowed': activityRecognitionAllowed,
    'backgroundTrackingAllowed': backgroundTrackingAllowed,
    'reasonCodes': reasonCodes,
    'gpsAssistedTrackingRequiresUserOptIn': true,
    'activityRecognitionRequiresUserOptIn': true,
    'backgroundTrackingRequiresUserOptIn': true,
    'platformPermissionRequired': true,
    'deviceCapabilityTrustedAfterValidationOnly': true,
    'validatedCapabilityDoesNotReplacePlatformPermission': true,
    'sensorConsentCanBeRevokedWithoutDeletingTripLog': true,
    'gpsOnlyModeRemainsAvailableWithoutMotionAssist': true,
    'motionAssistCanDegradeWithoutStoppingTrip': true,
    'backgroundAssistCanDegradeWithoutStoppingTrip': true,
    'gpsConsentRequiredBeforeActivityEvidence': true,
    'activityEvidenceRequiresCurrentConsent': true,
    'backgroundTrackingRequiresSeparatePlatformGrant': true,
    'foregroundLocationDoesNotGrantBackgroundTracking': true,
    'remoteCapabilityCanEnableSensorsWithoutOptIn': false,
    'firebaseCanEnableTrackingWithoutConsent': false,
    'mapboxCanEnableTrackingWithoutConsent': false,
    'employerCanEnableTrackingWithoutEmployeeConsent': false,
    'fleetAdminCanEnableTrackingWithoutEmployeeConsent': false,
    'deviceCapabilityCanEnableTrackingWithoutConsent': false,
    'backgroundPermissionCanBeAssumedFromForeground': false,
    'activityPermissionCanBeAssumedFromLocation': false,
    'sensorConsentCanBypassPlatformPermission': false,
    'activityRecognitionCanCreateOfficialStop': false,
    'activityRecognitionCanOnlySuggestReview': true,
    'gpsCanReplaceOdometer': false,
    'mapboxCanReplaceOdometer': false,
    'localTripLogProtected': true,
    'deviceModelIncluded': false,
    'rawSensorPayloadIncluded': false,
    'preciseLocationIncluded': false,
    'tokensIncluded': false,
  };
}

class TripTrackingSensorConsentSummaryValidation {
  const TripTrackingSensorConsentSummaryValidation._({
    required this.isRenderable,
    required this.status,
    required this.reasons,
  });

  factory TripTrackingSensorConsentSummaryValidation.fromSummary(
    Map<String, Object?> summary,
  ) {
    final reasons = <String>[];
    final status = _safeStatus(summary['status']);
    if (summary['schemaVersion'] != 1) {
      reasons.add('unsupported_schema_version');
    }
    if (status == null) reasons.add('invalid_sensor_consent_status');
    final gpsAllowed = summary['gpsAllowed'];
    final activityAllowed = summary['activityRecognitionAllowed'];
    final backgroundAllowed = summary['backgroundTrackingAllowed'];
    if (gpsAllowed is! bool ||
        activityAllowed is! bool ||
        backgroundAllowed is! bool) {
      reasons.add('invalid_sensor_flags');
    }
    final reasonCodes = summary['reasonCodes'];
    if (reasonCodes is! List ||
        reasonCodes.any((reason) => _safeReason(reason) == null)) {
      reasons.add('invalid_sensor_reason_codes');
    }
    if ((activityAllowed == true || backgroundAllowed == true) &&
        gpsAllowed != true) {
      reasons.add('assist_enabled_without_gps');
    }
    if (summary['gpsAssistedTrackingRequiresUserOptIn'] != true ||
        summary['activityRecognitionRequiresUserOptIn'] != true ||
        summary['backgroundTrackingRequiresUserOptIn'] != true ||
        summary['platformPermissionRequired'] != true ||
        summary['gpsConsentRequiredBeforeActivityEvidence'] != true ||
        summary['activityEvidenceRequiresCurrentConsent'] != true ||
        summary['backgroundTrackingRequiresSeparatePlatformGrant'] != true ||
        summary['foregroundLocationDoesNotGrantBackgroundTracking'] != true ||
        summary['validatedCapabilityDoesNotReplacePlatformPermission'] !=
            true ||
        summary['sensorConsentCanBypassPlatformPermission'] != false ||
        summary['backgroundPermissionCanBeAssumedFromForeground'] != false ||
        summary['activityPermissionCanBeAssumedFromLocation'] != false) {
      reasons.add('platform_permission_boundary_missing');
    }
    if (summary['deviceCapabilityTrustedAfterValidationOnly'] != true ||
        summary['remoteCapabilityCanEnableSensorsWithoutOptIn'] != false ||
        summary['firebaseCanEnableTrackingWithoutConsent'] != false ||
        summary['mapboxCanEnableTrackingWithoutConsent'] != false ||
        summary['deviceCapabilityCanEnableTrackingWithoutConsent'] != false ||
        summary['employerCanEnableTrackingWithoutEmployeeConsent'] != false ||
        summary['fleetAdminCanEnableTrackingWithoutEmployeeConsent'] != false) {
      reasons.add('remote_or_employer_can_enable_sensors');
    }
    if (summary['sensorConsentCanBeRevokedWithoutDeletingTripLog'] != true ||
        summary['motionAssistCanDegradeWithoutStoppingTrip'] != true ||
        summary['backgroundAssistCanDegradeWithoutStoppingTrip'] != true ||
        summary['localTripLogProtected'] != true) {
      reasons.add('consent_revocation_can_harm_trip_log');
    }
    if (summary['activityRecognitionCanCreateOfficialStop'] != false ||
        summary['activityRecognitionCanOnlySuggestReview'] != true ||
        summary['gpsCanReplaceOdometer'] != false ||
        summary['mapboxCanReplaceOdometer'] != false) {
      reasons.add('sensor_can_create_trip_truth');
    }
    if (summary['deviceModelIncluded'] != false ||
        summary['rawSensorPayloadIncluded'] != false ||
        summary['preciseLocationIncluded'] != false ||
        summary['tokensIncluded'] != false) {
      reasons.add('summary_contains_sensitive_sensor_material');
    }
    if (summary.values.any(_looksSensitive)) {
      reasons.add('summary_contains_sensitive_text');
    }

    return TripTrackingSensorConsentSummaryValidation._(
      isRenderable: reasons.isEmpty,
      status: reasons.isEmpty ? status : null,
      reasons: List.unmodifiable(reasons),
    );
  }

  final bool isRenderable;
  final TripTrackingSensorConsentStatus? status;
  final List<String> reasons;
}

TripTrackingSensorConsentStatus _statusFor({
  required bool gpsAllowed,
  required bool activityAllowed,
  required bool backgroundAllowed,
}) {
  if (!gpsAllowed) return TripTrackingSensorConsentStatus.gpsOnly;
  if (activityAllowed && backgroundAllowed) {
    return TripTrackingSensorConsentStatus.fullAssistAllowed;
  }
  if (backgroundAllowed) {
    return TripTrackingSensorConsentStatus.backgroundGpsAllowed;
  }
  if (activityAllowed) {
    return TripTrackingSensorConsentStatus.motionAssistAllowed;
  }
  return TripTrackingSensorConsentStatus.gpsOnly;
}

TripTrackingSensorConsentStatus? _safeStatus(Object? value) {
  if (value is! String) return null;
  for (final status in TripTrackingSensorConsentStatus.values) {
    if (status.name == value) return status;
  }
  return null;
}

String? _safeReason(Object? value) {
  if (value is! String) return null;
  return switch (value) {
    'gps_assist_user_disabled' => value,
    'location_permission_or_capability_required' => value,
    'activity_recognition_not_available_or_not_permitted' => value,
    'background_tracking_not_available_or_not_permitted' => value,
    'gps_assist_allowed' => value,
    _ => null,
  };
}

bool _looksSensitive(Object? value) {
  if (value is! String) return false;
  final clean = value.trim();
  return clean.startsWith('pk.') ||
      clean.startsWith('sk.') ||
      RegExp(r'-?\d{1,3}\.\d{4,}\s*,\s*-?\d{1,3}\.\d{4,}').hasMatch(clean);
}
