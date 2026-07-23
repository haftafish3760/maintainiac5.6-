import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/durable_storage/maintainiac_durable_storage.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('storage_warning_test_');
    Hive.init(directory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (directory.existsSync()) await directory.delete(recursive: true);
  });

  test('default warns at every low-storage level', () {
    final snapshot = AppStorageWarningSnapshot.defaults();
    expect(snapshot.shouldShow(AppStorageLevel.green), isFalse);
    expect(snapshot.shouldShow(AppStorageLevel.yellow), isTrue);
    expect(snapshot.shouldShow(AppStorageLevel.orange), isTrue);
    expect(snapshot.shouldShow(AppStorageLevel.red), isTrue);
  });

  test('show below 500 MB suppresses yellow but retains urgent warnings', () {
    final snapshot = AppStorageWarningSnapshot(
      preference: AppStorageWarningPreference.below500Mb,
      revision: 1,
      updatedAtUtc: DateTime.utc(2026, 7, 22),
    );
    expect(snapshot.shouldShow(AppStorageLevel.yellow), isFalse);
    expect(snapshot.shouldShow(AppStorageLevel.orange), isTrue);
    expect(snapshot.shouldShow(AppStorageLevel.red), isTrue);
  });

  test('preference saves immediately and survives restart', () async {
    final store = await AppStorageWarningPreferenceStore.create();
    await store.save(
      AppStorageWarningPreference.never,
      nowUtc: DateTime.utc(2026, 7, 22),
    );
    await Hive.close();
    Hive.init(directory.path);
    final reopened = await AppStorageWarningPreferenceStore.create();
    expect(reopened.snapshot.preference, AppStorageWarningPreference.never);
    expect(reopened.snapshot.revision, 1);
  });

  test('failed preference write preserves prior choice', () async {
    var hasSpace = true;
    final store = AppStorageWarningPreferenceStore.memory(
      storageCheck: () async => AppStorageCheck(
        availableBytes: hasSpace ? 100 : 0,
        operationBytes: 1,
        requiredBytes: 1,
        purpose: AppStoragePurpose.smallRecordWrite,
      ),
    );
    await store.save(AppStorageWarningPreference.below500Mb);
    hasSpace = false;
    await expectLater(
      store.save(AppStorageWarningPreference.never),
      throwsStateError,
    );
    expect(store.snapshot.preference, AppStorageWarningPreference.below500Mb);
  });
}
