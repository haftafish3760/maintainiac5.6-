import 'trip_tracking_platform.dart';
import 'trip_tracking_settings_store.dart';

enum TripTrackingCapabilityReadiness {
  unavailable,
  locationOnly,
  foregroundReady,
  backgroundReady,
  motionReady,
  fullSafetyAssist,
}

class TripTrackingCapabilityGuidance {
  const TripTrackingCapabilityGuidance({
    required this.readiness,
    required this.canStartForegroundGps,
    required this.canStartBackgroundGps,
    required this.canUseActivityRecognition,
    required this.canUseBatteryGuard,
    required this.canUseLowPowerGuard,
    required this.safeStatus,
    required this.dashboardBadge,
    required this.degradationMode,
    required this.stopDetectionAssistMode,
    required this.requiresManualStopReviewFallback,
    required this.recommendedSettings,
  });

  final TripTrackingCapabilityReadiness readiness;
  final bool canStartForegroundGps;
  final bool canStartBackgroundGps;
  final bool canUseActivityRecognition;
  final bool canUseBatteryGuard;
  final bool canUseLowPowerGuard;
  final String safeStatus;
  final String dashboardBadge;
  final String degradationMode;
  final String stopDetectionAssistMode;
  final bool requiresManualStopReviewFallback;
  final TripTrackingSettings recommendedSettings;

  bool get gpsUnavailable =>
      readiness == TripTrackingCapabilityReadiness.unavailable;

  bool get hasSafetySensors =>
      canUseBatteryGuard || canUseActivityRecognition || canUseLowPowerGuard;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'readiness': readiness.name,
    'canStartForegroundGps': canStartForegroundGps,
    'canStartBackgroundGps': canStartBackgroundGps,
    'canUseActivityRecognition': canUseActivityRecognition,
    'canUseBatteryGuard': canUseBatteryGuard,
    'canUseLowPowerGuard': canUseLowPowerGuard,
    'gpsUnavailable': gpsUnavailable,
    'hasSafetySensors': hasSafetySensors,
    'safeStatus': safeStatus,
    'dashboardBadge': dashboardBadge,
    'degradationMode': degradationMode,
    'stopDetectionAssistMode': stopDetectionAssistMode,
    'requiresManualStopReviewFallback': requiresManualStopReviewFallback,
    'gpsAssistRequiresOptIn': true,
    'backgroundTrackingRequiresOptIn': true,
    'activityRecognitionRequiresOptIn': true,
    'batteryGuardRequiresOptIn': true,
    'deviceCapabilityCanReduceAccuracy': true,
    'deviceCapabilityControlsSamplingTier': true,
    'deviceCapabilityControlsStopAssistTier': true,
    'locationOnlyModeRequiresMoreUserReview': requiresManualStopReviewFallback,
    'gpsTrackingCanRunWithoutMaps': true,
    'mapsRequiredForTracking': false,
    'routeHistoryRequiresLocationCapability': true,
    'routeHistoryDisabledWhenGpsUnavailable': true,
    'odometerRemainsCanonical': true,
    'odometerIsGlobalTruth': true,
    'nativeCapabilitiesAreAdvisory': true,
    'sensorAvailabilityRequiresRuntimePermission': true,
    'capabilityReadDoesNotStartTracking': true,
    'capabilityReadDoesNotGrantAuthorization': true,
    'capabilityReadDoesNotGrantPlatformPermission': true,
    'capabilityReadDoesNotGrantEmployerVisibility': true,
    'remoteCapabilityCanEnableSensorsWithoutOptIn': false,
    'deviceModelCanBeUsedAsSensorProof': false,
    'batteryBelowTwentyDefaultsToGpsPause': canUseBatteryGuard,
    'lowBatteryOverrideRequiresUserChoice': canUseBatteryGuard,
    'lowBatteryWarningCanBeRestoredInSettings': canUseBatteryGuard,
    'rawNativePayloadIncluded': false,
    'rawSensorPayloadIncluded': false,
    'preciseLocationIncluded': false,
    'tokensIncluded': false,
  };

  static TripTrackingCapabilityGuidance fromCapabilities({
    required TripTrackingPlatformCapabilities capabilities,
    required TripTrackingSettings settings,
  }) {
    final gpsEnabled =
        settings.gpsAssistedTrackingEnabled && capabilities.locationAvailable;
    final activityEnabled =
        gpsEnabled &&
        settings.activityRecognitionEnabled &&
        capabilities.activityRecognitionAvailable;
    final backgroundEnabled =
        gpsEnabled &&
        settings.backgroundTrackingEnabled &&
        capabilities.backgroundTrackingAvailable;
    final lowBatteryProtection =
        settings.lowBatteryGpsProtectionEnabled &&
        capabilities.batteryStateAvailable;
    final recommended = settings.copyWith(
      gpsAssistedTrackingEnabled: gpsEnabled,
      backgroundTrackingEnabled: backgroundEnabled,
      activityRecognitionEnabled: activityEnabled,
      lowBatteryGpsProtectionEnabled: lowBatteryProtection,
      lowBatteryGpsOverrideEnabled:
          lowBatteryProtection && settings.lowBatteryGpsOverrideEnabled,
      lowBatteryGpsWarningDismissed:
          lowBatteryProtection && settings.lowBatteryGpsWarningDismissed,
      mapRouteHistorySavingEnabled:
          gpsEnabled && settings.mapRouteHistorySavingEnabled,
    );
    final readiness = _readinessFor(
      capabilities: capabilities,
      backgroundEnabled: backgroundEnabled,
      activityEnabled: activityEnabled,
      lowBatteryProtection: lowBatteryProtection,
    );
    return TripTrackingCapabilityGuidance(
      readiness: readiness,
      canStartForegroundGps: capabilities.locationAvailable,
      canStartBackgroundGps: backgroundEnabled,
      canUseActivityRecognition: capabilities.activityRecognitionAvailable,
      canUseBatteryGuard: capabilities.batteryStateAvailable,
      canUseLowPowerGuard: capabilities.lowPowerModeAvailable,
      safeStatus: _safeStatus(readiness),
      dashboardBadge: _dashboardBadge(readiness),
      degradationMode: _degradationMode(readiness),
      stopDetectionAssistMode: _stopDetectionAssistMode(readiness),
      requiresManualStopReviewFallback: _manualFallbackRequired(readiness),
      recommendedSettings: recommended,
    );
  }
}

