part of 'receipt_native_capture_staging.dart';

Future<ReceiptNativeCaptureStagingResult> _stageNativeCapture(
  ReceiptNativeCaptureStaging staging,
  ReceiptNativeCaptureResult capture, {
  required ReceiptDataSaverLevel dataSaverLevel,
}) async {
  final stagedPaths = <String>[];
  final stagedOriginalPaths = <String>[];
  final pathMap = <String, String>{};
  final captureDiagnosticsByPath = <String, Map<String, Object?>>{};
  final stagedAttachments = <ReceiptAttachmentRecord>[];
  final createdAt = capture.capturedAt;
  final sessionId = staging._captureSessionId(capture);
  final captureDiagnostics = staging._jsonSafeDiagnostics(
    capture.captureDiagnostics,
  );
  for (var index = 0; index < capture.originalPhotoPaths.length; index++) {
    final originalPath = capture.originalPhotoPaths[index].trim();
    if (originalPath.isEmpty) continue;
    final source = File(originalPath);
    if (!await source.exists()) continue;
    final staged = await staging._storage.stageAttachment(
      ReceiptAttachmentRecord(
        id: staging._captureId(capture, index, sessionId),
        path: source.path,
        kind: ReceiptAttachmentKind.photo,
        dataSaverLevel: dataSaverLevel,
        createdAt: createdAt,
        displayName: staging._displayName(index),
        originalFileName: path.basename(source.path),
        sourceLabel: staging._sourceLabel(capture.engine),
      ),
    );
    stagedPaths.add(staged.path);
    stagedOriginalPaths.add(originalPath);
    pathMap[originalPath] = staged.path;
    stagedAttachments.add(staged);
  }
  final manifestPath = stagedAttachments.isEmpty
      ? ''
      : await staging._writeRecoveryManifest(
          sessionId: sessionId,
          capture: capture,
          dataSaverLevel: dataSaverLevel,
          stagedAttachments: stagedAttachments,
          originalToStagedPath: pathMap,
        );
  for (var index = 0; index < stagedAttachments.length; index++) {
    final staged = stagedAttachments[index];
    final shutterZoom = _stagedShutterZoom(
      captureDiagnostics,
      stagedOriginalPaths[index],
    );
    captureDiagnosticsByPath[staged.path] = staging._stagedPhotoDiagnostics(
      baseDiagnostics: captureDiagnostics,
      staged: staged,
      index: index,
      stagedPhotoCount: stagedAttachments.length,
      recoveryManifestPath: manifestPath,
      shutterZoomRatio: shutterZoom,
    );
  }
  return ReceiptNativeCaptureStagingResult(
    photoPaths: stagedPaths,
    originalToStagedPath: pathMap,
    captureDiagnosticsByPhotoPath: captureDiagnosticsByPath,
    stagedAttachments: stagedAttachments,
    recoveryManifestPath: manifestPath,
  );
}

double? _stagedShutterZoom(
  Map<String, Object?> diagnostics,
  String originalPath,
) {
  final raw = diagnostics['captureShutterZoomByPath'];
  if (raw is! Map) return null;
  final value = raw[originalPath];
  final zoom = value is num ? value.toDouble() : double.tryParse('$value');
  return zoom != null && zoom.isFinite && zoom >= 1 ? zoom : null;
}
