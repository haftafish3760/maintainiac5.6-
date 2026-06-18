part of 'expense_ledger_models.dart';

enum ExpenseDuplicateCheckStatus {
  notChecked('Not checked'),
  clear('Clear'),
  candidatesFound('Needs review'),
  overrideSaved('Override saved');

  const ExpenseDuplicateCheckStatus(this.label);

  final String label;

  static ExpenseDuplicateCheckStatus fromName(String? name) {
    return ExpenseDuplicateCheckStatus.values.firstWhere(
      (value) => value.name == name,
      orElse: () => ExpenseDuplicateCheckStatus.notChecked,
    );
  }
}

enum ExpenseDuplicateConfidence {
  exactFileMatch(1, 'Exact file match'),
  veryHigh(.96, 'Very high'),
  high(.86, 'High'),
  possible(.62, 'Possible');

  const ExpenseDuplicateConfidence(this.score, this.label);

  final double score;
  final String label;

  int get percent => (score * 100).round();

  static ExpenseDuplicateConfidence fromName(String? name) {
    return ExpenseDuplicateConfidence.values.firstWhere(
      (value) => value.name == name,
      orElse: () => ExpenseDuplicateConfidence.possible,
    );
  }
}

enum ExpenseDuplicateSaveAction {
  viewExisting,
  editCurrent,
  saveAnyway,
  cancel,
}

enum ExpenseDuplicateAttachmentScope { currentForm, expenses, allModulesFuture }

class ExpenseDuplicateSaveChoice {
  const ExpenseDuplicateSaveChoice({
    required this.action,
    this.overrideReason = '',
  });

  final ExpenseDuplicateSaveAction action;
  final String overrideReason;

  bool get shouldViewExistingFirst =>
      action == ExpenseDuplicateSaveAction.viewExisting;

  bool get shouldKeepEditingCurrent =>
      action == ExpenseDuplicateSaveAction.cancel ||
      action == ExpenseDuplicateSaveAction.editCurrent;

  bool get shouldSaveAnyway => action == ExpenseDuplicateSaveAction.saveAnyway;
}

class ExpenseReceiptDuplicateCheckResult {
  const ExpenseReceiptDuplicateCheckResult({
    required this.checkedAt,
    required this.status,
    required this.fileHashSha256,
    required this.candidates,
  });

  final DateTime checkedAt;
  final ExpenseDuplicateCheckStatus status;
  final String fileHashSha256;
  final List<ExpenseReceiptDuplicateCandidate> candidates;

  bool get hasCandidates => candidates.isNotEmpty;
}

class ExpenseAttachmentDuplicateCandidate {
  const ExpenseAttachmentDuplicateCandidate({
    required this.attachmentId,
    required this.fileHashSha256,
    required this.reason,
    this.receiptId = '',
    this.linkedModule = '',
    this.linkedRecordId = '',
    this.originalFileName = '',
    this.sourceLabel = '',
    this.byteSize,
    this.createdAt,
  });

  factory ExpenseAttachmentDuplicateCandidate.fromAttachment({
    required ReceiptAttachmentRecord attachment,
    required String reason,
    String receiptId = '',
  }) {
    return ExpenseAttachmentDuplicateCandidate(
      attachmentId: attachment.id,
      receiptId: receiptId,
      linkedModule: attachment.linkedModule,
      linkedRecordId: attachment.linkedRecordId,
      fileHashSha256: attachment.fileHash,
      originalFileName: attachment.originalFileName,
      sourceLabel: attachment.sourceLabel,
      byteSize: attachment.byteSize,
      createdAt: attachment.createdAt,
      reason: reason,
    );
  }

  final String attachmentId;
  final String receiptId;
  final String linkedModule;
  final String linkedRecordId;
  final String fileHashSha256;
  final String originalFileName;
  final String sourceLabel;
  final int? byteSize;
  final DateTime? createdAt;
  final String reason;
}

class ExpenseReceiptDuplicateCandidate {
  const ExpenseReceiptDuplicateCandidate({
    required this.receiptId,
    required this.merchantName,
    required this.receiptDate,
    required this.total,
    required this.tax,
    required this.category,
    required this.vehicleId,
    required this.confidence,
    required this.reason,
    this.matchedFileHashSha256 = '',
    this.receipt,
  });

  factory ExpenseReceiptDuplicateCandidate.fromReceipt({
    required ExpenseReceiptRecord receipt,
    required ExpenseDuplicateConfidence confidence,
    required String reason,
    String matchedFileHashSha256 = '',
  }) {
    return ExpenseReceiptDuplicateCandidate(
      receiptId: receipt.id,
      merchantName: receipt.title,
      receiptDate: receipt.receiptDate,
      total: receipt.total,
      tax: receipt.receiptTax,
      category: receipt.primaryCategoryLabel,
      vehicleId: receipt.vehicleId ?? '',
      confidence: confidence,
      reason: reason,
      matchedFileHashSha256: matchedFileHashSha256,
      receipt: receipt,
    );
  }

  factory ExpenseReceiptDuplicateCandidate.fromMap(Map<dynamic, dynamic> map) {
    return ExpenseReceiptDuplicateCandidate(
      receiptId: map['receiptId'] as String? ?? '',
      merchantName: map['merchantName'] as String? ?? '',
      receiptDate:
          DateTime.tryParse(map['receiptDate'] as String? ?? '') ??
          DateTime.now(),
      total: (map['total'] as num?)?.toDouble() ?? 0,
      tax: (map['tax'] as num?)?.toDouble() ?? 0,
      category: map['category'] as String? ?? '',
      vehicleId: map['vehicleId'] as String? ?? '',
      confidence: ExpenseDuplicateConfidence.fromName(
        map['confidence'] as String?,
      ),
      reason: map['reason'] as String? ?? '',
      matchedFileHashSha256: map['matchedFileHashSha256'] as String? ?? '',
    );
  }

  final String receiptId;
  final String merchantName;
  final DateTime receiptDate;
  final double total;
  final double tax;
  final String category;
  final String vehicleId;
  final ExpenseDuplicateConfidence confidence;
  final String reason;
  final String matchedFileHashSha256;
  final ExpenseReceiptRecord? receipt;

  bool get isExactProofMatch =>
      confidence == ExpenseDuplicateConfidence.exactFileMatch;

  Map<String, dynamic> toMap() {
    return {
      'receiptId': receiptId,
      'merchantName': merchantName,
      'receiptDate': receiptDate.toIso8601String(),
      'total': total,
      'tax': tax,
      'category': category,
      'vehicleId': vehicleId,
      'confidence': confidence.name,
      'reason': reason,
      'matchedFileHashSha256': matchedFileHashSha256,
    };
  }
}
