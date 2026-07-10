part of 'receipt_photo_review_screen.dart';

class _PickedReceiptPhotos {
  _PickedReceiptPhotos({
    required List<String> paths,
    required Map<String, ReceiptPhotoQualityCheck> qualityChecksByPath,
    required Map<String, Map<String, Object?>> captureDiagnosticsByPath,
    this.wasCanceled = false,
  }) : paths = List<String>.unmodifiable(paths),
       qualityChecksByPath = Map<String, ReceiptPhotoQualityCheck>.unmodifiable(
         qualityChecksByPath,
       ),
       captureDiagnosticsByPath = _freezePickedReceiptDiagnostics(
         captureDiagnosticsByPath,
       );

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
    String? previousSectionReasonCode,
    String? previousSectionGuidance,
    ReceiptPhotoCoverageDecision? previousSectionCoverageDecision,
  }) {
    final pickedPaths = _pickedReceiptPhotoUniquePaths(paths);
    final normalizedReasonCode = _normalizedBackupPreviousSectionReason(
      previousSectionReasonCode,
    );
    final guidance =
        _trimmedBackupPreviousSectionValue(previousSectionGuidance) ??
        previousSectionCoverageDecision?.guidance;
    final missingBottomAndTotals =
        normalizedReasonCode == 'missing_bottom_edge_and_totals';
    final usesNextContext =
        normalizedReasonCode == 'retake_top_with_next_context';
    final ghostGuidePolicy = _phoneCameraBackupGhostGuidePolicy(
      normalizedReasonCode,
    );
    final ghostGuideMatchTarget = _phoneCameraBackupGhostGuideMatchTarget(
      normalizedReasonCode,
    );
    return _PickedReceiptPhotos(
      paths: pickedPaths,
      qualityChecksByPath: const {},
      captureDiagnosticsByPath: _freezePickedReceiptDiagnostics({
        for (final path in pickedPaths)
          path: {
            'captureFlow': 'phone_camera_backup_receipt_photo',
            'primaryCaptureFlow': 'maintainiac_native_receipt_camera',
            'phoneCameraBackupRole': 'fallback_only',
            'phoneCameraBackupUserFacingLabel':
                'Phone camera backup; returns to Maintainiac review',
            'phoneCameraBackupUsed': true,
            'phoneCameraBackupHadPreviousSectionGuide': hadPreviousSectionGuide,
            ...?switch (normalizedReasonCode) {
              final code? => {
                'phoneCameraBackupPreviousSectionReasonCode': code,
                'phoneCameraBackupPreviousSectionGhostGuideRepeatLineTarget':
                    'repeat_3_to_5_readable_lines',
                'phoneCameraBackupPreviousSectionGhostGuidePlacement':
                    'top_ghost_slice',
              },
              null => null,
            },
            ...?switch (guidance) {
              final previousGuidance? => {
                'phoneCameraBackupPreviousSectionGuidance': previousGuidance,
              },
              null => null,
            },
            if (missingBottomAndTotals)
              'phoneCameraBackupPreviousSectionMissingBottomAndTotals': true,
            ...?switch (ghostGuidePolicy) {
              final policy? => {
                'phoneCameraBackupPreviousSectionGhostGuidePolicy': policy,
              },
              null => null,
            },
            ...?switch (ghostGuideMatchTarget) {
              final matchTarget? => {
                'phoneCameraBackupPreviousSectionGhostGuideMatchTarget':
                    matchTarget,
              },
              null => null,
            },
            if (usesNextContext)
              'phoneCameraBackupPreviousSectionGhostGuideUsesNextContext': true,
            'nativeCaptureFailureStage': 'maintainiac_camera_unavailable',
            'nativeCaptureRecoveryAction': 'review_phone_camera_receipt_photo',
          },
      }),
      wasCanceled: false,
    );
  }

  final List<String> paths;
  final Map<String, ReceiptPhotoQualityCheck> qualityChecksByPath;
  final Map<String, Map<String, Object?>> captureDiagnosticsByPath;
  final bool wasCanceled;
}

Map<String, Map<String, Object?>> _freezePickedReceiptDiagnostics(
  Map<String, Map<String, Object?>> diagnosticsByPath,
) {
  if (diagnosticsByPath.isEmpty) return const {};
  return Map<String, Map<String, Object?>>.unmodifiable({
    for (final entry in diagnosticsByPath.entries)
      entry.key: Map<String, Object?>.unmodifiable(entry.value),
  });
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

String? _trimmedBackupPreviousSectionValue(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}

String? _normalizedBackupPreviousSectionReason(String? value) {
  final trimmed = _trimmedBackupPreviousSectionValue(value);
  if (trimmed == null) return null;
  final normalized = trimmed
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  return normalized.isEmpty ? null : normalized;
}

String? _phoneCameraBackupGhostGuidePolicy(String? reasonCode) {
  if (reasonCode == null) return null;
  if (reasonCode == 'retake_top_with_next_context') {
    return 'next_section_top_context_ghost_at_top_repeat_3_to_5_lines';
  }
  if (reasonCode == 'missing_bottom_edge_and_totals') {
    return 'bottom_overlap_ghost_at_top_repeat_3_to_5_lines';
  }
  return 'section_overlap_ghost_at_top_repeat_3_to_5_lines';
}

String? _phoneCameraBackupGhostGuideMatchTarget(String? reasonCode) {
  if (reasonCode == null) return null;
  if (reasonCode == 'retake_top_with_next_context') {
    return 'next_section_top_lines';
  }
  if (reasonCode == 'missing_bottom_edge_and_totals') {
    return 'subtotal_total_and_final_lines';
  }
  return 'repeated_receipt_lines';
}
