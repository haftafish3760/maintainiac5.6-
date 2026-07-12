part of '../../work_supply_receipt_parser.dart';

/// Resolves unambiguous plumbing receipt shorthand before broad fast rules.
WorkSupplyItem? _directPlumbingReceiptPrecedenceMatch(
  String text, {
  String? tradeScope,
}) {
  if (tradeScope != null &&
      tradeScope.trim().isNotEmpty &&
      tradeScope.trim().toLowerCase() != 'plumbing') {
    return null;
  }

  WorkSupplyItem? findPlumbing(bool Function(String name) matches) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && matches(name)) return item;
    }
    return null;
  }

  final wantsPosiTempCartridge =
      RegExp(r'\bposi\s*temp\b').hasMatch(text) &&
      RegExp(r'\b(shower|cartridge|cart)\b').hasMatch(text);
  if (wantsPosiTempCartridge) {
    final match = findPlumbing((name) => name.contains('shower cartridge'));
    if (match != null) return match;
  }

  final wantsCpvcCoupling =
      RegExp(r'\b(cpvc|cpv\s*c)\b').hasMatch(text) &&
      RegExp(r'\b(coupling|cplg|coup)\b').hasMatch(text);
  if (wantsCpvcCoupling) {
    final size = _nominalReceiptSize(text);
    final match = findPlumbing(
      (name) =>
          name.contains('cpvc coupling') &&
          (size == null || _nameMatchesReceiptSize(name, size)),
    );
    if (match != null) return match;
  }

  final wantsCleanoutPlug =
      RegExp(r'\b(cleanout|clean\s*out|co)\b').hasMatch(text) &&
      RegExp(r'\bplug\b').hasMatch(text) &&
      !RegExp(r'\b(abs|black)\b').hasMatch(text);
  if (wantsCleanoutPlug) {
    final size = _nominalReceiptSize(text);
    final match = findPlumbing(
      (name) =>
          name.contains('cleanout access part') &&
          name.contains('cleanout plug') &&
          (size == null || _nameMatchesReceiptSize(name, size)),
    );
    if (match != null) return match;
  }

  final wantsTailpiece = RegExp(
    r'\b(tailpc|tailpiece|tail\s*piece)\b',
  ).hasMatch(text);
  if (wantsTailpiece) {
    final size = _nominalReceiptSize(text);
    final match = findPlumbing(
      (name) =>
          name.contains('tailpiece') &&
          (size == null || _nameMatchesReceiptSize(name, size)),
    );
    if (match != null) return match;
  }

  return null;
}
