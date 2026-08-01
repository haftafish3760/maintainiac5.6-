// Regression coverage for allocation sync into the published durable bucket.
//
// Owns GPS/Dashboard-side idempotency and opt-in tests. It does not test the
// durable-store implementation, Expense behavior, raw GPS, or odometer edits.
// App bootstrap uses this sync after confirmed odometer evidence changes.

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/odometer/odometer_mileage_review.dart';
import 'package:maintaniac/shared/odometer/odometer_validation.dart';
import 'package:maintaniac/shared/records/maintainiac_durable_record_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';
import 'package:maintaniac/shared/trip_tracking/vehicle_mileage_allocation_durable_sync.dart';
import 'package:maintaniac/shared/vehicle_mileage_allocation/vehicle_mileage_allocation_durable_store.dart';

void main() {
  final occurredAt = DateTime.utc(2026, 8, 1, 12);

  OdometerReadingEvent event({
    OdometerMileageUse use = OdometerMileageUse.business,
    int? businessMiles,
  }) => OdometerReadingEvent(
    id: 'event-1',
    reading: 1012,
    previousReading: 1000,
    recordedAt: occurredAt,
    mileageReview: OdometerMileageReview(
      use: use,
      businessMiles: businessMiles,
    ),
    sourceType: 'manual_odometer',
    sourceId: 'entry-1',
  );

  test('opt-out writes no allocation history', () async {
    final bucket = VehicleMileageAllocationDurableStore(
      records: MaintainiacDurableRecordStore.memory(),
    );
    final result = await VehicleMileageAllocationDurableSync(store: bucket)
        .sync(
          settings: const TripTrackingSettings(),
          vehicleId: 'vehicle-1',
          history: [event()],
        );

    expect(result.savedCount, 0);
    expect(bucket.recover().records, isEmpty);
  });

  test(
    'confirmed evidence is saved once and unchanged sync is idempotent',
    () async {
      final bucket = VehicleMileageAllocationDurableStore(
        records: MaintainiacDurableRecordStore.memory(),
      );
      final sync = VehicleMileageAllocationDurableSync(store: bucket);
      const settings = TripTrackingSettings(
        vehicleMileageAllocationEnabled: true,
      );

      final first = await sync.sync(
        settings: settings,
        vehicleId: 'vehicle-1',
        history: [event()],
      );
      final repeat = await sync.sync(
        settings: settings,
        vehicleId: 'vehicle-1',
        history: [event()],
      );

      expect(first.savedCount, 1);
      expect(repeat.savedCount, 0);
      expect(repeat.unchangedCount, 1);
      expect(bucket.recover().records, hasLength(1));
      expect(bucket.recover().records.single.allocation.businessTenths, 120);
    },
  );

  test('later classification revises the same durable record', () async {
    final bucket = VehicleMileageAllocationDurableStore(
      records: MaintainiacDurableRecordStore.memory(),
    );
    final sync = VehicleMileageAllocationDurableSync(store: bucket);
    const settings = TripTrackingSettings(
      vehicleMileageAllocationEnabled: true,
    );
    await sync.sync(
      settings: settings,
      vehicleId: 'vehicle-1',
      history: [event(use: OdometerMileageUse.unresolved)],
    );
    final revised = await sync.sync(
      settings: settings,
      vehicleId: 'vehicle-1',
      history: [event(use: OdometerMileageUse.split, businessMiles: 7)],
    );

    final record = bucket.recover().records.single;
    expect(revised.savedCount, 1);
    expect(record.lifecycle.revision, 2);
    expect(record.allocation.sourceRevision, 1);
    expect(record.allocation.businessTenths, 70);
    expect(record.allocation.personalTenths, 50);
  });

  test(
    'correction or absent review cannot create allocation evidence',
    () async {
      final bucket = VehicleMileageAllocationDurableStore(
        records: MaintainiacDurableRecordStore.memory(),
      );
      final result = await VehicleMileageAllocationDurableSync(store: bucket)
          .sync(
            settings: const TripTrackingSettings(
              vehicleMileageAllocationEnabled: true,
            ),
            vehicleId: 'vehicle-1',
            history: [
              OdometerReadingEvent(
                id: 'no-review',
                reading: 1010,
                previousReading: 1000,
                recordedAt: occurredAt,
              ),
            ],
          );

      expect(result.rejectedCount, 1);
      expect(bucket.recover().records, isEmpty);
    },
  );
}
