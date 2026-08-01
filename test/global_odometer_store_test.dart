import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/odometer/odometer_mileage_review.dart';
import 'package:maintaniac/shared/odometer/odometer_store.dart';
import 'package:maintaniac/shared/odometer/odometer_validation.dart';
import 'package:maintaniac/shared/odometer/odometer_vehicle_snapshot.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/storage/app_storage_guard.dart';

void main() {
  test('odometer store saves and restores vehicle snapshots', () async {
    final store = OdometerStore.memory();
    final controller = GlobalOdometerController(
      vehicleId: 'truck-1',
      initialReading: 1000,
      snapshotWriter: store.saveSnapshot,
    );

    controller.updateFromText(
      '1,045',
      mileageReview: const OdometerMileageReview(
        use: OdometerMileageUse.split,
        businessMiles: 30,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    final saved = store.snapshotForVehicle('truck-1');
    expect(saved.currentReading, 1045);
    expect(saved.history.last.mileageReview?.use, OdometerMileageUse.split);
    expect(saved.history.last.mileageReview?.businessMiles, 30);
  });

  test('snapshot preserves exact confirmed tenths and legacy fallback', () {
    final exact = OdometerVehicleSnapshot.fromMap({
      'vehicleId': 'truck-tenths',
      'currentReading': 1045,
      'currentReadingTenths': 10457,
      'updatedAt': DateTime.utc(2026, 8, 1).toIso8601String(),
      'history': [
        {
          'reading': 1045,
          'readingTenths': 10457,
          'previousReading': 1040,
          'previousReadingTenths': 10402,
          'recordedAt': DateTime.utc(2026, 8, 1).toIso8601String(),
        },
      ],
    });
    final legacy = OdometerVehicleSnapshot.fromMap({
      'vehicleId': 'truck-legacy',
      'currentReading': 1045,
      'updatedAt': DateTime.utc(2026, 8, 1).toIso8601String(),
      'history': [
        {
          'reading': 1045,
          'previousReading': 1040,
          'recordedAt': DateTime.utc(2026, 8, 1).toIso8601String(),
        },
      ],
    });

    expect(exact.effectiveCurrentReadingTenths, 10457);
    expect(exact.history.single.effectiveReadingTenths, 10457);
    expect(exact.history.single.effectivePreviousReadingTenths, 10402);
    expect(exact.toMap()['currentReadingTenths'], 10457);
    expect(legacy.effectiveCurrentReadingTenths, 10450);
    expect(legacy.history.single.effectiveReadingTenths, 10450);
    expect(legacy.history.single.effectivePreviousReadingTenths, 10400);
  });

  test(
    'odometer vehicle snapshots never persist negative current readings',
    () {
      final saved = OdometerVehicleSnapshot(
        vehicleId: 'truck-negative',
        currentReading: -42,
        updatedAt: DateTime.utc(2026, 7, 17, 12),
        history: const [],
      ).toMap();
      final restored = OdometerVehicleSnapshot.fromMap({
        'vehicleId': 'truck-negative',
        'currentReading': -99,
        'updatedAt': DateTime.utc(2026, 7, 17, 12).toIso8601String(),
        'history': const [],
      });

      expect(saved['currentReading'], isZero);
      expect(restored.currentReading, isZero);
    },
  );

  test('malformed vehicle snapshot fields fail closed on restore', () {
    final restored = OdometerVehicleSnapshot.fromMap({
      'vehicleId': ' ${'truck' * 80}\n',
      'currentReading': 'not-a-reading',
      'updatedAt': 'not-a-date',
      'history': const [],
    });

    expect(restored.vehicleId, hasLength(160));
    expect(restored.vehicleId, isNot(contains('\n')));
    expect(restored.currentReading, isZero);
    expect(
      restored.updatedAt,
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  });

  test(
    'odometer store normalizes unsafe vehicle keys before save and load',
    () async {
      final store = OdometerStore.memory();
      await store.saveSnapshot(
        OdometerVehicleSnapshot(
          vehicleId: ' ${'truck' * 80}\n',
          currentReading: 1200,
          updatedAt: DateTime.utc(2026, 7, 17, 12),
          history: const [],
        ),
      );

      final restored = store.snapshotForVehicle(' ${'truck' * 80}\n');

      expect(restored.vehicleId, hasLength(160));
      expect(restored.vehicleId, isNot(contains('\n')));
      expect(restored.currentReading, 1200);
    },
  );

  test('switching vehicles keeps odometer histories separate', () async {
    final store = OdometerStore.memory();
    await store.saveSnapshot(
      OdometerVehicleSnapshot(
        vehicleId: 'truck_1',
        currentReading: 1000,
        updatedAt: DateTime(2026, 6, 1, 8),
        history: [
          OdometerReadingEvent(
            reading: 1000,
            recordedAt: DateTime(2026, 6, 1, 8),
          ),
        ],
      ),
    );
    await store.saveSnapshot(
      OdometerVehicleSnapshot(
        vehicleId: 'truck_2',
        currentReading: 5000,
        updatedAt: DateTime(2026, 6, 1, 8),
        history: [
          OdometerReadingEvent(
            reading: 5000,
            recordedAt: DateTime(2026, 6, 1, 8),
          ),
        ],
      ),
    );
    final controller = GlobalOdometerController(
      vehicleId: 'truck_1',
      initialReading: 1000,
      snapshotReader: store.loadSnapshotForVehicle,
      snapshotWriter: store.saveSnapshot,
    );

    await controller.switchVehicleById('truck_2');
    expect(controller.vehicleId, 'truck_2');
    expect(controller.reading, 5000);

    controller.updateFromText(
      '5,050',
      mileageReview: const OdometerMileageReview(
        use: OdometerMileageUse.business,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(store.snapshotForVehicle('truck_2').currentReading, 5050);
    expect(store.snapshotForVehicle('truck_1').currentReading, 1000);
  });

  test(
    'opt-in driving-pattern review persists with its vehicle snapshot',
    () async {
      final store = OdometerStore.memory();
      final controller = GlobalOdometerController(
        vehicleId: 'truck_1',
        initialReading: 1000,
        snapshotWriter: store.saveSnapshot,
      );

      expect(controller.drivingPatternReviewEnabled, isFalse);
      await controller.setDrivingPatternReviewEnabled(true);

      expect(controller.drivingPatternReviewEnabled, isTrue);
      expect(
        store.snapshotForVehicle('truck_1').drivingPatternReviewEnabled,
        isTrue,
      );
    },
  );

  test('odometer history is not changed when storage is full', () async {
    final store = OdometerStore.memory(
      storageCheck: () async => const AppStorageCheck(
        availableBytes: 0,
        operationBytes: AppStorageGuard.mileageTrackingWriteBytes,
        requiredBytes: AppStorageGuard.mileageTrackingWriteBytes + 1,
        purpose: AppStoragePurpose.mileageTracking,
      ),
    );

    await expectLater(
      () => store.saveSnapshot(
        OdometerVehicleSnapshot(
          vehicleId: 'no-space',
          currentReading: 1200,
          updatedAt: DateTime.utc(2026, 7, 15),
          history: const [],
        ),
      ),
      throwsA(isA<StateError>()),
    );
    expect(store.snapshotForVehicle('no-space').history, isEmpty);
    expect(store.snapshotForVehicle('no-space').currentReading, 298150);
  });
}
