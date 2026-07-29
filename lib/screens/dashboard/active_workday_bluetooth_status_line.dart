/// Truthful Bluetooth vehicle-recognition status for an active workday.
///
/// Owns only user-visible health language. It does not observe Bluetooth,
/// expose device identifiers, select vehicles, or start trips. Consumed by
/// ActiveWorkdayTrackingStatusLine alongside the GPS status surface.
library;

import 'package:flutter/material.dart';

import '../../shared/trip_tracking/trip_tracking_bluetooth.dart';

@immutable
class ActiveWorkdayBluetoothStatus {
  const ActiveWorkdayBluetoothStatus(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;

  static ActiveWorkdayBluetoothStatus forSnapshot({
    required bool recognitionEnabled,
    required bool observationAvailable,
    required bool isListening,
    required BluetoothVehicleMatchDecision? lastDecision,
  }) {
    if (!recognitionEnabled) {
      return const ActiveWorkdayBluetoothStatus(
        'Bluetooth vehicle recognition off',
        Icons.bluetooth_disabled_rounded,
        Color(0xFFCAD2D5),
      );
    }
    if (!observationAvailable || !isListening) {
      return const ActiveWorkdayBluetoothStatus(
        'Bluetooth vehicle recognition unavailable',
        Icons.bluetooth_disabled_rounded,
        Color(0xFFFFD166),
      );
    }
    if (lastDecision?.requiresUserConfirmation == true) {
      return const ActiveWorkdayBluetoothStatus(
        'Bluetooth suggested a vehicle — review required',
        Icons.bluetooth_searching_rounded,
        Color(0xFFFFD166),
      );
    }
    if (lastDecision?.disposition ==
        BluetoothVehicleMatchDisposition.alreadyActiveVehicle) {
      return const ActiveWorkdayBluetoothStatus(
        'Bluetooth recognizes the active vehicle',
        Icons.bluetooth_connected_rounded,
        Color(0xFF50F77A),
      );
    }
    return const ActiveWorkdayBluetoothStatus(
      'Bluetooth is ready to recognize linked vehicles',
      Icons.bluetooth_rounded,
      Color(0xFF9CC7E8),
    );
  }
}

class ActiveWorkdayBluetoothStatusLine extends StatelessWidget {
  const ActiveWorkdayBluetoothStatusLine({super.key, required this.status});

  final ActiveWorkdayBluetoothStatus status;

  @override
  Widget build(BuildContext context) => Semantics(
    label: status.label,
    child: Row(
      children: [
        Icon(status.icon, size: 14, color: status.color),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            status.label,
            style: TextStyle(
              color: status.color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}
