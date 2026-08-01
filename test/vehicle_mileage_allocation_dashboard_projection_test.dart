// Regression coverage for the Dashboard read-only allocation projection.
//
// Owns Dashboard consumer safety tests. It does not test Expense UI, raw GPS,
// durable-store internals, or odometer entry. Dashboard readers use it to
// avoid treating incomplete or conflicting evidence as a percentage.

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/dashboard/data/vehicle_mileage_allocation_dashboard_projection.dart';
import 'package:maintaniac/shared/records/maintainiac_durable_record_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';
import 'package:maintaniac/shared/trip_tracking/vehicle_mileage_allocation.dart';
import 'package:maintaniac/shared/vehicle_mileage_allocation/vehicle_mileage_allocation_durable_store.dart';

void main() {
  VehicleMileageAllocationRecord record({
    required String id,
    required String sourceId,
    int revision = 1,
    DateTime? occurredAt,
  }) => VehicleMileageAllocationRecord.confirmed(
    id: id,
    vehicleId: 'vehicle-1',
    sourceType: 'odometer',
    sourceId: sourceId,
    sourceRevision: revision,
    occurredAt: occurredAt ?? DateTime.utc(2026, 8, 1, 12),
    confirmedAt: (occurredAt ?? DateTime.utc(2026, 8, 1, 12)).add(
      const Duration(minutes: 1),
    ),
    use: VehicleMileageAllocationUse.business,
    distanceTenths: 100,
    businessTenths: 100,
  );

  Future<VehicleMileageAllocationDashboardProjection> projection({
    required VehicleMileageAllocationDurableStore store,
    TripTrackingSettings settings = const TripTrackingSettings(
      vehicleMileageAllocationEnabled: true,
    ),
  }) async => VehicleMileageAllocationDashboardProjection.fromDurableStore(
    store: store,
    settings: settings,
    vehicleId: 'vehicle-1',
    from: DateTime.utc(2026, 8, 1),
    until: DateTime.utc(2026, 8, 2),
  );

  test('complete opted-in evidence is projected read-only', () async {
    final store = VehicleMileageAllocationDurableStore(
      records: MaintainiacDurableRecordStore.memory(),
    );
    await store.save(record(id: 'record-1', sourceId: 'source-1'));

    final result = await projection(store: store);

    expect(result.suggestedBusinessPercent, 1);
    expect(result.requiresReview, isFalse);
  });

  test(
    'opt-out suppresses the Dashboard suggestion without deleting evidence',
    () async {
      final store = VehicleMileageAllocationDurableStore(
        records: MaintainiacDurableRecordStore.memory(),
      );
      await store.save(record(id: 'record-1', sourceId: 'source-1'));

      final result = await projection(
        store: store,
        settings: const TripTrackingSettings(),
      );

      expect(result.suggestedBusinessPercent, isNull);
      expect(store.recover().records, hasLength(1));
    },
  );

  test(
    'duplicate source evidence requires review instead of a percentage',
    () async {
      final store = VehicleMileageAllocationDurableStore(
        records: MaintainiacDurableRecordStore.memory(),
      );
      await store.save(record(id: 'record-1', sourceId: 'source-1'));
      await store.save(record(id: 'record-2', sourceId: 'source-1'));

      final result = await projection(store: store);

      expect(result.duplicateSourceReviewRequired, isTrue);
      expect(result.suggestedBusinessPercent, isNull);
    },
  );

  test(
    'a duplicate outside the reporting period does not suppress it',
    () async {
      final store = VehicleMileageAllocationDurableStore(
        records: MaintainiacDurableRecordStore.memory(),
      );
      await store.save(record(id: 'record-1', sourceId: 'source-1'));
      await store.save(
        record(
          id: 'record-2',
          sourceId: 'source-1',
          occurredAt: DateTime.utc(2026, 7, 1, 12),
        ),
      );

      final result = await projection(store: store);

      expect(result.duplicateSourceReviewRequired, isFalse);
      expect(result.suggestedBusinessPercent, 1);
    },
  );
}
