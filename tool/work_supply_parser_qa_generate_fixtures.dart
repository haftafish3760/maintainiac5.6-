import 'dart:convert';
import 'dart:io';

import 'work_supply_parser_qa_fixture_recipes.dart';
import 'work_supply_parser_qa_fixture_recipes_electrical_complete.dart';
import 'work_supply_parser_qa_fixture_recipes_hvac_complete.dart';
import 'work_supply_parser_qa_fixture_recipes_hvac_professional.dart';

const _usage =
    'dart run tool/work_supply_parser_qa_generate_fixtures.dart '
    '[--trade plumbing] [--scope residential] [--tier core] '
    '[--locale en-US] [--limit 500] [--output-dir build/parser_qa_generated]';

Future<void> main(List<String> args) async {
  final exit = await runWorkSupplyParserFixtureGenerator(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

Future<int> runWorkSupplyParserFixtureGenerator(
  List<String> args, {
  required IOSink stdout,
  required IOSink stderr,
}) async {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return 0;
  }
  final options = _GeneratorOptions.parse(args);
  if (options.limit <= 0) {
    stderr.writeln('--limit must be greater than zero.');
    return 64;
  }

  final recipes = _recipesFor(options);
  if (recipes.isEmpty) {
    stderr.writeln(
      'No fixture recipes matched trade=${options.trade} '
      'scope=${options.scope} tier=${options.tier} locale=${options.locale}.',
    );
    return 65;
  }

  final cases = _buildCases(options: options, recipes: recipes);
  final runDir = Directory(
    '${options.outputDir}/work_supply_parser/${options.trade}/'
    '${options.scope}/${options.tier}/${options.locale}',
  );
  await runDir.create(recursive: true);
  final fixturePath = '${runDir.path}/generated_fixtures.json';
  final manifestPath = '${runDir.path}/manifest.json';
  await File(fixturePath).writeAsString(
    const JsonEncoder.withIndent('  ').convert(cases),
    flush: true,
  );
  await File(manifestPath).writeAsString(
    const JsonEncoder.withIndent('  ').convert({
      'schemaVersion': 1,
      'generator': 'work_supply_parser_qa_generate_fixtures',
      'generationSeed': options.seed,
      'trade': options.trade,
      'marketScope': options.scope,
      'tier': options.tier,
      'localePackId': options.locale,
      'requestedLimit': options.limit,
      'generatedCount': cases.length,
      'fixturePath': fixturePath,
      'caseTypes': _unique(cases, 'caseType'),
      'merchants': _unique(cases, 'merchant'),
      'riskTags': _riskTags(cases),
      'parserCalls': 0,
      'liveServicesAllowed': false,
      'writesProductionCatalog': false,
      'firebaseWritesAllowed': false,
    }),
    flush: true,
  );

  stdout.writeln(
    'QA_GENERATED_FIXTURES fixtures=$fixturePath manifest=$manifestPath '
    'count=${cases.length} seed=${options.seed}',
  );
  return 0;
}

List<Map<String, Object?>> _buildCases({
  required _GeneratorOptions options,
  required List<WorkSupplyFixtureRecipe> recipes,
}) {
  final cases = <Map<String, Object?>>[];
  var index = 0;
  while (cases.length < options.limit) {
    final recipe = recipes[index % recipes.length];
    final merchant = _merchants[index % _merchants.length];
    final pattern = recipe.patterns[index % recipe.patterns.length];
    final rawLine = '${merchant.prefix} $pattern ${_priceSuffix(index)}'.trim();
    final id = [
      options.trade,
      options.scope,
      options.tier,
      options.locale,
      recipe.slug,
      cases.length.toString().padLeft(5, '0'),
    ].join('_').replaceAll(RegExp(r'[^a-zA-Z0-9_]+'), '_');
    cases.add({
      'id': id,
      'caseType': recipe.caseType,
      'merchant': merchant.name,
      'riskTags': [
        ...recipe.riskTags,
        merchant.riskTag,
        ..._supplementalRiskTags(
          index: index,
          merchant: merchant,
          locale: options.locale,
        ),
        _sourceModalityTag(index),
        options.scope,
        options.tier,
        options.locale,
        'generated_batch',
      ],
      'rawLine': rawLine,
      'expectedTrade': recipe.expectedTrade.isEmpty
          ? _title(options.trade)
          : recipe.expectedTrade,
      'expectedNameContains': recipe.expectedNameContains.isEmpty
          ? _fallbackExpectedName(recipe)
          : recipe.expectedNameContains,
      'tradeScope': recipe.tradeScope.isEmpty
          ? _title(options.trade)
          : recipe.tradeScope,
      if (options.locale != 'en-US') 'localePackId': options.locale,
      if (recipe.expectUnknown) 'expectUnknown': true,
      if (recipe.maxConfidence < 1) 'maxConfidence': recipe.maxConfidence,
      'sourceType': 'synthetic',
      'sourceOwner': 'Mainteniac QA generator',
      'reviewStatus': 'generated-not-release-approved',
    });
    index++;
  }
  return cases;
}

String _fallbackExpectedName(WorkSupplyFixtureRecipe recipe) {
  if (recipe.caseType == 'receipt_noise') return 'noise';
  if (recipe.caseType == 'ambiguous_review') return 'review';
  return recipe.slug.replaceAll('_', ' ');
}

String _priceSuffix(int index) {
  final dollars = 1 + (index % 89);
  final cents = (index * 7) % 100;
  return '${dollars.toString()}.${cents.toString().padLeft(2, '0')}';
}

List<String> _supplementalRiskTags({
  required int index,
  required _MerchantShape merchant,
  required String locale,
}) {
  return [
    'merchant_abbreviation',
    if (locale == 'es-US') 'locale_pack',
    if (merchant.name == 'Supply House' || merchant.name == 'Ferguson')
      'supply_house',
    switch (index % 6) {
      0 => 'quantity',
      1 => 'negative_match',
      2 => 'return_line',
      3 => 'discount_line',
      4 => 'mixed_trade_receipt',
      _ => 'dangerous_word',
    },
  ];
}

String _sourceModalityTag(int index) {
  return switch (index % 10) {
    0 => 'photo_ocr_text_after_extraction',
    1 => 'uploaded_pdf_text_after_extraction',
    2 => 'emailed_receipt_text_after_extraction',
    3 => 'manual_pasted_receipt_text',
    4 => 'invoice_style_material_line_text',
    5 => 'quote_style_material_line_text',
    6 => 'packing_slip_material_list_text',
    7 => 'counter_sale_material_receipt_text',
    8 => 'generic_unknown_merchant_receipt_text',
    _ => 'local_regional_supplier_receipt_text',
  };
}

List<WorkSupplyFixtureRecipe> _recipesFor(_GeneratorOptions options) {
  if (options.scope != 'residential') return const [];
  if (options.trade == 'plumbing' &&
      options.tier == 'standard' &&
      options.locale == 'es-US') {
    return spanishPlumbingStandardRecipes;
  }
  if (options.trade == 'plumbing' &&
      options.tier == 'standard' &&
      options.locale == 'en-US') {
    return englishPlumbingStandardRecipes;
  }
  if (options.trade == 'plumbing' &&
      options.tier == 'professional' &&
      options.locale == 'es-US') {
    return spanishPlumbingProfessionalRecipes;
  }
  if (options.trade == 'plumbing' &&
      options.tier == 'professional' &&
      options.locale == 'en-US') {
    return englishPlumbingProfessionalRecipes;
  }
  if (options.trade == 'plumbing' &&
      options.tier == 'complete' &&
      options.locale == 'es-US') {
    return spanishPlumbingCompleteRecipes;
  }
  if (options.trade == 'plumbing' &&
      options.tier == 'complete' &&
      options.locale == 'en-US') {
    return englishPlumbingCompleteRecipes;
  }
  if (options.trade == 'electrical' &&
      options.tier == 'standard' &&
      options.locale == 'es-US') {
    return spanishElectricalStandardRecipes;
  }
  if (options.trade == 'electrical' &&
      options.tier == 'standard' &&
      options.locale == 'en-US') {
    return englishElectricalStandardRecipes;
  }
  if (options.trade == 'electrical' &&
      options.tier == 'professional' &&
      options.locale == 'es-US') {
    return spanishElectricalProfessionalRecipes;
  }
  if (options.trade == 'electrical' &&
      options.tier == 'professional' &&
      options.locale == 'en-US') {
    return englishElectricalProfessionalRecipes;
  }
  if (options.trade == 'electrical' &&
      options.tier == 'complete' &&
      options.locale == 'es-US') {
    return spanishElectricalCompleteRecipes;
  }
  if (options.trade == 'electrical' &&
      options.tier == 'complete' &&
      options.locale == 'en-US') {
    return englishElectricalCompleteRecipes;
  }
  if (options.trade == 'hvac' &&
      options.tier == 'standard' &&
      options.locale == 'es-US') {
    return spanishHvacStandardRecipes;
  }
  if (options.trade == 'hvac' &&
      options.tier == 'standard' &&
      options.locale == 'en-US') {
    return englishHvacStandardRecipes;
  }
  if (options.trade == 'hvac' &&
      options.tier == 'professional' &&
      options.locale == 'es-US') {
    return spanishHvacProfessionalRecipes;
  }
  if (options.trade == 'hvac' &&
      options.tier == 'professional' &&
      options.locale == 'en-US') {
    return englishHvacProfessionalRecipes;
  }
  if (options.trade == 'hvac' &&
      options.tier == 'complete' &&
      options.locale == 'es-US') {
    return spanishHvacCompleteRecipes;
  }
  if (options.trade == 'hvac' &&
      options.tier == 'complete' &&
      options.locale == 'en-US') {
    return englishHvacCompleteRecipes;
  }
  if (options.tier != 'core') return const [];
  if (options.trade == 'plumbing' && options.locale == 'es-US') {
    return spanishPlumbingCoreRecipes;
  }
  if (options.trade == 'plumbing' && options.locale == 'en-US') {
    return englishPlumbingCoreRecipes;
  }
  if (options.trade == 'electrical' && options.locale == 'es-US') {
    return spanishElectricalCoreRecipes;
  }
  if (options.trade == 'electrical' && options.locale == 'en-US') {
    return englishElectricalCoreRecipes;
  }
  if (options.trade == 'hvac' && options.locale == 'es-US') {
    return spanishHvacCoreRecipes;
  }
  if (options.trade == 'hvac' && options.locale == 'en-US') {
    return englishHvacCoreRecipes;
  }
  return const [];
}

List<String> _unique(List<Map<String, Object?>> cases, String key) {
  return {
    for (final entry in cases) entry[key]?.toString() ?? '',
  }.where((value) => value.isNotEmpty).toList()..sort();
}

List<String> _riskTags(List<Map<String, Object?>> cases) {
  final tags = <String>{};
  for (final entry in cases) {
    final raw = entry['riskTags'];
    if (raw is List) {
      tags.addAll(raw.map((value) => value.toString()));
    }
  }
  return tags.toList()..sort();
}

String _title(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1).toLowerCase();
}

