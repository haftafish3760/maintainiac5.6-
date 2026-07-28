import 'dart:async';

import 'package:flutter/material.dart';

import '../../shared/state/app_state.dart';
import '../../shared/trip_tracking/trip_tracking_settings_store.dart';
import '../dashboard/vehicle_tire_setup_prompt.dart';

Future<void> updateGpsAssistedTrackingOptIn({
  required BuildContext context,
  required TripTrackingSettings settings,
  required FutureOr<void> Function(TripTrackingSettings) onChanged,
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
  try {
    await Future<void>.sync(
      () => onChanged(settings.copyWith(gpsAssistedTrackingEnabled: enabled)),
    );
  } catch (_) {
    if (context.mounted && Scaffold.maybeOf(context) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GPS assistance could not be saved. Please try again.'),
        ),
      );
    }
    return;
  }
  if (!context.mounted || Scaffold.maybeOf(context) == null) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        enabled
            ? 'GPS assistance is on. Start Day to approve location access and begin tracking.'
            : 'GPS assistance is off. Manual trips and odometer entry remain available.',
      ),
    ),
  );
}
