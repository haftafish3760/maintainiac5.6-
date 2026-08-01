// Deterministic stress regression for vehicle mileage allocation integrity.
// Owns bounded revision, classification, and period-total checks. It does not
// simulate GPS, persist data, or validate an Expense user interface.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/vehicle_mileage_allocation.dart';
import 'package:maintaniac/shared/trip_tracking/vehicle_mileage_allocation_ledger.dart';

void main() {
  test(
    '20,000 deterministic allocation revisions retain only valid evidence',
    () {
      const seed = 72720260801;
      final random = Random(seed);
      var ledger = VehicleMileageAllocationLedger.empty();
      final expectedBySource = <String, VehicleMileageAllocationRecord>{};
      final periodStart = DateTime.utc(2026, 1, 1);

      for (var index = 0; index < 20000; index++) {
        final vehicleId = 'vehicle-${random.nextInt(5)}';
        final sourceId = 'source-${random.nextInt(600)}';
        final sourceKey = '$vehicleId:trip_review:$sourceId';
        final existing = expectedBySource[sourceKey];
        final revision = switch (random.nextInt(4)) {
          0 => existing?.sourceRevision ?? 0,
          1 => (existing?.sourceRevision ?? 0) + 1,
          _ => random.nextInt((existing?.sourceRevision ?? 0) + 1),
        };
        final distanceTenths = random.nextInt(5000) + 1;
        final requestedUse = VehicleMileageAllocationUse
            .values[random.nextInt(VehicleMileageAllocationUse.values.length)];
        final use =
            requestedUse == VehicleMileageAllocationUse.split &&
                distanceTenths < 2
            ? VehicleMileageAllocationUse.business
            : requestedUse;
        final businessTenths = use == VehicleMileageAllocationUse.split
            ? random.nextInt(distanceTenths - 1) + 1
            : null;
        final occurredAt = periodStart.add(
          Duration(hours: random.nextInt(8760)),
        );
        final record = VehicleMileageAllocationRecord.confirmed(
          id: 'allocation-$index',
          vehicleId: vehicleId,
          sourceType: 'trip_review',
          sourceId: sourceId,
          sourceRevision: revision,
          occurredAt: occurredAt,
          confirmedAt: occurredAt.add(const Duration(minutes: 1)),
          use: use,
          distanceTenths: distanceTenths,
          businessTenths: businessTenths,
        );

        final result = ledger.ingest(record);
        ledger = result.ledger;
        final expected = expectedBySource[sourceKey];
        if (expected == null ||
            record.sourceRevision > expected.sourceRevision) {
          expectedBySource[sourceKey] = record;
        }
      }

      expect(ledger.records, hasLength(expectedBySource.length));
      expect(ledger.records.every((record) => record.isValid), isTrue);

      for (var vehicle = 0; vehicle < 5; vehicle++) {
        final vehicleId = 'vehicle-$vehicle';
        final summary = ledger.summaryFor(
          vehicleId: vehicleId,
          from: periodStart,
          until: periodStart.add(const Duration(days: 366)),
        );
        final expected = expectedBySource.values.where(
          (record) => record.vehicleId == vehicleId,
        );
        expect(
          summary.totalTenths,
          expected.fold(0, (total, record) => total + record.distanceTenths),
        );
        expect(
          summary.businessTenths +
              summary.personalTenths +
              summary.unclassifiedTenths,
          summary.totalTenths,
        );
      }
    },
  );
}