class _GeneratorOptions {
  const _GeneratorOptions({
    required this.trade,
    required this.scope,
    required this.tier,
    required this.locale,
    required this.limit,
    required this.outputDir,
    required this.seed,
  });

  final String trade;
  final String scope;
  final String tier;
  final String locale;
  final int limit;
  final String outputDir;
  final String seed;

  static _GeneratorOptions parse(List<String> args) {
    final values = <String, String>{};
    for (var index = 0; index < args.length; index++) {
      final arg = args[index];
      if (!arg.startsWith('--')) continue;
      final keyValue = arg.substring(2).split('=');
      if (keyValue.length == 2) {
        values[keyValue[0]] = keyValue[1];
      } else if (index + 1 < args.length && !args[index + 1].startsWith('--')) {
        values[keyValue[0]] = args[++index];
      }
    }
    final trade = (values['trade'] ?? 'plumbing').toLowerCase();
    final scope = (values['scope'] ?? 'residential').toLowerCase();
    final tier = (values['tier'] ?? 'core').toLowerCase();
    final locale = values['locale'] ?? 'en-US';
    return _GeneratorOptions(
      trade: trade,
      scope: scope,
      tier: tier,
      locale: locale,
      limit: int.tryParse(values['limit'] ?? '') ?? 500,
      outputDir: values['output-dir'] ?? 'build/parser_qa_generated',
      seed:
          values['seed'] ?? 'fixture-generator-v1-$trade-$scope-$tier-$locale',
    );
  }
}

class _MerchantShape {
  const _MerchantShape(this.name, this.prefix, this.riskTag);

  final String name;
  final String prefix;
  final String riskTag;
}

const _merchants = [
  _MerchantShape('Home Depot', 'HD', 'home_depot_style'),
  _MerchantShape('Lowes', 'LOWES', 'lowes_style'),
  _MerchantShape('Ace', 'ACE', 'ace_style'),
  _MerchantShape('Ferguson', 'FERG', 'supply_house_style'),
  _MerchantShape('Grainger', 'GRAINGER', 'industrial_counter_style'),
  _MerchantShape('Menards', 'MENARDS', 'regional_big_box_style'),
  _MerchantShape('True Value', 'TV', 'hardware_store_style'),
  _MerchantShape('Walmart', 'WM', 'walmart_style'),
  _MerchantShape('Supply House', 'SUPPLYHOUSE', 'supply_house'),
  _MerchantShape('unknown', 'LOCAL', 'unknown_merchant_style'),
];
