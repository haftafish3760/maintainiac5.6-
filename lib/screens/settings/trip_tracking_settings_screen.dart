import 'package:flutter/material.dart';

import '../../shared/trip_tracking/trip_tracking_models.dart';
import '../../shared/trip_tracking/trip_automatic_start_detector.dart';
import '../../shared/trip_tracking/trip_tracking_controller.dart';
import '../../shared/trip_tracking/trip_tracking_bluetooth_runtime.dart';
import '../../shared/trip_tracking/trip_tracking_settings_store.dart';
import '../../shared/state/app_state.dart';
import '../../shared/state/global_odometer.dart';
import '../../shared/widgets/app_screen_shell.dart';
import '../../shared/widgets/app_back_button.dart';
import 'trip_background_location_settings_action.dart';
import 'trip_tracking_gps_opt_in_flow.dart';
import 'trip_tracking_sampling_explanation.dart';

part 'trip_tracking_settings_map_controls.dart';
part 'trip_tracking_settings_calibration_panel.dart';
part 'trip_tracking_settings_labels.dart';
part 'trip_tracking_settings_bluetooth_panel.dart';

/// Shared preference surface opened from both Dashboard Settings and Menu.
class TripTrackingSettingsScreen extends StatelessWidget {
  const TripTrackingSettingsScreen({
    super.key,
    this.bluetoothVehicleRecognitionAvailable,
    this.automaticStartAccess = TripAutomaticStartAccessLevel.free,
  });

  final bool? bluetoothVehicleRecognitionAvailable;
  final TripAutomaticStartAccessLevel automaticStartAccess;

