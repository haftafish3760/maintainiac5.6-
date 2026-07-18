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
    'doNotShowAgainStoredInLocalSettingsOnly': true,
    'settingsGearCanReverseChoice': true,
    'activeTripRemainsWritableAfterCancelGps': true,
    'localCheckpointRequiredBeforeGpsPause': true,
    'lowBatteryCanStopTextTripLog': false,
    'batteryActionCanDeleteTripRecords': false,
    'batteryActionCanConfirmMileage': false,
    'batteryActionCanCreateOfficialStop': false,
    'firebaseCanOverrideBatteryChoice': false,
    'mapboxCanOverrideBatteryChoice': false,
    'hiveRemainsOperationalSourceOfTruth': true,
    'odometerRemainsOfficialMileageTruth': true,
    'odometerIsGlobalTruth': true,
    'physicalOdometerRequiredForOfficialMileage': true,
    'confirmedOdometerOverridesExternalMileage': true,
    'externalMileageCannotBecomeGlobalTruth': true,
    'gpsDistanceCanOnlyAdviseMileageReview': true,
    'mapMatchingCanOnlyAdviseMileageReview': true,
    'optimizationCannotChangeOfficialMileage': true,
    'mapsRequiredForGps': false,
    'preciseBatteryIncluded': false,
    'rawBatteryPayloadIncluded': false,
    'tokensIncluded': false,
  };
}

class TripLowBatteryPromptActionSummaryValidation {
  const TripLowBatteryPromptActionSummaryValidation._({
    required this.isRenderable,
    required this.reasons,
  });

  factory TripLowBatteryPromptActionSummaryValidation.fromSummary(
    Map<String, Object?> summary,
  ) {
    final reasons = <String>[];
    if (summary['schemaVersion'] != 1) reasons.add('unsupported_schema');
    if (_safeStatus(summary['status']) == null) {
      reasons.add('invalid_battery_action_status');
    }
    if (_safeReason(summary['reasonCode']?.toString() ?? '') !=
        summary['reasonCode']) {
      reasons.add('invalid_battery_action_reason');
    }
    for (final key in const [
      'allowsGps',
      'nextOverrideEnabled',
      'nextWarningDismissed',
      'settingsReversalAvailable',
      'requiresActivePrompt',
      'doNotShowAgainAvailable',
      'dashboardSettingsCanRestorePrompt',
      'defaultGpsPausesBelowCutoff',
      'userOverrideRequiresExplicitChoice',
      'continueGpsDoesNotConfirmMileage',
      'cancelGpsOnlyPausesGpsSampling',
      'doNotShowAgainDoesNotRemoveSettingsReversal',
      'doNotShowAgainStoredInLocalSettingsOnly',
      'settingsGearCanReverseChoice',
      'activeTripRemainsWritableAfterCancelGps',
      'localCheckpointRequiredBeforeGpsPause',
      'lowBatteryCanStopTextTripLog',
      'batteryActionCanDeleteTripRecords',
      'batteryActionCanConfirmMileage',
      'batteryActionCanCreateOfficialStop',
      'firebaseCanOverrideBatteryChoice',
      'mapboxCanOverrideBatteryChoice',
      'hiveRemainsOperationalSourceOfTruth',
      'odometerRemainsOfficialMileageTruth',
      'odometerIsGlobalTruth',
      'physicalOdometerRequiredForOfficialMileage',
      'confirmedOdometerOverridesExternalMileage',
      'externalMileageCannotBecomeGlobalTruth',
      'gpsDistanceCanOnlyAdviseMileageReview',
      'mapMatchingCanOnlyAdviseMileageReview',
      'optimizationCannotChangeOfficialMileage',
      'mapsRequiredForGps',
      'preciseBatteryIncluded',
      'rawBatteryPayloadIncluded',
      'tokensIncluded',
    ]) {
      if (summary[key] is! bool) reasons.add('${key}_not_bool');
    }
    if (summary['continueGpsActionLabel'] != 'Continue with GPS' ||
        summary['cancelGpsActionLabel'] != 'Cancel GPS') {
      reasons.add('invalid_action_labels');
    }
    if (summary['status'] == 'blocked' && summary['allowsGps'] != false) {
      reasons.add('blocked_action_allows_gps');
    }
    if (summary['dashboardSettingsCanRestorePrompt'] != true ||
        summary['settingsReversalAvailable'] != true ||
        summary['doNotShowAgainDoesNotRemoveSettingsReversal'] != true ||
        summary['doNotShowAgainStoredInLocalSettingsOnly'] != true ||
        summary['settingsGearCanReverseChoice'] != true ||
        summary['userOverrideRequiresExplicitChoice'] != true) {
      reasons.add('battery_settings_reversal_boundary_missing');
    }
    if (summary['continueGpsDoesNotConfirmMileage'] != true ||
        summary['cancelGpsOnlyPausesGpsSampling'] != true ||
        summary['activeTripRemainsWritableAfterCancelGps'] != true ||
        summary['localCheckpointRequiredBeforeGpsPause'] != true ||
        summary['lowBatteryCanStopTextTripLog'] != false ||
        summary['batteryActionCanDeleteTripRecords'] != false ||
        summary['batteryActionCanConfirmMileage'] != false ||
        summary['batteryActionCanCreateOfficialStop'] != false ||
        summary['odometerRemainsOfficialMileageTruth'] != true ||
        summary['odometerIsGlobalTruth'] != true ||
        summary['physicalOdometerRequiredForOfficialMileage'] != true ||
        summary['confirmedOdometerOverridesExternalMileage'] != true ||
        summary['externalMileageCannotBecomeGlobalTruth'] != true ||
        summary['gpsDistanceCanOnlyAdviseMileageReview'] != true ||
        summary['mapMatchingCanOnlyAdviseMileageReview'] != true ||
        summary['optimizationCannotChangeOfficialMileage'] != true) {
      reasons.add('battery_action_claims_trip_truth');
    }
    if (summary['firebaseCanOverrideBatteryChoice'] != false ||
        summary['mapboxCanOverrideBatteryChoice'] != false ||
        summary['hiveRemainsOperationalSourceOfTruth'] != true) {
      reasons.add('remote_can_override_battery_action');
    }
    if (summary['mapsRequiredForGps'] != false ||
        summary['preciseBatteryIncluded'] != false ||
        summary['rawBatteryPayloadIncluded'] != false ||
        summary['tokensIncluded'] != false ||
        summary.values.any(_looksSensitive)) {
      reasons.add('summary_contains_sensitive_battery_action_material');
    }
    return TripLowBatteryPromptActionSummaryValidation._(
      isRenderable: reasons.isEmpty,
      reasons: List.unmodifiable(reasons),
    );
  }

  final bool isRenderable;
  final List<String> reasons;
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

TripLowBatteryPromptActionStatus? _safeStatus(Object? value) {
  if (value is! String) return null;
  for (final status in TripLowBatteryPromptActionStatus.values) {
    if (status.name == value) return status;
  }
  return null;
}

bool _looksSensitive(Object? value) {
  if (value is! String) return false;
  final clean = value.trim();
  return clean.startsWith('pk.') ||
      clean.startsWith('sk.') ||
      clean.contains('token=') ||
      RegExp(r'\b\d{1,3}%\b').hasMatch(clean);
}
