import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_native_camera_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_native_capture_recovery_store.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_native_capture_staging.dart';

import 'helpers/receipt_native_capture_staging_basic_expectations.dart';
import 'helpers/receipt_native_capture_staging_fixture.dart';
import 'helpers/receipt_native_capture_staging_harness.dart';
import 'helpers/receipt_native_capture_staging_index_expectations.dart';
import 'helpers/receipt_native_capture_staging_manifest_expectations.dart';
import 'helpers/receipt_native_capture_staging_signal_expectations.dart';

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
      acceptedNativeCaptureStagingFixture(
        sourcePath: source.path,
        capturedAt: capturedAt,
      ),
      dataSaverLevel: ReceiptDataSaverLevel.strong,
    );

    await expectAcceptedNativeCaptureStagingBasics(staged, source: source);
    await expectAcceptedNativeCaptureStagingSignals(staged);

    final manifest =
        jsonDecode(await File(staged.recoveryManifestPath).readAsString())
            as Map;
    expectAcceptedNativeCaptureRecoveryManifest(manifest, staged.photoPaths);

    final recoveryIndex = await ReceiptNativeCaptureRecoveryStore.create();
    await expectAcceptedNativeCaptureRecoveryIndex(
      recoveryIndex: recoveryIndex,
      staged: staged,
      manifest: manifest,
    );
  });

  test('native staging normalizes weak bottom edge evidence', () async {
    final sourceDir = await Directory.systemTemp.createTemp(
      'native_camera_bottom_edge_',
    );
    addTearDown(() async {
      if (await sourceDir.exists()) await sourceDir.delete(recursive: true);
    });
    final source = File('${sourceDir.path}/weak-bottom-edge.jpg');
    await source.writeAsBytes(List<int>.filled(384, 7), flush: true);

    final staged = await const ReceiptNativeCaptureStaging().stage(
      ReceiptNativeCaptureResult(
        engine: ReceiptNativeCameraEngine.cameraX,
        originalPhotoPaths: [source.path],
        temporaryCaptureIds: const ['weak-bottom'],
        capturedAt: DateTime(2026, 7, 1, 9, 10),
        captureDiagnostics: const {
          ReceiptCaptureDiagnosticKeys.latestCapturedBottomEdgeScore: .08,
          ReceiptCaptureDiagnosticKeys.latestFramingSignal:
              ReceiptNativeCoverageSignalValues.possiblyCutOff,
          ReceiptCaptureDiagnosticKeys.latestEdgeCoverage: .31,
          ReceiptCaptureDiagnosticKeys.latestPerspectiveReadiness:
              ReceiptNativeCoverageSignalValues.perspectiveSkippedCutOffRisk,
        },
      ),
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
    );

    final diagnostics =
        staged.captureDiagnosticsByPhotoPath[staged.photoPaths.single]!;
    expect(
      diagnostics[ReceiptCaptureDiagnosticKeys.receiptBottomEdgeDetected],
      isFalse,
    );
    expect(
      diagnostics[ReceiptCaptureDiagnosticKeys.receiptBottomEdgeStatus],
      'missing',
    );
    expect(
      diagnostics['receiptBottomEdgeEvidenceSource'],
      'native_bottom_edge_score',
    );
    expect(
      diagnostics['receiptBottomEdgeEvidenceReason'],
      'bottom_edge_score_below_missing_threshold',
    );
    final decision = ReceiptPhotoCoverageDecision.fromSignals(
      diagnostics: {
        ...diagnostics,
        ReceiptCaptureDiagnosticKeys.receiptSubtotalDetected: false,
        ReceiptCaptureDiagnosticKeys.receiptTotalDetected: false,
        ReceiptCaptureDiagnosticKeys.receiptTotalAmountDetected: false,
        ReceiptCaptureDiagnosticKeys.receiptTotalsTextEvidenceStatus: 'missing',
      },
    );
    expect(decision.reasonCode, 'missing_bottom_edge_and_totals');
    expect(
      decision.ghostGuideMatchTargetCode,
      'subtotal_total_and_final_lines',
    );
  });

  test('native staging treats non-finite edge evidence as cut off', () async {
    final sourceDir = await Directory.systemTemp.createTemp(
      'native_camera_nonfinite_edge_',
    );
    addTearDown(() async {
      if (await sourceDir.exists()) await sourceDir.delete(recursive: true);
    });
    final source = File('${sourceDir.path}/nonfinite-bottom-edge.jpg');
    await source.writeAsBytes(List<int>.filled(384, 9), flush: true);

    final staged = await const ReceiptNativeCaptureStaging().stage(
      ReceiptNativeCaptureResult(
        engine: ReceiptNativeCameraEngine.cameraX,
        originalPhotoPaths: [source.path],
        temporaryCaptureIds: const ['nonfinite-bottom'],
        capturedAt: DateTime(2026, 7, 3, 1, 6),
        captureDiagnostics: const {
          ReceiptCaptureDiagnosticKeys.latestCapturedBottomEdgeScore:
              double.infinity,
          ReceiptCaptureDiagnosticKeys.latestFramingSignal:
              ReceiptNativeCoverageSignalValues.possiblyCutOff,
          ReceiptCaptureDiagnosticKeys.latestEdgeCoverage: double.nan,
        },
      ),
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
    );

    final diagnostics =
        staged.captureDiagnosticsByPhotoPath[staged.photoPaths.single]!;
    expect(
      diagnostics[ReceiptCaptureDiagnosticKeys.receiptBottomEdgeDetected],
      isFalse,
    );
    expect(
      diagnostics[ReceiptCaptureDiagnosticKeys.receiptBottomEdgeStatus],
      'possibly_cut_off',
    );
    expect(
      diagnostics['receiptBottomEdgeEvidenceSource'],
      'native_framing_unusable_numbers',
    );
    expect(
      diagnostics['receiptBottomEdgeEvidenceReason'],
      'cut_off_signal_with_unusable_edge_evidence',
    );
    final manifest =
        jsonDecode(await File(staged.recoveryManifestPath).readAsString())
            as Map;
    expect(manifest.toString(), isNot(contains('Infinity')));
    expect(manifest.toString(), isNot(contains('NaN')));
  });

  test('native staging removes non-finite diagnostic list values', () async {
    final sourceDir = await Directory.systemTemp.createTemp(
      'native_camera_safe_list_',
    );
    addTearDown(() async {
      if (await sourceDir.exists()) await sourceDir.delete(recursive: true);
    });
    final source = File('${sourceDir.path}/safe-list.jpg');
    await source.writeAsBytes(List<int>.filled(256, 11), flush: true);

    final staged = await const ReceiptNativeCaptureStaging().stage(
      ReceiptNativeCaptureResult(
        engine: ReceiptNativeCameraEngine.cameraX,
        originalPhotoPaths: [source.path],
        temporaryCaptureIds: const ['safe-list'],
        capturedAt: DateTime(2026, 7, 3, 10, 22),
        captureDiagnostics: const {
          'capabilityPolicyCodes': [
            'edge_detection',
            double.nan,
            double.infinity,
            '-Infinity',
            3,
          ],
        },
      ),
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
    );

    final diagnostics =
        staged.captureDiagnosticsByPhotoPath[staged.photoPaths.single]!;
    expect(diagnostics['capabilityPolicyCodes'], ['edge_detection', '3']);
    final manifestText = await File(staged.recoveryManifestPath).readAsString();
    expect(manifestText, isNot(contains('Infinity')));
    expect(manifestText, isNot(contains('NaN')));
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
}
