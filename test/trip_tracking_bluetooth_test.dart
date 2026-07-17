import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_bluetooth.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

void main() {
  final link = TripTrackingBluetoothVehicleLink(
    deviceId: 'opaque-device-id',
    vehicleId: 'vehicle_1',
    createdAt: DateTime(2026),
  );

  test('Bluetooth recognition remains off by default', () {
    expect(
      resolveBluetoothVehicleMatch(
        settings: const TripTrackingSettings(),
        link: link,
        hasActiveGpsTrip: false,
      ),
      BluetoothVehicleMatchDisposition.recognitionDisabled,
    );
  });

  test(
    'recognized device requires confirmation without auto-switch consent',
    () {
      expect(
        resolveBluetoothVehicleMatch(
          settings: const TripTrackingSettings(
            bluetoothVehicleRecognitionEnabled: true,
          ),
          link: link,
          hasActiveGpsTrip: false,
        ),
        BluetoothVehicleMatchDisposition.requiresUserConfirmation,
      );
    },
  );

  test('an active GPS trip always blocks Bluetooth vehicle reassignment', () {
    expect(
      resolveBluetoothVehicleMatch(
        settings: const TripTrackingSettings(
          bluetoothVehicleRecognitionEnabled: true,
          automaticVehicleSwitchEnabled: true,
        ),
        link: link,
        hasActiveGpsTrip: true,
      ),
      BluetoothVehicleMatchDisposition.blockedByActiveTrip,
    );
  });

  test(
    'local vehicle links are keyed by device and can be safely relinked',
    () async {
      final store = TripTrackingBluetoothVehicleLinkStore.memory();
      final createdAt = DateTime.utc(2026, 7, 13, 8);

      await store.save(
        TripTrackingBluetoothVehicleLink(
          deviceId: '  opaque-device-id  ',
          vehicleId: 'vehicle_1',
          displayName: 'Work truck',
          createdAt: createdAt,
        ),
      );
      await store.save(
        TripTrackingBluetoothVehicleLink(
          deviceId: 'opaque-device-id',
          vehicleId: 'vehicle_2',
          displayName: 'Personal truck',
          createdAt: createdAt.add(const Duration(minutes: 1)),
        ),
      );

      expect(store.linksForVehicle('vehicle_1'), isEmpty);
      expect(store.linkForDevice('opaque-device-id')?.vehicleId, 'vehicle_2');
      expect(
        store.linkForDevice('opaque-device-id')?.displayName,
        'Personal truck',
      );
    },
  );

  test('Bluetooth vehicle links are trimmed and bounded locally', () {
    final link = TripTrackingBluetoothVehicleLink.fromMap({
      'deviceId': '  ${'d' * 200}  ',
      'vehicleId': '  ${'v' * 200}  ',
      'displayName': 'Truck\n${'x' * 120}',
      'createdAt': DateTime.utc(2026, 7, 13, 8).toIso8601String(),
    });
    final map = link.toMap();

    expect((map['deviceId'] as String), hasLength(160));
    expect((map['vehicleId'] as String), hasLength(160));
    expect((map['displayName'] as String), hasLength(80));
    expect(map['displayName'], isNot(contains('\n')));
    expect(link.isValid, isTrue);
  });

  test(
    'a vehicle may have multiple links and blank links cannot be saved',
    () async {
      final store = TripTrackingBluetoothVehicleLinkStore.memory();
      final createdAt = DateTime.utc(2026, 7, 13, 8);
      for (final deviceId in ['head-unit', 'obd-adapter']) {
        await store.save(
          TripTrackingBluetoothVehicleLink(
            deviceId: deviceId,
            vehicleId: 'vehicle_1',
            createdAt: createdAt,
          ),
        );
      }

      expect(store.linksForVehicle('vehicle_1'), hasLength(2));
      await expectLater(
        store.save(
          TripTrackingBluetoothVehicleLink(
            deviceId: ' ',
            vehicleId: 'vehicle_1',
            createdAt: createdAt,
          ),
        ),
        throwsArgumentError,
      );
    },
  );
}
