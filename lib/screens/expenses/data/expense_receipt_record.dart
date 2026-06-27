part of 'expense_ledger_models.dart';

class ExpenseReceiptRecord {
  const ExpenseReceiptRecord({
    required this.id,
    required this.receiptDate,
    required this.lines,
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
    this.receiptNumber = '',
    this.paymentMethod = '',
    this.hasReceiptProof = false,
    this.attachments = const [],
    this.rawOcrText = '',
    this.ocrReview = const ExpenseReceiptOcrReview(),
    this.enteredSubtotal,
    this.enteredTax,
    this.enteredTotal,
    this.trackMaterialsInInventory = false,
    this.vehicleId,
    this.odometerReading,
    this.sourceScreen = 'expenses',
    this.createdAt,
    this.updatedAt,
    this.auditEvents = const [],
    this.fileHashSha256 = '',
    this.duplicateCheckStatus = ExpenseDuplicateCheckStatus.notChecked,
    this.duplicateCandidates = const [],
    this.duplicateOverride = false,
    this.duplicateOverrideReason = '',
    this.duplicateCheckedAt,
  });

  factory ExpenseReceiptRecord.fromMap(Map<dynamic, dynamic> map) {
    return ExpenseReceiptRecord(
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
      receiptNumber: _expenseString(map['receiptNumber']),
      paymentMethod: _expenseString(map['paymentMethod']),
      hasReceiptProof: _expenseBool(map['hasReceiptProof']),
      attachments:
          (map['attachments'] as List?)
              ?.whereType<Map>()
              .map(ReceiptAttachmentRecord.fromMap)
              .toList(growable: false) ??
          const [],
      rawOcrText: _expenseString(map['rawOcrText']),
      ocrReview: ExpenseReceiptOcrReview.fromMap(_expenseMap(map['ocrReview'])),
      enteredSubtotal: _expenseDouble(map['enteredSubtotal']),
      enteredTax: _expenseDouble(map['enteredTax']),
      enteredTotal: _expenseDouble(map['enteredTotal']),
      trackMaterialsInInventory: _expenseBool(map['trackMaterialsInInventory']),
      vehicleId: _expenseString(map['vehicleId']).trim().isEmpty
          ? null
          : _expenseString(map['vehicleId']),
      odometerReading: _expenseInt(map['odometerReading']),
      sourceScreen: _expenseString(map['sourceScreen'], fallback: 'expenses'),
      createdAt: _expenseDateTime(map['createdAt']),
      updatedAt: _expenseDateTime(map['updatedAt']),
      auditEvents:
          (map['auditEvents'] as List?)?.whereType<String>().toList(
            growable: false,
          ) ??
          const [],
      fileHashSha256: _expenseString(map['fileHashSha256']),
      duplicateCheckStatus: ExpenseDuplicateCheckStatus.fromName(
        _expenseString(map['duplicateCheckStatus']),
      ),
      duplicateCandidates:
          (map['duplicateCandidates'] as List?)
              ?.whereType<Map>()
              .map(ExpenseReceiptDuplicateCandidate.fromMap)
              .toList(growable: false) ??
          const [],
      duplicateOverride: _expenseBool(map['duplicateOverride']),
      duplicateOverrideReason: _expenseString(map['duplicateOverrideReason']),
      duplicateCheckedAt: _expenseDateTime(map['duplicateCheckedAt']),
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
  final String receiptNumber;
  final String paymentMethod;
  final bool hasReceiptProof;
  final List<ReceiptAttachmentRecord> attachments;
  final String rawOcrText;
  final ExpenseReceiptOcrReview ocrReview;
  final double? enteredSubtotal;
  final double? enteredTax;
  final double? enteredTotal;
  final bool trackMaterialsInInventory;
  final String? vehicleId;
  final int? odometerReading;
  final String sourceScreen;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> auditEvents;
  final String fileHashSha256;
  final ExpenseDuplicateCheckStatus duplicateCheckStatus;
  final List<ExpenseReceiptDuplicateCandidate> duplicateCandidates;
  final bool duplicateOverride;
  final String duplicateOverrideReason;
  final DateTime? duplicateCheckedAt;
  final List<ExpenseReceiptLineRecord> lines;

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

  double get total => enteredTotal ?? lineSubtotal + receiptAdjustment;
  double get receiptAdjustment =>
      (enteredTotal ?? receiptSubtotal + receiptTax) - lineSubtotal;
  double? get effectiveTaxRate {
    final subtotal = receiptSubtotal;
    if (subtotal <= 0 || receiptTax == 0) return null;
    return receiptTax / subtotal;
  }

  double get businessLineSubtotal =>
      lines.fold(0, (sum, line) => sum + line.businessAmount);
  double get personalLineSubtotal =>
      lines.fold(0, (sum, line) => sum + line.personalAmount);
  double get businessTotal =>
      businessLineSubtotal + _allocatedReceiptAdjustment(businessLineSubtotal);
  double get personalTotal =>
      personalLineSubtotal + _allocatedReceiptAdjustment(personalLineSubtotal);
  bool get hasReceiptAttachment => hasReceiptProof || attachments.isNotEmpty;
  String get title => merchantName.trim().isEmpty ? 'Receipt' : merchantName;
  String get primaryFileHashSha256 {
    final savedHash = fileHashSha256.trim();
    if (savedHash.isNotEmpty) return savedHash;
    for (final attachment in attachments) {
      final hash = attachment.fileHash.trim();
      if (hash.isNotEmpty) return hash;
    }
    return '';
  }

  String get primaryCategoryLabel {
    final categories = lines
        .map((line) => line.category.trim())
        .where((category) => category.isNotEmpty)
        .toSet();
    if (categories.isEmpty) return 'Uncategorized';
    if (categories.length == 1) return categories.single;
    return 'Mixed';
  }

  double totalForLine(ExpenseReceiptLineRecord line) {
    return line.subtotal + _allocatedReceiptAdjustment(line.subtotal);
  }

  double businessTotalForLine(ExpenseReceiptLineRecord line) {
    return line.businessAmount +
        _allocatedReceiptAdjustment(line.businessAmount);
  }

  double personalTotalForLine(ExpenseReceiptLineRecord line) {
    return line.personalAmount +
        _allocatedReceiptAdjustment(line.personalAmount);
  }

  double _allocatedReceiptAdjustment(double lineAmount) {
    final subtotal = lineSubtotal;
    if (subtotal <= 0 || receiptAdjustment == 0) return 0;
    return receiptAdjustment * (lineAmount / subtotal);
  }

  static const _unset = Object();

  DateTime get sortDate {
    final minutes = receiptTimeMinutes;
    if (minutes == null) {
      return DateTime(
        receiptDate.year,
        receiptDate.month,
        receiptDate.day,
        23,
        59,
      );
    }
    return DateTime(
      receiptDate.year,
      receiptDate.month,
      receiptDate.day,
      minutes ~/ 60,
      minutes % 60,
    );
  }

  ExpenseReceiptRecord copyWith({
    Object? receiptDate = _unset,
    Object? receiptTimeMinutes = _unset,
    Object? merchantName = _unset,
    Object? phone = _unset,
    Object? street = _unset,
    Object? city = _unset,
    Object? state = _unset,
    Object? zip = _unset,
    Object? email = _unset,
    Object? website = _unset,
    Object? notes = _unset,
    Object? receiptNumber = _unset,
    Object? paymentMethod = _unset,
    Object? hasReceiptProof = _unset,
    List<ReceiptAttachmentRecord>? attachments,
    Object? rawOcrText = _unset,
    Object? ocrReview = _unset,
    Object? enteredSubtotal = _unset,
    Object? enteredTax = _unset,
    Object? enteredTotal = _unset,
    Object? trackMaterialsInInventory = _unset,
    Object? vehicleId = _unset,
    Object? odometerReading = _unset,
    Object? sourceScreen = _unset,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? auditEvents,
    Object? fileHashSha256 = _unset,
    Object? duplicateCheckStatus = _unset,
    List<ExpenseReceiptDuplicateCandidate>? duplicateCandidates,
    Object? duplicateOverride = _unset,
    Object? duplicateOverrideReason = _unset,
    Object? duplicateCheckedAt = _unset,
    List<ExpenseReceiptLineRecord>? lines,
  }) {
    return ExpenseReceiptRecord(
      id: id,
      receiptDate: receiptDate == _unset
          ? this.receiptDate
          : receiptDate as DateTime,
      receiptTimeMinutes: receiptTimeMinutes == _unset
          ? this.receiptTimeMinutes
          : receiptTimeMinutes as int?,
      merchantName: merchantName == _unset
          ? this.merchantName
          : merchantName as String,
      phone: phone == _unset ? this.phone : phone as String,
      street: street == _unset ? this.street : street as String,
      city: city == _unset ? this.city : city as String,
      state: state == _unset ? this.state : state as String,
      zip: zip == _unset ? this.zip : zip as String,
      email: email == _unset ? this.email : email as String,
      website: website == _unset ? this.website : website as String,
      notes: notes == _unset ? this.notes : notes as String,
      receiptNumber: receiptNumber == _unset
          ? this.receiptNumber
          : receiptNumber as String,
      paymentMethod: paymentMethod == _unset
          ? this.paymentMethod
          : paymentMethod as String,
      hasReceiptProof: hasReceiptProof == _unset
          ? this.hasReceiptProof
          : hasReceiptProof as bool,
      attachments: attachments ?? this.attachments,
      rawOcrText: rawOcrText == _unset ? this.rawOcrText : rawOcrText as String,
      ocrReview: ocrReview == _unset
          ? this.ocrReview
          : ocrReview as ExpenseReceiptOcrReview,
      enteredSubtotal: enteredSubtotal == _unset
          ? this.enteredSubtotal
          : enteredSubtotal as double?,
      enteredTax: enteredTax == _unset
          ? this.enteredTax
          : enteredTax as double?,
      enteredTotal: enteredTotal == _unset
          ? this.enteredTotal
          : enteredTotal as double?,
      trackMaterialsInInventory: trackMaterialsInInventory == _unset
          ? this.trackMaterialsInInventory
          : trackMaterialsInInventory as bool,
      vehicleId: vehicleId == _unset ? this.vehicleId : vehicleId as String?,
      odometerReading: odometerReading == _unset
          ? this.odometerReading
          : odometerReading as int?,
      sourceScreen: sourceScreen == _unset
          ? this.sourceScreen
          : sourceScreen as String,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      auditEvents: auditEvents ?? this.auditEvents,
      fileHashSha256: fileHashSha256 == _unset
          ? this.fileHashSha256
          : fileHashSha256 as String,
      duplicateCheckStatus: duplicateCheckStatus == _unset
          ? this.duplicateCheckStatus
          : duplicateCheckStatus as ExpenseDuplicateCheckStatus,
      duplicateCandidates: duplicateCandidates ?? this.duplicateCandidates,
      duplicateOverride: duplicateOverride == _unset
          ? this.duplicateOverride
          : duplicateOverride as bool,
      duplicateOverrideReason: duplicateOverrideReason == _unset
          ? this.duplicateOverrideReason
          : duplicateOverrideReason as String,
      duplicateCheckedAt: duplicateCheckedAt == _unset
          ? this.duplicateCheckedAt
          : duplicateCheckedAt as DateTime?,
      lines: lines ?? this.lines,
    );
  }

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
      'receiptNumber': receiptNumber,
      'paymentMethod': paymentMethod,
      'hasReceiptProof': hasReceiptProof,
      'attachments': [for (final attachment in attachments) attachment.toMap()],
      'rawOcrText': rawOcrText,
      'ocrReview': ocrReview.toMap(),
      'enteredSubtotal': enteredSubtotal,
      'enteredTax': enteredTax,
      'enteredTotal': enteredTotal,
      'trackMaterialsInInventory': trackMaterialsInInventory,
      'vehicleId': vehicleId,
      'odometerReading': odometerReading,
      'sourceScreen': sourceScreen,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'auditEvents': auditEvents,
      'fileHashSha256': primaryFileHashSha256,
      'duplicateCheckStatus': duplicateCheckStatus.name,
      'duplicateCandidates': [
        for (final candidate in duplicateCandidates) candidate.toMap(),
      ],
      'duplicateOverride': duplicateOverride,
      'duplicateOverrideReason': duplicateOverrideReason,
      'duplicateCheckedAt': duplicateCheckedAt?.toIso8601String(),
      'lines': [for (final line in lines) line.toMap()],
    };
  }
}
