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

  test('recognized device can auto-switch only after explicit consent', () {
    expect(
      resolveBluetoothVehicleMatch(
        settings: const TripTrackingSettings(
          bluetoothVehicleRecognitionEnabled: true,
          automaticVehicleSwitchEnabled: true,
        ),
        link: link,
        hasActiveGpsTrip: false,
      ),
      BluetoothVehicleMatchDisposition.automaticSwitchAllowed,
    );
    expect(
      resolveBluetoothVehicleMatch(
        settings: const TripTrackingSettings(
          automaticVehicleSwitchEnabled: true,
        ),
        link: link,
        hasActiveGpsTrip: false,
      ),
      BluetoothVehicleMatchDisposition.recognitionDisabled,
    );
  });

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

  test('Bluetooth match decisions never expose opaque device ids', () {
    final decision = resolveBluetoothVehicleMatchDecision(
      settings: const TripTrackingSettings(
        bluetoothVehicleRecognitionEnabled: true,
        automaticVehicleSwitchEnabled: true,
      ),
      link: link,
      hasActiveGpsTrip: false,
    );

    expect(
      decision.disposition,
      BluetoothVehicleMatchDisposition.automaticSwitchAllowed,
    );
    expect(decision.vehicleId, 'vehicle_1');
    expect(decision.canSwitchVehicle, isTrue);
    expect(decision.requiresUserConfirmation, isFalse);
    expect(decision.safeReason, 'bluetooth_vehicle_auto_switch_allowed');
    final safe = decision.toSafeSummary();
    expect(safe['disposition'], 'automaticSwitchAllowed');
    expect(safe['vehicleId'], 'vehicle_1');
    expect(safe['safeReason'], 'bluetooth_vehicle_auto_switch_allowed');
    expect(safe['canSwitchVehicle'], isTrue);
    expect(safe['requiresUserConfirmation'], isFalse);
    expect(safe['bluetoothDecisionCanSetGlobalTruth'], isFalse);
    expect(safe['bluetoothDecisionCanConfirmOfficialMileage'], isFalse);
    expect(safe['bluetoothDecisionCanChangeOfficialMileage'], isFalse);
    expect(safe['deviceIdIncluded'], isFalse);
    expect(safe['rawBluetoothPayloadIncluded'], isFalse);
    expect(safe['odometerIsGlobalTruth'], isTrue);
    expect(safe['gpsCanOverrideOdometer'], isFalse);
    expect(
      decision.toSafeSummary().toString(),
      isNot(contains('opaque-device-id')),
    );
  });

  test(
    'active GPS trip decision is review-only and preserves vehicle lock',
    () {
      final decision = resolveBluetoothVehicleMatchDecision(
        settings: const TripTrackingSettings(
          bluetoothVehicleRecognitionEnabled: true,
          automaticVehicleSwitchEnabled: true,
        ),
        link: link,
        hasActiveGpsTrip: true,
      );

      expect(
        decision.disposition,
        BluetoothVehicleMatchDisposition.blockedByActiveTrip,
      );
      expect(decision.canSwitchVehicle, isFalse);
      expect(
        decision.safeReason,
        'bluetooth_switch_blocked_by_active_gps_trip',
      );
      expect(decision.toSafeSummary()['deviceIdIncluded'], isFalse);
    },
  );

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
      'deviceId': '  ${'d' * 80}\n${'d' * 120}  ',
      'vehicleId': '  ${'v' * 80}\t${'v' * 120}  ',
      'displayName': 'Truck\n${'x' * 120}',
      'createdAt': DateTime.utc(2026, 7, 13, 8).toIso8601String(),
    });
    final map = link.toMap();

    expect((map['deviceId'] as String), hasLength(160));
    expect((map['vehicleId'] as String), hasLength(160));
    expect((map['displayName'] as String), hasLength(80));
    expect(map['deviceId'], isNot(contains('\n')));
    expect(map['vehicleId'], isNot(contains('\t')));
    expect(map['displayName'], isNot(contains('\n')));
    expect(link.isValid, isTrue);
    final safe = link.toSafeSummary();
    expect(safe['hasDeviceLink'], isTrue);
    expect(safe['vehicleId'], map['vehicleId']);
    expect(safe['hasDisplayName'], isTrue);
    expect(safe['bluetoothLinkCanSetGlobalTruth'], isFalse);
    expect(safe['bluetoothLinkCanConfirmOfficialMileage'], isFalse);
    expect(safe['bluetoothLinkCanChangeOfficialMileage'], isFalse);
    expect(safe['deviceIdIncluded'], isFalse);
    expect(safe['rawBluetoothPayloadIncluded'], isFalse);
    expect(safe['odometerIsGlobalTruth'], isTrue);
    expect(safe['gpsCanOverrideOdometer'], isFalse);
    expect(link.toSafeSummary().toString(), isNot(contains(map['deviceId'])));
  });

  test('malformed Bluetooth link timestamps do not become current time', () {
    final link = TripTrackingBluetoothVehicleLink.fromMap({
      'deviceId': 'head-unit',
      'vehicleId': 'vehicle_1',
      'createdAt': 'not-a-date',
    });

    expect(link.createdAt, DateTime.fromMillisecondsSinceEpoch(0, isUtc: true));
  });

  test('Bluetooth lookups and removals use normalized local ids', () async {
    final store = TripTrackingBluetoothVehicleLinkStore.memory();
    final createdAt = DateTime.utc(2026, 7, 13, 8);
    await store.save(
      TripTrackingBluetoothVehicleLink(
        deviceId: ' head-unit\none ',
        vehicleId: ' vehicle\t1 ',
        createdAt: createdAt,
      ),
    );

    expect(store.linkForDevice('head-unit one')?.vehicleId, 'vehicle 1');
    expect(store.linksForVehicle('vehicle 1'), hasLength(1));
    await store.removeDevice('head-unit one');
    expect(store.linkForDevice('head-unit one'), isNull);
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
