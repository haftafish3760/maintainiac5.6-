class ReceiptPhotoReviewResult {
  const ReceiptPhotoReviewResult({
    required this.photoPaths,
    required this.ocrSourcePhotoPaths,
    required this.dataSaverLevel,
  });

  final List<String> photoPaths;
  final List<String> ocrSourcePhotoPaths;
  final ReceiptDataSaverLevel dataSaverLevel;
}

enum ReceiptCameraCaptureMode { singleImage, bestShotCandidates }

class ReceiptCameraResult {
  const ReceiptCameraResult({
    required this.photoPaths,
    required this.mode,
    this.qualityChecks = const [],
  });

  const ReceiptCameraResult.single(
    List<String> photoPaths, {
    List<ReceiptPhotoQualityCheck> qualityChecks = const [],
  }) : this(
         photoPaths: photoPaths,
         mode: ReceiptCameraCaptureMode.singleImage,
         qualityChecks: qualityChecks,
       );

  const ReceiptCameraResult.bestShotCandidates(
    List<String> photoPaths, {
    List<ReceiptPhotoQualityCheck> qualityChecks = const [],
  }) : this(
         photoPaths: photoPaths,
         mode: ReceiptCameraCaptureMode.bestShotCandidates,
         qualityChecks: qualityChecks,
       );

  final List<String> photoPaths;
  final ReceiptCameraCaptureMode mode;
  final List<ReceiptPhotoQualityCheck> qualityChecks;

  bool get isBestShotCandidateSet =>
      mode == ReceiptCameraCaptureMode.bestShotCandidates;

  ReceiptPhotoQualityCheck? qualityForIndex(int index) {
    if (index < 0 || index >= qualityChecks.length) return null;
    return qualityChecks[index];
  }
}

class ReceiptImageStoragePreview {
  const ReceiptImageStoragePreview({
    required this.originalBytes,
    required this.estimatedBytes,
    required this.level,
    required this.quality,
  });

  final int originalBytes;
  final int estimatedBytes;
  final ReceiptDataSaverLevel level;
  final ReceiptPhotoQualityCheck quality;

  int get savedBytes =>
      (originalBytes - estimatedBytes).clamp(0, originalBytes);
  double get savedPercent =>
      originalBytes <= 0 ? 0 : savedBytes / originalBytes;

  String get originalLabel =>
      ReceiptStorageFormatter.formatBytes(originalBytes);
  String get estimatedLabel =>
      ReceiptStorageFormatter.formatBytes(estimatedBytes);
  String get savedLabel => ReceiptStorageFormatter.formatBytes(savedBytes);
}

class ReceiptPhotoQualityCheck {
  const ReceiptPhotoQualityCheck({
    required this.width,
    required this.height,
    required this.focusScore,
    required this.isLikelyReadable,
  });

  final int width;
  final int height;
  final double focusScore;
  final bool isLikelyReadable;

  String get resolutionLabel => '${width}x$height';
  int get reviewScore {
    if (width <= 0 || height <= 0) return 0;
    final focusPoints = (focusScore / 18 * 70).clamp(0, 70).round();
    final shortestSide = width < height ? width : height;
    final resolutionPoints = (shortestSide / 1600 * 30).clamp(0, 30).round();
    return (focusPoints + resolutionPoints).clamp(0, 100);
  }

  String get reviewScoreLabel => '$reviewScore%';

  String get focusLabel {
    if (focusScore >= 14) return 'sharp';
    if (focusScore >= 8) return 'usable';
    return 'may be blurry';
  }
}

