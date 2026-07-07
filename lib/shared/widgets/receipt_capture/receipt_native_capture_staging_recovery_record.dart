part of 'receipt_native_capture_staging.dart';

class ReceiptNativeCaptureRecoveryRecord {
  ReceiptNativeCaptureRecoveryRecord({
    required this.manifestPath,
    required this.sessionId,
    required this.engine,
    required this.capturedAt,
    required this.dataSaverLevel,
    required List<String> stagedPhotoPaths,
    required List<ReceiptAttachmentRecord> attachments,
    required Map<String, Object?> captureDiagnostics,
    Map<String, Object?> recoverySafety = const {},
  }) : stagedPhotoPaths = List<String>.unmodifiable(stagedPhotoPaths),
       attachments = List<ReceiptAttachmentRecord>.unmodifiable(attachments),
       captureDiagnostics = receiptNativeCaptureSanitizedDiagnostics(
         captureDiagnostics,
       ),
       recoverySafety = receiptNativeCaptureSanitizedDiagnostics(
         recoverySafety,
       );

  factory ReceiptNativeCaptureRecoveryRecord.fromManifest(
    String manifestPath,
    Map<dynamic, dynamic> manifest,
  ) {
    final dataSaverLevel = ReceiptDataSaverLevel.fromName(
      manifest['dataSaverLevel'] as String? ?? '',
    );
    return ReceiptNativeCaptureRecoveryRecord(
      manifestPath: manifestPath,
      sessionId: manifest['sessionId'] as String? ?? '',
      engine: receiptNativeCameraEngineFromName(manifest['engine'] as String?),
      capturedAt:
          DateTime.tryParse(manifest['capturedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      dataSaverLevel: dataSaverLevel,
      stagedPhotoPaths:
          (manifest['stagedPhotoPaths'] as List?)
              ?.map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toSet()
              .toList(growable: false) ??
          const [],
      attachments:
          (manifest['attachments'] as List?)
              ?.whereType<Map>()
              .map(ReceiptAttachmentRecord.fromMap)
              .toList(growable: false) ??
          const [],
      captureDiagnostics: receiptNativeCaptureSanitizedDiagnostics(
        manifest['captureDiagnostics'],
      ),
      recoverySafety: receiptNativeCaptureSanitizedDiagnostics(
        manifest['recoverySafety'],
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
  final Map<String, Object?> recoverySafety;

  List<String> get recoverablePhotoPaths {
    if (stagedPhotoPaths.isNotEmpty) return stagedPhotoPaths;
    return [
      for (final attachment in attachments)
        if (attachment.path.trim().isNotEmpty) attachment.path.trim(),
    ];
  }

  int get recoveredPhotoCount => recoverablePhotoPaths.length;

  int get existingPhotoCount {
    return recoverablePhotoPaths
        .where((photoPath) => File(photoPath).existsSync())
        .length;
  }

  int get missingPhotoCount {
    return recoveredPhotoCount - existingPhotoCount;
  }

  bool get hasExistingPhotos => existingPhotoCount > 0;

  bool get hasCompleteLocalRecovery {
    return recoveredPhotoCount > 0 && existingPhotoCount == recoveredPhotoCount;
  }

  bool get hasMultipleReceiptSections => recoveredPhotoCount > 1;

  bool? get assistedReceiptFillAtCapture {
    final value = captureDiagnostics['assistedReceiptFill'];
    if (value is bool) return value;
    final normalized = value?.toString().trim().toLowerCase();
    if (normalized == 'true') return true;
    if (normalized == 'false') return false;
    return null;
  }

  String get recoveryStorageStatus {
    if (hasCompleteLocalRecovery) return 'all_photos_available';
    if (hasExistingPhotos) return 'partial_photos_available';
    return 'photos_missing';
  }

  Duration recoveryAge({DateTime? now}) {
    return (now ?? DateTime.now()).difference(capturedAt);
  }

  String recoveryFreshnessBucket({DateTime? now}) {
    final age = recoveryAge(now: now);
    if (age <= const Duration(days: 1)) return 'fresh';
    if (age <= const Duration(days: 3)) return 'aging';
    if (age <= const Duration(days: 7)) return 'stale';
    return 'very_stale';
  }

  String recoveryFreshnessLabel({DateTime? now}) {
    return switch (recoveryFreshnessBucket(now: now)) {
      'fresh' => 'Recently saved',
      'aging' => 'Saved earlier',
      'stale' => 'Older saved receipt',
      _ => 'Very old saved receipt',
    };
  }

  String get recoveryResumeOutcomeCode {
    if (hasCompleteLocalRecovery) return 'resume_review_available';
    if (hasExistingPhotos) return 'partial_photos_available';
    return 'photos_missing';
  }

  String get recoveryResumeOutcomeLabel {
    return switch (recoveryResumeOutcomeCode) {
      'resume_review_available' => 'Saved receipt photos are ready to review.',
      'partial_photos_available' =>
        'Some saved receipt photos are still available for review.',
      _ =>
        'Saved receipt photos are missing from this device and must be retaken.',
    };
  }

  String get recoveryResumeStatusLabel {
    return switch (recoveryResumeOutcomeCode) {
      'resume_review_available' => 'Ready to resume',
      'partial_photos_available' => 'Partial recovery',
      _ => 'Photos missing',
    };
  }

  String get recoveryResumeActionLabel {
    return hasCompleteLocalRecovery
        ? 'Resume receipt review'
        : 'Retake receipt photos';
  }

  String get recoveryResumeActionDetail {
    if (hasCompleteLocalRecovery) {
      return 'Review the saved receipt photos before opening receipt details.';
    }
    if (hasExistingPhotos) {
      return 'Some saved files remain on this device. Review what is available or retake the receipt photos.';
    }
    return 'The saved files are no longer on this device. Take the receipt photos again.';
  }

  String get recoveredCountLabel {
    if (recoveredPhotoCount == 1) return '1 receipt photo';
    return '$recoveredPhotoCount ordered receipt sections';
  }

  String get recoveryCloseActionLabel {
    return switch (captureDiagnostics['closeAction']) {
      'back_returned_captured_sections' =>
        'Back was pressed after photos were captured.',
      'done_returned_captured_sections' =>
        'Done was pressed after photos were captured.',
      'back_no_photo_cancel' => 'Back was pressed before a photo was saved.',
      'done_no_photo_cancel' => 'Done was pressed before a photo was saved.',
      _ => 'Receipt capture was interrupted after photos were captured.',
    };
  }

  String get recoveryResumeDetail {
    final orderCopy = hasMultipleReceiptSections
        ? 'keeps the top-to-bottom order'
        : 'keeps the saved photo';
    return '$recoveryCloseActionLabel Resume $orderCopy for review.';
  }

  String get recoveryNextActionLabel => 'Review saved receipt sections';

  String get recoveryNextActionDetail {
    return 'Resume to review the saved sections in order, then use the saved photos to open receipt details from the saved proof. Discard only if these saved photos are not needed.';
  }

  String get privacySafeRecoveryEvidenceLabel {
    final fields = <String>[
      'freshness=${recoveryFreshnessBucket()}',
      'storageStatus=$recoveryStorageStatus',
      'resumeOutcome=$recoveryResumeOutcomeCode',
      'existingPhotos=$existingPhotoCount',
      'missingPhotos=$missingPhotoCount',
      if (captureDiagnostics['maxLocalPhotoBytes'] != null)
        'maxLocalPhotoBytes=${captureDiagnostics['maxLocalPhotoBytes']}',
      if (captureDiagnostics['nativeCaptureMemoryPolicy'] != null)
        'memoryPolicy=${captureDiagnostics['nativeCaptureMemoryPolicy']}',
      if (recoverySafety['hiveIndexSaved'] != null)
        'hiveIndexSaved=${recoverySafety['hiveIndexSaved']}',
      if (recoverySafety['privacyScope'] != null)
        'recoveryScope=${recoverySafety['privacyScope']}',
      if (recoverySafety['resumeCheckpoint'] != null)
        'checkpoint=${recoverySafety['resumeCheckpoint']}',
      if (recoverySafety['ocrSourcePolicy'] != null)
        'ocrSource=${recoverySafety['ocrSourcePolicy']}',
    ];
    return fields.join(' ');
  }
}
