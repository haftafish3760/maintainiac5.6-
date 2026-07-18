class TripTrackingNativeErrorPolicy {
  const TripTrackingNativeErrorPolicy._();

  static bool requiresRecovery(String? errorCode) => switch (errorCode) {
    'trip_tracking_foreground_service_denied' ||
    'trip_tracking_location_registration_failed' ||
    'trip_tracking_location_denied' ||
    'trip_tracking_gps_unavailable' ||
    'trip_tracking_gps_disabled' => true,
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
    'trip_tracking_gps_unavailable' =>
      'GPS is unavailable on this device right now.',
    'trip_tracking_gps_disabled' => 'GPS was turned off while tracking.',
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
      'malformedPayloadCanStopTrip': false,
      'rawNativePayloadIncluded': false,
      'preciseLocationIncluded': false,
      'tokensIncluded': false,
      'mapboxErrorCanCorruptTripLog': false,
      'odometerRemainsCanonical': true,
    };
  }
}

String _safeErrorCode(String? value) {
  return switch (value?.trim()) {
    'trip_tracking_foreground_service_denied' =>
      'trip_tracking_foreground_service_denied',
    'trip_tracking_location_registration_failed' =>
      'trip_tracking_location_registration_failed',
    'trip_tracking_location_denied' => 'trip_tracking_location_denied',
    'trip_tracking_gps_unavailable' => 'trip_tracking_gps_unavailable',
    'trip_tracking_gps_disabled' => 'trip_tracking_gps_disabled',
    'invalidLocationPayload' => 'invalidLocationPayload',
    'invalidActivityPayload' => 'invalidActivityPayload',
    'invalidNativeEventPayload' => 'invalidNativeEventPayload',
    'invalidStatusPayload' => 'invalidStatusPayload',
    _ => 'unknown_native_gps_error',
  };
}