class ReceiptAttachmentRecord {
  const ReceiptAttachmentRecord({
    required this.id,
    required this.path,
    required this.kind,
    required this.dataSaverLevel,
    required this.createdAt,
    this.displayName = '',
    this.originalFileName = '',
    this.mimeType = '',
    this.importedText = '',
    this.byteSize,
    this.fileHash = '',
    this.pageCount,
    this.pageCountStatus = ReceiptPdfPageCountStatus.unknown,
    this.validationStatus = ReceiptPdfValidationStatus.notChecked,
    this.riskFlags = const [],
    this.documentSignals = const [],
    this.sourceLabel = '',
    this.linkedModule = '',
    this.linkedRecordId = '',
    this.isOriginalImmutable = true,
    this.storageState = ReceiptAttachmentStorageState.permanent,
    this.promotedAt,
    this.cleanedUpAt,
    this.readState = ReceiptAttachmentReadState.notRead,
  });

  factory ReceiptAttachmentRecord.fromMap(Map<dynamic, dynamic> map) {
    return ReceiptAttachmentRecord(
      id: map['id'] as String? ?? '',
      path: map['path'] as String? ?? '',
      kind: ReceiptAttachmentKind.fromName(map['kind'] as String?),
      dataSaverLevel: ReceiptDataSaverLevel.fromName(
        map['dataSaverLevel'] as String?,
      ),
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      displayName: map['displayName'] as String? ?? '',
      originalFileName: map['originalFileName'] as String? ?? '',
      mimeType: map['mimeType'] as String? ?? '',
      importedText: map['importedText'] as String? ?? '',
      byteSize: (map['byteSize'] as num?)?.toInt(),
      fileHash: map['fileHash'] as String? ?? '',
      pageCount: (map['pageCount'] as num?)?.toInt(),
      pageCountStatus: ReceiptPdfPageCountStatus.fromName(
        map['pageCountStatus'] as String?,
      ),
      validationStatus: ReceiptPdfValidationStatus.fromName(
        map['validationStatus'] as String?,
      ),
      riskFlags:
          (map['riskFlags'] as List?)?.whereType<String>().toList(
            growable: false,
          ) ??
          const [],
      documentSignals:
          (map['documentSignals'] as List?)?.whereType<String>().toList(
            growable: false,
          ) ??
          const [],
      sourceLabel: map['sourceLabel'] as String? ?? '',
      linkedModule: map['linkedModule'] as String? ?? '',
      linkedRecordId: map['linkedRecordId'] as String? ?? '',
      isOriginalImmutable: map['isOriginalImmutable'] as bool? ?? true,
      storageState: ReceiptAttachmentStorageState.fromName(
        map['storageState'] as String?,
      ),
      promotedAt: DateTime.tryParse(map['promotedAt'] as String? ?? ''),
      cleanedUpAt: DateTime.tryParse(map['cleanedUpAt'] as String? ?? ''),
      readState: ReceiptAttachmentReadState.fromName(
        map['readState'] as String?,
      ),
    );
  }

  final String id;
  final String path;
  final ReceiptAttachmentKind kind;
  final ReceiptDataSaverLevel dataSaverLevel;
  final DateTime createdAt;
  final String displayName;
  final String originalFileName;
  final String mimeType;
  final String importedText;
  final int? byteSize;
  final String fileHash;
  final int? pageCount;
  final ReceiptPdfPageCountStatus pageCountStatus;
  final ReceiptPdfValidationStatus validationStatus;
  final List<String> riskFlags;
  final List<String> documentSignals;
  final String sourceLabel;
  final String linkedModule;
  final String linkedRecordId;
  final bool isOriginalImmutable;
  final ReceiptAttachmentStorageState storageState;
  final DateTime? promotedAt;
  final DateTime? cleanedUpAt;
  final ReceiptAttachmentReadState readState;

  bool get isPhoto => kind == ReceiptAttachmentKind.photo;
  bool get isPdf => kind == ReceiptAttachmentKind.pdf;
  bool get isImportedText =>
      kind == ReceiptAttachmentKind.emailText ||
      kind == ReceiptAttachmentKind.textMessageText;
  bool get isReadOnlyProof => isOriginalImmutable && !isImportedText;
  bool get canEditProofFileInApp => false;

