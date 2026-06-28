import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'receipt_capture_models.dart';
import 'receipt_native_camera_contract.dart';
import 'receipt_native_capture_recovery_store.dart';
import 'receipt_proof_storage.dart';

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

class ReceiptNativeCaptureRecoveryRecord {
  const ReceiptNativeCaptureRecoveryRecord({
    required this.manifestPath,
    required this.sessionId,
    required this.engine,
    required this.capturedAt,
    required this.dataSaverLevel,
    required this.stagedPhotoPaths,
    required this.attachments,
    required this.captureDiagnostics,
  });

  factory ReceiptNativeCaptureRecoveryRecord.fromManifest(
    String manifestPath,
    Map<dynamic, dynamic> map,
  ) {
    return ReceiptNativeCaptureRecoveryRecord(
      manifestPath: manifestPath,
      sessionId: map['sessionId'] as String? ?? '',
      engine: ReceiptNativeCameraEngine.values.firstWhere(
        (engine) => engine.name == map['engine'],
        orElse: () => ReceiptNativeCameraEngine.unavailable,
      ),
      capturedAt:
          DateTime.tryParse(map['capturedAt'] as String? ?? '') ??
          DateTime.now(),
      dataSaverLevel: ReceiptDataSaverLevel.fromName(
        map['dataSaverLevel'] as String?,
      ),
      stagedPhotoPaths:
          (map['stagedPhotoPaths'] as List?)
              ?.map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toList(growable: false) ??
          const [],
      attachments:
          (map['attachments'] as List?)
              ?.whereType<Map>()
              .map(ReceiptAttachmentRecord.fromMap)
              .toList(growable: false) ??
          const [],
      captureDiagnostics: Map<String, Object?>.from(
        map['captureDiagnostics'] is Map
            ? map['captureDiagnostics'] as Map
            : const {},
      ),
    );
  }

  final String manifestPath;
  final String sessionId;
  final ReceiptNativeCameraEngine engine;
  final DateTime capturedAt;
  final ReceiptDataSaverLevel dataSaverLevel;
  final List<String> stagedPhotoPaths;
  final List<ReceiptAttachmentRecord> attachments;
  final Map<String, Object?> captureDiagnostics;

  bool get hasExistingPhotos {
    return recoverablePhotoPaths.any(
      (photoPath) => File(photoPath).existsSync(),
    );
  }

  int get recoveredPhotoCount {
    return recoverablePhotoPaths.length;
  }

  bool get hasMultipleReceiptSections => recoveredPhotoCount > 1;

  List<String> get recoverablePhotoPaths {
    final paths = stagedPhotoPaths
        .map((photoPath) => photoPath.trim())
        .where((photoPath) => photoPath.isNotEmpty)
        .toList(growable: false);
    if (paths.isNotEmpty) return paths;
    return attachments
        .where((attachment) => attachment.isPhoto)
        .map((attachment) => attachment.path.trim())
        .where((photoPath) => photoPath.isNotEmpty)
        .toList(growable: false);
  }

  String get recoveredCountLabel {
    final count = recoveredPhotoCount;
    if (count <= 1) return '1 receipt photo';
    return '$count ordered receipt sections';
  }

  String get recoveryCloseActionLabel {
    final closeAction = captureDiagnostics['closeAction']?.toString() ?? '';
    return switch (closeAction) {
      'back_returned_captured_sections' =>
        'Back was pressed after photos were captured.',
      'done_returned_captured_sections' =>
        'Done was pressed after photos were captured.',
      'back_no_photo_cancel' => 'Back was pressed before a photo was saved.',
      'done_no_photo_cancel' => 'Done was pressed before a photo was saved.',
      _ => 'The receipt camera was interrupted before review finished.',
    };
  }

