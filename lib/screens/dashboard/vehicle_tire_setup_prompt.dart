import 'package:flutter/material.dart';

import '../../shared/state/app_state.dart';
import 'vehicle_tire_configuration_selector.dart';

Future<VehicleProfile?> showVehicleTireSetupPrompt(
  BuildContext context, {
  required VehicleProfile vehicle,
  DateTime Function()? clock,
}) {
  var tireSizeStatus = vehicle.tireSizeStatus;
  var calibrationStatus = vehicle.speedometerCalibrationStatus;
  return showDialog<VehicleProfile>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Check your tire setup'),
        content: SingleChildScrollView(
          child: VehicleTireConfigurationSelector(
            tireSizeStatus: tireSizeStatus,
            speedometerCalibrationStatus: calibrationStatus,
            onTireSizeChanged: (value) =>
                setDialogState(() => tireSizeStatus = value),
            onSpeedometerCalibrationChanged: (value) =>
                setDialogState(() => calibrationStatus = value),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(
                vehicle.copyWith(
                  tireSizeStatus: tireSizeStatus,
                  speedometerCalibrationStatus: calibrationStatus,
                  tireConfigurationRevision:
                      vehicle.tireConfigurationRevision + 1,
                  tireConfigurationUpdatedAt: (clock ?? DateTime.now)().toUtc(),
                ),
              );
            },
            child: const Text('Save and continue'),
          ),
        ],
      ),
    ),
  );
}
