import '../../../shared/widgets/receipt_capture/receipt_capture_models.dart';
import '../../../shared/records/maintainiac_record_lifecycle.dart';
import 'expense_ledger_models.dart';

/// Converts trusted Expense backup metadata into local record candidates.
///
/// This is deliberately network-free and does not write to Hive. A restore
/// coordinator must review available storage and merge policy before persisting
/// a decoded record. Cloud proof pointers remain separate because metadata
/// restore must never pretend a proof file is already on this device.
class ExpenseCloudRestoreCodec {
  const ExpenseCloudRestoreCodec._();

  static ExpenseCloudRestoredReceipt decodeReceipt(Map<dynamic, dynamic> data) {
    if ('${data['schema']}'.trim() != 'expense_receipt_backup_v1') {
      throw const FormatException('Unsupported Expense receipt backup schema.');
    }
    final id = _text(data['id']);
    if (id.isEmpty) {
      throw const FormatException('Expense receipt backup is missing its ID.');
    }
    final receiptDate = _date(data['receiptDate']);
    if (receiptDate == null) {
      throw const FormatException(
        'Expense receipt backup is missing its receipt date.',
      );
    }
    final proofPointers = _proofPointers(data['proofs']);
    final receipt = ExpenseReceiptRecord(
      id: id,
      receiptDate: receiptDate,
      receiptTimeMinutes: _integer(data['receiptTimeMinutes']),
      merchantName: _text(data['merchantName']),
      phone: _text(data['phone']),
      street: _text(data['street']),
      city: _text(data['city']),
      state: _text(data['state']),
      zip: _text(data['zip']),
      email: _text(data['email']),
      website: _text(data['website']),
      notes: _text(data['notes']),
      receiptNumber: _text(data['receiptNumber']),
      paymentMethod: _text(data['paymentMethod']),
      hasReceiptProof:
          _boolean(data['hasReceiptProof']) || proofPointers.isNotEmpty,
      enteredSubtotal: _cents(data['enteredSubtotalCents']),
      enteredTax: _cents(data['enteredTaxCents']),
      enteredTotal: _cents(data['enteredTotalCents']),
      trackMaterialsInInventory: _boolean(data['trackMaterialsInInventory']),
      vehicleId: _nullableText(data['vehicleId']),
      workProfileId: _nullableText(data['workProfileId']),
      odometerReading: _integer(data['odometerReading']),
      sourceScreen: _text(data['sourceScreen'], fallback: 'expenses'),
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
      localRevision: _integer(data['localRevision']) ?? 1,
      recordState: MaintainiacRecordState.fromName(_text(data['recordState'])),
      deletedAt: _date(data['deletedAt']),
      auditEvents: _auditEvents(data['auditEvents']),
      fileHashSha256: _text(data['fileHashSha256']),
      duplicateCheckStatus: ExpenseDuplicateCheckStatus.fromName(
        _text(data['duplicateCheckStatus']),
      ),
      duplicateOverride: _boolean(data['duplicateOverride']),
      duplicateOverrideReason: _text(data['duplicateOverrideReason']),
      duplicateCheckedAt: _date(data['duplicateCheckedAt']),
      ocrReview: ExpenseReceiptOcrReview.fromMap(_map(data['ocrReview'])),
      lines: _lines(data['lines']),
    );
    return ExpenseCloudRestoredReceipt(
      receipt: receipt,
      proofPointers: proofPointers,
    );
  }

  static List<ExpenseReceiptLineRecord> _lines(Object? value) {
    if (value is! List) return const [];
    return List.unmodifiable([
      for (final item in value)
        if (item is Map)
          ExpenseReceiptLineRecord.fromMap({
            ...item,
            'subtotal': _cents(item['subtotalCents']) ?? 0,
            'unitPrice': _cents(item['unitPriceCents']),
            'rawReceiptText': '',
          }),
    ]);
  }

