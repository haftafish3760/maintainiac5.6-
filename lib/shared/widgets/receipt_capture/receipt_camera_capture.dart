part of 'receipt_camera_screen.dart';

class _ReceiptCameraCapturePolicy {
  const _ReceiptCameraCapturePolicy({
    required this.resolutionTier,
    required this.quickShotCount,
    required this.assistedShotCount,
    required this.bestShotCandidateCount,
    required this.analysisGap,
    required this.readyHoldTime,
    required this.minimumAutoCaptureFrames,
    required this.minimumAutoFocusScore,
    required this.minimumAutoContrast,
    required this.minimumAutoTextBandScore,
    required this.minimumAutoCropScore,
    required this.minimumLiveEdgeConfidence,
    required this.enableLiveEdgeOverlay,
  });

  factory _ReceiptCameraCapturePolicy.forCapability(
    ReceiptDeviceCapability capability,
  ) {
    final assistedShotCount = capability.assistedCameraShotCount.clamp(1, 6);
    return _ReceiptCameraCapturePolicy(
      resolutionTier: capability.cameraResolutionTier,
      quickShotCount: assistedShotCount <= 2 ? 2 : 3,
      assistedShotCount: assistedShotCount,
      bestShotCandidateCount: capability.bestShotCandidateCount.clamp(1, 6),
      analysisGap: Duration(milliseconds: capability.liveAnalysisGapMs),
      readyHoldTime: Duration(milliseconds: capability.readyHoldMs),
      minimumAutoCaptureFrames: switch (capability.tier) {
        ReceiptCapabilityTier.light => 4,
        ReceiptCapabilityTier.medium => 4,
        ReceiptCapabilityTier.heavyweight => 5,
      },
      minimumAutoFocusScore: switch (capability.tier) {
        ReceiptCapabilityTier.light => 8.2,
        ReceiptCapabilityTier.medium => 8.8,
        ReceiptCapabilityTier.heavyweight => 9.4,
      },
      minimumAutoContrast: switch (capability.tier) {
        ReceiptCapabilityTier.light => 19.0,
        ReceiptCapabilityTier.medium => 20.0,
        ReceiptCapabilityTier.heavyweight => 21.0,
      },
      minimumAutoTextBandScore: switch (capability.tier) {
        ReceiptCapabilityTier.light => 8.4,
        ReceiptCapabilityTier.medium => 9.0,
        ReceiptCapabilityTier.heavyweight => 9.6,
      },
      minimumAutoCropScore: switch (capability.tier) {
        ReceiptCapabilityTier.light => .52,
        ReceiptCapabilityTier.medium => .56,
        ReceiptCapabilityTier.heavyweight => .58,
      },
      minimumLiveEdgeConfidence: switch (capability.tier) {
        ReceiptCapabilityTier.light => .92,
        ReceiptCapabilityTier.medium => .68,
        ReceiptCapabilityTier.heavyweight => .72,
      },
      enableLiveEdgeOverlay: switch (capability.tier) {
        ReceiptCapabilityTier.light => false,
        ReceiptCapabilityTier.medium => true,
        ReceiptCapabilityTier.heavyweight => true,
      },
    );
  }

  final ReceiptCameraResolutionTier resolutionTier;
  final int quickShotCount;
  final int assistedShotCount;
  final int bestShotCandidateCount;
  final Duration analysisGap;
  final Duration readyHoldTime;
  final int minimumAutoCaptureFrames;
  final double minimumAutoFocusScore;
  final double minimumAutoContrast;
  final double minimumAutoTextBandScore;
  final double minimumAutoCropScore;
  final double minimumLiveEdgeConfidence;
  final bool enableLiveEdgeOverlay;

  Duration get manualSettleDelay => const Duration(milliseconds: 120);
  Duration get assistedSettleDelay => const Duration(milliseconds: 520);
  Duration get quickShotGap => const Duration(milliseconds: 180);
  Duration get assistedShotGap => const Duration(milliseconds: 320);
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
  final score = right.quality.reviewScore.compareTo(left.quality.reviewScore);
  if (score != 0) return score;
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
