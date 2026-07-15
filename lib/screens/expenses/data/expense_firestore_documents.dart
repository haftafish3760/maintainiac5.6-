import '../../../shared/firebase/maintainiac_firestore_documents.dart';
import '../../../shared/firebase/maintainiac_firestore_schema.dart';
import '../../../shared/state/expense_settings_store.dart';
import '../../../shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'expense_ledger_models.dart';

class ExpenseFirestoreDocumentBuilder {
  const ExpenseFirestoreDocumentBuilder._();

  static MaintainiacFirestoreDocumentDraft expenseReceiptDocument({
    required String orgId,
    required String uid,
    required String deviceId,
    required ExpenseReceiptRecord receipt,
    DateTime? nowUtc,
    int localRevision = 1,
  }) {
    final exportedAt = (nowUtc ?? DateTime.now().toUtc()).toUtc();
    final createdAt = (receipt.createdAt ?? exportedAt).toUtc();
    final updatedAt = (receipt.updatedAt ?? exportedAt).toUtc();
    return MaintainiacFirestoreDocumentDraft(
      path:
          '${MaintainiacFirestoreSchema.orgCollectionPath(_pathToken(orgId), MaintainiacFirestoreSchema.orgExpenses)}/${_pathToken(receipt.id)}',
      data: Map.unmodifiable({
        'schema': 'expense_receipt_backup_v1',
        'schemaVersion': 1,
        'orgId': _pathToken(orgId),
        'id': _pathToken(receipt.id),
        'createdByUid': uid,
        'updatedByUid': uid,
        'deviceId': _token(deviceId),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': null,
        'localRevision': localRevision < 1 ? 1 : localRevision,
        'cloudRevision': 0,
        'syncStatus': 'pending',
        'sourceScreen': _token(receipt.sourceScreen, fallback: 'expenses'),
        'receiptDate': _dateOnly(receipt.receiptDate),
        'receiptTimeMinutes': receipt.receiptTimeMinutes,
        'merchantName': _readable(receipt.merchantName),
        'phone': _readable(receipt.phone),
        'street': _readable(receipt.street),
        'city': _readable(receipt.city),
        'state': _readable(receipt.state),
        'zip': _readable(receipt.zip),
        'email': _readable(receipt.email),
        'website': _readable(receipt.website),
        'notes': _readable(receipt.notes, maxLength: 1000),
        'receiptNumber': _readable(receipt.receiptNumber),
        'paymentMethod': _readable(receipt.paymentMethod),
        'vehicleId': _nullableToken(receipt.vehicleId),
        'context': _contextFor(receipt.contextSnapshot),
        'odometerReading': receipt.odometerReading,
        'trackMaterialsInInventory': receipt.trackMaterialsInInventory,
        'hasReceiptProof': receipt.hasReceiptAttachment,
        'proofCount': receipt.attachments.length,
        'proofs': [
          for (final attachment in receipt.attachments)
            _proofPointerFor(attachment),
        ],
        'enteredSubtotalCents': _moneyCents(receipt.enteredSubtotal),
        'enteredTaxCents': _moneyCents(receipt.enteredTax),
        'enteredTotalCents': _moneyCents(receipt.enteredTotal),
        'lineSubtotalCents': _moneyCents(receipt.lineSubtotal),
        'businessTotalCents': _moneyCents(receipt.businessTotal),
        'personalTotalCents': _moneyCents(receipt.personalTotal),
        'primaryCategory': _readable(receipt.primaryCategoryLabel),
        'useSummary': _useSummary(receipt),
        'lineCount': receipt.lines.length,
        'lines': [for (final line in receipt.lines.take(250)) _lineFor(line)],
        'ocrReview': _ocrReviewFor(receipt.ocrReview),
        'rawOcrStored': false,
        'auditEventCount': receipt.auditEvents.length,
        'fileHashSha256': _hashToken(receipt.primaryFileHashSha256),
        'duplicateCheckStatus': receipt.duplicateCheckStatus.name,
        'duplicateOverride': receipt.duplicateOverride,
        'duplicateCheckedAt': receipt.duplicateCheckedAt
            ?.toUtc()
            .toIso8601String(),
      }),
    );
  }

