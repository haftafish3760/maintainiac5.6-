import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/odometer/odometer_mileage_review.dart';
import 'package:maintaniac/shared/odometer/odometer_store.dart';
import 'package:maintaniac/shared/odometer/odometer_validation.dart';
import 'package:maintaniac/shared/odometer/odometer_vehicle_snapshot.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';

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
}
