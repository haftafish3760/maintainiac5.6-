// Bluetooth recognition and explicit vehicle-link controls for trip settings.
//
// Owns presentation and user approval/removal actions for local Bluetooth
// links. It does not observe radios, expose hardware identifiers, grant paid
// access, start GPS, or change odometer truth. TripTrackingSettingsScreen
// consumes this part through its settings panel.

part of 'trip_tracking_settings_screen.dart';

extension _TripTrackingBluetoothPanel on _TripTrackingSettingsPanel {
  bool get _bluetoothRecognitionControlsEnabled =>
      bluetoothVehicleRecognitionAvailable;

  bool get _automaticStartControlsEnabled =>
      automaticStartAccess == TripAutomaticStartAccessLevel.paid &&
      bluetoothVehicleRecognitionAvailable;

  Widget _bluetoothStatus(BuildContext context) {
    final (title, detail) = !bluetoothVehicleRecognitionAvailable
        ? (
            'Bluetooth setup required',
            'Bluetooth connection access is unavailable or not granted. Nothing is linked or tracked silently.',
          )
        : (
            'Ready for an approved vehicle link',
            'Only a vehicle link you approve on this phone can identify a vehicle.',
          );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        key: const Key('bluetoothTrackingStatus'),
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
        decoration: _rowDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SettingText(title: title, detail: detail),
            if (!bluetoothVehicleRecognitionAvailable &&
                bluetoothRuntime?.canRequestObservationAccess == true) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                key: const Key('enableBluetoothVehicleAccess'),
                onPressed: () async {
                  final enabled = await bluetoothRuntime!
                      .requestObservationAccess();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        enabled
                            ? 'Bluetooth vehicle access is ready.'
                            : 'Bluetooth access was not granted. Manual trip tracking remains available.',
                      ),
                    ),
                  );
                },
                child: const Text('Enable Bluetooth vehicle access'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _automaticStartStatus() => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Container(
      key: const Key('bluetoothAutomaticStartStatus'),
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: _rowDecoration,
      child: const _SettingText(
        title: 'Paid feature',
        detail:
            'Bluetooth-triggered automatic tracking requires an active paid plan. Vehicle recognition, GPS, and manual odometer entry remain independently available.',
      ),
    ),
  );

  Widget _bluetoothLinkPanel(BuildContext context) {
    final runtime = bluetoothRuntime;
    final vehicle = activeVehicle;
    if (runtime == null || vehicle == null) return const SizedBox.shrink();
    final links = runtime.linksForVehicle(vehicle.id);
    final canApprove =
        bluetoothVehicleRecognitionAvailable && runtime.hasPendingDevice;
    return Container(
      key: const Key('bluetoothVehicleLinkPanel'),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: _rowDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SettingText(
            title: 'Approved vehicle link',
            detail: links.isEmpty
                ? 'Connect the vehicle in phone settings, then return here to approve that recent connection for ${vehicle.nickname}. Hardware identifiers stay hidden.'
                : '${links.length} device${links.length == 1 ? '' : 's'} approved for ${vehicle.nickname}.',
          ),
          if (canApprove) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              key: const Key('approveRecentBluetoothVehicle'),
              onPressed: () async {
                final approved = await runtime.approvePendingForVehicle(
                  vehicleId: vehicle.id,
                  vehicleLabel: vehicle.nickname,
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      approved
                          ? 'Bluetooth device approved for ${vehicle.nickname}.'
                          : 'That connection expired. Reconnect the vehicle and try again.',
                    ),
                  ),
                );
              },
              child: Text('Approve recent connection for ${vehicle.nickname}'),
            ),
          ],
          for (var index = 0; index < links.length; index++) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Approved device ${index + 1}',
                    style: const TextStyle(color: Color(0xFFDDE5E7)),
                  ),
                ),
                TextButton(
                  onPressed: () => _confirmRemoveBluetoothLink(
                    context,
                    runtime: runtime,
                    deviceId: links[index].normalizedDeviceId,
                  ),
                  child: const Text('Forget'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmRemoveBluetoothLink(
    BuildContext context, {
    required TripTrackingBluetoothRuntimeController runtime,
    required String deviceId,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Forget Bluetooth vehicle link?'),
        content: const Text(
          'This device will no longer identify the vehicle. Manual mileage and GPS controls remain available.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep link'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Forget link'),
          ),
        ],
      ),
    );
    if (confirmed == true) await runtime.removeLink(deviceId);
  }
}