  String get proofAccessLabel {
    if (isImportedText) return 'editable receipt text';
    if (isPdf) return 'read-only PDF proof';
    return 'read-only receipt photo';
  }

  String get label {
    if (displayName.trim().isNotEmpty) return displayName.trim();
    return switch (kind) {
      ReceiptAttachmentKind.photo => 'Receipt photo',
      ReceiptAttachmentKind.pdf => 'Receipt PDF',
      ReceiptAttachmentKind.emailText => 'Receipt text',
      ReceiptAttachmentKind.textMessageText => 'Receipt text',
    };
  }

  ReceiptAttachmentRecord copyWith({
    String? id,
    String? path,
    ReceiptAttachmentKind? kind,
    ReceiptDataSaverLevel? dataSaverLevel,
    DateTime? createdAt,
    String? displayName,
    String? originalFileName,
    String? mimeType,
    String? importedText,
    int? byteSize,
    String? fileHash,
    int? pageCount,
    ReceiptPdfPageCountStatus? pageCountStatus,
    ReceiptPdfValidationStatus? validationStatus,
    List<String>? riskFlags,
    List<String>? documentSignals,
    String? sourceLabel,
    String? linkedModule,
    String? linkedRecordId,
    bool? isOriginalImmutable,
    ReceiptAttachmentStorageState? storageState,
    DateTime? promotedAt,
    DateTime? cleanedUpAt,
    ReceiptAttachmentReadState? readState,
  }) {
    return ReceiptAttachmentRecord(
      id: id ?? this.id,
      path: path ?? this.path,
      kind: kind ?? this.kind,
      dataSaverLevel: dataSaverLevel ?? this.dataSaverLevel,
      createdAt: createdAt ?? this.createdAt,
      displayName: displayName ?? this.displayName,
      originalFileName: originalFileName ?? this.originalFileName,
      mimeType: mimeType ?? this.mimeType,
      importedText: importedText ?? this.importedText,
      byteSize: byteSize ?? this.byteSize,
      fileHash: fileHash ?? this.fileHash,
      pageCount: pageCount ?? this.pageCount,
      pageCountStatus: pageCountStatus ?? this.pageCountStatus,
      validationStatus: validationStatus ?? this.validationStatus,
      riskFlags: riskFlags ?? this.riskFlags,
      documentSignals: documentSignals ?? this.documentSignals,
      sourceLabel: sourceLabel ?? this.sourceLabel,
      linkedModule: linkedModule ?? this.linkedModule,
      linkedRecordId: linkedRecordId ?? this.linkedRecordId,
      isOriginalImmutable: isOriginalImmutable ?? this.isOriginalImmutable,
      storageState: storageState ?? this.storageState,
      promotedAt: promotedAt ?? this.promotedAt,
      cleanedUpAt: cleanedUpAt ?? this.cleanedUpAt,
      readState: readState ?? this.readState,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'path': path,
      'kind': kind.name,
      'dataSaverLevel': dataSaverLevel.name,
      'createdAt': createdAt.toIso8601String(),
      'displayName': displayName,
      'originalFileName': originalFileName,
      'mimeType': mimeType,
      'importedText': importedText,
      'byteSize': byteSize,
      'fileHash': fileHash,
      'pageCount': pageCount,
      'pageCountStatus': pageCountStatus.name,
      'validationStatus': validationStatus.name,
      'riskFlags': riskFlags,
      'documentSignals': documentSignals,
      'sourceLabel': sourceLabel,
      'linkedModule': linkedModule,
      'linkedRecordId': linkedRecordId,
      'isOriginalImmutable': isOriginalImmutable,
      'storageState': storageState.name,
      'promotedAt': promotedAt?.toIso8601String(),
      'cleanedUpAt': cleanedUpAt?.toIso8601String(),
      'readState': readState.name,
    };
  }
}

enum ReceiptPdfPageCountStatus {
  verified('Verified'),
  estimated('Estimated'),
  unknown('Unknown'),
  failed('Failed');

