import 'package:hive_flutter/hive_flutter.dart';

import 'work_supply_models.dart';

class WorkSupplyItemIdentityStore {
  WorkSupplyItemIdentityStore._(this._box);

  static const boxName = 'work_supply_item_identity_aliases';

  final Box<dynamic> _box;

  static Future<WorkSupplyItemIdentityStore> create() async {
    final box = await Hive.openBox<dynamic>(boxName);
    return WorkSupplyItemIdentityStore._(box);
  }

  List<WorkSupplyPackageAlias> loadAliases() {
    final aliases = <WorkSupplyPackageAlias>[];
    for (final value in _box.values) {
      final alias = _aliasFromStoredValue(value);
      if (alias != null) aliases.add(alias);
    }
    aliases.sort((a, b) {
      final item = a.itemName.compareTo(b.itemName);
      if (item != 0) return item;
      return a.packageLabel.compareTo(b.packageLabel);
    });
    return aliases;
  }

  List<WorkSupplyPackageAlias> aliasesForItem(String itemId) {
    final normalizedItemId = itemId.trim();
    if (normalizedItemId.isEmpty) return const [];
    return loadAliases()
        .where((alias) => alias.itemId == normalizedItemId)
        .toList();
  }

  WorkSupplyPackageAlias? aliasForBarcode(String barcodeValue) {
    final normalized = normalizeWorkSupplyBarcode(barcodeValue);
    if (normalized.isEmpty) return null;
    return _aliasFromStoredValue(_box.get(normalized));
  }

  Future<WorkSupplyPackageAlias> saveAlias(WorkSupplyPackageAlias alias) async {
    final normalized = normalizeWorkSupplyBarcode(alias.barcodeValue);
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        alias.barcodeValue,
        'barcodeValue',
        'Barcode value is required.',
      );
    }

    final now = DateTime.now();
    final existing = aliasForBarcode(normalized);
    final saved = alias.copyWith(
      id: existing?.id ?? alias.id.ifBlank('alias-$normalized'),
      barcodeNormalized: normalized,
      barcodeValue: alias.barcodeValue.trim(),
      itemId: alias.itemId.trim(),
      itemName: alias.itemName.trim(),
      itemPath: alias.itemPath.trim(),
      packageLabel: alias.packageLabel.trim().ifBlank('Each'),
      purchaseType: alias.purchaseType.trim().ifBlank('each'),
      unit: alias.unit.trim().ifBlank('each'),
      merchantName: alias.merchantName.trim(),
      source: alias.source.trim().ifBlank('userLinked'),
      createdAt: existing?.createdAt ?? alias.createdAt ?? now,
      updatedAt: now,
    );
    await _box.put(normalized, _aliasToMap(saved));
    return saved;
  }

  Future<WorkSupplyPackageAlias> linkBarcodeToItem({
    required String barcodeValue,
    required WorkSupplyItem item,
    String barcodeFormat = 'unknown',
    String packageLabel = 'Each',
    String purchaseType = 'each',
    double unitsPerPackage = 1,
    String unit = '',
    String merchantName = '',
    String source = 'userLinked',
  }) {
    return saveAlias(
      WorkSupplyPackageAlias(
        barcodeValue: barcodeValue,
        barcodeFormat: barcodeFormat,
        itemId: item.id,
        itemName: item.name,
        itemPath: item.path,
        packageLabel: packageLabel,
        purchaseType: purchaseType,
        unitsPerPackage: unitsPerPackage <= 0 ? 1 : unitsPerPackage,
        unit: unit.trim().isEmpty ? item.unit : unit,
        merchantName: merchantName,
        source: source,
      ),
    );
  }

  Future<void> deleteAlias(String barcodeValue) async {
    final normalized = normalizeWorkSupplyBarcode(barcodeValue);
    if (normalized.isEmpty) return;
    await _box.delete(normalized);
  }

  Future<void> clear() async {
    await _box.clear();
  }
}

