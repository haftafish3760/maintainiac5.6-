part of 'receipt_native_capture_staging.dart';

extension _ReceiptNativeCaptureStagingRecoveryIndex
    on ReceiptNativeCaptureStaging {
  Future<bool> _saveRecoveryIndex(
    ReceiptNativeCaptureRecoveryIndexEntry entry,
  ) async {
    try {
      final store = await ReceiptNativeCaptureRecoveryStore.create();
      await store.save(entry);
      return true;
    } catch (_) {
      return false;
    }
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
      recoverySafety: entry.recoverySafety,
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
}
