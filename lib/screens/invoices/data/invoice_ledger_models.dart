import '../../../shared/media/app_media_asset.dart';
import '../../../shared/pdf/app_generated_pdf_models.dart';

enum InvoiceDocumentType { invoice, estimate }

enum InvoiceNumberMode { automatic, manual }

enum InvoiceRecordStatus {
  draft,
  sent,
  approved,
  unpaid,
  partlyPaid,
  paid,
  overdue,
  voided,
  convertedToInvoice,
}

enum InvoiceDiscountType { none, amount, percent }

enum InvoiceSyncStatus { dirty, synced, conflict, pendingDelete }

const int invoicePdfDeliveryEventHistoryLimit = 50;

enum InvoicePdfDeliveryEventType {
  generated,
  previewed,
  archived,
  shared,
  sent,
  printed,
  cancelled,
  failed,
}

class InvoicePdfDeliveryEvent {
  const InvoicePdfDeliveryEvent({
    required this.id,
    required this.type,
    required this.at,
    this.pdfKind = '',
    this.sourceRecordId = '',
    this.fileName = '',
    this.byteSize = 0,
    this.fileHashSha256 = '',
    this.reasonCode = '',
  });

  factory InvoicePdfDeliveryEvent.generatedFrom(
    AppGeneratedPdfDocument document, {
    DateTime? at,
    String fileHashSha256 = '',
  }) {
    final happenedAt = at ?? document.createdAt;
    return InvoicePdfDeliveryEvent(
      id: _pdfEventId(
        InvoicePdfDeliveryEventType.generated,
        happenedAt,
        document.sourceRecordId,
      ),
      type: InvoicePdfDeliveryEventType.generated,
      at: happenedAt,
      pdfKind: document.kind.name,
      sourceRecordId: _safeEventText(document.sourceRecordId, maxLength: 80),
      fileName: AppGeneratedPdfFileName.clean(document.safeFileName),
      byteSize: document.byteSize,
      fileHashSha256: _safeHash(fileHashSha256),
    );
  }

  factory InvoicePdfDeliveryEvent.previewed(
    AppGeneratedPdfDocument document, {
    DateTime? at,
  }) {
    final happenedAt = at ?? DateTime.now();
    return InvoicePdfDeliveryEvent(
      id: _pdfEventId(
        InvoicePdfDeliveryEventType.previewed,
        happenedAt,
        document.sourceRecordId,
      ),
      type: InvoicePdfDeliveryEventType.previewed,
      at: happenedAt,
      pdfKind: document.kind.name,
      sourceRecordId: _safeEventText(document.sourceRecordId, maxLength: 80),
      fileName: AppGeneratedPdfFileName.clean(document.safeFileName),
      byteSize: document.byteSize,
    );
  }

  factory InvoicePdfDeliveryEvent.archived({
    required String sourceRecordId,
    required String pdfKind,
    required String fileName,
    required int byteSize,
    required String fileHashSha256,
    DateTime? at,
  }) {
    final happenedAt = at ?? DateTime.now();
    return InvoicePdfDeliveryEvent(
      id: _pdfEventId(
        InvoicePdfDeliveryEventType.archived,
        happenedAt,
        sourceRecordId,
      ),
      type: InvoicePdfDeliveryEventType.archived,
      at: happenedAt,
      pdfKind: _safeEventText(pdfKind, maxLength: 40),
      sourceRecordId: _safeEventText(sourceRecordId, maxLength: 80),
      fileName: AppGeneratedPdfFileName.clean(fileName),
      byteSize: byteSize < 0 ? 0 : byteSize,
      fileHashSha256: _safeHash(fileHashSha256),
    );
  }

  factory InvoicePdfDeliveryEvent.action({
    required InvoicePdfDeliveryEventType type,
    required String sourceRecordId,
    required String pdfKind,
    String fileName = '',
    int byteSize = 0,
    DateTime? at,
  }) {
    assert(
      type != InvoicePdfDeliveryEventType.failed,
      'Use InvoicePdfDeliveryEvent.failed for failure events.',
    );
    final happenedAt = at ?? DateTime.now();
    return InvoicePdfDeliveryEvent(
      id: _pdfEventId(type, happenedAt, sourceRecordId),
      type: type,
      at: happenedAt,
      pdfKind: _safeEventText(pdfKind, maxLength: 40),
      sourceRecordId: _safeEventText(sourceRecordId, maxLength: 80),
      fileName: fileName.trim().isEmpty
          ? ''
          : AppGeneratedPdfFileName.clean(fileName),
      byteSize: byteSize < 0 ? 0 : byteSize,
    );
  }

