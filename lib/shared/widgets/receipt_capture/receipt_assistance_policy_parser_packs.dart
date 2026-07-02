part of 'receipt_assistance_policy.dart';

class ReceiptParserCategoryPackRoute {
  const ReceiptParserCategoryPackRoute({
    required this.categoryCode,
    required this.localFirst,
    required this.localPackCodes,
    required this.optionalLocalPackCodes,
    required this.assistFallbackPackCodes,
    required this.futureRegionalPackCode,
    required this.userFacingLabel,
  });

  final String categoryCode;
  final bool localFirst;
  final List<String> localPackCodes;
  final List<String> optionalLocalPackCodes;
  final List<String> assistFallbackPackCodes;
  final String futureRegionalPackCode;
  final String userFacingLabel;

  bool get hasOptionalLocalPack => optionalLocalPackCodes.isNotEmpty;
  bool get hasAssistFallback => assistFallbackPackCodes.isNotEmpty;
  bool get hasFutureRegionalPack => futureRegionalPackCode.trim().isNotEmpty;

  Map<String, Object?> toPrivacySafeDiagnostics() {
    return {
      'categoryCode': categoryCode,
      'localFirst': localFirst,
      'localPackCodes': localPackCodes,
      'optionalLocalPackCodes': optionalLocalPackCodes,
      'assistFallbackPackCodes': assistFallbackPackCodes,
      'futureRegionalPackCode': futureRegionalPackCode,
    };
  }
}

class ReceiptParserPackRoutingPlan {
  const ReceiptParserPackRoutingPlan({required this.routes});

  factory ReceiptParserPackRoutingPlan.fromCloudAssistPlan(
    ReceiptCloudAssistPlan plan,
  ) {
    final choice = plan.parserPackInstallChoice;
    final local = choice.includedLocalPackCodes;
    final optional = choice.optionalLocalDownloadPackCodes;
    final fallback = choice.cloudFallbackPackCodes;
    final lineItemOptional = optional.contains('general_expense_lines_v1')
        ? ['general_expense_lines_v1']
        : const <String>[];
    final materialOptional =
        optional.contains('materials_inventory_regional_v1')
        ? ['materials_inventory_regional_v1']
        : const <String>[];
    final materialFallback =
        fallback.contains('materials_inventory_regional_v1')
        ? ['materials_inventory_regional_v1']
        : const <String>[];
    final cloudFallback = fallback.contains('cloud_ocr_assist_v1')
        ? ['cloud_ocr_assist_v1']
        : const <String>[];

    return ReceiptParserPackRoutingPlan(
      routes: List.unmodifiable([
        ReceiptParserCategoryPackRoute(
          categoryCode: 'fuel',
          localFirst: true,
          localPackCodes: local,
          optionalLocalPackCodes: const [],
          assistFallbackPackCodes: cloudFallback,
          futureRegionalPackCode: 'fuel_region_patterns_v1',
          userFacingLabel:
              'Fuel receipt essentials stay local-first in the base reader. Optional regional fuel patterns can be added later for stronger merchant and pump-line parsing.',
        ),
        ReceiptParserCategoryPackRoute(
          categoryCode: 'general_expense',
          localFirst: plan.parserDepth != ReceiptParserDepth.proofTotalsOnly,
          localPackCodes: local,
          optionalLocalPackCodes: lineItemOptional,
          assistFallbackPackCodes: cloudFallback,
          futureRegionalPackCode: 'general_expense_region_patterns_v1',
          userFacingLabel:
              'General expense lines use the base reader first, then optional line-item packs when the phone has room.',
        ),
        ReceiptParserCategoryPackRoute(
          categoryCode: 'materials_inventory',
          localFirst: plan.parserDepth == ReceiptParserDepth.inventoryMatching,
          localPackCodes: local,
          optionalLocalPackCodes: materialOptional,
          assistFallbackPackCodes: [...materialFallback, ...cloudFallback],
          futureRegionalPackCode: 'materials_trade_region_patterns_v1',
          userFacingLabel:
              'Materials and inventory matching remain optional so contractor packs can be downloaded by trade or region instead of bloating the base app.',
        ),
      ]),
    );
  }

  final List<ReceiptParserCategoryPackRoute> routes;

  List<String> get localFirstCategoryCodes => [
    for (final route in routes)
      if (route.localFirst) route.categoryCode,
  ];

  List<String> get optionalLocalCategoryCodes => [
    for (final route in routes)
      if (route.hasOptionalLocalPack) route.categoryCode,
  ];

  List<String> get assistFallbackCategoryCodes => [
    for (final route in routes)
      if (route.hasAssistFallback) route.categoryCode,
  ];

  List<String> get futureRegionalCategoryCodes => [
    for (final route in routes)
      if (route.hasFutureRegionalPack) route.categoryCode,
  ];

  ReceiptParserCategoryPackRoute? routeForCategory(String categoryCode) {
    final normalized = categoryCode.trim().toLowerCase();
    for (final route in routes) {
      if (route.categoryCode == normalized) return route;
    }
    return null;
  }

  String routeLabelForCategory(String categoryCode) {
    return routeForCategory(categoryCode)?.userFacingLabel ??
        'Use the base receipt reader first; stronger parser packs can be added later if this category needs them.';
  }

  String get userFacingCategoryPackSummary {
    final fuel = routeForCategory('fuel');
    final general = routeForCategory('general_expense');
    final materials = routeForCategory('materials_inventory');
    final parts = <String>[
      fuel?.localFirst == true
          ? 'Fuel receipt essentials stay local-first in the base reader.'
          : 'Fuel receipts use the base reader first.',
      general?.hasOptionalLocalPack == true
          ? 'General line-item help can be an optional local add-on.'
          : 'General expenses use the base reader for this setup.',
      materials?.hasOptionalLocalPack == true
          ? 'Materials and inventory packs can be downloaded by trade or region.'
          : materials?.hasAssistFallback == true
          ? 'Materials and inventory matching can use optional assist later.'
          : 'Materials and inventory matching stays out of the required base install.',
      'Receipt capture works without downloading these add-ons.',
    ];
    return parts.join(' ');
  }

  Map<String, Object?> toPrivacySafeDiagnostics() {
    return {
      'parserPackRouteCount': routes.length,
      'parserPackLocalFirstCategoryCodes': localFirstCategoryCodes,
      'parserPackOptionalLocalCategoryCodes': optionalLocalCategoryCodes,
      'parserPackAssistFallbackCategoryCodes': assistFallbackCategoryCodes,
      'parserPackFutureRegionalCategoryCodes': futureRegionalCategoryCodes,
    };
  }
}
