import 'work_supply_models.dart';
import 'work_supply_receipt_confidence.dart';

enum WorkSupplyInventoryIntakeSource {
  manualWithReceipt,
  manualWithoutReceipt,
  photoAssist,
  pdfImport,
}

enum WorkSupplyLineReviewStatus { confirmed, needsReview }

enum WorkSupplyInvoiceProofMode { hidden, lineOnly, fullReceipt }

enum WorkSupplyReceiptLineKind { inventory, businessExpense, personal }

class WorkSupplyReceiptProofRef {
  const WorkSupplyReceiptProofRef({
    required this.id,
    required this.kind,
    required this.uri,
    this.label = '',
    this.createdAt,
  });

  final String id;
  final String kind;
  final String uri;
  final String label;
  final DateTime? createdAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'kind': kind,
      'uri': uri,
      'label': label,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  static WorkSupplyReceiptProofRef fromMap(Map value) {
    return WorkSupplyReceiptProofRef(
      id: _string(value['id']),
      kind: _string(value['kind'], fallback: 'image'),
      uri: _string(value['uri']),
      label: _string(value['label']),
      createdAt: _date(value['createdAt']),
    );
  }
}

class WorkSupplyLineProofCrop {
  const WorkSupplyLineProofCrop({
    required this.proofId,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final String proofId;
  final double left;
  final double top;
  final double width;
  final double height;

  Map<String, Object?> toMap() {
    return {
      'proofId': proofId,
      'left': left,
      'top': top,
      'width': width,
      'height': height,
    };
  }

  static WorkSupplyLineProofCrop fromMap(Map value) {
    return WorkSupplyLineProofCrop(
      proofId: _string(value['proofId']),
      left: _double(value['left']),
      top: _double(value['top']),
      width: _double(value['width']),
      height: _double(value['height']),
    );
  }
}

class WorkSupplyInventoryReceiptLine {
  const WorkSupplyInventoryReceiptLine({
    required this.id,
    required this.item,
    required this.displayName,
    this.kind = WorkSupplyReceiptLineKind.inventory,
    this.rawReceiptText = '',
    this.expenseCategory = '',
    this.quantity = 1,
    this.unitsPerPackage = 1,
    this.purchaseType = 'each',
    this.unit = 'each',
    this.subtotal = 0,
    this.taxRate = 0,
    this.storageArea = '',
    this.storageDetail = '',
    this.inventoryRecordId = '',
    this.businessUse = 'business',
    this.businessPercent = 1,
    this.confidence = 1,
    this.reviewStatus = WorkSupplyLineReviewStatus.confirmed,
    this.invoiceProofMode = WorkSupplyInvoiceProofMode.hidden,
    this.invoiceProofCrop,
    this.note = '',
  });

  final String id;
  final WorkSupplyItem item;
  final String displayName;
  final WorkSupplyReceiptLineKind kind;
  final String rawReceiptText;
  final String expenseCategory;
  final double quantity;
  final double unitsPerPackage;
  final String purchaseType;
  final String unit;
  final double subtotal;
  final double taxRate;
  final String storageArea;
  final String storageDetail;
  final String inventoryRecordId;
  final String businessUse;
  final double businessPercent;
  final double confidence;
  final WorkSupplyLineReviewStatus reviewStatus;
  final WorkSupplyInvoiceProofMode invoiceProofMode;
  final WorkSupplyLineProofCrop? invoiceProofCrop;
  final String note;

  double get totalUnits => quantity * unitsPerPackage;
  double get taxAmount => subtotal * taxRate;
  double get totalWithTax => subtotal + taxAmount;
  double get unitCostWithTax => totalUnits <= 0 ? 0 : totalWithTax / totalUnits;
  bool get isInventory => kind == WorkSupplyReceiptLineKind.inventory;
  bool get isBusinessExpense =>
      kind == WorkSupplyReceiptLineKind.businessExpense;
  bool get isPersonal => kind == WorkSupplyReceiptLineKind.personal;
  ReceiptConfidenceLevel get confidenceLevel =>
      receiptConfidenceLevelFor(confidence);
  String get confidenceLabel => receiptConfidenceLabel(confidenceLevel);
  String get confidenceGuidance => receiptConfidenceGuidance(confidenceLevel);
  bool get needsReview =>
      reviewStatus == WorkSupplyLineReviewStatus.needsReview ||
      confidenceLevel != ReceiptConfidenceLevel.good;

  WorkSupplyInventoryReceiptLine copyWith({
    WorkSupplyItem? item,
    String? displayName,
    WorkSupplyReceiptLineKind? kind,
    String? rawReceiptText,
    String? expenseCategory,
    double? quantity,
    double? unitsPerPackage,
    String? purchaseType,
    String? unit,
    double? subtotal,
    double? taxRate,
    String? storageArea,
    String? storageDetail,
    String? inventoryRecordId,
    String? businessUse,
    double? businessPercent,
    double? confidence,
    WorkSupplyLineReviewStatus? reviewStatus,
    WorkSupplyInvoiceProofMode? invoiceProofMode,
    WorkSupplyLineProofCrop? invoiceProofCrop,
    String? note,
  }) {
    return WorkSupplyInventoryReceiptLine(
      id: id,
      item: item ?? this.item,
      displayName: displayName ?? this.displayName,
      kind: kind ?? this.kind,
      rawReceiptText: rawReceiptText ?? this.rawReceiptText,
      expenseCategory: expenseCategory ?? this.expenseCategory,
      quantity: quantity ?? this.quantity,
      unitsPerPackage: unitsPerPackage ?? this.unitsPerPackage,
      purchaseType: purchaseType ?? this.purchaseType,
      unit: unit ?? this.unit,
      subtotal: subtotal ?? this.subtotal,
      taxRate: taxRate ?? this.taxRate,
      storageArea: storageArea ?? this.storageArea,
      storageDetail: storageDetail ?? this.storageDetail,
      inventoryRecordId: inventoryRecordId ?? this.inventoryRecordId,
      businessUse: businessUse ?? this.businessUse,
      businessPercent: businessPercent ?? this.businessPercent,
      confidence: confidence ?? this.confidence,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      invoiceProofMode: invoiceProofMode ?? this.invoiceProofMode,
      invoiceProofCrop: invoiceProofCrop ?? this.invoiceProofCrop,
      note: note ?? this.note,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'item': _itemToMap(item),
      'displayName': displayName,
      'kind': kind.name,
      'rawReceiptText': rawReceiptText,
      'expenseCategory': expenseCategory,
      'quantity': quantity,
      'unitsPerPackage': unitsPerPackage,
      'purchaseType': purchaseType,
      'unit': unit,
      'subtotal': subtotal,
      'taxRate': taxRate,
      'storageArea': storageArea,
      'storageDetail': storageDetail,
      'inventoryRecordId': inventoryRecordId,
      'businessUse': businessUse,
      'businessPercent': businessPercent,
      'confidence': confidence,
      'confidenceLevel': confidenceLevel.name,
      'reviewStatus': reviewStatus.name,
      'invoiceProofMode': invoiceProofMode.name,
      'invoiceProofCrop': invoiceProofCrop?.toMap(),
      'note': note,
    };
  }

  static WorkSupplyInventoryReceiptLine fromMap(Map value) {
    return WorkSupplyInventoryReceiptLine(
      id: _string(value['id']),
      item: _itemFromMap(value['item']),
      displayName: _string(value['displayName']),
      kind: _lineKind(value['kind']),
      rawReceiptText: _string(value['rawReceiptText']),
      expenseCategory: _string(value['expenseCategory']),
      quantity: _double(value['quantity'], fallback: 1),
      unitsPerPackage: _double(value['unitsPerPackage'], fallback: 1),
      purchaseType: _string(value['purchaseType'], fallback: 'each'),
      unit: _string(value['unit'], fallback: 'each'),
      subtotal: _double(value['subtotal']),
      taxRate: _double(value['taxRate']),
      storageArea: _string(value['storageArea']),
      storageDetail: _string(value['storageDetail']),
      inventoryRecordId: _string(value['inventoryRecordId']),
      businessUse: _string(value['businessUse'], fallback: 'business'),
      businessPercent: _double(value['businessPercent'], fallback: 1),
      confidence: _double(value['confidence'], fallback: 1),
      reviewStatus: _reviewStatus(value['reviewStatus']),
      invoiceProofMode: _invoiceProofMode(value['invoiceProofMode']),
      invoiceProofCrop: value['invoiceProofCrop'] is Map
          ? WorkSupplyLineProofCrop.fromMap(value['invoiceProofCrop'] as Map)
          : null,
      note: _string(value['note']),
    );
  }
}

class WorkSupplyInventoryReceiptRecord {
  const WorkSupplyInventoryReceiptRecord({
    required this.id,
    required this.source,
    required this.lines,
    this.merchantName = '',
    this.merchantPhone = '',
    this.merchantAddress = '',
    this.receiptDate,
    this.proofs = const [],
    this.createdAt,
    this.updatedAt,
    this.note = '',
  });

  final String id;
  final WorkSupplyInventoryIntakeSource source;
  final List<WorkSupplyInventoryReceiptLine> lines;
  final String merchantName;
  final String merchantPhone;
  final String merchantAddress;
  final DateTime? receiptDate;
  final List<WorkSupplyReceiptProofRef> proofs;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String note;

  bool get hasProof => proofs.isNotEmpty;
  double get subtotal => lines.fold(0, (sum, line) => sum + line.subtotal);
  double get taxTotal => lines.fold(0, (sum, line) => sum + line.taxAmount);
  double get total => subtotal + taxTotal;

  WorkSupplyInventoryReceiptRecord copyWith({
    List<WorkSupplyInventoryReceiptLine>? lines,
    String? merchantName,
    String? merchantPhone,
    String? merchantAddress,
    DateTime? receiptDate,
    List<WorkSupplyReceiptProofRef>? proofs,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? note,
  }) {
    return WorkSupplyInventoryReceiptRecord(
      id: id,
      source: source,
      lines: lines ?? this.lines,
      merchantName: merchantName ?? this.merchantName,
      merchantPhone: merchantPhone ?? this.merchantPhone,
      merchantAddress: merchantAddress ?? this.merchantAddress,
      receiptDate: receiptDate ?? this.receiptDate,
      proofs: proofs ?? this.proofs,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      note: note ?? this.note,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'source': source.name,
      'lines': [for (final line in lines) line.toMap()],
      'merchantName': merchantName,
      'merchantPhone': merchantPhone,
      'merchantAddress': merchantAddress,
      'receiptDate': receiptDate?.toIso8601String(),
      'proofs': [for (final proof in proofs) proof.toMap()],
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'note': note,
    };
  }

  static WorkSupplyInventoryReceiptRecord fromMap(Map value) {
    return WorkSupplyInventoryReceiptRecord(
      id: _string(value['id']),
      source: _source(value['source']),
      lines: [
        if (value['lines'] is List)
          for (final line in value['lines'] as List)
            if (line is Map) WorkSupplyInventoryReceiptLine.fromMap(line),
      ],
      merchantName: _string(value['merchantName']),
      merchantPhone: _string(value['merchantPhone']),
      merchantAddress: _string(value['merchantAddress']),
      receiptDate: _date(value['receiptDate']),
      proofs: [
        if (value['proofs'] is List)
          for (final proof in value['proofs'] as List)
            if (proof is Map) WorkSupplyReceiptProofRef.fromMap(proof),
      ],
      createdAt: _date(value['createdAt']),
      updatedAt: _date(value['updatedAt']),
      note: _string(value['note']),
    );
  }
}

Map<String, Object?> _itemToMap(WorkSupplyItem item) {
  return {
    'id': item.id,
    'name': item.name,
    'trade': item.trade,
    'category': item.category,
    'system': item.system,
    'itemType': item.itemType,
    'variant': item.variant,
    'unit': item.unit,
    'aliases': item.aliases,
  };
}

WorkSupplyItem _itemFromMap(Object? value) {
  if (value is! Map) {
    return const WorkSupplyItem(
      id: '',
      name: 'Unknown Inventory Item',
      trade: 'Unknown',
      category: 'Unknown',
      system: 'Unknown',
      itemType: 'Unknown',
      variant: '',
      unit: 'each',
    );
  }
  return WorkSupplyItem(
    id: _string(value['id']),
    name: _string(value['name'], fallback: 'Unknown Inventory Item'),
    trade: _string(value['trade'], fallback: 'Unknown'),
    category: _string(value['category'], fallback: 'Unknown'),
    system: _string(value['system'], fallback: 'Unknown'),
    itemType: _string(value['itemType'], fallback: 'Unknown'),
    variant: _string(value['variant']),
    unit: _string(value['unit'], fallback: 'each'),
    aliases: _stringList(value['aliases']),
  );
}

WorkSupplyInventoryIntakeSource _source(Object? value) {
  final name = _string(value);
  for (final source in WorkSupplyInventoryIntakeSource.values) {
    if (source.name == name) return source;
  }
  return WorkSupplyInventoryIntakeSource.manualWithoutReceipt;
}

WorkSupplyLineReviewStatus _reviewStatus(Object? value) {
  final name = _string(value);
  for (final status in WorkSupplyLineReviewStatus.values) {
    if (status.name == name) return status;
  }
  return WorkSupplyLineReviewStatus.needsReview;
}

WorkSupplyInvoiceProofMode _invoiceProofMode(Object? value) {
  final name = _string(value);
  for (final mode in WorkSupplyInvoiceProofMode.values) {
    if (mode.name == name) return mode;
  }
  return WorkSupplyInvoiceProofMode.hidden;
}

WorkSupplyReceiptLineKind _lineKind(Object? value) {
  final name = _string(value);
  for (final kind in WorkSupplyReceiptLineKind.values) {
    if (kind.name == name) return kind;
  }
  return WorkSupplyReceiptLineKind.inventory;
}

String _string(Object? value, {String fallback = ''}) {
  if (value == null) return fallback;
  return value.toString();
}

double _double(Object? value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

DateTime? _date(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

List<String> _stringList(Object? value) {
  if (value is List) return value.map((item) => item.toString()).toList();
  return const [];
}
