class CatalogFamily {
  const CatalogFamily({
    required this.slug,
    required this.category,
    required this.system,
    required this.itemType,
    required this.material,
    required this.unit,
    required this.sizes,
    required this.nameTemplate,
    required this.aliasTemplates,
    required this.receiptTemplates,
    this.negativeTokens = const [],
  });

  final String slug;
  final String category;
  final String system;
  final String itemType;
  final String material;
  final String unit;
  final List<String> sizes;
  final String nameTemplate;
  final List<String> aliasTemplates;
  final List<String> receiptTemplates;
  final List<String> negativeTokens;

  String nameFor(String size) => nameTemplate.replaceAll('{size}', size);

  List<String> aliasesFor(String size) {
    return [
      for (final template in aliasTemplates)
        template.replaceAll('{size}', size),
    ];
  }

  List<String> receiptPatternsFor(String size) {
    return [
      for (final template in receiptTemplates)
        template.replaceAll('{size}', size),
    ];
  }
}
