part of 'receipt_native_capture_staging.dart';

extension ReceiptNativeCaptureStagingRecoveryActions
    on ReceiptNativeCaptureStaging {
  Future<void> discard(ReceiptNativeCaptureStagingResult result) async {
    await _storage.deleteStagedAttachments(result.stagedAttachments);
    await _deleteRecoveryManifest(result.recoveryManifestPath);
  }

  Future<void> cleanOldAbandonedNativeStaging({
    Iterable<String> retainedPaths = const [],
    Duration olderThan = const Duration(days: 7),
    DateTime? now,
  }) async {
    // Old does not mean abandoned. Captures and manifests remain recoverable
    // until the user completes or explicitly discards the session.
    await _cleanRecoveryIndex(
      retainedPaths: retainedPaths,
      olderThan: olderThan,
      now: now,
    );
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

  Future<void> clearRecoveryManifestPath(String manifestPath) {
    return _deleteRecoveryManifest(manifestPath);
  }

  Future<void> markRecoveryStage(
    String manifestPath, {
    required String stage,
    required String reason,
    required String action,
    Map<String, Object?> extraMetadata = const {},
  }) async {
    final normalized = manifestPath.trim();
    if (normalized.isEmpty) return;
    final stageDiagnostics = _jsonSafeDiagnostics({
      'nativeRecoveryLastStage': stage,
      'nativeRecoveryLastReason': reason,
      'nativeRecoveryNextAction': action,
      'nativeRecoveryUpdatedAt': DateTime.now().toIso8601String(),
      ...extraMetadata,
    });
    if (stageDiagnostics.isEmpty) return;
    await _updateRecoveryManifestDiagnostics(
      normalized,
      diagnostics: stageDiagnostics,
    );
    try {
      final store = await ReceiptNativeCaptureRecoveryStore.create();
      await store.updateDiagnosticsByManifestPath(normalized, stageDiagnostics);
    } catch (_) {}
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

  Future<void> _updateRecoveryManifestDiagnostics(
    String manifestPath, {
    required Map<String, Object?> diagnostics,
  }) async {
    try {
      final file = File(manifestPath);
      if (!await file.exists()) return;
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return;
      final payload = Map<String, Object?>.from(decoded);
      final existingDiagnostics = _jsonSafeDiagnostics(
        receiptNativeCaptureSanitizedDiagnostics(payload['captureDiagnostics']),
      );
      payload['captureDiagnostics'] = _jsonSafeDiagnostics({
        ...existingDiagnostics,
        ...diagnostics,
      });
      payload['recoveryStage'] = {
        'schema': 'native_capture_recovery_stage_v1',
        'stage': diagnostics['nativeRecoveryLastStage'],
        'reason': diagnostics['nativeRecoveryLastReason'],
        'nextAction': diagnostics['nativeRecoveryNextAction'],
        'updatedAt': diagnostics['nativeRecoveryUpdatedAt'],
        'privacyScope': 'summary_only_no_receipt_content',
      };
      await file.writeAsString(jsonEncode(payload), flush: true);
    } catch (_) {}
  }
}
