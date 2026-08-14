import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_native_camera_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_native_capture_recovery_store.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_native_capture_staging.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

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

  test('discard fails closed when a recovery manifest still exists', () async {
    final undeletableManifest = Directory(
      '${documentsDirectory.path}/manifest-is-a-directory',
    );
    await undeletableManifest.create();
    final staged = ReceiptNativeCaptureStagingResult(
      photoPaths: const [],
      originalToStagedPath: const {},
      captureDiagnosticsByPhotoPath: const {},
      stagedAttachments: const [],
      recoveryManifestPath: undeletableManifest.path,
    );

    await expectLater(staged.discardStagedPhotos(), throwsA(isA<StateError>()));
    expect(await undeletableManifest.exists(), isTrue);
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

  test(
    'finalizing accepted capture deletes staged copy after durable save',
    () async {
      final source = File(
        '${Directory.systemTemp.path}/native-finalize-accepted.jpg',
      );
      await source.writeAsBytes(List<int>.filled(128, 45), flush: true);
      addTearDown(() {
        if (source.existsSync()) source.deleteSync();
      });

      final staging = const ReceiptNativeCaptureStaging();
      final staged = await staging.stage(
        ReceiptNativeCaptureResult(
          engine: ReceiptNativeCameraEngine.cameraX,
          originalPhotoPaths: [source.path],
          temporaryCaptureIds: const ['accepted-finalize'],
          capturedAt: DateTime(2026, 6, 29, 10, 20),
        ),
      );
      final stagedPath = staged.photoPaths.single;
      final manifestPath = staged.recoveryManifestPath;

      final finalized = await staging.finalizeAcceptedCapture(manifestPath);

      expect(finalized, isTrue);
      expect(await File(stagedPath).exists(), isFalse);
      expect(await File(manifestPath).exists(), isFalse);
      expect(await source.exists(), isTrue);
      final recoveryIndex = await ReceiptNativeCaptureRecoveryStore.create();
      expect(recoveryIndex.entries, isEmpty);
    },
  );

  test(
    'finalizing malformed recovery preserves it for explicit recovery',
    () async {
      final malformed = File(
        '${documentsDirectory.path}/malformed-native-recovery.json',
      );
      await malformed.writeAsString('{not-json', flush: true);

      final finalized = await const ReceiptNativeCaptureStaging()
          .finalizeAcceptedCapture(malformed.path);

      expect(finalized, isFalse);
      expect(await malformed.exists(), isTrue);
    },
  );

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

  test(
    'recovery resumes the reviewed order without reintroducing a removed photo',
    () async {
      final sourceFiles = <File>[];
      for (var index = 0; index < 3; index++) {
        final source = File(
          '${Directory.systemTemp.path}/review-checkpoint-$index.jpg',
        );
        await source.writeAsBytes(
          List<int>.filled(128, 70 + index),
          flush: true,
        );
        sourceFiles.add(source);
      }
      addTearDown(() {
        for (final source in sourceFiles) {
          if (source.existsSync()) source.deleteSync();
        }
      });

      const staging = ReceiptNativeCaptureStaging();
      final staged = await staging.stage(
        ReceiptNativeCaptureResult(
          engine: ReceiptNativeCameraEngine.cameraX,
          originalPhotoPaths: [for (final source in sourceFiles) source.path],
          temporaryCaptureIds: const ['top', 'middle', 'bottom'],
          capturedAt: DateTime(2026, 8, 14, 9),
        ),
      );
      final reviewedOrder = [staged.photoPaths[2], staged.photoPaths[0]];
      final review = ReceiptPhotoReviewResult(
        photoPaths: reviewedOrder,
        ocrSourcePhotoPaths: reviewedOrder,
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
        stitchResult: ReceiptStitchResult.notNeeded(reviewedOrder),
      );

      await staging.checkpointReviewedCapture(staged, review);

      final recovered = (await staging.recoverableNativeCaptures()).single;
      expect(recovered.recoverablePhotoPaths, reviewedOrder);
      expect(
        recovered.recoverablePhotoPaths,
        isNot(contains(staged.photoPaths[1])),
      );
      // All three app-owned sources remain cleanup-owned even though only the
      // reviewed two are visible when this session resumes.
      expect(recovered.attachments, hasLength(3));

      expect(
        await staging.finalizeAcceptedCapture(staged.recoveryManifestPath),
        isTrue,
      );
      for (final stagedPath in staged.photoPaths) {
        expect(await File(stagedPath).exists(), isFalse);
      }
      for (final source in sourceFiles) {
        expect(await source.exists(), isTrue);
      }
    },
  );

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