  factory InvoicePdfDeliveryEvent.failed({
    required String sourceRecordId,
    required String pdfKind,
    required String reasonCode,
    String fileName = '',
    DateTime? at,
  }) {
    final happenedAt = at ?? DateTime.now();
    return InvoicePdfDeliveryEvent(
      id: _pdfEventId(
        InvoicePdfDeliveryEventType.failed,
        happenedAt,
        sourceRecordId,
      ),
      type: InvoicePdfDeliveryEventType.failed,
      at: happenedAt,
      pdfKind: _safeEventText(pdfKind, maxLength: 40),
      sourceRecordId: _safeEventText(sourceRecordId, maxLength: 80),
      fileName: fileName.trim().isEmpty
          ? ''
          : AppGeneratedPdfFileName.clean(fileName),
      reasonCode: _safeEventText(reasonCode, maxLength: 80),
    );
  }

  factory InvoicePdfDeliveryEvent.cancelled({
    required String sourceRecordId,
    required String pdfKind,
    required String reasonCode,
    String fileName = '',
    int byteSize = 0,
    DateTime? at,
  }) {
    final happenedAt = at ?? DateTime.now();
    return InvoicePdfDeliveryEvent(
      id: _pdfEventId(
        InvoicePdfDeliveryEventType.cancelled,
        happenedAt,
        sourceRecordId,
      ),
      type: InvoicePdfDeliveryEventType.cancelled,
      at: happenedAt,
      pdfKind: _safeEventText(pdfKind, maxLength: 40),
      sourceRecordId: _safeEventText(sourceRecordId, maxLength: 80),
      fileName: fileName.trim().isEmpty
          ? ''
          : AppGeneratedPdfFileName.clean(fileName),
      byteSize: byteSize < 0 ? 0 : byteSize,
      reasonCode: _safeEventText(reasonCode, maxLength: 80),
    );
  }

  factory InvoicePdfDeliveryEvent.fromMap(Map<dynamic, dynamic> map) {
    return InvoicePdfDeliveryEvent(
      id: map['id'] as String? ?? '',
      type: _enumByName(
        InvoicePdfDeliveryEventType.values,
        map['type'],
        InvoicePdfDeliveryEventType.generated,
      ),
      at: _dateValue(map['at']) ?? DateTime.now(),
      pdfKind: map['pdfKind'] as String? ?? '',
      sourceRecordId: map['sourceRecordId'] as String? ?? '',
      fileName: map['fileName'] as String? ?? '',
      byteSize: _intValue(map['byteSize']),
      fileHashSha256: map['fileHashSha256'] as String? ?? '',
      reasonCode: map['reasonCode'] as String? ?? '',
    );
  }

  final String id;
  final InvoicePdfDeliveryEventType type;
  final DateTime at;
  final String pdfKind;
  final String sourceRecordId;
  final String fileName;
  final int byteSize;
  final String fileHashSha256;
  final String reasonCode;

  bool get hasFileHash => fileHashSha256.trim().isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'at': at.toIso8601String(),
      'pdfKind': pdfKind,
      'sourceRecordId': sourceRecordId,
      'fileName': fileName,
      'byteSize': byteSize,
      'fileHashSha256': fileHashSha256,
      'reasonCode': reasonCode,
    };
  }
}

class InvoiceNumberSettings {
  const InvoiceNumberSettings({
    this.mode = InvoiceNumberMode.automatic,
    this.invoicePrefix = 'INV',
    this.estimatePrefix = 'EST',
    this.nextInvoiceNumber = 1,
    this.nextEstimateNumber = 1,
    this.padding = 4,
  });

  factory InvoiceNumberSettings.fromMap(Map<dynamic, dynamic> map) {
    return InvoiceNumberSettings(
      mode: _enumByName(
        InvoiceNumberMode.values,
        map['mode'],
        InvoiceNumberMode.automatic,
      ),
      invoicePrefix: map['invoicePrefix'] as String? ?? 'INV',
      estimatePrefix: map['estimatePrefix'] as String? ?? 'EST',
      nextInvoiceNumber: _intValue(map['nextInvoiceNumber'], fallback: 1),
      nextEstimateNumber: _intValue(map['nextEstimateNumber'], fallback: 1),
      padding: _intValue(map['padding'], fallback: 4),
    );
  }

  final InvoiceNumberMode mode;
  final String invoicePrefix;
  final String estimatePrefix;
  final int nextInvoiceNumber;
  final int nextEstimateNumber;
  final int padding;

