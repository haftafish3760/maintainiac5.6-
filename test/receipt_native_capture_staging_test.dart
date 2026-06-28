import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_native_camera_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_native_capture_recovery_store.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_native_capture_staging.dart';

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
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => switch (call.method) {
            'getApplicationDocumentsDirectory' => documentsDirectory.path,
            _ => null,
          },
        );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    await Hive.close();
    if (await documentsDirectory.exists()) {
      await documentsDirectory.delete(recursive: true);
    }
    if (await hiveDirectory.exists()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  test('accepted native capture is copied into receipt staging', () async {
    final sourceDir = await Directory.systemTemp.createTemp(
      'native_camera_cache_',
    );
    addTearDown(() async {
      if (await sourceDir.exists()) await sourceDir.delete(recursive: true);
    });
    final source = File('${sourceDir.path}/native-temp-receipt.jpg');
    await source.writeAsBytes(List<int>.generate(256, (index) => index % 255));

    final capturedAt = DateTime(2026, 6, 28, 14, 35, 12);
    final staged = await const ReceiptNativeCaptureStaging().stage(
      ReceiptNativeCaptureResult(
        engine: ReceiptNativeCameraEngine.cameraX,
        originalPhotoPaths: [source.path],
        temporaryCaptureIds: const ['camera-cache-id'],
        capturedAt: capturedAt,
        captureDiagnostics: const {
          'engine': 'cameraX',
          'photoByteSize': 256,
          'photoByteSizeBucket': 'tiny_under_350kb',
          'latestCapturedPhotoWidth': 3024,
          'latestCapturedPhotoHeight': 4032,
          'latestCapturedMegapixelBucket': 'high_9mp_to_18mp',
          'latestCapturedByteBucket': 'normal_1mb_to_3mb',
          'latestCapturedBrightnessBucket': 'captured_dim',
          'latestCapturedSharpnessBucket': 'captured_sharp',
          'latestCapturedQualitySignal': 'review_before_saving',
          'latestCapturedExposureMismatch': 'live_ok_capture_dim',
          'torchOn': false,
          'captureQualityMode': 'maximizeQuality',
          'latestBrightnessBucket': 'dark_assisted',
          'latestShadowScore': 164.0,
          'latestReadabilitySignal': 'shadow_risk',
          'exposureAssistStatus': 'auto_adjusted',
          'lastAutoExposureDecision': 'waiting_for_receipt_target',
          'lastAutoExposureBrightnessBucket': 'dark_assisted',
          'lastAutoExposureCandidate': 'brighten',
          'autoExposureCandidateFrameCount': 2,
          'latestFramingConfidence': 'usable_edges',
          'latestEdgeCoverage': 0.64,
          'latestPerspectiveReadiness': 'perspective_ready_safe_bounds',
          'edgeDetectionEnabled': true,
          'edgeOverlayEnabled': true,
          'shadowWarningEnabled': true,
          'textTooSmallWarningEnabled': true,
          'autoCropSuggestionEnabled': true,
          'grayscalePreviewEnabled': true,
          'contrastBoostEnabled': true,
          'shadowReductionEnabled': true,
          'orientationCorrectionEnabled': true,
          'tapFocusCount': 2,
          'tapFocusSuppressedAfterZoomCount': 1,
          'zoomChangeCount': 3,
          'manualExposureChangeCount': 1,
          'lastFocusStatus': 'requested',
          'autoCaptureTriggerCount': 1,
          'latestAutoCaptureStatus': 'capturing',
          'closeAction': 'done_returned_captured_sections',
          'closeRetryCount': 1,
          'pendingCloseAfterCapture': true,
          'closeResultDelivered': true,
          'autoCaptureAllowed': true,
          'autoCaptureCurrentlyAllowed': true,
          'closingCamera': false,
          'storageSafetyLevel': 'maximum',
          'storageConstrained': true,
          'storageSafetyReason': 'tight_storage_tiny_proofs',
          'receiptText': 'LOWE PRIVATE TEXT',
        },
      ),
      dataSaverLevel: ReceiptDataSaverLevel.strong,
    );

    expect(staged.hasPhotos, isTrue);
    expect(staged.photoPaths, hasLength(1));
    expect(staged.photoPaths.single, isNot(source.path));
    expect(staged.photoPaths.single, contains('receipt_proofs_staging'));
    expect(await File(staged.photoPaths.single).exists(), isTrue);
    expect(staged.recoveryManifestPath, contains('native_capture_recovery'));
    expect(await File(staged.recoveryManifestPath).exists(), isTrue);
    expect(await source.exists(), isTrue);
    expect(staged.originalToStagedPath[source.path], staged.photoPaths.single);
    expect(
      staged.captureDiagnosticsByPhotoPath[staged
          .photoPaths
          .single]?['latestCapturedPhotoWidth'],
      3024,
    );
    expect(
      staged.captureDiagnosticsByPhotoPath[staged
          .photoPaths
          .single]?['latestCapturedPhotoHeight'],
      4032,
    );
    expect(
      staged.captureDiagnosticsByPhotoPath[staged
          .photoPaths
          .single]?['latestCapturedMegapixelBucket'],
      'high_9mp_to_18mp',
    );
    expect(
      staged.captureDiagnosticsByPhotoPath[staged
          .photoPaths
          .single]?['latestCapturedByteBucket'],
      'normal_1mb_to_3mb',
    );
    expect(
      staged.captureDiagnosticsByPhotoPath[staged
          .photoPaths
          .single]?['latestCapturedBrightnessBucket'],
      'captured_dim',
    );
    expect(
      staged.captureDiagnosticsByPhotoPath[staged
          .photoPaths
          .single]?['latestCapturedSharpnessBucket'],
      'captured_sharp',
    );
    expect(
      staged.captureDiagnosticsByPhotoPath[staged
          .photoPaths
          .single]?['latestCapturedQualitySignal'],
      'review_before_saving',
    );
    expect(
      staged.captureDiagnosticsByPhotoPath[staged
          .photoPaths
          .single]?['latestCapturedExposureMismatch'],
      'live_ok_capture_dim',
    );
    expect(
      staged.captureDiagnosticsByPhotoPath[staged
          .photoPaths
          .single]?['latestBrightnessBucket'],
      'dark_assisted',
    );
    expect(
      staged.captureDiagnosticsByPhotoPath[staged
          .photoPaths
          .single]?['latestShadowScore'],
      164.0,
    );
    expect(
      staged.captureDiagnosticsByPhotoPath[staged
          .photoPaths
          .single]?['latestReadabilitySignal'],
      'shadow_risk',
    );
    expect(
      staged.captureDiagnosticsByPhotoPath[staged
          .photoPaths
          .single]?['exposureAssistStatus'],
      'auto_adjusted',
    );
    expect(
      staged.captureDiagnosticsByPhotoPath[staged
          .photoPaths
          .single]?['lastAutoExposureDecision'],
      'waiting_for_receipt_target',
    );
    expect(
      staged.captureDiagnosticsByPhotoPath[staged
          .photoPaths
          .single]?['lastAutoExposureBrightnessBucket'],
      'dark_assisted',
    );
    expect(
      staged.captureDiagnosticsByPhotoPath[staged
          .photoPaths
          .single]?['lastAutoExposureCandidate'],
      'brighten',
    );
    expect(
      staged.captureDiagnosticsByPhotoPath[staged
          .photoPaths
          .single]?['autoExposureCandidateFrameCount'],
      2,
    );
    expect(
      staged.captureDiagnosticsByPhotoPath[staged
          .photoPaths
          .single]?['latestFramingConfidence'],
      'usable_edges',
    );
    expect(
      staged.captureDiagnosticsByPhotoPath[staged
          .photoPaths
          .single]?['latestEdgeCoverage'],
      0.64,
    );
    expect(
      staged.captureDiagnosticsByPhotoPath[staged
          .photoPaths
          .single]?['latestPerspectiveReadiness'],
      'perspective_ready_safe_bounds',
    );
    expect(
      staged.captureDiagnosticsByPhotoPath[staged
          .photoPaths
          .single]?['tapFocusCount'],
      2,
    );
    expect(
      staged.captureDiagnosticsByPhotoPath[staged
          .photoPaths
          .single]?['tapFocusSuppressedAfterZoomCount'],
      1,
    );
    expect(
      staged.captureDiagnosticsByPhotoPath[staged
          .photoPaths
          .single]?['zoomChangeCount'],
      3,
    );
    expect(
      staged.captureDiagnosticsByPhotoPath[staged
          .photoPaths
          .single]?['manualExposureChangeCount'],
      1,
    );
    expect(
      staged.captureDiagnosticsByPhotoPath[staged
          .photoPaths
          .single]?['lastFocusStatus'],
      'requested',
    );
    expect(
      staged.captureDiagnosticsByPhotoPath[staged
          .photoPaths
          .single]?['autoCaptureTriggerCount'],
      1,
    );
    expect(
      staged.captureDiagnosticsByPhotoPath[staged
          .photoPaths
          .single]?['latestAutoCaptureStatus'],
      'capturing',
    );
    expect(
      staged.captureDiagnosticsByPhotoPath[staged
          .photoPaths
          .single]?['pendingCloseAfterCapture'],
      isTrue,
    );
    expect(
      staged.captureDiagnosticsByPhotoPath[staged
          .photoPaths
          .single]?['closeAction'],
      'done_returned_captured_sections',
    );
    expect(
      staged.captureDiagnosticsByPhotoPath[staged
          .photoPaths
          .single]?['closeResultDelivered'],
      isTrue,
    );
    expect(
      staged.captureDiagnosticsByPhotoPath[staged
          .photoPaths
          .single]?['autoCaptureAllowed'],
      isTrue,
    );
    expect(
      staged.captureDiagnosticsByPhotoPath[staged
          .photoPaths
          .single]?['autoCaptureCurrentlyAllowed'],
      isTrue,
    );
    expect(
      staged.captureDiagnosticsByPhotoPath[staged
          .photoPaths
          .single]?['closingCamera'],
      isFalse,
    );
    expect(
      staged.captureDiagnosticsByPhotoPath[staged
          .photoPaths
          .single]?['storageSafetyLevel'],
      'maximum',
    );
    expect(
      staged.captureDiagnosticsByPhotoPath[staged
          .photoPaths
          .single]?['storageConstrained'],
      isTrue,
    );
    expect(
      staged.captureDiagnosticsByPhotoPath[staged
          .photoPaths
          .single]?['storageSafetyReason'],
      'tight_storage_tiny_proofs',
    );
    expect(
      staged.captureDiagnosticsByPhotoPath[staged
          .photoPaths
          .single]?['edgeDetectionEnabled'],
      isTrue,
    );
    expect(
      staged.captureDiagnosticsByPhotoPath[staged
          .photoPaths
          .single]?['edgeOverlayEnabled'],
      isTrue,
    );
    expect(
      staged.captureDiagnosticsByPhotoPath[staged
          .photoPaths
          .single]?['shadowWarningEnabled'],
      isTrue,
    );
    expect(
      staged.captureDiagnosticsByPhotoPath[staged
          .photoPaths
          .single]?['textTooSmallWarningEnabled'],
      isTrue,
    );
    expect(
      staged.captureDiagnosticsByPhotoPath[staged
          .photoPaths
          .single]?['autoCropSuggestionEnabled'],
      isTrue,
    );
    expect(
      staged.captureDiagnosticsByPhotoPath[staged
          .photoPaths
          .single]?['orientationCorrectionEnabled'],
      isTrue,
    );
    expect(
      staged.captureDiagnosticsByPhotoPath[staged.photoPaths.single]
          ?.containsKey('receiptText'),
      isFalse,
    );

    final attachment = staged.stagedAttachments.single;
    expect(attachment.kind, ReceiptAttachmentKind.photo);
    expect(attachment.storageState, ReceiptAttachmentStorageState.staged);
    expect(attachment.dataSaverLevel, ReceiptDataSaverLevel.strong);
    expect(attachment.sourceLabel, contains('CameraX'));
    expect(attachment.createdAt, capturedAt);
    expect(attachment.byteSize, await source.length());
    expect(attachment.fileHash, isNotEmpty);
    expect(attachment.isOriginalImmutable, isTrue);

    final manifest =
        jsonDecode(await File(staged.recoveryManifestPath).readAsString())
            as Map;
    expect(
      manifest['schema'],
      'maintainiac_native_receipt_capture_recovery_v1',
    );
    expect(manifest['engine'], 'cameraX');
    expect(manifest['dataSaverLevel'], ReceiptDataSaverLevel.strong.name);
    expect(manifest['photoCount'], 1);
    expect(manifest['stagedPhotoPaths'], contains(staged.photoPaths.single));
    expect(
      (manifest['captureDiagnostics'] as Map)['captureQualityMode'],
      'maximizeQuality',
    );
    expect(
      (manifest['captureDiagnostics'] as Map)['latestCapturedPhotoWidth'],
      3024,
    );
    expect(
      (manifest['captureDiagnostics'] as Map)['latestCapturedMegapixelBucket'],
      'high_9mp_to_18mp',
    );
    expect(
      (manifest['captureDiagnostics'] as Map)['latestBrightnessBucket'],
      'dark_assisted',
    );
    expect((manifest['captureDiagnostics'] as Map)['latestShadowScore'], 164.0);
    expect(
      (manifest['captureDiagnostics'] as Map)['latestReadabilitySignal'],
      'shadow_risk',
    );
    expect(
      (manifest['captureDiagnostics'] as Map)['exposureAssistStatus'],
      'auto_adjusted',
    );
    expect(
      (manifest['captureDiagnostics'] as Map)['lastAutoExposureDecision'],
      'waiting_for_receipt_target',
    );
    expect(
      (manifest['captureDiagnostics']
          as Map)['lastAutoExposureBrightnessBucket'],
      'dark_assisted',
    );
    expect(
      (manifest['captureDiagnostics'] as Map)['lastAutoExposureCandidate'],
      'brighten',
    );
    expect(
      (manifest['captureDiagnostics']
          as Map)['autoExposureCandidateFrameCount'],
      2,
    );
    expect(
      (manifest['captureDiagnostics'] as Map)['latestFramingConfidence'],
      'usable_edges',
    );
    expect((manifest['captureDiagnostics'] as Map)['latestEdgeCoverage'], 0.64);
    expect(
      (manifest['captureDiagnostics'] as Map)['latestPerspectiveReadiness'],
      'perspective_ready_safe_bounds',
    );
    expect(
      (manifest['captureDiagnostics'] as Map)['edgeDetectionEnabled'],
      isTrue,
    );
    expect(
      (manifest['captureDiagnostics'] as Map)['edgeOverlayEnabled'],
      isTrue,
    );
    expect(
      (manifest['captureDiagnostics'] as Map)['shadowWarningEnabled'],
      isTrue,
    );
    expect(
      (manifest['captureDiagnostics'] as Map)['textTooSmallWarningEnabled'],
      isTrue,
    );
    expect(
      (manifest['captureDiagnostics'] as Map)['autoCropSuggestionEnabled'],
      isTrue,
    );
    expect(
      (manifest['captureDiagnostics'] as Map)['orientationCorrectionEnabled'],
      isTrue,
    );
    expect((manifest['captureDiagnostics'] as Map)['tapFocusCount'], 2);
    expect((manifest['captureDiagnostics'] as Map)['zoomChangeCount'], 3);
    expect(
      (manifest['captureDiagnostics'] as Map)['manualExposureChangeCount'],
      1,
    );
    expect(
      (manifest['captureDiagnostics'] as Map)['lastFocusStatus'],
      'requested',
    );
    expect(
      (manifest['captureDiagnostics'] as Map)['autoCaptureTriggerCount'],
      1,
    );
    expect(
      (manifest['captureDiagnostics'] as Map)['latestAutoCaptureStatus'],
      'capturing',
    );
    expect(
      (manifest['captureDiagnostics'] as Map)['closeAction'],
      'done_returned_captured_sections',
    );
    expect((manifest['captureDiagnostics'] as Map)['closeRetryCount'], 1);
    expect(
      (manifest['captureDiagnostics'] as Map)['pendingCloseAfterCapture'],
      isTrue,
    );
    expect(
      (manifest['captureDiagnostics'] as Map)['closeResultDelivered'],
      isTrue,
    );
    expect(
      (manifest['captureDiagnostics'] as Map)['autoCaptureAllowed'],
      isTrue,
    );
    expect(
      (manifest['captureDiagnostics'] as Map)['autoCaptureCurrentlyAllowed'],
      isTrue,
    );
    expect((manifest['captureDiagnostics'] as Map)['closingCamera'], isFalse);
    expect(
      (manifest['captureDiagnostics'] as Map)['storageSafetyLevel'],
      'maximum',
    );
    expect(
      (manifest['captureDiagnostics'] as Map)['storageConstrained'],
      isTrue,
    );
    expect(
      (manifest['captureDiagnostics'] as Map)['storageSafetyReason'],
      'tight_storage_tiny_proofs',
    );
    expect(
      (manifest['captureDiagnostics'] as Map).containsKey('receiptText'),
      isFalse,
    );
    expect((manifest['privacy'] as Map)['storesReceiptText'], isFalse);
    expect((manifest['privacy'] as Map)['storesReceiptImageContent'], isFalse);
    expect((manifest['privacy'] as Map)['storesCustomerContent'], isFalse);
    expect(manifest.toString(), isNot(contains('LOWE')));
    expect(manifest.toString(), isNot(contains('receiptText')));

    final recoveryIndex = await ReceiptNativeCaptureRecoveryStore.create();
    expect(recoveryIndex.entries, hasLength(1));
    final indexEntry = recoveryIndex.entries.single;
    expect(indexEntry.sessionId, manifest['sessionId']);
    expect(indexEntry.manifestPath, staged.recoveryManifestPath);
    expect(indexEntry.engineName, 'cameraX');
    expect(indexEntry.dataSaverLevelName, ReceiptDataSaverLevel.strong.name);
    expect(indexEntry.photoCount, 1);
    expect(indexEntry.stagedPhotoPaths, staged.photoPaths);
    expect(indexEntry.attachments.single.path, staged.photoPaths.single);
    expect(
      indexEntry.captureDiagnostics['captureQualityMode'],
      'maximizeQuality',
    );
    expect(indexEntry.captureDiagnostics['latestCapturedPhotoHeight'], 4032);
    expect(
      indexEntry.captureDiagnostics['latestCapturedByteBucket'],
      'normal_1mb_to_3mb',
    );
    expect(
      indexEntry.captureDiagnostics['latestCapturedQualitySignal'],
      'review_before_saving',
    );
    expect(
      indexEntry.captureDiagnostics['latestCapturedExposureMismatch'],
      'live_ok_capture_dim',
    );
    expect(
      indexEntry.captureDiagnostics['latestBrightnessBucket'],
      'dark_assisted',
    );
    expect(indexEntry.captureDiagnostics['latestShadowScore'], 164.0);
    expect(
      indexEntry.captureDiagnostics['latestReadabilitySignal'],
      'shadow_risk',
    );
    expect(
      indexEntry.captureDiagnostics['exposureAssistStatus'],
      'auto_adjusted',
    );
    expect(
      indexEntry.captureDiagnostics['lastAutoExposureDecision'],
      'waiting_for_receipt_target',
    );
    expect(
      indexEntry.captureDiagnostics['lastAutoExposureBrightnessBucket'],
      'dark_assisted',
    );
    expect(
      indexEntry.captureDiagnostics['lastAutoExposureCandidate'],
      'brighten',
    );
    expect(indexEntry.captureDiagnostics['autoExposureCandidateFrameCount'], 2);
    expect(
      indexEntry.captureDiagnostics['latestFramingConfidence'],
      'usable_edges',
    );
    expect(indexEntry.captureDiagnostics['latestEdgeCoverage'], 0.64);
    expect(
      indexEntry.captureDiagnostics['latestPerspectiveReadiness'],
      'perspective_ready_safe_bounds',
    );
    expect(indexEntry.captureDiagnostics['edgeDetectionEnabled'], isTrue);
    expect(indexEntry.captureDiagnostics['edgeOverlayEnabled'], isTrue);
    expect(indexEntry.captureDiagnostics['shadowWarningEnabled'], isTrue);
    expect(indexEntry.captureDiagnostics['textTooSmallWarningEnabled'], isTrue);
    expect(indexEntry.captureDiagnostics['autoCropSuggestionEnabled'], isTrue);
    expect(
      indexEntry.captureDiagnostics['orientationCorrectionEnabled'],
      isTrue,
    );
    expect(indexEntry.captureDiagnostics['tapFocusCount'], 2);
    expect(
      indexEntry.captureDiagnostics['tapFocusSuppressedAfterZoomCount'],
      1,
    );
    expect(indexEntry.captureDiagnostics['zoomChangeCount'], 3);
    expect(indexEntry.captureDiagnostics['manualExposureChangeCount'], 1);
    expect(indexEntry.captureDiagnostics['lastFocusStatus'], 'requested');
    expect(indexEntry.captureDiagnostics['autoCaptureTriggerCount'], 1);
    expect(
      indexEntry.captureDiagnostics['latestAutoCaptureStatus'],
      'capturing',
    );
    expect(indexEntry.captureDiagnostics['closeRetryCount'], 1);
    expect(
      indexEntry.captureDiagnostics['closeAction'],
      'done_returned_captured_sections',
    );
    expect(indexEntry.captureDiagnostics['pendingCloseAfterCapture'], isTrue);
    expect(indexEntry.captureDiagnostics['closeResultDelivered'], isTrue);
    expect(indexEntry.captureDiagnostics['autoCaptureAllowed'], isTrue);
    expect(
      indexEntry.captureDiagnostics['autoCaptureCurrentlyAllowed'],
      isTrue,
    );
    expect(indexEntry.captureDiagnostics['closingCamera'], isFalse);
    expect(indexEntry.captureDiagnostics['storageSafetyLevel'], 'maximum');
    expect(indexEntry.captureDiagnostics['storageConstrained'], isTrue);
    expect(
      indexEntry.captureDiagnostics['storageSafetyReason'],
      'tight_storage_tiny_proofs',
    );
    expect(indexEntry.captureDiagnostics.containsKey('receiptText'), isFalse);
    expect(indexEntry.toMap().toString(), isNot(contains('LOWE')));
    expect(indexEntry.toMap().toString(), isNot(contains('receiptText')));
  });

  test('recovery record explains resume context without receipt content', () {
    final record = ReceiptNativeCaptureRecoveryRecord(
      manifestPath: '/tmp/recovery.json',
      sessionId: 'native-session',
      engine: ReceiptNativeCameraEngine.cameraX,
      capturedAt: DateTime(2026, 6, 28, 15),
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stagedPhotoPaths: const ['/tmp/section-one.jpg', '/tmp/section-two.jpg'],
      attachments: const [],
      captureDiagnostics: const {
        'closeAction': 'back_returned_captured_sections',
        'receiptText': 'PRIVATE RECEIPT TEXT',
      },
    );

    expect(record.recoveredPhotoCount, 2);
    expect(record.hasMultipleReceiptSections, isTrue);
    expect(record.recoveredCountLabel, '2 ordered receipt sections');
    expect(
      record.recoveryCloseActionLabel,
      'Back was pressed after photos were captured.',
    );
    expect(
      record.recoveryResumeDetail,
      'Back was pressed after photos were captured. Resume keeps the top-to-bottom order for review.',
    );
    expect(record.recoveryResumeDetail, isNot(contains('PRIVATE')));
  });

  test('recovery record falls back to attachment paths for resume', () async {
    final photo = File(
      '${Directory.systemTemp.path}/native-attachment-only.jpg',
    );
    await photo.writeAsBytes(List<int>.filled(64, 12), flush: true);
    addTearDown(() {
      if (photo.existsSync()) photo.deleteSync();
    });
    final record = ReceiptNativeCaptureRecoveryRecord(
      manifestPath: '/tmp/attachment-only-recovery.json',
      sessionId: 'attachment-only',
      engine: ReceiptNativeCameraEngine.cameraX,
      capturedAt: DateTime(2026, 6, 28, 16),
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stagedPhotoPaths: const [],
      attachments: [
        ReceiptAttachmentRecord(
          id: 'attachment-only-photo',
          path: photo.path,
          kind: ReceiptAttachmentKind.photo,
          dataSaverLevel: ReceiptDataSaverLevel.balanced,
          createdAt: DateTime(2026, 6, 28, 16),
        ),
      ],
      captureDiagnostics: const {
        'closeAction': 'done_returned_captured_sections',
      },
    );

    expect(record.recoverablePhotoPaths, [photo.path]);
    expect(record.recoveredPhotoCount, 1);
    expect(record.hasExistingPhotos, isTrue);
    expect(record.recoveredCountLabel, '1 receipt photo');
  });

  test(
    'missing native temp paths are skipped without inventing photos',
    () async {
      final staged = await const ReceiptNativeCaptureStaging().stage(
        ReceiptNativeCaptureResult(
          engine: ReceiptNativeCameraEngine.avFoundation,
          originalPhotoPaths: const ['/tmp/not-a-real-receipt-photo.jpg'],
          temporaryCaptureIds: const ['missing'],
          capturedAt: DateTime(2026, 6, 28),
        ),
      );

      expect(staged.hasPhotos, isFalse);
      expect(staged.photoPaths, isEmpty);
      expect(staged.stagedAttachments, isEmpty);
      expect(staged.recoveryManifestPath, isEmpty);
    },
  );

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

  test('recoverable captures list interrupted native receipt work', () async {
    final staging = const ReceiptNativeCaptureStaging();
    final source = File('${Directory.systemTemp.path}/native-recoverable.jpg');
    await source.writeAsBytes(List<int>.filled(96, 7), flush: true);
    addTearDown(() {
      if (source.existsSync()) source.deleteSync();
    });

    final capturedAt = DateTime(2026, 6, 28, 21, 44);
    final staged = await staging.stage(
      ReceiptNativeCaptureResult(
        engine: ReceiptNativeCameraEngine.cameraX,
        originalPhotoPaths: [source.path],
        temporaryCaptureIds: const ['recoverable-one'],
        capturedAt: capturedAt,
        captureDiagnostics: const {'zoomRatio': 1.4, 'torchOn': true},
      ),
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
    );

    final records = await staging.recoverableNativeCaptures();

    expect(records, hasLength(1));
    final record = records.single;
    expect(record.manifestPath, staged.recoveryManifestPath);
    expect(record.engine, ReceiptNativeCameraEngine.cameraX);
    expect(record.capturedAt, capturedAt);
    expect(record.dataSaverLevel, ReceiptDataSaverLevel.balanced);
    expect(record.stagedPhotoPaths, staged.photoPaths);
    expect(record.attachments.single.path, staged.photoPaths.single);
    expect(record.captureDiagnostics['torchOn'], isTrue);
    expect(record.captureDiagnostics['zoomRatio'], 1.4);
    expect(record.hasExistingPhotos, isTrue);
  });

  test(
    'Hive recovery index can restore capture when manifest is missing',
    () async {
      final staging = const ReceiptNativeCaptureStaging();
      final source = File('${Directory.systemTemp.path}/native-hive-only.jpg');
      await source.writeAsBytes(List<int>.filled(96, 11), flush: true);
      addTearDown(() {
        if (source.existsSync()) source.deleteSync();
      });

      final capturedAt = DateTime(2026, 6, 28, 22, 15);
      final staged = await staging.stage(
        ReceiptNativeCaptureResult(
          engine: ReceiptNativeCameraEngine.cameraX,
          originalPhotoPaths: [source.path],
          temporaryCaptureIds: const ['hive-only'],
          capturedAt: capturedAt,
          captureDiagnostics: const {
            'latestFramingSignal': 'framing_ok',
            'latestMotionSignal': 'steady',
          },
        ),
        dataSaverLevel: ReceiptDataSaverLevel.light,
      );
      await File(staged.recoveryManifestPath).delete();

      final records = await staging.recoverableNativeCaptures();

      expect(records, hasLength(1));
      final record = records.single;
      expect(record.manifestPath, staged.recoveryManifestPath);
      expect(record.engine, ReceiptNativeCameraEngine.cameraX);
      expect(record.capturedAt, capturedAt);
      expect(record.dataSaverLevel, ReceiptDataSaverLevel.light);
      expect(record.stagedPhotoPaths, staged.photoPaths);
      expect(record.recoverablePhotoPaths, staged.photoPaths);
      expect(record.attachments.single.path, staged.photoPaths.single);
      expect(
        record.attachments.single.dataSaverLevel,
        ReceiptDataSaverLevel.light,
      );
      expect(record.captureDiagnostics['latestFramingSignal'], 'framing_ok');
      expect(record.captureDiagnostics['latestMotionSignal'], 'steady');
      expect(record.hasExistingPhotos, isTrue);
    },
  );

  test('recovery diagnostics drop unknown private-looking keys', () async {
    final source = File('${Directory.systemTemp.path}/native-redacted.jpg');
    await source.writeAsBytes(List<int>.filled(96, 17), flush: true);
    addTearDown(() {
      if (source.existsSync()) source.deleteSync();
    });

    final staged = await const ReceiptNativeCaptureStaging().stage(
      ReceiptNativeCaptureResult(
        engine: ReceiptNativeCameraEngine.cameraX,
        originalPhotoPaths: [source.path],
        temporaryCaptureIds: const ['redacted'],
        capturedAt: DateTime(2026, 6, 28, 23),
        captureDiagnostics: const {
          'latestFramingSignal': 'framing_ok',
          'latestMotionScore': 3.2,
          'receiptText': 'LOWE private receipt words',
          'customerName': 'Private Customer',
          'address': '123 Private Street',
        },
      ),
    );

    final manifest =
        jsonDecode(await File(staged.recoveryManifestPath).readAsString())
            as Map;
    final manifestDiagnostics = manifest['captureDiagnostics'] as Map;

    expect(manifestDiagnostics['latestFramingSignal'], 'framing_ok');
    expect(manifestDiagnostics['latestMotionScore'], 3.2);
    expect(manifestDiagnostics.containsKey('receiptText'), isFalse);
    expect(manifestDiagnostics.containsKey('customerName'), isFalse);
    expect(manifestDiagnostics.containsKey('address'), isFalse);
    expect(manifest.toString(), isNot(contains('LOWE private')));
    expect(manifest.toString(), isNot(contains('Private Customer')));

    final recoveryIndex = await ReceiptNativeCaptureRecoveryStore.create();
    final indexMap = recoveryIndex.entries.single.toMap();
    expect(indexMap.toString(), isNot(contains('LOWE private')));
    expect(indexMap.toString(), isNot(contains('Private Customer')));
  });

  test('recoverable captures skip corrupt or missing staged work', () async {
    final staging = const ReceiptNativeCaptureStaging();
    final source = File(
      '${Directory.systemTemp.path}/native-missing-later.jpg',
    );
    await source.writeAsBytes(List<int>.filled(96, 8), flush: true);
    addTearDown(() {
      if (source.existsSync()) source.deleteSync();
    });

    final staged = await staging.stage(
      ReceiptNativeCaptureResult(
        engine: ReceiptNativeCameraEngine.avFoundation,
        originalPhotoPaths: [source.path],
        temporaryCaptureIds: const ['missing-later'],
        capturedAt: DateTime(2026, 6, 28, 22),
      ),
    );
    await File(staged.photoPaths.single).delete();

    final manifestDir = File(staged.recoveryManifestPath).parent;
    await File('${manifestDir.path}/not-json.json').writeAsString('{oops');
    await File(
      '${manifestDir.path}/wrong-schema.json',
    ).writeAsString(jsonEncode({'schema': 'something_else'}));

    final records = await staging.recoverableNativeCaptures();

    expect(records, isEmpty);
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
}
