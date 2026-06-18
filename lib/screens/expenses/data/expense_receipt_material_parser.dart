part of 'expense_receipt_parser.dart';

_ParsedQuantity? _materialQuantityFor({
  required String rawRow,
  required String description,
}) {
  final text = '$rawRow $description'.toLowerCase();
  final quantity = _materialExplicitQuantity(text);
  final packageSize = _materialPackageSize(text);
  final measured = _materialMeasuredPackage(text);

  if (quantity != null && packageSize != null) {
    return _ParsedQuantity(
      quantity: quantity,
      unitsPerPackage: packageSize.size,
      unit: packageSize.unit,
    );
  }
  if (quantity != null) {
    return _ParsedQuantity(
      quantity: quantity,
      unitsPerPackage: 1,
      unit: 'each',
    );
  }
  if (packageSize != null) {
    return _ParsedQuantity(
      quantity: 1,
      unitsPerPackage: packageSize.size,
      unit: packageSize.unit,
    );
  }
  if (measured != null) {
    return _ParsedQuantity(
      quantity: 1,
      unitsPerPackage: measured.size,
      unit: measured.unit,
    );
  }
  return null;
}

double? _materialExplicitQuantity(String text) {
  final qty = RegExp(r'\bqty\s*[:#]?\s*(\d+(?:\.\d+)?)\b').firstMatch(text);
  if (qty != null) return double.parse(qty.group(1)!);

  final leadingEach = RegExp(
    r'^\s*(\d+(?:\.\d+)?)\s*(?:ea|each)\b',
  ).firstMatch(text);
  if (leadingEach != null) return double.parse(leadingEach.group(1)!);

  final atPrice = RegExp(r'^\s*(\d+(?:\.\d+)?)\s*@\s*\d').firstMatch(text);
  if (atPrice != null) return double.parse(atPrice.group(1)!);

  final xPrice = RegExp(r'^\s*(\d+(?:\.\d+)?)\s+x\s+\$?\d').firstMatch(text);
  if (xPrice != null) return double.parse(xPrice.group(1)!);

  return null;
}

_MaterialPackageSize? _materialPackageSize(String text) {
  final count = RegExp(
    r'\b(\d+(?:\.\d+)?)\s*(?:pk|pack|pkg|ct|count|pc|piece|pieces)\b',
  ).firstMatch(text);
  if (count != null) {
    return _MaterialPackageSize(double.parse(count.group(1)!), 'each');
  }

  final box = RegExp(
    r'\b(\d+(?:\.\d+)?)\s*(?:box|case|bag|roll|tube|sheet|sheets)\b',
  ).firstMatch(text);
  if (box != null) {
    return _MaterialPackageSize(
      double.parse(box.group(1)!),
      _materialUnitForPackageWord(box.group(0)!),
    );
  }

  return null;
}

_MaterialPackageSize? _materialMeasuredPackage(String text) {
  if (_looksLikeDimensionalLumber(text)) return null;

  final foot = RegExp(
    r'\b(\d+(?:\.\d+)?)\s*(?:ft|feet|foot|lf|linear ft|linear foot)\b',
  ).firstMatch(text);
  if (foot != null) {
    return _MaterialPackageSize(double.parse(foot.group(1)!), 'foot');
  }

  final gallon = RegExp(
    r'\b(\d+(?:\.\d+)?)\s*(?:gal|gallon|gallons)\b',
  ).firstMatch(text);
  if (gallon != null) {
    return _MaterialPackageSize(double.parse(gallon.group(1)!), 'gallon');
  }

  final quart = RegExp(
    r'\b(\d+(?:\.\d+)?)\s*(?:qt|quart|quarts)\b',
  ).firstMatch(text);
  if (quart != null) {
    return _MaterialPackageSize(double.parse(quart.group(1)!), 'quart');
  }

  return null;
}

bool _looksLikeDimensionalLumber(String text) {
  return RegExp(
    r'\b\d+\s*x\s*\d+(?:\s*x\s*\d+)?\b|\b\d+x\d+(?:x\d+)?\b',
  ).hasMatch(text);
}

String _materialUnitForPackageWord(String text) {
  if (RegExp(r'\bsheets?\b').hasMatch(text)) return 'sheet';
  if (RegExp(r'\broll\b').hasMatch(text)) return 'roll';
  if (RegExp(r'\btube\b').hasMatch(text)) return 'tube';
  if (RegExp(r'\bbag\b').hasMatch(text)) return 'bag';
  if (RegExp(r'\bcase\b').hasMatch(text)) return 'case';
  if (RegExp(r'\bbox\b').hasMatch(text)) return 'box';
  return 'each';
}

class _MaterialPackageSize {
  const _MaterialPackageSize(this.size, this.unit);

  final double size;
  final String unit;
}
