import '../device_capabilities/device_capabilities.dart';
import 'trip_tracking_capability_guidance.dart';
import 'trip_tracking_device_profile_validator.dart';
import 'trip_tracking_platform.dart';
import 'trip_tracking_settings_store.dart';

enum TripTrackingStorageDecisionStatus {
  allowTextTripLog,
  deferMapRouteHistory,
  reviewStorage,
}

enum TripTrackingDeviceAssistLevel {
  unavailable,
  locationOnly,
  locationWithBatteryGuard,
  motionAssist,
  motionAndBatteryAssist,
}

enum TripTrackingDeviceConsentStatus {
  ready,
  gpsDisabledByUser,
  locationUnavailable,
  backgroundNeedsConsentOrCapability,
  motionNeedsConsentOrCapability,
}

class TripTrackingDeviceConsentDecision {
  const TripTrackingDeviceConsentDecision({
    required this.status,
    required this.assistLevel,
    required this.locationEnabled,
    required this.backgroundEnabled,
    required this.activityRecognitionEnabled,
    required this.batteryGuardEnabled,
    required this.mapHistoryEnabled,
    required this.reasonCodes,
    required this.recommendedSettings,
  });

  final TripTrackingDeviceConsentStatus status;
  final TripTrackingDeviceAssistLevel assistLevel;
  final bool locationEnabled;
  final bool backgroundEnabled;
  final bool activityRecognitionEnabled;
  final bool batteryGuardEnabled;
  final bool mapHistoryEnabled;
  final List<String> reasonCodes;
  final TripTrackingSettings recommendedSettings;

  bool get canStartGpsTracking =>
      locationEnabled &&
      status != TripTrackingDeviceConsentStatus.gpsDisabledByUser &&
      status != TripTrackingDeviceConsentStatus.locationUnavailable;

  bool get canUseMotionStopAssist =>
      canStartGpsTracking && activityRecognitionEnabled;

  Map<String, Object?> toSafeSummary() => {
    'schemaVersion': 1,
    'status': status.name,
    'assistLevel': assistLevel.name,
    'reasonCodes': reasonCodes,
    'canStartGpsTracking': canStartGpsTracking,
    'canUseMotionStopAssist': canUseMotionStopAssist,
    'canDegradeToLocationOnly': locationEnabled && !activityRecognitionEnabled,
    'missingAssistBlocksGpsTracking': false,
    'backgroundAssistCanDegradeWithoutStoppingTrip': true,
    'motionAssistCanDegradeWithoutStoppingTrip': true,
    'locationEnabled': locationEnabled,
    'backgroundEnabled': backgroundEnabled,
    'activityRecognitionEnabled': activityRecognitionEnabled,
    'batteryGuardEnabled': batteryGuardEnabled,
    'mapHistoryEnabled': mapHistoryEnabled,
    'gpsTrackingCanRunWithoutMaps': true,
    'mapsRequiredForTracking': false,
    'mapHistoryRequiresSeparateOptIn': true,
    'mapboxCanEnableGpsTracking': false,
    'mapboxCanEnableMotionSensors': false,
    'firebaseCanEnableSensorsWithoutUserConsent': false,
    'employerCanEnableTrackingWithoutUserConsent': false,
    'activityRecognitionRequiresUserConsent': true,
    'backgroundTrackingRequiresUserConsent': true,
    'backgroundTrackingRequiresPlatformCapability': true,
    'deviceCapabilityTrustedAfterValidationOnly': true,
    'validatedCapabilityDoesNotReplacePlatformPermission': true,
    'deviceCapabilityCannotInferConsentFromModel': true,
    'deviceCapabilityCanOnlyRecommendSettings': true,
    'deviceCapabilityCanSilentlyStartTracking': false,
    'activityRecognitionCanCreateOfficialStop': false,
    'activityRecognitionCanOnlySuggestReview': true,
    'activityEvidenceRequiresCurrentDeviceSession': true,
    'importedSensorEvidenceCannotEnableAssist': true,
    'batteryGuardCanStopTripAutomatically': false,
    'batteryGuardCanDeleteTripRecords': false,
    'lowBatteryDefaultGpsPausePercent': 20,
    'lowBatteryPauseCanBeOverriddenByUser': true,
    'odometerRemainsOfficialMileageTruth': true,
    'odometerIsGlobalTruth': true,
    'physicalOdometerRequiredForOfficialMileage': true,
    'confirmedOdometerOverridesExternalMileage': true,
    'externalMileageCannotBecomeGlobalTruth': true,
    'gpsDistanceCanOnlyAdviseMileageReview': true,
    'mapMatchingCanOnlyAdviseMileageReview': true,
    'optimizationCannotChangeOfficialMileage': true,
    'rawSensorPayloadIncluded': false,
    'preciseLocationIncluded': false,
    'deviceModelIncluded': false,
    'tokensIncluded': false,
  };
}

