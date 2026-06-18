enum ReceiptLineKind { inventory, expense }

class ReceiptLineDraft {
  const ReceiptLineDraft({
    required this.kind,
    required this.description,
    this.inventoryItemId = '',
    this.inventoryPath = '',
    this.expenseCategory = '',
    this.quantity = 1,
    this.unitsPerPackage = 1,
    this.purchaseType = 'each',
    this.unit = 'each',
    this.subtotal = 0,
    this.taxRate = 0,
    this.storageArea = '',
    this.storageDetail = '',
    this.businessUse = 'business',
    this.businessPercent = 1,
    this.note = '',
  });

  final ReceiptLineKind kind;
  final String description;
  final String inventoryItemId;
  final String inventoryPath;
  final String expenseCategory;
  final double quantity;
  final double unitsPerPackage;
  final String purchaseType;
  final String unit;
  final double subtotal;
  final double taxRate;
  final String storageArea;
  final String storageDetail;
  final String businessUse;
  final double businessPercent;
  final String note;

  bool get isInventory => kind == ReceiptLineKind.inventory;
  bool get isExpense => kind == ReceiptLineKind.expense;
  double get totalUnits => quantity * unitsPerPackage;
  double get taxAmount => subtotal * taxRate;
  double get totalWithTax => subtotal + taxAmount;
  double get unitCostWithTax => totalUnits <= 0 ? 0 : totalWithTax / totalUnits;

  Map<String, Object?> toMap() {
    return {
      'kind': kind.name,
      'description': description,
      'inventoryItemId': inventoryItemId,
      'inventoryPath': inventoryPath,
      'expenseCategory': expenseCategory,
      'quantity': quantity,
      'unitsPerPackage': unitsPerPackage,
      'purchaseType': purchaseType,
      'unit': unit,
      'subtotal': subtotal,
      'taxRate': taxRate,
      'storageArea': storageArea,
      'storageDetail': storageDetail,
      'businessUse': businessUse,
      'businessPercent': businessPercent,
      'note': note,
    };
  }
}
