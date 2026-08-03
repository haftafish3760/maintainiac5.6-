import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/durable_storage/maintainiac_durable_storage.dart';
import 'package:maintaniac/shared/trip_tracking/vehicle_mileage_allocation.dart';

void main() {
  VehicleMileageAllocationRecord allocation({
    required String id,
    int sourceRevision = 1,
  }) => VehicleMileageAllocationRecord.confirmed(
    id: id,
    vehicleId: 'vehicle-1',
    sourceType: 'trip',
    sourceId: 'trip-1',
    sourceRevision: sourceRevision,
    occurredAt: DateTime.utc(2026, 8, 1, 10),
    confirmedAt: DateTime.utc(2026, 8, 1, 10, 1),
    use: VehicleMileageAllocationUse.split,
    distanceTenths: 555,
    businessTenths: 400,
  );

  test(
    'preserves the Trip Tracking allocation contract in one durable record',
    () async {
      final bucket = VehicleMileageAllocationDurableStore(
        records: MaintainiacDurableRecordStore.memory(),
      );

      final saved = await bucket.save(
        allocation(id: 'allocation-1'),
        now: DateTime.utc(2026, 8, 1, 11),
      );

      expect(saved.id, 'allocation-1');
      expect(saved.lifecycle.revision, 1);
      expect(saved.lifecycle.auditEvents, hasLength(1));
      expect(saved.allocation.businessTenths, 400);
      expect(saved.allocation.personalTenths, 155);
      expect(saved.allocation.unclassifiedTenths, 0);
    },
  );

  test(
    'updates the stable allocation ID with lifecycle revision history',
    () async {
      final bucket = VehicleMileageAllocationDurableStore(
        records: MaintainiacDurableRecordStore.memory(),
      );
      final first = await bucket.save(allocation(id: 'allocation-1'));
      final updated = await bucket.save(
        allocation(id: 'allocation-1', sourceRevision: 2),
        expectedRevision: first.lifecycle.revision,
        now: DateTime.utc(2026, 8, 2),
      );

      expect(updated.lifecycle.revision, 2);
      expect(updated.allocation.sourceRevision, 2);
      expect(updated.lifecycle.auditEvents, hasLength(2));
    },
  );

  test('uses the central private durable-record cloud envelope', () async {
    final records = MaintainiacDurableRecordStore.memory();
    final bucket = VehicleMileageAllocationDurableStore(records: records);
    await bucket.save(allocation(id: 'allocation-1'));
    final record = records.recordFor(
      VehicleMileageAllocationDurableStore.module,
      'allocation-1',
    )!;

    final document = MaintainiacFirestoreDurableRecordCodec.encode(
      organizationId: 'org-a',
      uid: 'user-a',
      accountScopeId: 'org-a.user-a',
      schemaVersion: VehicleMileageAllocationDurableStore.schemaVersion,
      record: record,
    );

    expect(document.path, startsWith('orgs/org-a/records/'));
    expect(
      document.data['module'],
      VehicleMileageAllocationDurableStore.module,
    );
    expect(document.data['recordSchemaVersion'], 1);
    expect(VehicleMileageAllocationDurableStore.cloudSchemaVersions, const {
      VehicleMileageAllocationDurableStore.module: 1,
    });
    expect(document.data['privateToOwner'], isTrue);
    expect(document.data['recordPayload'], isNot(contains('deviceId')));
  });

  test(
    'queues one versioned record through the shared cloud gateway',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'vehicle_mileage_allocation_queue_',
      );
      Hive.init(directory.path);
      try {
        final records = MaintainiacDurableRecordStore.memory();
        final bucket = VehicleMileageAllocationDurableStore(records: records);
        await bucket.save(allocation(id: 'allocation-1'));
        final queue = await MaintainiacFirestoreUploadQueueStore.create();
        final gateway = MaintainiacDurableCloudBackupGateway(
          records: records,
          queue: queue,
          identityProvider: const _Identity('user-a'),
        );

        final queued = await bucket.queueForBackup(
          gateway: gateway,
          organizationId: 'org-a',
          queuedAtUtc: DateTime.utc(2026, 8, 1, 12),
        );

        expect(queued, hasLength(1));
        expect(queue.pendingRecords, hasLength(1));
        expect(
          queued.single.data['module'],
          VehicleMileageAllocationDurableStore.module,
        );
        expect(queued.single.data['recordSchemaVersion'], 1);
      } finally {
        await Hive.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test(
    'reports malformed and duplicate records without deleting either',
    () async {
      final records = MaintainiacDurableRecordStore.memory();
      final bucket = VehicleMileageAllocationDurableStore(records: records);
      await bucket.save(allocation(id: 'allocation-1'));
      await bucket.save(allocation(id: 'allocation-2'));
      await records.save(
        module: VehicleMileageAllocationDurableStore.module,
        id: 'bad-allocation',
        payload: const {
          'schema': 'vehicle_mileage_allocation_durable_record_v1',
        },
      );

      final recovery = bucket.recover();

      expect(
        recovery.records.map((record) => record.id),
        containsAll(['allocation-1', 'allocation-2']),
      );
      expect(recovery.issues, hasLength(1));
      expect(bucket.duplicateGroups(), hasLength(1));
      expect(bucket.duplicateGroups().single.records, hasLength(2));
      expect(
        records.recordFor(
          VehicleMileageAllocationDurableStore.module,
          'bad-allocation',
        ),
        isNotNull,
      );
    },
  );

  test(
    'rejects an invalid source allocation before writing local storage',
    () async {
      final bucket = VehicleMileageAllocationDurableStore(
        records: MaintainiacDurableRecordStore.memory(),
      );
      final invalid = VehicleMileageAllocationRecord(
        id: 'allocation-1',
        vehicleId: 'vehicle-1',
        sourceType: 'trip',
        sourceId: 'trip-1',
        sourceRevision: 1,
        occurredAt: DateTime.utc(2026, 8, 1),
        confirmedAt: DateTime.utc(2026, 8, 1),
        use: VehicleMileageAllocationUse.business,
        distanceTenths: 10,
        businessTenths: 9,
        personalTenths: 1,
        unclassifiedTenths: 0,
      );

      await expectLater(bucket.save(invalid), throwsArgumentError);
      expect(bucket.recover().records, isEmpty);
    },
  );
}

class _Identity implements MaintainiacCloudIdentityProvider {
  const _Identity(this.currentUid);

  @override
  final String? currentUid;
}
