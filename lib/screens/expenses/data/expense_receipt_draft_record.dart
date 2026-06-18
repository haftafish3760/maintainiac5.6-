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
    this.enteredSubtotal,
    this.enteredTax,
    this.enteredTotal,
    this.trackMaterialsInInventory = false,
    this.sourceScreen = 'expenses',
    this.lines = const [],
  });

  factory ExpenseReceiptDraftRecord.fromMap(Map<dynamic, dynamic> map) {
    return ExpenseReceiptDraftRecord(
      id: map['id'] as String? ?? '',
      receiptDate:
          DateTime.tryParse(map['receiptDate'] as String? ?? '') ??
          DateTime.now(),
      receiptTimeMinutes: map['receiptTimeMinutes'] as int?,
      merchantName: map['merchantName'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      street: map['street'] as String? ?? '',
      city: map['city'] as String? ?? '',
      state: map['state'] as String? ?? '',
      zip: map['zip'] as String? ?? '',
      email: map['email'] as String? ?? '',
      website: map['website'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      hasReceiptProof: map['hasReceiptProof'] as bool? ?? false,
      attachments:
          (map['attachments'] as List?)
              ?.whereType<Map>()
              .map(ReceiptAttachmentRecord.fromMap)
              .toList(growable: false) ??
          const [],
      rawOcrText: map['rawOcrText'] as String? ?? '',
      enteredSubtotal: (map['enteredSubtotal'] as num?)?.toDouble(),
      enteredTax: (map['enteredTax'] as num?)?.toDouble(),
      enteredTotal: (map['enteredTotal'] as num?)?.toDouble(),
      trackMaterialsInInventory:
          map['trackMaterialsInInventory'] as bool? ?? false,
      sourceScreen: map['sourceScreen'] as String? ?? 'expenses',
      updatedAt:
          DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
          DateTime.now(),
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
  final double? enteredSubtotal;
  final double? enteredTax;
  final double? enteredTotal;
  final bool trackMaterialsInInventory;
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
        enteredSubtotal != null ||
        enteredTax != null ||
        enteredTotal != null ||
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
      'enteredSubtotal': enteredSubtotal,
      'enteredTax': enteredTax,
      'enteredTotal': enteredTotal,
      'trackMaterialsInInventory': trackMaterialsInInventory,
      'sourceScreen': sourceScreen,
      'updatedAt': updatedAt.toIso8601String(),
      'lines': [for (final line in lines) line.toMap()],
    };
  }
}