class TripTrackingCapabilityGuidanceSummaryValidation {
  const TripTrackingCapabilityGuidanceSummaryValidation._({
    required this.isRenderable,
    required this.readiness,
    required this.reasons,
  });

  factory TripTrackingCapabilityGuidanceSummaryValidation.fromSummary(
    Map<String, Object?> summary,
  ) {
    final reasons = <String>[];
    final readiness = _safeReadiness(summary['readiness']);
    if (summary['schemaVersion'] != 1) {
      reasons.add('unsupported_schema_version');
    }
    if (readiness == null) reasons.add('invalid_capability_readiness');
    for (final key in const [
      'canStartForegroundGps',
      'canStartBackgroundGps',
      'canUseActivityRecognition',
      'canUseBatteryGuard',
      'canUseLowPowerGuard',
      'gpsUnavailable',
      'hasSafetySensors',
      'requiresManualStopReviewFallback',
    ]) {
      if (summary[key] is! bool) reasons.add('${key}_not_bool');
    }
    if (!_safeText(summary['safeStatus']) ||
        !_safeText(summary['dashboardBadge'], maxLength: 80) ||
        !_safeText(summary['degradationMode'], maxLength: 80) ||
        !_safeText(summary['stopDetectionAssistMode'], maxLength: 80)) {
      reasons.add('invalid_capability_display_text');
    }
    if (summary['gpsAssistRequiresOptIn'] != true ||
        summary['backgroundTrackingRequiresOptIn'] != true ||
        summary['activityRecognitionRequiresOptIn'] != true ||
        summary['batteryGuardRequiresOptIn'] != true ||
        summary['sensorAvailabilityRequiresRuntimePermission'] != true ||
        summary['capabilityReadDoesNotGrantPlatformPermission'] != true) {
      reasons.add('capability_permission_boundary_missing');
    }
    if (summary['capabilityReadDoesNotStartTracking'] != true ||
        summary['capabilityReadDoesNotGrantAuthorization'] != true ||
        summary['capabilityReadDoesNotGrantEmployerVisibility'] != true ||
        summary['remoteCapabilityCanEnableSensorsWithoutOptIn'] != false ||
        summary['deviceModelCanBeUsedAsSensorProof'] != false) {
      reasons.add('capability_can_enable_tracking');
    }
    if (summary['gpsTrackingCanRunWithoutMaps'] != true ||
        summary['mapsRequiredForTracking'] != false ||
        summary['routeHistoryRequiresLocationCapability'] != true ||
        summary['routeHistoryDisabledWhenGpsUnavailable'] != true) {
      reasons.add('map_tracking_boundary_missing');
    }
    if (summary['odometerRemainsCanonical'] != true ||
        summary['odometerIsGlobalTruth'] != true ||
        summary['nativeCapabilitiesAreAdvisory'] != true ||
        summary['deviceCapabilityCanReduceAccuracy'] != true ||
        summary['deviceCapabilityControlsSamplingTier'] != true ||
        summary['deviceCapabilityControlsStopAssistTier'] != true ||
        summary['locationOnlyModeRequiresMoreUserReview'] is! bool) {
      reasons.add('capability_truth_boundary_missing');
    }
    if (summary['rawNativePayloadIncluded'] != false ||
        summary['rawSensorPayloadIncluded'] != false ||
        summary['preciseLocationIncluded'] != false ||
        summary['tokensIncluded'] != false) {
      reasons.add('summary_contains_sensitive_capability_material');
    }
    if (summary.values.any(_looksSensitive)) {
      reasons.add('summary_contains_sensitive_text');
    }

    return TripTrackingCapabilityGuidanceSummaryValidation._(
      isRenderable: reasons.isEmpty,
      readiness: reasons.isEmpty ? readiness : null,
      reasons: List.unmodifiable(reasons),
    );
  }

