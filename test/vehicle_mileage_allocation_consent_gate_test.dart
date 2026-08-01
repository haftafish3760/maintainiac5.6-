// Regression coverage for the vehicle-use allocation opt-in boundary.
//
// Owns consent-gate tests. It does not test Expense category allocation,
// durable storage, raw GPS, or odometer classification. The Dashboard and
// future durable allocation repository depend on this boundary.

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';
import 'package:maintaniac/shared/trip_tracking/vehicle_mileage_allocation.dart';
import 'package:maintaniac/shared/trip_tracking/vehicle_mileage_allocation_consent_gate.dart';
import 'package:maintaniac/shared/trip_tracking/vehicle_mileage_allocation_ledger.dart';

void main() {
  final record = VehicleMileageAllocationRecord.confirmed(
    id: 'record-1',
    vehicleId: 'vehicle-1',
    sourceType: 'odometer_event',
    sourceId: 'event-1',
    sourceRevision: 1,
    occurredAt: DateTime.utc(2026, 8, 1, 12),
    confirmedAt: DateTime.utc(2026, 8, 1, 12, 1),
    use: VehicleMileageAllocationUse.business,
    distanceTenths: 125,
    businessTenths: 125,
  );

  test('disabled opt-in retains no allocation history', () {
    final result = ingestVehicleMileageAllocationIfOptedIn(
      settings: const TripTrackingSettings(),
      ledger: VehicleMileageAllocationLedger.empty(),
      record: record,
    );

    expect(
      result.decision,
      VehicleMileageAllocationConsentDecision.optInRequired,
    );
    expect(result.ledger.records, isEmpty);
  });

  test(
    'explicit opt-in permits confirmed evidence and preserves ledger rules',
    () {
      final result = ingestVehicleMileageAllocationIfOptedIn(
        settings: const TripTrackingSettings(
          vehicleMileageAllocationEnabled: true,
        ),
        ledger: VehicleMileageAllocationLedger.empty(),
        record: record,
      );

      expect(result.decision, VehicleMileageAllocationConsentDecision.accepted);
      expect(result.ledger.records, hasLength(1));
      expect(result.ledger.records.single.businessTenths, 125);
      expect(result.changed, isTrue);
    },
  );

  test('enabled opt-in cannot disguise duplicate evidence as a new write', () {
    final first = ingestVehicleMileageAllocationIfOptedIn(
      settings: const TripTrackingSettings(
        vehicleMileageAllocationEnabled: true,
      ),
      ledger: VehicleMileageAllocationLedger.empty(),
      record: record,
    );
    final duplicate = ingestVehicleMileageAllocationIfOptedIn(
      settings: const TripTrackingSettings(
        vehicleMileageAllocationEnabled: true,
      ),
      ledger: first.ledger,
      record: record,
    );

    expect(duplicate.changed, isFalse);
    expect(
      duplicate.ingestResult!.status,
      VehicleMileageAllocationIngestStatus.duplicateRevision,
    );
  });
}
