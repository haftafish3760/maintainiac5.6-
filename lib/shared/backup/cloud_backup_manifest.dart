import '../documents/app_document_models.dart';
import '../media/app_media_asset.dart';
import '../widgets/receipt_capture/receipt_capture_models.dart';

enum CloudBackupPrivacyScope { normal, customerProtected }

class CloudBackupManifest {
  const CloudBackupManifest({required this.createdAt, required this.entries});

  factory CloudBackupManifest.fromDocuments({
    required Iterable<AppDocumentRecord> documents,
    Iterable<AppMediaAsset> mediaAssets = const [],
    bool includeCustomerProtected = false,
    DateTime? createdAt,
  }) {
    final entries = <CloudBackupManifestEntry>[];
    for (final document in documents) {
      final privacyScope = _privacyScopeForDocument(document);
      if (privacyScope == CloudBackupPrivacyScope.customerProtected &&
          !includeCustomerProtected) {
        continue;
      }
      for (final attachment in document.attachments) {
        final entry = CloudBackupManifestEntry.fromAttachment(
          document: document,
          attachment: attachment,
          privacyScope: privacyScope,
        );
        if (entry != null) entries.add(entry);
      }
    }
    for (final asset in mediaAssets) {
      final entry = CloudBackupManifestEntry.fromMediaAsset(asset);
      if (entry != null) entries.add(entry);
    }
    return CloudBackupManifest(
      createdAt: createdAt ?? DateTime.now(),
      entries: entries,
    );
  }

  final DateTime createdAt;
  final List<CloudBackupManifestEntry> entries;

  int get pendingBytes {
    return entries.fold(0, (sum, entry) => sum + entry.byteSize);
  }

  int get entryCount => entries.length;

  bool get hasEntries => entries.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'createdAt': createdAt.toIso8601String(),
      'pendingBytes': pendingBytes,
      'entryCount': entryCount,
      'entries': [for (final entry in entries) entry.toMap()],
    };
  }

  static CloudBackupPrivacyScope _privacyScopeForDocument(
    AppDocumentRecord document,
  ) {
    return switch (document.kind) {
      AppDocumentKind.invoiceDocument =>
        CloudBackupPrivacyScope.customerProtected,
      _ => CloudBackupPrivacyScope.normal,
    };
  }
}

class CloudBackupManifestEntry {
  const CloudBackupManifestEntry({
    required this.id,
    required this.localPath,
    required this.module,
    required this.recordId,
    required this.kind,
    required this.byteSize,
    required this.fileHashSha256,
    required this.privacyScope,
    this.mimeType = '',
    this.displayName = '',
  });

  static CloudBackupManifestEntry? fromMediaAsset(AppMediaAsset asset) {
    if (!asset.canAttemptCloudBackup || !asset.hasFile) return null;
    return CloudBackupManifestEntry(
      id: asset.id,
      localPath: asset.path,
      module: _moduleForMediaPurpose(asset.purpose),
      recordId: asset.id,
      kind: asset.purpose.name,
      byteSize: asset.byteSize ?? 0,
      fileHashSha256: asset.fileHash,
      privacyScope: CloudBackupPrivacyScope.normal,
      mimeType: asset.mimeType,
      displayName: asset.displayName,
    );
  }

  static CloudBackupManifestEntry? fromAttachment({
    required AppDocumentRecord document,
    required ReceiptAttachmentRecord attachment,
    required CloudBackupPrivacyScope privacyScope,
  }) {
    final hash = attachment.fileHash.trim();
    final byteSize = attachment.byteSize ?? 0;
    final localPath = attachment.path.trim();
    if (hash.isEmpty || byteSize <= 0 || localPath.isEmpty) return null;
    return CloudBackupManifestEntry(
      id: attachment.id,
      localPath: localPath,
      module: document.kind.storageModule,
      recordId: document.id,
      kind: attachment.kind.name,
      byteSize: byteSize,
      fileHashSha256: hash,
      privacyScope: privacyScope,
      mimeType: attachment.mimeType,
      displayName: attachment.displayName,
    );
  }

  final String id;
  final String localPath;
  final String module;
  final String recordId;
  final String kind;
  final int byteSize;
  final String fileHashSha256;
  final CloudBackupPrivacyScope privacyScope;
  final String mimeType;
  final String displayName;

  bool get isCustomerProtected =>
      privacyScope == CloudBackupPrivacyScope.customerProtected;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'localPath': localPath,
      'module': module,
      'recordId': recordId,
      'kind': kind,
      'byteSize': byteSize,
      'fileHashSha256': fileHashSha256,
      'privacyScope': privacyScope.name,
      'mimeType': mimeType,
      'displayName': displayName,
    };
  }

  static String _moduleForMediaPurpose(AppMediaAssetPurpose purpose) {
    return switch (purpose) {
      AppMediaAssetPurpose.companyLogo => 'company',
      AppMediaAssetPurpose.receiptProof => 'receipts',
      AppMediaAssetPurpose.invoiceAttachment => 'invoices',
    };
  }
}
