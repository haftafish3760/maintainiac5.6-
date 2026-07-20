class TripTrackingNativeErrorPolicy {
  const TripTrackingNativeErrorPolicy._();

  static bool requiresRecovery(String? errorCode) => switch (errorCode) {
    'trip_tracking_foreground_service_denied' ||
    'trip_tracking_location_registration_failed' ||
    'trip_tracking_location_denied' ||
    'trip_tracking_background_location_denied' ||
    'trip_tracking_location_accuracy_reduced' ||
    'trip_tracking_location_error' ||
    'trip_tracking_gps_unavailable' ||
    'trip_tracking_gps_disabled' ||
    'trip_tracking_battery_critical' => true,
    _ => false,
  };

  static bool isIgnorableMalformedPayload(String? errorCode) =>
      switch (errorCode) {
        'invalidLocationPayload' ||
        'invalidActivityPayload' ||
        'invalidNativeEventPayload' ||
        'invalidStatusPayload' => true,
        _ => false,
      };

  static String safeMessage(String? errorCode) => switch (errorCode) {
    'trip_tracking_foreground_service_denied' =>
      'GPS foreground service permission is required for this tracking mode.',
    'trip_tracking_location_registration_failed' =>
      'GPS location updates could not be registered by the device.',
    'trip_tracking_location_denied' =>
      'GPS location permission is required for trip tracking.',
    'trip_tracking_background_location_denied' =>
      'Background GPS permission was removed while tracking.',
    'trip_tracking_location_accuracy_reduced' =>
      'Precise GPS access was reduced while tracking.',
    'trip_tracking_location_error' =>
      'The device could not continue GPS trip tracking.',
    'trip_tracking_gps_unavailable' =>
      'GPS is unavailable on this device right now.',
    'trip_tracking_gps_disabled' => 'GPS was turned off while tracking.',
    'trip_tracking_battery_critical' =>
      'Battery is critically low. GPS-assisted tracking is paused below 10%.',
    'trip_tracking_activity_unavailable' =>
      'Walking-assisted stop evidence is unavailable. GPS tracking continues without it.',
    'trip_tracking_sampling_update_failed' =>
      'The device could not apply the requested GPS sampling change.',
    'trip_tracking_permission_busy' =>
      'Another GPS permission request is already in progress.',
    _ => 'GPS reported a device error.',
  };

  static Map<String, Object?> toSafeSummary(String? errorCode) {
    final recoverable = requiresRecovery(errorCode);
    final malformedPayload = isIgnorableMalformedPayload(errorCode);
    return {
      'schemaVersion': 1,
      'recoverable': recoverable,
      'ignorableMalformedPayload': malformedPayload,
      'safeMessage': safeMessage(errorCode),
      'nativeErrorCode': _safeErrorCode(errorCode),
      'gpsCanContinueOffline': malformedPayload,
      'requiresUserAction': recoverable,
      'failClosedForGpsStartup': recoverable,
      'externalNativeErrorTrustedAfterValidationOnly': true,
      'nativeErrorCanDeleteLocalTripData': false,
      'nativeErrorCanOverrideOdometer': false,
      'firestoreErrorCanOverrideGpsState': false,
      'mapboxServiceFailureStopsGpsTracking': false,
      'malformedNativeErrorFailsSafe': true,
      'malformedPayloadCanStopTrip': false,
      'rawNativePayloadIncluded': false,
      'preciseLocationIncluded': false,
      'tokensIncluded': false,
      'mapboxErrorCanCorruptTripLog': false,
      'odometerRemainsCanonical': true,
      'odometerIsGlobalTruth': true,
    };
  }
}

class TripTrackingNativeErrorSummaryValidation {
  const TripTrackingNativeErrorSummaryValidation._({
    required this.isRenderable,
    required this.reasons,
  });

