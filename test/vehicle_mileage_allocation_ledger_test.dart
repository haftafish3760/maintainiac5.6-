// Regression coverage for confirmed vehicle mileage allocation calculations.
//
// Owns precision, source-revision, and transparent-percentage checks. It does
// not test GPS collection, expense persistence, or durable-storage mechanics.

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/vehicle_mileage_allocation.dart';
import 'package:maintaniac/shared/trip_tracking/vehicle_mileage_allocation_ledger.dart';

void main() {
  final occurredAt = DateTime.utc(2026, 8, 1, 12);

  VehicleMileageAllocationRecord record({
    String id = 'allocation-1',
    String vehicleId = 'truck-1',
    String sourceType = 'trip_review',
    String sourceId = 'trip-1',
    int revision = 0,
    VehicleMileageAllocationUse use = VehicleMileageAllocationUse.business,
    int distanceTenths = 1000,
    int? businessTenths,
    DateTime? occurred,
  }) => VehicleMileageAllocationRecord.confirmed(
    id: id,
    vehicleId: vehicleId,
    sourceType: sourceType,
    sourceId: sourceId,
    sourceRevision: revision,
    occurredAt: occurred ?? occurredAt,
    confirmedAt: (occurred ?? occurredAt).add(const Duration(minutes: 1)),
    use: use,
    distanceTenths: distanceTenths,
    businessTenths: businessTenths,
  );

  test('complete period produces an explainable business percentage', () {
    var ledger = VehicleMileageAllocationLedger.empty();
    ledger = ledger
        .ingest(record(distanceTenths: 700, sourceId: 'business'))
        .ledger;
    ledger = ledger
        .ingest(
          record(
            id: 'allocation-2',
            sourceId: 'personal',
            use: VehicleMileageAllocationUse.personal,
            distanceTenths: 300,
          ),
        )
        .ledger;

    final summary = ledger.summaryFor(
      vehicleId: 'truck-1',
      from: occurredAt.subtract(const Duration(days: 1)),
      until: occurredAt.add(const Duration(days: 1)),
    );

    expect(summary.businessTenths, 700);
    expect(summary.personalTenths, 300);
    expect(summary.unclassifiedTenths, 0);
    expect(summary.expenseSuggestedBusinessPercent, .7);
    expect(summary.expenseExplanation, contains('70.0% business'));
  });

  test('unclassified mileage never becomes an expense percentage', () {
    final ledger = VehicleMileageAllocationLedger([
      record(distanceTenths: 700),
      record(
        id: 'allocation-unclassified',
        sourceId: 'unknown-trip',
        use: VehicleMileageAllocationUse.unclassified,
        distanceTenths: 100,
      ),
    ]);

    final summary = ledger.summaryFor(
      vehicleId: 'truck-1',
      from: occurredAt.subtract(const Duration(days: 1)),
      until: occurredAt.add(const Duration(days: 1)),
    );

    expect(summary.businessPercentOfClassified, 1);
    expect(summary.expenseSuggestedBusinessPercent, isNull);
    expect(summary.expenseExplanation, contains('partly unclassified'));
  });

  test('split mileage preserves exact tenth-mile math', () {
    final entry = record(
      use: VehicleMileageAllocationUse.split,
      distanceTenths: 37,
      businessTenths: 12,
    );

    expect(entry.isValid, isTrue);
    expect(entry.businessMiles, 1.2);
    expect(entry.personalMiles, 2.5);
    expect(entry.unclassifiedMiles, 0);
  });

  test('complete mileage exposes an exact ratio beside display percentage', () {
    final ledger = VehicleMileageAllocationLedger([
      record(distanceTenths: 10, sourceId: 'business'),
      record(
        id: 'personal-allocation',
        sourceId: 'personal',
        use: VehicleMileageAllocationUse.personal,
        distanceTenths: 20,
      ),
    ]);

    final summary = ledger.summaryFor(
      vehicleId: 'truck-1',
      from: occurredAt.subtract(const Duration(days: 1)),
      until: occurredAt.add(const Duration(days: 1)),
    );

    expect(summary.expenseBusinessNumeratorTenths, 10);
    expect(summary.expenseClassifiedDenominatorTenths, 30);
    expect(summary.expenseSuggestedBusinessPercent, closeTo(1 / 3, .000001));
  });

  test('duplicate source revision cannot add mileage twice', () {
    final first = record(distanceTenths: 100);
    final ledger = VehicleMileageAllocationLedger.empty().ingest(first).ledger;
    final duplicate = ledger.ingest(first);

    expect(
      duplicate.status,
      VehicleMileageAllocationIngestStatus.duplicateRevision,
    );
    expect(duplicate.ledger.records, hasLength(1));
  });

  test('newer source revision replaces rather than adds mileage', () {
    final ledger = VehicleMileageAllocationLedger.empty()
        .ingest(record(distanceTenths: 100, revision: 0))
        .ledger;
    final replacement = ledger.ingest(record(distanceTenths: 125, revision: 1));

    expect(
      replacement.status,
      VehicleMileageAllocationIngestStatus.replacedOlderRevision,
    );
    expect(replacement.ledger.records.single.distanceTenths, 125);
  });

  test('stale source revision cannot overwrite newer confirmation', () {
    final ledger = VehicleMileageAllocationLedger.empty()
        .ingest(record(distanceTenths: 125, revision: 1))
        .ledger;
    final stale = ledger.ingest(record(distanceTenths: 100, revision: 0));

    expect(stale.status, VehicleMileageAllocationIngestStatus.staleRevision);
    expect(stale.ledger.records.single.distanceTenths, 125);
  });

  test('conflicting equal revisions are never chosen by input ordering', () {
    final business = record(distanceTenths: 100, revision: 3);
    final personal = record(
      id: 'conflicting-allocation',
      revision: 3,
      use: VehicleMileageAllocationUse.personal,
      distanceTenths: 100,
    );

    for (final records in [
      [business, personal],
      [personal, business],
    ]) {
      final ledger = VehicleMileageAllocationLedger(records);
      final summary = ledger.summaryFor(
        vehicleId: 'truck-1',
        from: occurredAt.subtract(const Duration(days: 1)),
        until: occurredAt.add(const Duration(days: 1)),
      );

      expect(ledger.records, isEmpty);
      expect(ledger.conflictedSourceKeys, {'truck-1:trip_review:trip-1'});
      expect(summary.totalTenths, 0);
    }
  });

  test('a conflicting equal revision cannot replace confirmed mileage', () {
    final ledger = VehicleMileageAllocationLedger.empty()
        .ingest(record(distanceTenths: 100, revision: 3))
        .ledger;
    final conflict = ledger.ingest(
      record(
        id: 'conflicting-allocation',
        revision: 3,
        use: VehicleMileageAllocationUse.personal,
        distanceTenths: 100,
      ),
    );

    expect(
      conflict.status,
      VehicleMileageAllocationIngestStatus.conflictingRevision,
    );
    expect(conflict.ledger.records.single.businessTenths, 100);
  });

  test('a newer revision resolves an older conflicting source revision', () {
    final conflictingBusiness = record(distanceTenths: 100, revision: 3);
    final conflictingPersonal = record(
      id: 'conflicting-allocation',
      revision: 3,
      use: VehicleMileageAllocationUse.personal,
      distanceTenths: 100,
    );
    final corrected = record(
      id: 'corrected-allocation',
      revision: 4,
      use: VehicleMileageAllocationUse.split,
      distanceTenths: 100,
      businessTenths: 60,
    );

    final ledger = VehicleMileageAllocationLedger([
      conflictingBusiness,
      conflictingPersonal,
      corrected,
    ]);

    expect(ledger.conflictedSourceKeys, isEmpty);
    expect(ledger.records, [corrected]);
  });

  test('an old conflicting revision cannot resolve a restored conflict', () {
    final business = record(distanceTenths: 100, revision: 3);
    final personal = record(
      id: 'conflicting-allocation',
      revision: 3,
      use: VehicleMileageAllocationUse.personal,
      distanceTenths: 100,
    );
    final restored = VehicleMileageAllocationLedger([business, personal]);

    final replay = restored.ingest(business);

    expect(
      replay.status,
      VehicleMileageAllocationIngestStatus.conflictingRevision,
    );
    expect(replay.ledger.records, isEmpty);
    expect(replay.ledger.conflictedSourceKeys, {'truck-1:trip_review:trip-1'});
  });

  test('allocation records round-trip only when their totals are coherent', () {
    final entry = record(
      use: VehicleMileageAllocationUse.split,
      distanceTenths: 37,
      businessTenths: 12,
    );

    expect(
      VehicleMileageAllocationRecord.fromMap(entry.toMap())?.toMap(),
      entry.toMap(),
    );
    final corrupt = Map<String, Object?>.from(entry.toMap())
      ..['personalTenths'] = 99;
    expect(VehicleMileageAllocationRecord.fromMap(corrupt), isNull);
  });

  test('vehicle and period boundaries isolate a percentage calculation', () {
    final ledger = VehicleMileageAllocationLedger([
      record(distanceTenths: 100),
      record(
        id: 'other-vehicle',
        vehicleId: 'truck-2',
        sourceId: 'truck-2-trip',
        use: VehicleMileageAllocationUse.personal,
        distanceTenths: 100,
      ),
      record(
        id: 'outside-period',
        sourceId: 'old-trip',
        use: VehicleMileageAllocationUse.personal,
        distanceTenths: 100,
        occurred: occurredAt.subtract(const Duration(days: 2)),
      ),
    ]);

    final summary = ledger.summaryFor(
      vehicleId: 'truck-1',
      from: occurredAt.subtract(const Duration(days: 1)),
      until: occurredAt.add(const Duration(days: 1)),
    );

    expect(summary.recordCount, 1);
    expect(summary.businessTenths, 100);
    expect(summary.personalTenths, 0);
  });
}