  static List<ExpenseCloudProofPointer> _proofPointers(Object? value) {
    if (value is! List) return const [];
    return List.unmodifiable([
      for (final item in value)
        if (item is Map && _text(item['id']).isNotEmpty)
          ExpenseCloudProofPointer(
            id: _text(item['id']),
            storagePath: _text(item['storagePath']),
            kind: ReceiptAttachmentKind.fromName(_text(item['kind'])),
            mimeType: _text(item['mimeType']),
            byteSize: _integer(item['backupByteSize'] ?? item['byteSize']),
            fileHashSha256: _text(item['fileHashSha256']),
            dataSaverLevel: ReceiptDataSaverLevel.fromName(
              _text(item['dataSaverLevel']),
            ),
          ),
    ]);
  }

  static List<String> _auditEvents(Object? value) {
    if (value is! List) return const [];
    return List.unmodifiable([
      for (final item in value)
        if (item is Map)
          if (_date(item['occurredAt']) != null &&
              _text(item['action']).isNotEmpty &&
              _text(item['recordId']).isNotEmpty)
            '${_date(item['occurredAt'])!.toUtc().toIso8601String()} '
                '${_text(item['action'])} receipt ${_text(item['recordId'])}',
    ]);
  }

  static Map<dynamic, dynamic> _map(Object? value) =>
      value is Map ? value : const {};

  static String _text(Object? value, {String fallback = ''}) {
    final result = '${value ?? ''}'.trim();
    return result.isEmpty ? fallback : result;
  }

  static String? _nullableText(Object? value) {
    final result = _text(value);
    return result.isEmpty ? null : result;
  }

  static DateTime? _date(Object? value) =>
      DateTime.tryParse(_text(value))?.toUtc();

  static int? _integer(Object? value) {
    if (value is num) return value.isFinite ? value.round() : null;
    return int.tryParse(_text(value));
  }

  static double? _cents(Object? value) {
    if (value is! num || !value.isFinite) return null;
    return value.toDouble() / 100;
  }

  static bool _boolean(Object? value) => value == true || value == 'true';
}

class ExpenseCloudRestoredReceipt {
  const ExpenseCloudRestoredReceipt({
    required this.receipt,
    required this.proofPointers,
  });

  final ExpenseReceiptRecord receipt;
  final List<ExpenseCloudProofPointer> proofPointers;
}

/// Storage facts for a user-authorized restore choice.
///
/// The estimate intentionally separates structured records from proof files:
/// records-only restores do not require downloading proof bytes, while a full
/// restore can disclose the known proof-file total before it starts.
class ExpenseCloudRestoreEstimate {
  const ExpenseCloudRestoreEstimate({
    required this.recordCount,
    required this.proofCount,
    required this.knownProofBytes,
    required this.proofsWithUnknownSize,
  });

  factory ExpenseCloudRestoreEstimate.fromReceipts(
    Iterable<ExpenseCloudRestoredReceipt> receipts,
  ) {
    var recordCount = 0;
    var proofCount = 0;
    var knownProofBytes = 0;
    var proofsWithUnknownSize = 0;
    for (final receipt in receipts) {
      recordCount += 1;
      for (final proof in receipt.proofPointers) {
        proofCount += 1;
        final byteSize = proof.byteSize;
        if (byteSize == null || byteSize < 0) {
          proofsWithUnknownSize += 1;
        } else {
          knownProofBytes += byteSize;
        }
      }
    }
    return ExpenseCloudRestoreEstimate(
      recordCount: recordCount,
      proofCount: proofCount,
      knownProofBytes: knownProofBytes,
      proofsWithUnknownSize: proofsWithUnknownSize,
    );
  }

  final int recordCount;
  final int proofCount;
  final int knownProofBytes;
  final int proofsWithUnknownSize;

  bool get hasCompleteProofByteEstimate => proofsWithUnknownSize == 0;
}

class ExpenseCloudProofPointer {
  const ExpenseCloudProofPointer({
    required this.id,
    required this.storagePath,
    required this.kind,
    required this.mimeType,
    required this.byteSize,
    required this.fileHashSha256,
    required this.dataSaverLevel,
  });

  final String id;
  final String storagePath;
  final ReceiptAttachmentKind kind;
  final String mimeType;
  final int? byteSize;
  final String fileHashSha256;
  final ReceiptDataSaverLevel dataSaverLevel;
}
