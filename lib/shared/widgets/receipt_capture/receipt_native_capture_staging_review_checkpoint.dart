part of 'receipt_native_capture_staging.dart';

extension ReceiptNativeCaptureStagingReviewCheckpoint
    on ReceiptNativeCaptureStaging {
  Future<void> checkpointRecoveredCapture(
    ReceiptNativeCaptureRecoveryRecord record,
    ReceiptPhotoReviewResult review,
  ) {
    return checkpointReviewedCapture(
      ReceiptNativeCaptureStagingResult(
        photoPaths: record.recoverablePhotoPaths,
        originalToStagedPath: const {},
        captureDiagnosticsByPhotoPath: const {},
        stagedAttachments: record.attachments,
        recoveryManifestPath: record.manifestPath,
      ),
      review,
    );
  }

  /// Makes recovery resume the exact photo set and order approved in review.
  ///
  /// Source staging remains listed in [attachments] so final save or explicit
  /// discard can clean every app-owned copy. Only [stagedPhotoPaths] drives
  /// the resume surface, so a removed photo cannot reappear there.
  Future<void> checkpointReviewedCapture(
    ReceiptNativeCaptureStagingResult staged,
    ReceiptPhotoReviewResult review,
  ) async {
    final manifestPath = staged.recoveryManifestPath.trim();
    if (manifestPath.isEmpty || review.photoPaths.isEmpty) return;
    final manifestFile = File(manifestPath);
    final createdAttachments = <ReceiptAttachmentRecord>[];
    String? originalManifestSource;
    try {
      originalManifestSource = await manifestFile.readAsString();
      final decoded = jsonDecode(originalManifestSource);
      if (decoded is! Map ||
          decoded['schema'] !=
              'maintainiac_native_receipt_capture_recovery_v1') {
        throw const FormatException('Unsupported receipt recovery manifest.');
      }
      final payload = Map<String, Object?>.from(decoded);
      final existingAttachments = <ReceiptAttachmentRecord>[
        ...(decoded['attachments'] as List? ?? const []).whereType<Map>().map(
          ReceiptAttachmentRecord.fromMap,
        ),
      ];
      final attachmentByPath = {
        for (final attachment in existingAttachments)
          attachment.path.trim(): attachment,
      };
      final reviewedAttachments = <ReceiptAttachmentRecord>[];
      final checkpointId = DateTime.now().microsecondsSinceEpoch;
      for (var index = 0; index < review.photoPaths.length; index++) {
        final reviewedPath = review.photoPaths[index].trim();
        if (reviewedPath.isEmpty) continue;
        var attachment = attachmentByPath[reviewedPath];
        if (attachment == null) {
          attachment = await _storage.stageAttachment(
            ReceiptAttachmentRecord(
              id: 'reviewed-$checkpointId-$index',
              path: reviewedPath,
              kind: ReceiptAttachmentKind.photo,
              dataSaverLevel: review.dataSaverLevel,
              createdAt: DateTime.now(),
              displayName: 'Reviewed receipt photo ${index + 1}',
              originalFileName: path.basename(reviewedPath),
              sourceLabel: 'Receipt photo review',
            ),
          );
          if (attachment.storageState != ReceiptAttachmentStorageState.staged ||
              attachment.path.trim().isEmpty ||
              !await File(attachment.path).exists()) {
            throw StateError(
              'A reviewed receipt photo could not be staged for recovery.',
            );
          }
          createdAttachments.add(attachment);
          attachmentByPath[attachment.path.trim()] = attachment;
        }
        reviewedAttachments.add(attachment);
      }
      if (reviewedAttachments.length != review.photoPaths.length) {
        throw StateError(
          'The reviewed receipt order could not be checkpointed safely.',
        );
      }
      final cleanupAttachments = <ReceiptAttachmentRecord>[
        ...existingAttachments,
        ...createdAttachments,
      ];
      final reviewedPaths = [
        for (final attachment in reviewedAttachments) attachment.path,
      ];
      final safeDiagnostics = _jsonSafeDiagnostics({
        ...receiptNativeCaptureSanitizedDiagnostics(
          payload['captureDiagnostics'],
        ),
        'nativeRecoveryLastStage': 'review_checkpointed',
        'nativeRecoveryReviewedPhotoCount': reviewedPaths.length,
        'nativeRecoveryReviewOrderAuthoritative': true,
        'nativeRecoveryRemovedPhotoCount':
            (existingAttachments.length - reviewedAttachments.length).clamp(
              0,
              existingAttachments.length,
            ),
      });
      payload
        ..['photoCount'] = reviewedPaths.length
        ..['stagedPhotoPaths'] = reviewedPaths
        ..['attachments'] = [
          for (final attachment in cleanupAttachments) attachment.toMap(),
        ]
        ..['dataSaverLevel'] = review.dataSaverLevel.name
        ..['captureDiagnostics'] = safeDiagnostics
        ..['recoverySafety'] = _recoverySafetyPayload(
          stagedAttachments: cleanupAttachments,
          hiveIndexSaved: true,
        )
        ..['reviewCheckpoint'] = {
          'schema': 'receipt_review_checkpoint_v1',
          'reviewedPhotoCount': reviewedPaths.length,
          'orderedPhotoPaths': reviewedPaths,
          'userOrderAuthoritative': true,
          'removedPhotosExcludedFromResume': true,
        };
      await manifestFile.writeAsString(jsonEncode(payload), flush: true);

      final capturedAt =
          DateTime.tryParse('${payload['capturedAt'] ?? ''}') ?? DateTime.now();
      final store = await ReceiptNativeCaptureRecoveryStore.create();
      await store.save(
        ReceiptNativeCaptureRecoveryIndexEntry(
          sessionId: '${payload['sessionId'] ?? ''}'.trim(),
          manifestPath: manifestPath,
          engineName: '${payload['engine'] ?? ''}'.trim(),
          capturedAt: capturedAt,
          dataSaverLevelName: review.dataSaverLevel.name,
          photoCount: reviewedPaths.length,
          stagedPhotoPaths: reviewedPaths,
          attachments: cleanupAttachments,
          captureDiagnostics: safeDiagnostics,
          recoverySafety: receiptNativeCaptureSanitizedDiagnostics(
            payload['recoverySafety'],
          ),
        ),
      );
    } catch (_) {
      if (originalManifestSource != null) {
        try {
          await manifestFile.writeAsString(originalManifestSource, flush: true);
        } catch (_) {
          // The original manifest remains the recovery authority whenever the
          // filesystem permits restoration. The caller still fails closed.
        }
      }
      if (createdAttachments.isNotEmpty) {
        await _storage.deleteStagedAttachments(createdAttachments);
      }
      rethrow;
    }
  }
}
