import 'trip_tracking_models.dart';

enum TripGpsBatteryDecisionStatus { allowed, userPromptRequired, blocked }

class TripGpsBatteryDecision {
  const TripGpsBatteryDecision({
    required this.status,
    required this.reasonCode,
  });

  final TripGpsBatteryDecisionStatus status;
  final String reasonCode;

  bool get allowsGps => status == TripGpsBatteryDecisionStatus.allowed;
}

class TripTrackingPolicy {
  const TripTrackingPolicy({
    this.precisionSpeedMetersPerSecond = 6.7056,
    this.precisionExitSpeedMetersPerSecond = 5.6,
    this.lowSpeedMovementMetersPerSecond = 0.8,
    this.maximumHorizontalAccuracyMeters = 65,
    this.maximumPlausibleSpeedMetersPerSecond = 75,
    this.maximumReportedSpeedDisagreementMetersPerSecond = 25,
    this.maximumGap = const Duration(minutes: 2),
    this.maximumFutureSampleSkew = const Duration(minutes: 2),
    this.minimumMovementMeters = 5,
    this.accuracyEnvelopeMultiplier = 1.25,
    this.walkingConfirmationCount = 3,
    this.walkingConfirmationWindow = const Duration(seconds: 45),
    this.walkingStopConfirmationDuration = const Duration(seconds: 20),
    this.lowBatteryGpsCutoffPercent = 20,
  });

  /// Fifteen mph. At or above this speed the requested two-second precision
  /// profile becomes appropriate; it is deliberately not the startup default.
  final double precisionSpeedMetersPerSecond;

  /// Lower exit threshold avoids battery-costly mode flapping around 15 mph.
  final double precisionExitSpeedMetersPerSecond;
  final double lowSpeedMovementMetersPerSecond;
  final double maximumHorizontalAccuracyMeters;
  final double maximumPlausibleSpeedMetersPerSecond;
  final double maximumReportedSpeedDisagreementMetersPerSecond;
  final Duration maximumGap;

  /// Native timestamps beyond this wall-clock tolerance are held out of the
  /// live trip. A device clock correction must never make future movement look
  /// like accepted mileage.
  final Duration maximumFutureSampleSkew;
  final double minimumMovementMeters;
  final double accuracyEnvelopeMultiplier;
  final int walkingConfirmationCount;
  final Duration walkingConfirmationWindow;

  /// A fitness-motion classification is only an advisory stop clue after this
  /// much corroborating time; one classification must not become a stop.
  final Duration walkingStopConfirmationDuration;
  final int lowBatteryGpsCutoffPercent;

  TripGpsBatteryDecision gpsBatteryDecision({
    required int? batteryPercent,
    required bool isCharging,
    required bool lowBatteryProtectionEnabled,
    required bool lowBatteryOverrideEnabled,
    required bool lowBatteryWarningDismissed,
  }) {
    if (!lowBatteryProtectionEnabled) {
      return const TripGpsBatteryDecision(
        status: TripGpsBatteryDecisionStatus.allowed,
        reasonCode: 'battery_protection_disabled',
      );
    }
    if (isCharging) {
      return const TripGpsBatteryDecision(
        status: TripGpsBatteryDecisionStatus.allowed,
        reasonCode: 'device_charging',
      );
    }
    final percent = batteryPercent;
    if (percent == null || percent < 0 || percent > 100) {
      return const TripGpsBatteryDecision(
        status: TripGpsBatteryDecisionStatus.allowed,
        reasonCode: 'battery_unknown',
      );
    }
    final cutoff =
        lowBatteryGpsCutoffPercent >= 0 && lowBatteryGpsCutoffPercent <= 100
        ? lowBatteryGpsCutoffPercent
        : 20;
    if (percent >= cutoff) {
      return const TripGpsBatteryDecision(
        status: TripGpsBatteryDecisionStatus.allowed,
        reasonCode: 'battery_above_cutoff',
      );
    }
    if (lowBatteryOverrideEnabled) {
      return const TripGpsBatteryDecision(
        status: TripGpsBatteryDecisionStatus.allowed,
        reasonCode: 'user_override_low_battery',
      );
    }
    if (lowBatteryWarningDismissed) {
      return const TripGpsBatteryDecision(
        status: TripGpsBatteryDecisionStatus.blocked,
        reasonCode: 'low_battery_gps_blocked_by_saved_choice',
      );
    }
    return const TripGpsBatteryDecision(
      status: TripGpsBatteryDecisionStatus.userPromptRequired,
      reasonCode: 'low_battery_requires_user_choice',
    );
  }

  TripSamplingRecommendation samplingFor({
    required double? speedMetersPerSecond,
    required bool vehicleMovementConfirmed,
    TripTrackingProfile profile = TripTrackingProfile.roadVehicle,
    TripSamplingMode? currentMode,
    bool activeTrip = false,
  }) {
    final reportedSpeed = speedMetersPerSecond ?? 0;
    final speed = reportedSpeed.isFinite && reportedSpeed >= 0
        ? reportedSpeed
        : 0.0;
    final remainPrecision =
        currentMode == TripSamplingMode.precision &&
        speed >= precisionExitSpeedMetersPerSecond;
    if (vehicleMovementConfirmed &&
        (speed >= precisionSpeedMetersPerSecond || remainPrecision)) {
      return const TripSamplingRecommendation(
        mode: TripSamplingMode.precision,
        interval: Duration(seconds: 2),
        minimumDisplacementMeters: 3,
      );
    }
    if (activeTrip ||
        vehicleMovementConfirmed ||
        speed >= lowSpeedMovementMetersPerSecond ||
        profile == TripTrackingProfile.lowSpeedEquipment) {
      return const TripSamplingRecommendation(
        mode: TripSamplingMode.balanced,
        interval: Duration(seconds: 5),
        minimumDisplacementMeters: 5,
      );
    }
    return const TripSamplingRecommendation(
      mode: TripSamplingMode.economy,
      interval: Duration(seconds: 30),
      minimumDisplacementMeters: 20,
    );
  }
}