  String get recoveryResumeDetail {
    final sectionCopy = hasMultipleReceiptSections
        ? 'Resume keeps the top-to-bottom order for review.'
        : 'Resume opens the saved photo for review.';
    return '$recoveryCloseActionLabel $sectionCopy';
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
    final stagedPaths = <String>[];
    final pathMap = <String, String>{};
    final captureDiagnosticsByPath = <String, Map<String, Object?>>{};
    final stagedAttachments = <ReceiptAttachmentRecord>[];
    final createdAt = capture.capturedAt;
    final sessionId = _captureSessionId(capture);
    final captureDiagnostics = _jsonSafeDiagnostics(capture.captureDiagnostics);
    for (var index = 0; index < capture.originalPhotoPaths.length; index++) {
      final originalPath = capture.originalPhotoPaths[index].trim();
      if (originalPath.isEmpty) continue;
      final source = File(originalPath);
      if (!await source.exists()) continue;
      final staged = await _storage.stageAttachment(
        ReceiptAttachmentRecord(
          id: _captureId(capture, index, sessionId),
          path: source.path,
          kind: ReceiptAttachmentKind.photo,
          dataSaverLevel: dataSaverLevel,
          createdAt: createdAt,
          displayName: _displayName(index),
          originalFileName: path.basename(source.path),
          sourceLabel: _sourceLabel(capture.engine),
        ),
      );
      stagedPaths.add(staged.path);
      pathMap[originalPath] = staged.path;
      captureDiagnosticsByPath[staged.path] = captureDiagnostics;
      stagedAttachments.add(staged);
    }
    final manifestPath = stagedAttachments.isEmpty
        ? ''
        : await _writeRecoveryManifest(
            sessionId: sessionId,
            capture: capture,
            dataSaverLevel: dataSaverLevel,
            stagedAttachments: stagedAttachments,
            originalToStagedPath: pathMap,
          );
    return ReceiptNativeCaptureStagingResult(
      photoPaths: stagedPaths,
      originalToStagedPath: pathMap,
      captureDiagnosticsByPhotoPath: captureDiagnosticsByPath,
      stagedAttachments: stagedAttachments,
      recoveryManifestPath: manifestPath,
    );
  }

  Future<void> discard(ReceiptNativeCaptureStagingResult result) async {
    await _storage.deleteStagedAttachments(result.stagedAttachments);
    await _deleteRecoveryManifest(result.recoveryManifestPath);
  }

  Future<void> cleanOldAbandonedNativeStaging({
    Iterable<String> retainedPaths = const [],
    Duration olderThan = const Duration(days: 7),
    DateTime? now,
  }) async {
    await _storage.cleanOldStagedFiles(
      retainedPaths: retainedPaths,
      olderThan: olderThan,
      now: now,
    );
    await _cleanOldRecoveryManifests(
      retainedPaths: retainedPaths,
      olderThan: olderThan,
      now: now,
    );
    await _cleanUnrecoverableRecoveryIndex(retainedPaths: retainedPaths);
  }

  Future<List<ReceiptNativeCaptureRecoveryRecord>>
  recoverableNativeCaptures() async {
    final root = await _recoveryManifestRoot();
    final records = <ReceiptNativeCaptureRecoveryRecord>[];
    if (await root.exists()) {
      await for (final entity in root.list()) {
        if (entity is! File || path.extension(entity.path) != '.json') {
          continue;
        }
        try {
          final decoded = jsonDecode(await entity.readAsString());
          if (decoded is! Map ||
              decoded['schema'] !=
                  'maintainiac_native_receipt_capture_recovery_v1') {
            continue;
          }
          final record = ReceiptNativeCaptureRecoveryRecord.fromManifest(
            entity.path,
            decoded,
          );
          if (!record.hasExistingPhotos) continue;
          records.add(record);
        } catch (_) {
          continue;
        }
      }
    }
    records.addAll(await _recoverableNativeCapturesFromIndex(records));
    records.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
    return records;
  }

  Future<void> clearRecoveryRecord(ReceiptNativeCaptureRecoveryRecord record) {
    return _deleteRecoveryManifest(record.manifestPath);
  }

  Future<void> discardRecoveryRecord(
    ReceiptNativeCaptureRecoveryRecord record,
  ) async {
    final attachments = record.attachments.isNotEmpty
        ? record.attachments
        : _attachmentsFromStagedPaths(record);
    await _storage.deleteStagedAttachments(attachments);
    await _deleteRecoveryManifest(record.manifestPath);
  }

  String _captureId(
    ReceiptNativeCaptureResult capture,
    int index,
    String sessionId,
  ) {
    final nativeId = index < capture.temporaryCaptureIds.length
        ? capture.temporaryCaptureIds[index].trim()
        : '';
    final safeNativeId = nativeId
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    if (safeNativeId.isNotEmpty) return '$sessionId-$safeNativeId';
    return '$sessionId-$index';
  }

