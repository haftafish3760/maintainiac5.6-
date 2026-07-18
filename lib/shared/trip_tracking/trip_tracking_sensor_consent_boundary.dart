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
    'remoteCapabilityCanEnableSensorsWithoutOptIn': false,
    'firebaseCanEnableTrackingWithoutConsent': false,
    'mapboxCanEnableTrackingWithoutConsent': false,
    'employerCanEnableTrackingWithoutEmployeeConsent': false,
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
