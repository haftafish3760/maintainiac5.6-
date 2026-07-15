import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/expenses/data/expense_cloud_restore_codec.dart';
import 'package:maintaniac/screens/expenses/data/expense_cloud_restore_session.dart';
import 'package:maintaniac/screens/expenses/data/expense_cloud_restore_storage_plan.dart';

void main() {
  late Directory hiveDirectory;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'maintainiac_restore_session_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  setUp(() async {
    if (Hive.isBoxOpen(ExpenseCloudRestoreSessionStore.boxName)) {
      await Hive.box<dynamic>(ExpenseCloudRestoreSessionStore.boxName).close();
    }
    await Hive.deleteBoxFromDisk(ExpenseCloudRestoreSessionStore.boxName);
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  final plan = ExpenseCloudRestoreStoragePlan.forMode(
    mode: ExpenseCloudRestoreMode.smart,
    estimate: const ExpenseCloudRestoreEstimate(
      recordCount: 3,
      proofCount: 0,
      cloudProofCount: 0,
      metadataOnlyProofCount: 0,
      knownProofBytes: 0,
      proofsWithUnknownSize: 0,
    ),
    structuredRecordBytes: 100,
    availableBytes: 200,
  );

  test('persists resumable progress without an authorization token', () async {
    final store = await ExpenseCloudRestoreSessionStore.create();
    await store.savePrepared(
      id: 'restore-1',
      requestId: 'server-request-1',
      plan: plan,
      totalRecords: 3,
      nowUtc: DateTime.utc(2026, 7, 15),
    );
    await store.updateProgress(
      id: 'restore-1',
      completedDownloadBytes: 50,
      completedRecords: 1,
      nowUtc: DateTime.utc(2026, 7, 15, 1),
    );
    await store.pause('restore-1', nowUtc: DateTime.utc(2026, 7, 15, 2));

    final session = store.sessionById('restore-1')!;
    expect(session.state, ExpenseCloudRestoreSessionState.paused);
    expect(session.canResume, isTrue);
    expect(session.completedDownloadBytes, 50);
    expect(session.completedRecords, 1);
    expect(session.toMap().containsKey('authorizationToken'), isFalse);
    expect(session.toMap().containsKey('proofPath'), isFalse);
  });

  test('prevents a restore from beginning without safe storage', () async {
    final store = await ExpenseCloudRestoreSessionStore.create();
    final unsafePlan = ExpenseCloudRestoreStoragePlan.forMode(
      mode: ExpenseCloudRestoreMode.full,
      estimate: const ExpenseCloudRestoreEstimate(
        recordCount: 1,
        proofCount: 1,
        cloudProofCount: 1,
        metadataOnlyProofCount: 0,
        knownProofBytes: 1000,
        proofsWithUnknownSize: 0,
      ),
      availableBytes: 1,
    );

    await expectLater(
      store.savePrepared(
        id: 'unsafe',
        requestId: 'server-request',
        plan: unsafePlan,
        totalRecords: 1,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('never allows terminal sessions to be modified', () async {
    final store = await ExpenseCloudRestoreSessionStore.create();
    await store.savePrepared(
      id: 'restore-2',
      requestId: 'server-request-2',
      plan: plan,
      totalRecords: 3,
    );
    await store.updateProgress(
      id: 'restore-2',
      completedDownloadBytes: 100,
      completedRecords: 3,
    );
    await store.complete('restore-2');

    await expectLater(
      store.updateProgress(
        id: 'restore-2',
        completedDownloadBytes: 1,
        completedRecords: 1,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('does not resume corrupt local restore session state', () async {
    final store = await ExpenseCloudRestoreSessionStore.create();
    await Hive.box<dynamic>(
      ExpenseCloudRestoreSessionStore.boxName,
    ).put('corrupt-restore', {
      'id': 'corrupt-restore',
      'requestId': 'server-request-corrupt',
      'mode': 'smart',
      'state': 'transferring',
      'createdAt': '2026-07-15T00:00:00.000Z',
      'updatedAt': '2026-07-15T00:00:00.000Z',
      'expectedDownloadBytes': 10,
      'completedDownloadBytes': 11,
      'totalRecords': 1,
      'completedRecords': 1,
    });

    expect(store.sessionById('corrupt-restore'), isNull);

    await Hive.box<dynamic>(
      ExpenseCloudRestoreSessionStore.boxName,
    ).put('missing-request', {
      'id': 'missing-request',
      'mode': 'smart',
      'state': 'prepared',
      'createdAt': '2026-07-15T00:00:00.000Z',
      'updatedAt': '2026-07-15T00:00:00.000Z',
      'expectedDownloadBytes': 0,
      'completedDownloadBytes': 0,
      'totalRecords': 0,
      'completedRecords': 0,
    });
    expect(store.sessionById('missing-request'), isNull);
  });

  test('does not mark an incomplete restore as completed', () async {
    final store = await ExpenseCloudRestoreSessionStore.create();
    await store.savePrepared(
      id: 'restore-incomplete',
      requestId: 'server-request-incomplete',
      plan: plan,
      totalRecords: 3,
    );

    await expectLater(
      store.complete('restore-incomplete'),
      throwsA(isA<StateError>()),
    );

    final session = store.sessionById('restore-incomplete')!;
    expect(session.state, ExpenseCloudRestoreSessionState.prepared);
    expect(session.completedDownloadBytes, 0);
    expect(session.completedRecords, 0);
  });

  test(
    'an active restore session cannot be rebound to another request',
    () async {
      final store = await ExpenseCloudRestoreSessionStore.create();
      await store.savePrepared(
        id: 'restore-request-binding',
        requestId: 'server-request-original',
        plan: plan,
        totalRecords: 3,
      );

      await expectLater(
        store.savePrepared(
          id: 'restore-request-binding',
          requestId: 'server-request-other',
          plan: plan,
          totalRecords: 3,
        ),
        throwsA(isA<StateError>()),
      );
    },
  );

  test('delayed restore progress cannot move a session backward', () async {
    final store = await ExpenseCloudRestoreSessionStore.create();
    await store.savePrepared(
      id: 'restore-progress-order',
      requestId: 'server-request-progress-order',
      plan: plan,
      totalRecords: 3,
    );

    await Future.wait([
      store.updateProgress(
        id: 'restore-progress-order',
        completedDownloadBytes: 75,
        completedRecords: 2,
      ),
      store.updateProgress(
        id: 'restore-progress-order',
        completedDownloadBytes: 10,
        completedRecords: 1,
      ),
    ]);

    final session = store.sessionById('restore-progress-order')!;
    expect(session.completedDownloadBytes, 75);
    expect(session.completedRecords, 2);
  });

  test(
    'a resumed plan bounds retained progress to its verified size',
    () async {
      final store = await ExpenseCloudRestoreSessionStore.create();
      await store.savePrepared(
        id: 'restore-replan',
        requestId: 'server-request-replan',
        plan: plan,
        totalRecords: 3,
      );
      await store.updateProgress(
        id: 'restore-replan',
        completedDownloadBytes: 100,
        completedRecords: 3,
      );
      await store.savePrepared(
        id: 'restore-replan',
        requestId: 'server-request-replan',
        plan: ExpenseCloudRestoreStoragePlan.forMode(
          mode: ExpenseCloudRestoreMode.recordsOnly,
          estimate: const ExpenseCloudRestoreEstimate(
            recordCount: 1,
            proofCount: 0,
            cloudProofCount: 0,
            metadataOnlyProofCount: 0,
            knownProofBytes: 0,
            proofsWithUnknownSize: 0,
          ),
          structuredRecordBytes: 10,
          availableBytes: 200,
        ),
        totalRecords: 1,
      );
      final session = store.sessionById('restore-replan')!;
      expect(
        session.completedDownloadBytes,
        lessThanOrEqualTo(session.expectedDownloadBytes),
      );
      expect(session.completedRecords, 1);
    },
  );
}
