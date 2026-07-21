import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../shared/firebase/maintainiac_auth_service.dart';
import '../../shared/trip_tracking/trip_tracking_models.dart';
import '../../shared/trip_tracking/trip_tracking_controller.dart';
import '../../shared/trip_tracking/trip_tracking_settings_store.dart';
import '../../shared/profiles/user_profile_store.dart';
import '../../shared/widgets/app_screen_shell.dart';
import 'trip_tracking_gps_opt_in_flow.dart';

part 'trip_tracking_settings_map_controls.dart';
part 'trip_tracking_settings_account_panel.dart';

/// Shared preference surface opened from both Dashboard Settings and Menu.
class TripTrackingSettingsScreen extends StatelessWidget {
  const TripTrackingSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TripTrackingSettingsScope.of(context);
    final tripTracking = TripTrackingScope.maybeOf(context);
    final settings = controller.settings;
    final userProfiles = UserProfileScope.maybeOf(context);
    return AppScreenShell(
      section: AppSection.dashboard,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 22),
        children: [
          const GlobalOdometerHeader(),
          const SizedBox(height: 12),
          if (Firebase.apps.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: _FirebaseBackupAccountPanel(),
            ),
            const SizedBox(height: 8),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _TripTrackingSettingsPanel(
              settings: settings,
              onChanged: controller.update,
              tripTracking: tripTracking,
              cloudBackupEnabled:
                  userProfiles?.activeProfile.cloudBackupEnabled ?? false,
              onCloudBackupChanged: userProfiles == null
                  ? null
                  : (enabled) => userProfiles.saveActiveProfile(
                      userProfiles.activeProfile.copyWith(
                        cloudBackupEnabled: enabled,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TripTrackingSettingsPanel extends StatelessWidget {
  const _TripTrackingSettingsPanel({
    required this.settings,
    required this.onChanged,
    required this.tripTracking,
    required this.cloudBackupEnabled,
    required this.onCloudBackupChanged,
  });

  final TripTrackingSettings settings;
  final ValueChanged<TripTrackingSettings> onChanged;
  final TripTrackingController? tripTracking;
  final bool cloudBackupEnabled;
  final ValueChanged<bool>? onCloudBackupChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF172023),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF5D6A71)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'GPS-Assisted Trip Tracking',
            style: TextStyle(
              color: Color(0xFFE2E8EA),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Location stays on this device for active-trip recovery and review. It does not start until you choose Start GPS Trip.',
            style: TextStyle(
              color: Color(0xFFCAD2D5),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          _switch(
            title: 'Back up reviewed mileage',
            detail:
                'Off by default. Turning it off cancels unsent backup. Only reviewed mileage summaries are backed up; GPS coordinates, routes, raw samples, and live location never leave this device.',
            value: cloudBackupEnabled,
            onChanged: onCloudBackupChanged ?? (_) {},
          ),
          _switch(
            title: 'Share reviewed mileage summaries with organization',
            detail:
                'Off by default. Turn this on only when you agree to share reviewed mileage totals with your organization. GPS coordinates, routes, and live location are never shared.',
            value: settings.organizationMileageSharingEnabled,
            onChanged: (value) => onChanged(
              settings.copyWith(organizationMileageSharingEnabled: value),
            ),
          ),
          _choice<TripTrackingBackupNetworkPolicy>(
            title: 'Mileage backup network',
            value: settings.backupNetworkPolicy,
            items: TripTrackingBackupNetworkPolicy.values,
            label: _backupNetworkPolicyLabel,
            onChanged: (value) =>
                onChanged(settings.copyWith(backupNetworkPolicy: value)),
          ),
          _switch(
            title: 'Enable GPS-assisted tracking',
            detail:
                'Keep the manual trip and odometer workflow available even when this is off.',
            value: settings.gpsAssistedTrackingEnabled,
            onChanged: (value) => updateGpsAssistedTrackingOptIn(
              context: context,
              settings: settings,
              onChanged: onChanged,
              enabled: value,
            ),
          ),
          _switch(
            title: 'Show optional maps',
            detail: settings.gpsAssistedTrackingEnabled
                ? 'Separate opt-in. GPS-assisted trip tracking still works without maps, route drawing, or map storage.'
                : 'Enable GPS-assisted tracking first. Maps are optional and never required for mileage tracking.',
            value: settings.mapPreviewEnabled,
            onChanged: settings.gpsAssistedTrackingEnabled
                ? (value) => onChanged(
                    settings.copyWith(
                      mapPreviewEnabled: value,
                      mapRouteHistorySavingEnabled: value
                          ? settings.mapRouteHistorySavingEnabled
                          : false,
                    ),
                  )
                : null,
          ),
          _switch(
            title: 'Save optional map route history',
            detail: settings.mapPreviewEnabled
                ? 'Separate opt-in. Saves a bounded route preview for the day; odometer readings remain the official mileage truth.'
                : 'Turn on optional maps first. Route history is never enabled by GPS alone.',
            value: settings.mapRouteHistorySavingEnabled,
            onChanged: settings.mapPreviewEnabled
                ? (value) => onChanged(
                    settings.copyWith(
                      mapRouteHistorySavingEnabled: value,
                      mapRouteHistoryDailyBudgetMb: value
                          ? _defaultMapBudgetMb(settings)
                          : settings.mapRouteHistoryDailyBudgetMb,
                      mapRouteHistorySampleIntervalSeconds: value
                          ? _defaultMapSampleIntervalSeconds(settings)
                          : settings.mapRouteHistorySampleIntervalSeconds,
                    ),
                  )
                : null,
          ),
          if (settings.mapPreviewEnabled) _mapRouteHistoryControls(settings),
          _switch(
            title: 'Continue during an active background trip',
            detail: settings.gpsAssistedTrackingEnabled
                ? 'Off by default. Without it, GPS stops when the app is backgrounded. Requests the extra location permission only when you start a trip with this enabled.'
                : 'Enable GPS-assisted tracking before allowing a trip to continue in the background.',
            value: settings.backgroundTrackingEnabled,
            onChanged: settings.gpsAssistedTrackingEnabled
                ? (value) => onChanged(
                    settings.copyWith(backgroundTrackingEnabled: value),
                  )
                : null,
          ),
          _switch(
            title: 'Protect GPS below 20% battery',
            detail:
                'On by default. Below 20%, GPS asks before continuing. Below 10%, GPS stays off to preserve emergency battery.',
            value: settings.lowBatteryGpsProtectionEnabled,
            onChanged: (value) => onChanged(
              settings.copyWith(lowBatteryGpsProtectionEnabled: value),
            ),
          ),
          _switch(
            title: 'Allow GPS below 20% battery',
            detail:
                'Off by default. This can continue GPS from 10% to 19% when you accept the battery drain risk; GPS remains off below 10%.',
            value: settings.lowBatteryGpsOverrideEnabled,
            onChanged: (value) => onChanged(
              settings.copyWith(lowBatteryGpsOverrideEnabled: value),
            ),
          ),
          _switch(
            title: 'Remember low-battery GPS choice',
            detail:
                'Controls the do-not-show-again state for the low-battery GPS warning. Turn this off to show the warning again.',
            value: settings.lowBatteryGpsWarningDismissed,
            onChanged: (value) => onChanged(
              settings.copyWith(lowBatteryGpsWarningDismissed: value),
            ),
          ),
          _choice<TripTrackingSamplingPreset>(
            title: 'GPS update preset',
            value: settings.samplingPreset,
            items: TripTrackingSamplingPreset.values,
            label: _samplingPresetLabel,
            onChanged: (value) =>
                onChanged(settings.copyWith(samplingPreset: value)),
          ),
          if (settings.samplingPreset == TripTrackingSamplingPreset.custom)
            _customInterval(settings),
          _switch(
            title: 'Adaptive GPS sampling',
            detail:
                'Let the tracker temporarily adjust the selected interval when movement evidence supports it.',
            value: settings.adaptiveSamplingEnabled,
            onChanged: (value) =>
                onChanged(settings.copyWith(adaptiveSamplingEnabled: value)),
          ),
          _switch(
            title: 'Use motion activity for walking review',
            detail: settings.gpsAssistedTrackingEnabled
                ? 'Off by default. When enabled, the app asks for motion/activity permission at trip start and uses it only during an active GPS trip to help separate driving from walking.'
                : 'Enable GPS-assisted tracking before using motion activity during trips.',
            value: settings.activityRecognitionEnabled,
            onChanged: settings.gpsAssistedTrackingEnabled
                ? (value) => onChanged(
                    settings.copyWith(activityRecognitionEnabled: value),
                  )
                : null,
          ),
          _choice<TripTrackingProfile>(
            title: 'Default tracking profile',
            value: settings.defaultProfile,
            items: TripTrackingProfile.values,
            label: _profileLabel,
            onChanged: (value) =>
                onChanged(settings.copyWith(defaultProfile: value)),
          ),
          _profileGuidance(settings.defaultProfile),
          _switch(
            title: 'Walking-transition review',
            detail:
                'When motion evidence is available, flag likely walking rather than silently counting it as vehicle distance.',
            value: settings.walkingTransitionReviewEnabled,
            onChanged: (value) => onChanged(
              settings.copyWith(walkingTransitionReviewEnabled: value),
            ),
          ),
          _switch(
            title: 'Odometer anomaly alerts',
            detail: settings.gpsAssistedTrackingEnabled
                ? 'Optional. After enough reviewed driving days, warn when GPS-assisted distance and confirmed odometer patterns look persistently unusual. This never changes odometer truth.'
                : 'Enable GPS-assisted tracking before using optional odometer anomaly alerts.',
            value: settings.odometerAnomalyAlertsEnabled,
            onChanged: settings.gpsAssistedTrackingEnabled
                ? (value) => onChanged(
                    settings.copyWith(odometerAnomalyAlertsEnabled: value),
                  )
                : null,
          ),
          _switch(
            title: 'Odometer calibration assist',
            detail: settings.odometerAnomalyAlertsEnabled
                ? 'Separate opt-in. It remains neutral until you review and accept current local evidence; then it affects future GPS estimates only, never confirmed odometer records.'
                : 'Enable odometer anomaly alerts first. Calibration assist stays off until you opt in.',
            value: settings.gpsOdometerCalibrationAssistEnabled,
            onChanged: settings.odometerAnomalyAlertsEnabled
                ? (value) => onChanged(
                    settings.copyWith(
                      gpsOdometerCalibrationAssistEnabled: value,
                    ),
                  )
                : null,
          ),
          if (settings.gpsOdometerCalibrationAssistEnabled &&
              tripTracking != null) ...[
            const SizedBox(height: 8),
            _CalibrationAcceptancePanel(tripTracking: tripTracking!),
          ],
          _switch(
            title: 'Suggest a trip after sustained driving',
            detail: settings.gpsAssistedTrackingEnabled
                ? 'Optional. Requires several credible movement observations and never confirms mileage, purpose, or a job.'
                : 'Enable GPS-assisted tracking before turning on driving-based trip suggestions.',
            value: settings.assistedStartSuggestionsEnabled,
            onChanged: settings.gpsAssistedTrackingEnabled
                ? (value) => onChanged(
                    settings.copyWith(assistedStartSuggestionsEnabled: value),
                  )
                : null,
          ),
          _switch(
            title: 'Begin an assisted candidate automatically',
            detail: settings.assistedStartSuggestionsEnabled
                ? 'Separate opt-in. Requires an independent in-vehicle or approved Bluetooth hint. The trip still waits for your odometer review.'
                : 'Turn on driving-based trip suggestions first. Automatic candidates remain off by default.',
            value: settings.automaticAssistedStartEnabled,
            onChanged: settings.assistedStartSuggestionsEnabled
                ? (value) => onChanged(
                    settings.copyWith(automaticAssistedStartEnabled: value),
                  )
                : null,
          ),
          _switch(
            title: 'Recognize a linked vehicle by Bluetooth',
            detail:
                'Uses only Bluetooth devices you explicitly link to a vehicle on this device.',
            value: settings.bluetoothVehicleRecognitionEnabled,
            onChanged: (value) => onChanged(
              settings.copyWith(bluetoothVehicleRecognitionEnabled: value),
            ),
          ),
          _switch(
            title: 'Automatically switch the active vehicle',
            detail:
                'Never switches while a GPS trip is active. Otherwise, a linked device can select its vehicle.',
            value: settings.automaticVehicleSwitchEnabled,
            onChanged: settings.bluetoothVehicleRecognitionEnabled
                ? (value) => onChanged(
                    settings.copyWith(automaticVehicleSwitchEnabled: value),
                  )
                : (_) {},
          ),
        ],
      ),
    );
  }

  Widget _switch({
    required String title,
    required String detail,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 6, 7),
      decoration: _rowDecoration,
      child: Row(
        children: [
          Expanded(
            child: _SettingText(title: title, detail: detail),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    ),
  );

  Widget _profileGuidance(TripTrackingProfile profile) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
      decoration: _rowDecoration,
      child: _SettingText(
        title: 'Profile-specific stop detection',
        detail: _profileTrackingDetail(profile),
      ),
    ),
  );

  Widget _choice<T>({
    required String title,
    required T value,
    required List<T> items,
    required String Function(T) label,
    required ValueChanged<T> onChanged,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
      decoration: _rowDecoration,
      child: Row(
        children: [
          Expanded(child: Text(title, style: _titleStyle)),
          const SizedBox(width: 8),
          DropdownButton<T>(
            value: value,
            dropdownColor: const Color(0xFF202A2E),
            underline: const SizedBox.shrink(),
            style: const TextStyle(
              color: Color(0xFFE2E8EA),
              fontWeight: FontWeight.w800,
            ),
            items: [
              for (final item in items)
                DropdownMenuItem(value: item, child: Text(label(item))),
            ],
            onChanged: (next) {
              if (next != null) onChanged(next);
            },
          ),
        ],
      ),
    ),
  );

  Widget _customInterval(TripTrackingSettings settings) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
      decoration: _rowDecoration,
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Custom update interval (3–60 sec)',
              style: _titleStyle,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 72,
            child: TextFormField(
              key: const Key('gpsCustomIntervalSeconds'),
              initialValue: '${settings.customIntervalSeconds}',
              keyboardType: TextInputType.number,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Color(0xFFE2E8EA),
                fontWeight: FontWeight.w800,
              ),
              onFieldSubmitted: (value) {
                final seconds = int.tryParse(value);
                if (seconds != null) {
                  onChanged(settings.copyWith(customIntervalSeconds: seconds));
                }
              },
            ),
          ),
        ],
      ),
    ),
  );
}