  @override
  Widget build(BuildContext context) {
    final controller = TripTrackingSettingsScope.of(context);
    final tripTracking = TripTrackingScope.maybeOf(context);
    final odometer = GlobalOdometerScope.of(context);
    final bluetoothRuntime = TripTrackingBluetoothRuntimeScope.maybeOf(context);
    final activeVehicle = AppStateScope.of(context).activeVehicle;
    final settings = controller.settings;
    return AppScreenShell(
      section: AppSection.dashboard,
      pinnedHeader: const AppScreenHeader(title: 'GPS-Assisted Trip Tracking'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 22),
        children: [
          const GlobalOdometerHeader(),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _TripTrackingSettingsPanel(
              settings: settings,
              onChanged: controller.update,
              tripTracking: tripTracking,
              odometer: odometer,
              bluetoothVehicleRecognitionAvailable:
                  bluetoothVehicleRecognitionAvailable ??
                  bluetoothRuntime?.observationAvailable ??
                  false,
              automaticStartAccess: automaticStartAccess,
              bluetoothRuntime: bluetoothRuntime,
              activeVehicle: activeVehicle,
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
    required this.odometer,
    required this.bluetoothVehicleRecognitionAvailable,
    required this.automaticStartAccess,
    required this.bluetoothRuntime,
    required this.activeVehicle,
  });

  final TripTrackingSettings settings;
  final ValueChanged<TripTrackingSettings> onChanged;
  final TripTrackingController? tripTracking;
  final GlobalOdometerController odometer;
  final bool bluetoothVehicleRecognitionAvailable;
  final TripAutomaticStartAccessLevel automaticStartAccess;
  final TripTrackingBluetoothRuntimeController? bluetoothRuntime;
  final VehicleProfile? activeVehicle;

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
          const _SettingsSectionTitle('Core tracking'),
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
          _choice<TripTrackingSamplingPreset>(
            title: 'Accuracy and battery use',
            value: settings.samplingPreset,
            items: TripTrackingSamplingPreset.values,
            label: _samplingPresetLabel,
            onChanged: (value) =>
                onChanged(settings.copyWith(samplingPreset: value)),
          ),
          TripTrackingSamplingExplanation(preset: settings.samplingPreset),
          if (settings.samplingPreset == TripTrackingSamplingPreset.custom)
            _customInterval(settings),
          _switch(
            title: 'Continue during an active background trip',
            detail: settings.gpsAssistedTrackingEnabled
                ? 'Keeps assisting after you leave the screen. At Start Day, iPhone asks for location access; background use needs Allow Always. Android may also need additional access.'
                : 'Enable GPS-assisted tracking before allowing a trip to continue in the background.',
            value: settings.backgroundTrackingEnabled,
            onChanged: settings.gpsAssistedTrackingEnabled
                ? (value) => onChanged(
                    settings.copyWith(backgroundTrackingEnabled: value),
                  )
                : null,
          ),
          if (settings.backgroundTrackingEnabled && tripTracking != null)
            TripBackgroundLocationSettingsAction(
              onOpenSettings: tripTracking!.openBackgroundLocationSettings,
            ),
          const _SettingsSectionTitle('Maps and route history'),
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
          if (settings.mapRouteHistorySavingEnabled)
            _routeStorageNotice(tripTracking?.routeStorageStatus),
          const _SettingsSectionTitle('Battery protection'),
          _switch(
            title: 'Protect GPS at or below 15% battery',
            detail:
                'On by default. Below 20%, the app warns you. At or below 15%, it asks before continuing. Below 10%, location pauses unless the phone is charging.',
            value: settings.lowBatteryGpsProtectionEnabled,
            onChanged: (value) => onChanged(
              settings.copyWith(lowBatteryGpsProtectionEnabled: value),
            ),
          ),
          _switch(
            title: 'Allow GPS at or below 15% battery',
            detail:
                'Off by default. This can continue location from 10% to 15% when you accept the battery use. Below 10%, location pauses unless the phone is charging.',
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
          const _SettingsSectionTitle('Tracking behavior and stops'),
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
            detail: !settings.gpsAssistedTrackingEnabled
                ? 'Enable GPS-assisted tracking before using motion activity during trips.'
                : !settings.walkingTransitionReviewEnabled
                ? 'Enable walking-transition review before allowing optional motion activity.'
                : 'Off by default. When enabled, the app asks for motion/activity permission at trip start and uses it only during an active GPS trip to help separate driving from walking.',
            value: settings.activityRecognitionEnabled,
            onChanged:
                settings.gpsAssistedTrackingEnabled &&
                    settings.walkingTransitionReviewEnabled
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
          const _SettingsSectionTitle('Odometer review and calibration'),
          _switch(
            title: 'Use confirmed mileage history for review',
            detail:
                'Optional and local to this vehicle. Maintains a typical-mileage baseline from confirmed odometer readings only, then asks you to review unusual manual entries. It never changes mileage or submits driving data anywhere.',
            value: odometer.drivingPatternReviewEnabled,
            onChanged: odometer.setDrivingPatternReviewEnabled,
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
          const _SettingsSectionTitle('Vehicle-use allocation'),
          _switch(
            title: 'Calculate vehicle-use percentages',
            detail:
                'Optional and local. Uses only mileage you have already confirmed as business, personal, or split to prepare a vehicle-use percentage. It does not enable GPS, track your location, change an expense, or send data automatically.',
            value: settings.vehicleMileageAllocationEnabled,
            onChanged: (value) => onChanged(
              settings.copyWith(vehicleMileageAllocationEnabled: value),
            ),
          ),
          _settingsNotice(
            title: 'You remain in control',
            detail:
                'Expense categories may read this percentage later for a suggested split, but you review and confirm every expense. Unclassified mileage is never represented as business or personal.',
          ),
          const _SettingsSectionTitle('Vehicle recognition'),
          _bluetoothStatus(context),
          _bluetoothLinkPanel(context),
          if (automaticStartAccess != TripAutomaticStartAccessLevel.paid)
            _automaticStartStatus(),
          _switch(
            title: 'Recognize a linked vehicle by Bluetooth',
            detail:
                'Uses only a Bluetooth device you explicitly link to a vehicle on this phone. Bluetooth identifies the vehicle; GPS estimates distance.',
            value: settings.bluetoothVehicleRecognitionEnabled,
            onChanged: _bluetoothRecognitionControlsEnabled
                ? (value) => onChanged(
                    settings.copyWith(
                      bluetoothVehicleRecognitionEnabled: value,
                      automaticVehicleSwitchEnabled: value
                          ? settings.automaticVehicleSwitchEnabled
                          : false,
                      automaticStartAssistanceEnabled: value
                          ? settings.automaticStartAssistanceEnabled
                          : false,
                    ),
                  )
                : null,
          ),
          _settingsNotice(
            title: 'Linked vehicle suggestions need your approval',
            detail:
                'Bluetooth can recognize a linked vehicle, but it never changes your active workday vehicle or odometer vehicle on its own.',
          ),
          _switch(
            title: 'Automatically start GPS for the linked vehicle',
            detail: !settings.gpsAssistedTrackingEnabled
                ? 'Enable GPS-assisted tracking first. Manual mileage remains available.'
                : 'Paid feature. Starts advisory GPS distance when the approved vehicle connects. Confirmed odometer mileage is never changed without your review.',
            value: settings.automaticStartAssistanceEnabled,
            onChanged:
                _automaticStartControlsEnabled &&
                    settings.gpsAssistedTrackingEnabled &&
                    settings.bluetoothVehicleRecognitionEnabled
                ? (value) => onChanged(
                    settings.copyWith(automaticStartAssistanceEnabled: value),
                  )
                : null,
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
          Semantics(
            label: title,
            value: value ? 'On' : 'Off',
            toggled: value,
            child: Switch(value: value, onChanged: onChanged),
          ),
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

  Widget _settingsNotice({required String title, required String detail}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
          decoration: _rowDecoration,
          child: _SettingText(title: title, detail: detail),
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
          Semantics(
            label: title,
            value: label(value),
            button: true,
            child: DropdownButton<T>(
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

class _SettingsSectionTitle extends StatelessWidget {
  const _SettingsSectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 8, 2, 7),
    child: Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: Color(0xFF8EC8F0),
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.7,
      ),
    ),
  );
}

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
