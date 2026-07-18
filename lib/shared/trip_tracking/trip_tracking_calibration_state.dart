import 'trip_tracking_odometer_calibration.dart';

class TripTrackingCalibrationState {
  const TripTrackingCalibrationState({
    required this.enabled,
    required this.multiplier,
  });

  factory TripTrackingCalibrationState.initial(double multiplier) =>
      TripTrackingCalibrationState(
        enabled: false,
        multiplier: safeMultiplier(multiplier),
      );

  final bool enabled;
  final double multiplier;

  TripTrackingCalibrationState refresh({
    required bool enabled,
    required TripOdometerCalibrationSignal signal,
  }) {
    final nextMultiplier = enabled
        ? safeMultiplier(signal.gpsAssistanceCalibrationMultiplier)
        : 1.0;
    if (this.enabled == enabled && multiplier == nextMultiplier) {
      return this;
    }
    return TripTrackingCalibrationState(
      enabled: enabled,
      multiplier: nextMultiplier,
    );
  }

  TripTrackingCalibrationState refreshEnabled(
    TripOdometerCalibrationSignal signal,
  ) {
    if (!enabled) return this;
    return refresh(enabled: true, signal: signal);
  }

  Map<String, Object?> toSafeSummary() => {
    'schemaVersion': 1,
    'enabled': enabled,
    'multiplier': multiplier,
    'advisoryOnly': true,
    'requiresReviewedOdometerHistory': true,
    'continuousCalibrationAverageRequired': true,
    'poorGpsDaysExcludedFromCalibration': true,
    'calibrationRequiresTrustedGpsWindow': true,
    'calibrationRequiresTrustedSignalDiagnostics': true,
    'unknownSignalDiagnosticsFailNeutralInController': true,
    'poorGpsDaysCannotCountAsTrustedWindow': true,
    'unknownSignalDiagnosticsCannotCountAsTrustedWindow': true,
    'unknownSignalDiagnosticsExcludedByDefault': true,
    'excludedPoorGpsCannotBecomeCalibrationProof': true,
    'singleDayCalibrationRejected': true,
    'calibrationRequiresVehicleScopedHistory': true,
    'settingsCanDisableCalibrationAssist': true,
    'settingsCanResetCalibrationPrompt': true,
    'calibrationCanReplaceConfirmedOdometer': false,
    'calibrationCanSetGlobalTruth': false,
    'calibrationCanChangeGlobalTruth': false,
    'calibrationCanConfirmOfficialMileage': false,
    'calibrationCanRewritePastTrips': false,
    'calibrationCanLowerConfirmedOdometer': false,
    'calibrationCanCreateMaintenanceRecord': false,
    'calibrationAppliesToFutureGpsProjectionOnly': true,
    'gpsEstimateRemainsNonCanonical': true,
    'odometerIsGlobalTruth': true,
    'odometerRemainsCanonical': true,
    'remoteCalibrationCanOverrideLocalState': false,
    'remoteCalibrationCanEnableSetting': false,
    'remoteCalibrationCanResetPrompt': false,
    'mapboxCanOverrideCalibration': false,
    'mapboxCanTriggerTirePrompt': false,
    'gpsCanAutoApplyCalibration': false,
    'malformedCalibrationSignalFailsNeutral': true,
    'rawGpsIncluded': false,
    'preciseLocationIncluded': false,
    'tokensIncluded': false,
  };

  static double safeMultiplier(double value) {
    if (!value.isFinite || value <= 0) return 1;
    return value.clamp(0.8, 1.25).toDouble();
  }
}