  bool get usesAutomaticNumbering => mode == InvoiceNumberMode.automatic;

  String numberFor(InvoiceDocumentType type) {
    final prefix = type == InvoiceDocumentType.invoice
        ? invoicePrefix
        : estimatePrefix;
    final number = type == InvoiceDocumentType.invoice
        ? nextInvoiceNumber
        : nextEstimateNumber;
    return '$prefix-${number.toString().padLeft(padding, '0')}';
  }

  InvoiceNumberSettings advanceFor(InvoiceDocumentType type) {
    if (type == InvoiceDocumentType.invoice) {
      return copyWith(nextInvoiceNumber: nextInvoiceNumber + 1);
    }
    return copyWith(nextEstimateNumber: nextEstimateNumber + 1);
  }

  InvoiceNumberSettings copyWith({
    InvoiceNumberMode? mode,
    String? invoicePrefix,
    String? estimatePrefix,
    int? nextInvoiceNumber,
    int? nextEstimateNumber,
    int? padding,
  }) {
    return InvoiceNumberSettings(
      mode: mode ?? this.mode,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      estimatePrefix: estimatePrefix ?? this.estimatePrefix,
      nextInvoiceNumber: nextInvoiceNumber ?? this.nextInvoiceNumber,
      nextEstimateNumber: nextEstimateNumber ?? this.nextEstimateNumber,
      padding: padding ?? this.padding,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mode': mode.name,
      'invoicePrefix': invoicePrefix,
      'estimatePrefix': estimatePrefix,
      'nextInvoiceNumber': nextInvoiceNumber,
      'nextEstimateNumber': nextEstimateNumber,
      'padding': padding,
    };
  }
}

class InvoicePhoneNumber {
  const InvoicePhoneNumber({required this.type, required this.number});

  factory InvoicePhoneNumber.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) return const InvoicePhoneNumber(type: '', number: '');
    return InvoicePhoneNumber(
      type: map['type'] as String? ?? '',
      number: map['number'] as String? ?? '',
    );
  }

  final String type;
  final String number;

  bool get hasNumber => number.trim().isNotEmpty;

  String get displayLine {
    final trimmedType = type.trim();
    final trimmedNumber = number.trim();
    if (trimmedType.isEmpty) return trimmedNumber;
    return '$trimmedType: $trimmedNumber';
  }

  Map<String, dynamic> toMap() => {'type': type, 'number': number};
}

class InvoicePartySnapshot {
  const InvoicePartySnapshot({
    this.displayName = '',
    this.companyName = '',
    this.street = '',
    this.city = '',
    this.state = '',
    this.postalCode = '',
    this.phone = '',
    this.phones = const <InvoicePhoneNumber>[],
    this.email = '',
    this.website = '',
    this.notes = '',
    this.logoPath = '',
    this.logoAsset = const AppMediaAsset(
      id: '',
      path: '',
      purpose: AppMediaAssetPurpose.companyLogo,
    ),
  });

  factory InvoicePartySnapshot.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) return const InvoicePartySnapshot();
    final logoAsset = AppMediaAsset.fromMap(map['logoAsset'] as Map?);
    final legacyLogoPath = map['logoPath'] as String? ?? '';
    final legacyPhone = map['phone'] as String? ?? '';
    final phoneEntries = (map['phones'] as List? ?? const [])
        .whereType<Map>()
        .map(InvoicePhoneNumber.fromMap)
        .where((entry) => entry.hasNumber)
        .toList(growable: false);
    return InvoicePartySnapshot(
      displayName: map['displayName'] as String? ?? '',
      companyName: map['companyName'] as String? ?? '',
      street: map['street'] as String? ?? '',
      city: map['city'] as String? ?? '',
      state: map['state'] as String? ?? '',
      postalCode: map['postalCode'] as String? ?? '',
      phone: phoneEntries.isNotEmpty ? phoneEntries.first.number : legacyPhone,
      phones: phoneEntries.isNotEmpty
          ? phoneEntries
          : legacyPhone.trim().isEmpty
          ? const <InvoicePhoneNumber>[]
          : [InvoicePhoneNumber(type: 'Business', number: legacyPhone)],
      email: map['email'] as String? ?? '',
      website: map['website'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      logoPath: logoAsset.hasFile ? logoAsset.path : legacyLogoPath,
      logoAsset: logoAsset.hasFile
          ? logoAsset
          : legacyLogoPath.trim().isEmpty
          ? AppMediaAsset.empty()
          : AppMediaAsset.empty().copyWith(path: legacyLogoPath),
    );
  }

  final String displayName;
  final String companyName;
  final String street;
  final String city;
  final String state;
  final String postalCode;
  final String phone;
  final List<InvoicePhoneNumber> phones;
  final String email;
  final String website;
  final String notes;
  final String logoPath;
  final AppMediaAsset logoAsset;

  String get bestName {
    if (companyName.trim().isNotEmpty) return companyName.trim();
    return displayName.trim();
  }

  List<String> get phoneDisplayLines {
    final typedLines = phones
        .where((entry) => entry.hasNumber)
        .map((entry) => entry.displayLine)
        .where((line) => line.trim().isNotEmpty)
        .toList(growable: false);
    if (typedLines.isNotEmpty) return typedLines;
    return phone.trim().isEmpty ? const <String>[] : [phone.trim()];
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'companyName': companyName,
      'street': street,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'phone': phone,
      'phones': phones.map((entry) => entry.toMap()).toList(growable: false),
      'email': email,
      'website': website,
      'notes': notes,
      'logoPath': logoPath,
      'logoAsset': logoAsset.toMap(),
    };
  }
}

