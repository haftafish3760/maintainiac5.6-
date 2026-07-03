part of 'receipt_photo_review_screen.dart';

class _PickedReceiptPhotos {
  const _PickedReceiptPhotos({
    required this.paths,
    required this.qualityChecksByPath,
    required this.captureDiagnosticsByPath,
    this.wasCanceled = false,
  });

  const _PickedReceiptPhotos.empty()
    : paths = const [],
      qualityChecksByPath = const {},
      captureDiagnosticsByPath = const {},
      wasCanceled = false;

  const _PickedReceiptPhotos.canceled()
    : paths = const [],
      qualityChecksByPath = const {},
      captureDiagnosticsByPath = const {},
      wasCanceled = true;

  factory _PickedReceiptPhotos.fromCameraResult(
    ReceiptCameraResult result,
    List<String> paths,
  ) {
    final pickedPaths = _pickedReceiptPhotoUniquePaths(paths);
    final checks = <String, ReceiptPhotoQualityCheck>{};
    if (_pickedReceiptPhotoPathsAreUnique(result.photoPaths) &&
        _pickedReceiptPhotoPathsAreUnique(pickedPaths) &&
        _pickedReceiptPhotoPathsAreCameraResultMembers(
          result.photoPaths,
          pickedPaths,
        )) {
      for (final path in pickedPaths) {
        final index = result.photoPaths.indexOf(path);
        final quality = result.qualityForIndex(index);
        if (quality != null) checks[path] = quality;
      }
    }
    return _PickedReceiptPhotos(
      paths: pickedPaths,
      qualityChecksByPath: checks,
      captureDiagnosticsByPath: result.captureDiagnosticsByPhotoPath(
        pickedPaths,
      ),
      wasCanceled: false,
    );
  }

  static _PickedReceiptPhotos fromNativePhotoPaths(
    List<String> paths, {
    Map<String, Map<String, Object?>> captureDiagnosticsByPath = const {},
  }) {
    final pickedPaths = _pickedReceiptPhotoUniquePaths(paths);
    return _PickedReceiptPhotos(
      paths: pickedPaths,
      qualityChecksByPath: const {},
      captureDiagnosticsByPath: _pickedReceiptDiagnosticsForPaths(
        captureDiagnosticsByPath,
        pickedPaths,
      ),
      wasCanceled: false,
    );
  }

  static _PickedReceiptPhotos fromPhoneCameraBackupPaths(
    List<String> paths, {
    required bool hadPreviousSectionGuide,
    ReceiptPhotoCoverageDecision? previousSectionCoverageDecision,
  }) {
    final pickedPaths = _pickedReceiptPhotoUniquePaths(paths);
    return _PickedReceiptPhotos(
      paths: pickedPaths,
      qualityChecksByPath: const {},
      captureDiagnosticsByPath: {
        for (final path in pickedPaths)
          path: {
            'captureFlow': 'phone_camera_backup_receipt_photo',
            'primaryCaptureFlow': 'maintainiac_native_receipt_camera',
            'phoneCameraBackupRole': 'fallback_only',
            'phoneCameraBackupUserFacingLabel':
                'Phone camera backup; returns to Maintainiac review',
            'phoneCameraBackupUsed': true,
            'phoneCameraBackupHadPreviousSectionGuide': hadPreviousSectionGuide,
            if (previousSectionCoverageDecision != null)
              'phoneCameraBackupPreviousSectionReasonCode':
                  previousSectionCoverageDecision.reasonCode,
            if (previousSectionCoverageDecision != null)
              'phoneCameraBackupPreviousSectionGuidance':
                  previousSectionCoverageDecision.guidance,
            if (previousSectionCoverageDecision?.isMissingBottomEdgeAndTotals ==
                true)
              'phoneCameraBackupPreviousSectionMissingBottomAndTotals': true,
            if (previousSectionCoverageDecision != null)
              'phoneCameraBackupPreviousSectionGhostGuidePolicy':
                  previousSectionCoverageDecision.ghostGuidePolicyCode,
            if (previousSectionCoverageDecision != null)
              'phoneCameraBackupPreviousSectionGhostGuideRepeatLineTarget':
                  'repeat_3_to_5_readable_lines',
            if (previousSectionCoverageDecision != null)
              'phoneCameraBackupPreviousSectionGhostGuidePlacement':
                  'top_ghost_slice',
            if (previousSectionCoverageDecision?.isMissingBottomEdgeAndTotals ==
                true)
              'phoneCameraBackupPreviousSectionGhostGuideMatchTarget':
                  'subtotal_total_and_final_lines',
            'nativeCaptureFailureStage': 'maintainiac_camera_unavailable',
            'nativeCaptureRecoveryAction': 'review_phone_camera_receipt_photo',
          },
      },
      wasCanceled: false,
    );
  }

  final List<String> paths;
  final Map<String, ReceiptPhotoQualityCheck> qualityChecksByPath;
  final Map<String, Map<String, Object?>> captureDiagnosticsByPath;
  final bool wasCanceled;
}

List<String> _pickedReceiptPhotoUniquePaths(List<String> paths) {
  return uniqueNormalizedReceiptPhotoPaths(paths);
}

Map<String, Map<String, Object?>> _pickedReceiptDiagnosticsForPaths(
  Map<String, Map<String, Object?>> diagnosticsByPath,
  List<String> paths,
) {
  if (diagnosticsByPath.isEmpty || paths.isEmpty) return const {};
  return Map<String, Map<String, Object?>>.unmodifiable({
    for (final path in paths)
      if (diagnosticsByPath[path] != null)
        path: Map<String, Object?>.unmodifiable(diagnosticsByPath[path]!),
  });
}

bool _pickedReceiptPhotoPathsAreUnique(List<String> paths) {
  return receiptPhotoPathsAreUniqueAndNormalized(paths);
}

bool _pickedReceiptPhotoPathsAreCameraResultMembers(
  List<String> resultPaths,
  List<String> pickedPaths,
) {
  for (final pickedPath in pickedPaths) {
    if (!receiptPhotoPathSetContains(resultPaths, pickedPath)) return false;
  }
  return true;
}
