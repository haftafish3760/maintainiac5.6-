enum AppMediaAssetPurpose { companyLogo, receiptProof, invoiceAttachment }

enum AppMediaAssetBackupPolicy {
  localOnly,
  cloudEligible,
  requiresExplicitCustomerBackup,
}

class AppMediaAsset {
  const AppMediaAsset({
    required this.id,
    required this.path,
    required this.purpose,
    this.createdAt,
    this.displayName = '',
    this.originalFileName = '',
    this.mimeType = '',
    this.byteSize,
    this.fileHash = '',
    this.backupPolicy = AppMediaAssetBackupPolicy.localOnly,
    this.firebaseStoragePath = '',
    this.lastBackedUpAt,
  });

  factory AppMediaAsset.empty() {
    return const AppMediaAsset(
      id: '',
      path: '',
      purpose: AppMediaAssetPurpose.companyLogo,
    );
  }

  factory AppMediaAsset.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) return AppMediaAsset.empty();
    return AppMediaAsset(
      id: map['id'] as String? ?? '',
      path: map['path'] as String? ?? '',
      purpose: AppMediaAssetPurpose.values.firstWhere(
        (value) => value.name == _mediaAssetString(map['purpose']).trim(),
        orElse: () => AppMediaAssetPurpose.companyLogo,
      ),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? ''),
      displayName: map['displayName'] as String? ?? '',
      originalFileName: map['originalFileName'] as String? ?? '',
      mimeType: map['mimeType'] as String? ?? '',
      byteSize: _mediaAssetInt(map['byteSize']),
      fileHash: map['fileHash'] as String? ?? '',
      backupPolicy: AppMediaAssetBackupPolicy.values.firstWhere(
        (value) => value.name == _mediaAssetString(map['backupPolicy']).trim(),
        orElse: () => AppMediaAssetBackupPolicy.localOnly,
      ),
      firebaseStoragePath: map['firebaseStoragePath'] as String? ?? '',
      lastBackedUpAt: DateTime.tryParse(map['lastBackedUpAt'] as String? ?? ''),
    );
  }

  final String id;
  final String path;
  final AppMediaAssetPurpose purpose;
  final DateTime? createdAt;
  final String displayName;
  final String originalFileName;
  final String mimeType;
  final int? byteSize;
  final String fileHash;
  final AppMediaAssetBackupPolicy backupPolicy;
  final String firebaseStoragePath;
  final DateTime? lastBackedUpAt;

  bool get hasFile => path.trim().isNotEmpty;
  bool get canAttemptCloudBackup =>
      backupPolicy == AppMediaAssetBackupPolicy.cloudEligible &&
      fileHash.trim().isNotEmpty &&
      byteSize != null;

  AppMediaAsset copyWith({
    String? id,
    String? path,
    AppMediaAssetPurpose? purpose,
    DateTime? createdAt,
    String? displayName,
    String? originalFileName,
    String? mimeType,
    int? byteSize,
    String? fileHash,
    AppMediaAssetBackupPolicy? backupPolicy,
    String? firebaseStoragePath,
    DateTime? lastBackedUpAt,
  }) {
    return AppMediaAsset(
      id: id ?? this.id,
      path: path ?? this.path,
      purpose: purpose ?? this.purpose,
      createdAt: createdAt ?? this.createdAt,
      displayName: displayName ?? this.displayName,
      originalFileName: originalFileName ?? this.originalFileName,
      mimeType: mimeType ?? this.mimeType,
      byteSize: byteSize ?? this.byteSize,
      fileHash: fileHash ?? this.fileHash,
      backupPolicy: backupPolicy ?? this.backupPolicy,
      firebaseStoragePath: firebaseStoragePath ?? this.firebaseStoragePath,
      lastBackedUpAt: lastBackedUpAt ?? this.lastBackedUpAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'path': path,
      'purpose': purpose.name,
      'createdAt': createdAt?.toIso8601String(),
      'displayName': displayName,
      'originalFileName': originalFileName,
      'mimeType': mimeType,
      'byteSize': byteSize,
      'fileHash': fileHash,
      'backupPolicy': backupPolicy.name,
      'firebaseStoragePath': firebaseStoragePath,
      'lastBackedUpAt': lastBackedUpAt?.toIso8601String(),
    };
  }
}

String _mediaAssetString(dynamic value) {
  if (value is String) return value;
  if (value is num || value is bool) return value.toString();
  return '';
}

int? _mediaAssetInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.isFinite ? value.toInt() : null;
  if (value is String) return int.tryParse(value.trim().replaceAll(',', ''));
  return null;
}