class InvoiceLineItemRecord {
  const InvoiceLineItemRecord({
    required this.id,
    required this.name,
    this.details = '',
    this.quantity = 1,
    this.unit = 'item',
    this.unitPrice = 0,
    this.taxRate = 0,
    this.taxable = true,
    this.sourceMaterialId = '',
  });

  factory InvoiceLineItemRecord.fromMap(Map<dynamic, dynamic> map) {
    return InvoiceLineItemRecord(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      details: map['details'] as String? ?? '',
      quantity: _doubleValue(map['quantity'], fallback: 1),
      unit: map['unit'] as String? ?? 'item',
      unitPrice: _doubleValue(map['unitPrice']),
      taxRate: _doubleValue(map['taxRate']),
      taxable: map['taxable'] as bool? ?? true,
      sourceMaterialId: map['sourceMaterialId'] as String? ?? '',
    );
  }

  final String id;
  final String name;
  final String details;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double taxRate;
  final bool taxable;
  final String sourceMaterialId;

  double get subtotal => _money(quantity * unitPrice);
  double get taxAmount => taxable ? _money(subtotal * taxRate / 100) : 0;
  double get total => _money(subtotal + taxAmount);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'details': details,
      'quantity': quantity,
      'unit': unit,
      'unitPrice': unitPrice,
      'taxRate': taxRate,
      'taxable': taxable,
      'sourceMaterialId': sourceMaterialId,
    };
  }
}

class InvoiceDiscountRecord {
  const InvoiceDiscountRecord({
    this.type = InvoiceDiscountType.none,
    this.value = 0,
  });

  factory InvoiceDiscountRecord.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) return const InvoiceDiscountRecord();
    return InvoiceDiscountRecord(
      type: _enumByName(
        InvoiceDiscountType.values,
        map['type'],
        InvoiceDiscountType.none,
      ),
      value: _doubleValue(map['value']),
    );
  }

  final InvoiceDiscountType type;
  final double value;

  double amountFor(double subtotal) {
    return switch (type) {
      InvoiceDiscountType.none => 0,
      InvoiceDiscountType.amount => _money(value.clamp(0, subtotal)),
      InvoiceDiscountType.percent => _money(
        subtotal * value.clamp(0, 100) / 100,
      ),
    };
  }

  Map<String, dynamic> toMap() => {'type': type.name, 'value': value};
}

class InvoicePaymentRecord {
  const InvoicePaymentRecord({
    required this.id,
    required this.amount,
    required this.paidAt,
    this.method = '',
    this.note = '',
  });

  factory InvoicePaymentRecord.fromMap(Map<dynamic, dynamic> map) {
    return InvoicePaymentRecord(
      id: map['id'] as String? ?? '',
      amount: _doubleValue(map['amount']),
      paidAt: _dateValue(map['paidAt']) ?? DateTime.now(),
      method: map['method'] as String? ?? '',
      note: map['note'] as String? ?? '',
    );
  }

  final String id;
  final double amount;
  final DateTime paidAt;
  final String method;
  final String note;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'paidAt': paidAt.toIso8601String(),
      'method': method,
      'note': note,
    };
  }
}

class InvoiceSignatureSnapshot {
  const InvoiceSignatureSnapshot({
    required this.role,
    required this.signedAt,
    this.signatureHashSha256 = '',
  });

