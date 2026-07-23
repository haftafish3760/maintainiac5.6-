import '../documents/app_document_models.dart';
import '../media/app_media_asset.dart';
import '../widgets/receipt_capture/receipt_capture_models.dart';
import 'cloud_backup_pdf_policy.dart';

enum CloudBackupPrivacyScope { normal, customerProtected }

class CloudBackupManifest {
  CloudBackupManifest({
    required this.createdAt,
    required List<CloudBackupManifestEntry> entries,
  }) : entries = List.unmodifiable(entries);

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

  int get estimatedCloudBytes {
    return entries.fold(0, (sum, entry) => sum + entry.estimatedCloudBytes);
  }

  int get entryCount => entries.length;

  bool get hasEntries => entries.isNotEmpty;

  /// Cloud-safe metadata only. Device paths and user-facing filenames never
  /// cross this serialization boundary.
  Map<String, dynamic> toMap() {
    return {
      'createdAt': createdAt.toIso8601String(),
      'pendingBytes': pendingBytes,
      'estimatedCloudBytes': estimatedCloudBytes,
      'entryCount': entryCount,
      'entries': [for (final entry in entries) entry.toMap()],
    };
  }

  /// Explicit local diagnostic form. This must never be queued to Firestore.
  Map<String, dynamic> toLocalMap() => {
    ...toMap(),
    'entries': [for (final entry in entries) entry.toLocalMap()],
  };

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
    required this.estimatedCloudBytes,
    required this.fileHashSha256,
    required this.privacyScope,
    required this.cloudBackupAction,
    this.mimeType = '',
    this.displayName = '',
    this.cloudBackupReason = '',
  });

  static CloudBackupManifestEntry? fromMediaAsset(AppMediaAsset asset) {
    if (!asset.canAttemptCloudBackup ||
        !asset.hasFile ||
        !_isSha256(asset.fileHash)) {
      return null;
    }
    return CloudBackupManifestEntry(
      id: asset.id,
      localPath: asset.path,
      module: _moduleForMediaPurpose(asset.purpose),
      recordId: asset.id,
      kind: asset.purpose.name,
      byteSize: asset.byteSize ?? 0,
      estimatedCloudBytes: asset.byteSize ?? 0,
      fileHashSha256: asset.fileHash,
      privacyScope: CloudBackupPrivacyScope.normal,
      cloudBackupAction: CloudBackupFileAction.uploadAsIs,
      mimeType: asset.mimeType,
      displayName: asset.displayName,
      cloudBackupReason: 'Media asset is cloud eligible.',
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
    if (!_isSha256(hash) || byteSize <= 0 || localPath.isEmpty) return null;
    final plan = CloudBackupPdfPolicy.planAttachment(
      attachment: attachment,
      generatedPdf: document.sourceLabel == 'Generated PDF',
    );
    return CloudBackupManifestEntry(
      id: attachment.id,
      localPath: localPath,
      module: document.kind.storageModule,
      recordId: document.id,
      kind: attachment.kind.name,
      byteSize: byteSize,
      estimatedCloudBytes: plan.estimatedCloudBytes,
      fileHashSha256: hash,
      privacyScope: privacyScope,
      cloudBackupAction: plan.action,
      mimeType: attachment.mimeType,
      displayName: attachment.displayName,
      cloudBackupReason: plan.reason,
    );
  }

  final String id;
  final String localPath;
  final String module;
  final String recordId;
  final String kind;
  final int byteSize;
  final int estimatedCloudBytes;
  final String fileHashSha256;
  final CloudBackupPrivacyScope privacyScope;
  final CloudBackupFileAction cloudBackupAction;
  final String mimeType;
  final String displayName;
  final String cloudBackupReason;

  bool get isCustomerProtected =>
      privacyScope == CloudBackupPrivacyScope.customerProtected;

  factory CloudBackupManifestEntry.fromCloudMap(Map<dynamic, dynamic> map) {
    const forbidden = {'localPath', 'path', 'displayName', 'cloudBackupReason'};
    if (map.keys.whereType<String>().any(forbidden.contains)) {
      throw const FormatException('Cloud manifest contains device-only data.');
    }
    final privacy = CloudBackupPrivacyScope.values.where(
      (value) => value.name == map['privacyScope'],
    );
    final action = CloudBackupFileAction.values.where(
      (value) => value.name == map['cloudBackupAction'],
    );
    final hash = map['fileHashSha256'];
    final byteSize = map['byteSize'];
    final estimatedCloudBytes = map['estimatedCloudBytes'];
    if (privacy.length != 1 ||
        action.length != 1 ||
        hash is! String ||
        !_isSha256(hash) ||
        byteSize is! int ||
        byteSize <= 0 ||
        estimatedCloudBytes is! int ||
        estimatedCloudBytes < 0 ||
        estimatedCloudBytes > byteSize) {
      throw const FormatException('Cloud manifest entry is corrupt.');
    }
    return CloudBackupManifestEntry(
      id: _requiredCloudToken(map, 'id'),
      localPath: '',
      module: _requiredCloudToken(map, 'module'),
      recordId: _requiredCloudToken(map, 'recordId'),
      kind: _requiredCloudToken(map, 'kind'),
      byteSize: byteSize,
      estimatedCloudBytes: estimatedCloudBytes,
      fileHashSha256: hash,
      privacyScope: privacy.single,
      cloudBackupAction: action.single,
      mimeType: _optionalCloudText(map, 'mimeType', maximumLength: 160),
    );
  }

  Map<String, dynamic> toMap() {
    if (!_isSha256(fileHashSha256)) {
      throw const FormatException('Cloud manifest requires a SHA-256 hash.');
    }
    return {
      'id': id,
      'module': module,
      'recordId': recordId,
      'kind': kind,
      'byteSize': byteSize,
      'estimatedCloudBytes': estimatedCloudBytes,
      'fileHashSha256': fileHashSha256,
      'privacyScope': privacyScope.name,
      'cloudBackupAction': cloudBackupAction.name,
      'mimeType': mimeType,
    };
  }

  Map<String, dynamic> toLocalMap() => {
    ...toMap(),
    'localPath': localPath,
    'displayName': displayName,
    'cloudBackupReason': cloudBackupReason,
  };

  static String _moduleForMediaPurpose(AppMediaAssetPurpose purpose) {
    return switch (purpose) {
      AppMediaAssetPurpose.companyLogo => 'company',
      AppMediaAssetPurpose.receiptProof => 'receipts',
      AppMediaAssetPurpose.invoiceAttachment => 'invoices',
    };
  }
}

bool _isSha256(String value) => RegExp(r'^[a-f0-9]{64}$').hasMatch(value);

String _requiredCloudToken(Map<dynamic, dynamic> map, String key) {
  final value = map[key];
  if (value is! String || !RegExp(r'^[A-Za-z0-9_.-]{1,160}$').hasMatch(value)) {
    throw FormatException('Cloud manifest has invalid $key.');
  }
  return value;
}

String _optionalCloudText(
  Map<dynamic, dynamic> map,
  String key, {
  required int maximumLength,
}) {
  final value = map[key];
  if (value == null) return '';
  if (value is! String || value.length > maximumLength) {
    throw FormatException('Cloud manifest has invalid $key.');
  }
  return value;
}
