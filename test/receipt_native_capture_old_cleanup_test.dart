import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_native_camera_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_native_capture_recovery_store.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_native_capture_staging.dart';

import 'helpers/receipt_native_capture_staging_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory documentsDirectory;
  late Directory hiveDirectory;

  setUp(() async {
    documentsDirectory = await Directory.systemTemp.createTemp(
      'receipt_native_capture_staging_',
    );
    hiveDirectory = await Directory.systemTemp.createTemp(
      'receipt_native_capture_hive_',
    );
    Hive.init(hiveDirectory.path);
    installReceiptNativeCaptureStagingHarness(
      documentsDirectory: () => documentsDirectory,
    );
  });

  tearDown(() async {
    await disposeReceiptNativeCaptureStagingHarness(
      documentsDirectory: documentsDirectory,
      hiveDirectory: hiveDirectory,
    );
  });

  test('old abandoned native staging cleanup keeps retained paths', () async {
    final staging = const ReceiptNativeCaptureStaging();
    final sourceA = File('${Directory.systemTemp.path}/native-old-a.jpg');
    final sourceB = File('${Directory.systemTemp.path}/native-old-b.jpg');
    await sourceA.writeAsBytes(List<int>.filled(64, 1), flush: true);
    await sourceB.writeAsBytes(List<int>.filled(64, 2), flush: true);
    addTearDown(() {
      if (sourceA.existsSync()) sourceA.deleteSync();
      if (sourceB.existsSync()) sourceB.deleteSync();
    });

    final oldA = await staging.stage(
      ReceiptNativeCaptureResult(
        engine: ReceiptNativeCameraEngine.cameraX,
        originalPhotoPaths: [sourceA.path],
        temporaryCaptureIds: const ['old-retained'],
        capturedAt: DateTime(2026, 6, 1),
      ),
    );
    final oldB = await staging.stage(
      ReceiptNativeCaptureResult(
        engine: ReceiptNativeCameraEngine.avFoundation,
        originalPhotoPaths: [sourceB.path],
        temporaryCaptureIds: const ['old-abandoned'],
        capturedAt: DateTime(2026, 6, 1),
      ),
    );
    final retainedPath = oldA.photoPaths.single;
    final abandonedPath = oldB.photoPaths.single;
    final retainedManifestPath = oldA.recoveryManifestPath;
    final abandonedManifestPath = oldB.recoveryManifestPath;
    final oldModified = DateTime(2026, 6, 10);
    File(retainedPath).setLastModifiedSync(oldModified);
    File(abandonedPath).setLastModifiedSync(oldModified);
    File(retainedManifestPath).setLastModifiedSync(oldModified);
    File(abandonedManifestPath).setLastModifiedSync(oldModified);

    await staging.cleanOldAbandonedNativeStaging(
      retainedPaths: [retainedPath],
      olderThan: const Duration(days: 7),
      now: DateTime(2026, 6, 28),
    );

    expect(await File(retainedPath).exists(), isTrue);
    expect(await File(abandonedPath).exists(), isFalse);
    expect(await File(retainedManifestPath).exists(), isTrue);
    expect(await File(abandonedManifestPath).exists(), isFalse);
    final recoveryIndex = await ReceiptNativeCaptureRecoveryStore.create();
    expect(
      recoveryIndex.entries.map((entry) => entry.manifestPath),
      contains(retainedManifestPath),
    );
    expect(
      recoveryIndex.entries.map((entry) => entry.manifestPath),
      isNot(contains(abandonedManifestPath)),
    );
  });

  test(
    'old Hive-only recovery entry is removed when staged photo is gone',
    () async {
      final staging = const ReceiptNativeCaptureStaging();
      final source = File('${Directory.systemTemp.path}/native-hive-old.jpg');
      await source.writeAsBytes(List<int>.filled(64, 9), flush: true);
      addTearDown(() {
        if (source.existsSync()) source.deleteSync();
      });

      final staged = await staging.stage(
        ReceiptNativeCaptureResult(
          engine: ReceiptNativeCameraEngine.cameraX,
          originalPhotoPaths: [source.path],
          temporaryCaptureIds: const ['hive-old-cleanup'],
          capturedAt: DateTime(2026, 6, 1),
        ),
      );
      final stagedPath = staged.photoPaths.single;
      final manifestPath = staged.recoveryManifestPath;
      await File(manifestPath).delete();
      final oldModified = DateTime(2026, 6, 10);
      File(stagedPath).setLastModifiedSync(oldModified);

      var recoveryIndex = await ReceiptNativeCaptureRecoveryStore.create();
      expect(recoveryIndex.entries.single.manifestPath, manifestPath);

      await staging.cleanOldAbandonedNativeStaging(
        olderThan: const Duration(days: 7),
        now: DateTime(2026, 6, 28),
      );

      expect(await File(stagedPath).exists(), isFalse);
      recoveryIndex = await ReceiptNativeCaptureRecoveryStore.create();
      expect(recoveryIndex.entries, isEmpty);
      expect(await staging.recoverableNativeCaptures(), isEmpty);
    },
  );

  test(
    'old Hive-only recovery entry is kept when staged photo is retained',
    () async {
      final staging = const ReceiptNativeCaptureStaging();
      final source = File(
        '${Directory.systemTemp.path}/native-hive-retained.jpg',
      );
      await source.writeAsBytes(List<int>.filled(64, 12), flush: true);
      addTearDown(() {
        if (source.existsSync()) source.deleteSync();
      });

      final staged = await staging.stage(
        ReceiptNativeCaptureResult(
          engine: ReceiptNativeCameraEngine.cameraX,
          originalPhotoPaths: [source.path],
          temporaryCaptureIds: const ['hive-retained-cleanup'],
          capturedAt: DateTime(2026, 6, 1),
        ),
      );
      final stagedPath = staged.photoPaths.single;
      final manifestPath = staged.recoveryManifestPath;
      await File(manifestPath).delete();
      final oldModified = DateTime(2026, 6, 10);
      File(stagedPath).setLastModifiedSync(oldModified);

      await staging.cleanOldAbandonedNativeStaging(
        retainedPaths: [stagedPath],
        olderThan: const Duration(days: 7),
        now: DateTime(2026, 6, 28),
      );

      expect(await File(stagedPath).exists(), isTrue);
      final recoveryIndex = await ReceiptNativeCaptureRecoveryStore.create();
      expect(recoveryIndex.entries.single.manifestPath, manifestPath);
      final recoverable = await staging.recoverableNativeCaptures();
      expect(recoverable.single.recoverablePhotoPaths, [stagedPath]);
    },
  );
}
