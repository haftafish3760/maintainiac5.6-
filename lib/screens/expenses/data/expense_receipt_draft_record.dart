part of 'expense_ledger_models.dart';

class ExpenseReceiptDraftRecord {
  const ExpenseReceiptDraftRecord({
    required this.id,
    required this.receiptDate,
    required this.updatedAt,
    this.receiptTimeMinutes,
    this.merchantName = '',
    this.phone = '',
    this.street = '',
    this.city = '',
    this.state = '',
    this.zip = '',
    this.email = '',
    this.website = '',
    this.notes = '',
    this.hasReceiptProof = false,
    this.attachments = const [],
    this.rawOcrText = '',
    this.ocrReview = const ExpenseReceiptOcrReview(),
    this.receiptReviewFlowStarted = false,
    this.receiptReadAttemptedWithoutText = false,
    this.receiptReadHandoffProofCount = 0,
    this.receiptReadHandoffOcrSourceCount = 0,
    this.receiptReadHandoffDecision = '',
    this.receiptReadHandoffAction = '',
    this.receiptReadHandoffStage = '',
    this.receiptReadHandoffRouteResult = '',
    this.receiptReadHandoffCoverageWarning = '',
    this.receiptReviewMode = '',
    this.receiptReviewModeChangedByUser = false,
    this.enteredSubtotal,
    this.enteredTax,
    this.enteredTotal,
    this.trackMaterialsInInventory = false,
    this.odometerReading,
    this.sourceScreen = 'expenses',
    this.lines = const [],
  });

  factory ExpenseReceiptDraftRecord.fromMap(Map<dynamic, dynamic> map) {
    return ExpenseReceiptDraftRecord(
      id: _expenseString(map['id']),
      receiptDate: _expenseDateTime(map['receiptDate']) ?? DateTime.now(),
      receiptTimeMinutes: _expenseInt(map['receiptTimeMinutes']),
      merchantName: _expenseString(map['merchantName']),
      phone: _expenseString(map['phone']),
      street: _expenseString(map['street']),
      city: _expenseString(map['city']),
      state: _expenseString(map['state']),
      zip: _expenseString(map['zip']),
      email: _expenseString(map['email']),
      website: _expenseString(map['website']),
      notes: _expenseString(map['notes']),
      hasReceiptProof: _expenseBool(map['hasReceiptProof']),
      attachments:
          (map['attachments'] as List?)
              ?.whereType<Map>()
              .map(ReceiptAttachmentRecord.fromMap)
              .toList(growable: false) ??
          const [],
      rawOcrText: _expenseString(map['rawOcrText']),
      ocrReview: ExpenseReceiptOcrReview.fromMap(_expenseMap(map['ocrReview'])),
      receiptReviewFlowStarted: _expenseBool(map['receiptReviewFlowStarted']),
      receiptReadAttemptedWithoutText: _expenseBool(
        map['receiptReadAttemptedWithoutText'],
      ),
      receiptReadHandoffProofCount:
          _expenseInt(map['receiptReadHandoffProofCount']) ?? 0,
      receiptReadHandoffOcrSourceCount:
          _expenseInt(map['receiptReadHandoffOcrSourceCount']) ?? 0,
      receiptReadHandoffDecision: _expenseString(
        map['receiptReadHandoffDecision'],
      ),
      receiptReadHandoffAction: _expenseString(map['receiptReadHandoffAction']),
      receiptReadHandoffStage: _expenseString(map['receiptReadHandoffStage']),
      receiptReadHandoffRouteResult: _expenseString(
        map['receiptReadHandoffRouteResult'],
      ),
      receiptReadHandoffCoverageWarning: _expenseString(
        map['receiptReadHandoffCoverageWarning'],
      ),
      receiptReviewMode: _expenseString(map['receiptReviewMode']),
      receiptReviewModeChangedByUser: _expenseBool(
        map['receiptReviewModeChangedByUser'],
      ),
      enteredSubtotal: _expenseDouble(map['enteredSubtotal']),
      enteredTax: _expenseDouble(map['enteredTax']),
      enteredTotal: _expenseDouble(map['enteredTotal']),
      trackMaterialsInInventory: _expenseBool(map['trackMaterialsInInventory']),
      odometerReading: _expenseInt(map['odometerReading']),
      sourceScreen: _expenseString(map['sourceScreen'], fallback: 'expenses'),
      updatedAt: _expenseDateTime(map['updatedAt']) ?? DateTime.now(),
      lines:
          (map['lines'] as List?)
              ?.whereType<Map>()
              .map(ExpenseReceiptLineRecord.fromMap)
              .toList(growable: false) ??
          const [],
    );
  }

