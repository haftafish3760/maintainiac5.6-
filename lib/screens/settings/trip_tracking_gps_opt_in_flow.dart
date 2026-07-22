import 'package:flutter/material.dart';

import '../../shared/state/app_state.dart';
import '../../shared/trip_tracking/trip_tracking_settings_store.dart';
import '../dashboard/vehicle_tire_setup_prompt.dart';

Future<void> updateGpsAssistedTrackingOptIn({
  required BuildContext context,
  required TripTrackingSettings settings,
  required ValueChanged<TripTrackingSettings> onChanged,
  required bool enabled,
}) async {
  if (enabled) {
    final appState = AppStateScope.of(context);
    final vehicle = appState.activeVehicle;
    if (vehicle != null && vehicle.tireConfigurationUpdatedAt == null) {
      final updated = await showVehicleTireSetupPrompt(
        context,
        vehicle: vehicle,
      );
      if (updated != null) {
        try {
          await appState.updateVehicle(updated);
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'GPS assistance can still be enabled, but the tire setup could not be saved.',
                ),
              ),
            );
          }
        }
      }
    }
  }
  if (!context.mounted) return;
  onChanged(settings.copyWith(gpsAssistedTrackingEnabled: enabled));
}
