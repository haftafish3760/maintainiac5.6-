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

  WorkSupplyItem? findPlumbingItem(bool Function(WorkSupplyItem item) matches) {
    for (final item in _activeWorkSupplyCatalogItems) {
      if (item.trade == 'Plumbing' && matches(item)) return item;
    }
    return null;
  }

  final wantsDishwasherBranchTailpiece = RegExp(
    r'\bdishwasher\s+branch\s+tailpiece\b',
  ).hasMatch(text);
  if (wantsDishwasherBranchTailpiece) {
    final match = findPlumbing(
      (name) =>
          name.contains('dishwasher disposal drain part') &&
          name.contains('dishwasher branch tailpiece'),
    );
    if (match != null) return match;
  }

  final wantsCleanoutCover =
      RegExp(r'\bcleanout\b').hasMatch(text) &&
      RegExp(r'\bcover\b').hasMatch(text);
  if (wantsCleanoutCover) {
    final size = _nominalReceiptSize(text);
    final match = findPlumbingItem((item) {
      final name = item.name.toLowerCase();
      final variant = item.variant.toLowerCase();
      return name.contains('cleanout access part') &&
          variant.contains('cleanout cover') &&
          (size == null ||
              _nameMatchesReceiptSize(name, size) ||
              variant.startsWith('$size in'));
    });
    if (match != null) return match;
  }

  final wantsPushFitSupplyStop =
      RegExp(
        r'\b(push\s*fit|push[-\s]*to[-\s]*connect|sharkbite)\b',
      ).hasMatch(text) &&
      RegExp(r'\b(supply\s+stop|stop\s+valve|shutoff)\b').hasMatch(text);
  if (wantsPushFitSupplyStop) {
    final match = findPlumbingItem(
      (item) =>
          item.name.toLowerCase().contains('push-fit supply stop') &&
          _matchesHalfByThreeEighthStop(text, item.variant),
    );
    if (match != null) return match;
  }

  final wantsAbsSanitaryTee =
      RegExp(r'\b(abs|black\s+drain|black\s+dwv)\b').hasMatch(text) &&
      RegExp(r'\b(san\s+tee|sanitary\s+tee|sanitary\s+t)\b').hasMatch(text);
  if (wantsAbsSanitaryTee) {
    final size = _nominalReceiptSize(text);
    final match = findPlumbingItem((item) {
      final name = item.name.toLowerCase();
      final variant = _normalize(item.variant);
      return name.contains('abs dwv sanitary tee') &&
          (size == null ||
              variant == '$size in' ||
              variant.startsWith('$size in ') ||
              name.startsWith('$size in '));
    });
    if (match != null) return match;
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