  factory TripTrackingNativeErrorSummaryValidation.fromSummary(
    Map<String, Object?> summary,
  ) {
    final reasons = <String>[];
    if (summary['schemaVersion'] != 1) reasons.add('unsupported_schema');
    final nativeCode = summary['nativeErrorCode'];
    if (nativeCode is! String ||
        _safeErrorCode(nativeCode) != nativeCode ||
        _looksSensitive(nativeCode)) {
      reasons.add('invalid_native_error_code');
    }
    final safeMessage = summary['safeMessage'];
    if (safeMessage is! String ||
        safeMessage.trim().isEmpty ||
        _looksSensitive(safeMessage)) {
      reasons.add('invalid_native_error_message');
    }
    for (final key in const [
      'recoverable',
      'ignorableMalformedPayload',
      'gpsCanContinueOffline',
      'requiresUserAction',
      'failClosedForGpsStartup',
      'externalNativeErrorTrustedAfterValidationOnly',
      'nativeErrorCanDeleteLocalTripData',
      'nativeErrorCanOverrideOdometer',
      'firestoreErrorCanOverrideGpsState',
      'mapboxServiceFailureStopsGpsTracking',
      'malformedNativeErrorFailsSafe',
      'malformedPayloadCanStopTrip',
      'rawNativePayloadIncluded',
      'preciseLocationIncluded',
      'tokensIncluded',
      'mapboxErrorCanCorruptTripLog',
      'odometerRemainsCanonical',
      'odometerIsGlobalTruth',
    ]) {
      if (summary[key] is! bool) reasons.add('${key}_not_bool');
    }
    if (_nativeErrorBoundaryRisk(summary) != null) {
      reasons.add('native_error_status_conflicts_with_authority');
    }
    if (summary['externalNativeErrorTrustedAfterValidationOnly'] != true ||
        summary['malformedNativeErrorFailsSafe'] != true ||
        summary['malformedPayloadCanStopTrip'] != false ||
        summary['gpsCanContinueOffline'] == true &&
            summary['ignorableMalformedPayload'] != true) {
      reasons.add('native_error_validation_boundary_missing');
    }
    if (summary['nativeErrorCanDeleteLocalTripData'] != false ||
        summary['nativeErrorCanOverrideOdometer'] != false ||
        summary['firestoreErrorCanOverrideGpsState'] != false ||
        summary['mapboxServiceFailureStopsGpsTracking'] != false ||
        summary['mapboxErrorCanCorruptTripLog'] != false ||
        summary['odometerRemainsCanonical'] != true ||
        summary['odometerIsGlobalTruth'] != true) {
      reasons.add('native_error_can_mutate_trip_truth');
    }
    if (summary['rawNativePayloadIncluded'] != false ||
        summary['preciseLocationIncluded'] != false ||
        summary['tokensIncluded'] != false ||
        summary.values.any(_looksSensitive)) {
      reasons.add('summary_contains_sensitive_native_error_material');
    }
    return TripTrackingNativeErrorSummaryValidation._(
      isRenderable: reasons.isEmpty,
      reasons: List.unmodifiable(reasons),
    );
  }

  final bool isRenderable;
  final List<String> reasons;
}

String _safeErrorCode(String? value) {
  return switch (value?.trim()) {
    'trip_tracking_foreground_service_denied' =>
      'trip_tracking_foreground_service_denied',
    'trip_tracking_location_registration_failed' =>
      'trip_tracking_location_registration_failed',
    'trip_tracking_location_denied' => 'trip_tracking_location_denied',
    'trip_tracking_background_location_denied' =>
      'trip_tracking_background_location_denied',
    'trip_tracking_location_accuracy_reduced' =>
      'trip_tracking_location_accuracy_reduced',
    'trip_tracking_location_error' => 'trip_tracking_location_error',
    'trip_tracking_gps_unavailable' => 'trip_tracking_gps_unavailable',
    'trip_tracking_gps_disabled' => 'trip_tracking_gps_disabled',
    'trip_tracking_battery_critical' => 'trip_tracking_battery_critical',
    'trip_tracking_activity_unavailable' =>
      'trip_tracking_activity_unavailable',
    'invalidLocationPayload' => 'invalidLocationPayload',
    'invalidActivityPayload' => 'invalidActivityPayload',
    'invalidNativeEventPayload' => 'invalidNativeEventPayload',
    'invalidStatusPayload' => 'invalidStatusPayload',
    _ => 'unknown_native_gps_error',
  };
}

String? _nativeErrorBoundaryRisk(Map<String, Object?> summary) {
  final recoverable = summary['recoverable'];
  final malformed = summary['ignorableMalformedPayload'];
  final offline = summary['gpsCanContinueOffline'];
  final userAction = summary['requiresUserAction'];
  final failClosed = summary['failClosedForGpsStartup'];
  if (recoverable is! bool ||
      malformed is! bool ||
      offline is! bool ||
      userAction is! bool ||
      failClosed is! bool) {
    return null;
  }
  if (recoverable && (!userAction || !failClosed || offline)) return 'blocked';
  if (malformed && (recoverable || userAction || failClosed || !offline)) {
    return 'blocked';
  }
  return null;
}

bool _looksSensitive(Object? value) {
  if (value is! String) return false;
  final clean = value.toLowerCase();
  return clean.contains('pk.') ||
      clean.contains('sk.') ||
      clean.contains('token=') ||
      RegExp(r'-?\d{1,3}\.\d{4,}\s*,\s*-?\d{1,3}\.\d{4,}').hasMatch(clean);
}