class TripTrackingDeviceConsentPolicy {
  const TripTrackingDeviceConsentPolicy._();

  static TripTrackingDeviceConsentDecision evaluate({
    required TripTrackingSettings settings,
    required TripTrackingPlatformCapabilities capabilities,
    required bool userConsentedToGps,
    required bool userConsentedToBackground,
    required bool userConsentedToActivityRecognition,
  }) {
    final reasons = <String>[];
    if (!settings.gpsAssistedTrackingEnabled || !userConsentedToGps) {
      reasons.add('gps_tracking_not_enabled_by_user');
    }
    if (!capabilities.locationAvailable) {
      reasons.add('location_capability_unavailable');
    }

    final locationEnabled =
        settings.gpsAssistedTrackingEnabled &&
        userConsentedToGps &&
        capabilities.locationAvailable;
    final backgroundEnabled =
        locationEnabled &&
        settings.backgroundTrackingEnabled &&
        userConsentedToBackground &&
        capabilities.backgroundTrackingAvailable;
    if (settings.backgroundTrackingEnabled &&
        (!userConsentedToBackground ||
            !capabilities.backgroundTrackingAvailable)) {
      reasons.add('background_tracking_not_authorized_or_available');
    }

    final activityRecognitionEnabled =
        locationEnabled &&
        settings.activityRecognitionEnabled &&
        userConsentedToActivityRecognition &&
        capabilities.activityRecognitionAvailable;
    if (settings.activityRecognitionEnabled &&
        (!userConsentedToActivityRecognition ||
            !capabilities.activityRecognitionAvailable)) {
      reasons.add('activity_recognition_not_authorized_or_available');
    }

    final batteryGuardEnabled =
        locationEnabled &&
        settings.lowBatteryGpsProtectionEnabled &&
        capabilities.batteryStateAvailable;
    final mapHistoryEnabled =
        locationEnabled &&
        settings.mapRouteHistorySavingEnabled &&
        settings.mapRouteHistoryDailyBudgetMb > 0;

    final status = _statusFor(
      locationEnabled: locationEnabled,
      gpsRequested: settings.gpsAssistedTrackingEnabled || userConsentedToGps,
      locationAvailable: capabilities.locationAvailable,
      backgroundRequested: settings.backgroundTrackingEnabled,
      backgroundEnabled: backgroundEnabled,
      activityRequested: settings.activityRecognitionEnabled,
      activityEnabled: activityRecognitionEnabled,
    );
    return TripTrackingDeviceConsentDecision(
      status: status,
      assistLevel: _assistLevelFor(
        locationEnabled: locationEnabled,
        activityRecognitionEnabled: activityRecognitionEnabled,
        batteryGuardEnabled: batteryGuardEnabled,
      ),
      locationEnabled: locationEnabled,
      backgroundEnabled: backgroundEnabled,
      activityRecognitionEnabled: activityRecognitionEnabled,
      batteryGuardEnabled: batteryGuardEnabled,
      mapHistoryEnabled: mapHistoryEnabled,
      reasonCodes: List.unmodifiable(reasons.isEmpty ? ['ready'] : reasons),
      recommendedSettings: settings.copyWith(
        backgroundTrackingEnabled: backgroundEnabled,
        activityRecognitionEnabled: activityRecognitionEnabled,
        lowBatteryGpsProtectionEnabled: settings.lowBatteryGpsProtectionEnabled,
        mapRouteHistorySavingEnabled: mapHistoryEnabled,
      ),
    );
  }
}

