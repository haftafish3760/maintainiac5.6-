import 'receipt_capture_models.dart';
import 'receipt_native_camera_contract.dart';
import 'receipt_native_capture_staging.dart';
import 'receipt_proof_storage.dart';

/// Makes an app-owned, recoverable copy before a picked or fallback photo is
/// shown in receipt review. The original path remains recorded in staging
/// provenance; this helper never replaces the original evidence.
class ReceiptAcquiredPhotoStaging {
  const ReceiptAcquiredPhotoStaging({
    this.staging = const ReceiptNativeCaptureStaging(),
  });

  final ReceiptNativeCaptureStaging staging;

  Future<ReceiptNativeCaptureStagingResult> stage({
    required List<String> sourcePaths,
    required ReceiptDataSaverLevel dataSaverLevel,
    required String captureFlow,
    required String temporaryIdPrefix,
    Map<String, Object?> diagnostics = const {},
  }) async {
    final staged = await staging.stage(
      ReceiptNativeCaptureResult(
        engine: ReceiptNativeCameraEngine.unavailable,
        originalPhotoPaths: sourcePaths,
        temporaryCaptureIds: [
          for (var index = 0; index < sourcePaths.length; index++)
            '$temporaryIdPrefix-$index',
        ],
        capturedAt: DateTime.now(),
        captureDiagnostics: {'captureFlow': captureFlow, ...diagnostics},
      ),
      dataSaverLevel: dataSaverLevel,
    );
    if (staged.hasPhotos) return staged;
    throw const ReceiptProofStorageException(
      'That receipt photo could not be kept safely. Capture it again before continuing.',
    );
  }
}
