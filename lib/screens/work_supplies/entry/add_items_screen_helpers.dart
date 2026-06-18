part of 'work_supply_add_items_screen.dart';

const _chooseTradeLabel = 'Choose trade';
const _chooseCategoryLabel = 'Choose category';
const _chooseItemTypeLabel = 'Choose item type';
const _chooseSystemLabel = 'Choose material';
const _chooseSizeLabel = 'Choose size';
const _customAddCategoryLabel = 'Add new category';
const _customAddSystemLabel = 'Add new system or material';
const _customAddItemTypeLabel = 'Add new item type';
const _customAddSizeLabel = 'Add custom size';

const _allExpenseCategories = <ExpenseCategoryDefinition>[
  ...defaultExpenseCategories,
  ...otherExpenseCategories,
];

String _safePathValue(String? value, List<String> options, String fallback) {
  if (value != null && options.contains(value)) return value;
  return fallback;
}

WorkSupplyTrade? _tradeByName(String name) {
  for (final trade in workSupplyTrades) {
    if (trade.name == name) return trade;
  }
  return null;
}

WorkSupplyCategory? _categoryByName(
  List<WorkSupplyCategory> categories,
  String? name,
) {
  if (name == null) return null;
  for (final category in categories) {
    if (category.name == name) return category;
  }
  return null;
}

List<String> _itemTypeNamesForSystems(List<WorkSupplySystem> systems) {
  final names = <String>{};
  for (final system in systems) {
    for (final type in system.itemTypes) {
      names.add(type.name);
    }
  }
  return names.toList()..sort();
}

List<WorkSupplySystem> _systemsForItemType(
  List<WorkSupplySystem> systems,
  String itemTypeName,
) {
  if (itemTypeName == _customAddItemTypeLabel || itemTypeName.trim().isEmpty) {
    return systems;
  }
  return [
    for (final system in systems)
      if (system.itemTypes.any((type) => type.name == itemTypeName)) system,
  ];
}

List<String> _variantNamesForSelection({
  required List<WorkSupplySystem> systems,
  required String systemName,
  required String itemTypeName,
}) {
  final names = <String>{};
  for (final system in systems) {
    if (systemName != _customAddSystemLabel && system.name != systemName) {
      continue;
    }
    for (final type in system.itemTypes) {
      if (itemTypeName != _customAddItemTypeLabel &&
          type.name != itemTypeName) {
        continue;
      }
      for (final item in type.items) {
        if (item.variant.trim().isNotEmpty) names.add(item.variant.trim());
      }
    }
  }
  return names.toList()..sort(_sizeSort);
}

int _sizeSort(String a, String b) {
  final aValue = _sizeValue(a);
  final bValue = _sizeValue(b);
  if (aValue != bValue) return aValue.compareTo(bValue);
  return a.compareTo(b);
}

double _sizeValue(String value) {
  final match = RegExp(r'(\d+)(?:/(\d+))?').firstMatch(value);
  if (match == null) return double.maxFinite;
  final whole = double.tryParse(match.group(1) ?? '') ?? 0;
  final denominator = double.tryParse(match.group(2) ?? '');
  if (denominator == null || denominator == 0) return whole;
  return whole / denominator;
}

String _guessBarcodeFormat(String value) {
  final normalized = normalizeWorkSupplyBarcode(value);
  if (RegExp(r'^\d{12}$').hasMatch(normalized)) return 'upcA';
  if (RegExp(r'^\d{8}$').hasMatch(normalized)) return 'ean8';
  if (RegExp(r'^\d{13}$').hasMatch(normalized)) return 'ean13';
  if (normalized.length > 14) return 'qrOrCode128';
  return 'unknown';
}

int _countTradeItems(WorkSupplyTrade trade) {
  return trade.categories.fold(0, (total, category) {
    return total + _countCategoryItems(category);
  });
}

int _countCategoryItems(WorkSupplyCategory category) {
  return category.systems.fold(0, (total, system) {
    return total + _countSystemItems(system);
  });
}

int _countSystemItems(WorkSupplySystem system) {
  return system.itemTypes.fold(0, (total, type) => total + type.items.length);
}

String _newUserItemId() {
  return 'USER-${DateTime.now().microsecondsSinceEpoch}';
}

String _money(double value) => '\$${value.toStringAsFixed(2)}';

String _formatPercent(double value) {
  if (value == value.roundToDouble()) return '${value.toInt()}%';
  return '${value.toStringAsFixed(2)}%';
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(2);
}
