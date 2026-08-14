import 'receipt_capture_models.dart';
import 'receipt_native_capture_staging.dart';
import 'receipt_temporary_artifact_cleanup.dart';

/// Owns only the temporary artifacts created during one receipt-entry session.
///
/// Gallery originals are never deletion candidates. Staged capture manifests
/// remain recoverable until the person explicitly discards the session or a
/// durable receipt save succeeds.
class ReceiptSessionArtifactTracker {
  ReceiptSessionArtifactTracker({
    ReceiptTemporaryArtifactCleanup temporaryCleanup =
        const ReceiptTemporaryArtifactCleanup(),
    ReceiptNativeCaptureStaging nativeStaging =
        const ReceiptNativeCaptureStaging(),
  }) : _temporaryCleanup = temporaryCleanup,
       _nativeStaging = nativeStaging;

  final ReceiptTemporaryArtifactCleanup _temporaryCleanup;
  final ReceiptNativeCaptureStaging _nativeStaging;
  final Set<String> _temporaryArtifactPaths = {};
  final Set<String> _recoveryManifestPaths = {};

  void retainReviewSources(ReceiptPhotoReviewResult result) {
    _temporaryArtifactPaths
      ..addAll(result.photoPaths)
      ..addAll(result.ocrSourcePhotoPaths)
      ..addAll(result.temporarySourcePhotoPaths);
  }

  void retainRecoveryManifest(String manifestPath) {
    final normalized = manifestPath.trim();
    if (normalized.isNotEmpty) _recoveryManifestPaths.add(normalized);
  }

  Future<void> finalizeSuccessfulSave({
    required Iterable<String> keptReceiptPhotoPaths,
  }) async {
    await _temporaryCleanup.deleteAppOwnedFiles(
      _temporaryArtifactPaths,
      keptPaths: keptReceiptPhotoPaths,
    );
    _temporaryArtifactPaths.clear();
    await _finalizeTrackedManifests();
  }

  Future<void> discardSession() async {
    await _temporaryCleanup.deleteAppOwnedFiles(_temporaryArtifactPaths);
    _temporaryArtifactPaths.clear();
    final finalized = await _finalizeTrackedManifests();
    if (!finalized) {
      throw StateError(
        'Receipt recovery cleanup could not be confirmed. The draft was kept so this receipt can be recovered.',
      );
    }
  }

  Future<bool> _finalizeTrackedManifests() async {
    var allFinalized = true;
    for (final manifestPath in _recoveryManifestPaths.toList()) {
      try {
        final finalized = await _nativeStaging.finalizeAcceptedCapture(
          manifestPath,
        );
        if (finalized) {
          _recoveryManifestPaths.remove(manifestPath);
        } else {
          allFinalized = false;
        }
      } catch (_) {
        allFinalized = false;
      }
    }
    return allFinalized && _recoveryManifestPaths.isEmpty;
  }
}
