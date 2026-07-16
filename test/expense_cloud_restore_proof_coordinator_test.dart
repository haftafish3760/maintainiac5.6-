import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/expenses/data/expense_cloud_proof_cache.dart';
import 'package:maintaniac/screens/expenses/data/expense_cloud_proof_storage.dart';
import 'package:maintaniac/screens/expenses/data/expense_cloud_restore_codec.dart';
import 'package:maintaniac/screens/expenses/data/expense_cloud_restore_proof_coordinator.dart';
import 'package:maintaniac/screens/expenses/data/expense_cloud_restore_session.dart';
import 'package:maintaniac/screens/expenses/data/expense_cloud_restore_storage_plan.dart';

void main() {
  late Directory hiveDirectory;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('proof-restore-');
    Hive.init(hiveDirectory.path);
  });

  setUp(() async {
    for (final name in [
      ExpenseCloudRestoreSessionStore.boxName,
      ExpenseCloudRestoreProofCheckpointStore.boxName,
    ]) {
      if (Hive.isBoxOpen(name)) await Hive.box<dynamic>(name).close();
      await Hive.deleteBoxFromDisk(name);
    }
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  test('checkpoints a proof before completing a full restore', () async {
    final sessions = await ExpenseCloudRestoreSessionStore.create();
    await sessions.savePrepared(
      id: 'restore-1',
      requestId: 'request-1',
      plan: ExpenseCloudRestoreStoragePlan.forMode(
        mode: ExpenseCloudRestoreMode.full,
        estimate: const ExpenseCloudRestoreEstimate(
          recordCount: 0,
          proofCount: 1,
          cloudProofCount: 1,
          metadataOnlyProofCount: 0,
          knownProofBytes: 3,
          proofsWithUnknownSize: 0,
        ),
        availableBytes: 100,
      ),
      totalRecords: 0,
    );
    final root = await Directory.systemTemp.createTemp('proof-cache-');
    addTearDown(() => root.delete(recursive: true));
    final store = _MemoryObjectStore();
    final cloud = ExpenseCloudProofStorage(objectStore: store);
    final reference = (await cloud.uploadProof(
      organizationId: 'org_1',
      userId: 'user_1',
      receiptId: 'receipt_1',
      proofId: 'proof_1',
      uploadGrantId: 'grant_1',
      bytes: Uint8List.fromList([1, 2, 3]),
      contentType: 'image/jpeg',
    )).finalized();
    final coordinator = ExpenseCloudRestoreProofCoordinator(
      cache: ExpenseCloudProofCache(
        cloudStorage: cloud,
        rootDirectory: () async => root,
        ensureSpace: (_) async {},
      ),
      sessions: sessions,
      checkpoints: await ExpenseCloudRestoreProofCheckpointStore.create(),
    );

    final result = await coordinator.restoreFullProofs(
      sessionId: 'restore-1',
      references: [reference],
    );

    expect(result.restoredCount, 1);
    expect(store.downloadCount, 1);
    expect(
      sessions.sessionById('restore-1')?.state,
      ExpenseCloudRestoreSessionState.completed,
    );
  });

  test(
    'resumes from a durable proof checkpoint without downloading again',
    () async {
      final sessions = await ExpenseCloudRestoreSessionStore.create();
      await sessions.savePrepared(
        id: 'restore-1',
        requestId: 'request-1',
        plan: ExpenseCloudRestoreStoragePlan.forMode(
          mode: ExpenseCloudRestoreMode.full,
          estimate: const ExpenseCloudRestoreEstimate(
            recordCount: 0,
            proofCount: 1,
            cloudProofCount: 1,
            metadataOnlyProofCount: 0,
            knownProofBytes: 3,
            proofsWithUnknownSize: 0,
          ),
          availableBytes: 100,
        ),
        totalRecords: 0,
      );
      final store = _MemoryObjectStore();
      final cloud = ExpenseCloudProofStorage(objectStore: store);
      final reference = (await cloud.uploadProof(
        organizationId: 'org_1',
        userId: 'user_1',
        receiptId: 'receipt_1',
        proofId: 'proof_1',
        uploadGrantId: 'grant_1',
        bytes: Uint8List.fromList([1, 2, 3]),
        contentType: 'image/jpeg',
      )).finalized();
      final checkpoints =
          await ExpenseCloudRestoreProofCheckpointStore.create();
      final root = await Directory.systemTemp.createTemp('proof-cache-');
      addTearDown(() => root.delete(recursive: true));
      final cache = ExpenseCloudProofCache(
        cloudStorage: cloud,
        rootDirectory: () async => root,
        ensureSpace: (_) async {},
      );
      await cache.restore(reference);
      await checkpoints.markCompleted('restore-1', reference);
      final downloadsBeforeResume = store.downloadCount;

      final result = await ExpenseCloudRestoreProofCoordinator(
        cache: cache,
        sessions: sessions,
        checkpoints: checkpoints,
      ).restoreFullProofs(sessionId: 'restore-1', references: [reference]);

      expect(result.restoredCount, 0);
      expect(store.downloadCount, downloadsBeforeResume);
      expect(
        sessions.sessionById('restore-1')?.state,
        ExpenseCloudRestoreSessionState.completed,
      );
    },
  );
}

class _MemoryObjectStore implements ExpenseCloudProofObjectStore {
  final _objects = <String, Uint8List>{};
  var downloadCount = 0;

  @override
  Future<Uint8List> download({
    required String path,
    required int maxBytes,
  }) async {
    downloadCount += 1;
    return _objects[path]!;
  }

  @override
  Future<void> upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
    required Map<String, String> metadata,
  }) async {
    _objects[path] = bytes;
  }
}
