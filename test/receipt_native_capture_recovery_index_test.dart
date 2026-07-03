import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
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
      expect(
        record.recoverySafety['schema'],
        'native_capture_recovery_safety_v1',
      );
      expect(record.recoverySafety['manifestBacked'], isTrue);
      expect(record.recoverySafety['hiveIndexSaved'], isTrue);
      expect(record.recoverySafety['localStagedPhotoCount'], 1);
      expect(record.recoverySafety['localExistingPhotoCount'], 1);
      expect(record.recoverySafety['allLocalPhotosExist'], isTrue);
      expect(
        record.recoverySafety['privacyScope'],
        'summary_only_no_receipt_content',
      );
      expect(
        record.recoverySafety['contentPolicy'],
        'no_receipt_text_no_customer_content',
      );
      expect(
        record.recoverySafety['attachmentState'],
        'staged_not_attached_until_user_accepts',
      );
      expect(
        record.recoverySafety['resumeAction'],
        'resume_review_before_receipt_details',
      );
      expect(
        record.recoverySafety['resumeCheckpoint'],
        'after_native_capture_before_ocr',
      );
      expect(
        record.recoverySafety['ocrSourcePolicy'],
        'original_staged_photo_used_before_data_saver_copy',
      );
      expect(
        record.recoverySafety['cleanupPolicy'],
        'discard_only_after_accept_or_user_discard_or_old_cleanup',
      );
      expect(
        record.recoverySafety['interruptionGuarantee'],
        'resume_review_keeps_photos_available_before_receipt_details',
      );
      expect(
        record.recoverySafety['userSafeExit'],
        'local_recovery_kept_until_accept_or_discard',
      );
      expect(
        record.privacySafeRecoveryEvidenceLabel,
        contains('hiveIndexSaved=true'),
      );
      expect(
        record.privacySafeRecoveryEvidenceLabel,
        contains('recoveryScope=summary_only_no_receipt_content'),
      );
      expect(
        record.privacySafeRecoveryEvidenceLabel,
        contains('checkpoint=after_native_capture_before_ocr'),
      );
      expect(
        record.privacySafeRecoveryEvidenceLabel,
        contains('ocrSource=original_staged_photo_used_before_data_saver_copy'),
      );
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
    expect(indexMap.toString(), contains('summary_only_no_receipt_content'));
    expect(indexMap.toString(), isNot(contains('LOWE private')));
    expect(indexMap.toString(), isNot(contains('Private Customer')));
  });

  test('recovery restore drops malformed diagnostic numbers', () {
    final entry = ReceiptNativeCaptureRecoveryIndexEntry.fromMap({
      'schema': ReceiptNativeCaptureRecoveryStore.entrySchema,
      'sessionId': 'unsafe-diagnostics',
      'manifestPath': '/tmp/unsafe-manifest.json',
      'engineName': ' cameraX ',
      'capturedAt': '2026-07-03T10:20:00.000Z',
      'dataSaverLevelName': ' balanced ',
      'photoCount': 1,
      'stagedPhotoPaths': const ['/tmp/recovered.jpg'],
      'captureDiagnostics': {
        'photoCount': 1,
        'latestFrameBrightness': double.nan,
        'zoomRatio': double.infinity,
        'nested': {'safe': 2.5, 'bad': double.negativeInfinity},
        'list': ['ok', double.nan, 3],
        7: 'non-string-key',
      },
      'recoverySafety': {
        'hiveIndexSaved': true,
        'maxLocalPhotoBytes': double.nan,
      },
    });

    expect(entry.captureDiagnostics['photoCount'], 1);
    expect(entry.captureDiagnostics, isNot(contains('latestFrameBrightness')));
    expect(entry.captureDiagnostics, isNot(contains('zoomRatio')));
    expect(entry.captureDiagnostics['nested'], {'safe': 2.5});
    expect(entry.captureDiagnostics['list'], ['ok', 3]);
    expect(entry.recoverySafety['hiveIndexSaved'], isTrue);
    expect(entry.recoverySafety, isNot(contains('maxLocalPhotoBytes')));
    expect(entry.toMap().toString(), isNot(contains('NaN')));
    expect(entry.toMap().toString(), isNot(contains('Infinity')));

    final record = ReceiptNativeCaptureRecoveryRecord.fromManifest(
      '/tmp/unsafe-manifest.json',
      entry.toMap(),
    );

    expect(record.captureDiagnostics['photoCount'], 1);
    expect(record.captureDiagnostics['nested'], {'safe': 2.5});
    expect(record.recoverySafety['hiveIndexSaved'], isTrue);
    expect(record.privacySafeRecoveryEvidenceLabel, contains('hiveIndexSaved'));
  });

  test('recovery index restore normalizes stored identity and paths', () {
    final entry = ReceiptNativeCaptureRecoveryIndexEntry.fromMap({
      'schema': ReceiptNativeCaptureRecoveryStore.entrySchema,
      'sessionId': ' native-session ',
      'manifestPath': ' /tmp/native-manifest.json ',
      'engineName': ' cameraX ',
      'capturedAt': '2026-07-03T10:20:00.000Z',
      'dataSaverLevelName': ' balanced ',
      'photoCount': 3,
      'stagedPhotoPaths': const [
        ' /tmp/section-one.jpg ',
        '/tmp/section-one.jpg',
        ' /tmp/section-two.jpg ',
      ],
      'attachments': const [],
    });

    expect(entry.sessionId, 'native-session');
    expect(entry.manifestPath, '/tmp/native-manifest.json');
    expect(entry.engineName, 'cameraX');
    expect(entry.dataSaverLevelName, 'balanced');
    expect(entry.stagedPhotoPaths, [
      '/tmp/section-one.jpg',
      '/tmp/section-two.jpg',
    ]);
    expect(entry.toMap()['manifestPath'], '/tmp/native-manifest.json');
    expect(entry.toMap()['stagedPhotoPaths'], [
      '/tmp/section-one.jpg',
      '/tmp/section-two.jpg',
    ]);
  });

  test(
    'native recovery restores padded engine names from saved state',
    () async {
      final staging = const ReceiptNativeCaptureStaging();
      final source = File(
        '${Directory.systemTemp.path}/native-padded-engine.jpg',
      );
      await source.writeAsBytes(List<int>.filled(96, 12), flush: true);
      addTearDown(() {
        if (source.existsSync()) source.deleteSync();
      });

      final staged = await staging.stage(
        ReceiptNativeCaptureResult(
          engine: ReceiptNativeCameraEngine.avFoundation,
          originalPhotoPaths: [source.path],
          temporaryCaptureIds: const ['padded-engine'],
          capturedAt: DateTime(2026, 7, 3, 5, 8),
        ),
      );

      final manifestFile = File(staged.recoveryManifestPath);
      final manifest = jsonDecode(await manifestFile.readAsString()) as Map;
      await manifestFile.writeAsString(
        jsonEncode({...manifest, 'engine': ' avFoundation '}),
        flush: true,
      );

      var records = await staging.recoverableNativeCaptures();
      expect(records.single.engine, ReceiptNativeCameraEngine.avFoundation);

      await manifestFile.delete();
      final store = await ReceiptNativeCaptureRecoveryStore.create();
      final indexEntry = store.entries.single;
      await store.save(
        ReceiptNativeCaptureRecoveryIndexEntry(
          sessionId: indexEntry.sessionId,
          manifestPath: indexEntry.manifestPath,
          engineName: ' avFoundation ',
          capturedAt: indexEntry.capturedAt,
          dataSaverLevelName: indexEntry.dataSaverLevelName,
          photoCount: indexEntry.photoCount,
          stagedPhotoPaths: indexEntry.stagedPhotoPaths,
          attachments: indexEntry.attachments,
          captureDiagnostics: indexEntry.captureDiagnostics,
          recoverySafety: indexEntry.recoverySafety,
        ),
      );

      records = await staging.recoverableNativeCaptures();
      expect(records.single.engine, ReceiptNativeCameraEngine.avFoundation);
    },
  );

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
}