class TripTrackingStorageDecision {
  const TripTrackingStorageDecision({
    required this.status,
    required this.reasonCode,
    required this.freeStorageBucket,
    required this.textTripLogAllowed,
    required this.mapRouteHistoryAllowed,
  });

  final TripTrackingStorageDecisionStatus status;
  final String reasonCode;
  final String freeStorageBucket;
  final bool textTripLogAllowed;
  final bool mapRouteHistoryAllowed;

  bool get shouldPromptUser =>
      status == TripTrackingStorageDecisionStatus.reviewStorage;

  Map<String, Object?> toSafeSummary() => {
    'schemaVersion': 1,
    'status': status.name,
    'reasonCode': _safeStorageReason(reasonCode),
    'freeStorageBucket': _safeStorageBucket(freeStorageBucket),
    'textTripLogAllowed': textTripLogAllowed,
    'mapRouteHistoryAllowed': mapRouteHistoryAllowed,
    'shouldPromptUser': shouldPromptUser,
    'minimumTextTripLogStorageMb': 25,
    'gpsTextTripLogCanContinueAtTwentyFiveMb': true,
    'mapRouteHistoryIsOptional': true,
    'mapRouteHistoryRequiresSeparateOptIn': true,
    'mapRouteHistoryCanBeDeferredWithoutStoppingTrip': true,
    'storageDecisionCanDeleteTripData': false,
    'storageDecisionCanPurgeLocalRecords': false,
    'firebaseBackupCanPurgeLocalRecordsSilently': false,
    'mapboxCanOverrideStorageDecision': false,
    'rawStoragePayloadIncluded': false,
    'preciseFreeStorageIncluded': false,
  };

  static TripTrackingStorageDecision evaluate({
    required int? freeStorageMb,
    required bool mapRouteHistoryRequested,
    int minimumTextTripLogStorageMb = 25,
    int minimumMapRouteHistoryStorageMb = 500,
  }) {
    if (minimumTextTripLogStorageMb < 0 ||
        minimumMapRouteHistoryStorageMb < minimumTextTripLogStorageMb) {
      return const TripTrackingStorageDecision(
        status: TripTrackingStorageDecisionStatus.reviewStorage,
        reasonCode: 'invalid_storage_policy',
        freeStorageBucket: 'unknown',
        textTripLogAllowed: true,
        mapRouteHistoryAllowed: false,
      );
    }
    final free = freeStorageMb;
    if (free == null || free < 0) {
      return TripTrackingStorageDecision(
        status: mapRouteHistoryRequested
            ? TripTrackingStorageDecisionStatus.deferMapRouteHistory
            : TripTrackingStorageDecisionStatus.allowTextTripLog,
        reasonCode: mapRouteHistoryRequested
            ? 'unknown_storage_defers_map_history'
            : 'unknown_storage_allows_text_log',
        freeStorageBucket: 'unknown',
        textTripLogAllowed: true,
        mapRouteHistoryAllowed: false,
      );
    }
    if (free < minimumTextTripLogStorageMb) {
      return TripTrackingStorageDecision(
        status: TripTrackingStorageDecisionStatus.reviewStorage,
        reasonCode: 'critically_low_storage_review',
        freeStorageBucket: _storageBucketFor(free),
        textTripLogAllowed: true,
        mapRouteHistoryAllowed: false,
      );
    }
    if (mapRouteHistoryRequested && free < minimumMapRouteHistoryStorageMb) {
      return TripTrackingStorageDecision(
        status: TripTrackingStorageDecisionStatus.deferMapRouteHistory,
        reasonCode: 'low_storage_defers_map_history',
        freeStorageBucket: _storageBucketFor(free),
        textTripLogAllowed: true,
        mapRouteHistoryAllowed: false,
      );
    }
    return TripTrackingStorageDecision(
      status: TripTrackingStorageDecisionStatus.allowTextTripLog,
      reasonCode: mapRouteHistoryRequested
          ? 'storage_allows_text_log_and_map_history'
          : 'storage_allows_text_log',
      freeStorageBucket: _storageBucketFor(free),
      textTripLogAllowed: true,
      mapRouteHistoryAllowed: mapRouteHistoryRequested,
    );
  }
}

