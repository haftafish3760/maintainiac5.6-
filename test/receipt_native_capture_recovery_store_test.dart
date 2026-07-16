import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/storage/app_storage_guard.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_native_capture_recovery_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'receipt_capture_recovery_store_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    if (Hive.isBoxOpen(ReceiptNativeCaptureRecoveryStore.boxName)) {
      await Hive.box<dynamic>(
        ReceiptNativeCaptureRecoveryStore.boxName,
      ).close();
    }
    if (await hiveDirectory.exists()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  test('does not write a recovery index when storage is full', () async {
    final store = await ReceiptNativeCaptureRecoveryStore.create(
      storageCheck: () async => const AppStorageCheck(
        availableBytes: 0,
        operationBytes: AppStorageGuard.smallRecordWriteBytes,
        requiredBytes:
            AppStorageGuard.minimumDeviceReserveBytes +
            AppStorageGuard.smallRecordWriteBytes,
        purpose: AppStoragePurpose.smallRecordWrite,
      ),
    );

    await expectLater(store.save(_entry()), throwsA(isA<StateError>()));

    expect(store.entries, isEmpty);
  });

  test('serializes recovery index writes and diagnostics updates', () async {
    final store = await ReceiptNativeCaptureRecoveryStore.create(
      storageCheck: () async => const AppStorageCheck(
        availableBytes: 1024 * 1024 * 1024,
        operationBytes: AppStorageGuard.smallRecordWriteBytes,
        requiredBytes:
            AppStorageGuard.minimumDeviceReserveBytes +
            AppStorageGuard.smallRecordWriteBytes,
        purpose: AppStoragePurpose.smallRecordWrite,
      ),
    );
    final entry = _entry();

    await Future.wait([
      store.save(entry),
      store.updateDiagnosticsByManifestPath(entry.manifestPath, {
        'resumeCheckpoint': 'review_ready',
      }),
    ]);

    expect(store.entries, hasLength(1));
    expect(
      store.entries.single.captureDiagnostics,
      containsPair('resumeCheckpoint', 'review_ready'),
    );
  });
}

ReceiptNativeCaptureRecoveryIndexEntry _entry() {
  return ReceiptNativeCaptureRecoveryIndexEntry(
    sessionId: 'recovery-session',
    manifestPath: '/tmp/recovery-manifest.json',
    engineName: 'system_camera',
    capturedAt: DateTime(2026, 7, 16),
    dataSaverLevelName: 'balanced',
    photoCount: 1,
    stagedPhotoPaths: const ['/tmp/recovery-photo.jpg'],
    attachments: const [],
    captureDiagnostics: const {},
  );
}
