import 'trip_tracking_policy.dart';

enum TripLowBatteryPromptAction {
  continueGps,
  cancelGps,
  continueGpsDoNotShowAgain,
  cancelGpsDoNotShowAgain,
  restorePromptInSettings,
}

enum TripLowBatteryPromptActionStatus { allowed, blocked }

class TripLowBatteryPromptActionDecision {
  const TripLowBatteryPromptActionDecision({
    required this.status,
    required this.reasonCode,
    required this.allowsGps,
    required this.nextOverrideEnabled,
    required this.nextWarningDismissed,
    required this.settingsReversalAvailable,
    required this.requiresActivePrompt,
  });

  final TripLowBatteryPromptActionStatus status;
  final String reasonCode;
  final bool allowsGps;
  final bool nextOverrideEnabled;
  final bool nextWarningDismissed;
  final bool settingsReversalAvailable;
  final bool requiresActivePrompt;

  Map<String, Object?> toSafeSummary() => {
    'schemaVersion': 1,
    'status': status.name,
    'reasonCode': _safeReason(reasonCode),
    'allowsGps':
        status == TripLowBatteryPromptActionStatus.allowed && allowsGps,
    'nextOverrideEnabled': nextOverrideEnabled,
    'nextWarningDismissed': nextWarningDismissed,
    'settingsReversalAvailable': settingsReversalAvailable,
    'requiresActivePrompt': requiresActivePrompt,
    'continueGpsActionLabel': 'Continue with GPS',
    'cancelGpsActionLabel': 'Cancel GPS',
    'doNotShowAgainAvailable': requiresActivePrompt,
    'dashboardSettingsCanRestorePrompt': true,
    'defaultGpsPausesBelowCutoff': true,
    'userOverrideRequiresExplicitChoice': true,
    'continueGpsDoesNotConfirmMileage': true,
    'cancelGpsOnlyPausesGpsSampling': true,
    'doNotShowAgainDoesNotRemoveSettingsReversal': true,
    'lowBatteryCanStopTextTripLog': false,
    'batteryActionCanDeleteTripRecords': false,
    'batteryActionCanConfirmMileage': false,
    'batteryActionCanCreateOfficialStop': false,
    'firebaseCanOverrideBatteryChoice': false,
    'mapboxCanOverrideBatteryChoice': false,
    'hiveRemainsOperationalSourceOfTruth': true,
    'odometerRemainsOfficialMileageTruth': true,
    'mapsRequiredForGps': false,
    'preciseBatteryIncluded': false,
    'rawBatteryPayloadIncluded': false,
    'tokensIncluded': false,
  };
}

class TripLowBatteryPromptActionPolicy {
  const TripLowBatteryPromptActionPolicy._();

  static TripLowBatteryPromptActionDecision evaluate({
    required TripGpsBatteryDecision currentDecision,
    required TripLowBatteryPromptAction action,
  }) {
    if (action == TripLowBatteryPromptAction.restorePromptInSettings) {
      return const TripLowBatteryPromptActionDecision(
        status: TripLowBatteryPromptActionStatus.allowed,
        reasonCode: 'battery_prompt_restored_in_settings',
        allowsGps: false,
        nextOverrideEnabled: false,
        nextWarningDismissed: false,
        settingsReversalAvailable: true,
        requiresActivePrompt: false,
      );
    }
    if (!currentDecision.requiresUserChoice) {
      return const TripLowBatteryPromptActionDecision(
        status: TripLowBatteryPromptActionStatus.blocked,
        reasonCode: 'active_battery_prompt_required',
        allowsGps: false,
        nextOverrideEnabled: false,
        nextWarningDismissed: false,
        settingsReversalAvailable: true,
        requiresActivePrompt: true,
      );
    }
    return switch (action) {
      TripLowBatteryPromptAction.continueGps =>
        const TripLowBatteryPromptActionDecision(
          status: TripLowBatteryPromptActionStatus.allowed,
          reasonCode: 'continue_gps_for_current_low_battery_session',
          allowsGps: true,
          nextOverrideEnabled: true,
          nextWarningDismissed: false,
          settingsReversalAvailable: true,
          requiresActivePrompt: true,
        ),
      TripLowBatteryPromptAction.cancelGps =>
        const TripLowBatteryPromptActionDecision(
          status: TripLowBatteryPromptActionStatus.allowed,
          reasonCode: 'cancel_gps_for_current_low_battery_session',
          allowsGps: false,
          nextOverrideEnabled: false,
          nextWarningDismissed: false,
          settingsReversalAvailable: true,
          requiresActivePrompt: true,
        ),
      TripLowBatteryPromptAction.continueGpsDoNotShowAgain =>
        const TripLowBatteryPromptActionDecision(
          status: TripLowBatteryPromptActionStatus.allowed,
          reasonCode: 'continue_gps_and_remember_low_battery_choice',
          allowsGps: true,
          nextOverrideEnabled: true,
          nextWarningDismissed: true,
          settingsReversalAvailable: true,
          requiresActivePrompt: true,
        ),
      TripLowBatteryPromptAction.cancelGpsDoNotShowAgain =>
        const TripLowBatteryPromptActionDecision(
          status: TripLowBatteryPromptActionStatus.allowed,
          reasonCode: 'cancel_gps_and_remember_low_battery_choice',
          allowsGps: false,
          nextOverrideEnabled: false,
          nextWarningDismissed: true,
          settingsReversalAvailable: true,
          requiresActivePrompt: true,
        ),
      TripLowBatteryPromptAction.restorePromptInSettings => throw StateError(
        'handled above',
      ),
    };
  }
}

String _safeReason(String value) {
  final clean = value.trim();
  return switch (clean) {
    'battery_prompt_restored_in_settings' ||
    'active_battery_prompt_required' ||
    'continue_gps_for_current_low_battery_session' ||
    'cancel_gps_for_current_low_battery_session' ||
    'continue_gps_and_remember_low_battery_choice' ||
    'cancel_gps_and_remember_low_battery_choice' => clean,
    _ => 'active_battery_prompt_required',
  };
}