  String _captureSessionId(ReceiptNativeCaptureResult capture) {
    final nativeSeed = capture.temporaryCaptureIds.isEmpty
        ? ''
        : capture.temporaryCaptureIds.first.trim();
    final safeNativeSeed = nativeSeed
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    final timestamp = capture.capturedAt.microsecondsSinceEpoch;
    if (safeNativeSeed.isNotEmpty) return 'native-$timestamp-$safeNativeSeed';
    return 'native-$timestamp-${DateTime.now().microsecondsSinceEpoch}';
  }

  String _displayName(int index) {
    return index == 0 ? 'Receipt photo' : 'Receipt photo ${index + 1}';
  }

  String _sourceLabel(ReceiptNativeCameraEngine engine) {
    return switch (engine) {
      ReceiptNativeCameraEngine.cameraX => 'Maintainiac CameraX receipt camera',
      ReceiptNativeCameraEngine.avFoundation =>
        'Maintainiac AVFoundation receipt camera',
      ReceiptNativeCameraEngine.unavailable => 'Maintainiac receipt camera',
    };
  }

  Future<String> _writeRecoveryManifest({
    required String sessionId,
    required ReceiptNativeCaptureResult capture,
    required ReceiptDataSaverLevel dataSaverLevel,
    required List<ReceiptAttachmentRecord> stagedAttachments,
    required Map<String, String> originalToStagedPath,
  }) async {
    final directory = await _recoveryManifestRoot();
    await directory.create(recursive: true);
    final manifest = File(path.join(directory.path, '$sessionId.json'));
    final payload = <String, Object?>{
      'schema': 'maintainiac_native_receipt_capture_recovery_v1',
      'sessionId': sessionId,
      'createdAt': DateTime.now().toIso8601String(),
      'capturedAt': capture.capturedAt.toIso8601String(),
      'engine': capture.engine.name,
      'dataSaverLevel': dataSaverLevel.name,
      'photoCount': stagedAttachments.length,
      'stagedPhotoPaths': [
        for (final attachment in stagedAttachments) attachment.path,
      ],
      'attachments': [
        for (final attachment in stagedAttachments) attachment.toMap(),
      ],
      'originalToStagedPath': originalToStagedPath,
      'captureDiagnostics': _jsonSafeDiagnostics(capture.captureDiagnostics),
      'privacy': {
        'storesReceiptImageContent': false,
        'storesReceiptText': false,
        'storesCustomerContent': false,
      },
    };
    await manifest.writeAsString(jsonEncode(payload), flush: true);
    await _saveRecoveryIndex(
      ReceiptNativeCaptureRecoveryIndexEntry(
        sessionId: sessionId,
        manifestPath: manifest.path,
        engineName: capture.engine.name,
        capturedAt: capture.capturedAt,
        dataSaverLevelName: dataSaverLevel.name,
        photoCount: stagedAttachments.length,
        stagedPhotoPaths: [
          for (final attachment in stagedAttachments) attachment.path,
        ],
        attachments: stagedAttachments,
        captureDiagnostics: _jsonSafeDiagnostics(capture.captureDiagnostics),
      ),
    );
    return manifest.path;
  }

  Future<void> _saveRecoveryIndex(
    ReceiptNativeCaptureRecoveryIndexEntry entry,
  ) async {
    try {
      final store = await ReceiptNativeCaptureRecoveryStore.create();
      await store.save(entry);
    } catch (_) {}
  }

  Future<List<ReceiptNativeCaptureRecoveryRecord>>
  _recoverableNativeCapturesFromIndex(
    List<ReceiptNativeCaptureRecoveryRecord> manifestRecords,
  ) async {
    try {
      final store = await ReceiptNativeCaptureRecoveryStore.create();
      final manifestPaths = manifestRecords
          .map((record) => path.normalize(record.manifestPath.trim()))
          .where((item) => item.isNotEmpty)
          .toSet();
      final records = <ReceiptNativeCaptureRecoveryRecord>[];
      for (final entry in store.entries) {
        final normalizedManifest = path.normalize(entry.manifestPath.trim());
        if (manifestPaths.contains(normalizedManifest)) continue;
        if (!entry.hasExistingPhotos) continue;
        records.add(_recoveryRecordFromIndex(entry));
      }
      return records;
    } catch (_) {
      return const [];
    }
  }