  static MaintainiacFirestoreDocumentDraft expenseSettingsDocument({
    required String orgId,
    required String uid,
    required String deviceId,
    required ExpenseSettingsController settings,
    DateTime? nowUtc,
  }) {
    final exportedAt = (nowUtc ?? DateTime.now().toUtc()).toUtc();
    return MaintainiacFirestoreDocumentDraft(
      path:
          '${MaintainiacFirestoreSchema.orgCollectionPath(_pathToken(orgId), MaintainiacFirestoreSchema.orgSettings)}/expenses_${_pathToken(uid)}',
      data: Map.unmodifiable({
        ...settings.toBackupMap(ownerUid: uid, exportedAtUtc: exportedAt),
        'orgId': _pathToken(orgId),
        'id': 'expenses_${_pathToken(uid)}',
        'createdByUid': uid,
        'updatedByUid': uid,
        'deviceId': _token(deviceId),
        'createdAt': exportedAt.toIso8601String(),
        'updatedAt': exportedAt.toIso8601String(),
        'module': 'expenses',
        'settingsScope': 'member',
        'uploadShape': 'single_settings_document',
      }),
    );
  }
}

Map<String, Object?> _lineFor(ExpenseReceiptLineRecord line) {
  return {
    'id': _pathToken(line.id),
    'description': _readable(line.description, maxLength: 240),
    'category': _readable(line.category),
    'use': line.use.name,
    'quantity': _finiteNumber(line.quantity),
    'unitsPerPackage': _finiteNumber(line.unitsPerPackage),
    'unit': _token(line.unit, fallback: 'each'),
    'subtotalCents': _moneyCents(line.subtotal),
    'businessPercent': _finiteNumber(line.businessPercent),
    'odometerReading': line.odometerReading,
    'fuelType': _nullableToken(line.fuelType),
    'fillType': _nullableToken(line.fillType),
    'unitPriceCents': _moneyCents(line.unitPrice),
    'catalogItemId': _nullableCatalogToken(line.catalogItemId),
    'catalogMatchConfidence': _finiteNumber(line.catalogMatchConfidence),
    'parserConfidence': _finiteNumber(line.parserConfidence),
    'parserReviewLabel': _nullableToken(line.parserReviewLabel),
    'parserNeedsReview': line.parserNeedsReview,
    'rawReceiptTextStored': false,
  };
}

Map<String, Object?> _contextFor(ExpenseReceiptContextSnapshot context) {
  return {
    'workProfileId': _nullableToken(context.workProfileId),
    'workProfileName': _readable(context.workProfileName, maxLength: 120),
    'vehicleId': _nullableToken(context.vehicleId),
    'vehicleLabel': _readable(context.vehicleLabel, maxLength: 120),
    'jobId': _nullableToken(context.jobId),
    'jobLabel': _readable(context.jobLabel, maxLength: 180),
  };
}

Map<String, Object?> _proofPointerFor(ReceiptAttachmentRecord attachment) {
  return {
    'id': _pathToken(attachment.id),
    'kind': attachment.kind.name,
    'mimeType': _token(attachment.mimeType, fallback: 'unknown'),
    'byteSize': attachment.byteSize,
    'backupByteSize': attachment.byteSize,
    'backupSizeBucket': _byteSizeBucket(attachment.byteSize),
    'fileHashSha256': _hashToken(attachment.fileHash),
    'pageCount': attachment.pageCount,
    'dataSaverLevel': attachment.dataSaverLevel.name,
    'storageState': attachment.storageState.name,
    'readState': attachment.readState.name,
    'photoQualityScore': attachment.photoQualityScore,
    'storagePath': _storageProofPath(attachment),
    'localPathStored': false,
    'importedTextStored': false,
  };
}

String _byteSizeBucket(int? bytes) {
  if (bytes == null || bytes <= 0) return 'unknown';
  if (bytes <= 100 * 1024) return 'tiny_under_100kb';
  if (bytes <= 300 * 1024) return 'normal_under_300kb';
  if (bytes <= 700 * 1024) return 'high_under_700kb';
  if (bytes <= 2 * 1024 * 1024) return 'large_under_2mb';
  return 'oversized_over_2mb';
}

Map<String, int> _useSummary(ExpenseReceiptRecord receipt) {
  final counts = <String, int>{};
  for (final line in receipt.lines) {
    counts[line.use.name] = (counts[line.use.name] ?? 0) + 1;
  }
  return Map.unmodifiable(counts);
}

