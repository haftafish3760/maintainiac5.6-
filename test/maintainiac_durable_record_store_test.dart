import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/records/maintainiac_durable_record_store.dart';
import 'package:maintaniac/shared/records/maintainiac_record_lifecycle.dart';
import 'package:maintaniac/shared/storage/app_storage_guard.dart';

void main() {
  test('shared confirmed records survive a local Hive restart', () async {
    final directory = await Directory.systemTemp.createTemp(
      'maintainiac_durable_record_store_',
    );
    addTearDown(() async {
      await Hive.close();
      if (await directory.exists()) await directory.delete(recursive: true);
    });
    Hive.init(directory.path);
    final first = await MaintainiacDurableRecordStore.create('shared-records');
    await first.save(
      module: 'maintenance',
      id: 'record-1',
      payload: {
        'title': 'Oil change',
        'line': {'amount': 42.50},
      },
      now: DateTime.utc(2026, 7, 15),
    );

    await Hive.close();
    Hive.init(directory.path);
    final reopened = await MaintainiacDurableRecordStore.create(
      'shared-records',
    );

    expect(reopened.recordFor('maintenance', 'record-1')?.payload, {
      'title': 'Oil change',
      'line': {'amount': 42.50},
    });
  });

  test('shared confirmed records save, delete, and restore locally', () async {
    final store = MaintainiacDurableRecordStore.memory();
    final created = DateTime.utc(2026, 7, 15, 12);
    final saved = await store.save(
      module: 'maintenance',
      id: 'record-1',
      payload: const {'title': 'Oil'},
      now: created,
    );
    final deleted = await store.delete(
      'maintenance',
      'record-1',
      now: created.add(const Duration(minutes: 1)),
    );
    final restored = await store.restore(
      'maintenance',
      'record-1',
      now: created.add(const Duration(minutes: 2)),
    );
    expect(saved.lifecycle.revision, 1);
    expect(deleted?.lifecycle.isDeleted, isTrue);
    expect(restored?.lifecycle.isActive, isTrue);
    expect(store.recordsFor('maintenance'), hasLength(1));
  });

  test(
    'shared confirmed records never claim a write when storage is full',
    () async {
      final store = MaintainiacDurableRecordStore.memory(
        storageCheck: () async => const AppStorageCheck(
          availableBytes: 0,
          operationBytes: 1,
          requiredBytes: 2,
          purpose: AppStoragePurpose.smallRecordWrite,
        ),
      );
      await expectLater(
        () => store.save(
          module: 'maintenance',
          id: 'record-1',
          payload: const {},
        ),
        throwsStateError,
      );
      expect(store.recordFor('maintenance', 'record-1'), isNull);
    },
  );

  test('shared confirmed records isolate nested payloads from callers', () {
    final nested = <String, dynamic>{'amount': 10};
    final record = MaintainiacDurableRecord(
      module: 'expenses',
      id: 'record-1',
      payload: {'line': nested},
      lifecycle: MaintainiacRecordLifecycle(
        createdAt: DateTime.utc(2026, 7, 15),
        updatedAt: DateTime.utc(2026, 7, 15),
      ),
    );

    nested['amount'] = 20;

    expect((record.payload['line'] as Map)['amount'], 10);
    expect(
      () => (record.payload['line'] as Map)['amount'] = 30,
      throwsUnsupportedError,
    );
  });

  test('corrupt durable lifecycle dates are rejected during recovery', () {
    expect(
      () => MaintainiacDurableRecord.fromMap({
        'module': 'expenses',
        'id': 'record-1',
        'payload': const {},
        'lifecycle': {'updatedAt': '2026-07-15T00:00:00.000Z', 'revision': 1},
      }),
      throwsFormatException,
    );
  });

  test(
    'malformed recovered records are ignored without crashing recovery',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'maintainiac_corrupt_record_recovery_',
      );
      addTearDown(() async {
        await Hive.close();
        if (await directory.exists()) await directory.delete(recursive: true);
      });
      Hive.init(directory.path);
      final recordsBox = await Hive.openBox<dynamic>('corrupt-records');
      final draftsBox = await Hive.openBox<dynamic>(
        MaintainiacRecordDraftStore.boxName,
      );
      const malformed = {
        'module': 'expenses',
        'id': 'record-1',
        'payload': <String, dynamic>{},
        'lifecycle': {
          'createdAt': '2026-07-15T00:00:00.000Z',
          'updatedAt': '2026-07-15T00:00:00.000Z',
          'revision': 1,
          'state': 99,
        },
      };
      await recordsBox.put('expenses:record-1', malformed);
      await draftsBox.put('expenses:record-1', malformed);

      final records = await MaintainiacDurableRecordStore.create(
        'corrupt-records',
      );
      final drafts = await MaintainiacRecordDraftStore.create();

      expect(records.recordFor('expenses', 'record-1'), isNull);
      expect(drafts.draftFor('expenses', 'record-1'), isNull);
    },
  );

  test(
    'confirmed records acknowledge only the matching draft checkpoint',
    () async {
      final records = MaintainiacDurableRecordStore.memory();
      final drafts = MaintainiacRecordDraftStore.memory();
      final checkpoint = await drafts.save(
        module: 'expenses',
        id: 'receipt-1',
        payload: const {'merchant': 'Local draft'},
        now: DateTime.utc(2026, 7, 15),
      );

      final saved = await records.saveAndAcknowledgeDraft(
        module: 'expenses',
        id: 'receipt-1',
        payload: const {'merchant': 'Confirmed receipt'},
        draftStore: drafts,
        expectedDraftUpdatedAt: checkpoint.lifecycle.updatedAt,
        now: DateTime.utc(2026, 7, 15, 1),
      );

      expect(saved.payload['merchant'], 'Confirmed receipt');
      expect(drafts.draftFor('expenses', 'receipt-1'), isNull);
      final acknowledged = drafts.draftFor(
        'expenses',
        'receipt-1',
        includeDeleted: true,
      );
      expect(acknowledged?.lifecycle.isDeleted, isTrue);
      expect(acknowledged?.payload['merchant'], 'Local draft');
    },
  );

  test(
    'confirmed records retain a newer draft checkpoint for recovery',
    () async {
      final records = MaintainiacDurableRecordStore.memory();
      final drafts = MaintainiacRecordDraftStore.memory();
      final checkpoint = await drafts.save(
        module: 'expenses',
        id: 'receipt-1',
        payload: const {'merchant': 'Original draft'},
        now: DateTime.utc(2026, 7, 15),
      );
      await drafts.save(
        module: 'expenses',
        id: 'receipt-1',
        payload: const {'merchant': 'Newer edit'},
        now: DateTime.utc(2026, 7, 15, 1),
      );

      await records.saveAndAcknowledgeDraft(
        module: 'expenses',
        id: 'receipt-1',
        payload: const {'merchant': 'Confirmed receipt'},
        draftStore: drafts,
        expectedDraftUpdatedAt: checkpoint.lifecycle.updatedAt,
        now: DateTime.utc(2026, 7, 15, 2),
      );

      expect(
        drafts.draftFor('expenses', 'receipt-1')?.payload['merchant'],
        'Newer edit',
      );
    },
  );
}
