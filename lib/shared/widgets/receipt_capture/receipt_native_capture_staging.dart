import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'receipt_capture_models.dart';
import 'receipt_native_capture_diagnostics_sanitizer.dart';
import 'receipt_native_camera_contract.dart';
import 'receipt_native_capture_recovery_store.dart';
import 'receipt_proof_storage.dart';

part 'receipt_native_capture_staging_diagnostics.dart';
part 'receipt_native_capture_staging_recovery_record.dart';
part 'receipt_native_capture_staging_recovery_actions.dart';
part 'receipt_native_capture_staging_manifest_helpers.dart';
part 'receipt_native_capture_staging_manifest_writer.dart';
part 'receipt_native_capture_staging_recovery_index.dart';
part 'receipt_native_capture_staging_safe_diagnostics.dart';
part 'receipt_native_capture_staging_safe_brain_keys.dart';
part 'receipt_native_capture_staging_safe_keys.dart';
part 'receipt_native_capture_staging_cleanup.dart';
part 'receipt_native_capture_staging_stage_helpers.dart';

class ReceiptNativeCaptureStagingResult {
  const ReceiptNativeCaptureStagingResult({
    required this.photoPaths,
    required this.originalToStagedPath,
    required this.captureDiagnosticsByPhotoPath,
    required this.stagedAttachments,
    required this.recoveryManifestPath,
  });

  final List<String> photoPaths;
  final Map<String, String> originalToStagedPath;
  final Map<String, Map<String, Object?>> captureDiagnosticsByPhotoPath;
  final List<ReceiptAttachmentRecord> stagedAttachments;
  final String recoveryManifestPath;

  bool get hasPhotos => photoPaths.isNotEmpty;

  Future<void> discardStagedPhotos({
    ReceiptNativeCaptureStaging staging = const ReceiptNativeCaptureStaging(),
  }) {
    return staging.discard(this);
  }
}

class ReceiptNativeCaptureStaging {
  const ReceiptNativeCaptureStaging({
    ReceiptProofStorage storage = ReceiptProofStorage.instance,
  }) : _storage = storage;

  final ReceiptProofStorage _storage;

  Future<ReceiptNativeCaptureStagingResult> stage(
    ReceiptNativeCaptureResult capture, {
    ReceiptDataSaverLevel dataSaverLevel = ReceiptDataSaverLevel.original,
  }) async {
    return _stageNativeCapture(this, capture, dataSaverLevel: dataSaverLevel);
  }
}

class _ReceiptBottomEdgeEvidence {
  const _ReceiptBottomEdgeEvidence({
    required this.detected,
    required this.status,
    required this.source,
    required this.reason,
  });

  final bool detected;
  final String status;
  final String source;
  final String reason;
}
