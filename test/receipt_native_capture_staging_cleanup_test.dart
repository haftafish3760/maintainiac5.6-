import 'dart:convert';
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

  test('discard removes only app-owned staged native photos', () async {
    final source = File('${Directory.systemTemp.path}/native-discard.jpg');
    await source.writeAsBytes(List<int>.filled(128, 4), flush: true);
    addTearDown(() {
      if (source.existsSync()) source.deleteSync();
    });

    final staging = const ReceiptNativeCaptureStaging();
    final staged = await staging.stage(
      ReceiptNativeCaptureResult(
        engine: ReceiptNativeCameraEngine.cameraX,
        originalPhotoPaths: [source.path],
        temporaryCaptureIds: const ['discard-me'],
        capturedAt: DateTime(2026, 6, 28),
      ),
    );
    final stagedPath = staged.photoPaths.single;
    final manifestPath = staged.recoveryManifestPath;

    await staged.discardStagedPhotos(staging: staging);

    expect(await File(stagedPath).exists(), isFalse);
    expect(await File(manifestPath).exists(), isFalse);
    expect(await source.exists(), isTrue);
    final recoveryIndex = await ReceiptNativeCaptureRecoveryStore.create();
    expect(recoveryIndex.entries, isEmpty);
  });

  test('clearing accepted recovery leaves attached staged photos', () async {
    final source = File(
      '${Directory.systemTemp.path}/native-clear-accepted.jpg',
    );
    await source.writeAsBytes(List<int>.filled(128, 44), flush: true);
    addTearDown(() {
      if (source.existsSync()) source.deleteSync();
    });

    final staging = const ReceiptNativeCaptureStaging();
    final staged = await staging.stage(
      ReceiptNativeCaptureResult(
        engine: ReceiptNativeCameraEngine.cameraX,
        originalPhotoPaths: [source.path],
        temporaryCaptureIds: const ['accepted-clear'],
        capturedAt: DateTime(2026, 6, 29, 10, 15),
      ),
    );
    final stagedPath = staged.photoPaths.single;
    final manifestPath = staged.recoveryManifestPath;
    expect(await File(stagedPath).exists(), isTrue);
    expect(await File(manifestPath).exists(), isTrue);

    await staging.clearRecoveryManifestPath(manifestPath);

    expect(await File(stagedPath).exists(), isTrue);
    expect(await File(manifestPath).exists(), isFalse);
    expect(await source.exists(), isTrue);
    final recoveryIndex = await ReceiptNativeCaptureRecoveryStore.create();
    expect(recoveryIndex.entries, isEmpty);
  });

  test('recovery stage updates manifest and Hive index safely', () async {
    final source = File('${Directory.systemTemp.path}/native-stage-update.jpg');
    await source.writeAsBytes(List<int>.filled(128, 61), flush: true);
    addTearDown(() {
      if (source.existsSync()) source.deleteSync();
    });

    final staging = const ReceiptNativeCaptureStaging();
    final staged = await staging.stage(
      ReceiptNativeCaptureResult(
        engine: ReceiptNativeCameraEngine.cameraX,
        originalPhotoPaths: [source.path],
        temporaryCaptureIds: const ['stage-update'],
        capturedAt: DateTime(2026, 6, 29, 10, 45),
        captureDiagnostics: const {
          'engine': 'cameraX',
          'deviceTier': 'heavyweight',
        },
      ),
    );
    final manifestFile = File(staged.recoveryManifestPath);
    final poisonedManifest =
        jsonDecode(await manifestFile.readAsString()) as Map;
    await manifestFile.writeAsString(
      jsonEncode({
        ...poisonedManifest,
        'captureDiagnostics': {
          ...(poisonedManifest['captureDiagnostics'] as Map),
          'receiptText': 'LOWE PRIVATE RECEIPT',
          'customerName': 'Private Customer',
          'latestFrameBrightness': 118,
        },
      }),
      flush: true,
    );

    await staging.markRecoveryStage(
      staged.recoveryManifestPath,
      stage: 'review_accepted',
      reason: 'receipt_photos_accepted_for_receipt_details',
      action: 'open_receipt_details_or_save_proof',
      extraMetadata: const {
        'nativeRecoveryReviewAccepted': true,
        'nativeRecoveryOcrPending': true,
        'nativeRecoveryReviewedPhotoCount': 1,
        'nativeRecoveryOcrSourcePhotoCount': 1,
        'unsafePrivateReceiptText': 'LOWE PRIVATE RECEIPT',
      },
    );

    final manifest =
        jsonDecode(await File(staged.recoveryManifestPath).readAsString())
            as Map;
    final diagnostics = manifest['captureDiagnostics'] as Map;
    final stage = manifest['recoveryStage'] as Map;

    expect(diagnostics['nativeRecoveryLastStage'], 'review_accepted');
    expect(
      diagnostics['nativeRecoveryLastReason'],
      'receipt_photos_accepted_for_receipt_details',
    );
    expect(
      diagnostics['nativeRecoveryNextAction'],
      'open_receipt_details_or_save_proof',
    );
    expect(diagnostics['nativeRecoveryReviewAccepted'], isTrue);
    expect(diagnostics['nativeRecoveryOcrPending'], isTrue);
    expect(diagnostics['nativeRecoveryReviewedPhotoCount'], 1);
    expect(diagnostics['nativeRecoveryOcrSourcePhotoCount'], 1);
    expect(diagnostics['latestFrameBrightness'], 118);
    expect(diagnostics, isNot(contains('receiptText')));
    expect(diagnostics, isNot(contains('customerName')));
    expect(stage['schema'], 'native_capture_recovery_stage_v1');
    expect(stage['stage'], 'review_accepted');
    expect(stage['privacyScope'], 'summary_only_no_receipt_content');
    expect(manifest.toString(), isNot(contains('LOWE PRIVATE RECEIPT')));
    expect(manifest.toString(), isNot(contains('unsafePrivateReceiptText')));

    final recoveryIndex = await ReceiptNativeCaptureRecoveryStore.create();
    final indexEntry = recoveryIndex.entries.single;
    expect(
      indexEntry.captureDiagnostics['nativeRecoveryLastStage'],
      'review_accepted',
    );
    expect(
      indexEntry.captureDiagnostics['nativeRecoveryReviewAccepted'],
      isTrue,
    );
    expect(indexEntry.captureDiagnostics.toString(), isNot(contains('LOWE')));
    expect(
      indexEntry.captureDiagnostics.toString(),
      isNot(contains('Private Customer')),
    );
  });

  test('discarding recovery record removes staged photos and index', () async {
    final source = File('${Directory.systemTemp.path}/native-record-drop.jpg');
    await source.writeAsBytes(List<int>.filled(128, 5), flush: true);
    addTearDown(() {
      if (source.existsSync()) source.deleteSync();
    });

    final staging = const ReceiptNativeCaptureStaging();
    final staged = await staging.stage(
      ReceiptNativeCaptureResult(
        engine: ReceiptNativeCameraEngine.cameraX,
        originalPhotoPaths: [source.path],
        temporaryCaptureIds: const ['drop-record'],
        capturedAt: DateTime(2026, 6, 28, 23, 20),
      ),
    );
    final stagedPath = staged.photoPaths.single;
    final manifestPath = staged.recoveryManifestPath;
    final record = (await staging.recoverableNativeCaptures()).single;

    await staging.discardRecoveryRecord(record);

    expect(await File(stagedPath).exists(), isFalse);
    expect(await File(manifestPath).exists(), isFalse);
    expect(await source.exists(), isTrue);
    final recoveryIndex = await ReceiptNativeCaptureRecoveryStore.create();
    expect(recoveryIndex.entries, isEmpty);
    expect(await staging.recoverableNativeCaptures(), isEmpty);
  });

  test('discarding Hive-only recovery record removes staged photos', () async {
    final source = File('${Directory.systemTemp.path}/native-hive-drop.jpg');
    await source.writeAsBytes(List<int>.filled(128, 6), flush: true);
    addTearDown(() {
      if (source.existsSync()) source.deleteSync();
    });

    final staging = const ReceiptNativeCaptureStaging();
    final staged = await staging.stage(
      ReceiptNativeCaptureResult(
        engine: ReceiptNativeCameraEngine.avFoundation,
        originalPhotoPaths: [source.path],
        temporaryCaptureIds: const ['hive-drop'],
        capturedAt: DateTime(2026, 6, 28, 23, 30),
      ),
    );
    final stagedPath = staged.photoPaths.single;
    await File(staged.recoveryManifestPath).delete();
    final record = (await staging.recoverableNativeCaptures()).single;
    expect(record.manifestPath, staged.recoveryManifestPath);
    expect(record.attachments.single.path, stagedPath);

    await staging.discardRecoveryRecord(record);

    expect(await File(stagedPath).exists(), isFalse);
    expect(await source.exists(), isTrue);
    final recoveryIndex = await ReceiptNativeCaptureRecoveryStore.create();
    expect(recoveryIndex.entries, isEmpty);
    expect(await staging.recoverableNativeCaptures(), isEmpty);
  });
}
