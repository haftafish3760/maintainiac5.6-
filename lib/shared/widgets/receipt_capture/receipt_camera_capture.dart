part of 'receipt_camera_screen.dart';

class _ReceiptCameraCapturePolicy {
  const _ReceiptCameraCapturePolicy._();

  static const settleDelay = Duration(milliseconds: 320);
  static const assistedShotCount = 5;
  static const assistedShotGap = Duration(milliseconds: 260);
  static const analysisGap = Duration(milliseconds: 420);
  static const readyHoldTime = Duration(milliseconds: 650);
}

class _ReceiptCameraCandidate {
  const _ReceiptCameraCandidate({required this.path, required this.quality});

  final String path;
  final ReceiptPhotoQualityCheck quality;
}

int _compareReceiptCameraCandidates(
  _ReceiptCameraCandidate left,
  _ReceiptCameraCandidate right,
) {
  if (left.quality.isLikelyReadable != right.quality.isLikelyReadable) {
    return right.quality.isLikelyReadable ? 1 : -1;
  }
  final focus = right.quality.focusScore.compareTo(left.quality.focusScore);
  if (focus != 0) return focus;
  final rightPixels = right.quality.width * right.quality.height;
  final leftPixels = left.quality.width * left.quality.height;
  return rightPixels.compareTo(leftPixels);
}

Future<void> _deleteUnusedReceiptCameraPhotos(
  List<_ReceiptCameraCandidate> candidates,
  Set<String> keptPaths,
) async {
  for (final candidate in candidates) {
    if (keptPaths.contains(candidate.path)) continue;
    final path = candidate.path.trim();
    if (path.isEmpty) continue;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Best effort cleanup for app-created camera temp files.
    }
  }
}