const _rowDecoration = BoxDecoration(
  color: Color(0xFF202A2E),
  borderRadius: BorderRadius.all(Radius.circular(5)),
  border: Border.fromBorderSide(BorderSide(color: Color(0xFF445158))),
);

const _titleStyle = TextStyle(
  color: Color(0xFFE2E8EA),
  fontSize: 14,
  fontWeight: FontWeight.w900,
);

class _SettingText extends StatelessWidget {
  const _SettingText({required this.title, required this.detail});
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: _titleStyle),
      const SizedBox(height: 3),
      Text(
        detail,
        style: const TextStyle(
          color: Color(0xFFCAD2D5),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.18,
        ),
      ),
    ],
  );
}

/// The switch is only a standing opt-in. A materially different GPS/odometer
/// pattern still requires this separate, current-evidence acceptance before it
/// can influence future GPS estimates.
class _CalibrationAcceptancePanel extends StatelessWidget {
  const _CalibrationAcceptancePanel({required this.tripTracking});

  final TripTrackingController tripTracking;

  @override
  Widget build(BuildContext context) {
    final guard = tripTracking.gpsAssistanceCalibrationApplyGuard;
    final reviewRequired = guard.reasonCodes.contains(
      'user_must_accept_calibration_review',
    );
    final waitingForHistory = guard.reasonCodes.contains(
      'more_reviewed_odometer_days_required',
    );
    final detail = reviewRequired
        ? 'Current reviewed mileage shows a consistent difference. Accepting applies the advisory adjustment only to future GPS estimates for this vehicle. It never changes confirmed odometer history.'
        : waitingForHistory
        ? 'More consistent, reviewed driving days are needed before a calibration review can be offered.'
        : tripTracking.calibrationReviewAcceptedForCurrentEvidence
        ? 'Current reviewed evidence has been accepted. Only future GPS estimates use the advisory adjustment.'
        : 'Current evidence is not eligible for an advisory GPS calibration.';
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _rowDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SettingText(
            title: 'Calibration review',
            detail:
                'Confirmed odometer readings remain authoritative. GPS can never rewrite them.',
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            style: const TextStyle(
              color: Color(0xFFCAD2D5),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.18,
            ),
          ),
          if (reviewRequired) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => _acceptCurrentReview(context),
              child: const Text('Accept current calibration review'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _acceptCurrentReview(BuildContext context) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Accept advisory GPS calibration?'),
        content: const Text(
          'This affects only future GPS-assisted estimates for the current vehicle. It never edits confirmed odometer readings, completed TripLog history, or Recap.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
    if (accepted != true || !context.mounted) return;
    final applied = tripTracking.acceptGpsAssistanceCalibrationReview();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          applied
              ? 'Advisory GPS calibration will apply to future estimates only.'
              : 'Calibration evidence changed or is not eligible. No adjustment was applied.',
        ),
      ),
    );
  }
}