  const ReceiptPdfPageCountStatus(this.label);

  final String label;

  static ReceiptPdfPageCountStatus fromName(String? name) {
    return ReceiptPdfPageCountStatus.values.firstWhere(
      (value) => value.name == name,
      orElse: () => ReceiptPdfPageCountStatus.unknown,
    );
  }
}

enum ReceiptPdfValidationStatus {
  notChecked('Not checked'),
  valid('Valid PDF'),
  missing('Missing'),
  empty('Empty'),
  invalidHeader('Invalid PDF'),
  tooLarge('Too large'),
  pageCountUnknown('Page count unknown'),
  failed('Validation failed');

  const ReceiptPdfValidationStatus(this.label);

  final String label;

  static ReceiptPdfValidationStatus fromName(String? name) {
    return ReceiptPdfValidationStatus.values.firstWhere(
      (value) => value.name == name,
      orElse: () => ReceiptPdfValidationStatus.notChecked,
    );
  }
}

enum ReceiptPdfHandlingDisposition {
  blocked('Cannot attach'),
  proofOnly('Save as proof only'),
  assistedReadReady('Can fill receipt'),
  assistedReadWithWarning('Can fill receipt with review');

  const ReceiptPdfHandlingDisposition(this.label);

  final String label;
}

enum ReceiptAttachmentStorageState {
  staged('Staged'),
  permanent('Saved proof'),
  missing('Missing'),
  cleanedUp('Cleaned up');

  const ReceiptAttachmentStorageState(this.label);

  final String label;

  static ReceiptAttachmentStorageState fromName(String? name) {
    return ReceiptAttachmentStorageState.values.firstWhere(
      (value) => value.name == name,
      orElse: () => ReceiptAttachmentStorageState.permanent,
    );
  }
}

enum ReceiptAttachmentReadState {
  notRead('Saved proof only'),
  readIntoForm('Read into form'),
  unreadable('Saved, not readable');

  const ReceiptAttachmentReadState(this.label);

  final String label;

  static ReceiptAttachmentReadState fromName(String? name) {
    return ReceiptAttachmentReadState.values.firstWhere(
      (value) => value.name == name,
      orElse: () => ReceiptAttachmentReadState.notRead,
    );
  }
}

enum ReceiptAttachmentKind {
  photo,
  pdf,
  emailText,
  textMessageText;

  static ReceiptAttachmentKind fromName(String? name) {
    return ReceiptAttachmentKind.values.firstWhere(
      (value) => value.name == name,
      orElse: () => ReceiptAttachmentKind.photo,
    );
  }
}

enum ReceiptDataSaverLevel {
  original('Level 1', 'Least saving', 'Keep the full color image.'),
  light('Level 2', 'Light', 'Smaller color copy with little visible change.'),
  balanced('Level 3', 'Balanced', 'Black-and-white receipt copy.'),
  strong(
    'Level 4',
    'Strong',
    'Smaller black-and-white copy with extra contrast.',
  ),
  maximum('Level 5', 'Maximum', 'Smallest copy. Review before saving.');

  const ReceiptDataSaverLevel(this.label, this.shortLabel, this.description);

  final String label;
  final String shortLabel;
  final String description;

  bool get usesGrayscale =>
      this == ReceiptDataSaverLevel.balanced ||
      this == ReceiptDataSaverLevel.strong ||
      this == ReceiptDataSaverLevel.maximum;

  static ReceiptDataSaverLevel fromName(String? name) {
    return ReceiptDataSaverLevel.values.firstWhere(
      (value) => value.name == name,
      orElse: () => ReceiptDataSaverLevel.balanced,
    );
  }
}

class ReceiptStorageFormatter {
  const ReceiptStorageFormatter._();

  static String formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) return '${(bytes / 1024).ceil()} KB';
    return '$bytes bytes';
  }
}
