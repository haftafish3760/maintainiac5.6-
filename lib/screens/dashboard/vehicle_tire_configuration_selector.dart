import 'package:flutter/material.dart';

import '../../shared/state/app_state.dart';

class VehicleTireConfigurationSelector extends StatelessWidget {
  const VehicleTireConfigurationSelector({
    super.key,
    required this.tireSizeStatus,
    required this.speedometerCalibrationStatus,
    required this.onTireSizeChanged,
    required this.onSpeedometerCalibrationChanged,
  });

  final VehicleTireSizeStatus tireSizeStatus;
  final VehicleSpeedometerCalibrationStatus speedometerCalibrationStatus;
  final ValueChanged<VehicleTireSizeStatus> onTireSizeChanged;
  final ValueChanged<VehicleSpeedometerCalibrationStatus>
  onSpeedometerCalibrationChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tire and speedometer setup',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'This helps explain consistent GPS differences. It never changes '
          'confirmed odometer mileage.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<VehicleTireSizeStatus>(
          key: const ValueKey('vehicle-tire-size-status'),
          initialValue: tireSizeStatus,
          decoration: const InputDecoration(
            labelText: 'Current tire size',
            border: OutlineInputBorder(),
          ),
          items: VehicleTireSizeStatus.values
              .map(
                (status) => DropdownMenuItem(
                  value: status,
                  child: Text(_tireSizeLabel(status)),
                ),
              )
              .toList(growable: false),
          onChanged: (value) {
            if (value != null) onTireSizeChanged(value);
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<VehicleSpeedometerCalibrationStatus>(
          key: const ValueKey('vehicle-speedometer-calibration-status'),
          initialValue: speedometerCalibrationStatus,
          decoration: const InputDecoration(
            labelText: 'Recalibrated for these tires?',
            border: OutlineInputBorder(),
          ),
          items: VehicleSpeedometerCalibrationStatus.values
              .map(
                (status) => DropdownMenuItem(
                  value: status,
                  child: Text(_calibrationLabel(status)),
                ),
              )
              .toList(growable: false),
          onChanged: (value) {
            if (value != null) onSpeedometerCalibrationChanged(value);
          },
        ),
      ],
    );
  }
}

String _tireSizeLabel(VehicleTireSizeStatus status) => switch (status) {
  VehicleTireSizeStatus.factoryEquivalent => 'Factory or recommended size',
  VehicleTireSizeStatus.largerThanRecommended => 'Larger than recommended',
  VehicleTireSizeStatus.smallerThanRecommended => 'Smaller than recommended',
  VehicleTireSizeStatus.unknown => 'Not sure',
};

String _calibrationLabel(VehicleSpeedometerCalibrationStatus status) =>
    switch (status) {
      VehicleSpeedometerCalibrationStatus.calibratedForCurrentTires => 'Yes',
      VehicleSpeedometerCalibrationStatus.notCalibratedForCurrentTires => 'No',
      VehicleSpeedometerCalibrationStatus.unknown => 'Not sure',
    };
