part of 'work_supply_parser_qa_generate_fixtures.dart';

List<WorkSupplyFixtureRecipe> _coreHvacRecipes(
  List<WorkSupplyFixtureRecipe> recipes,
) => recipes
    .where(
      (recipe) => !const {
        'flex_duct',
        'start_collar',
        'ducto_flexible',
        'collarin_arranque',
      }.contains(recipe.slug),
    )
    .toList(growable: false);

List<WorkSupplyFixtureRecipe> _corePlumbingRecipes(
  List<WorkSupplyFixtureRecipe> recipes,
) => recipes
    .where(
      (recipe) => !const {
        'brass_flare_fitting',
        'brass_barb_fitting',
        'brass_compression_union',
        'varilla_roscada',
        'sal_suavizador',
        'service_press_jaw',
        'service_hole_saw',
        'service_recip_blade',
      }.contains(recipe.slug),
    )
    .toList(growable: false);

List<WorkSupplyFixtureRecipe> _prioritizeRecipesForLimitedBatch(
  List<WorkSupplyFixtureRecipe> recipes,
  _GeneratorOptions options,
) {
  if (recipes.length < 2) return recipes;

  const preferredCaseTypes = [
    'ambiguous_review',
    'receipt_noise',
    'dangerous_generic',
    'negative_match',
    'quantity_price',
    'clear_match',
  ];
  final prioritized = <WorkSupplyFixtureRecipe>[];
  final seen = <String>{};

  void addRecipe(WorkSupplyFixtureRecipe recipe) {
    final key =
        '${recipe.slug}|${recipe.caseType}|${recipe.patterns.join('|')}';
    if (!seen.add(key)) return;
    prioritized.add(recipe);
  }

  for (final slug in _prioritySlugsForLimitedBatch(options)) {
    for (final recipe in recipes) {
      if (recipe.slug == slug) addRecipe(recipe);
    }
  }
  for (final caseType in preferredCaseTypes) {
    for (final recipe in recipes) {
      if (recipe.caseType != caseType) continue;
      addRecipe(recipe);
      break;
    }
  }
  for (final recipe in recipes) {
    addRecipe(recipe);
  }
  return prioritized;
}

List<String> _prioritySlugsForLimitedBatch(_GeneratorOptions options) {
  if (options.trade == 'electrical' && options.locale == 'es-US') {
    if (options.tier == 'professional') {
      return const ['breaker_doble', 'varilla_tierra'];
    }
    if (options.tier == 'complete') {
      return const ['conduit_lb', 'cubierta_exterior', 'caja_exterior'];
    }
  }
  if (options.trade == 'hvac' &&
      options.scope == 'residential' &&
      options.tier == 'core') {
    if (options.locale == 'es-US') {
      return const [
        'filtro_generico',
        'capacitor_doble',
        'contactor_hvac',
        'bomba_condensado',
        'cable_termostato',
        'panel_humidificador',
        'sensor_flama',
        'filtro_aire',
        'acople_condensado',
        'pastillas_condensado',
      ];
    }
    return const [
      'dangerous_filter',
      'dual_run_capacitor',
      'hvac_contactor',
      'condensate_pump',
      'thermostat_wire',
      'humidifier_water_panel',
      'flame_sensor',
      'pleated_filter',
      'condensate_coupling',
      'pan_tabs',
    ];
  }
  return const [];
}