String _samplingPresetLabel(TripTrackingSamplingPreset preset) =>
    switch (preset) {
      TripTrackingSamplingPreset.highAccuracy => 'High accuracy (3 sec)',
      TripTrackingSamplingPreset.enhancedAccuracy => 'Enhanced (8 sec)',
      TripTrackingSamplingPreset.balanced => 'Balanced (15 sec)',
      TripTrackingSamplingPreset.batterySaver => 'Battery saver (30 sec)',
      TripTrackingSamplingPreset.extremeOptimized =>
        'Extreme optimized (60 sec)',
      TripTrackingSamplingPreset.custom => 'Custom',
    };

String _backupNetworkPolicyLabel(TripTrackingBackupNetworkPolicy policy) =>
    switch (policy) {
      TripTrackingBackupNetworkPolicy.wifiOnly => 'Wi‑Fi only',
      TripTrackingBackupNetworkPolicy.wifiAndMobileData => 'Wi‑Fi + mobile',
      TripTrackingBackupNetworkPolicy.mobileDataOnly => 'Mobile data only',
    };

String _profileLabel(TripTrackingProfile profile) => switch (profile) {
  TripTrackingProfile.roadVehicle => 'Road vehicle',
  TripTrackingProfile.rideshareVehicle => 'Rideshare / passenger driving',
  TripTrackingProfile.deliveryVehicle => 'Delivery driver',
  TripTrackingProfile.contractorVehicle => 'Contractor / service vehicle',
  TripTrackingProfile.lowSpeedEquipment => 'Low-speed equipment',
};

String _profileTrackingDetail(TripTrackingProfile profile) => switch (profile) {
  TripTrackingProfile.rideshareVehicle =>
    'Uses stronger stop evidence because the driver often stays in the vehicle. Long lights should not become delivery-style stops.',
  TripTrackingProfile.deliveryVehicle =>
    'Uses walking evidence as a review-only stop clue after vehicle movement so porch or pickup walks are not counted as vehicle miles.',
  TripTrackingProfile.contractorVehicle =>
    'Uses walking evidence as a review-only jobsite stop clue while keeping confirmed odometer entries authoritative.',
  TripTrackingProfile.lowSpeedEquipment =>
    'Ignores walking-stop evidence so low-speed equipment routes do not become false stops.',
  TripTrackingProfile.roadVehicle =>
    'Uses conservative walking evidence for review-only stop assistance without changing confirmed odometer mileage.',
};
