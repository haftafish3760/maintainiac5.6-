part of 'receipt_capture_models.dart';

enum ReceiptPdfPageCountStatus {
  verified('Verified'),
  estimated('Estimated'),
  unknown('Unknown'),
  failed('Failed');

  const ReceiptPdfPageCountStatus(this.label);

  final String label;

  static ReceiptPdfPageCountStatus fromName(String? name) {
    final normalized = name?.trim();
    return ReceiptPdfPageCountStatus.values.firstWhere(
      (value) => value.name == normalized,
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
    final normalized = name?.trim();
    return ReceiptPdfValidationStatus.values.firstWhere(
      (value) => value.name == normalized,
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
    final normalized = name?.trim();
    return ReceiptAttachmentStorageState.values.firstWhere(
      (value) => value.name == normalized,
      orElse: () => ReceiptAttachmentStorageState.permanent,
    );
  }
}

enum ReceiptAttachmentReadState {
  notRead('Saved proof only'),
  readIntoForm('Ready for receipt review'),
  unreadable('Saved, not readable');

  const ReceiptAttachmentReadState(this.label);

  final String label;

  static ReceiptAttachmentReadState fromName(String? name) {
    final normalized = name?.trim();
    return ReceiptAttachmentReadState.values.firstWhere(
      (value) => value.name == normalized,
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
    final normalized = name?.trim();
    return ReceiptAttachmentKind.values.firstWhere(
      (value) => value.name == normalized,
      orElse: () => ReceiptAttachmentKind.photo,
    );
  }
}

enum ReceiptDataSaverLevel {
  original('Original', 'Local only', 'Keep the full source file locally.'),
  light(
    'High Quality',
    '500-700 KB',
    'Larger saved proof image for easier review.',
  ),
  balanced(
    'Normal',
    '200-300 KB',
    'Everyday black-and-white saved proof image.',
  ),
  strong(
    'Low Storage',
    '100-150 KB',
    'Smaller saved proof image with extra contrast.',
  ),
  maximum(
    'Tiny Proof',
    '40-100 KB',
    'Smallest saved proof image. Review first.',
  );

  const ReceiptDataSaverLevel(this.label, this.shortLabel, this.description);

  final String label;
  final String shortLabel;
  final String description;

  bool get usesGrayscale =>
      this == ReceiptDataSaverLevel.balanced ||
      this == ReceiptDataSaverLevel.strong ||
      this == ReceiptDataSaverLevel.maximum;

  static ReceiptDataSaverLevel fromName(String? name) {
    final normalized = name?.trim();
    return ReceiptDataSaverLevel.values.firstWhere(
      (value) => value.name == normalized,
      orElse: () => ReceiptDataSaverLevel.balanced,
    );
  }
}

class ReceiptProofTargetSizePolicy {
  const ReceiptProofTargetSizePolicy({
    required this.level,
    required this.policyCode,
    required this.minBytes,
    required this.targetBytes,
    required this.maxBytes,
    required this.cloudBackupDefaultAllowed,
    required this.keepsOriginalLocalOnly,
    required this.requiresReadabilityReview,
    required this.userFacingSummary,
  });

  factory ReceiptProofTargetSizePolicy.forLevel(ReceiptDataSaverLevel level) {
    return switch (level) {
      ReceiptDataSaverLevel.original => const ReceiptProofTargetSizePolicy(
        level: ReceiptDataSaverLevel.original,
        policyCode: 'original_local_only_not_cloud_default',
        minBytes: 0,
        targetBytes: 0,
        maxBytes: 0,
        cloudBackupDefaultAllowed: false,
        keepsOriginalLocalOnly: true,
        requiresReadabilityReview: false,
        userFacingSummary:
            'Original receipt photos stay local only unless the user explicitly keeps them. Cloud backup should use a proof copy.',
      ),
      ReceiptDataSaverLevel.light => const ReceiptProofTargetSizePolicy(
        level: ReceiptDataSaverLevel.light,
        policyCode: 'high_quality_proof_500_700kb',
        minBytes: 500 * 1024,
        targetBytes: 600 * 1024,
        maxBytes: 700 * 1024,
        cloudBackupDefaultAllowed: true,
        keepsOriginalLocalOnly: false,
        requiresReadabilityReview: false,
        userFacingSummary:
            'High quality proof keeps receipt text easy to inspect while staying far smaller than the camera original.',
      ),
      ReceiptDataSaverLevel.balanced => const ReceiptProofTargetSizePolicy(
        level: ReceiptDataSaverLevel.balanced,
        policyCode: 'normal_proof_200_300kb',
        minBytes: 200 * 1024,
        targetBytes: 250 * 1024,
        maxBytes: 300 * 1024,
        cloudBackupDefaultAllowed: true,
        keepsOriginalLocalOnly: false,
        requiresReadabilityReview: false,
        userFacingSummary:
            'Normal proof is the default receipt backup size: readable, black-and-white when useful, and storage-conscious.',
      ),
      ReceiptDataSaverLevel.strong => const ReceiptProofTargetSizePolicy(
        level: ReceiptDataSaverLevel.strong,
        policyCode: 'low_storage_proof_100_150kb',
        minBytes: 100 * 1024,
        targetBytes: 125 * 1024,
        maxBytes: 150 * 1024,
        cloudBackupDefaultAllowed: true,
        keepsOriginalLocalOnly: false,
        requiresReadabilityReview: true,
        userFacingSummary:
            'Low-storage proof saves more phone and backup space. Review readability before relying on it.',
      ),
      ReceiptDataSaverLevel.maximum => const ReceiptProofTargetSizePolicy(
        level: ReceiptDataSaverLevel.maximum,
        policyCode: 'tiny_proof_40_100kb',
        minBytes: 40 * 1024,
        targetBytes: 80 * 1024,
        maxBytes: 100 * 1024,
        cloudBackupDefaultAllowed: true,
        keepsOriginalLocalOnly: false,
        requiresReadabilityReview: true,
        userFacingSummary:
            'Tiny proof is for severe storage pressure. It should be reviewed before backup because fine text may be harder to inspect.',
      ),
    };
  }

  final ReceiptDataSaverLevel level;
  final String policyCode;
  final int minBytes;
  final int targetBytes;
  final int maxBytes;
  final bool cloudBackupDefaultAllowed;
  final bool keepsOriginalLocalOnly;
  final bool requiresReadabilityReview;
  final String userFacingSummary;

  String get rangeLabel {
    if (keepsOriginalLocalOnly) return 'Local original only';
    return '${ReceiptStorageFormatter.formatBytes(minBytes)}-${ReceiptStorageFormatter.formatBytes(maxBytes)}';
  }

  String get targetLabel => keepsOriginalLocalOnly
      ? 'Local original only'
      : ReceiptStorageFormatter.formatBytes(targetBytes);

  Map<String, Object?> toPrivacySafeDiagnostics() {
    return {
      'receiptProofTargetLevel': level.name,
      'receiptProofTargetPolicyCode': policyCode,
      'receiptProofTargetMinBytes': minBytes,
      'receiptProofTargetBytes': targetBytes,
      'receiptProofTargetMaxBytes': maxBytes,
      'receiptProofCloudBackupDefaultAllowed': cloudBackupDefaultAllowed,
      'receiptProofOriginalLocalOnly': keepsOriginalLocalOnly,
      'receiptProofReadabilityReviewRequired': requiresReadabilityReview,
      'receiptProofTargetRangeLabel': rangeLabel,
      'receiptProofTargetSummary': userFacingSummary,
    };
  }
}

extension ReceiptDataSaverLevelProofPolicy on ReceiptDataSaverLevel {
  ReceiptProofTargetSizePolicy get proofTargetSizePolicy {
    return ReceiptProofTargetSizePolicy.forLevel(this);
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