  ReceiptNativeCaptureRecoveryRecord _recoveryRecordFromIndex(
    ReceiptNativeCaptureRecoveryIndexEntry entry,
  ) {
    final dataSaverLevel = ReceiptDataSaverLevel.fromName(
      entry.dataSaverLevelName,
    );
    final attachments = entry.attachments.isNotEmpty
        ? entry.attachments
        : [
            for (var index = 0; index < entry.stagedPhotoPaths.length; index++)
              ReceiptAttachmentRecord(
                id: '${entry.sessionId}-recovered-$index',
                path: entry.stagedPhotoPaths[index],
                kind: ReceiptAttachmentKind.photo,
                dataSaverLevel: dataSaverLevel,
                createdAt: entry.capturedAt,
                displayName: _displayName(index),
                sourceLabel: 'Maintainiac interrupted receipt capture',
              ),
          ];
    return ReceiptNativeCaptureRecoveryRecord(
      manifestPath: entry.manifestPath,
      sessionId: entry.sessionId,
      engine: ReceiptNativeCameraEngine.values.firstWhere(
        (engine) => engine.name == entry.engineName,
        orElse: () => ReceiptNativeCameraEngine.unavailable,
      ),
      capturedAt: entry.capturedAt,
      dataSaverLevel: dataSaverLevel,
      stagedPhotoPaths: entry.stagedPhotoPaths,
      attachments: attachments,
      captureDiagnostics: entry.captureDiagnostics,
    );
  }

  List<ReceiptAttachmentRecord> _attachmentsFromStagedPaths(
    ReceiptNativeCaptureRecoveryRecord record,
  ) {
    return [
      for (var index = 0; index < record.stagedPhotoPaths.length; index++)
        ReceiptAttachmentRecord(
          id: '${record.sessionId}-discard-$index',
          path: record.stagedPhotoPaths[index],
          kind: ReceiptAttachmentKind.photo,
          dataSaverLevel: record.dataSaverLevel,
          createdAt: record.capturedAt,
          displayName: _displayName(index),
          sourceLabel: 'Maintainiac interrupted receipt capture',
        ),
    ];
  }

  Map<String, Object?> _jsonSafeDiagnostics(Map<String, Object?> diagnostics) {
    final safe = <String, Object?>{};
    for (final entry in diagnostics.entries) {
      if (!_safeDiagnosticKeys.contains(entry.key)) continue;
      final value = entry.value;
      if (value == null ||
          value is String ||
          value is num ||
          value is bool ||
          value is List<String>) {
        safe[entry.key] = value;
      } else if (value is Iterable) {
        safe[entry.key] = value.map((item) => item.toString()).toList();
      } else {
        safe[entry.key] = value.toString();
      }
    }
    return safe;
  }