TripTrackingDeviceConsentStatus _statusFor({
  required bool locationEnabled,
  required bool gpsRequested,
  required bool locationAvailable,
  required bool backgroundRequested,
  required bool backgroundEnabled,
  required bool activityRequested,
  required bool activityEnabled,
}) {
  if (!locationAvailable && gpsRequested) {
    return TripTrackingDeviceConsentStatus.locationUnavailable;
  }
  if (!locationEnabled) {
    return TripTrackingDeviceConsentStatus.gpsDisabledByUser;
  }
  if (backgroundRequested && !backgroundEnabled) {
    return TripTrackingDeviceConsentStatus.backgroundNeedsConsentOrCapability;
  }
  if (activityRequested && !activityEnabled) {
    return TripTrackingDeviceConsentStatus.motionNeedsConsentOrCapability;
  }
  return TripTrackingDeviceConsentStatus.ready;
}

TripTrackingDeviceAssistLevel _assistLevelFor({
  required bool locationEnabled,
  required bool activityRecognitionEnabled,
  required bool batteryGuardEnabled,
}) {
  if (!locationEnabled) return TripTrackingDeviceAssistLevel.unavailable;
  if (activityRecognitionEnabled && batteryGuardEnabled) {
    return TripTrackingDeviceAssistLevel.motionAndBatteryAssist;
  }
  if (activityRecognitionEnabled) {
    return TripTrackingDeviceAssistLevel.motionAssist;
  }
  if (batteryGuardEnabled) {
    return TripTrackingDeviceAssistLevel.locationWithBatteryGuard;
  }
  return TripTrackingDeviceAssistLevel.locationOnly;
}

class TripTrackingDeviceOperationalPolicy {
  const TripTrackingDeviceOperationalPolicy({
    required this.platformCapabilities,
    required this.recommendedSampleIntervalSeconds,
    required this.lowBatteryGuardRecommended,
    required this.activityRecognitionRecommended,
    required this.backgroundTrackingAllowed,
    required this.deferMapRouteHistory,
  });

  final TripTrackingPlatformCapabilities platformCapabilities;
  final int recommendedSampleIntervalSeconds;
  final bool lowBatteryGuardRecommended;
  final bool activityRecognitionRecommended;
  final bool backgroundTrackingAllowed;
  final bool deferMapRouteHistory;

  TripTrackingCapabilityGuidance guidanceFor(TripTrackingSettings settings) {
    return TripTrackingCapabilityGuidance.fromCapabilities(
      capabilities: platformCapabilities,
      settings: settings.copyWith(
        lowBatteryGpsProtectionEnabled: lowBatteryGuardRecommended,
        activityRecognitionEnabled:
            settings.activityRecognitionEnabled &&
            activityRecognitionRecommended,
        backgroundTrackingEnabled:
            settings.backgroundTrackingEnabled && backgroundTrackingAllowed,
        mapRouteHistorySavingEnabled:
            settings.mapRouteHistorySavingEnabled && !deferMapRouteHistory,
        mapRouteHistorySampleIntervalSeconds: recommendedSampleIntervalSeconds,
      ),
    );
  }

