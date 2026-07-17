import 'trip_tracking_models.dart';

enum TripGpsBatteryDecisionStatus { allowed, userPromptRequired, blocked }

class TripGpsBatteryDecision {
  const TripGpsBatteryDecision({
    required this.status,
    required this.reasonCode,
    required this.batteryBucket,
    required this.promptTitle,
    required this.promptBody,
  });

  final TripGpsBatteryDecisionStatus status;
  final String reasonCode;
  final String batteryBucket;
  final String promptTitle;
  final String promptBody;

  bool get allowsGps => status == TripGpsBatteryDecisionStatus.allowed;
  bool get requiresUserChoice =>
      status == TripGpsBatteryDecisionStatus.userPromptRequired;
  bool get isSavedBlock => status == TripGpsBatteryDecisionStatus.blocked;

  Map<String, Object?> toSafeSummary() => {
    'status': status.name,
    'reasonCode': reasonCode,
    'batteryBucket': batteryBucket,
    'promptTitle': promptTitle,
    'promptBody': promptBody,
    'allowsGps': allowsGps,
    'requiresUserChoice': requiresUserChoice,
    'preciseBatteryIncluded': false,
  };
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
    bool lowPowerModeEnabled = false,
    required bool lowBatteryProtectionEnabled,
    required bool lowBatteryOverrideEnabled,
    required bool lowBatteryWarningDismissed,
  }) {
    if (!lowBatteryProtectionEnabled) {
      return _batteryDecision(
        status: TripGpsBatteryDecisionStatus.allowed,
        reasonCode: 'battery_protection_disabled',
        batteryPercent: batteryPercent,
      );
    }
    if (isCharging) {
      return _batteryDecision(
        status: TripGpsBatteryDecisionStatus.allowed,
        reasonCode: 'device_charging',
        batteryPercent: batteryPercent,
      );
    }
    final percent = batteryPercent;
    final cutoff =
        lowBatteryGpsCutoffPercent >= 1 && lowBatteryGpsCutoffPercent <= 100
        ? lowBatteryGpsCutoffPercent
        : 20;
    if (percent != null && percent >= 0 && percent < cutoff) {
      if (lowBatteryOverrideEnabled) {
        return _batteryDecision(
          status: TripGpsBatteryDecisionStatus.allowed,
          reasonCode: 'user_override_low_battery',
          batteryPercent: percent,
        );
      }
      if (lowBatteryWarningDismissed) {
        return _batteryDecision(
          status: TripGpsBatteryDecisionStatus.blocked,
          reasonCode: 'low_battery_gps_blocked_by_saved_choice',
          batteryPercent: percent,
        );
      }
      return _batteryDecision(
        status: TripGpsBatteryDecisionStatus.userPromptRequired,
        reasonCode: 'low_battery_requires_user_choice',
        batteryPercent: percent,
      );
    }
    if (lowPowerModeEnabled) {
      if (lowBatteryOverrideEnabled) {
        return _batteryDecision(
          status: TripGpsBatteryDecisionStatus.allowed,
          reasonCode: 'user_override_low_power_mode',
          batteryPercent: percent,
        );
      }
      if (lowBatteryWarningDismissed) {
        return _batteryDecision(
          status: TripGpsBatteryDecisionStatus.blocked,
          reasonCode: 'low_power_mode_gps_blocked_by_saved_choice',
          batteryPercent: percent,
        );
      }
      return _batteryDecision(
        status: TripGpsBatteryDecisionStatus.userPromptRequired,
        reasonCode: 'low_power_mode_requires_user_choice',
        batteryPercent: percent,
      );
    }
    if (percent == null || percent < 0 || percent > 100) {
      return _batteryDecision(
        status: TripGpsBatteryDecisionStatus.allowed,
        reasonCode: 'battery_unknown',
        batteryPercent: percent,
      );
    }
    if (percent >= cutoff) {
      return _batteryDecision(
        status: TripGpsBatteryDecisionStatus.allowed,
        reasonCode: 'battery_above_cutoff',
        batteryPercent: percent,
      );
    }
    return _batteryDecision(
      status: TripGpsBatteryDecisionStatus.allowed,
      reasonCode: 'battery_unknown',
      batteryPercent: percent,
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
    final precisionSpeed = _safePositiveDouble(
      precisionSpeedMetersPerSecond,
      fallback: 6.7056,
    );
    final precisionExitSpeed = _safePositiveDouble(
      precisionExitSpeedMetersPerSecond,
      fallback: 5.6,
    );
    final lowSpeedMovement = _safePositiveDouble(
      lowSpeedMovementMetersPerSecond,
      fallback: 0.8,
    );
    final remainPrecision =
        currentMode == TripSamplingMode.precision &&
        speed >= precisionExitSpeed;
    if (vehicleMovementConfirmed &&
        (speed >= precisionSpeed || remainPrecision)) {
      return const TripSamplingRecommendation(
        mode: TripSamplingMode.precision,
        interval: Duration(seconds: 2),
        minimumDisplacementMeters: 3,
      );
    }
    if (activeTrip ||
        vehicleMovementConfirmed ||
        speed >= lowSpeedMovement ||
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

TripGpsBatteryDecision _batteryDecision({
  required TripGpsBatteryDecisionStatus status,
  required String reasonCode,
  required int? batteryPercent,
}) {
  return TripGpsBatteryDecision(
    status: status,
    reasonCode: reasonCode,
    batteryBucket: _batteryBucket(batteryPercent),
    promptTitle: _batteryPromptTitle(reasonCode),
    promptBody: _batteryPromptBody(reasonCode),
  );
}

String _batteryBucket(int? percent) {
  if (percent == null || percent < 0 || percent > 100) return 'unknown';
  if (percent < 20) return 'below_20';
  if (percent < 50) return '20_to_49';
  return '50_plus';
}

String _batteryPromptTitle(String reasonCode) {
  return switch (reasonCode) {
    'low_battery_requires_user_choice' ||
    'low_battery_gps_blocked_by_saved_choice' => 'Battery below 20%',
    'low_power_mode_requires_user_choice' ||
    'low_power_mode_gps_blocked_by_saved_choice' => 'Battery saver is active',
    _ => 'GPS battery guard',
  };
}

String _batteryPromptBody(String reasonCode) {
  return switch (reasonCode) {
    'low_battery_requires_user_choice' =>
      'GPS-assisted tracking is paused by default below the safety threshold. Continue only if you want GPS to keep running.',
    'low_battery_gps_blocked_by_saved_choice' =>
      'GPS-assisted tracking is blocked by your saved low-battery choice. You can reverse this in dashboard settings.',
    'low_power_mode_requires_user_choice' =>
      'Battery saver may limit GPS reliability. Continue only if you want GPS to keep running.',
    'low_power_mode_gps_blocked_by_saved_choice' =>
      'GPS-assisted tracking is blocked by your saved battery-saver choice. You can reverse this in dashboard settings.',
    'user_override_low_battery' || 'user_override_low_power_mode' =>
      'GPS is continuing because you opted in to bypass the battery guard.',
    _ => 'GPS battery guard did not block tracking.',
  };
}

double _safePositiveDouble(double value, {required double fallback}) =>
    value.isFinite && value > 0 ? value : fallback;