Map<String, Object?> _ocrReviewFor(ExpenseReceiptOcrReview review) {
  final commandSummary = review.commandCenterSummary;
  return {
    'severity': _token(review.severity, fallback: 'none'),
    'source': _token(review.source, fallback: 'unknown'),
    'needsReview': review.needsReview,
    'warningCount': review.warningCount,
    'blockingWarningCount': review.blockingWarningCount,
    'partialWarningCount': review.partialWarningCount,
    'reviewWarningCount': review.reviewWarningCount,
    'warningKindCounts': review.warningKindCounts,
    'primaryWarningKind': _pathToken(review.primaryWarningKind),
    'primaryWarningLabel': _summaryText(
      review.primaryWarningLabel,
      fallback: 'none',
    ),
    'primaryWarningTargetLabel': _summaryText(
      review.primaryWarningTargetLabel,
      fallback: 'none',
    ),
    'primaryWarningTargetInstruction': _summaryText(
      review.primaryWarningTargetInstruction,
      fallback: 'none',
    ),
    'recoveryAction': _pathToken('${commandSummary['recoveryAction']}'),
    'recoveryTarget': _pathToken('${commandSummary['recoveryTarget']}'),
    'recoverySummary': _summaryText(
      '${commandSummary['primaryAction']}',
      fallback: 'none',
    ),
    'commandCenterSummary': _ocrCommandCenterSummary(review),
    'attachmentsRead': review.attachmentsRead,
    'attachmentsSkipped': review.attachmentsSkipped,
    'rawLineCount': review.rawLineCount,
    'parserLineCount': review.parserLineCount,
    'pdfPagesRequested': review.pdfPagesRequested,
    'usedLocalOcr': review.usedLocalOcr,
    'hadDuplicateOrOverlapText': review.hadDuplicateOrOverlapText,
  };
}

Map<String, Object?> _ocrCommandCenterSummary(ExpenseReceiptOcrReview review) {
  final summary = review.commandCenterSummary;
  return {
    'severity': _token('${summary['severity']}', fallback: 'none'),
    'source': _token(review.source, fallback: 'unknown'),
    'needsReview': summary['needsReview'],
    'warningCount': summary['warningCount'],
    'blockingWarningCount': summary['blockingWarningCount'],
    'partialWarningCount': summary['partialWarningCount'],
    'reviewWarningCount': summary['reviewWarningCount'],
    'attachmentsRead': summary['attachmentsRead'],
    'attachmentsSkipped': summary['attachmentsSkipped'],
    'parserLineCount': summary['parserLineCount'],
    'primaryWarningKind': _pathToken('${summary['primaryWarningKind']}'),
    'recoveryAction': _pathToken('${summary['recoveryAction']}'),
    'recoveryTarget': _pathToken('${summary['recoveryTarget']}'),
    'primaryIssue': _summaryText(
      '${summary['primaryIssue']}',
      fallback: 'none',
    ),
    'primaryAction': _summaryText(
      '${summary['primaryAction']}',
      fallback: 'none',
    ),
  };
}

String _storageProofPath(ReceiptAttachmentRecord attachment) {
  final id = _pathToken(attachment.id);
  final bucket = switch (attachment.kind) {
    ReceiptAttachmentKind.pdf => 'pdf',
    ReceiptAttachmentKind.photo => 'optimized',
    ReceiptAttachmentKind.emailText ||
    ReceiptAttachmentKind.textMessageText => 'text',
  };
  return '${MaintainiacStorageSchema.receiptProofsPrefix}/$bucket/$id';
}

String _dateOnly(DateTime value) {
  final utc = DateTime.utc(value.year, value.month, value.day);
  return utc.toIso8601String();
}

int? _moneyCents(double? value) {
  if (value == null || value.isNaN || value.isInfinite) return null;
  return (value * 100).round();
}

double? _finiteNumber(double? value) {
  if (value == null || value.isNaN || value.isInfinite) return null;
  return double.parse(value.toStringAsFixed(4));
}

String? _nullableToken(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  return _token(value);
}

String? _nullableCatalogToken(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  return value
      .trim()
      .replaceAll(RegExp(r'[^A-Za-z0-9_.:-]+'), '_')
      .replaceAll(RegExp(r'_+'), '_');
}

String _hashToken(String value) {
  return value.trim().replaceAll(RegExp(r'[^A-Fa-f0-9]+'), '').toLowerCase();
}

String _pathToken(String value) {
  final safe = value
      .trim()
      .replaceAll(RegExp(r'[^A-Za-z0-9_.-]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  return safe.isEmpty ? 'unknown' : safe;
}

String _token(String value, {String fallback = 'unknown'}) {
  final safe = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_.-]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  if (safe.isEmpty) return fallback;
  return safe.length > 80 ? safe.substring(0, 80) : safe;
}

String _summaryText(String value, {String fallback = 'unknown'}) {
  final safe = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (safe.isEmpty) return fallback;
  return safe.length > 180 ? safe.substring(0, 180) : safe;
}

String _readable(String value, {int maxLength = 240}) {
  final safe = value
      .trim()
      .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');
  if (safe.isEmpty) return '';
  return safe.length > maxLength ? safe.substring(0, maxLength) : safe;
}
