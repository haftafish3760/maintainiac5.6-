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

  static _PickedReceiptPhotos fromSystemCameraPaths(
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
    return _PickedReceiptPhotos(
      paths: pickedPaths,
      qualityChecksByPath: const {},
      captureDiagnosticsByPath: _freezePickedReceiptDiagnostics({
        for (final path in pickedPaths)
          path: {
            'captureFlow': 'system_phone_camera_receipt_photo',
            'systemPhoneCameraUsed': true,
            'systemPhoneCameraRole': 'primary_capture',
            'systemPhoneCameraHadPreviousSectionGuide': hadPreviousSectionGuide,
            ...?switch (normalizedReasonCode) {
              final reasonCode? => {
                'systemPhoneCameraPreviousSectionReasonCode': reasonCode,
              },
              null => null,
            },
            ...?switch (guidance) {
              final previousGuidance? => {
                'systemPhoneCameraPreviousSectionGuidance': previousGuidance,
              },
              null => null,
            },
            if (normalizedReasonCode == 'missing_bottom_edge_and_totals')
              'systemPhoneCameraPreviousSectionMissingBottomAndTotals': true,
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
