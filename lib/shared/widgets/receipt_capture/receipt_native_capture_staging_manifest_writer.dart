part of 'receipt_native_capture_staging.dart';

extension _ReceiptNativeCaptureStagingManifestWriter
    on ReceiptNativeCaptureStaging {
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
    final safeDiagnostics = _jsonSafeDiagnostics(capture.captureDiagnostics);
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
      'captureDiagnostics': safeDiagnostics,
      'recoverySafety': _recoverySafetyPayload(
        stagedAttachments: stagedAttachments,
        hiveIndexSaved: false,
      ),
      'privacy': {
        'storesReceiptImageContent': false,
        'storesReceiptText': false,
        'storesCustomerContent': false,
      },
    };
    await manifest.writeAsString(jsonEncode(payload), flush: true);
    final hiveIndexSaved = await _saveRecoveryIndex(
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
        captureDiagnostics: safeDiagnostics,
        recoverySafety: _recoverySafetyPayload(
          stagedAttachments: stagedAttachments,
          hiveIndexSaved: true,
        ),
      ),
    );
    payload['recoverySafety'] = _recoverySafetyPayload(
      stagedAttachments: stagedAttachments,
      hiveIndexSaved: hiveIndexSaved,
    );
    await manifest.writeAsString(jsonEncode(payload), flush: true);
    return manifest.path;
  }

  Map<String, Object?> _recoverySafetyPayload({
    required List<ReceiptAttachmentRecord> stagedAttachments,
    required bool hiveIndexSaved,
  }) {
    final localCopyCount = stagedAttachments
        .where((attachment) => File(attachment.path).existsSync())
        .length;
    return {
      'schema': 'native_capture_recovery_safety_v1',
      'manifestBacked': true,
      'hiveIndexSaved': hiveIndexSaved,
      'localStagedPhotoCount': stagedAttachments.length,
      'localExistingPhotoCount': localCopyCount,
      'allLocalPhotosExist':
          stagedAttachments.isNotEmpty &&
          localCopyCount == stagedAttachments.length,
      'privacyScope': 'summary_only_no_receipt_content',
      'contentPolicy': 'no_receipt_text_no_customer_content',
      'attachmentState': 'staged_not_attached_until_user_accepts',
      'resumeAction': 'resume_review_before_receipt_details',
      'resumeCheckpoint': 'after_native_capture_before_ocr',
      'ocrSourcePolicy': 'original_staged_photo_used_before_data_saver_copy',
      'cleanupPolicy':
          'discard_only_after_accept_or_user_discard_or_old_cleanup',
      'writeOrder': 'copy_photo_then_manifest_then_hive_index',
      'interruptionGuarantee':
          'resume_review_keeps_photos_available_before_receipt_details',
      'coveredInterruptions': _coveredInterruptionCases,
      'userSafeExit': 'local_recovery_kept_until_accept_or_discard',
    };
  }
}