  final bool isRenderable;
  final TripTrackingCapabilityReadiness? readiness;
  final List<String> reasons;
}

TripTrackingCapabilityReadiness? _safeReadiness(Object? value) {
  if (value is! String) return null;
  for (final readiness in TripTrackingCapabilityReadiness.values) {
    if (readiness.name == value) return readiness;
  }
  return null;
}

bool _safeText(Object? value, {int maxLength = 160}) {
  if (value is! String) return false;
  final clean = value.trim();
  if (clean.isEmpty || clean.length > maxLength) return false;
  final lower = clean.toLowerCase();
  return !lower.contains('token=') &&
      !lower.contains('pk.') &&
      !lower.contains('sk.') &&
      !lower.contains('lat=') &&
      !lower.contains('lng=') &&
      !lower.contains('longitude=');
}

bool _looksSensitive(Object? value) {
  if (value is! String) return false;
  final clean = value.trim();
  return clean.startsWith('pk.') ||
      clean.startsWith('sk.') ||
      clean.contains(RegExp(r'-?\d{1,3}\.\d{5,}'));
}

TripTrackingCapabilityReadiness _readinessFor({
  required TripTrackingPlatformCapabilities capabilities,
  required bool backgroundEnabled,
  required bool activityEnabled,
  required bool lowBatteryProtection,
}) {
  if (!capabilities.locationAvailable) {
    return TripTrackingCapabilityReadiness.unavailable;
  }
  if (activityEnabled &&
      lowBatteryProtection &&
      capabilities.lowPowerModeAvailable) {
    return TripTrackingCapabilityReadiness.fullSafetyAssist;
  }
  if (activityEnabled) return TripTrackingCapabilityReadiness.motionReady;
  if (backgroundEnabled) return TripTrackingCapabilityReadiness.backgroundReady;
  if (capabilities.locationAvailable) {
    return TripTrackingCapabilityReadiness.foregroundReady;
  }
  return TripTrackingCapabilityReadiness.locationOnly;
}

String _safeStatus(TripTrackingCapabilityReadiness readiness) {
  return switch (readiness) {
    TripTrackingCapabilityReadiness.unavailable =>
      'GPS tracking is unavailable on this device.',
    TripTrackingCapabilityReadiness.locationOnly =>
      'Location-only GPS assist is available.',
    TripTrackingCapabilityReadiness.foregroundReady =>
      'Foreground GPS assist is available.',
    TripTrackingCapabilityReadiness.backgroundReady =>
      'Background GPS assist is available when the user opts in.',
    TripTrackingCapabilityReadiness.motionReady =>
      'Motion-assisted stop review is available when the user opts in.',
    TripTrackingCapabilityReadiness.fullSafetyAssist =>
      'Motion and battery safety assist are available when the user opts in.',
  };
}

String _dashboardBadge(TripTrackingCapabilityReadiness readiness) {
  return switch (readiness) {
    TripTrackingCapabilityReadiness.unavailable => 'GPS unavailable',
    TripTrackingCapabilityReadiness.locationOnly => 'Location only',
    TripTrackingCapabilityReadiness.foregroundReady => 'Foreground GPS',
    TripTrackingCapabilityReadiness.backgroundReady => 'Background capable',
    TripTrackingCapabilityReadiness.motionReady => 'Motion capable',
    TripTrackingCapabilityReadiness.fullSafetyAssist => 'Motion + battery',
  };
}

String _degradationMode(TripTrackingCapabilityReadiness readiness) {
  return switch (readiness) {
    TripTrackingCapabilityReadiness.unavailable => 'tracking_unavailable',
    TripTrackingCapabilityReadiness.locationOnly ||
    TripTrackingCapabilityReadiness.foregroundReady =>
      'foreground_location_only',
    TripTrackingCapabilityReadiness.backgroundReady =>
      'background_location_without_motion',
    TripTrackingCapabilityReadiness.motionReady =>
      'motion_assisted_foreground_tracking',
    TripTrackingCapabilityReadiness.fullSafetyAssist =>
      'full_safety_assisted_tracking',
  };
}

String _stopDetectionAssistMode(TripTrackingCapabilityReadiness readiness) {
  return switch (readiness) {
    TripTrackingCapabilityReadiness.unavailable => 'manual_only',
    TripTrackingCapabilityReadiness.locationOnly ||
    TripTrackingCapabilityReadiness.foregroundReady ||
    TripTrackingCapabilityReadiness.backgroundReady =>
      'gps_dwell_review_required',
    TripTrackingCapabilityReadiness.motionReady ||
    TripTrackingCapabilityReadiness.fullSafetyAssist =>
      'gps_plus_motion_review_assist',
  };
}

bool _manualFallbackRequired(TripTrackingCapabilityReadiness readiness) {
  return switch (readiness) {
    TripTrackingCapabilityReadiness.unavailable ||
    TripTrackingCapabilityReadiness.locationOnly ||
    TripTrackingCapabilityReadiness.foregroundReady ||
    TripTrackingCapabilityReadiness.backgroundReady => true,
    TripTrackingCapabilityReadiness.motionReady ||
    TripTrackingCapabilityReadiness.fullSafetyAssist => false,
  };
}