class WorkSupplyPackageAlias {
  const WorkSupplyPackageAlias({
    this.id = '',
    required this.barcodeValue,
    this.barcodeNormalized = '',
    this.barcodeFormat = 'unknown',
    required this.itemId,
    required this.itemName,
    required this.itemPath,
    this.packageLabel = 'Each',
    this.purchaseType = 'each',
    this.unitsPerPackage = 1,
    this.unit = 'each',
    this.merchantName = '',
    this.source = 'userLinked',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String barcodeValue;
  final String barcodeNormalized;
  final String barcodeFormat;
  final String itemId;
  final String itemName;
  final String itemPath;
  final String packageLabel;
  final String purchaseType;
  final double unitsPerPackage;
  final String unit;
  final String merchantName;
  final String source;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WorkSupplyPackageAlias copyWith({
    String? id,
    String? barcodeValue,
    String? barcodeNormalized,
    String? barcodeFormat,
    String? itemId,
    String? itemName,
    String? itemPath,
    String? packageLabel,
    String? purchaseType,
    double? unitsPerPackage,
    String? unit,
    String? merchantName,
    String? source,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkSupplyPackageAlias(
      id: id ?? this.id,
      barcodeValue: barcodeValue ?? this.barcodeValue,
      barcodeNormalized: barcodeNormalized ?? this.barcodeNormalized,
      barcodeFormat: barcodeFormat ?? this.barcodeFormat,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      itemPath: itemPath ?? this.itemPath,
      packageLabel: packageLabel ?? this.packageLabel,
      purchaseType: purchaseType ?? this.purchaseType,
      unitsPerPackage: unitsPerPackage ?? this.unitsPerPackage,
      unit: unit ?? this.unit,
      merchantName: merchantName ?? this.merchantName,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

String normalizeWorkSupplyBarcode(String value) {
  return value.trim().replaceAll(RegExp(r'[\s-]+'), '').toUpperCase();
}

Map<String, Object?> _aliasToMap(WorkSupplyPackageAlias alias) {
  return {
    'id': alias.id,
    'barcodeValue': alias.barcodeValue,
    'barcodeNormalized': alias.barcodeNormalized,
    'barcodeFormat': alias.barcodeFormat,
    'itemId': alias.itemId,
    'itemName': alias.itemName,
    'itemPath': alias.itemPath,
    'packageLabel': alias.packageLabel,
    'purchaseType': alias.purchaseType,
    'unitsPerPackage': alias.unitsPerPackage,
    'unit': alias.unit,
    'merchantName': alias.merchantName,
    'source': alias.source,
    'createdAt': alias.createdAt?.toIso8601String(),
    'updatedAt': alias.updatedAt?.toIso8601String(),
  };
}

WorkSupplyPackageAlias? _aliasFromStoredValue(Object? value) {
  if (value is! Map) return null;
  return WorkSupplyPackageAlias(
    id: _string(value['id']),
    barcodeValue: _string(value['barcodeValue']),
    barcodeNormalized: _string(value['barcodeNormalized']),
    barcodeFormat: _string(value['barcodeFormat'], fallback: 'unknown'),
    itemId: _string(value['itemId']),
    itemName: _string(value['itemName']),
    itemPath: _string(value['itemPath']),
    packageLabel: _string(value['packageLabel'], fallback: 'Each'),
    purchaseType: _string(value['purchaseType'], fallback: 'each'),
    unitsPerPackage: _double(value['unitsPerPackage'], fallback: 1),
    unit: _string(value['unit'], fallback: 'each'),
    merchantName: _string(value['merchantName']),
    source: _string(value['source'], fallback: 'userLinked'),
    createdAt: _date(value['createdAt']),
    updatedAt: _date(value['updatedAt']),
  );
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

extension on String {
  String ifBlank(String fallback) => trim().isEmpty ? fallback : this;
}