  final String id;
  final DateTime receiptDate;
  final int? receiptTimeMinutes;
  final String merchantName;
  final String phone;
  final String street;
  final String city;
  final String state;
  final String zip;
  final String email;
  final String website;
  final String notes;
  final bool hasReceiptProof;
  final List<ReceiptAttachmentRecord> attachments;
  final String rawOcrText;
  final ExpenseReceiptOcrReview ocrReview;
  final bool receiptReviewFlowStarted;
  final bool receiptReadAttemptedWithoutText;
  final int receiptReadHandoffProofCount;
  final int receiptReadHandoffOcrSourceCount;
  final String receiptReadHandoffDecision;
  final String receiptReadHandoffAction;
  final String receiptReadHandoffStage;
  final String receiptReadHandoffRouteResult;
  final String receiptReadHandoffCoverageWarning;
  final String receiptReviewMode;
  final bool receiptReviewModeChangedByUser;
  final double? enteredSubtotal;
  final double? enteredTax;
  final double? enteredTotal;
  final bool trackMaterialsInInventory;
  final int? odometerReading;
  final String sourceScreen;
  final DateTime updatedAt;
  final List<ExpenseReceiptLineRecord> lines;

  bool get hasUserContent {
    return merchantName.trim().isNotEmpty ||
        phone.trim().isNotEmpty ||
        street.trim().isNotEmpty ||
        city.trim().isNotEmpty ||
        state.trim().isNotEmpty ||
        zip.trim().isNotEmpty ||
        email.trim().isNotEmpty ||
        website.trim().isNotEmpty ||
        notes.trim().isNotEmpty ||
        hasReceiptProof ||
        attachments.isNotEmpty ||
        rawOcrText.trim().isNotEmpty ||
        receiptReviewFlowStarted ||
        receiptReadAttemptedWithoutText ||
        enteredSubtotal != null ||
        enteredTax != null ||
        enteredTotal != null ||
        odometerReading != null ||
        lines.isNotEmpty;
  }

  double get lineSubtotal => lines.fold(0, (sum, line) => sum + line.subtotal);
  double get receiptSubtotal => enteredSubtotal ?? lineSubtotal;
  double get receiptTax {
    if (enteredTax != null) return enteredTax!;
    final total = enteredTotal;
    final subtotal = enteredSubtotal;
    if (total != null && subtotal != null) {
      return total - subtotal;
    }
    return 0;
  }

  double get total => enteredTotal ?? receiptSubtotal + receiptTax;
  bool get hasReceiptAttachment => hasReceiptProof || attachments.isNotEmpty;
  String get title =>
      merchantName.trim().isEmpty ? 'Receipt draft' : merchantName;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'receiptDate': receiptDate.toIso8601String(),
      'receiptTimeMinutes': receiptTimeMinutes,
      'merchantName': merchantName,
      'phone': phone,
      'street': street,
      'city': city,
      'state': state,
      'zip': zip,
      'email': email,
      'website': website,
      'notes': notes,
      'hasReceiptProof': hasReceiptProof,
      'attachments': [for (final attachment in attachments) attachment.toMap()],
      'rawOcrText': rawOcrText,
      'ocrReview': ocrReview.toMap(),
      'receiptReviewFlowStarted': receiptReviewFlowStarted,
      'receiptReadAttemptedWithoutText': receiptReadAttemptedWithoutText,
      'receiptReadHandoffProofCount': receiptReadHandoffProofCount,
      'receiptReadHandoffOcrSourceCount': receiptReadHandoffOcrSourceCount,
      'receiptReadHandoffDecision': receiptReadHandoffDecision,
      'receiptReadHandoffAction': receiptReadHandoffAction,
      'receiptReadHandoffStage': receiptReadHandoffStage,
      'receiptReadHandoffRouteResult': receiptReadHandoffRouteResult,
      'receiptReadHandoffCoverageWarning': receiptReadHandoffCoverageWarning,
      'receiptReviewMode': receiptReviewMode,
      'receiptReviewModeChangedByUser': receiptReviewModeChangedByUser,
      'enteredSubtotal': enteredSubtotal,
      'enteredTax': enteredTax,
      'enteredTotal': enteredTotal,
      'trackMaterialsInInventory': trackMaterialsInInventory,
      'odometerReading': odometerReading,
      'sourceScreen': sourceScreen,
      'updatedAt': updatedAt.toIso8601String(),
      'lines': [for (final line in lines) line.toMap()],
    };
  }
}
