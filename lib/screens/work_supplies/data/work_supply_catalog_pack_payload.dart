import 'work_supply_item_identity_resolver.dart';
import 'work_supply_models.dart';

const workSupplyCatalogPackSchemaVersion = 2;

class WorkSupplyCatalogPackItemPayload {
  const WorkSupplyCatalogPackItemPayload({
    required this.canonicalKey,
    required this.id,
    required this.name,
    required this.trade,
    required this.category,
    required this.system,
    required this.itemType,
    required this.variant,
    required this.unit,
    required this.searchTerms,
    required this.aliases,
    required this.merchantAliases,
    required this.barcodeAliases,
    required this.merchantSkuAliases,
    required this.packageHints,
  });

  final String canonicalKey;
  final String id;
  final String name;
  final String trade;
  final String category;
  final String system;
  final String itemType;
  final String variant;
  final String unit;
  final List<String> searchTerms;
  final List<WorkSupplyCatalogPackAliasPayload> aliases;
  final List<WorkSupplyCatalogPackAliasPayload> merchantAliases;
  final List<WorkSupplyCatalogPackAliasPayload> barcodeAliases;
  final List<WorkSupplyCatalogPackAliasPayload> merchantSkuAliases;
  final List<String> packageHints;

  Map<String, Object?> toMap() {
    return {
      'canonicalKey': canonicalKey,
      'id': id,
      'name': name,
      'trade': trade,
      'category': category,
      'system': system,
      'itemType': itemType,
      'variant': variant,
      'unit': unit,
      'searchTerms': searchTerms,
      'aliases': [for (final alias in aliases) alias.toMap()],
      'merchantAliases': [for (final alias in merchantAliases) alias.toMap()],
      'barcodeAliases': [for (final alias in barcodeAliases) alias.toMap()],
      'merchantSkuAliases': [
        for (final alias in merchantSkuAliases) alias.toMap(),
      ],
      'packageHints': packageHints,
    };
  }
}

class WorkSupplyCatalogPackAliasPayload {
  const WorkSupplyCatalogPackAliasPayload({
    required this.value,
    required this.normalized,
    required this.source,
  });

  final String value;
  final String normalized;
  final String source;

  Map<String, Object?> toMap() {
    return {'value': value, 'normalized': normalized, 'source': source};
  }
}

WorkSupplyCatalogPackItemPayload buildWorkSupplyCatalogPackItemPayload(
  WorkSupplyItem item,
) {
  final canonicalTerms = _canonicalTermsFor(item);
  final aliasPayloads = [
    for (final alias in _aliasValuesFor(item))
      WorkSupplyCatalogPackAliasPayload(
        value: alias,
        normalized: normalizeWorkSupplyCatalogPackText(alias),
        source: 'catalog',
      ),
  ];
  return WorkSupplyCatalogPackItemPayload(
    canonicalKey: canonicalWorkSupplyItemKey(item),
    id: item.id,
    name: item.name,
    trade: item.trade,
    category: item.category,
    system: item.system,
    itemType: item.itemType,
    variant: item.variant,
    unit: item.unit,
    searchTerms: canonicalTerms,
    aliases: aliasPayloads,
    merchantAliases: const [],
    barcodeAliases: const [],
    merchantSkuAliases: const [],
    packageHints: _packageHintsFor(item),
  );
}

String normalizeWorkSupplyCatalogPackText(String value) {
  return value
      .toLowerCase()
      .replaceAll('&', ' and ')
      .replaceAll(RegExp(r'(\d+)ft\b'), r'$1 ft')
      .replaceAll(RegExp(r'(\d+)in\b'), r'$1 in')
      .replaceAll(RegExp(r'(\d+)lb\b'), r'$1 lb')
      .replaceAll(RegExp(r'(\d+)oz\b'), r'$1 oz')
      .replaceAll(RegExp(r'(\d+)gal\b'), r'$1 gal')
      .replaceAll(RegExp(r'[^a-z0-9/.-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

List<String> _aliasValuesFor(WorkSupplyItem item) {
  return [
    item.name,
    item.variant,
    item.itemType,
    item.system,
    ...item.aliases,
  ].where((value) => value.trim().isNotEmpty).toSet().toList(growable: false);
}

List<String> _canonicalTermsFor(WorkSupplyItem item) {
  final sourceText = [
    item.name,
    item.trade,
    item.category,
    item.system,
    item.itemType,
    item.variant,
    item.unit,
    ...item.aliases,
  ].join(' ');
  final terms = normalizeWorkSupplyCatalogPackText(sourceText)
      .split(RegExp(r'\s+'))
      .where((term) => term.length >= 2 && !_ignoredPackTerm(term))
      .toSet()
      .toList();
  terms.sort();
  return terms;
}

bool _ignoredPackTerm(String term) {
  return switch (term) {
    'a' || 'an' || 'and' || 'the' || 'for' || 'with' || 'x' => true,
    _ => false,
  };
}

List<String> _packageHintsFor(WorkSupplyItem item) {
  final text = normalizeWorkSupplyCatalogPackText(
    '${item.name} ${item.variant} ${item.aliases.join(' ')}',
  );
  final hints = <String>{};
  for (final match in RegExp(
    r'\b(\d+)\s*(pack|pk|ct|count|piece|pieces|roll|rolls|bag|bags|box)\b',
  ).allMatches(text)) {
    hints.add(match.group(0)!);
  }
  if (item.unit.trim().isNotEmpty) hints.add('unit:${item.unit}');
  return hints.toList(growable: false)..sort();
}