  static const _safeDiagnosticKeys = {
    'engine',
    'captureSurface',
    'captureMode',
    'captureQualityMode',
    'capturedAt',
    'photoByteSize',
    'photoByteSizeBucket',
    'latestCapturedPhotoWidth',
    'latestCapturedPhotoHeight',
    'latestCapturedMegapixelBucket',
    'latestCapturedByteBucket',
    'latestCapturedBrightnessBucket',
    'latestCapturedSharpnessBucket',
    'latestCapturedQualitySignal',
    'latestCapturedExposureMismatch',
    'photoCount',
    'maxSectionCount',
    'liveAnalysisEnabled',
    'analysisGapMs',
    'latestFrameBrightness',
    'latestShadowScore',
    'latestBrightnessBucket',
    'latestReadabilitySignal',
    'latestFramingSignal',
    'latestFramingConfidence',
    'latestEdgeCoverage',
    'latestPerspectiveReadiness',
    'edgeDetectionEnabled',
    'edgeOverlayEnabled',
    'shadowWarningEnabled',
    'textTooSmallWarningEnabled',
    'perspectiveCorrectionEnabled',
    'manualCropAfterCapture',
    'autoCropSuggestionEnabled',
    'grayscalePreviewEnabled',
    'contrastBoostEnabled',
    'sharpeningEnabled',
    'shadowReductionEnabled',
    'adaptiveThresholdEnabled',
    'orientationCorrectionEnabled',
    'latestMotionSignal',
    'latestMotionScore',
    'autoExposureAssistEnabled',
    'receiptGuidanceWarningsEnabled',
    'autoExposureAdjustmentCount',
    'lastAutoExposureDecision',
    'lastAutoExposureBrightnessBucket',
    'lastAutoExposureCandidate',
    'autoExposureCandidateFrameCount',
    'tapFocusCount',
    'tapFocusSuppressedAfterZoomCount',
    'zoomChangeCount',
    'manualExposureChangeCount',
    'lastFocusStatus',
    'autoCaptureStableFrameCount',
    'autoCaptureTriggerCount',
    'latestAutoCaptureStatus',
    'closeAction',
    'closeRetryCount',
    'closingCamera',
    'pendingCloseAfterCapture',
    'closeResultDelivered',
    'exposureAssistStatus',
    'userExposureOverride',
    'assistedReceiptFill',
    'longReceiptMode',
    'autoCaptureEnabled',
    'autoCaptureAllowed',
    'autoCaptureCurrentlyAllowed',
    'reviewDepth',
    'dataSaverLevel',
    'storageSafetyLevel',
    'storageConstrained',
    'storageSafetyReason',
    'hasPreviousSectionGuide',
    'torchOn',
    'hasFlashUnit',
    'hasTorch',
    'exposureCompensationIndex',
    'exposureCompensationRangeLower',
    'exposureCompensationRangeUpper',
    'exposureTargetBias',
    'minExposureTargetBias',
    'maxExposureTargetBias',
    'zoomRatio',
    'minZoomRatio',
    'maxZoomRatio',
    'tapFocusEnabled',
    'pinchZoomEnabled',
    'exposureSliderEnabled',
    'exposureResetEnabled',
    'manualShutterAlwaysAvailable',
    'ocrUsesOriginalFirst',
  };

  Future<Directory> _recoveryManifestRoot() async {
    final directory = await getApplicationDocumentsDirectory();
    return Directory(path.join(directory.path, 'native_capture_recovery'));
  }

  Future<void> _deleteRecoveryManifest(String manifestPath) async {
    if (manifestPath.trim().isEmpty) return;
    try {
      final file = File(manifestPath);
      if (await file.exists()) await file.delete();
    } catch (_) {}
    await _deleteRecoveryIndex(manifestPath);
  }

  Future<void> _deleteRecoveryIndex(String manifestPath) async {
    try {
      final store = await ReceiptNativeCaptureRecoveryStore.create();
      await store.deleteByManifestPath(manifestPath);
    } catch (_) {}
  }

  Future<void> _cleanUnrecoverableRecoveryIndex({
    required Iterable<String> retainedPaths,
  }) async {
    try {
      final store = await ReceiptNativeCaptureRecoveryStore.create();
      await store.deleteUnrecoverableEntries(retainedPaths: retainedPaths);
    } catch (_) {}
  }

  Future<void> _cleanOldRecoveryManifests({
    required Iterable<String> retainedPaths,
    Duration olderThan = const Duration(days: 7),
    DateTime? now,
  }) async {
    final retained = retainedPaths
        .map((item) => path.normalize(item.trim()))
        .where((item) => item.isNotEmpty)
        .toSet();
    final root = await _recoveryManifestRoot();
    if (!await root.exists()) return;
    final cutoff = (now ?? DateTime.now()).subtract(olderThan);
    await for (final entity in root.list()) {
      if (entity is! File || path.extension(entity.path) != '.json') continue;
      try {
        final stat = await entity.stat();
        if (stat.modified.isAfter(cutoff)) continue;
        final content = jsonDecode(await entity.readAsString());
        if (_manifestReferencesRetainedPath(content, retained)) continue;
        await _deleteRecoveryManifest(entity.path);
      } catch (_) {
        continue;
      }
    }
  }

  bool _manifestReferencesRetainedPath(Object? content, Set<String> retained) {
    if (retained.isEmpty || content is! Map) return false;
    final stagedPhotoPaths = content['stagedPhotoPaths'];
    if (stagedPhotoPaths is! Iterable) return false;
    for (final item in stagedPhotoPaths) {
      if (retained.contains(path.normalize(item.toString().trim()))) {
        return true;
      }
    }
    return false;
  }
}