  Map<String, Object?> toSafeSummary() => {
    'schemaVersion': 1,
    'usesSharedDeviceCapabilityProfile': true,
    'deviceTier': platformCapabilities.deviceTier.name,
    'recommendedSampleIntervalSeconds': _safeSampleIntervalSeconds(
      recommendedSampleIntervalSeconds,
    ),
    'lowBatteryGuardRecommended': lowBatteryGuardRecommended,
    'activityRecognitionRecommended': activityRecognitionRecommended,
    'backgroundTrackingAllowed': backgroundTrackingAllowed,
    'deferMapRouteHistory': deferMapRouteHistory,
    'gpsTrackingCanRunWithoutMaps': true,
    'mapsRequiredForTracking': false,
    'mapUsageRequiresSeparateUserOptIn': true,
    'paidMapServicesCanBeDisabled': true,
    'gpsTextTripLogCanContinueWithLowStorage': true,
    'gpsTextTripLogCanContinueAtTwentyFiveMb': true,
    'mapRouteHistoryIsOptional': true,
    'mapRouteHistoryDeferBelowDeviceBudget': true,
    'deviceCapabilityTrustedAfterValidationOnly': true,
    'validatedCapabilityDoesNotReplacePlatformPermission': true,
    'deviceCapabilityCanOnlyRecommendSettings': true,
    'deviceCapabilityCanDeleteLocalData': false,
    'deviceCapabilityCanSilentlyStartTracking': false,
    'remoteCapabilityCanEnableSensorsWithoutOptIn': false,
    'firebaseDeviceProfileCanOverrideUserConsent': false,
    'mapboxCanOverrideDevicePolicy': false,
    'malformedCapabilityPayloadFailsSafe': true,
    'lowBatteryDefaultGpsPausePercent': 20,
    'lowBatteryPauseCanBeOverriddenByUser': true,
    'activityRecognitionRequiresOptIn': true,
    'activityRecognitionCanCreateOfficialStop': false,
    'activityRecognitionCanOnlySuggestReview': true,
    'backgroundTrackingRequiresPlatformPermission': true,
    'backgroundTrackingRequiresUserConsent': true,
    'deviceModelIncluded': false,
    'rawSensorPayloadIncluded': false,
    'preciseLocationIncluded': false,
    'tokensIncluded': false,
  };

  factory TripTrackingDeviceOperationalPolicy.fromDeviceProfile(
    DeviceCapabilityProfile profile, {
    DateTime? currentAt,
  }) {
    final validation = TripTrackingDeviceProfileValidation.evaluate(
      profile,
      currentAt: currentAt,
    );
    final operational = profile.operationalPolicy;
    final sensors = profile.extended.sensors;
    final battery = profile.extended.battery;
    final constrained =
        operational.deferNonEssentialHeavyWork ||
        validation.shouldDegradeToLocationOnly;
    return TripTrackingDeviceOperationalPolicy(
      platformCapabilities: TripTrackingPlatformCapabilities(
        locationAvailable: true,
        backgroundTrackingAvailable:
            !constrained && validation.trustedForGpsAssist,
        activityRecognitionAvailable:
            sensors.hasMotion && validation.trustedForGpsAssist,
        batteryStateAvailable: battery.levelPercent != null,
        lowPowerModeAvailable: profile.runtime.powerSaving || battery.isLow,
      ),
      recommendedSampleIntervalSeconds: operational.tripLocationIntervalSeconds
          .clamp(5, 60),
      lowBatteryGuardRecommended: true,
      activityRecognitionRecommended:
          sensors.hasMotion && !constrained && validation.trustedForGpsAssist,
      backgroundTrackingAllowed: !constrained && validation.trustedForGpsAssist,
      deferMapRouteHistory:
          constrained ||
          !operational.allowLargeNetworkTransfer ||
          validation.shouldDegradeToLocationOnly,
    );
  }
}

int _safeSampleIntervalSeconds(int value) => value.clamp(5, 60).toInt();

String _storageBucketFor(int freeStorageMb) {
  if (freeStorageMb < 25) return 'below_25_mb';
  if (freeStorageMb < 500) return '25_to_499_mb';
  if (freeStorageMb < 5000) return '500_mb_to_4_gb';
  return '5_gb_plus';
}

String _safeStorageBucket(String value) {
  final clean = value.trim();
  return switch (clean) {
    'unknown' ||
    'below_25_mb' ||
    '25_to_499_mb' ||
    '500_mb_to_4_gb' ||
    '5_gb_plus' => clean,
    _ => 'unknown',
  };
}

String _safeStorageReason(String value) {
  final clean = value.trim();
  return switch (clean) {
    'invalid_storage_policy' => clean,
    'unknown_storage_defers_map_history' => clean,
    'unknown_storage_allows_text_log' => clean,
    'critically_low_storage_review' => clean,
    'low_storage_defers_map_history' => clean,
    'storage_allows_text_log_and_map_history' => clean,
    'storage_allows_text_log' => clean,
    _ => 'invalid_storage_policy',
  };
}