  factory InvoiceSignatureSnapshot.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) return nullSnapshot;
    return InvoiceSignatureSnapshot(
      role: map['role'] as String? ?? '',
      signedAt: _dateValue(map['signedAt']) ?? DateTime.now(),
      signatureHashSha256: map['signatureHashSha256'] as String? ?? '',
    );
  }

  static const nullSnapshot = InvoiceSignatureSnapshot(
    role: '',
    signedAt: null,
  );

  final String role;
  final DateTime? signedAt;
  final String signatureHashSha256;

  bool get isPresent => role.trim().isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'signedAt': signedAt?.toIso8601String(),
      'signatureHashSha256': signatureHashSha256,
    };
  }
}

class InvoiceSyncMetadata {
  const InvoiceSyncMetadata({
    required this.createdAt,
    required this.updatedAt,
    this.revision = 1,
    this.syncStatus = InvoiceSyncStatus.dirty,
    this.lastSyncedAt,
    this.firebasePath = '',
    this.deletedAt,
  });

  factory InvoiceSyncMetadata.fromMap(Map<dynamic, dynamic>? map) {
    final now = DateTime.now();
    if (map == null) {
      return InvoiceSyncMetadata(createdAt: now, updatedAt: now);
    }
    return InvoiceSyncMetadata(
      createdAt: _dateValue(map['createdAt']) ?? now,
      updatedAt: _dateValue(map['updatedAt']) ?? now,
      revision: _intValue(map['revision'], fallback: 1),
      syncStatus: _enumByName(
        InvoiceSyncStatus.values,
        map['syncStatus'],
        InvoiceSyncStatus.dirty,
      ),
      lastSyncedAt: _dateValue(map['lastSyncedAt']),
      firebasePath: map['firebasePath'] as String? ?? '',
      deletedAt: _dateValue(map['deletedAt']),
    );
  }

  final DateTime createdAt;
  final DateTime updatedAt;
  final int revision;
  final InvoiceSyncStatus syncStatus;
  final DateTime? lastSyncedAt;
  final String firebasePath;
  final DateTime? deletedAt;

  bool get dirty => syncStatus != InvoiceSyncStatus.synced;

  InvoiceSyncMetadata markDirty(DateTime now) {
    return copyWith(
      updatedAt: now,
      revision: revision + 1,
      syncStatus: InvoiceSyncStatus.dirty,
      clearLastSyncedAt: true,
    );
  }

  InvoiceSyncMetadata markSynced(DateTime now, {String? firebasePath}) {
    return copyWith(
      updatedAt: updatedAt,
      syncStatus: InvoiceSyncStatus.synced,
      lastSyncedAt: now,
      firebasePath: firebasePath ?? this.firebasePath,
    );
  }

  InvoiceSyncMetadata copyWith({
    DateTime? createdAt,
    DateTime? updatedAt,
    int? revision,
    InvoiceSyncStatus? syncStatus,
    DateTime? lastSyncedAt,
    String? firebasePath,
    DateTime? deletedAt,
    bool clearLastSyncedAt = false,
  }) {
    return InvoiceSyncMetadata(
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      revision: revision ?? this.revision,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: clearLastSyncedAt
          ? null
          : lastSyncedAt ?? this.lastSyncedAt,
      firebasePath: firebasePath ?? this.firebasePath,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'revision': revision,
      'syncStatus': syncStatus.name,
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      'firebasePath': firebasePath,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }
}

T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  return values.firstWhere(
    (value) => value.name == name,
    orElse: () => fallback,
  );
}

int _intValue(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _doubleValue(Object? value, {double fallback = 0}) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

DateTime? _dateValue(Object? value) {
  if (value is DateTime) return value;
  return DateTime.tryParse(value?.toString() ?? '');
}

double _money(num value) => (value * 100).roundToDouble() / 100;

String _pdfEventId(
  InvoicePdfDeliveryEventType type,
  DateTime at,
  String sourceRecordId,
) {
  final safeSource = _safeEventText(sourceRecordId, maxLength: 40);
  final source = safeSource.isEmpty ? 'invoice' : safeSource;
  return '${type.name}_${at.microsecondsSinceEpoch}_$source';
}

String _safeEventText(String value, {required int maxLength}) {
  final cleaned = value
      .replaceAll(RegExp(r'[^A-Za-z0-9_.-]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  if (cleaned.length <= maxLength) return cleaned;
  return cleaned.substring(0, maxLength);
}

String _safeHash(String value) {
  final trimmed = value.trim().toLowerCase();
  if (RegExp(r'^[a-f0-9]{64}$').hasMatch(trimmed)) return trimmed;
  return '';
}
